#!/usr/bin/env bash
# Observability layer, step 1: operators (add-only, nothing of the demo is changed).
#   - Tempo operator (Red Hat, stable)            -> openshift-tempo-operator
#   - OpenTelemetry operator (Red Hat, stable)    -> openshift-opentelemetry-operator
#   - Grafana operator (community, v5)            -> observability (own-namespace OperatorGroup)
# Idempotent. Waits for the CSVs to Succeed.
set -euo pipefail
sub() { # ns pkg channel source [ownNamespace]
  local ns=$1 pkg=$2 ch=$3 src=$4 own=${5:-}
  oc get ns "$ns" >/dev/null 2>&1 || oc create ns "$ns" >/dev/null
  if ! oc get operatorgroup -n "$ns" --no-headers 2>/dev/null | grep -q .; then
    if [ -n "$own" ]; then
      oc apply -f - <<Y
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata: {name: ${ns}-og, namespace: ${ns}}
spec: {targetNamespaces: [${ns}]}
Y
    else
      oc apply -f - <<Y
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata: {name: ${ns}-og, namespace: ${ns}}
spec: {}
Y
    fi
  fi
  oc apply -f - <<Y
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata: {name: ${pkg}, namespace: ${ns}}
spec: {channel: ${ch}, name: ${pkg}, source: ${src}, sourceNamespace: openshift-marketplace, installPlanApproval: Automatic}
Y
}
src_of() { oc get packagemanifest "$1" -n openshift-marketplace -o jsonpath='{.status.catalogSource}'; }
sub openshift-tempo-operator          tempo-product          stable "$(src_of tempo-product)"
sub openshift-opentelemetry-operator  opentelemetry-product  stable "$(src_of opentelemetry-product)"
sub observability                     grafana-operator       v5     "$(src_of grafana-operator)" own
oc label ns observability openshift.io/cluster-monitoring- >/dev/null 2>&1 || true
echo "-- waiting for CSVs"
for pair in openshift-tempo-operator/tempo-product openshift-opentelemetry-operator/opentelemetry-product observability/grafana-operator; do
  ns=${pair%/*}; pkg=${pair#*/}
  for i in $(seq 1 60); do
    csv=$(oc get sub "$pkg" -n "$ns" -o jsonpath='{.status.installedCSV}' 2>/dev/null)
    [ -n "$csv" ] && [ "$(oc get csv "$csv" -n "$ns" -o jsonpath='{.status.phase}' 2>/dev/null)" = Succeeded ] && { echo "   $ns: $csv Succeeded"; break; }
    sleep 10
  done
done
