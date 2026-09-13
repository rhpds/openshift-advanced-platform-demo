#!/usr/bin/env bash
# Post-provisioning fix-ups for an ocp4-adv-app-platform-demo instance.
#
# Run ONCE per instance, as cluster admin, from the OpenShift console Web Terminal
# (or any shell with oc + curl + jq logged in as admin):
#
#   curl -fsSL https://raw.githubusercontent.com/rhpds/openshift-advanced-platform-demo/main/scripts/post-provision.sh | bash
#
# Every step is idempotent: re-running is safe and only touches what is still wrong.
# Nothing here changes the upstream demo; it layers fixes on top of a provisioned instance.
#
# Steps
#   1. sonar-scan task: use the fully qualified Maven goal in the RHDH template skeleton,
#      the build-deployer chart and any already-scaffolded per-user gitops repos.
#   2. RHDH catalog: add argocd/app-selector to the parasol-insurance components (CD tab)
#      and point the secured component at its own Quay repository.
#   3. Argo CD: label the four Parasol Applications so the app-selector finds them.
#   4. Secured prod: create git tag 1.0 so the promotion pipeline publishes the image
#      that values-prod.yaml already references (prod otherwise stays ImagePullBackOff).
#   5. Resurrected-cluster repairs: restart Parasol db+app where the app is crash-looping,
#      restart RHDH when its OIDC login is broken.
#   6. Refresh the RHDH catalog and print a health summary.
#
# Env overrides: SKIP_TAG=1 skips step 4. DRY_RUN=1 prints what would change.
#   WITH_RHCL=1          also install Red Hat Connectivity Link, the parasol gateway, the
#                        governed API entry point and the API Product (Module 3 Part 1b)
#   WITH_RHDH_PLUGINS=1  also enable the Kuadrant Developer Hub plugins + RBAC (needs WITH_RHCL)
#   REPO_RAW=<url>       where to fetch the sibling scripts from when run via curl | bash
#                        (default: this repository on GitHub, branch main)

set -euo pipefail

log()  { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }
ok()   { printf '   \033[32m✔\033[0m %s\n' "$*"; }
warn() { printf '   \033[33m!\033[0m %s\n' "$*"; }
run()  { if [ "${DRY_RUN:-0}" = "1" ]; then echo "   [dry-run] $*"; else "$@"; fi; }

for bin in oc curl jq base64 sed; do command -v "$bin" >/dev/null || { echo "missing: $bin"; exit 1; }; done
oc whoami >/dev/null 2>&1 || { echo "not logged in to the cluster"; exit 1; }

DOMAIN=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
GL="https://gitlab-gitlab.${DOMAIN}"
QUAY="https://quay.${DOMAIN}"
RHDH="https://backstage-developer-hub-rhdh.${DOMAIN}"
TOKEN=$(oc get secret root-user-personal-token -n gitlab -o jsonpath='{.data.token}' | base64 -d)
[ -n "$TOKEN" ] || { echo "GitLab root token not found in secret gitlab/root-user-personal-token"; exit 1; }
CURL=(curl -sk -H "PRIVATE-TOKEN: ${TOKEN}")

# urlencode a GitLab project path or file path (only / needs escaping here)
enc() { printf '%s' "$1" | sed 's#/#%2F#g'; }

gl_get_raw() { "${CURL[@]}" "$GL/api/v4/projects/$(enc "$1")/repository/files/$(enc "$2")/raw?ref=main"; }
gl_exists()  { "${CURL[@]}" -o /dev/null -w '%{http_code}' "$GL/api/v4/projects/$(enc "$1")/repository/files/$(enc "$2")?ref=main"; }
gl_put() {   # project file localfile message
  local code
  code=$("${CURL[@]}" -o /tmp/gl_put.out -w '%{http_code}' -X PUT "$GL/api/v4/projects/$(enc "$1")/repository/files/$(enc "$2")" \
        --data-urlencode branch=main --data-urlencode "content@$3" --data-urlencode "commit_message=$4")
  [ "$code" = "200" ] || { warn "commit failed ($code): $(jq -r .message /tmp/gl_put.out 2>/dev/null)"; return 1; }
}
gl_ensure_root_maintainer() {   # protected main only accepts Maintainers, root is admin but not a member
  "${CURL[@]}" -o /dev/null -X POST "$GL/api/v4/projects/$(enc "$1")/members" --data user_id=1 --data access_level=40 || true
}

