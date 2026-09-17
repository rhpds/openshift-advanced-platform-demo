#!/usr/bin/env bash
# Fix the Quay ("Image Registry") tab in Developer Hub.
# The operator's default mount point shows QuayPage on EVERY Component (if: isKind: component),
# and the plugin throws "'Quay' annotations are missing" on components without
# quay.io/repository-slug. Gate the card on the annotation instead (same pattern as Kiali),
# so the tab only appears where it can render. Restarts Developer Hub (~4 min).
# Requires scripts/rhdh-kuadrant/apply.sh first (it makes the RHDH ConfigMaps ours).
set -euo pipefail
NS=rhdh
cd "$(dirname "$0")"

oc get cm dynamic-plugins -n $NS -o jsonpath='{.data.dynamic-plugins\.yaml}' > dp.cur.yaml
python3 - <<'PYEOF'
import yaml
dp = yaml.safe_load(open('dp.cur.yaml'))
changed = False
for p in dp['plugins']:
    if not p.get('package', '').endswith('backstage-community-plugin-quay'):
        continue
    fe = p['pluginConfig']['dynamicPlugins']['frontend']['backstage-community.plugin-quay']
    for mp in fe.get('mountPoints', []):
        if mp.get('importName') != 'QuayPage':
            continue
        cond = mp.setdefault('config', {}).setdefault('if', {})
        if cond.get('allOf') != ['isQuayAvailable']:
            cond.clear(); cond['allOf'] = ['isQuayAvailable']; changed = True
if not changed:
    print('   quay mount point already gated on isQuayAvailable; nothing to do')
else:
    print('   quay mount point: if.allOf = [isQuayAvailable]')
open('dp.new.yaml', 'w').write(yaml.safe_dump(dp, sort_keys=False))
yaml.safe_load(open('dp.new.yaml')); print('   yaml ok')
PYEOF
if [ "${DRY_RUN:-0}" = "1" ]; then diff dp.cur.yaml dp.new.yaml || true; exit 0; fi
oc create cm dynamic-plugins -n $NS --from-file=dynamic-plugins.yaml=dp.new.yaml --dry-run=client -o yaml | oc apply -f -
oc label cm dynamic-plugins -n $NS app.kubernetes.io/name=backstage --overwrite >/dev/null
oc rollout restart deployment/backstage-developer-hub -n $NS
oc rollout status deployment/backstage-developer-hub -n $NS --timeout=900s | tail -1
echo "Done. 'Image Registry' tab now appears only on components with quay.io/repository-slug."
