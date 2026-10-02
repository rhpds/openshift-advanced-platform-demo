#!/usr/bin/env python3
"""Generate the two custom Grafana dashboards of the observability layer as JSON.

    build-dashboards.py <out-dir>

Metrics come from OpenShift user-workload monitoring (Thanos): Istio gateway/waypoint metrics
(istio_requests_total, istio_request_duration_milliseconds_bucket), Connectivity Link
(authorized_calls, limited_calls, auth_server_response_status, kuadrant_*), kube-state-metrics,
Tekton and Argo CD. The gateway pod is scraped on two ports by the Kuadrant PodMonitor, so every
Istio series is de-duplicated with max by (pod, ...) before summing.
"""
import json, sys, os

PROM = {"type": "prometheus", "uid": "prometheus"}
TEMPO = {"type": "tempo", "uid": "tempo"}
_id = [0]


def nid():
    _id[0] += 1
    return _id[0]


def target(expr, legend, ds=PROM):
    return {"datasource": ds, "expr": expr, "legendFormat": legend, "refId": chr(64 + nid() % 26 + 1)}


def panel(title, ptype, targets, x, y, w, h, unit=None, extra=None, desc=None):
    p = {"id": nid(), "type": ptype, "title": title, "datasource": PROM, "targets": targets,
         "gridPos": {"x": x, "y": y, "w": w, "h": h},
         "fieldConfig": {"defaults": {"unit": unit or "short"}, "overrides": []},
         "options": {"legend": {"displayMode": "list", "placement": "bottom"}, "tooltip": {"mode": "multi"}}}
    if desc:
        p["description"] = desc
    if ptype == "stat":
        p["options"] = {"reduceOptions": {"calcs": ["lastNotNull"]}, "colorMode": "value", "graphMode": "area"}
    if ptype == "table":
        p["options"] = {"showHeader": True}
    if extra:
        p.update(extra)
    return p


def row(title, y):
    return {"id": nid(), "type": "row", "title": title, "collapsed": False, "gridPos": {"x": 0, "y": y, "w": 24, "h": 1}, "panels": []}


def dashboard(uid, title, tags, panels, templating=None):
    return {"uid": uid, "title": title, "tags": tags, "timezone": "browser", "schemaVersion": 39, "version": 1,
            "editable": True, "refresh": "30s", "time": {"from": "now-1h", "to": "now"},
            "templating": {"list": templating or []}, "panels": panels}


# de-duplicated Istio request rate, grouped as asked
def istio_rate(by, sel, rng="2m"):
    return (f'sum by ({by}) (max by (pod, {by}) '
            f'(rate(istio_requests_total{{{sel}}}[{rng}])))')


def istio_p95(by, sel, rng="5m"):
    return (f'histogram_quantile(0.95, sum by (le, {by}) (max by (pod, le, {by}) '
            f'(rate(istio_request_duration_milliseconds_bucket{{{sel}}}[{rng}]))))')


NS_VAR = {"name": "namespace", "label": "Namespace", "type": "query", "datasource": PROM, "includeAll": True, "multi": True,
          "allValue": "parasol-.*", "current": {"text": "All", "value": "$__all"}, "refresh": 2,
          "query": {"query": 'label_values(istio_requests_total{destination_workload_namespace=~"parasol-.*"}, destination_workload_namespace)', "refId": "ns"},
          "definition": 'label_values(istio_requests_total{destination_workload_namespace=~"parasol-.*"}, destination_workload_namespace)'}

APP = 'destination_workload_namespace=~"$namespace"'

