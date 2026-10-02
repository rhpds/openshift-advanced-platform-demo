#!/usr/bin/env bash
# Tempo's read-only query API (GET /api/traces/<id>, /api/search) exposed through the
# parasol-gateway with Connectivity Link, so the end-to-end trace of a request (gateway ->
# Authorino/Limitador -> backend) can be fetched from outside the cluster (Postman folder 7,
# validate-instance.sh). Tempo itself has no authentication: only the gateway path reaches it
# from outside, and only with a platform key (X-API-Key, Secrets labelled app=parasol-platform,
# created by scripts/rhcl/mcp-gateway.sh). Read-only: only GET is routed.
#
#   bash scripts/observability/traces-api.sh          # create + test
#   bash scripts/observability/traces-api.sh delete
set -euo pipefail
GWNS=parasol-gateway
KEYNS=kuadrant-system
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
HOST="traces-api.${D}"
BACKEND=tempo-tempo.observability.svc.cluster.local

if [ "${1:-}" = "delete" ]; then
  oc delete authpolicy/traces-api httproute/traces-api serviceentry/tempo -n $GWNS --ignore-not-found
  oc patch ratelimitpolicy parasol-api -n $GWNS --type json -p '[{"op":"remove","path":"/spec/overrides/limits/traces-per-client"}]' 2>/dev/null || true
  oc delete route traces-api -n $GWNS --ignore-not-found
  echo "traces API removed."; exit 0
fi
oc get secret platform-key-demo -n $KEYNS >/dev/null 2>&1 || { echo "platform keys missing: run scripts/rhcl/mcp-gateway.sh first"; exit 1; }
oc label ns $GWNS parasol.rhdp.io/gateway-access=true --overwrite >/dev/null

oc apply -f - <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: traces-api
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
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: tempo
  namespace: $GWNS
spec:
  hosts: [ "$BACKEND" ]
  location: MESH_EXTERNAL
  resolution: DNS
  ports:
    - number: 3200
      name: http
      protocol: HTTP
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: traces-api
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
            value: /api/traces/
          method: GET
        - path:
            type: PathPrefix
            value: /api/search
          method: GET
      filters:
        - type: URLRewrite
          urlRewrite:
            hostname: $BACKEND
      backendRefs:
        - group: networking.istio.io
          kind: Hostname
          name: $BACKEND
          port: 3200
---
apiVersion: kuadrant.io/v1
kind: AuthPolicy
metadata:
  name: traces-api
  namespace: $GWNS
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: traces-api
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
EOF
# rate limit: one more limit of the gateway-level override policy (a route-level one would be overridden)
oc patch ratelimitpolicy parasol-api -n $GWNS --type merge -p "{\"spec\":{\"overrides\":{\"limits\":{\"traces-per-client\":{\"rates\":[{\"limit\":30,\"window\":\"10s\"}],\"counters\":[{\"expression\":\"auth.identity.userid\"}],\"when\":[{\"predicate\":\"request.host == '$HOST'\"}]}}}}}" >/dev/null

sleep 20
oc get authpolicy/traces-api -n $GWNS -o custom-columns='KIND:.kind,ACCEPTED:.status.conditions[?(@.type=="Accepted")].status,ENFORCED:.status.conditions[?(@.type=="Enforced")].status,MSG:.status.conditions[?(@.type=="Enforced")].message'

KEY=$(oc get secret platform-key-demo -n $KEYNS -o jsonpath='{.data.api_key}' | base64 -d)
PK=$(oc get secret parasol-api-key-partner1 -n $KEYNS -o jsonpath='{.data.api_key}' | base64 -d)
for i in $(seq 1 24); do
  c=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "https://$HOST/api/search?limit=1" || true)
  [ "$c" = "401" ] && break
  sleep 5
done
echo "== end-to-end trace test"
printf '   search without key -> HTTP %s (expected 401)\n' "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 "https://$HOST/api/search?limit=1")"
printf '   search with key    -> HTTP %s (expected 200)\n' "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 -H "X-API-Key: $KEY" "https://$HOST/api/search?limit=1")"
printf '   POST blocked       -> HTTP %s (expected 404: only GET is routed)\n' "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 -H "X-API-Key: $KEY" -X POST "https://$HOST/api/search")"
TID=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n'); SID=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')
printf '   traced call to the Parasol API -> HTTP %s (trace %s)\n' "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 -H "Authorization: APIKEY $PK" -H "traceparent: 00-${TID}-${SID}-01" "https://parasol-api-parasol-insurance-prod.${D}/api/claims")" "$TID"
sleep 15
T=$(curl -sk --max-time 20 -H "X-API-Key: $KEY" "https://$HOST/api/traces/$TID")
svcs=$(echo "$T" | grep -o '"key":"service.name","value":{"stringValue":"[^"]*"' | sed 's/.*stringValue":"//; s/"$//' | sort -u | tr '\n' ' ')
up=$(echo "$T" | grep -o '"key":"upstream_cluster","value":{"stringValue":"[^"]*"' | sed 's/.*stringValue":"//; s/"$//' | head -1)
echo "   trace services: ${svcs:-none}"
echo "   gateway upstream (backend): ${up:-none}"
echo "$svcs" | grep -q parasol-gateway && echo "$svcs" | grep -q authorino && echo "$svcs" | grep -q limitador && echo "$up" | grep -q parasol-insurance \
  && echo "   PASS: one trace crosses OSSM (gateway), Connectivity Link (Authorino, Limitador) and reaches the Parasol backend" \
  || echo "   FAIL: trace incomplete"
echo "Done. Traces API: https://$HOST/api/traces/<trace-id> (header X-API-Key)"
