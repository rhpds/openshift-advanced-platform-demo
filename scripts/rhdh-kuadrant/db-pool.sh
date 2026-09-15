#!/usr/bin/env bash
# Developer Hub hits PostgreSQL's max_connections (100) once the RBAC + Kuadrant backends
# are added: every backend plugin keeps its own knex pool (min 2, max 10). Symptom in the
# backend log: "sorry, too many clients already" and random permission denials.
# Fix: smaller per-plugin pools (app-config) and a higher limit on the local database.
set -euo pipefail
NS=rhdh
cd "$(dirname "$0")"

oc get cm app-config-rhdh -n $NS -o jsonpath='{.data.app-config-rhdh\.yaml}' > ac.cur.yaml
python3 - <<'EOF'
import re
ac=open('ac.cur.yaml').read()
if 'knexConfig' not in ac:
    block='''backend:
  # Smaller per-plugin connection pools: ~30 backend plugins x (min 2, max 10) exhausts
  # PostgreSQL max_connections=100 and breaks permission evaluation.
  database:
    knexConfig:
      pool:
        min: 0
        max: 4
        acquireTimeoutMillis: 30000
        idleTimeoutMillis: 30000
'''
    ac=re.sub(r'^backend:\n', block, ac, count=1, flags=re.M)
open('ac.new.yaml','w').write(ac)
import yaml; d=yaml.safe_load(open('ac.new.yaml')); assert d['backend']['database']['knexConfig']['pool']['max']==4; print('   app-config ok')
EOF
oc create cm app-config-rhdh -n $NS --from-file=app-config-rhdh.yaml=ac.new.yaml --dry-run=client -o yaml | oc apply -f -
oc label cm app-config-rhdh -n $NS app.kubernetes.io/name=backstage --overwrite >/dev/null

# local DB: raise the server-side limit as well (the operator-managed StatefulSet honours
# the postgresql image's POSTGRESQL_MAX_CONNECTIONS variable)
STS=$(oc get sts -n $NS -o name | grep psql | head -1)
if ! oc get "$STS" -n $NS -o jsonpath='{.spec.template.spec.containers[0].env[*].name}' | grep -q POSTGRESQL_MAX_CONNECTIONS; then
  oc set env "$STS" -n $NS POSTGRESQL_MAX_CONNECTIONS=300
  oc rollout status "$STS" -n $NS --timeout=180s
fi

oc rollout restart deployment/backstage-developer-hub -n $NS
oc rollout status deployment/backstage-developer-hub -n $NS --timeout=600s
sleep 30
POD=$(oc get pods -n $NS --no-headers | awk '/^backstage-developer-hub/ && $3=="Running"{print $1; exit}')
echo "too many clients since restart: $(oc logs "$POD" -n $NS -c backstage-backend 2>/dev/null | grep -c 'too many clients')"
oc exec "${STS#statefulset.apps/}-0" -n $NS -- psql -U postgres -tAc "show max_connections; select count(*) from pg_stat_activity;" 2>/dev/null | tr '\n' ' '; echo
