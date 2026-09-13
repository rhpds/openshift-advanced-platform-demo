#!/usr/bin/env bash
# RHCL policies for the Parasol API (Section 1 prod, namespace parasol-insurance-prod).
# Adds a parallel, governed entry point; the application and its existing Route are untouched.
#
#   bash scripts/rhcl/parasol-api.sh          # create + test (401 / 200 / 429)
#   bash scripts/rhcl/parasol-api.sh delete   # remove route, policies and the API key
#
# Prereq: scripts/rhcl/gateway.sh (Gateway parasol-gateway programmed and exposed).
set -euo pipefail
NS=parasol-insurance-prod
GWNS=parasol-gateway
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
HOST="parasol-api-${NS}.${D}"

if [ "${1:-}" = "delete" ]; then
  oc delete ratelimitpolicy/parasol-api authpolicy/parasol-api httproute/parasol-api -n $NS --ignore-not-found
  oc delete secret parasol-api-key-partner1 -n $NS --ignore-not-found
  oc delete route parasol-api -n $GWNS --ignore-not-found
  echo "removed the parasol-api HTTPRoute, policies, API key and Route"
  exit 0
fi

# API key for the "partner1" consumer. Generated once; read it back with:
#   oc get secret parasol-api-key-partner1 -n parasol-insurance-prod -o jsonpath='{.data.api_key}' | base64 -d
if ! oc get secret parasol-api-key-partner1 -n $NS >/dev/null 2>&1; then
  KEY=$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)
  oc create secret generic parasol-api-key-partner1 -n $NS --from-literal=api_key="$KEY" >/dev/null
  oc label secret parasol-api-key-partner1 -n $NS authorino.kuadrant.io/managed-by=authorino app=parasol-api --overwrite >/dev/null
  oc annotate secret parasol-api-key-partner1 -n $NS secret.kuadrant.io/user-id=partner1 --overwrite >/dev/null
fi

oc apply -f - <<EOF
# Public hostname for the API, terminated by the OpenShift Router and handed to the gateway
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: parasol-api
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
# Gateway -> Parasol prod service, only /api
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: parasol-api
  namespace: $NS
spec:
  parentRefs:
    - name: parasol-gateway
      namespace: $GWNS
  hostnames:
    - $HOST
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: parasol-insurance
          port: 8080
---
# Who may call: API key in "Authorization: APIKEY <key>", looked up in Secrets labelled app=parasol-api
apiVersion: kuadrant.io/v1
kind: AuthPolicy
metadata:
  name: parasol-api
  namespace: $NS
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: parasol-api
  rules:
    authentication:
      api-key:
        apiKey:
          selector:
            matchLabels:
              app: parasol-api
          # Authorino runs in kuadrant-system; without this it only looks for
          # Secrets there and every key is rejected with 401
          allNamespaces: true
        credentials:
          authorizationHeader:
            prefix: APIKEY
    response:
      success:
        filters:
          identity:
            json:
              properties:
                userid:
                  selector: auth.identity.metadata.annotations.secret\.kuadrant\.io/user-id
---
# How much: 10 requests per 10 seconds per API key
apiVersion: kuadrant.io/v1
kind: RateLimitPolicy
metadata:
  name: parasol-api
  namespace: $NS
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: parasol-api
  limits:
    per-consumer:
      rates:
        - limit: 10
          window: 10s
      counters:
        - expression: auth.identity.userid
EOF

echo "waiting for the policies to be enforced..."
for i in $(seq 1 36); do
  a=$(oc get authpolicy parasol-api -n $NS -o jsonpath='{.status.conditions[?(@.type=="Enforced")].status}' 2>/dev/null)
  r=$(oc get ratelimitpolicy parasol-api -n $NS -o jsonpath='{.status.conditions[?(@.type=="Enforced")].status}' 2>/dev/null)
  [ "$a" = "True" ] && [ "$r" = "True" ] && break
  sleep 5
done
echo "== status"
oc get httproute parasol-api -n $NS -o custom-columns='HTTPROUTE:.metadata.name,ACCEPTED:.status.parents[0].conditions[?(@.type=="Accepted")].status,RESOLVED:.status.parents[0].conditions[?(@.type=="ResolvedRefs")].status'
oc get authpolicy,ratelimitpolicy parasol-api -n $NS -o custom-columns='KIND:.kind,ACCEPTED:.status.conditions[?(@.type=="Accepted")].status,ENFORCED:.status.conditions[?(@.type=="Enforced")].status,MSG:.status.conditions[?(@.type=="Enforced")].message'

KEY=$(oc get secret parasol-api-key-partner1 -n $NS -o jsonpath='{.data.api_key}' | base64 -d)
# the gateway's Envoy reloads to load the Kuadrant wasm filter; 502/503 until it is done
echo "waiting for the gateway to reload with the policies..."
for i in $(seq 1 24); do
  c=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "https://$HOST/api/claims" || true)
  [ "$c" = "401" ] && break
  sleep 5
done
echo "== tests against https://$HOST/api/claims"
printf '   without key   -> HTTP %s (expected 401)\n' "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 "https://$HOST/api/claims")"
printf '   with key      -> HTTP %s (expected 200)\n' "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 -H "Authorization: APIKEY $KEY" "https://$HOST/api/claims")"
printf '   12 quick calls -> '
for i in $(seq 1 12); do curl -sk -o /dev/null -w '%{http_code} ' --max-time 15 -H "Authorization: APIKEY $KEY" "https://$HOST/api/claims"; done; echo "(expected: 200 x10 then 429)"
printf '   UI route still direct -> HTTP %s (expected 200, unaffected)\n' "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 15 "https://parasol-insurance-${NS}.${D}/api/claims")"
