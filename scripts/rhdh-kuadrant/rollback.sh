#!/usr/bin/env bash
# Undo apply.sh: restore the ConfigMaps and Backstage CR from the newest backup-* directory
# (or the one given as $1) and let Argo CD manage them again.
set -euo pipefail
cd "$(dirname "$0")"
BK=${1:-$(ls -d backup-* 2>/dev/null | sort | tail -1)}
[ -n "$BK" ] && [ -d "$BK" ] || { echo "no backup directory found"; exit 1; }
echo "restoring from $BK"
for f in cm-dynamic-plugins cm-app-config-rhdh cm-rbac-policy backstage; do
  oc apply -f "$BK/$f.yaml"
done
oc patch application.argoproj.io developer-hub-application -n openshift-gitops --type=json -p '[{"op":"remove","path":"/spec/ignoreDifferences"}]' || true
oc annotate application.argoproj.io developer-hub-application -n openshift-gitops argocd.argoproj.io/refresh=hard --overwrite
oc rollout status deployment/backstage-developer-hub -n rhdh --timeout=600s
echo "Done. Kuadrant plugins and the permission framework are disabled again."
