#!/usr/bin/env bash
# OpenShift Lightspeed (the AI assistant of the OpenShift console) for the platform engineer,
# consuming the model THROUGH the Connectivity Link LLM gateway of Module 7 (its own platform key
# and token budget), so the same governance covers the console assistant, the application and
# the developers' assistants. Add-only: operator in openshift-lightspeed (own-namespace
# OperatorGroup, the only install mode it supports), one OLSConfig, one key in kuadrant-system.
#
#   bash scripts/ai/openshift-lightspeed.sh          # install + configure + test a query
#   bash scripts/ai/openshift-lightspeed.sh delete   # remove OLSConfig, operator and the key
# Requires scripts/rhcl/llm-gateway.sh (the llm route and the team keys).
set -euo pipefail
NS=openshift-lightspeed
KEYNS=kuadrant-system
MODEL=${MODEL:-qwen3-14b}

if [ "${1:-}" = "delete" ]; then
  oc delete olsconfig cluster --ignore-not-found
  oc delete sub lightspeed-operator -n $NS --ignore-not-found; oc delete csv -n $NS -l operators.coreos.com/lightspeed-operator.openshift-lightspeed --ignore-not-found
  oc delete ns $NS --ignore-not-found; oc delete secret llm-key-team-platform -n $KEYNS --ignore-not-found
  echo "OpenShift Lightspeed removed."; exit 0
fi
oc get secret llm-key-team-demo -n $KEYNS >/dev/null 2>&1 || { echo "run scripts/rhcl/llm-gateway.sh first"; exit 1; }

echo "== operator"
oc get ns $NS >/dev/null 2>&1 || oc create ns $NS >/dev/null
oc get operatorgroup -n $NS --no-headers 2>/dev/null | grep -c . >/dev/null || oc apply -f - <<Y >/dev/null
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata: {name: openshift-lightspeed-og, namespace: ${NS}}
spec: {targetNamespaces: [${NS}]}
Y
oc apply -f - <<Y >/dev/null
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata: {name: lightspeed-operator, namespace: ${NS}}
spec: {channel: stable, name: lightspeed-operator, source: $(oc get packagemanifest lightspeed-operator -n openshift-marketplace -o jsonpath='{.status.catalogSource}'), sourceNamespace: openshift-marketplace, installPlanApproval: Automatic}
Y
for i in $(seq 1 40); do csv=$(oc get sub lightspeed-operator -n $NS -o jsonpath='{.status.installedCSV}' 2>/dev/null); [ -n "$csv" ] && [ "$(oc get csv "$csv" -n $NS -o jsonpath='{.status.phase}' 2>/dev/null)" = Succeeded ] && { echo "   $csv Succeeded"; break; }; sleep 10; done

echo "== platform key for the console assistant (gateway team key, never printed)"
if ! oc get secret llm-key-team-platform -n $KEYNS >/dev/null 2>&1; then
  # same provider key as the other team keys, new api_key, own user-id for the token budget counters
  oc get secret llm-key-team-demo -n $KEYNS -o json \
    | jq --arg k "$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32 | base64)" \
         '{apiVersion, kind, type, metadata: {name: "llm-key-team-platform", namespace: .metadata.namespace, labels: .metadata.labels, annotations: {"secret.kuadrant.io/user-id": "team-platform"}}, data: {api_key: $k, provider_key: .data.provider_key}}' \
    | oc apply -f - >/dev/null
  echo "   created llm-key-team-platform (app=parasol-llm)"
fi
oc get secret llm-key-team-platform -n $KEYNS -o json | jq '{apiVersion, kind, type: "Opaque", metadata: {name: "llm-gateway-key", namespace: "'$NS'"}, data: {apitoken: .data.api_key}}' | oc apply -f - >/dev/null
echo "   secret llm-gateway-key in $NS"

echo "== OLSConfig: provider = the Connectivity Link LLM gateway"
oc apply -f - <<Y
apiVersion: ols.openshift.io/v1alpha1
kind: OLSConfig
metadata:
  name: cluster
spec:
  llm:
    providers:
      - name: parasol-gateway
        type: openai
        url: http://llm.parasol-gateway.svc/v1
        credentialsSecretRef:
          name: llm-gateway-key
        models:
          - name: ${MODEL}
  ols:
    defaultProvider: parasol-gateway
    defaultModel: ${MODEL}
    logLevel: INFO
    deployment:
      replicas: 1
Y
for i in $(seq 1 60); do
  r=$(oc get deployment lightspeed-app-server -n $NS -o jsonpath="{.status.readyReplicas}" 2>/dev/null || true); [ "${r:-0}" -ge 1 ] 2>/dev/null && break; sleep 10
done
echo "   app server ready replicas: $(oc get deployment lightspeed-app-server -n $NS -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
echo "   console plugin: $(oc get consoles.operator cluster -o jsonpath='{.spec.plugins}' | grep -o lightspeed-console-plugin || echo 'not yet enabled')"

echo "== test query (as the current oc user)"
oc run ols-probe -n $NS --rm -i --restart=Never --quiet --image=quay.io/curl/curl:latest --env="T=$(oc whoami -t)" -- sh -c '
  sleep 2; curl -sk --max-time 120 -H "Authorization: Bearer $T" -H "Content-Type: application/json" https://lightspeed-app-server.'$NS'.svc:8443/v1/query -d "{\"query\":\"In one sentence, what is a Gateway API HTTPRoute?\"}"' 2>/dev/null | head -c 600; echo
echo "Done. OpenShift console -> Lightspeed button (bottom right) as any console user."
