#!/usr/bin/env bash
# Spike step: create the north-south Gateway for the Parasol API and expose it through an
# OpenShift Route. No HTTPRoute and no policy yet, so the Parasol application is untouched.
#
#   bash scripts/rhcl/gateway.sh          # create + verify
#   bash scripts/rhcl/gateway.sh delete   # remove everything again
#
# What this validates (open points of the RHCL proposal):
#   - the existing OSSM 3.2 control plane programs a Gateway of class "istio"
#   - on CNV (no LoadBalancer provider) the gateway is reachable through an edge Route
set -euo pipefail
NS=parasol-gateway
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')

if [ "${1:-}" = "delete" ]; then
  oc delete namespace $NS --ignore-not-found
  echo "removed namespace $NS (Gateway, Route and the Istio-managed deployment)"
  exit 0
fi

oc apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NS
  labels:
    lab.rhdp.io/managed-by: openshift-advanced-platform-demo
    # The demo's Istio CR limits discovery to namespaces labelled ambient
    # (meshConfig.discoverySelectors). Without this label istiod never sees the Gateway
    # and it stays "Waiting for controller". Istio marks its own gateway pod
    # dataplane-mode=none, so the gateway is not captured by ztunnel.
    istio.io/dataplane-mode: ambient
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: parasol-gateway
  namespace: $NS
  annotations:
    # CNV has no LoadBalancer provider; the Route below fronts the ClusterIP service
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      hostname: "*.${D}"
      allowedRoutes:
        namespaces:
          # only namespaces the platform team labels may attach routes to the front door
          from: Selector
          selector:
            matchLabels:
              parasol.rhdp.io/gateway-access: "true"
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: parasol-gateway
  namespace: $NS
spec:
  host: parasol-gateway.${D}
  to:
    kind: Service
    name: parasol-gateway-istio
  port:
    targetPort: 80
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF

# namespaces allowed to attach routes: the gateway's own (LLM route) and Parasol prod
oc label namespace $NS parasol-insurance-prod parasol.rhdp.io/gateway-access=true --overwrite >/dev/null

echo "waiting for Istio to program the gateway..."
for i in $(seq 1 24); do
  [ "$(oc get gateway parasol-gateway -n $NS -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null)" = "True" ] && break
  sleep 5
done
# two replicas: Envoy reloads (and occasionally restarts) when Connectivity Link policies change;
# a single replica means a few seconds of "connection refused" on every policy edit
oc scale deployment/parasol-gateway-istio -n $NS --replicas=2 >/dev/null 2>&1 || true

echo "== Gateway"
oc get gateway parasol-gateway -n $NS -o custom-columns='NAME:.metadata.name,CLASS:.spec.gatewayClassName,ACCEPTED:.status.conditions[?(@.type=="Accepted")].status,PROGRAMMED:.status.conditions[?(@.type=="Programmed")].status,ADDR:.status.addresses[*].value'
echo "== created by Istio"
oc get deploy,svc,pods -n $NS --no-headers | awk '{print "   "$1, $2, $3}'
echo "== through the Route (404 from Envoy means programmed and reachable; no HTTPRoute exists yet)"
sleep 5
curl -skI "https://parasol-gateway.${D}/" | grep -iE '^(HTTP|server)' || echo "   no answer yet, retry in a minute"

# The demo's ztunnel-healer CronJob (Argo app openshift-gitops/ztunnel-healer, every 2 min) deletes any
# Running pod in an ambient namespace whose HBONE port 15008 refuses. Istio gateway pods are never
# enrolled in ztunnel (dataplane-mode none), so it killed both gateway pods every run (503 blips,
# "fewer than 2 replicas"). Exclude the gateway namespace, and keep Argo from reverting the env.
echo "== ztunnel-healer: exclude the gateway namespace"
oc get application.argoproj.io ztunnel-healer -n openshift-gitops -o jsonpath='{.spec.ignoreDifferences}' | grep -c CronJob >/dev/null || \
  oc patch application.argoproj.io ztunnel-healer -n openshift-gitops --type merge -p '{"spec":{"ignoreDifferences":[{"group":"batch","kind":"CronJob","name":"ztunnel-healer","namespace":"istio-mesh-tools","jsonPointers":["/spec/jobTemplate/spec/template/spec/containers/0/env"]}]}}' >/dev/null
EX=$(oc get cronjob ztunnel-healer -n istio-mesh-tools -o json | jq -r '.spec.jobTemplate.spec.template.spec.containers[0].env[] | select(.name=="EXCLUDE_NS") | .value')
if ! echo " $EX " | grep -q " $NS "; then
  IDX=$(oc get cronjob ztunnel-healer -n istio-mesh-tools -o json | jq '.spec.jobTemplate.spec.template.spec.containers[0].env | map(.name=="EXCLUDE_NS") | index(true)')
  oc patch cronjob ztunnel-healer -n istio-mesh-tools --type json -p "[{\"op\":\"replace\",\"path\":\"/spec/jobTemplate/spec/template/spec/containers/0/env/$IDX/value\",\"value\":\"$EX $NS\"}]" >/dev/null
fi
echo "   EXCLUDE_NS: $(oc get cronjob ztunnel-healer -n istio-mesh-tools -o json | jq -r '.spec.jobTemplate.spec.template.spec.containers[0].env[] | select(.name=="EXCLUDE_NS") | .value')"