# ---------------------------------------------------------------------------
log "1. sonar-scan task: fully qualified Maven goal"
SONAR_TARGETS=(
  "rhdh/rhdh-templates|templates/parasol-insurance-secured/manifests/helm/templates/task-sonar-scan.yaml"
  "rhdh/helm-charts|charts/build-deployer/templates/task-sonar-scan.yaml"
)
# per-user gitops repos scaffolded by the RHDH template (dev1/…-gitops, dev2/…-gitops)
while read -r p; do SONAR_TARGETS+=("$p|helm/templates/task-sonar-scan.yaml"); done < <(
  "${CURL[@]}" "$GL/api/v4/projects?search=-gitops&per_page=100&simple=true" | jq -r '.[].path_with_namespace' | grep -E '^dev[0-9]+/.*-gitops$' || true)

for t in "${SONAR_TARGETS[@]}"; do
  repo=${t%%|*}; file=${t##*|}
  [ "$(gl_exists "$repo" "$file")" = "200" ] || { warn "$repo: $file not found, skipping"; continue; }
  gl_get_raw "$repo" "$file" > /tmp/sonar.yaml
  if grep -qE 'mvn (verify )?sonar:sonar' /tmp/sonar.yaml; then
    sed -i.bak -E 's#mvn (verify )?sonar:sonar \\#mvn org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \\#' /tmp/sonar.yaml
    gl_ensure_root_maintainer "$repo"
    run gl_put "$repo" "$file" /tmp/sonar.yaml "fix: sonar scan must use fully qualified plugin name" && ok "$repo fixed"
  else
    ok "$repo already fixed"
  fi
done

# ---------------------------------------------------------------------------
log "2. RHDH catalog: CD tab and Quay repository on the parasol components"
REPO=rhdh/rhdh-templates; FILE=entities/components.yaml
gl_get_raw "$REPO" "$FILE" > /tmp/components.yaml
changed=0
add_after() {   # add_after <anchor line regex> <new line>  (portable, no GNU-only sed)
  awk -v anchor="$1" -v line="$2" '{print} $0 ~ anchor {print line}' /tmp/components.yaml > /tmp/components.new && mv /tmp/components.new /tmp/components.yaml
}
if ! grep -q 'argocd/app-selector: backstage.io/component=parasol-insurance$' /tmp/components.yaml; then
  add_after '^    janus-idp.io/tekton: parasol-insurance$' '    argocd/app-selector: backstage.io/component=parasol-insurance'; changed=1
fi
if ! grep -q 'argocd/app-selector: backstage.io/component=parasol-insurance-secured' /tmp/components.yaml; then
  add_after '^    janus-idp.io/tekton: parasol-insurance-secured$' '    argocd/app-selector: backstage.io/component=parasol-insurance-secured'; changed=1
fi
# the secured component must show its own images, not the foundational repo's
if awk '/name: parasol-insurance-secured$/{f=1} f && /quay.io\/repository-slug: parasol\/parasol-insurance$/{print "wrong"; exit}' /tmp/components.yaml | grep -q wrong; then
  awk '/name: parasol-insurance-secured$/{f=1} {if (f && $0 ~ /quay.io\/repository-slug: parasol\/parasol-insurance$/) sub(/parasol\/parasol-insurance$/, "parasol/parasol-insurance-secured"); print}' /tmp/components.yaml > /tmp/components.new && mv /tmp/components.new /tmp/components.yaml; changed=1
fi
if [ "$changed" = "1" ]; then
  gl_ensure_root_maintainer "$REPO"
  run gl_put "$REPO" "$FILE" /tmp/components.yaml "feat: CD tab and Quay repo annotations on parasol components" && ok "components.yaml updated"
else
  ok "components.yaml already up to date"
fi

# ---------------------------------------------------------------------------
log "3. Argo CD: label the Parasol Applications for the app-selector"
for app in parasol-insurance-dev parasol-insurance-prod; do
  oc get application.argoproj.io "$app" -n rhdh-gitops >/dev/null 2>&1 && run oc label application.argoproj.io "$app" -n rhdh-gitops backstage.io/component=parasol-insurance --overwrite >/dev/null && ok "$app"
done
for app in parasol-insurance-secured-dev parasol-insurance-secured-prod; do
  oc get application.argoproj.io "$app" -n rhdh-gitops >/dev/null 2>&1 && run oc label application.argoproj.io "$app" -n rhdh-gitops backstage.io/component=parasol-insurance-secured --overwrite >/dev/null && ok "$app"
done

# ---------------------------------------------------------------------------
log "4. Secured prod: publish image tag 1.0 through the promotion pipeline"
if [ "${SKIP_TAG:-0}" = "1" ]; then
  warn "skipped (SKIP_TAG=1)"
else
  PROD_TAG=$(gl_get_raw parasol/parasol-insurance-secured-manifests app/values/values-prod.yaml | sed -nE 's/^[[:space:]]*tag:[[:space:]]*"?([^"[:space:]]+)"?.*/\1/p' | head -1)
  [ -n "$PROD_TAG" ] || { warn "could not read image tag from values-prod.yaml"; PROD_TAG=none; }
  QUAY_HAS=$(curl -sk -o /dev/null -w '%{http_code}' "$QUAY/api/v1/repository/parasol/parasol-insurance-secured/tag/?specificTag=${PROD_TAG}&onlyActiveTags=true")
  QUAY_COUNT=$(curl -sk "$QUAY/api/v1/repository/parasol/parasol-insurance-secured/tag/?specificTag=${PROD_TAG}&onlyActiveTags=true" | jq '.tags | length' 2>/dev/null || echo 0)
  GIT_TAG=$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$GL/api/v4/projects/parasol%2Fparasol-insurance-secured/repository/tags/${PROD_TAG}")
  if [ "$QUAY_HAS" = "200" ] && [ "${QUAY_COUNT:-0}" -gt 0 ]; then
    ok "image parasol-insurance-secured:${PROD_TAG} already in Quay"
  elif [ "$GIT_TAG" = "200" ]; then
    warn "git tag ${PROD_TAG} exists but image is missing: check the tag-promote PipelineRun in parasol-insurance-secured-build"
  else
    # the initial push pipeline must have produced :latest first
    if ! oc get pipelinerun -n parasol-insurance-secured-build -o json | jq -e '[.items[] | select(.metadata.name|startswith("parasol-insurance-secured-push")) | select(.status.conditions[0].status=="True")] | length > 0' >/dev/null; then
      warn "no successful push pipeline yet in parasol-insurance-secured-build; run this script again later"
    else
      run "${CURL[@]}" -o /dev/null -X POST "$GL/api/v4/projects/parasol%2Fparasol-insurance-secured/repository/tags" \
        --data-urlencode "tag_name=${PROD_TAG}" --data-urlencode ref=main --data-urlencode "message=Initial production release"
      ok "git tag ${PROD_TAG} created; tag-promote + validate pipelines start now (~6 min)"
      for i in $(seq 1 60); do
        st=$(oc get pipelinerun -n parasol-insurance-secured-build -o json | jq -r '[.items[] | select(.metadata.name|startswith("parasol-insurance-secured-tag-promote")) | select(.spec.params[]? | select(.name=="git-tag" and .value=="'"${PROD_TAG}"'"))] | sort_by(.metadata.creationTimestamp) | last | .status.conditions[0].status // "Unknown"')
        [ "$st" = "True" ] && { ok "tag-promote ${PROD_TAG} succeeded"; break; }
        [ "$st" = "False" ] && { warn "tag-promote ${PROD_TAG} FAILED, inspect the PipelineRun"; break; }
        sleep 15
      done
      run oc rollout status deployment/parasol-insurance-secured -n parasol-insurance-secured-prod --timeout=300s >/dev/null && ok "secured prod is running ${PROD_TAG}" || warn "secured prod still not ready"
    fi
  fi
fi

# ---------------------------------------------------------------------------
log "5. Resurrected-cluster repairs"
for ns in $(oc get deployment -A -l app=parasol-db -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}'); do
  app=$(oc get deployment -n "$ns" -o name | grep -E 'deployment.apps/parasol-insurance(-secured)?$' | head -1 || true)
  [ -n "$app" ] || continue
  # look only at the application pods (label app=<name>), never at finished pipeline pods
  if oc get pods -n "$ns" -l "app=${app#deployment.apps/}" --no-headers 2>/dev/null | grep -qE 'CrashLoopBackOff|Error'; then
    warn "$ns: application crash-looping (HBONE tunnels lost), restarting db then app"
    run oc rollout restart deployment -l app=parasol-db -n "$ns" >/dev/null
    run oc rollout status deployment -l app=parasol-db -n "$ns" --timeout=120s >/dev/null
    run oc rollout restart "$app" -n "$ns" >/dev/null
    run oc rollout status "$app" -n "$ns" --timeout=240s >/dev/null && ok "$ns recovered"
  else
    ok "$ns healthy"
  fi
done
LOGIN=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 20 "$RHDH/api/auth/oidc/start?env=production" || echo 000)
if [ "$LOGIN" != "302" ]; then
  warn "RHDH login broken (HTTP $LOGIN, OIDC discovery stuck after restart), restarting Developer Hub"
  run oc rollout restart deployment/backstage-developer-hub -n rhdh >/dev/null
  run oc rollout status deployment/backstage-developer-hub -n rhdh --timeout=300s >/dev/null
  sleep 15
  LOGIN=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 20 "$RHDH/api/auth/oidc/start?env=production" || echo 000)
