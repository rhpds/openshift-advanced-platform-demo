#!/usr/bin/env bash
# Phase 2 spike: put the external LLM endpoint (Red Hat MaaS, OpenAI-compatible) behind the
# parasol-gateway with Connectivity Link policies:
#   - AuthPolicy: callers present a PLATFORM key in the X-Platform-Key header; Authorino
#     resolves the matching Secret (kept in kuadrant-system, admin-only) and injects the
#     provider key it carries as the upstream Authorization header. The provider key never
#     appears in a route, a policy or the application.
#   - TokenRateLimitPolicy: per-consumer token budget, counted from usage.total_tokens
# The application is NOT switched here. To point the Section 3 app at the gateway later,
# change its LLM base URL to http://llm.parasol-gateway.svc/v1, drop the provider key and send
# the platform key in X-Platform-Key (e.g. quarkus.rest-client custom header).
#
#   bash scripts/rhcl/llm-gateway.sh           # create + test from inside the cluster
#   bash scripts/rhcl/llm-gateway.sh delete    # remove
set -euo pipefail
GWNS=parasol-gateway
SRC_NS=parasol-insurance-secured-dev2          # where the demo keeps litellm-credentials (Vault via ESO)
TEAM=team-claims
KEYNS=kuadrant-system                            # Authorino's namespace: only cluster admins can write here
if [ "${1:-}" = "delete" ]; then
  oc delete tokenratelimitpolicy/llm authpolicy/llm httproute/llm -n $GWNS --ignore-not-found
  oc delete destinationrule/maas serviceentry/maas service/llm -n $GWNS --ignore-not-found
  oc delete secret/llm-key-$TEAM -n $KEYNS --ignore-not-found
  oc patch gateway parasol-gateway -n $GWNS --type=json -p '[{"op":"replace","path":"/spec/listeners","value":[{"name":"http","protocol":"HTTP","port":80,"hostname":"*.'"$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')"'","allowedRoutes":{"namespaces":{"from":"All"}}}]}]' >/dev/null || true
  echo "removed the LLM route, policies, key and the internal listener"
  exit 0
fi

# provider endpoint + real key, read from the demo's own secret (never printed)
MAAS_URL=$(oc get secret litellm-credentials -n $SRC_NS -o jsonpath='{.data.base_url}' | base64 -d)     # https://host/v1
MAAS_HOST=$(echo "$MAAS_URL" | sed -E 's#https?://([^/]+).*#\1#')
MAAS_KEY_B64=$(oc get secret litellm-credentials -n $SRC_NS -o jsonpath='{.data.api_key}')
[ -n "$MAAS_HOST" ] && [ -n "$MAAS_KEY_B64" ] || { echo "litellm-credentials not found in $SRC_NS"; exit 1; }

# platform key for one team (what the application holds instead of the provider key), stored
# where only cluster admins can write. The provider key travels inside the same Secret, so the
# AuthPolicy needs no allNamespaces and no literal credential.
if ! oc get secret llm-key-$TEAM -n $KEYNS >/dev/null 2>&1; then
  PK=$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)
  oc create secret generic llm-key-$TEAM -n $KEYNS --from-literal=api_key="$PK" --from-literal=provider_key="Bearer $(echo "$MAAS_KEY_B64" | base64 -d)" >/dev/null
  oc label secret llm-key-$TEAM -n $KEYNS authorino.kuadrant.io/managed-by=authorino app=parasol-llm --overwrite >/dev/null
  oc annotate secret llm-key-$TEAM -n $KEYNS secret.kuadrant.io/user-id=$TEAM --overwrite >/dev/null
fi

# second listener for the in-cluster hostname
oc patch gateway parasol-gateway -n $GWNS --type=json -p '[{"op":"add","path":"/spec/listeners/-","value":{"name":"llm","protocol":"HTTP","port":80,"hostname":"llm.parasol-gateway.svc","allowedRoutes":{"namespaces":{"from":"Same"}}}}]' 2>/dev/null || true

oc apply -f - <<EOF
# stable in-cluster name for the application: http://llm.parasol-gateway.svc/v1
apiVersion: v1
kind: Service
metadata:
  name: llm
  namespace: $GWNS
spec:
  selector:
    gateway.networking.k8s.io/gateway-name: parasol-gateway
  ports:
    - name: http
      port: 80
      targetPort: 80
---
# the external provider as a mesh destination, with TLS origination at the gateway
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: maas
  namespace: $GWNS
spec:
  hosts: [ "$MAAS_HOST" ]
  location: MESH_EXTERNAL
  resolution: DNS
  ports:
    - number: 443
      name: https
      protocol: TLS
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: maas
  namespace: $GWNS
spec:
  host: $MAAS_HOST
  trafficPolicy:
    tls:
      mode: SIMPLE
      sni: $MAAS_HOST
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: llm
  namespace: $GWNS
