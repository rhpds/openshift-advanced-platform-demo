#!/usr/bin/env bash
# Reset everything the Golden Path template created for a persona, so Act 1 can be recorded again.
# The template names the namespace and the image per USER (parasol-insurance-secured-<user>), so a
# second run by the same persona collides with the first: remove the first before re-recording.
#
#   bash webinar/reset-tanaka-dev.sh <user> <branch>      e.g. bash webinar/reset-tanaka-dev.sh tanaka-dev claims-ai
#
# Removes: Argo CD apps (bootstrap + app), the namespace, the per-user GitLab gitops project, the
# feature branch of parasol/parasol-insurance, the push webhook of that namespace's listener, the
# catalog Location of the component, and the persona's developer-portal key objects. Keeps the
# persona, its Quay repository (tags accumulate) and the SonarQube project.
set -euo pipefail
U=${1:?user}; B=${2:?branch}
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
GL="https://gitlab-gitlab.${D}"; T=$(oc get secret root-user-personal-token -n gitlab -o jsonpath='{.data.token}' | base64 -d)
NS="parasol-insurance-secured-${U}"; APP="parasol-insurance-secured-${U}-${B}"
echo "== Argo CD apps"; oc delete application.argoproj.io "$APP" "$APP-bootstrap" -n rhdh-gitops --ignore-not-found --wait=false
echo "== namespace $NS"; oc delete ns "$NS" --ignore-not-found --wait=false
echo "== catalog Location"; POD=$(oc get pods -n rhdh --no-headers | awk '/^backstage-developer-hub/ && $3=="Running"{print $1; exit}')
oc exec "$POD" -n rhdh -c backstage-backend -- sh -c 'curl -s -H "Authorization: Bearer $BACKEND_SECRET" http://localhost:7007/api/catalog/locations' 2>/dev/null \
  | jq -r --arg u "$U" --arg b "$B" '.[] | .data | select(.target|test($u + "/parasol-insurance-secured-" + $b + "-gitops")) | .id' \
  | while read -r id; do oc exec "$POD" -n rhdh -c backstage-backend -- sh -c "curl -s -o /dev/null -w '   location $id: HTTP %{http_code}\n' -X DELETE -H \"Authorization: Bearer \$BACKEND_SECRET\" http://localhost:7007/api/catalog/locations/$id" 2>/dev/null; done
echo "== GitLab: gitops project, branch, webhook"
PID=$(curl -sk -H "PRIVATE-TOKEN: $T" "$GL/api/v4/projects/${U}%2Fparasol-insurance-secured-${B}-gitops" | jq -r '.id // empty')
[ -n "$PID" ] && curl -sk -o /dev/null -w "   project deleted: HTTP %{http_code}\n" -X DELETE -H "PRIVATE-TOKEN: $T" "$GL/api/v4/projects/$PID"
curl -sk -o /dev/null -w "   branch $B deleted: HTTP %{http_code}\n" -X DELETE -H "PRIVATE-TOKEN: $T" "$GL/api/v4/projects/parasol%2Fparasol-insurance/repository/branches/$B"
curl -sk -H "PRIVATE-TOKEN: $T" "$GL/api/v4/projects/parasol%2Fparasol-insurance/hooks" | jq -r --arg u "$U" '.[] | select(.url|test("el-secured-" + $u + "\\.")) | .id' \
  | while read -r hid; do curl -sk -o /dev/null -w "   webhook $hid deleted: HTTP %{http_code}\n" -X DELETE -H "PRIVATE-TOKEN: $T" "$GL/api/v4/projects/parasol%2Fparasol-insurance/hooks/$hid"; done
echo "== developer-portal key objects of $U"
oc delete apikey -n "kuadrant-${U}-lab" --all --ignore-not-found 2>/dev/null || true
oc get apikeyrequest,apikeyapproval -A -o json 2>/dev/null | jq -r --arg u "$U" '.items[] | select(.metadata.name|test("kuadrant-" + $u + "-lab")) | .kind + " " + .metadata.namespace + " " + .metadata.name' \
  | while read -r k n name; do oc delete "$k" "$name" -n "$n" --ignore-not-found; done
echo "== waiting for the namespace to go"; for i in $(seq 1 30); do oc get ns "$NS" >/dev/null 2>&1 || break; sleep 5; done
echo "Done. $U can run the template again (branch name must be new or the same: $B)."