fi
[ "$LOGIN" = "302" ] && ok "RHDH login OK" || warn "RHDH login still failing (HTTP $LOGIN)"
oc delete pod load-generator -n parasol-insurance-prod --ignore-not-found >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
log "6. Refresh RHDH catalog entities"
POD=$(oc get pods -n rhdh --no-headers | awk '/^backstage-developer-hub/ && $3=="Running"{print $1; exit}')
if [ -n "$POD" ] && [ "${DRY_RUN:-0}" != "1" ]; then
  oc exec "$POD" -n rhdh -c backstage-backend -- sh -c '
    for e in location:default/pe-owned-templates component:default/parasol-insurance component:default/parasol-insurance-secured; do
      curl -s -o /dev/null -X POST -H "Authorization: Bearer $BACKEND_SECRET" -H "Content-Type: application/json" \
        http://localhost:7007/api/catalog/refresh -d "{\"entityRef\":\"$e\"}"
    done' 2>/dev/null && ok "refresh requested (takes up to a minute)"
fi

# ---------------------------------------------------------------------------
# Optional layers: Connectivity Link and the Developer Hub Kuadrant plugins. The sibling
# scripts live in scripts/ of this repository; when this file was piped from curl they are
# fetched from REPO_RAW.
REPO_RAW=${REPO_RAW:-https://raw.githubusercontent.com/rhpds/openshift-advanced-platform-demo/main}
fetch_scripts() {
  SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]:-x}")" 2>/dev/null && pwd || true)
  if [ -n "$SCRIPTS_DIR" ] && [ -f "$SCRIPTS_DIR/rhcl/install.sh" ]; then return; fi
  SCRIPTS_DIR=$(mktemp -d)/scripts; mkdir -p "$SCRIPTS_DIR/rhcl" "$SCRIPTS_DIR/rhdh-kuadrant"
  for f in rhcl/install.sh rhcl/gateway.sh rhcl/parasol-api.sh rhcl/api-product.sh \
           rhdh-kuadrant/apply.sh rhdh-kuadrant/db-pool.sh rhdh-kuadrant/rollback.sh \
           rhdh-kuadrant/dynamic-plugins.fragment.yaml rhdh-kuadrant/app-config.fragment.yaml rhdh-kuadrant/rbac-policy.fragment.csv; do
    curl -fsSL "$REPO_RAW/scripts/$f" -o "$SCRIPTS_DIR/$f"
  done
}
if [ "${WITH_RHCL:-0}" = "1" ]; then
  log "7. Connectivity Link layer (operator, gateway, governed Parasol API, API Product)"
  fetch_scripts
  run bash "$SCRIPTS_DIR/rhcl/install.sh"
  run bash "$SCRIPTS_DIR/rhcl/gateway.sh"
  run bash "$SCRIPTS_DIR/rhcl/parasol-api.sh"
  run bash "$SCRIPTS_DIR/rhcl/api-product.sh"