spec:
  parentRefs:
    - name: parasol-gateway
      sectionName: llm
  hostnames:
    - llm.parasol-gateway.svc
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /v1
      filters:
        - type: URLRewrite
          urlRewrite:
            hostname: $MAAS_HOST
      backendRefs:
        - group: networking.istio.io
          kind: Hostname
          name: $MAAS_HOST
          port: 443
---
# who: platform key in X-Platform-Key, validated by Authorino against Secrets in its own
# namespace (no allNamespaces: a labelled Secret elsewhere cannot mint a key). The upstream
# Authorization header is built from the provider_key field of the matched Secret. The caller
# must NOT send Authorization itself: the wasm shim appends injected headers, and a doubled
# Authorization is rejected by the provider.
apiVersion: kuadrant.io/v1
kind: AuthPolicy
metadata:
  name: llm
  namespace: $GWNS
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: llm
  rules:
    authentication:
      platform-key:
        apiKey:
          selector:
            matchLabels:
              app: parasol-llm
        credentials:
          customHeader:
            name: X-Platform-Key
    response:
      success:
        filters:
          identity:
            json:
              properties:
                userid:
                  selector: auth.identity.metadata.annotations.secret\.kuadrant\.io/user-id
        headers:
          authorization:
            plain:
              # Authorino cannot concatenate strings, so the field already carries "Bearer <key>"
              selector: auth.identity.data.provider_key|@base64:decode
---
# how much: tokens per consumer, counted from usage.total_tokens in the OpenAI-style response
apiVersion: kuadrant.io/v1alpha1
kind: TokenRateLimitPolicy
metadata:
  name: llm
  namespace: $GWNS
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: llm
  limits:
    per-team:
      rates:
        - limit: 1500
          window: 1m
      counters:
        - expression: auth.identity.userid
EOF
echo "waiting for the policies to be enforced..."
for i in $(seq 1 36); do
  a=$(oc get authpolicy llm -n $GWNS -o jsonpath='{.status.conditions[?(@.type=="Enforced")].status}' 2>/dev/null)
  t=$(oc get tokenratelimitpolicy llm -n $GWNS -o jsonpath='{.status.conditions[?(@.type=="Enforced")].status}' 2>/dev/null)
  [ "$a" = "True" ] && [ "$t" = "True" ] && break
  sleep 5
done
oc get httproute llm -n $GWNS -o custom-columns='HTTPROUTE:.metadata.name,ACCEPTED:.status.parents[0].conditions[?(@.type=="Accepted")].status,RESOLVED:.status.parents[0].conditions[?(@.type=="ResolvedRefs")].status'
oc get authpolicy,tokenratelimitpolicy llm -n $GWNS -o custom-columns='KIND:.kind,ACCEPTED:.status.conditions[?(@.type=="Accepted")].status,ENFORCED:.status.conditions[?(@.type=="Enforced")].status,MSG:.status.conditions[?(@.type=="Enforced")].message'

PK=$(oc get secret llm-key-$TEAM -n $KEYNS -o jsonpath='{.data.api_key}' | base64 -d)
echo "== tests from inside the cluster (http://llm.parasol-gateway.svc/v1)"
oc run llm-test -n $GWNS --rm -i --restart=Never --image=quay.io/curl/curl:latest --env="PK=$PK" -- sh -c '
  sleep 20
  echo -n "   without key -> "; curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 30 http://llm.parasol-gateway.svc/v1/models
  echo -n "   with platform key, /v1/models -> "; curl -s -o /dev/null -w "HTTP %{http_code}\n" --max-time 30 -H "X-Platform-Key: $PK" http://llm.parasol-gateway.svc/v1/models
  echo -n "   chat completion -> "; curl -s --max-time 90 -H "X-Platform-Key: $PK" -H "Content-Type: application/json" -w " HTTP %{http_code}\n" \
     -d "{\"model\":\"qwen3-14b\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with one word: CLAIMS\"}],\"max_tokens\":8}" \
     http://llm.parasol-gateway.svc/v1/chat/completions | grep -oE "\"total_tokens\":[0-9]+| HTTP [0-9]+" | tr "\n" " "; echo
  echo -n "   burst until the 1500-token minute budget is spent -> "
  for i in $(seq 1 12); do curl -s -o /dev/null -w "%{http_code} " --max-time 90 -H "X-Platform-Key: $PK" -H "Content-Type: application/json" \
     -d "{\"model\":\"qwen3-14b\",\"messages\":[{\"role\":\"user\",\"content\":\"Write 120 words about insurance claims.\"}],\"max_tokens\":220}" \
     http://llm.parasol-gateway.svc/v1/chat/completions; done; echo "(expected: 200s then 429)"
' 2>&1 | grep -vE '^pod .* deleted'
