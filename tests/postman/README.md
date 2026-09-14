# Postman tests — Parasol Advanced App Platform

Smoke and policy tests for a provisioned `ocp4-adv-app-platform-demo` instance, including the Connectivity Link layer added by `scripts/post-provision.sh` (`WITH_RHCL=1`).

## Files

| File | What |
|---|---|
| `parasol-platform.postman_collection.json` | The collection: 7 folders, 30 requests, ~55 assertions |
| `parasol-platform.postman_environment.json` | Environment with the instance domain and the two secrets you fill in |

## Setup (2 minutes)

1. Postman → **Import** → drop both files.
2. Select the environment **Parasol demo instance** and set:
   - `domain`: ingress domain of the instance (`oc get ingresses.config cluster -o jsonpath='{.spec.domain}'`)
   - `cluster_domain`: same without the `apps.` prefix
   - `partner_api_key`: `oc get secret parasol-api-key-partner1 -n kuadrant-system -o jsonpath='{.data.api_key}' | base64 -d`
   - `ocp_token` (folder 5 only): `oc whoami -t` as cluster admin
   - `platform_api_key` (folders 6 and 7): `oc get secret platform-key-demo -n kuadrant-system -o jsonpath='{.data.api_key}' | base64 -d`
3. Settings → turn **SSL certificate verification** off (the instance uses the cluster's self-signed ingress certificate).

## Running (roteiro)

| Step | Folder | How | Expected |
|---|---|---|---|
| 1 | **1. Platform endpoints** | Runner, 1 iteration | All green. A `500` on the RHDH login request means Developer Hub started before Keycloak: `oc rollout restart deployment/backstage-developer-hub -n rhdh` |
| 2 | **2. Parasol application** | Runner, 1 iteration | All green. `503` on dev or secured prod after an instance restart: run `scripts/post-provision.sh` (it restarts db + app) |
| 3 | **3. Connectivity Link: governed API** | Runner, 1 iteration | 401 without key, 401 with a wrong key, 200 with the partner key, 404 outside `/api` |
| 4 | **4. Connectivity Link: rate limit** | Runner, **14 iterations, delay 0 ms**, this folder only | 9–11 × `200` then `429`; the last iteration asserts the count |
| 5 | **5. developer portal objects** | Runner, 1 iteration, needs `ocp_token` | APIProduct published, AuthPolicy Enforced |
| 6 | **6. MCP server of Developer Hub** | Runner, 1 iteration, needs `platform_api_key` | 401 without key, `initialize` answered by the `backstage` MCP server, `tools/list` offers the catalog and TechDocs tools, `tools/call` returns the Parasol component; a wrong key is 401 |
| 7 | **7. End-to-end trace** | Runner, 1 iteration, needs `partner_api_key` and `platform_api_key` | The traced call is 200; its trace (fetched from Tempo through the gateway) has the OSSM gateway span, the Authorino and Limitador spans, and the gateway's upstream is the Parasol prod service |

Run folders 3 and 4 at least 10 seconds apart: the rate limit window is 10 seconds per consumer and folder 3 consumes 2 of the 10 calls. Folder 6 uses 4 of the 10 MCP calls per 10 s; folder 7 waits 8 s for Tempo before reading the trace.

Folders 6 and 7 need the MCP and traces layers (`scripts/rhcl/mcp-gateway.sh`, `scripts/observability/traces-api.sh`, both run by `post-provision.sh` with `WITH_RHCL=1 WITH_OBSERVABILITY=1`).

## Command line (Newman)

```bash
npm i -g newman
newman run parasol-platform.postman_collection.json -e parasol-platform.postman_environment.json \
  --env-var partner_api_key="$(oc get secret parasol-api-key-partner1 -n kuadrant-system -o jsonpath='{.data.api_key}' | base64 -d)" \
  --env-var ocp_token="$(oc whoami -t)" --insecure --folder "1. Platform endpoints" --folder "2. Parasol application" --folder "3. Connectivity Link: governed API"
newman run parasol-platform.postman_collection.json -e parasol-platform.postman_environment.json \
  --env-var partner_api_key="$(oc get secret parasol-api-key-partner1 -n kuadrant-system -o jsonpath='{.data.api_key}' | base64 -d)" \
  --insecure --folder "4. Connectivity Link: rate limit (run with delay 0 ms)" -n 14
newman run parasol-platform.postman_collection.json -e parasol-platform.postman_environment.json \
  --env-var partner_api_key="$(oc get secret parasol-api-key-partner1 -n kuadrant-system -o jsonpath='{.data.api_key}' | base64 -d)" \
  --env-var platform_api_key="$(oc get secret platform-key-demo -n kuadrant-system -o jsonpath='{.data.api_key}' | base64 -d)" \
  --insecure --folder "6. Connectivity Link: MCP server of Developer Hub" --folder "7. End-to-end trace: OSSM gateway + Connectivity Link + backend"
```

## Not covered here (needs in-cluster access or a browser session)

- The LLM gateway (`http://llm.parasol-gateway.svc/v1`) is only reachable inside the cluster: `scripts/rhcl/llm-gateway.sh` tests it (401 / 200 / 429 by tokens).
- The backend itself (Quarkus) emits no spans of its own (no OpenTelemetry extension in the demo image), so the trace ends at the gateway's hop to `parasol-insurance`; the response code and latency of that hop are on the gateway span.
- Developer Hub pages behind login (RBAC, Connectivity Link tabs): `scripts/rhdh-kuadrant/walk-rhdh.mjs` drives them as `dev1` and `pe1`.
- Everything above and the cluster-side checks in one go: `scripts/validate-instance.sh`.
