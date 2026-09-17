#!/usr/bin/env bash
# Enable the Advanced Cluster Security (ACS) plugin in Developer Hub: a "Security" tab on components
# annotated with acs/deployment-name, showing workload CVEs from ACS Central.
# The plugin is frontend-only and is NOT bundled in the RHDH 1.9 image, so it comes from the official
# plugin export overlays (OCI), pinned to this RHDH's Backstage version (1.45.3). It talks to Central
# through the backend proxy (/api/proxy/acs) with an ACS API token that this script generates.
#   1. ACS API token (role Analyst, read-only) -> Secret rhdh/acs-secret (ACS_API_URL, ACS_API_KEY)
#   2. Backstage CR: extraEnvs.secrets += acs-secret (Argo told to ignore extraEnvs, like the ConfigMaps)
#   3. dynamic-plugins: the plugin + "Security" tab;  app-config: proxy /acs + acs.acsUrl
#   4. catalog: acs/deployment-name on the parasol components (rhdh-templates entities/components.yaml)
# Restarts Developer Hub (~4 min). Requires scripts/rhdh-kuadrant/apply.sh first (it makes the RHDH
# ConfigMaps ours). DRY_RUN=1 prints the diffs and touches nothing.
set -euo pipefail
NS=rhdh
cd "$(dirname "$0")"
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
CENTRAL="https://central-stackrox.${D}"
GL="https://gitlab-gitlab.${D}"
PLUGIN='oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-acs:bs_1.45.3__0.1.1!backstage-community-plugin-acs'
DRY="${DRY_RUN:-0}"
run() { if [ "$DRY" = "1" ]; then echo "   [dry-run] $*"; else "$@"; fi; }

echo "== 1. ACS API token -> Secret $NS/acs-secret"
if oc get secret acs-secret -n $NS >/dev/null 2>&1; then
  echo "   acs-secret already exists; keeping it"
elif [ "$DRY" = "1" ]; then
  echo "   [dry-run] would generate token 'rhdh-developer-hub' (role Analyst) on $CENTRAL and create the secret"
