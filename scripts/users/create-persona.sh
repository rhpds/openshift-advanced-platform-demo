#!/usr/bin/env bash
# Create a demo persona (developer or platform engineer) across the identity systems of the
# instance, mirroring what dev1 / pe1 have, plus an avatar shown in Developer Hub's header:
#   Keycloak (realm backstage): user, common password, groups, attribute "picture"
#     dev: developers + devteam1          pe: platformengineers + rhdh
#   OpenShift: dev -> admin on parasol-insurance-{build,dev,prod}; pe -> cluster-admin (as pe1)
#   GitLab: user; dev -> owner of devteam1 + parasol; pe -> owner of rhdh + parasol
#   Developer Hub: pe -> RBAC admin (app-config); the avatar comes from the OIDC "picture" claim
#     (Keycloak's profile scope maps the user attribute), served from a public GitLab project
#     rhdh/avatars, which the app-config CSP img-src must allow (added here, needs one restart).
#
#   bash scripts/users/create-persona.sh <username> <first> <last> <email> <dev|pe> [avatar.svg]
#   e.g. bash scripts/users/create-persona.sh tanaka-dev "Tanaka" "Developer" tanaka-dev@rhdemo.com dev scripts/users/avatars/tanaka-dev.svg
#
# Idempotent. NO_RESTART=1 skips the Developer Hub restart (run it once after the last persona).
set -euo pipefail
U=${1:?usage: create-persona.sh <username> <first> <last> <email> <dev|pe> [avatar.svg]}; F=${2:?}; L=${3:?}; E=${4:?}; ROLE=${5:?dev|pe}; AVATAR=${6:-}
case "$ROLE" in dev) KGROUPS="developers devteam1"; GLGROUPS="devteam1 parasol";; pe) KGROUPS="platformengineers rhdh"; GLGROUPS="rhdh parasol";; *) echo "role must be dev or pe"; exit 1;; esac
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
GL="https://gitlab-gitlab.${D}"
PW=$(oc get secret keycloak-realm-users -n keycloak -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)
[ -n "$PW" ] || PW=$(oc get secret gitlab-secret -n gitlab -o jsonpath='{.data.GITLAB_ROOT_PASSWORD}' | base64 -d)
T=$(oc get secret root-user-personal-token -n gitlab -o jsonpath='{.data.token}' | base64 -d)
log() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }
PIC=""

if [ -n "$AVATAR" ]; then
  log "0. Avatar: public GitLab project rhdh/avatars"
  PID=$(curl -sk -H "PRIVATE-TOKEN: $T" "$GL/api/v4/projects/rhdh%2Favatars" | jq -r '.id // empty')
  if [ -z "$PID" ]; then
    NSID=$(curl -sk -H "PRIVATE-TOKEN: $T" "$GL/api/v4/groups?search=rhdh" | jq -r '.[] | select(.path=="rhdh") | .id')
    PID=$(curl -sk -H "PRIVATE-TOKEN: $T" -X POST "$GL/api/v4/projects" --data-urlencode "name=avatars" --data-urlencode "namespace_id=$NSID" --data-urlencode "visibility=public" --data-urlencode "initialize_with_readme=true" --data-urlencode "description=Avatars of the demo personas (Developer Hub header)" | jq -r '.id')
    echo "   created project rhdh/avatars ($PID)"
  fi
  FN=$(basename "$AVATAR")
  B64=$(base64 < "$AVATAR" | tr -d '\n')
  ACT=$(curl -sk -o /dev/null -w '%{http_code}' -H "PRIVATE-TOKEN: $T" "$GL/api/v4/projects/$PID/repository/files/$FN?ref=main")
  [ "$ACT" = 200 ] && ACT=update || ACT=create
  jq -n --arg a "$ACT" --arg f "$FN" --arg c "$B64" '{branch:"main",commit_message:("avatar " + $f),actions:[{action:$a,file_path:$f,content:$c,encoding:"base64"}]}' \
    | curl -sk -o /dev/null -w "   $FN pushed (HTTP %{http_code})\n" -H "PRIVATE-TOKEN: $T" -H 'Content-Type: application/json' -X POST "$GL/api/v4/projects/$PID/repository/commits" --data @-
  PIC="$GL/rhdh/avatars/-/raw/main/$FN"
  curl -sk -o /dev/null -w "   public URL answers HTTP %{http_code}\n" "$PIC"