fi
if [ "${WITH_RHDH_PLUGINS:-0}" = "1" ]; then
  log "8. Developer Hub: Kuadrant plugins + RBAC (restarts Developer Hub twice, ~8 min)"
  fetch_scripts
  run bash "$SCRIPTS_DIR/rhdh-kuadrant/apply.sh"
  run bash "$SCRIPTS_DIR/rhdh-kuadrant/db-pool.sh"
fi

# ---------------------------------------------------------------------------
log "Health summary"
while read -r name url; do
  follow=-L; [ "$name" = "rhdh-login(302)" ] && follow=
  printf '   %-22s %s\n' "$name" "$(curl -sk -o /dev/null -w '%{http_code}' --max-time 20 $follow "$url" || echo 000)"
done <<EOF
console https://console-openshift-console.${DOMAIN}
gitlab ${GL}/users/sign_in
sonarqube https://sonarqube-sonarqube.${DOMAIN}/api/system/status
argocd https://rhdh-gitops-server-rhdh-gitops.${DOMAIN}
rhdh ${RHDH}
rhdh-login(302) ${RHDH}/api/auth/oidc/start?env=production
tpa https://server-trusted-profile-analyzer.${DOMAIN}
vault https://vault-vault.${DOMAIN}/v1/sys/health
quay ${QUAY}/health/instance
parasol-dev https://parasol-insurance-parasol-insurance-dev.${DOMAIN}/api/claims
parasol-prod https://parasol-insurance-parasol-insurance-prod.${DOMAIN}/api/claims
secured-dev https://parasol-insurance-secured-parasol-insurance-secured-dev.${DOMAIN}/api/claims
secured-prod https://parasol-insurance-secured-parasol-insurance-secured-prod.${DOMAIN}/api/claims
EOF
oc get application.argoproj.io -A -o json | jq -r '.items[] | select(.status.sync.status!="Synced" or .status.health.status!="Healthy") | "   argo not healthy: \(.metadata.name) \(.status.sync.status)/\(.status.health.status)"'
echo; echo "Done."
