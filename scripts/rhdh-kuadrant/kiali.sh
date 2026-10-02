#!/usr/bin/env bash
# Enable the Kiali (Service Mesh) plugin in Developer Hub: a "Service Mesh" tab on components
# annotated with kiali.io/namespace, and a Kiali page in the sidebar.
# The demo's Kiali uses auth.strategy=openshift, which the plugin cannot talk to ("Authentication
# failed. Not supported"), so this adds a SECOND, view-only Kiali instance (kiali-rhdh, same
# namespace, auth.strategy=token) and points the plugin at it with the RHDH service-account
# token the demo already provides (KUBERNETES_SA_TOKEN). The original Kiali is untouched.
# Requires scripts/rhdh-kuadrant/apply.sh first (it makes the RHDH ConfigMaps ours).
set -euo pipefail
NS=rhdh
cd "$(dirname "$0")"
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
KIALI="https://kiali-rhdh-istio-system.${D}"

echo "== Kiali instance for the plugin (kiali-rhdh, token auth, view-only)"
oc apply -f kiali-instance.yaml
for i in $(seq 1 30); do
  [ "$(oc get kiali kiali-rhdh -n istio-system -o jsonpath='{.status.conditions[?(@.type=="Successful")].status}' 2>/dev/null)" = True ] && break; sleep 10
done
oc rollout status deployment/kiali-rhdh -n istio-system --timeout=300s | tail -1

oc get cm dynamic-plugins -n $NS -o jsonpath='{.data.dynamic-plugins\.yaml}' > dp.cur.yaml
oc get cm app-config-rhdh -n $NS -o jsonpath='{.data.app-config-rhdh\.yaml}' > ac.cur.yaml
python3 - "$KIALI" <<'PYEOF'
import sys, yaml
kiali = sys.argv[1]
dp = open('dp.cur.yaml').read()
if 'backstage-community-plugin-kiali' not in dp:
    dp = dp.rstrip('\n') + '''

  # --- Kiali (Service Mesh) plugin: "Service Mesh" tab + /kiali page ---
  - package: 'oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-kiali-backend:bs_1.45.3__1.28.0'
    disabled: false
  - package: 'oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-kiali:bs_1.45.3__1.49.0'
    disabled: false
    pluginConfig:
      dynamicPlugins:
        frontend:
          backstage-community.plugin-kiali:
            appIcons:
              - name: kialiIcon
                importName: KialiIcon
            dynamicRoutes:
              - path: /kiali
                importName: KialiPage
                menuItem:
                  icon: kialiIcon
                  text: Service Mesh
            mountPoints:
              - mountPoint: entity.page.kiali/cards
                importName: EntityKialiContent
                config:
                  layout:
                    gridColumn: "1 / -1"
                  if:
                    allOf:
                      - hasAnnotation: kiali.io/namespace
            entityTabs:
              - path: /kiali
                title: Service Mesh
                mountPoint: entity.page.kiali
'''
open('dp.new.yaml', 'w').write(dp)
ac = open('ac.cur.yaml').read()
if '\nkiali:' not in ac:
    ac = ac.rstrip('\n') + f'''

# Kiali plugin: the demo's Kiali (OSSM 3) with the RHDH service-account token
kiali:
  providers:
    - name: default
      url: {kiali}
      serviceAccountToken: ${{KUBERNETES_SA_TOKEN}}
      skipTLSVerify: true
      sessionTime: 300
'''
open('ac.new.yaml', 'w').write(ac)
yaml.safe_load(open('dp.new.yaml')); yaml.safe_load(open('ac.new.yaml')); print('   yaml ok')
PYEOF
oc create cm dynamic-plugins -n $NS --from-file=dynamic-plugins.yaml=dp.new.yaml --dry-run=client -o yaml | oc apply -f -
oc create cm app-config-rhdh -n $NS --from-file=app-config-rhdh.yaml=ac.new.yaml --dry-run=client -o yaml | oc apply -f -
oc label cm dynamic-plugins app-config-rhdh -n $NS app.kubernetes.io/name=backstage --overwrite >/dev/null
# permission: the plugin declares kiali.view.read
oc get cm rbac-policy -n $NS -o jsonpath='{.data.rbac-policy\.csv}' > rb.cur.csv
grep -q 'kiali.view.read' rb.cur.csv || { echo 'p, role:default/plugins, kiali.view.read, read, allow' >> rb.cur.csv
  oc get cm rbac-policy -n $NS -o jsonpath='{.data.rbac-conditional-policies\.yaml}' > rbc.cur.yaml
  oc create cm rbac-policy -n $NS --from-file=rbac-policy.csv=rb.cur.csv --from-file=rbac-conditional-policies.yaml=rbc.cur.yaml --dry-run=client -o yaml | oc apply -f -
  oc label cm rbac-policy -n $NS app.kubernetes.io/name=backstage --overwrite >/dev/null; }
oc rollout restart deployment/backstage-developer-hub -n $NS
oc rollout status deployment/backstage-developer-hub -n $NS --timeout=900s | tail -1
POD=$(oc get pods -n $NS --no-headers | awk '/^backstage-developer-hub/ && $3=="Running"{print $1; exit}')
echo "   kiali plugin lines in backend log: $(oc logs "$POD" -n $NS -c backstage-backend 2>/dev/null | grep -ci kiali)"
echo "Done. Components with kiali.io/namespace get a 'Service Mesh' tab; sidebar gets 'Service Mesh'."
