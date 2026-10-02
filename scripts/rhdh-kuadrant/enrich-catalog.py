import yaml, sys, copy
S = sys.argv[1]; D = sys.argv[2]
CON = f"https://console-openshift-console.{D}"
LINKS_COMMON = {
    "kafka":  {"url": f"https://streams-console.{D}/", "title": "Kafka (Streams console)", "icon": "cloud"},
    "acs":    {"url": f"https://central-stackrox.{D}/main/vulnerability-management/workload-cves", "title": "ACS: workload CVEs", "icon": "alert"},
    "tpa":    {"url": f"https://server-trusted-profile-analyzer.{D}/sboms", "title": "TPA: SBOMs and vulnerabilities", "icon": "docs"},
    "rekor":  {"url": f"https://rekor-search-ui-trusted-artifact-signer.{D}/", "title": "TAS: signature transparency log (Rekor)", "icon": "search"},
    "sonar":  {"url": f"https://sonarqube-sonarqube.{D}/dashboard?id=parasol-insurance", "title": "SonarQube quality gate", "icon": "dashboard"},
    "vault":  {"url": f"https://vault-vault.{D}/ui/vault/secrets/kv/list/secrets/", "title": "Vault secrets", "icon": "lock"},
    "rhcl":   {"url": f"{CON}/kuadrant/policies/ns/parasol-insurance-prod", "title": "Connectivity Link: policies", "icon": "cloud"},
    "apiprod":{"url": f"https://backstage-developer-hub-rhdh.{D}/kuadrant/api-products", "title": "Connectivity Link: API Products (Developer Hub)", "icon": "catalog"},
}
def links_for(name):
    ns_dev, ns_prod = (f"{name}-dev", f"{name}-prod")
    repo = "parasol/parasol-insurance" if name == "parasol-insurance" else "parasol/parasol-insurance-secured"
    L = [
        {"url": f"https://rhdh-gitops-server-rhdh-gitops.{D}/applications/rhdh-gitops/{ns_prod}", "title": "Argo CD: production app", "icon": "cloud"},
        {"url": f"{CON}/topology/ns/{ns_prod}?view=graph", "title": "OpenShift topology (prod)", "icon": "dashboard"},
        {"url": f"https://kiali-istio-system.{D}/console/graph/namespaces/?namespaces={ns_prod}%2Ckafka&graphType=workload", "title": "Kiali: service graph (prod)", "icon": "dashboard"},
        {"url": f"https://quay.{D}/repository/{repo}", "title": "Quay repository", "icon": "cloud"},
        {"url": f"https://gitlab-gitlab.{D}/parasol/parasol-insurance", "title": "Source (GitLab)", "icon": "github"},
        LINKS_COMMON["sonar"], LINKS_COMMON["kafka"], LINKS_COMMON["acs"], LINKS_COMMON["tpa"], LINKS_COMMON["rekor"], LINKS_COMMON["vault"],
    ]
    if name == "parasol-insurance":
        L += [LINKS_COMMON["rhcl"], LINKS_COMMON["apiprod"]]
    return L

docs = list(yaml.safe_load_all(open(f"{S}/components.yaml")))
for d in docs:
    n = d["metadata"]["name"]
    a = d["metadata"].setdefault("annotations", {})
    a["gitlab.com/project-slug"] = "parasol/parasol-insurance"          # source repo for both (secured builds from the same code)
    a["sonarqube.org/project-key"] = "parasol-insurance"
    a["quay.io/repository-slug"] = "parasol/parasol-insurance" if n == "parasol-insurance" else "parasol/parasol-insurance-secured"
    a["backstage.io/kubernetes-namespace"] = f"{n}-prod"
    a["kiali.io/provider"] = "default"
    a["kiali.io/namespace"] = f"{n}-prod"
    a["acs/deployment-name"] = n                                        # ACS "Security" tab (Deployment name in the prod namespace)
    d["metadata"]["links"] = links_for(n)
    d["metadata"].setdefault("tags", [])
    for t in (["quarkus", "java", "kafka", "postgresql"] + (["ai", "llm"] if n.endswith("secured") else [])):
        if t not in d["metadata"]["tags"]: d["metadata"]["tags"].append(t)
    spec = d["spec"]
    deps = ["resource:default/kafka-cluster", "resource:default/parasol-db"] + (["resource:default/llm-inference-server"] if n.endswith("secured") else [])
    spec["dependsOn"] = deps
    if n == "parasol-insurance":
        spec["providesApis"] = ["parasol-insurance-api", "parasol-claims-api"]
    else:
        spec["providesApis"] = ["parasol-insurance-api"]
        spec["consumesApis"] = ["parasol-claims-api"] if False else spec.get("consumesApis", [])
        spec.pop("consumesApis", None)
open(f"{S}/components.new.yaml", "w").write("---\n".join(yaml.safe_dump(d, sort_keys=False) for d in docs))

res = list(yaml.safe_load_all(open(f"{S}/resources.yaml")))
kafka = res[0]
kafka["metadata"]["links"] = [LINKS_COMMON["kafka"], {"url": f"{CON}/k8s/ns/kafka/kafka.strimzi.io~v1beta2~Kafka/kafka", "title": "Kafka CR (OpenShift console)", "icon": "cloud"}]
kafka["metadata"].setdefault("annotations", {})["backstage.io/kubernetes-namespace"] = "kafka"
kafka["metadata"]["annotations"]["backstage.io/kubernetes-label-selector"] = "strimzi.io/cluster=kafka"
kafka["spec"]["system"] = "parasol-insurance"
db = {"apiVersion": "backstage.io/v1alpha1", "kind": "Resource",
      "metadata": {"name": "parasol-db", "description": "PostgreSQL database of the Parasol application (one per environment namespace)",
                   "tags": ["postgresql", "database"],
                   "annotations": {"backstage.io/kubernetes-label-selector": "app=parasol-db", "backstage.io/kubernetes-namespace": "parasol-insurance-prod"},
                   "links": [{"url": LINKS_COMMON["vault"]["url"], "title": "Credentials in Vault", "icon": "lock"}]},
      "spec": {"type": "database", "lifecycle": "production", "owner": "platformengineers", "system": "parasol-insurance"}}
open(f"{S}/resources.new.yaml", "w").write("---\n".join(yaml.safe_dump(d, sort_keys=False) for d in [kafka, db]))

api = yaml.safe_load(open(f"{S}/api.yaml"))
api["metadata"].setdefault("annotations", {})["gitlab.com/project-slug"] = "parasol/parasol-insurance"
api["metadata"]["links"] = [
    {"url": f"https://parasol-api-parasol-insurance-prod.{D}/api/claims", "title": "Governed endpoint (Connectivity Link)", "icon": "cloud"},
    {"url": f"https://parasol-insurance-parasol-insurance-prod.{D}/api/claims", "title": "Direct endpoint (prod)", "icon": "cloud"},
    LINKS_COMMON["apiprod"], LINKS_COMMON["rhcl"],
]
open(f"{S}/api.new.yaml", "w").write(yaml.safe_dump(api, sort_keys=False))
print("ok")
