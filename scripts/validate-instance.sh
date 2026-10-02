#!/usr/bin/env bash
# Read-only validation of a provisioned ocp4-adv-app-platform-demo instance, after
# scripts/post-provision.sh (and optionally the RHCL / RHDH layers). Prints PASS/FAIL per check
# and exits non-zero if any required check fails. Safe to run any number of times.
#
#   bash scripts/validate-instance.sh            # base demo + fix-ups
#   WITH_RHCL=1 WITH_RHDH_PLUGINS=1 WITH_OBSERVABILITY=1 WITH_KIALI_PLUGIN=1 bash scripts/validate-instance.sh
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
# grep that reads all its input (grep -q + pipefail makes the producer fail with SIGPIPE)
has() { grep -c "$@" >/dev/null; }
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
gl_raw rhdh/rhdh-templates templates/parasol-insurance-secured/manifests/helm/templates/task-sonar-scan.yaml | has 'sonar-maven-plugin:sonar' && pass "template sonar task uses the qualified goal" || failf "template sonar task still 'mvn sonar:sonar'"
gl_raw rhdh/rhdh-templates entities/components.yaml | has 'argocd/app-selector: backstage.io/component=parasol-insurance-secured' && pass "components.yaml has argocd/app-selector" || failf "components.yaml without app-selector"
[ "$(oc get application.argoproj.io -n rhdh-gitops -l backstage.io/component --no-headers 2>/dev/null | wc -l | tr -d ' ')" -ge 4 ] && pass "Argo Applications labelled for the CD tab" || failf "Argo Applications missing backstage.io/component labels"
tag=$(gl_raw parasol/parasol-insurance-secured-manifests app/values/values-prod.yaml | sed -nE 's/^[[:space:]]*tag:[[:space:]]*"?([^"[:space:]]+)"?.*/\1/p' | head -1)
n=$(curl -sk "https://quay.$D/api/v1/repository/parasol/parasol-insurance-secured/tag/?specificTag=${tag}&onlyActiveTags=true" | jq '.tags|length' 2>/dev/null)
[ "${n:-0}" -gt 0 ] && pass "secured prod image tag $tag exists in Quay" || failf "secured prod references tag $tag which is not in Quay (ImagePullBackOff)"

