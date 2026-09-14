#!/usr/bin/env bash
# A discreet "Webinar" card at the top of the Developer Hub home page (presenter signature).
# The home page comes from the operator's default dynamic-plugins list; to add a card we copy that
# plugin's default block (read from the running pod, so it follows the RHDH version) into our
# dynamic-plugins ConfigMap and prepend a MarkdownCard. Restarts Developer Hub (~4 min).
#   bash scripts/rhdh-kuadrant/home-card.sh            # add/update the card
#   bash scripts/rhdh-kuadrant/home-card.sh delete     # remove the block (defaults come back)
set -euo pipefail
NS=rhdh; cd "$(dirname "$0")"
TITLE=${TITLE:-Webinar}
CONTENT=${CONTENT:-'**Como turbinar sua Engenharia de Plataforma com IA** &nbsp;·&nbsp; demo por Sandro Tanaka'}
oc get cm dynamic-plugins -n $NS -o jsonpath='{.data.dynamic-plugins\.yaml}' > dp.cur.yaml
POD=$(oc get pods -n $NS --no-headers | awk '/^backstage-developer-hub/ && $3=="Running"{print $1; exit}')
oc exec "$POD" -n $NS -c backstage-backend -- cat /opt/app-root/src/dynamic-plugins.default.yaml > dp.default.yaml
python3 - "${1:-}" "$TITLE" "$CONTENT" <<'PYEOF'
import sys, yaml, re
mode, title, content = (sys.argv[1] if len(sys.argv) > 1 else ''), sys.argv[2], sys.argv[3]
dp = yaml.safe_load(open('dp.cur.yaml')); plugins = dp.setdefault('plugins', [])
PKG = './dynamic-plugins/dist/red-hat-developer-hub-backstage-plugin-dynamic-home-page'
plugins = [p for p in plugins if p.get('package') != PKG]
if mode != 'delete':
    default = next(p for p in yaml.safe_load(open('dp.default.yaml'))['plugins'] if p.get('package') == PKG)
    fe = default['pluginConfig']['dynamicPlugins']['frontend']['red-hat-developer-hub.backstage-plugin-dynamic-home-page']
    card = {'mountPoint': 'home.page/cards', 'importName': 'MarkdownCard',
            'config': {'layouts': {k: {'w': 12, 'h': 1} for k in ('xl', 'lg', 'md', 'sm', 'xs', 'xxs')},
                       'props': {'title': title, 'content': content}}}
    fe['mountPoints'] = [m for m in fe['mountPoints'] if m.get('importName') != 'MarkdownCard']
    listener = [m for m in fe['mountPoints'] if m.get('mountPoint') == 'application/listener']
    cards = [m for m in fe['mountPoints'] if m.get('mountPoint') != 'application/listener']
    fe['mountPoints'] = listener + [card] + cards
    default['disabled'] = False
    plugins.append(default)
dp['plugins'] = plugins
open('dp.new.yaml', 'w').write(yaml.safe_dump(dp, sort_keys=False, allow_unicode=True))
print('   home page block', 'removed' if mode == 'delete' else 'added with the Webinar card')
PYEOF
oc create cm dynamic-plugins -n $NS --from-file=dynamic-plugins.yaml=dp.new.yaml --dry-run=client -o yaml | oc apply -f - >/dev/null
oc label cm dynamic-plugins -n $NS app.kubernetes.io/name=backstage --overwrite >/dev/null
oc rollout restart deployment/backstage-developer-hub -n $NS >/dev/null
oc rollout status deployment/backstage-developer-hub -n $NS --timeout=900s | tail -1
