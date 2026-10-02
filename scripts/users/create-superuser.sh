#!/usr/bin/env bash
# Create a "super user" persona across every identity system of the demo instance:
#   Keycloak (SSO realm backstage: console via the "developers" IdP, RHDH, GitLab OIDC if used),
#   OpenShift (cluster-admin), GitLab (admin + owner of the demo groups), Developer Hub
#   (RBAC superUser + admin) and the demo groups (platformengineers, developers, devteam1, rhdh).
#
#   bash scripts/users/create-superuser.sh tanaka "Sandro" "Tanaka" tanaka@rhdemo.com
#
# Password: the instance's common password (the same one dev1/pe1 use), read from the demo's
# Vault-synced secrets. Idempotent. Needs cluster admin (oc) and the RHDH Kuadrant layer's
# app-config ownership (scripts/rhdh-kuadrant/apply.sh) for the RBAC part.
set -euo pipefail
U=${1:?usage: create-superuser.sh <username> <first> <last> <email>}; F=${2:?}; L=${3:?}; E=${4:?}
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
GL="https://gitlab-gitlab.${D}"
PW=$(oc get secret keycloak-realm-users -n keycloak -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)
[ -n "$PW" ] || PW=$(oc get secret gitlab-secret -n gitlab -o jsonpath='{.data.GITLAB_ROOT_PASSWORD}' | base64 -d)
log() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

log "1. Keycloak realm backstage: user $U in platformengineers, developers, devteam1, rhdh"
oc exec keycloak-0 -n keycloak -- sh -c '
  cd /opt/keycloak/bin; C=/tmp/kcadm.config
  ./kcadm.sh config credentials --config $C --server http://localhost:8080 --realm master --user "$KEYCLOAK_ADMIN" --password "$KEYCLOAK_ADMIN_PASSWORD" >/dev/null
  U='"$U"'; ID=$(./kcadm.sh get users --config $C -r backstage -q username=$U --fields id 2>/dev/null | grep -oE "[0-9a-f-]{36}" | head -1)
  if [ -z "$ID" ]; then
    ./kcadm.sh create users --config $C -r backstage -s username=$U -s firstName="'"$F"'" -s lastName="'"$L"'" -s email="'"$E"'" -s enabled=true -s emailVerified=true >/dev/null
    ID=$(./kcadm.sh get users --config $C -r backstage -q username=$U --fields id | grep -oE "[0-9a-f-]{36}" | head -1)
    echo "   created $U ($ID)"
  else echo "   $U exists ($ID)"; fi
  ./kcadm.sh set-password --config $C -r backstage --username $U --new-password "'"$PW"'" >/dev/null && echo "   password set (common password)"
  for G in platformengineers developers devteam1 rhdh; do
    GID=$(./kcadm.sh get groups --config $C -r backstage -q search=$G --fields id,name | tr -d "\n " | grep -oE "\{\"id\":\"[0-9a-f-]{36}\",\"name\":\"$G\"\}" | grep -oE "[0-9a-f-]{36}" | head -1)
    [ -n "$GID" ] && ./kcadm.sh update users/$ID/groups/$GID --config $C -r backstage -s realm=backstage -s userId=$ID -s groupId=$GID -n >/dev/null && echo "   member of $G"
  done' 2>&1 | grep -vE 'recorded in container|command prompt'

log "2. OpenShift: cluster-admin for $U (identity provider 'developers')"
oc adm policy add-cluster-role-to-user cluster-admin "$U" >/dev/null && echo "   cluster-admin bound"

log "3. GitLab: admin user $U, owner of parasol, rhdh, devteam1"
T=$(oc get secret root-user-personal-token -n gitlab -o jsonpath='{.data.token}' | base64 -d)
UID_=$(curl -sk -H "PRIVATE-TOKEN: $T" "$GL/api/v4/users?username=$U" | jq -r '.[0].id // empty')
if [ -z "$UID_" ]; then
  UID_=$(curl -sk -H "PRIVATE-TOKEN: $T" -X POST "$GL/api/v4/users" --data-urlencode "username=$U" --data-urlencode "name=$F $L" --data-urlencode "email=$E" --data-urlencode "password=$PW" --data-urlencode "admin=true" --data-urlencode "skip_confirmation=true" | jq -r '.id')
  echo "   created (id $UID_)"
else echo "   exists (id $UID_)"; fi
for g in parasol rhdh devteam1; do
  gid=$(curl -sk -H "PRIVATE-TOKEN: $T" "$GL/api/v4/groups?search=$g" | jq -r ".[] | select(.path==\"$g\") | .id")
  code=$(curl -sk -o /dev/null -w '%{http_code}' -H "PRIVATE-TOKEN: $T" -X POST "$GL/api/v4/groups/$gid/members" --data user_id=$UID_ --data access_level=50)
  echo "   owner of $g (HTTP $code)"
done

log "4. Developer Hub: superUser + RBAC admin (app-config), then restart"
oc get cm app-config-rhdh -n rhdh -o jsonpath='{.data.app-config-rhdh\.yaml}' > /tmp/ac.yaml
if ! grep -q "user:default/$U" /tmp/ac.yaml; then
  python3 - "$U" <<'PYEOF'
import sys,re
u=sys.argv[1]; s=open('/tmp/ac.yaml').read()
# admin.users: add; superUsers: create or add
s=re.sub(r'(    admin:\n      users:\n)', r'\1        - name: user:default/%s\n' % u, s, count=1)
if 'superUsers:' in s:
    s=re.sub(r'(      superUsers:\n)', r'\1        - name: user:default/%s\n' % u, s, count=1)
else:
    s=re.sub(r'(    admin:\n      users:\n(?:        - name: [^\n]+\n)+)', r'\1      superUsers:\n        - name: user:default/%s\n' % u, s, count=1)
open('/tmp/ac.yaml','w').write(s)
PYEOF
  oc create cm app-config-rhdh -n rhdh --from-file=app-config-rhdh.yaml=/tmp/ac.yaml --dry-run=client -o yaml | oc apply -f - >/dev/null
  oc label cm app-config-rhdh -n rhdh app.kubernetes.io/name=backstage --overwrite >/dev/null
  oc rollout restart deployment/backstage-developer-hub -n rhdh >/dev/null
  oc rollout status deployment/backstage-developer-hub -n rhdh --timeout=600s | tail -1
else echo "   already a superUser"; fi
echo
echo "Done. $U signs in everywhere with the common password: console (developers IdP), GitLab, Developer Hub."
echo "Developer Hub imports the user from Keycloak within 2 minutes (keycloakOrg provider)."
