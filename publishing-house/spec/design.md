# OpenShift Advanced Application Platform Demo Lab

## Overview

This lab enables sales engineers and solution architects to deliver the OpenShift Advanced Application Platform demo by providing hands-on experience with every section of the demo CI. Participants work through seven modules covering the full application lifecycle on OpenShift: developer inner loop with Dev Spaces, CI/CD with Tekton and Argo CD, platform operations with service mesh and autoscaling, Developer Hub self-service, software supply chain security with ACS/TAS/Tekton Chains, and AI-enhanced application features using LLM integration. Each participant gets a dedicated OpenShift environment with the Parasol Insurance demo application pre-deployed, along with all supporting infrastructure (GitLab, SonarQube, Vault, Keycloak SSO, Kafka, LLM endpoint).

## Target Audience

- **Role:** Sales engineers, solution architects, technical sellers
- **Experience level:** Advanced
- **What they already know:** Kubernetes and OpenShift fundamentals, CI/CD concepts and pipelines, Java and Quarkus basics, Git workflows, service mesh concepts, container security basics, LLM integration patterns
- **What they don't know:** How to effectively present and navigate the specific Advanced Application Platform demo CI, the end-to-end narrative connecting developer experience through supply chain security to AI integration, product-specific talk tracks and recovery steps for live demo delivery

## Prerequisites

- Familiarity with OpenShift web console navigation and CLI
- Basic understanding of CI/CD pipelines (Tekton or equivalent)
- Experience with Git-based workflows
- Awareness of container image security concepts (scanning, signing, SBOMs)
- The lab cannot validate these prerequisites automatically; they are assumed based on the target role

## Learning Objectives

1. Demonstrate the OpenShift developer inner loop using Dev Spaces and Quarkus dev mode to build and test application features
2. Deploy applications through automated CI/CD pipelines using Red Hat OpenShift Pipelines and Red Hat OpenShift GitOps
3. Configure platform operations including service mesh traffic policies, autoscaling, and external secrets management
4. Explore Red Hat Developer Hub software catalog and provision applications using golden path templates
5. Secure the software supply chain using image scanning, SBOM generation, artifact signing, and policy validation
6. Integrate AI-powered capabilities into a Quarkus application using LLM endpoints and LangChain4j

## Content Type

Lab (hands-on, per-student)

## Products & Technologies

- Red Hat OpenShift Container Platform
- Red Hat OpenShift Dev Spaces
- Red Hat OpenShift Pipelines (Tekton)
- Red Hat OpenShift GitOps (Argo CD)
- Red Hat OpenShift Service Mesh (Istio ambient mode)
- Red Hat build of Quarkus
- Red Hat Developer Hub
- Red Hat Developer Lightspeed
- Red Hat Advanced Cluster Security for Kubernetes
- Red Hat Trusted Artifact Signer (Tekton Chains)
- Red Hat Trusted Profile Analyzer
- Red Hat AMQ Streams (Apache Kafka)
- Conforma (formerly Enterprise Contract)
- Dependency Analytics (IDE plugin)
- Migration Toolkit for Applications (referenced in talk track)
- SonarQube (third-party, in-cluster)
- HashiCorp Vault (third-party, in-cluster)
- External Secrets Operator (third-party)
- GitLab (third-party, in-cluster)
- Kiali (third-party)
- Red Hat Quay
- Red Hat build of Keycloak (SSO)
- LiteMaaS (external LLM endpoint)

## Module Map

| Module | Title | Duration |
|--------|-------|----------|
| 1 | Developer Experience | 30 min |
| 2 | CI/CD Pipeline | 15 min |
| 3 | Platform Operations | 20 min |
| 4 | Developer Hub | 15 min |
| 5 | Secure Development | 15 min |
| 6 | Trusted Software Supply Chain | 10 min |
| 7 | AI-Enhanced Applications | 15 min |
| -- | **Total hands-on** | **2 hours** |
| -- | Intro / overview / setup | ~25 min |
| -- | **Total lab** | **~2.5 hours** |

## Difficulty Level

Advanced

## Environment

**Learner view:** Each participant receives a dedicated OpenShift multinode cluster with the Parasol Insurance application fully deployed across dev, stage, and prod namespaces. All required operators are pre-installed (Dev Spaces, Pipelines, GitOps, Service Mesh, ACS, TAS, TPA, External Secrets, RHDH). Supporting services are running in-cluster: GitLab with pre-populated repositories, SonarQube for code quality, HashiCorp Vault for secrets, Keycloak for SSO, Kafka for messaging, and Kiali for service mesh observability. Two personas are available via Keycloak SSO: a developer user and a platform engineer user. An LLM endpoint is accessible via LiteMaaS for AI module exercises.

**Automation needed:** Yes

- All OpenShift operators listed above must be installed and configured
- Parasol Insurance application deployed across multiple namespaces with Argo CD
- GitLab instance with pre-populated source code repositories and GitOps configuration repos
- SonarQube instance with quality profiles configured
- HashiCorp Vault with pre-seeded secrets
- Keycloak realm with developer and platform engineer users
- Kafka cluster with required topics
- Tekton pipelines and tasks pre-configured
- Service mesh control plane configured in ambient mode
- RHDH instance with software catalog entries and golden path templates
- LiteMaaS LLM endpoint connectivity

## Infrastructure Requirements

TBD -- confirmed in infrastructure phase