overview = dashboard("parasol-overview", "Parasol Platform Overview", ["parasol", "custom"], [
    row("Traffic (Istio ambient: gateway + waypoints)", 0),
    panel("Requests / s", "stat", [target(f'sum({istio_rate("destination_workload_namespace", APP)})', "req/s")], 0, 1, 4, 4, "reqps"),
    panel("5xx ratio", "stat", [target(
        f'(sum({istio_rate("destination_workload_namespace", APP + ',response_code=~"5.."')}) / sum({istio_rate("destination_workload_namespace", APP)})) or vector(0)',
        "5xx")], 4, 1, 4, 4, "percentunit", {"fieldConfig": {"defaults": {"unit": "percentunit", "thresholds": {"mode": "absolute", "steps": [{"color": "green", "value": None}, {"color": "orange", "value": 0.01}, {"color": "red", "value": 0.05}]}}, "overrides": []}}),
    panel("p95 latency", "stat", [target(f'max({istio_p95("destination_workload_namespace", APP)})', "p95")], 8, 1, 4, 4, "ms"),
    panel("mTLS share of requests", "stat", [target(
        f'(sum({istio_rate("connection_security_policy", APP + ',connection_security_policy="mutual_tls"')}) / sum({istio_rate("connection_security_policy", APP)})) or vector(0)', "mTLS")],
        12, 1, 4, 4, "percentunit"),
    panel("Requests by namespace and response code", "timeseries",
          [target(istio_rate("destination_workload_namespace, response_code", APP), "{{destination_workload_namespace}} {{response_code}}")], 0, 5, 12, 8, "reqps"),
    panel("p95 latency by namespace", "timeseries", [target(istio_p95("destination_workload_namespace", APP), "{{destination_workload_namespace}}")], 12, 5, 12, 8, "ms"),
    panel("Top services (req/s)", "table", [target(f'topk(10, {istio_rate("destination_service_name, destination_workload_namespace", APP)})', "", )],
          16, 1, 8, 4, "reqps", {"options": {"showHeader": True}, "targets": [dict(target(f'topk(10, {istio_rate("destination_service_name, destination_workload_namespace", APP)})', ""), format="table", instant=True)]}),

    row("Connectivity Link (Authorino + Limitador on the Parasol gateway)", 13),
    panel("Authorization decisions / s", "timeseries", [target('sum by (status) (rate(auth_server_response_status[2m]))', "{{status}}")], 0, 14, 8, 7, "reqps",
          desc="Authorino: OK = API key accepted, UNAUTHENTICATED = missing/invalid key"),
    panel("Rate limiting: authorized vs limited / s", "timeseries", [
        target('sum by (limitador_namespace) (rate(authorized_calls[2m]))', "allowed {{limitador_namespace}}"),
        target('sum by (limitador_namespace) (rate(limited_calls[2m]))', "limited (429) {{limitador_namespace}}")], 8, 14, 8, 7, "reqps"),
    panel("Gateway responses by code (Connectivity Link decisions)", "timeseries",
          [target(istio_rate("response_code", 'source_workload="parasol-gateway-istio"'), "{{response_code}}")], 16, 14, 8, 7, "reqps",
          desc="401 = Authorino rejected, 429 = Limitador rate limit, 200 = forwarded to Parasol"),

    row("Platform health", 21),
    panel("Container restarts (1h) in Parasol namespaces", "timeseries",
          [target('sum by (namespace) (increase(kube_pod_container_status_restarts_total{namespace=~"parasol-.*"}[1h]))', "{{namespace}}")], 0, 22, 8, 7),
    panel("Pipeline runs (24h) by namespace and status", "bargauge",
          [dict(target('sum by (namespace, status) (increase(tekton_pipelines_controller_pipelinerun_duration_seconds_count{namespace=~"parasol-.*"}[24h]))', "{{namespace}} {{status}}"), instant=True)],
          8, 22, 8, 7, "short", {"options": {"orientation": "horizontal", "displayMode": "gradient", "reduceOptions": {"calcs": ["lastNotNull"]}}}),
    panel("Argo CD applications by health", "piechart",
          [dict(target('count by (health_status) (argocd_app_info{namespace="rhdh-gitops"})', "{{health_status}}"), instant=True)], 16, 22, 8, 7, "short",
          {"options": {"reduceOptions": {"calcs": ["lastNotNull"]}, "legend": {"displayMode": "list", "placement": "right"}}}),
], [NS_VAR])