else
  PW=$(oc get secret central-admin-password -n stackrox -o jsonpath='{.data.password}' | base64 -d)
  RESP=$(curl -sk -u "admin:$PW" -H 'Content-Type: application/json' -X POST "$CENTRAL/v1/apitokens/generate" \
          -d '{"name":"rhdh-developer-hub-'"$(date +%s)"'","roles":["Analyst"]}')
  TOKEN=$(printf '%s' "$RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))' 2>/dev/null || true)
  [ -n "$TOKEN" ] || { echo "token generation failed. Central answered:"; echo "$RESP" | head -c 600; echo; exit 1; }
  oc create secret generic acs-secret -n $NS --from-literal=ACS_API_URL="$CENTRAL" --from-literal=ACS_API_KEY="$TOKEN"
  oc label secret acs-secret -n $NS app.kubernetes.io/name=backstage --overwrite >/dev/null
fi

echo "== 2. Backstage CR: inject acs-secret (and keep Argo CD from reverting extraEnvs)"
# select the Backstage CR entry by kind (not by list position, which differs between instances)
IGN=$(oc get application.argoproj.io developer-hub-application -n openshift-gitops -o json | jq -c '
  [ (.spec.ignoreDifferences // [])[] | if .kind == "Backstage" then .jsonPointers = (((.jsonPointers // []) + ["/spec/application/extraEnvs"]) | unique) else . end ]')
run oc patch application.argoproj.io developer-hub-application -n openshift-gitops --type merge -p "{\"spec\":{\"ignoreDifferences\":$IGN}}"
if oc get backstage developer-hub -n $NS -o jsonpath='{.spec.application.extraEnvs.secrets[*].name}' | grep -qw acs-secret; then
  echo "   acs-secret already in extraEnvs"
else
  run oc patch backstage developer-hub -n $NS --type=json -p '[{"op":"add","path":"/spec/application/extraEnvs/secrets/-","value":{"name":"acs-secret"}}]'
fi

echo "== 3. dynamic-plugins + app-config"
oc get cm dynamic-plugins -n $NS -o jsonpath='{.data.dynamic-plugins\.yaml}' > dp.cur.yaml
oc get cm app-config-rhdh -n $NS -o jsonpath='{.data.app-config-rhdh\.yaml}' > ac.cur.yaml
python3 - "$PLUGIN" "$CENTRAL" <<'PYEOF'
import sys, yaml
plugin, central = sys.argv[1], sys.argv[2]
dp = yaml.safe_load(open('dp.cur.yaml'))
if any(p.get('package', '').split('!')[-1].endswith('backstage-community-plugin-acs') for p in dp['plugins']):
    print('   dynamic-plugins: ACS plugin already present')
else:
    dp['plugins'].append({
        'package': plugin, 'disabled': False,
        'pluginConfig': {'dynamicPlugins': {'frontend': {'backstage-community.plugin-acs': {
            'mountPoints': [{'mountPoint': 'entity.page.security/cards', 'importName': 'EntityACSContent',
                             'config': {'layout': {'gridColumn': '1 / -1'},
                                        'if': {'allOf': [{'hasAnnotation': 'acs/deployment-name'}]}}}],
            'entityTabs': [{'path': '/security', 'title': 'Security', 'mountPoint': 'entity.page.security'}]}}}}})
    print('   dynamic-plugins: ACS plugin added')
open('dp.new.yaml', 'w').write(yaml.safe_dump(dp, sort_keys=False))

ac = open('ac.cur.yaml').read()
if "'/acs':" not in ac:
    # proxy endpoint goes next to the existing ones (after /quay/api); acs stanza at the end
    marker = "    '/quay/api':"
    assert marker in ac, "proxy '/quay/api' endpoint not found in app-config"
    proxy = """    '/acs':
      target: ${ACS_API_URL}
      headers:
        authorization: 'Bearer ${ACS_API_KEY}'
      changeOrigin: true
      secure: false
"""
    ac = ac.replace(marker, proxy + marker, 1)
    ac = ac.rstrip('\n') + f'''

# ACS plugin: Central URL for the links; data goes through proxy /acs with the API token
acs:
  acsUrl: ${{ACS_API_URL}}
'''
    print('   app-config: proxy /acs + acs.acsUrl added')
else:
    print('   app-config: /acs already present')
open('ac.new.yaml', 'w').write(ac)
yaml.safe_load(open('dp.new.yaml')); yaml.safe_load(open('ac.new.yaml')); print('   yaml ok')
PYEOF
if [ "$DRY" = "1" ]; then
  diff dp.cur.yaml dp.new.yaml || true; diff ac.cur.yaml ac.new.yaml || true
  echo "   [dry-run] would apply ConfigMaps dynamic-plugins and app-config-rhdh"
else
  oc create cm dynamic-plugins -n $NS --from-file=dynamic-plugins.yaml=dp.new.yaml --dry-run=client -o yaml | oc apply -f -
  oc create cm app-config-rhdh -n $NS --from-file=app-config-rhdh.yaml=ac.new.yaml --dry-run=client -o yaml | oc apply -f -
  oc label cm dynamic-plugins app-config-rhdh -n $NS app.kubernetes.io/name=backstage --overwrite >/dev/null
fi

echo "== 4. catalog: acs/deployment-name on the parasol components"
T=$(oc get secret root-user-personal-token -n gitlab -o jsonpath='{.data.token}' | base64 -d)
REPO=rhdh%2Frhdh-templates; FILE=entities%2Fcomponents.yaml
curl -sk -H "PRIVATE-TOKEN: $T" "$GL/api/v4/projects/$REPO/repository/files/$FILE/raw?ref=main" > components.remote.yaml
if grep -q 'acs/deployment-name' components.remote.yaml; then
  echo "   annotation already present"
else
  # deployment name == component name in both prod namespaces (parasol-insurance, parasol-insurance-secured)
  awk '{print} /^    kiali.io\/namespace: (parasol-insurance|parasol-insurance-secured)-prod$/ {n=$2; sub(/-prod$/,"",n); print "    acs/deployment-name: " n}' \
    components.remote.yaml > components.acs.yaml
  diff components.remote.yaml components.acs.yaml || true
  if [ "$DRY" = "1" ]; then echo "   [dry-run] would commit entities/components.yaml"; else
    code=$(curl -sk -o /tmp/gl_put.out -w '%{http_code}' -H "PRIVATE-TOKEN: $T" -X PUT "$GL/api/v4/projects/$REPO/repository/files/$FILE" \
      --data-urlencode branch=main --data-urlencode "content@components.acs.yaml" \
      --data-urlencode "commit_message=catalog: acs/deployment-name on the parasol components (ACS Security tab)")
    [ "$code" = "200" ] || { echo "commit failed ($code): $(cat /tmp/gl_put.out)"; exit 1; }
    echo "   components.yaml committed"
  fi
fi
[ "$DRY" = "1" ] && exit 0

echo "== 5. restart Developer Hub"
oc rollout restart deployment/backstage-developer-hub -n $NS
oc rollout status deployment/backstage-developer-hub -n $NS --timeout=900s | tail -1
POD=$(oc get pods -n $NS --no-headers | awk '/^backstage-developer-hub/ && $3=="Running"{print $1; exit}')
echo "   acs plugin lines in backend log: $(oc logs "$POD" -n $NS -c backstage-backend 2>/dev/null | grep -ci 'plugin-acs')"
echo "Done. parasol-insurance and parasol-insurance-secured get a 'Security' tab (catalog refresh: ~2 min)."
