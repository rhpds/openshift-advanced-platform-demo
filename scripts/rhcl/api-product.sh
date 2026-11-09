#!/usr/bin/env bash
# Publish the Parasol claims API as a Connectivity Link API Product, so it shows up in the
# Developer Hub "API Products" page (Kuadrant plugin) with self-service key requests. The plans
# the portal offers come from the PlanPolicy that parasol-api.sh attaches to the route.
#
#   bash scripts/rhcl/api-product.sh          # create
#   bash scripts/rhcl/api-product.sh delete   # remove
#
# Prereq: scripts/rhcl/parasol-api.sh (HTTPRoute parasol-api + policies) and the Kuadrant
# Developer Hub plugins (scripts/rhdh-kuadrant/apply.sh) for the portal side.
#
# Naming: the plugin's catalog provider turns every published APIProduct into a catalog
# entity of kind API named after the CR. The demo already registers api:default/
# parasol-insurance-api from rhdh-templates, so the product gets its own name.
set -euo pipefail
NS=parasol-insurance-prod
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')

if [ "${1:-}" = "delete" ]; then
  oc delete apiproduct/parasol-claims-api apiproduct/parasol-insurance-api -n $NS --ignore-not-found
  echo "removed the API Product"
  exit 0
fi

oc apply -f - <<EOF
# (the PlanPolicy with the gold/silver/bronze tiers is created by parasol-api.sh, on the route)
apiVersion: devportal.kuadrant.io/v1alpha1
kind: APIProduct
metadata:
  name: parasol-claims-api
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
oc get apiproduct parasol-claims-api -n $NS -o custom-columns='APIPRODUCT:.metadata.name,PUBLISH:.spec.publishStatus,APPROVAL:.spec.approvalMode,ROUTE:.spec.targetRef.name'
echo "Developer Hub: Connectivity Link -> API Products lists it; the catalog gets api:default/parasol-claims-api within a minute."
