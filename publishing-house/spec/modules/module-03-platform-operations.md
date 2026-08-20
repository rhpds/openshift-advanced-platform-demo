# Module Outline: Platform Operations

## Brief Overview

This module shifts to the platform engineer perspective, covering operational concerns for running applications at scale on OpenShift. Participants configure service mesh mTLS and traffic policies, use Kiali for observability and fault injection testing, set up Horizontal Pod Autoscaler with a load test, and integrate HashiCorp Vault for external secrets management.

## Audience and Time

- **Target personas:** Sales engineers, solution architects presenting to platform engineering and operations audiences
- **Prerequisites:** Basic understanding of service mesh concepts (sidecar vs. ambient), familiarity with Kubernetes scaling primitives, awareness of secrets management challenges
- **Estimated duration:** 20 min

## Learning Objectives

- Configure Red Hat OpenShift Service Mesh traffic policies and mTLS enforcement for application workloads
- Observe application behavior using Kiali service mesh visualization and simulate faults for resilience testing
- Scale applications automatically using Horizontal Pod Autoscaler under simulated load
- Manage application secrets securely using External Secrets Operator with HashiCorp Vault

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Service Mesh mTLS and Traffic Policies | 5 min |
| 2 | Kiali Observability and Fault Injection | 5 min |
| 3 | HPA Autoscaling with Load Test | 5 min |
| 4 | External Secrets with Vault | 5 min |

## Detailed Steps

1. Navigate to the OpenShift Service Mesh configuration and review the ambient mode control plane
2. Demonstrate mTLS enforcement between services in the Parasol Insurance application
3. Configure traffic policies (e.g., traffic shifting, request routing) for a canary deployment scenario
4. Open the Kiali dashboard and explore the service graph for the Parasol Insurance application
5. Observe real-time traffic flow, success rates, and latency between services
6. Inject a fault (delay or abort) into a service and observe how it propagates through the mesh in Kiali
7. Remove the fault injection and verify service recovery
8. Navigate to the HPA configuration for the Parasol Insurance application workload
9. Review the autoscaling policy (CPU/memory thresholds, min/max replicas)
10. Run a load test against the application endpoint to trigger autoscaling
11. Monitor pod scaling in the OpenShift console and Prometheus/Grafana dashboards
12. Navigate to the External Secrets Operator configuration
13. Show the ExternalSecret resource that references HashiCorp Vault
14. Demonstrate how secrets are automatically synced from Vault into Kubernetes Secrets
15. Verify the application consumes the Vault-managed secret without direct Kubernetes Secret management

## Key Takeaways

- OpenShift Service Mesh (ambient mode) provides mTLS and traffic management without sidecar overhead
- Kiali enables real-time observability and fault injection testing for service mesh workloads
- HPA provides automatic scaling based on real-time metrics, demonstrated under realistic load
- External Secrets Operator bridges enterprise secrets managers (Vault) with Kubernetes-native secret consumption
- Platform engineers can manage all of these capabilities through OpenShift without modifying application code

## Infrastructure Notes

- Service Mesh operator installed in ambient mode with control plane configured
- Kiali instance deployed and connected to the service mesh control plane
- Prometheus and Grafana available for metrics visualization during the autoscaling demo
- HPA resources pre-configured with appropriate thresholds for the load test to trigger scaling
- HashiCorp Vault deployed in-cluster with pre-seeded secrets for the Parasol Insurance application
- External Secrets Operator installed with ClusterSecretStore configured to point at Vault