if [ "${WITH_RHCL:-0}" = 1 ]; then
  log "3. Connectivity Link layer"
  [ "$(oc get kuadrant kuadrant -n kuadrant-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ] && pass "Kuadrant Ready" || failf "Kuadrant not Ready"
  oc get pods -n kuadrant-system --no-headers 2>/dev/null | has 'developer-portal-controller.*Running' && pass "developer portal controller running" || failf "developer portal controller missing (spec.components.developerPortal)"
  oc get console.operator cluster -o jsonpath='{.spec.plugins}' | has kuadrant-console-plugin && pass "console plugin enabled" || warnf "console plugin not enabled"
  [ "$(oc get gateway parasol-gateway -n parasol-gateway -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null)" = True ] && pass "parasol-gateway Programmed" || failf "parasol-gateway not programmed (namespace label istio.io/dataplane-mode=ambient?)"
  [ "$(oc get deployment parasol-gateway-istio -n parasol-gateway -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" -ge 2 ] 2>/dev/null && pass "gateway has 2 ready replicas" || warnf "gateway with fewer than 2 replicas (policy reloads cause blips)"
  for p in "authpolicy/parasol-api parasol-insurance-prod" "ratelimitpolicy/parasol-api parasol-gateway" "authpolicy/llm parasol-gateway" "tokenratelimitpolicy/llm parasol-gateway"; do set -- $p; [ "$(oc get $1 -n $2 -o jsonpath='{.status.conditions[?(@.type=="Enforced")].status}' 2>/dev/null)" = True ] && pass "$1 Enforced" || failf "$1 not Enforced"; done
  oc get apiproduct parasol-claims-api -n parasol-insurance-prod >/dev/null 2>&1 && pass "API Product parasol-claims-api" || failf "API Product missing"
  H="https://parasol-api-parasol-insurance-prod.$D/api/claims"
  [ "$(http "$H")" = 401 ] && pass "API without key -> 401" || failf "API without key not 401"
  K=$(oc get secret parasol-api-key-partner1 -n kuadrant-system -o jsonpath='{.data.api_key}' 2>/dev/null | base64 -d)
  if [ -n "$K" ]; then
    codes=""; for i in $(seq 1 12); do codes="$codes$(http -H "Authorization: APIKEY $K" "$H") "; done
    echo "$codes" | has '^200 ' && echo "$codes" | has 429 && pass "API with key: 200 then 429 ($codes)" || failf "API burst: $codes"
  else failf "partner1 key not in kuadrant-system"; fi
  PK=$(oc get secret llm-key-team-demo -n kuadrant-system -o jsonpath='{.data.api_key}' 2>/dev/null | base64 -d)
  if [ -n "$PK" ]; then
    out=$(oc run validate-llm -n default --rm -i --restart=Never --image=quay.io/curl/curl:latest --env="PK=$PK" -- sh -c 'sleep 3; a=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 http://llm.parasol-gateway.svc/v1/models); b=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 -H "Authorization: Bearer $PK" http://llm.parasol-gateway.svc/v1/models); echo "nokey=$a key=$b"' 2>/dev/null | grep -E '^nokey=')
    echo "$out" | has 'nokey=401 key=200' && pass "LLM route: 401 without key, 200 with platform key" || failf "LLM route: $out"
    # NoSuchKey("identity") is logged for unauthenticated (401) calls on the llm route and is harmless;
    # UndeclaredReference means the token counter itself is broken (more than one identity in the AuthPolicy)
    [ "$(oc logs -n parasol-gateway -l gateway.networking.k8s.io/gateway-name=parasol-gateway --since=10m --tail=2000 2>/dev/null | grep CelError | grep -vc 'NoSuchKey("identity")')" = 0 ] && pass "no blocking wasm CelError in the last 10 min" || failf "wasm CelError UndeclaredReference present (token counting broken; check AuthPolicy llm has one identity)"
  else warnf "llm-key-team-demo not found (llm-gateway.sh not run)"; fi
  M="https://mcp-developer-hub.$D/api/mcp-actions/v1"; INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"validate","version":"1"}}}'
  if oc get httproute mcp -n parasol-gateway >/dev/null 2>&1; then
    [ "$(http -X POST -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' "$M" -d "$INIT")" = 401 ] && pass "MCP endpoint without key -> 401" || failf "MCP endpoint without key not 401"
    MK=$(oc get secret platform-key-demo -n kuadrant-system -o jsonpath='{.data.api_key}' 2>/dev/null | base64 -d)
    curl -sk --max-time 30 -X POST -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' -H "X-API-Key: $MK" "$M" -d "$INIT" | has '"serverInfo":{"name":"backstage"' && pass "MCP initialize with platform key answered by Developer Hub" || failf "MCP initialize through the gateway failed"
  else warnf "MCP gateway not installed (mcp-gateway.sh)"; fi
  if [ -n "${LLM_USER:-}" ]; then
    ns="parasol-insurance-secured-${LLM_USER}"
    b=$(oc get secret litellm-credentials -n $ns -o jsonpath='{.data.base_url}' 2>/dev/null | base64 -d)
    [ "$b" = "http://llm.parasol-gateway.svc/v1" ] && pass "$ns points at the gateway" || failf "$ns base_url is $b"
    [ "$(oc logs -n $ns deploy/parasol-insurance-secured --since=30m 2>/dev/null | grep -c 'LLM classification response')" -gt 0 ] && pass "$ns classified emails through the gateway (last 30 min)" || warnf "$ns: no classifications in the last 30 min (no emails?)"
  fi
fi

if [ "${WITH_RHDH_PLUGINS:-0}" = 1 ]; then
  log "4. Developer Hub Kuadrant plugins"
  oc get cm dynamic-plugins -n rhdh -o jsonpath='{.data.dynamic-plugins\.yaml}' | has 'kuadrant-backstage-plugin-frontend' && pass "dynamic-plugins declares the Kuadrant plugins" || failf "Kuadrant plugins not in dynamic-plugins"
  oc get cm app-config-rhdh -n rhdh -o jsonpath='{.data.app-config-rhdh\.yaml}' | has '^permission:' && pass "permission framework enabled" || failf "permission framework off"
  [ "$(http "$RHDH/kuadrant")" = 200 ] && pass "/kuadrant route served" || failf "/kuadrant not served"
  POD=$(oc get pods -n rhdh --no-headers | awk '/^backstage-developer-hub/ && $3=="Running"{print $1; exit}')
  [ "$(oc logs "$POD" -n rhdh -c backstage-backend 2>/dev/null | grep -c 'too many clients')" = 0 ] && pass "no PostgreSQL 'too many clients'" || failf "PostgreSQL connection exhaustion (run db-pool.sh)"
  oc exec "$POD" -n rhdh -c backstage-backend -- sh -c 'curl -s -H "Authorization: Bearer $BACKEND_SECRET" http://localhost:7007/api/permission/roles' 2>/dev/null | has 'role:default/api-admin' && pass "RBAC roles loaded (api-admin present)" || failf "RBAC roles not loaded"
  oc exec "$POD" -n rhdh -c backstage-backend -- sh -c 'curl -s -H "Authorization: Bearer $BACKEND_SECRET" "http://localhost:7007/api/catalog/entities/by-name/api/default/parasol-claims-api"' 2>/dev/null | has '"kind":"API"' && pass "API Product entity in the catalog" || warnf "parasol-claims-api not yet in the catalog (refresh takes a minute)"
fi

if [ "${WITH_OBSERVABILITY:-0}" = 1 ]; then
  log "5. Observability layer"
  [ "$(oc get statefulset tempo-tempo -n observability -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" = 1 ] && pass "Tempo ready" || failf "Tempo not ready"
  [ "$(oc get deployment otel-collector -n observability -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" = 1 ] && pass "OpenTelemetry collector ready" || failf "collector not ready"
  oc get istio default -o jsonpath='{.spec.values.meshConfig.extensionProviders}' 2>/dev/null | has otel-tracing && pass "Istio tracing provider otel-tracing" || failf "Istio CR lost the otel-tracing provider (Argo sync?)"
  nt=$(oc get telemetry -A -l parasol.rhdp.io/layer=observability --no-headers 2>/dev/null | awk '$2=="tracing"' | wc -l | tr -d ' '); na=$(oc get ns -l istio.io/dataplane-mode=ambient --no-headers | wc -l | tr -d ' ')
  [ "$nt" = "$na" ] && pass "Telemetry in all $na ambient namespaces" || warnf "Telemetry in $nt of $na ambient namespaces (re-run observability/tracing.sh)"
  svc=$(oc run validate-tempo -n observability --rm -i --restart=Never --image=quay.io/curl/curl:latest -- sh -c 'sleep 2; curl -s "http://tempo-tempo.observability.svc:3200/api/search/tag/service.name/values"' 2>/dev/null | grep -o '"tagValues":\[[^]]*\]')
  echo "$svc" | has 'parasol-gateway' && pass "gateway spans in Tempo" || warnf "no gateway spans in Tempo yet ($svc)"
  echo "$svc" | has 'authorino' && pass "Authorino spans in Tempo" || warnf "no Authorino spans in Tempo"
  [ "$(oc get kiali kiali -n istio-system -o jsonpath='{.spec.external_services.tracing.enabled}')" = true ] && pass "Kiali reads traces from Tempo" || failf "Kiali tracing disabled (Argo reverted the Kiali CR?)"
  if oc get httproute traces-api -n parasol-gateway >/dev/null 2>&1; then
    MK=$(oc get secret platform-key-demo -n kuadrant-system -o jsonpath='{.data.api_key}' 2>/dev/null | base64 -d); PK=$(oc get secret parasol-api-key-partner1 -n kuadrant-system -o jsonpath='{.data.api_key}' 2>/dev/null | base64 -d)
    TID=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n'); http -H "Authorization: APIKEY $PK" -H "traceparent: 00-${TID}-$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')-01" "https://parasol-api-parasol-insurance-prod.$D/api/claims" >/dev/null; sleep 12
    T=$(curl -sk --max-time 20 -H "X-API-Key: $MK" "https://traces-api.$D/api/traces/$TID")
    echo "$T" | has '"parasol-gateway-istio' && echo "$T" | has '"authorino"' && echo "$T" | has '"limitador"' && echo "$T" | has 'parasol-insurance.parasol-insurance-prod' \
      && pass "end-to-end trace: gateway + Authorino + Limitador + backend hop" || failf "end-to-end trace incomplete for $TID"
  else warnf "traces API not installed (traces-api.sh)"; fi
  G="https://grafana-route-observability.$D"
  [ "$(http "$G/api/health")" = 200 ] && pass "Grafana route up" || failf "Grafana route down"
  st=$(oc get grafana grafana -n observability -o jsonpath='{.status.stageStatus}'); [ "$st" = success ] && pass "Grafana operator stage success" || failf "Grafana operator stage $st"
  nd=$(oc get grafana grafana -n observability -o jsonpath='{.status.dashboards}' | tr ',' '\n' | grep -c observability); [ "$nd" -ge 10 ] && pass "$nd dashboards provisioned" || failf "only $nd dashboards provisioned"
  r=$(curl -sk "$G/api/ds/query" -H 'Content-Type: application/json' -d '{"queries":[{"refId":"A","datasource":{"uid":"prometheus"},"expr":"up","instant":true}],"from":"now-5m","to":"now"}')
  echo "$r" | has '"frames"' && ! echo "$r" | has '"error"' && pass "Prometheus datasource answers anonymously" || failf "Prometheus datasource query failed: $(echo "$r" | head -c 160)"
fi
if [ "${WITH_KIALI_PLUGIN:-0}" = 1 ]; then
  log "6. Developer Hub Kiali plugin"
  [ "$(oc get deployment kiali-rhdh -n istio-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" = 1 ] && pass "kiali-rhdh instance ready" || failf "kiali-rhdh not ready"
  [ "$(oc get kiali kiali-rhdh -n istio-system -o jsonpath='{.spec.auth.strategy}')" = token ] && pass "kiali-rhdh uses token auth" || failf "kiali-rhdh auth strategy is not token"
  oc get cm dynamic-plugins -n rhdh -o jsonpath='{.data.dynamic-plugins\.yaml}' | has 'plugin-kiali:' && pass "Kiali plugin declared" || failf "Kiali plugin not in dynamic-plugins"
  oc get cm app-config-rhdh -n rhdh -o jsonpath='{.data.app-config-rhdh\.yaml}' | has 'kiali-rhdh-istio-system' && pass "app-config points at kiali-rhdh" || failf "app-config kiali provider not kiali-rhdh"
fi

echo; printf 'Result: %d failed, %d warnings\n' "$fail" "$warn"
[ "$fail" = 0 ]
