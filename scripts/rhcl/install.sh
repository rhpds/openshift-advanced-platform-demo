#!/usr/bin/env bash
# Install Red Hat Connectivity Link (Kuadrant) on the demo cluster: operator, control plane
# and the OpenShift console plugin. Idempotent. Does NOT touch the Parasol application:
# no Gateway, HTTPRoute or policy is created here (see the RHCL proposal for that step).
#
# Prereqs already present on ocp4-adv-app-platform-demo: Gateway API CRDs (OCP 4.20),
# GatewayClass "istio" from OSSM 3.2, cert-manager operator.
set -euo pipefail
NS=kuadrant-system
log() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }

log "operator (redhat-operators, channel stable)"
oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NS
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: kuadrant
  namespace: $NS
spec:
  upgradeStrategy: Default
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhcl-operator
  namespace: $NS
spec:
  channel: stable
  name: rhcl-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
EOF
for i in $(seq 1 60); do
  csv=$(oc get subscription rhcl-operator -n $NS -o jsonpath='{.status.installedCSV}' 2>/dev/null || true)
  [ -n "$csv" ] && [ "$(oc get csv "$csv" -n $NS -o jsonpath='{.status.phase}' 2>/dev/null)" = "Succeeded" ] && { echo "   $csv Succeeded"; break; }
  sleep 10
done

log "Kuadrant control plane (Authorino, Limitador, DNS operator, console plugin)"
oc apply -f - <<EOF
apiVersion: kuadrant.io/v1beta1
kind: Kuadrant
metadata:
  name: kuadrant
  namespace: $NS
spec: {}
EOF
for i in $(seq 1 30); do
  [ "$(oc get kuadrant kuadrant -n $NS -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = "True" ] && { echo "   Kuadrant Ready"; break; }
  sleep 10
done

log "OpenShift console plugin"
if ! oc get console.operator cluster -o jsonpath='{.spec.plugins}' | grep -q kuadrant-console-plugin; then
  oc patch console.operator cluster --type=json -p '[{"op":"add","path":"/spec/plugins/-","value":"kuadrant-console-plugin"}]'
fi
echo "   plugins: $(oc get console.operator cluster -o jsonpath='{.spec.plugins}')"

log "state"
oc get pods -n $NS --no-headers | awk '{print "   "$1, $3}'
oc get gatewayclass --no-headers | awk '{print "   gatewayclass", $1, $2, $3}'
echo; echo "Done. Connectivity Link is installed; nothing is attached to the Parasol application yet."
