#!/usr/bin/env bash
# Observability layer, step 2: distributed tracing (add-only).
#   - TempoMonolithic "tempo" in namespace observability (PV storage, Jaeger UI route behind OpenShift auth)
#   - OpenTelemetryCollector "otel" (OTLP gRPC/HTTP in -> Tempo), the single endpoint everything points at:
#       otel-collector.observability.svc:4317 (gRPC) / :4318 (HTTP)
#   - Istio: extension provider "otel-tracing" + a Telemetry per ambient namespace (100% sampling, demo) so the
#     gateways and waypoints (L7, ambient) emit spans. The Istio CR is Argo-owned: the service-mesh
#     Application gets an ignoreDifferences for the extensionProviders we add.
#   - Connectivity Link: Limitador and Authorino export their spans to the same collector.
#   - Kiali: both instances read traces from Tempo (Traces tab / trace overlay on the graph).
# Requires install-operators.sh.
set -euo pipefail
NS=observability
D=$(oc get ingresses.config cluster -o jsonpath='{.spec.domain}')
oc get ns $NS >/dev/null 2>&1 || oc create ns $NS >/dev/null
oc label ns $NS parasol.rhdp.io/layer=observability --overwrite >/dev/null

echo "== Tempo (monolithic)"
oc apply -f - <<'Y'
apiVersion: tempo.grafana.com/v1alpha1
kind: TempoMonolithic
metadata:
  name: tempo
  namespace: observability
spec:
  storage:
    traces:
      backend: pv
      size: 10Gi
  jaegerui:
    enabled: true
    route:
      enabled: true
    authentication:
      enabled: true
  observability:
    metrics:
      serviceMonitors:
        enabled: true
Y
for i in $(seq 1 40); do
  oc get statefulset tempo-tempo -n $NS >/dev/null 2>&1 && [ "$(oc get statefulset tempo-tempo -n $NS -o jsonpath='{.status.readyReplicas}')" = 1 ] && break; sleep 10
done
echo "   tempo ready replicas: $(oc get statefulset tempo-tempo -n $NS -o jsonpath='{.status.readyReplicas}')"

echo "== OpenTelemetry collector"
oc apply -f - <<'Y'
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel
  namespace: observability
spec:
  mode: deployment
  observability:
    metrics:
      enableMetrics: true
  config:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      zipkin:
        endpoint: 0.0.0.0:9411
    processors:
      batch: {}
      memory_limiter:
        check_interval: 1s
        limit_percentage: 75
        spike_limit_percentage: 15
    exporters:
      otlp/tempo:
        endpoint: tempo-tempo.observability.svc:4317
        tls:
          insecure: true
      debug:
        verbosity: basic
    service:
      pipelines:
        traces:
          receivers: [otlp, zipkin]
          processors: [memory_limiter, batch]
          exporters: [otlp/tempo]
Y
oc rollout status deployment/otel-collector -n $NS --timeout=300s | tail -1

echo "== Istio: tracing provider + mesh Telemetry"
# keep Argo from reverting what we add to the Istio and Kiali CRs. The app-of-apps re-applies the child
# Applications' ignoreDifferences list, so it must ignore that field first (RespectIgnoreDifferences is
# already on for app-of-apps and service-mesh).
oc get application.argoproj.io app-of-apps -n openshift-gitops -o jsonpath='{.spec.ignoreDifferences}' | grep -q '"kind":"Application"' || \
  oc patch application.argoproj.io app-of-apps -n openshift-gitops --type merge -p '{"spec":{"ignoreDifferences":[{"group":"argoproj.io","kind":"Application","jsonPointers":["/spec/ignoreDifferences"]}]}}' >/dev/null
oc get application.argoproj.io app-of-apps -n openshift-gitops -o jsonpath='{.spec.syncPolicy.syncOptions}' | grep -q RespectIgnoreDifferences || \
  oc patch application.argoproj.io app-of-apps -n openshift-gitops --type json -p '[{"op":"add","path":"/spec/syncPolicy/syncOptions/-","value":"RespectIgnoreDifferences=true"}]' >/dev/null
