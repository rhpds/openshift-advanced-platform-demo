#!/usr/bin/env bash
# Developer Hub's MCP server (the Backstage "mcp-actions" endpoint that Developer Lightspeed uses:
# fetch-catalog-entities, fetch-template-metadata, TechDocs search) governed by Connectivity Link:
#   - public hostname mcp-developer-hub.<domain> -> parasol-gateway -> backstage-developer-hub.rhdh
#     (only /api/mcp-actions/v1; the rest of Developer Hub stays where it is)
#   - AuthPolicy: MCP clients send a PLATFORM key as "X-API-Key: <key>" (a header every MCP client
#     can add). Authorino resolves the Secret (kuadrant-system, admin-only) and injects the
#     Backstage static token it carries as the upstream "Authorization: Bearer" header, so the
#     Backstage token never leaves the cluster and every client gets its own revocable key.
#   - rate limit: 10 calls / 10 s per key, as one more limit of the gateway-level override policy
#     that parasol-api.sh created (a route-level RateLimitPolicy would be overridden by it),
#     scoped to this hostname with a `when` predicate
#   - the Developer Hub namespace has NetworkPolicies (only the router and itself may reach the
#     pods): one more policy admits the gateway namespace on the backend port
# Keys: platform-key-<id> Secrets labelled app=parasol-platform (shared with the traces API,
# scripts/observability/traces-api.sh). Two are created: tanaka and demo.
#
#   bash scripts/rhcl/mcp-gateway.sh            # create + test
#   bash scripts/rhcl/mcp-gateway.sh delete     # remove route and policies (keeps the keys)
#   bash scripts/rhcl/mcp-gateway.sh delete --purge
set -euo pipefail
GWNS=parasol-gateway
KEYNS=kuadrant-system
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
HOST="mcp-developer-hub.${D}"
BACKEND=backstage-developer-hub.rhdh.svc.cluster.local
MCP=/api/mcp-actions/v1

if [ "${1:-}" = "delete" ]; then
  oc delete authpolicy/mcp httproute/mcp serviceentry/developer-hub -n $GWNS --ignore-not-found
  oc delete route mcp-developer-hub -n $GWNS --ignore-not-found
  oc delete networkpolicy allow-parasol-gateway -n rhdh --ignore-not-found
  oc patch ratelimitpolicy parasol-api -n $GWNS --type json -p '[{"op":"remove","path":"/spec/overrides/limits/mcp-per-client"}]' 2>/dev/null || true
  [ "${2:-}" = "--purge" ] && oc delete secret -n $KEYNS -l app=parasol-platform --ignore-not-found
  echo "MCP gateway removed."; exit 0
fi

# the platform keys: api_key (what the client sends) + backend_token (what the gateway injects)
BT="Bearer $(oc get secret backend-secret -n rhdh -o jsonpath='{.data.MCP_SECRET}' | base64 -d)"
for id in tanaka demo; do
  if ! oc get secret platform-key-$id -n $KEYNS >/dev/null 2>&1; then
    K=$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)
    oc create secret generic platform-key-$id -n $KEYNS --from-literal=api_key="$K" --from-literal=backend_token="$BT" >/dev/null
    oc label secret platform-key-$id -n $KEYNS authorino.kuadrant.io/managed-by=authorino app=parasol-platform --overwrite >/dev/null
    oc annotate secret platform-key-$id -n $KEYNS secret.kuadrant.io/user-id=$id --overwrite >/dev/null
  fi
done

# the route's namespace must be admitted by the gateway's "http" listener (namespace selector)
oc label ns $GWNS parasol.rhdp.io/gateway-access=true --overwrite >/dev/null

oc apply -f - <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: mcp-developer-hub
  namespace: $GWNS
spec:
  host: $HOST
  to:
    kind: Service
    name: parasol-gateway-istio
  port:
    targetPort: 80
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
---
# Developer Hub is outside the namespaces istiod watches (discoverySelectors): make it a mesh destination
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: developer-hub
  namespace: $GWNS
spec:
  hosts: [ "$BACKEND" ]
  location: MESH_EXTERNAL
  resolution: DNS
  ports:
    - number: 80
      name: http
      protocol: HTTP
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: mcp
  namespace: $GWNS
spec:
  parentRefs:
    - name: parasol-gateway
      sectionName: http
  hostnames:
    - $HOST
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: $MCP
      timeouts:
        request: 60s
        backendRequest: 60s
      filters:
        - type: URLRewrite
          urlRewrite:
            hostname: $BACKEND
      backendRefs:
        - group: networking.istio.io
          kind: Hostname
          name: $BACKEND
          port: 80
