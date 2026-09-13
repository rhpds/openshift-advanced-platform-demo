#!/usr/bin/env bash
# Publish the Parasol claims API as a Connectivity Link API Product, so it shows up in the
# Developer Hub "API Products" page (Kuadrant plugin) with self-service key requests, and
# attach a PlanPolicy with the tiers the portal offers.
#
#   bash scripts/rhcl/api-product.sh          # create
#   bash scripts/rhcl/api-product.sh delete   # remove
#
# Prereq: scripts/rhcl/parasol-api.sh (HTTPRoute parasol-api + policies) and the Kuadrant
# Developer Hub plugins (scripts/rhdh-kuadrant/apply.sh) for the portal side.
set -euo pipefail
NS=parasol-insurance-prod
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')

if [ "${1:-}" = "delete" ]; then
  oc delete apiproduct/parasol-insurance-api planpolicy/parasol-api-plans -n $NS --ignore-not-found
  echo "removed the API Product and the PlanPolicy"
  exit 0
fi

oc apply -f - <<EOF
# Tiers a consumer can request from the portal. The identity's tier comes from the
# secret.kuadrant.io/plan-id annotation the plugin stamps on the API key it creates.
apiVersion: extensions.kuadrant.io/v1alpha1
kind: PlanPolicy
metadata:
  name: parasol-api-plans
  namespace: $NS
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: parasol-api
  plans:
    - tier: gold
      predicate: |
        has(auth.identity) && auth.identity.metadata.annotations["secret.kuadrant.io/plan-id"] == "gold"
      limits:
        daily: 10000
    - tier: silver
      predicate: |
        has(auth.identity) && auth.identity.metadata.annotations["secret.kuadrant.io/plan-id"] == "silver"
      limits:
        daily: 1000
    - tier: bronze
      predicate: |
        has(auth.identity) && auth.identity.metadata.annotations["secret.kuadrant.io/plan-id"] == "bronze"
      limits:
        daily: 100
---
apiVersion: devportal.kuadrant.io/v1alpha1
kind: APIProduct
metadata:
  name: parasol-insurance-api
  namespace: $NS
  annotations:
    backstage.io/owner: group:default/devteam1
spec:
  displayName: Parasol Insurance Claims API
  description: >-
    REST API of the Parasol Insurance claims management application (production).
    Exposed through the parasol-gateway with API-key authentication and per-consumer
    rate limits managed by Red Hat Connectivity Link.
  version: v1
  approvalMode: manual
  publishStatus: Published
  tags:
    - parasol
    - claims
    - insurance
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: parasol-api
  documentation:
    docsURL: https://parasol-api-${NS}.${D}/api/claims
  contact:
    team: devteam1
    email: dev1@rhdemo.com
EOF

sleep 10
echo "== status"
oc get planpolicy parasol-api-plans -n $NS -o custom-columns='PLANPOLICY:.metadata.name,ACCEPTED:.status.conditions[?(@.type=="Accepted")].status,ENFORCED:.status.conditions[?(@.type=="Enforced")].status'
oc get apiproduct parasol-insurance-api -n $NS -o custom-columns='APIPRODUCT:.metadata.name,PUBLISH:.spec.publishStatus,APPROVAL:.spec.approvalMode,ROUTE:.spec.targetRef.name'
echo "Developer Hub: Connectivity Link -> API Products lists it within a minute (catalog refresh)."
