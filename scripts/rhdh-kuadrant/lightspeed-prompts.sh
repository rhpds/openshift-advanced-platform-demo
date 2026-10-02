#!/usr/bin/env bash
# Developer Lightspeed: replace the suggestion cards with the three questions of the webinar
# journey (discover the service, pick the Golden Path, understand what the platform automates).
# The cards are app-config lightspeed.prompts; the demo's default cards ask for Java snippets and
# rotate in unrelated ones (OAuth docs). Language: pt-BR (the audience); set LANG_EN=1 for English.
#   bash scripts/rhdh-kuadrant/lightspeed-prompts.sh            # apply + restart Developer Hub
#   NO_RESTART=1 bash scripts/rhdh-kuadrant/lightspeed-prompts.sh
set -euo pipefail
oc get cm app-config-rhdh -n rhdh -o jsonpath='{.data.app-config-rhdh\.yaml}' > /tmp/ac.yaml
python3 - "${LANG_EN:-0}" <<'PYEOF'
import sys, re, yaml
en = sys.argv[1] == '1'
s = open('/tmp/ac.yaml').read()
prompts_pt = [
  ("Conhecer o Parasol Insurance", "Quais componentes formam o sistema parasol-insurance neste catálogo, quem é o dono de cada um e quais APIs eles fornecem?"),
  ("Começar uma nova feature", "Sou novo no time. Qual software template devo usar para começar uma nova feature da aplicação Parasol Insurance e o que ele cria para mim?"),
  ("O que a plataforma automatiza", "Quando eu executo o template de nova feature do Parasol Insurance, o que a plataforma faz automaticamente por mim (pipeline, GitOps, catálogo) e onde acompanho o resultado?"),
]
prompts_en = [
  ("Get to know Parasol Insurance", "Which components make up the parasol-insurance system in this catalog, who owns each one and which APIs do they provide?"),
  ("Start a new feature", "I am new to the team. Which software template should I use to start a new feature of the Parasol Insurance application, and what will it create for me?"),
  ("What the platform automates", "When I run the Parasol Insurance new-feature template, what does the platform do for me automatically (pipeline, GitOps, catalog) and where do I follow the result?"),
]
prompts = prompts_en if en else prompts_pt
block = "  prompts:\n" + "".join("    - title: %s\n      message: |\n        %s\n" % (t, m) for t, m in prompts)
m = re.search(r'^lightspeed:\n', s, re.M)
assert m, 'no lightspeed section'
start = m.end()
end_m = re.search(r'^[A-Za-z]', s[start:], re.M); end = start + (end_m.start() if end_m else len(s) - start)
sec = s[start:end]
# drop the existing prompts block (comments above it included) and insert ours at the top of the section
sec2 = re.sub(r'(?:  #[^\n]*\n)*  prompts:\n(?:    [^\n]*\n|      [^\n]*\n|        [^\n]*\n|\n)*?(?=  [a-zA-Z#])', '', sec, count=1)
sec2 = block + "\n" + sec2
s = s[:start] + sec2 + s[end:]
yaml.safe_load(s)
open('/tmp/ac.yaml', 'w').write(s)
print("   prompts:", ", ".join(t for t, _ in prompts))
PYEOF
oc create cm app-config-rhdh -n rhdh --from-file=app-config-rhdh.yaml=/tmp/ac.yaml --dry-run=client -o yaml | oc apply -f - >/dev/null
oc label cm app-config-rhdh -n rhdh app.kubernetes.io/name=backstage --overwrite >/dev/null
if [ "${NO_RESTART:-0}" = 1 ]; then echo "   restart skipped"; else
  oc rollout restart deployment/backstage-developer-hub -n rhdh >/dev/null
  oc rollout status deployment/backstage-developer-hub -n rhdh --timeout=600s | tail -1; fi
