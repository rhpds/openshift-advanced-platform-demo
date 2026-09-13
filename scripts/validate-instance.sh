#!/usr/bin/env bash
# Read-only validation of a provisioned ocp4-adv-app-platform-demo instance, after
# scripts/post-provision.sh (and optionally the RHCL / RHDH layers). Prints PASS/FAIL per check
# and exits non-zero if any required check fails. Safe to run any number of times.
#
#   bash scripts/validate-instance.sh            # base demo + fix-ups
#   WITH_RHCL=1 WITH_RHDH_PLUGINS=1 bash scripts/validate-instance.sh
#   LLM_USER=dev2 LLM_BRANCH=llm-routing ...      # also check the app switched to the gateway
set -uo pipefail
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
GL="https://gitlab-gitlab.${D}"
RHDH="https://backstage-developer-hub-rhdh.${D}"
fail=0; warn=0
pass() { printf '  \033[32mPASS\033[0m %s\n' "$*"; }
failf() { printf '  \033[31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
warnf() { printf '  \033[33mWARN\033[0m %s\n' "$*"; warn=$((warn+1)); }
check() { local name=$1; shift; if "$@" >/dev/null 2>&1; then pass "$name"; else failf "$name"; fi; }
http() { curl -sk -o /dev/null -w '%{http_code}' --max-time 20 "$@"; }
log() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }
gl_raw() { curl -sk "$GL/api/v4/projects/$(printf '%s' "$1" | sed 's#/#%2F#g')/repository/files/$(printf '%s' "$2" | sed 's#/#%2F#g')/raw?ref=main"; }

