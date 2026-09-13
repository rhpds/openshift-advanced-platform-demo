#!/usr/bin/env bash
# Point ONE Section 3 application (a per-user namespace created by the "Parasol Insurance
# Secured Development" template) at the governed LLM endpoint of the parasol-gateway.
#
#   bash scripts/rhcl/llm-switch-app.sh dev2 llm-routing          # switch
#   bash scripts/rhcl/llm-switch-app.sh dev2 llm-routing revert   # back to the direct endpoint
#
# What it does (no application code change):
#   1. writes secrets/litellm/gateway in Vault: base_url = http://llm.parasol-gateway.svc/v1,
#      api_key = the team's PLATFORM key (from kuadrant-system/llm-key-<team>)
#   2. changes es-litellm.yaml in the user's gitops repo to read that Vault path (Argo CD syncs
#      the ExternalSecret; the shared secrets/litellm/credentials used by Dev Spaces, Lightspeed
#      and the other namespaces is untouched)
#   3. forces the ExternalSecret refresh and restarts the application
# Prereq: scripts/rhcl/llm-gateway.sh. Reads the GitLab root token and the Vault root token
# from their cluster secrets (never printed).
set -euo pipefail
USER_NS=${1:?usage: llm-switch-app.sh <gitlab user> <branch> [revert]}
BRANCH=${2:?usage: llm-switch-app.sh <gitlab user> <branch> [revert]}
MODE=${3:-switch}
TEAM=team-claims
NS="parasol-insurance-secured-${USER_NS}"
REPO="${USER_NS}/parasol-insurance-secured-${BRANCH}-gitops"
FILE="helm/templates/es-litellm.yaml"
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
GL="https://gitlab-gitlab.${D}"
GLTOKEN=$(oc get secret root-user-personal-token -n gitlab -o jsonpath='{.data.token}' | base64 -d)
enc() { printf '%s' "$1" | sed 's#/#%2F#g'; }
log() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

if [ "$MODE" = "switch" ]; then
  log "1. Vault: secrets/litellm/gateway (governed endpoint + platform key of $TEAM)"
  PK=$(oc get secret llm-key-$TEAM -n kuadrant-system -o jsonpath='{.data.api_key}' | base64 -d)
  [ -n "$PK" ] || { echo "platform key kuadrant-system/llm-key-$TEAM not found; run llm-gateway.sh first"; exit 1; }
  VT=$(oc get secret vault-token -n vault -o jsonpath='{.data.token}' | base64 -d)
  # the demo's ClusterSecretStore maps ESO key "secrets/…" onto the KV v2 mount "kv/"
  oc exec vault-0 -n vault -- sh -c "VAULT_TOKEN='$VT' vault kv put -mount=kv secrets/litellm/gateway base_url=http://llm.parasol-gateway.svc/v1 api_key='$PK'" >/dev/null
  echo "   written"
  NEWKEY=secrets/litellm/gateway
else
  NEWKEY=secrets/litellm/credentials
fi

log "2. GitLab: $REPO $FILE -> $NEWKEY"
"${CURL:-curl}" -sk -H "PRIVATE-TOKEN: $GLTOKEN" "$GL/api/v4/projects/$(enc "$REPO")/repository/files/$(enc "$FILE")/raw?ref=main" -o /tmp/es-litellm.yaml
grep -q 'remoteRef' /tmp/es-litellm.yaml || { echo "could not read $FILE from $REPO"; exit 1; }
sed -i.bak -E "s#key: secrets/litellm/(credentials|gateway)#key: ${NEWKEY}#g" /tmp/es-litellm.yaml
curl -sk -H "PRIVATE-TOKEN: $GLTOKEN" -o /dev/null -X POST "$GL/api/v4/projects/$(enc "$REPO")/members" --data user_id=1 --data access_level=40 || true
code=$(curl -sk -H "PRIVATE-TOKEN: $GLTOKEN" -o /tmp/gl.out -w '%{http_code}' -X PUT "$GL/api/v4/projects/$(enc "$REPO")/repository/files/$(enc "$FILE")" \
  --data-urlencode branch=main --data-urlencode "content@/tmp/es-litellm.yaml" \
  --data-urlencode "commit_message=chore: LLM through the platform gateway ($NEWKEY)")
[ "$code" = "200" ] && echo "   committed" || { echo "   commit failed ($code): $(cat /tmp/gl.out)"; exit 1; }

log "3. sync + restart"
APP=$(oc get application.argoproj.io -n rhdh-gitops -o name | grep "parasol-insurance-secured-${USER_NS}-${BRANCH}$" | head -1)
[ -n "$APP" ] && oc annotate "$APP" -n rhdh-gitops argocd.argoproj.io/refresh=normal --overwrite >/dev/null
for i in $(seq 1 30); do
  k=$(oc get externalsecret litellm-credentials -n $NS -o jsonpath='{.spec.data[0].remoteRef.key}' 2>/dev/null)
  [ "$k" = "$NEWKEY" ] && break; sleep 10
done
oc annotate externalsecret litellm-credentials -n $NS force-sync="$(date +%s)" --overwrite >/dev/null
sleep 10
oc rollout restart deployment/parasol-insurance-secured -n $NS >/dev/null
oc rollout status deployment/parasol-insurance-secured -n $NS --timeout=300s | tail -1
echo "   base_url now: $(oc get secret litellm-credentials -n $NS -o jsonpath='{.data.base_url}' | base64 -d)"
echo "Watch it: oc logs -n $NS deploy/parasol-insurance-secured -f | grep 'LLM classification'"
echo "          and the gateway counters: oc logs -n kuadrant-system deploy/limitador-limitador --since=2m | tail"
