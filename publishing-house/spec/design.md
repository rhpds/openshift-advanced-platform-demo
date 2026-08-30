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

**Learner view:** The RHDP demo CI (`ocp4-adv-app-platform-demo`) is pre-provisioned and accessible via catalog.demo.redhat.com. During instructor-led highlight walkthroughs (Modules 2–4), the instructor drives the demo on a projected screen while participants observe and take notes. For the hands-on practice module (Module 5), each participant accesses their own provisioned demo instance to run one selected module end-to-end.

The environment includes a multi-node OpenShift cluster with all operators pre-installed (DevSpaces, Pipelines, GitOps, Service Mesh, Developer Hub, ACS, TAS, TPA, KEDA, External Secrets Operator), a GitLab instance, SonarQube, HashiCorp Vault, and an external LiteLLM endpoint for the AI module. Two Argo CD instances are configured: `rhdh-gitops` for application delivery and `openshift-gitops` for cluster bootstrap.

**Automation needed:** No — the demo environment is pre-provisioned by RHDP infrastructure. Participants provision their own instance via the catalog for Module 5.

## Infrastructure Requirements

- **Cloud provider:** TBD — confirmed in infrastructure phase
- **Cluster type:** TBD — confirmed in infrastructure phase
- **OCP version:** TBD — confirmed in infrastructure phase
- **Topology:** TBD — confirmed in infrastructure phase
- **Sizing:** TBD — confirmed in infrastructure phase
- **Automation approach:** TBD — confirmed in infrastructure phase
- **AI/MaaS:** TBD — confirmed in infrastructure phase
- **External services:** TBD — confirmed in infrastructure phase
- **Non-GA products:** TBD — confirmed in infrastructure phase
