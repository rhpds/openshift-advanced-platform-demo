# Delivering the Advanced App Platform Demo: An Enablement Lab for Red Hat SAs

## Overview

This 2-hour instructor-led enablement session prepares Red Hat SAs and technical sellers to confidently deliver the OpenShift Advanced App Platform demo (ocp4-adv-app-platform-demo) to enterprise customers. The session opens with a 15-minute overview of the Parasol Insurance business narrative, the three-section demo structure, and the core customer messages. Attendees then form 20 groups of 5 and receive a shared pre-provisioned RHDP demo instance; one group member drives at any time while the others observe. The instructor then delivers the full demo live — all three sections, with Q&A at the end of each — while each group's driver follows along in their shared instance. There is no separate hands-on segment: the live follow-along is the practice. If time runs short due to questions, reaching the end of Section 2 is the minimum viable outcome; Section 3 is time-permitting, with SAs encouraged to work through it independently after the event using their own RHDP instance.

## Target Audience

- **Role:** Red Hat Solution Architects, Technical Sales Specialists, Partner Solution Architects
- **Experience level:** Intermediate
- **What they already know:** OpenShift console navigation, basic Kubernetes concepts (pods, namespaces, deployments), Git fundamentals, familiarity with the RHDP demo catalog
- **What they don't know:** The specific narrative arc, section sequencing, and objection handling for this demo; the integration points between DevSpaces, Pipelines, GitOps, Developer Hub, ACS, TAS, TPA, and the AI/LLM workflow; how to scope and customize the demo for a given customer context

## Prerequisites

- Familiarity with OpenShift Container Platform concepts (console navigation, namespaces, basic workload management)
- No deep expertise in any individual product is required; this lab assumes breadth over depth

Note: Participants do not need individual RHDP accounts for this session — the RHDP team pre-provisions one instance per group and provides login credentials at the start of the session. Attendees who want to practice independently after the event will need their own RHDP access.

## Learning Objectives

1. Describe the Parasol Insurance business narrative and connect each demo section to measurable customer business outcomes
2. Follow along with the instructor through all three demo sections in a shared live RHDP environment, building familiarity with the navigation flow and key talking points
3. Recall the differentiation messages and objection responses for each of the three demo sections
4. Identify which sections to prioritize given different customer contexts and time constraints
5. Practice the full demo independently using the RHDP live environment after the session

## Assessment Strategy

No formal assessment. This is an instructor-led session with no quiz, no automated validation, and no pass/fail gate. Assessment is formative and self-directed:

- **During the session:** Real-time Q&A at the end of each section surfaces comprehension gaps; the instructor addresses them live. The live follow-along in the group instance provides immediate feedback on navigation familiarity.
- **Post-session:** Participants self-assess readiness for a first customer delivery by completing at least one independent practice run of their target section(s) using their own RHDP instance. No tracked completion is required.
- **Completion signal:** An SA is considered ready for a first customer delivery when they can navigate their chosen section end-to-end without referring to the Showroom content.

## Content Type

Lab

## Products & Technologies

**Red Hat Products:**
- Red Hat OpenShift Container Platform
- Red Hat OpenShift Dev Spaces
- Red Hat OpenShift Pipelines
- Red Hat OpenShift GitOps
- Red Hat OpenShift Service Mesh
- Red Hat Connectivity Link (optional layer added post-provisioning; Module 3, Part 1b)
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
| 1 | Demo Overview: Story, Structure, and Customer Message | 15 min |
| 2 | Group Formation and Instance Setup | 10 min |
| 3 | Section 1 Live Walkthrough: Foundational App Platform | ~30 min incl. Q&A |
| 4 | Section 2 Live Walkthrough: Advanced Developer Services | ~30 min incl. Q&A *(minimum endpoint)* |
| 5 | Section 3 Live Walkthrough: Intelligent Applications | ~25 min incl. Q&A *(time permitting)* |
| — | **Total** | **~2 hours** |

## Difficulty Level

Intermediate

## Environment

**Two-Showroom approach:** This CI is the enablement Showroom (5 teaching modules). The original demo Showroom — the `ocp4-adv-app-platform-demo` catalog item — is a separate, unchanged CI that serves as both the reference environment and the hands-on practice environment. Participants use both: this Showroom for teaching content, the demo Showroom for the hands-on module.

**Learner view:** The RHDP demo CI (`ocp4-adv-app-platform-demo`) is pre-provisioned by the RHDP team before the session — one instance per group of 5 (20 instances total for 100 attendees, plus one for the instructor). Each group receives a single set of login credentials at the start of the session. One group member drives at any time; the driver role can rotate between group members as the group chooses. Provisioning typically takes 20–30 minutes, so instances are ordered well in advance. During Modules 2–4, the instructor drives on a projected screen while each group follows along in this enablement Showroom. For Module 5, each group's driver switches to their shared pre-provisioned demo instance to run one selected module end-to-end with the group observing.

The demo environment includes a multi-node OpenShift cluster with all operators pre-installed (DevSpaces, Pipelines, GitOps, Service Mesh, Developer Hub, ACS, TAS, TPA, KEDA, External Secrets Operator), a GitLab instance, SonarQube, HashiCorp Vault, and an external LiteLLM endpoint for the AI module. Two Argo CD instances are configured: `rhdh-gitops` for application delivery and `openshift-gitops` for cluster bootstrap.

**Automation needed:** No — all instances are provisioned via the RHDP catalog before the session. The event organizer must order 20 instances (one per group) at least 30 minutes before the session starts.

## Infrastructure Requirements

- **Cloud provider:** CNV
- **Cluster type:** Multinode
- **OCP version:** 4.20
- **Topology:** Per-group (modelled as per-student in RHDP — one instance per group of 5, 20 instances peak)
- **Peak concurrent instances:** 20
- **Sizing:** 3 control plane nodes (16 vCPU, 64GB RAM); 6 worker nodes (16 vCPU, 64GB RAM, 200GB disk) — sized for the full operator stack (DevSpaces, Service Mesh, RHDH, ACS, TAS, TPA, Kafka, GitLab, SonarQube, Vault). TODO: right-size after initial delivery; the group format (one driver, four observers) may allow smaller worker sizing than the full customer-facing demo.
- **Automation approach:** GitOps (Helm + ArgoCD) and Ansible
- **AI/MaaS:** MaaS, open-source — LLM endpoint is external to the demo cluster, hosted on Red Hat Demo Platform (`litellm-prod-frontend.apps.maas.redhatworkshops.io`); no GPU on the demo cluster
- **External services:** `litellm-prod-frontend.apps.maas.redhatworkshops.io` (LLM MaaS endpoint), `registry.redhat.io` (Red Hat container images), `quay.io` (pipeline image output), `registry.devfile.io` (DevSpaces devfile catalog), Red Hat advisory/vulnerability databases (Dependency Analytics, TPA CVE data)
- **AAP version:** N/A
- **Non-GA products:** None (all products are GA)