GW = 'source_workload="parasol-gateway-istio"'
rhcl = dashboard("parasol-rhcl", "Connectivity Link: Parasol API and LLM gateway", ["parasol", "custom", "kuadrant"], [
    row("Parasol API (parasol-api.<domain>: AuthPolicy + RateLimitPolicy + PlanPolicy)", 0),
    panel("Requests / s through the gateway", "stat", [target(f'sum({istio_rate("response_code", GW)})', "req/s")], 0, 1, 4, 4, "reqps"),
    panel("Rejected: 401 / s", "stat", [target(f'sum({istio_rate("response_code", GW + ',response_code="401"')})', "401")], 4, 1, 4, 4, "reqps"),
    panel("Rate limited: 429 / s", "stat", [target(f'sum({istio_rate("response_code", GW + ',response_code="429"')})', "429")], 8, 1, 4, 4, "reqps"),
    panel("Gateway p95 latency", "stat", [target(f'max({istio_p95("source_workload", GW)})', "p95")], 12, 1, 4, 4, "ms"),
    panel("Gateway pods", "stat", [target('sum(kube_deployment_status_replicas_available{namespace="parasol-gateway"})', "ready")], 16, 1, 4, 4),
    panel("Limitador / Authorino up", "stat", [target('min(limitador_up)', "limitador"), target('min(up{job=~".*authorino.*"})', "authorino")], 20, 1, 4, 4),
    panel("Responses by code and destination", "timeseries",
          [target(istio_rate("response_code, destination_service_name", GW), "{{response_code}} → {{destination_service_name}}")], 0, 5, 12, 8, "reqps"),
    panel("Limits: allowed vs limited per limit namespace", "timeseries", [
        target('sum by (limitador_namespace) (rate(authorized_calls[2m]))', "allowed {{limitador_namespace}}"),
        target('sum by (limitador_namespace) (rate(limited_calls[2m]))', "limited {{limitador_namespace}}")], 12, 5, 12, 8, "reqps",
          desc="One limit namespace per policy target: parasol-insurance-prod/parasol-api (API), parasol-gateway/llm (token budgets)"),

    row("Authorino", 13),
    panel("Auth decisions by status", "timeseries", [target('sum by (status) (rate(auth_server_response_status[2m]))', "{{status}}")], 0, 14, 8, 7, "reqps"),
    panel("AuthConfig evaluation p95", "timeseries",
          [target('histogram_quantile(0.95, sum by (le) (rate(auth_server_authconfig_duration_seconds_bucket[5m])))', "p95")], 8, 14, 8, 7, "s"),
    panel("Kuadrant wasm shim: allowed vs denied", "timeseries", [
        target('sum(max by (pod) (rate(kuadrant_allowed[2m])))', "allowed"), target('sum(max by (pod) (rate(kuadrant_denied[2m])))', "denied")], 16, 14, 8, 7, "reqps"),

    row("LLM gateway (llm.parasol-gateway.svc: TokenRateLimitPolicy)", 21),
    panel("LLM calls allowed vs limited", "timeseries", [
        target('sum by (limitador_namespace) (rate(authorized_calls{limitador_namespace=~".*llm.*"}[2m]))', "allowed {{limitador_namespace}}"),
        target('sum by (limitador_namespace) (rate(limited_calls{limitador_namespace=~".*llm.*"}[2m]))', "limited {{limitador_namespace}}")], 0, 22, 12, 7, "reqps"),
    panel("LLM responses by code (in-mesh callers → gateway llm listener)", "timeseries",
          [target(istio_rate("response_code", 'destination_service_name="llm",destination_service_namespace="parasol-gateway"'), "{{response_code}}")], 12, 22, 12, 7, "reqps",
          desc="200 = forwarded to the model provider, 401 = missing team key, 429 = token budget exhausted"),
])

out = sys.argv[1]
os.makedirs(out, exist_ok=True)
for d in (overview, rhcl):
    with open(os.path.join(out, d["uid"] + ".json"), "w") as f:
        json.dump(d, f, indent=1)
    print("wrote", d["uid"] + ".json")