# exact entries for Istio and Kiali (replace ours if present, keep the demo's own entries)
NEWIGN=$(oc get application.argoproj.io service-mesh -n openshift-gitops -o json | jq -c '
  [ (.spec.ignoreDifferences // [])[] | select(.kind != "Istio" and .kind != "Kiali") ]
  + [ {group:"sailoperator.io", kind:"Istio", jsonPointers:["/spec/values/meshConfig/extensionProviders","/spec/values/meshConfig/enableTracing"]},
      {group:"kiali.io", kind:"Kiali", jsonPointers:["/spec/external_services/tracing","/spec/external_services/grafana"]} ]')
oc patch application.argoproj.io service-mesh -n openshift-gitops --type merge -p "{\"spec\":{\"ignoreDifferences\":$NEWIGN}}" >/dev/null
# setting extensionProviders replaces Istio's built-in list, so the "envoy" access-log provider is declared too
if ! oc get istio default -o jsonpath='{.spec.values.meshConfig.extensionProviders}' | grep -c 'envoyFileAccessLog' >/dev/null; then
  oc patch istio default --type merge -p '{"spec":{"values":{"meshConfig":{"enableTracing":true,"extensionProviders":[{"name":"otel-tracing","opentelemetry":{"port":4317,"service":"otel-collector.observability.svc.cluster.local"}},{"name":"envoy","envoyFileAccessLog":{"path":"/dev/stdout"}}]}}}}'
fi
# istiod only watches the namespaces selected by discoverySelectors (istio.io/dataplane-mode=ambient),
# so a mesh-wide Telemetry in istio-system is never seen: one Telemetry per ambient namespace instead
# (re-run after new per-user namespaces are created; post-provision.sh does that).
# Istio honours ONE namespace-wide Telemetry per namespace, so the gateway namespace gets its
# Envoy access logs (stdout of the gateway pods: who called what, with the response flags) in the
# same resource as the tracing configuration.
for ns in $(oc get ns -l istio.io/dataplane-mode=ambient --no-headers -o custom-columns=:metadata.name); do
  extra=""; [ "$ns" = parasol-gateway ] && extra='
  accessLogging:
    - providers:
        - name: envoy'
  oc apply -f - <<Y >/dev/null
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: tracing
  namespace: ${ns}
  labels:
    parasol.rhdp.io/layer: observability
spec:
  tracing:
    - providers:
        - name: otel-tracing
      randomSamplingPercentage: 100${extra}
Y
done
oc delete telemetry access-log -n parasol-gateway --ignore-not-found >/dev/null 2>&1
echo "   Telemetry applied to: $(oc get telemetry -A -l parasol.rhdp.io/layer=observability --no-headers | wc -l | tr -d ' ') ambient namespaces"
# the collector lives outside the watched namespaces: make its Service known to istiod
oc apply -f - <<'Y' >/dev/null
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: otel-collector
  namespace: parasol-gateway
  labels:
    parasol.rhdp.io/layer: observability
spec:
  hosts: [otel-collector.observability.svc.cluster.local]
  location: MESH_EXTERNAL
  resolution: DNS
  exportTo: ["*"]
  ports:
    - name: grpc-otlp
      number: 4317
      protocol: GRPC
Y
for i in $(seq 1 30); do [ "$(oc get istio default -o jsonpath='{.status.state}')" = Healthy ] && break; sleep 5; done
echo "   istio: $(oc get istio default -o jsonpath='{.status.state}')"

echo "== Connectivity Link: Limitador and Authorino spans to the collector"
oc patch limitador limitador -n kuadrant-system --type merge -p '{"spec":{"tracing":{"endpoint":"rpc://otel-collector.observability.svc:4317"}}}' >/dev/null
oc patch authorino authorino -n kuadrant-system --type merge -p '{"spec":{"tracing":{"endpoint":"rpc://otel-collector.observability.svc:4317","insecure":true}}}' >/dev/null
oc patch kuadrant kuadrant -n kuadrant-system --type merge -p '{"spec":{"observability":{"enable":true}}}' >/dev/null
echo "   limitador tracing: $(oc get limitador limitador -n kuadrant-system -o jsonpath='{.spec.tracing.endpoint}')"
echo "   authorino tracing: $(oc get authorino authorino -n kuadrant-system -o jsonpath='{.spec.tracing.endpoint}')"

echo "== Kiali: read traces from Tempo"
TRACING='{"spec":{"external_services":{"tracing":{"enabled":true,"provider":"tempo","use_grpc":false,"internal_url":"http://tempo-tempo.observability.svc:3200","external_url":"https://tempo-tempo-jaegerui-observability.'"$D"'","tempo_config":{"org_id":"1","url_format":"jaeger"}}}}}'
oc patch kiali kiali -n istio-system --type merge -p "$TRACING" >/dev/null
oc patch kiali kiali-rhdh -n istio-system --type merge -p "$TRACING" >/dev/null 2>&1 || true
echo "Done. Jaeger UI: https://tempo-tempo-jaegerui-observability.$D"