fi

log "1. Keycloak realm backstage: user $U ($ROLE: $KGROUPS)"
# the realm uses a declarative user profile: "picture" must be a managed attribute (admin-only,
# so it never shows on the account forms) or updates silently drop it
oc exec keycloak-0 -n keycloak -- sh -c 'cd /opt/keycloak/bin; C=/tmp/kcadm.config; ./kcadm.sh config credentials --config $C --server http://localhost:8080 --realm master --user "$KEYCLOAK_ADMIN" --password "$KEYCLOAK_ADMIN_PASSWORD" >/dev/null; ./kcadm.sh get users/profile --config $C -r backstage' 2>/dev/null \
  | python3 -c '
import json,sys
p=json.load(sys.stdin)
if not any(a["name"]=="picture" for a in p["attributes"]):
    p["attributes"].append({"name":"picture","displayName":"Picture (avatar URL)","permissions":{"view":["admin"],"edit":["admin"]},"multivalued":False})
print(json.dumps(p))' \
  | oc exec -i keycloak-0 -n keycloak -- sh -c 'cat > /tmp/up.json; cd /opt/keycloak/bin; ./kcadm.sh update users/profile --config /tmp/kcadm.config -r backstage -f /tmp/up.json' 2>&1 | grep -vE 'recorded|prompt|Logging' || true
# full representation: a partial PUT wipes the other fields (names, e-mail) and forces VERIFY_PROFILE at login
python3 -c 'import json,sys; u,f,l,e,pic=sys.argv[1:]; print(json.dumps({"username":u,"firstName":f,"lastName":l,"email":e,"enabled":True,"emailVerified":True,"requiredActions":[],"attributes":({"picture":[pic]} if pic else {})}))' "$U" "$F" "$L" "$E" "$PIC" \
  | oc exec -i keycloak-0 -n keycloak -- sh -c '
  cat > /tmp/u.json; cd /opt/keycloak/bin; C=/tmp/kcadm.config
  U='"$U"'; ID=$(./kcadm.sh get users --config $C -r backstage -q username=$U --fields id 2>/dev/null | grep -oE "[0-9a-f-]{36}" | head -1)
  if [ -z "$ID" ]; then
    ./kcadm.sh create users --config $C -r backstage -f /tmp/u.json >/dev/null
    ID=$(./kcadm.sh get users --config $C -r backstage -q username=$U --fields id | grep -oE "[0-9a-f-]{36}" | head -1)
    echo "   created $U ($ID)"
  else ./kcadm.sh update users/$ID --config $C -r backstage -f /tmp/u.json && echo "   $U updated ($ID)"; fi
  ./kcadm.sh set-password --config $C -r backstage --username $U --new-password "'"$PW"'" >/dev/null && echo "   password set (common password)"
  for G in '"$KGROUPS"'; do
    GID=$(./kcadm.sh get groups --config $C -r backstage -q search=$G --fields id,name | tr -d "\n " | grep -oE "\{\"id\":\"[0-9a-f-]{36}\",\"name\":\"$G\"\}" | grep -oE "[0-9a-f-]{36}" | head -1)
    [ -n "$GID" ] && ./kcadm.sh update users/$ID/groups/$GID --config $C -r backstage -s realm=backstage -s userId=$ID -s groupId=$GID -n >/dev/null && echo "   member of $G"
  done' 2>&1 | grep -vE 'recorded in container|command prompt|Logging into'

log "2. OpenShift"
if [ "$ROLE" = pe ]; then
  oc adm policy add-cluster-role-to-user cluster-admin "$U" >/dev/null && echo "   cluster-admin bound (as pe1)"