---
# who: platform key in X-API-Key; the Backstage token the key carries goes upstream as Authorization
apiVersion: kuadrant.io/v1
kind: AuthPolicy
metadata:
  name: mcp
  namespace: $GWNS
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: mcp
  rules:
    authentication:
      platform-key:
        apiKey:
          selector:
            matchLabels:
              app: parasol-platform
        credentials:
          customHeader:
            name: X-API-Key
    response:
      success:
        filters:
          identity:
            json:
              properties:
                userid:
                  selector: auth.identity.metadata.annotations.secret\.kuadrant\.io/user-id
        headers:
          Authorization:
            plain:
              selector: auth.identity.data.backend_token|@base64:decode
---
# the gateway may reach Developer Hub (its namespace is closed by NetworkPolicies)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-parasol-gateway
  namespace: rhdh
  labels:
    parasol.rhdp.io/layer: rhcl-mcp
spec:
  podSelector:
    matchLabels:
      rhdh.redhat.com/app: backstage-developer-hub
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: $GWNS
      ports:
        - port: 7007
          protocol: TCP
EOF

# how much: one more limit in the gateway override policy, scoped to this host
oc patch ratelimitpolicy parasol-api -n $GWNS --type merge -p "{\"spec\":{\"overrides\":{\"limits\":{\"mcp-per-client\":{\"rates\":[{\"limit\":10,\"window\":\"10s\"}],\"counters\":[{\"expression\":\"auth.identity.userid\"}],\"when\":[{\"predicate\":\"request.host == '$HOST'\"}]}}}}}" >/dev/null
# NOTE: changing the gateway policy re-evaluates the Parasol API route too; approved developer-portal
# keys may need re-approval afterwards (see api-product.sh)

sleep 20
oc get authpolicy/mcp -n $GWNS -o custom-columns='KIND:.kind,ACCEPTED:.status.conditions[?(@.type=="Accepted")].status,ENFORCED:.status.conditions[?(@.type=="Enforced")].status,MSG:.status.conditions[?(@.type=="Enforced")].message'

KEY=$(oc get secret platform-key-demo -n $KEYNS -o jsonpath='{.data.api_key}' | base64 -d)
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"rhcl-test","version":"1"}}}'
H=(-H "Content-Type: application/json" -H "Accept: application/json, text/event-stream")
echo "waiting for the gateway to program the route..."
for i in $(seq 1 24); do
  c=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "${H[@]}" -X POST "https://$HOST$MCP" -d "$INIT" || true)
  [ "$c" = "401" ] && break
  sleep 5
done
echo "== tests against https://$HOST$MCP"
printf '   initialize without key -> HTTP %s (expected 401)\n' "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 "${H[@]}" -X POST "https://$HOST$MCP" -d "$INIT")"
R=$(curl -sk --max-time 20 "${H[@]}" -H "X-API-Key: $KEY" -X POST "https://$HOST$MCP" -d "$INIT")
printf '   initialize with key    -> server: %s\n' "$(echo "$R" | grep -o '"serverInfo":{[^}]*}' | head -1)"
R=$(curl -sk --max-time 20 "${H[@]}" -H "X-API-Key: $KEY" -X POST "https://$HOST$MCP" -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}')
printf '   tools/list             -> %s\n' "$(echo "$R" | grep -oE '"name":"[a-z-]+"' | sort -u | tr '\n' ' ')"
R=$(curl -sk --max-time 30 "${H[@]}" -H "X-API-Key: $KEY" -X POST "https://$HOST$MCP" -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"fetch-catalog-entities","arguments":{"kind":"Component","name":"parasol-insurance"}}}')
printf '   tools/call fetch-catalog-entities -> %s parasol-insurance mentions, %s\n' "$(echo "$R" | grep -o 'parasol-insurance' | wc -l | tr -d ' ')" "$(echo "$R" | grep -o '"isError":[a-z]*' | head -1)"
printf '   12 quick calls -> '
for i in $(seq 1 12); do curl -sk -o /dev/null -w '%{http_code} ' --max-time 15 "${H[@]}" -H "X-API-Key: $KEY" -X POST "https://$HOST$MCP" -d "$INIT"; done; echo "(expected: 200 x<=10 then 429)"
echo "Done. MCP endpoint for clients: https://$HOST$MCP  (header X-API-Key; keys: oc get secret -n $KEYNS -l app=parasol-platform)"
