# Delivering the Advanced App Platform Demo: An Enablement Lab for Red Hat SAs

## Overview

This 2-hour instructor-led enablement session prepares Red Hat SAs and technical sellers to confidently deliver the OpenShift Advanced App Platform demo (ocp4-adv-app-platform-demo) to enterprise customers. Rather than re-running the full 2.5-hour demo, participants receive focused walkthroughs of the three demo sections — targeting key talking points, differentiation messages, and objection handling — followed by a self-selected hands-on practice segment where participants run one demo module end-to-end in the RHDP live demo CI environment. Participants leave with the narrative, the environment knowledge, and at least one complete delivery under their belt.

## Target Audience

- **Role:** Red Hat Solution Architects, Technical Sales Specialists, Partner Solution Architects
- **Experience level:** Intermediate
- **What they already know:** OpenShift console navigation, basic Kubernetes concepts (pods, namespaces, deployments), Git fundamentals, familiarity with the RHDP demo catalog
- **What they don't know:** The specific narrative arc, section sequencing, and objection handling for this demo; the integration points between DevSpaces, Pipelines, GitOps, Developer Hub, ACS, TAS, TPA, and the AI/LLM workflow; how to scope and customize the demo for a given customer context

## Prerequisites

- Familiarity with OpenShift Container Platform concepts (console navigation, namespaces, basic workload management)
- An active RHDP account (catalog.demo.redhat.com) with access to the `ocp4-adv-app-platform-demo` catalog item for the hands-on practice module
- No deep expertise in any individual product is required; this lab assumes breadth over depth

Note: Prerequisites cannot be auto-validated. Participants must confirm RHDP access before the session.

## Learning Objectives

1. Demonstrate the Parasol Insurance business narrative end-to-end, connecting each demo section to measurable customer business outcomes
2. Analyze customer signals to configure the demo scope and module sequence for different audience personas and time constraints
3. Explore the key talking points, differentiation messages, and objection responses for each of the three demo sections
4. Verify the demo environment using the pre-demo checklist and troubleshoot common setup issues before a customer delivery
5. Demonstrate one complete demo module end-to-end independently in the RHDP live demo CI environment

## Content Type

Lab

## Products & Technologies

**Red Hat Products:**
- Red Hat OpenShift Container Platform
- Red Hat OpenShift Dev Spaces
- Red Hat OpenShift Pipelines
- Red Hat OpenShift GitOps
- Red Hat OpenShift Service Mesh
- Red Hat Developer Hub
- Red Hat Advanced Cluster Security for Kubernetes
- Red Hat Trusted Artifact Signer
- Red Hat Trusted Profile Analyzer
- Red Hat AMQ Streams
- Red Hat build of Quarkus
- Migration Toolkit for Applications
- Red Hat OpenShift AI (external LiteLLM endpoint hosting)

**Community / Third-Party (referenced in demo context):**
- GitLab
- SonarQube
- HashiCorp Vault
- External Secrets Operator
- Kiali
- Roo Code AI assistant
- LiteLLM

## Module Map

| Module | Title | Duration |
|--------|-------|----------|
| 1 | Demo Narrative and Delivery Preparation | 20 min |
| 2 | Section 1 Highlights: Foundational App Platform | 20 min |
| 3 | Section 2 Highlights: Advanced Developer Services | 20 min |
| 4 | Section 3 Highlights: Intelligent Applications | 15 min |
| 5 | Hands-On Practice and Q&A | 45 min |
| — | **Total** | **~2 hours** |

## Difficulty Level

Intermediate

## Environment

**Two-Showroom approach:** This CI is the enablement Showroom (5 teaching modules). The original demo Showroom — the `ocp4-adv-app-platform-demo` catalog item — is a separate, unchanged CI that serves as both the reference environment and the hands-on practice environment. Participants use both: this Showroom for teaching content, the demo Showroom for the hands-on module.

**Learner view:** The RHDP demo CI (`ocp4-adv-app-platform-demo`) is pre-provisioned by the event organizer before the session starts — one instance per participant plus one for the instructor. Provisioning typically takes 20–30 minutes, which exceeds the time available during the instructor-led sections, so instances must be ordered in advance. During Modules 2–4, the instructor drives on a projected screen while participants observe and follow along in this enablement Showroom. For Module 5, each participant switches to their pre-provisioned demo instance to run one selected module end-to-end.

The demo environment includes a multi-node OpenShift cluster with all operators pre-installed (DevSpaces, Pipelines, GitOps, Service Mesh, Developer Hub, ACS, TAS, TPA, KEDA, External Secrets Operator), a GitLab instance, SonarQube, HashiCorp Vault, and an external LiteLLM endpoint for the AI module. Two Argo CD instances are configured: `rhdh-gitops` for application delivery and `openshift-gitops` for cluster bootstrap.

**Automation needed:** No — all instances are provisioned via the RHDP catalog before the session. The event organizer must order one instance per participant at least 30 minutes before the session starts.

## Infrastructure Requirements

- **Cloud provider:** CNV
- **Cluster type:** Multinode
- **OCP version:** 4.20
- **Topology:** Per-student
- **Sizing:** 3 control plane nodes (16 vCPU, 64GB RAM); 6 worker nodes (16 vCPU, 64GB RAM, 200GB disk) — sized for the full operator stack (DevSpaces, Service Mesh, RHDH, ACS, TAS, TPA, Kafka, GitLab, SonarQube, Vault). TODO: right-size after initial delivery; the enablement format may require less capacity than the full customer-facing demo.
- **Automation approach:** GitOps (Helm + ArgoCD) and Ansible
- **AI/MaaS:** MaaS, open-source — LLM endpoint is external to the demo cluster, hosted on Red Hat Demo Platform (`litellm-prod-frontend.apps.maas.redhatworkshops.io`); no GPU on the demo cluster
- **External services:** `litellm-prod-frontend.apps.maas.redhatworkshops.io` (LLM MaaS endpoint), `registry.redhat.io` (Red Hat container images), `quay.io` (pipeline image output), `registry.devfile.io` (DevSpaces devfile catalog), Red Hat advisory/vulnerability databases (Dependency Analytics, TPA CVE data)
- **AAP version:** N/A
- **Non-GA products:** None (all products are GA)
