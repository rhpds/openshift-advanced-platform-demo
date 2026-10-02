#!/usr/bin/env bash
# Enable the Kuadrant (Red Hat Connectivity Link) plugins in the demo's Developer Hub.
#
# Prereqs: RHCL operator + Kuadrant CR installed (see scripts/rhcl/), oc logged in as admin,
# python3 available. Run from the repo root:  bash scripts/rhdh-kuadrant/apply.sh
#
# What it changes (all in namespace rhdh, all reversible with rollback.sh):
#   - Argo CD app developer-hub-application: ignoreDifferences so selfHeal keeps our edits
#   - ConfigMap dynamic-plugins: RBAC plugin + Kuadrant frontend/backend (npm 0.4.0)
#   - ConfigMap app-config-rhdh: permission framework on, APIProduct catalog rule
#   - ConfigMap rbac-policy: Kuadrant roles + plugin permissions (existing demo policy kept)
#   - Backstage CR developer-hub: mount rbac-policy at /opt/app-root/etc
# The RHDH operator restarts Developer Hub automatically (npm install takes ~3 min).
#
# Changing rbac-policy later: the operator mounts the CSV with subPath, so the running pod
# never sees ConfigMap updates (policyFileReload cannot help). After editing the ConfigMap run
#   oc rollout restart deployment/backstage-developer-hub -n rhdh
# db-pool.sh must be run once after this script (PostgreSQL connection limit).
set -euo pipefail
cd "$(dirname "$0")"
NS=rhdh
BK=backup-$(date +%Y%m%d-%H%M%S); mkdir -p "$BK"
log() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

log "backup of current state -> $BK"
oc get cm dynamic-plugins -n $NS -o yaml > "$BK/cm-dynamic-plugins.yaml"
oc get cm app-config-rhdh -n $NS -o yaml > "$BK/cm-app-config-rhdh.yaml"
oc get cm rbac-policy -n $NS -o yaml > "$BK/cm-rbac-policy.yaml"
oc get backstage developer-hub -n $NS -o yaml > "$BK/backstage.yaml"
oc get application.argoproj.io developer-hub-application -n openshift-gitops -o yaml > "$BK/argo-app.yaml"

log "1. Argo CD: keep our edits (ignoreDifferences on the managed objects)"
oc patch application.argoproj.io developer-hub-application -n openshift-gitops --type=merge -p '{
  "spec": {"ignoreDifferences": [
    {"kind":"ConfigMap","name":"dynamic-plugins","namespace":"rhdh","jsonPointers":["/data"]},
    {"kind":"ConfigMap","name":"app-config-rhdh","namespace":"rhdh","jsonPointers":["/data"]},
    {"kind":"ConfigMap","name":"rbac-policy","namespace":"rhdh","jsonPointers":["/data"]},
    {"group":"rhdh.redhat.com","kind":"Backstage","name":"developer-hub","namespace":"rhdh","jsonPointers":["/spec/application/extraFiles","/spec/deployment"]}
  ]}}'

log "2. build new ConfigMap contents"
oc get cm dynamic-plugins -n $NS -o jsonpath='{.data.dynamic-plugins\.yaml}' > dp.cur.yaml
oc get cm app-config-rhdh -n $NS -o jsonpath='{.data.app-config-rhdh\.yaml}' > ac.cur.yaml
oc get cm rbac-policy -n $NS -o jsonpath='{.data.rbac-policy\.csv}' > rb.cur.csv
oc get cm rbac-policy -n $NS -o jsonpath='{.data.rbac-conditional-policies\.yaml}' > rbc.cur.yaml
python3 - <<'EOF'
import re
dp=open('dp.cur.yaml').read()
if 'kuadrant-backstage-plugin-frontend' not in dp:
    dp=dp.rstrip('\n')+'\n'+open('dynamic-plugins.fragment.yaml').read()
open('dp.new.yaml','w').write(dp)

ac=open('ac.cur.yaml').read()
ac=re.sub(r'^(\s*- allow: \[Component, System, API), (Resource, Location, Template, Domain\])$', r'\1, APIProduct, \2', ac, flags=re.M)
if '\npermission:' not in ac:
    ac=ac.rstrip('\n')+'\n'+open('app-config.fragment.yaml').read()
open('ac.new.yaml','w').write(ac)

rb=[l.rstrip() for l in open('rb.cur.csv').read().splitlines() if l.strip()]
have=set(rb)
for l in open('rbac-policy.fragment.csv').read().splitlines():
    l=l.rstrip()
    if l and l not in have: rb.append(l)
open('rb.new.csv','w').write('\n'.join(rb)+'\n')
import yaml; yaml.safe_load(open('dp.new.yaml')); yaml.safe_load(open('ac.new.yaml')); print('   yaml ok')
EOF

log "3. apply ConfigMaps"
oc create cm dynamic-plugins -n $NS --from-file=dynamic-plugins.yaml=dp.new.yaml --dry-run=client -o yaml | oc apply -f -
oc create cm app-config-rhdh -n $NS --from-file=app-config-rhdh.yaml=ac.new.yaml --dry-run=client -o yaml | oc apply -f -
oc create cm rbac-policy -n $NS --from-file=rbac-policy.csv=rb.new.csv --from-file=rbac-conditional-policies.yaml=rbc.cur.yaml --dry-run=client -o yaml | oc apply -f -
oc label cm dynamic-plugins app-config-rhdh rbac-policy -n $NS app.kubernetes.io/name=backstage --overwrite >/dev/null

log "4. Backstage CR: mount the RBAC policy files and the in-cluster SA token"
oc patch backstage developer-hub -n $NS --type=merge -p '{
  "spec": {
    "application": {"extraFiles": {"mountPath": "/opt/app-root/etc", "configMaps": [{"name": "rbac-policy"}]}},
    "deployment": {"patch": {"spec": {"template": {"spec": {"automountServiceAccountToken": true}}}}}
  }}'

log "5. wait for Developer Hub to come back (npm install of the plugins takes a few minutes)"
sleep 20
oc rollout status deployment/backstage-developer-hub -n $NS --timeout=900s
POD=$(oc get pods -n $NS --no-headers | awk '/^backstage-developer-hub/ && $3=="Running"{print $1; exit}')
echo "   plugins loaded:"; oc logs "$POD" -n $NS -c backstage-backend 2>/dev/null | grep -oE 'kuadrant[a-z-]*|plugin-rbac[a-z-]*' | sort | uniq -c | head
DOMAIN=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
printf '   rhdh: %s   login: %s\n' "$(curl -sk -o /dev/null -w '%{http_code}' https://backstage-developer-hub-rhdh.$DOMAIN/)" "$(curl -sk -o /dev/null -w '%{http_code}' "https://backstage-developer-hub-rhdh.$DOMAIN/api/auth/oidc/start?env=production")"
echo; echo "Done. Sign in as pe1: 'Connectivity Link' appears in the sidebar; API entities get Kuadrant tabs."