else
  for ns in parasol-insurance-build parasol-insurance-dev parasol-insurance-prod; do
    oc create rolebinding "$U-admin" -n $ns --clusterrole=admin --user="$U" --dry-run=client -o yaml | oc apply -f - >/dev/null; done
  echo "   admin on parasol-insurance-build/dev/prod (as dev1)"
fi

log "3. GitLab: user $U, owner of $GLGROUPS"
UID_=$(curl -sk -H "PRIVATE-TOKEN: $T" "$GL/api/v4/users?username=$U" | jq -r '.[0].id // empty')
if [ -z "$UID_" ]; then
  UID_=$(curl -sk -H "PRIVATE-TOKEN: $T" -X POST "$GL/api/v4/users" --data-urlencode "username=$U" --data-urlencode "name=$F $L" --data-urlencode "email=$E" --data-urlencode "password=$PW" --data-urlencode "skip_confirmation=true" | jq -r '.id')
  echo "   created (id $UID_)"
else echo "   exists (id $UID_)"; fi
# GitLab avatars must be raster: a .png next to the .svg is used when present
PNG="${AVATAR%.svg}.png"; [ -n "$AVATAR" ] && [ -f "$PNG" ] && curl -sk -o /dev/null -w "   GitLab avatar set (HTTP %{http_code})\n" -H "PRIVATE-TOKEN: $T" -X PUT "$GL/api/v4/users/$UID_" -F "avatar=@$PNG" || true
for g in $GLGROUPS; do
  gid=$(curl -sk -H "PRIVATE-TOKEN: $T" "$GL/api/v4/groups?search=$g" | jq -r ".[] | select(.path==\"$g\") | .id")
  code=$(curl -sk -o /dev/null -w '%{http_code}' -H "PRIVATE-TOKEN: $T" -X POST "$GL/api/v4/groups/$gid/members" --data user_id=$UID_ --data access_level=50)
  echo "   owner of $g (HTTP $code)"
done

log "4. Developer Hub app-config: CSP for the avatars$([ "$ROLE" = pe ] && echo ", RBAC admin $U")"
oc get cm app-config-rhdh -n rhdh -o jsonpath='{.data.app-config-rhdh\.yaml}' > /tmp/ac.yaml
python3 - "$U" "$ROLE" "$GL" <<'PYEOF'
import sys, re
u, role, gl = sys.argv[1:4]; s = open('/tmp/ac.yaml').read(); changed = False
if gl not in s.split('csp:')[1].split('\n\n')[0] if 'csp:' in s else True:
    s = re.sub(r'(  csp:\n(?:    [^\n]*\n)*?    img-src:\n(?:      - [^\n]*\n)+)', lambda m: m.group(1) + '      - "%s"\n' % gl, s, count=1); changed = True
if role == 'pe' and ('user:default/%s' % u) not in s:
    s = re.sub(r'(    admin:\n      users:\n)', r'\1        - name: user:default/%s\n' % u, s, count=1); changed = True
open('/tmp/ac.yaml', 'w').write(s); open('/tmp/ac.changed', 'w').write('1' if changed else '')
PYEOF
if [ -n "$(cat /tmp/ac.changed)" ]; then
  oc create cm app-config-rhdh -n rhdh --from-file=app-config-rhdh.yaml=/tmp/ac.yaml --dry-run=client -o yaml | oc apply -f - >/dev/null
  oc label cm app-config-rhdh -n rhdh app.kubernetes.io/name=backstage --overwrite >/dev/null
  echo "   app-config updated"
  if [ "${NO_RESTART:-0}" = 1 ]; then echo "   restart skipped (NO_RESTART=1)"; else
    oc rollout restart deployment/backstage-developer-hub -n rhdh >/dev/null
    oc rollout status deployment/backstage-developer-hub -n rhdh --timeout=600s | tail -1; fi
else echo "   nothing to change"; fi
echo
echo "Done. $U ($F $L) signs in with the common password. Developer Hub imports the user from Keycloak within 2 minutes."