log "1. Cluster and demo baseline"
[ "$(oc get nodes --no-headers | awk '$2!="Ready"' | wc -l | tr -d ' ')" = 0 ] && pass "all nodes Ready" || failf "nodes not Ready"
[ "$(oc get co --no-headers | awk '$3!="True"||$4!="False"||$5!="False"' | wc -l | tr -d ' ')" = 0 ] && pass "cluster operators healthy" || failf "degraded cluster operators"
bad=$(oc get application.argoproj.io -A -o json | jq -r '.items[] | select(.status.sync.status!="Synced" or .status.health.status!="Healthy") | .metadata.name' | tr '\n' ' ')
[ -z "$bad" ] && pass "Argo CD apps Synced/Healthy" || failf "Argo CD apps not healthy: $bad"
for ns in parasol-insurance-dev parasol-insurance-prod parasol-insurance-secured-dev parasol-insurance-secured-prod; do
  app=$(oc get deployment -n $ns -o name 2>/dev/null | grep -E 'deployment.apps/parasol-insurance(-secured)?$' | head -1)
  r=$(oc get "$app" -n $ns -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' 2>/dev/null)
  [ "${r%/*}" = "${r#*/}" ] && [ -n "$r" ] && pass "$ns application $r" || failf "$ns application not ready ($r)"
done
[ "$(http https://parasol-insurance-parasol-insurance-prod.$D/api/claims)" = 200 ] && pass "Parasol prod API answers" || failf "Parasol prod API"
[ "$(http "$RHDH/api/auth/oidc/start?env=production")" = 302 ] && pass "RHDH login redirect (302)" || failf "RHDH login (restart RHDH if 500)"
for u in "sonarqube https://sonarqube-sonarqube.$D/api/system/status" "gitlab $GL/users/sign_in" "tpa https://server-trusted-profile-analyzer.$D" "quay https://quay.$D/health/instance" "vault https://vault-vault.$D/v1/sys/health"; do set -- $u; [ "$(http -L "$2")" = 200 ] && pass "$1 reachable" || failf "$1 unreachable"; done

log "2. post-provision fix-ups"
gl_raw rhdh/rhdh-templates templates/parasol-insurance-secured/manifests/helm/templates/task-sonar-scan.yaml | grep -q 'sonar-maven-plugin:sonar' && pass "template sonar task uses the qualified goal" || failf "template sonar task still 'mvn sonar:sonar'"
gl_raw rhdh/rhdh-templates entities/components.yaml | grep -q 'argocd/app-selector: backstage.io/component=parasol-insurance-secured' && pass "components.yaml has argocd/app-selector" || failf "components.yaml without app-selector"
[ "$(oc get application.argoproj.io -n rhdh-gitops -l backstage.io/component --no-headers 2>/dev/null | wc -l | tr -d ' ')" -ge 4 ] && pass "Argo Applications labelled for the CD tab" || failf "Argo Applications missing backstage.io/component labels"
tag=$(gl_raw parasol/parasol-insurance-secured-manifests app/values/values-prod.yaml | sed -nE 's/^[[:space:]]*tag:[[:space:]]*"?([^"[:space:]]+)"?.*/\1/p' | head -1)
n=$(curl -sk "https://quay.$D/api/v1/repository/parasol/parasol-insurance-secured/tag/?specificTag=${tag}&onlyActiveTags=true" | jq '.tags|length' 2>/dev/null)
[ "${n:-0}" -gt 0 ] && pass "secured prod image tag $tag exists in Quay" || failf "secured prod references tag $tag which is not in Quay (ImagePullBackOff)"

if [ "${WITH_RHCL:-0}" = 1 ]; then
  log "3. Connectivity Link layer"
  [ "$(oc get kuadrant kuadrant -n kuadrant-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ] && pass "Kuadrant Ready" || failf "Kuadrant not Ready"
  oc get pods -n kuadrant-system --no-headers 2>/dev/null | grep -q 'developer-portal-controller.*Running' && pass "developer portal controller running" || failf "developer portal controller missing (spec.components.developerPortal)"
  oc get console.operator cluster -o jsonpath='{.spec.plugins}' | grep -q kuadrant-console-plugin && pass "console plugin enabled" || warnf "console plugin not enabled"
  [ "$(oc get gateway parasol-gateway -n parasol-gateway -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null)" = True ] && pass "parasol-gateway Programmed" || failf "parasol-gateway not programmed (namespace label istio.io/dataplane-mode=ambient?)"
  [ "$(oc get deployment parasol-gateway-istio -n parasol-gateway -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" -ge 2 ] 2>/dev/null && pass "gateway has 2 ready replicas" || warnf "gateway with fewer than 2 replicas (policy reloads cause blips)"
  for p in "authpolicy/parasol-api parasol-insurance-prod" "ratelimitpolicy/parasol-api parasol-gateway" "authpolicy/llm parasol-gateway" "tokenratelimitpolicy/llm parasol-gateway"; do set -- $p; [ "$(oc get $1 -n $2 -o jsonpath='{.status.conditions[?(@.type=="Enforced")].status}' 2>/dev/null)" = True ] && pass "$1 Enforced" || failf "$1 not Enforced"; done
  oc get apiproduct parasol-claims-api -n parasol-insurance-prod >/dev/null 2>&1 && pass "API Product parasol-claims-api" || failf "API Product missing"
  H="https://parasol-api-parasol-insurance-prod.$D/api/claims"
  [ "$(http "$H")" = 401 ] && pass "API without key -> 401" || failf "API without key not 401"
  K=$(oc get secret parasol-api-key-partner1 -n kuadrant-system -o jsonpath='{.data.api_key}' 2>/dev/null | base64 -d)
  if [ -n "$K" ]; then
    codes=""; for i in $(seq 1 12); do codes="$codes$(http -H "Authorization: APIKEY $K" "$H") "; done
    echo "$codes" | grep -q '^200 ' && echo "$codes" | grep -q 429 && pass "API with key: 200 then 429 ($codes)" || failf "API burst: $codes"
  else failf "partner1 key not in kuadrant-system"; fi
  PK=$(oc get secret llm-key-team-demo -n kuadrant-system -o jsonpath='{.data.api_key}' 2>/dev/null | base64 -d)
  if [ -n "$PK" ]; then
    out=$(oc run validate-llm -n default --rm -i --restart=Never --image=quay.io/curl/curl:latest --env="PK=$PK" -- sh -c 'sleep 3; a=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 http://llm.parasol-gateway.svc/v1/models); b=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 -H "Authorization: Bearer $PK" http://llm.parasol-gateway.svc/v1/models); echo "nokey=$a key=$b"' 2>/dev/null | grep -E '^nokey=')
    echo "$out" | grep -q 'nokey=401 key=200' && pass "LLM route: 401 without key, 200 with platform key" || failf "LLM route: $out"
    [ "$(oc logs -n parasol-gateway deploy/parasol-gateway-istio --since=10m 2>/dev/null | grep -c CelError)" = 0 ] && pass "no wasm CelError in the last 10 min" || failf "wasm CelError present (token counting broken; check AuthPolicy llm has one identity)"
  else warnf "llm-key-team-demo not found (llm-gateway.sh not run)"; fi
  if [ -n "${LLM_USER:-}" ]; then
    ns="parasol-insurance-secured-${LLM_USER}"
    b=$(oc get secret litellm-credentials -n $ns -o jsonpath='{.data.base_url}' 2>/dev/null | base64 -d)
    [ "$b" = "http://llm.parasol-gateway.svc/v1" ] && pass "$ns points at the gateway" || failf "$ns base_url is $b"
    [ "$(oc logs -n $ns deploy/parasol-insurance-secured --since=30m 2>/dev/null | grep -c 'LLM classification response')" -gt 0 ] && pass "$ns classified emails through the gateway (last 30 min)" || warnf "$ns: no classifications in the last 30 min (no emails?)"
  fi
fi

if [ "${WITH_RHDH_PLUGINS:-0}" = 1 ]; then
  log "4. Developer Hub Kuadrant plugins"
  oc get cm dynamic-plugins -n rhdh -o jsonpath='{.data.dynamic-plugins\.yaml}' | grep -q 'kuadrant-backstage-plugin-frontend' && pass "dynamic-plugins declares the Kuadrant plugins" || failf "Kuadrant plugins not in dynamic-plugins"
  oc get cm app-config-rhdh -n rhdh -o jsonpath='{.data.app-config-rhdh\.yaml}' | grep -q '^permission:' && pass "permission framework enabled" || failf "permission framework off"
  [ "$(http "$RHDH/kuadrant")" = 200 ] && pass "/kuadrant route served" || failf "/kuadrant not served"
  POD=$(oc get pods -n rhdh --no-headers | awk '/^backstage-developer-hub/ && $3=="Running"{print $1; exit}')
  [ "$(oc logs "$POD" -n rhdh -c backstage-backend 2>/dev/null | grep -c 'too many clients')" = 0 ] && pass "no PostgreSQL 'too many clients'" || failf "PostgreSQL connection exhaustion (run db-pool.sh)"
  oc exec "$POD" -n rhdh -c backstage-backend -- sh -c 'curl -s -H "Authorization: Bearer $BACKEND_SECRET" http://localhost:7007/api/permission/roles' 2>/dev/null | grep -q 'role:default/api-admin' && pass "RBAC roles loaded (api-admin present)" || failf "RBAC roles not loaded"
  oc exec "$POD" -n rhdh -c backstage-backend -- sh -c 'curl -s -H "Authorization: Bearer $BACKEND_SECRET" "http://localhost:7007/api/catalog/entities/by-name/api/default/parasol-claims-api"' 2>/dev/null | grep -q '"kind":"API"' && pass "API Product entity in the catalog" || warnf "parasol-claims-api not yet in the catalog (refresh takes a minute)"
fi

echo; printf 'Result: %d failed, %d warnings\n' "$fail" "$warn"
[ "$fail" = 0 ]
