# Module 02 — Section 1 Highlights: Foundational App Platform

## Brief Overview

This module delivers a focused, instructor-led walkthrough of the demo's first section — Foundational App Platform — which spans three source demo modules: the developer inner loop (Module 1, ~30 min full), the CI/CD pipeline (Module 2, ~15 min full), and platform operations (Module 3, ~20 min full). Rather than re-running all 65 minutes, participants receive the highlight moments and the talking points that make each demonstration beat land effectively with customers. Key objections for the DevEx, pipeline security, and platform ops domains are addressed in context.

## Audience and Time

- **Roles:** Red Hat Solution Architects, Technical Sales Specialists — intermediate
- **Prerequisites for this module:** Module 01 complete; participants should have the Parasol Insurance narrative framing
- **Duration:** 20 minutes

## Learning Objectives

- Demonstrate the developer inner-loop workflow using Dev Spaces one-click workspace and MTA modernization context
- Explore the CI/CD pipeline execution, including the SonarQube SAST failure and Roo Code AI-assisted remediation flow
- Demonstrate Argo CD GitOps delivery and the Kiali traffic management visualization for platform operations positioning
- Analyze the key talking points for HPA autoscaling and Vault external secrets in a platform ops customer conversation

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Source Module 1 highlight: Dev Spaces workspace launch + MTA context | 5 min |
| 2 | Source Module 2 highlight: CI/CD pipeline — SAST failure and AI-assisted fix | 5 min |
| 3 | Source Module 2 highlight: Argo CD GitOps delivery sync | 3 min |
| 4 | Source Module 3 highlight: Kiali traffic graph and HPA autoscaling | 5 min |
| 5 | Source Module 3 highlight: Vault external secrets and objection handling | 2 min |

## Detailed Steps

1. Open the DevSpaces dashboard in the browser; show the one-click workspace launch button sourced from the GitLab repo URL — emphasize the "zero local toolchain setup" message for developer productivity audiences.
2. While the workspace loads, explain the MTA modernization context: the Parasol policy management app was analyzed by Migration Toolkit for Applications, which identified the Java EE patterns to refactor before DevSpaces was used for the active development work.
3. Once the workspace is open, show Quarkus dev mode running in the integrated terminal — send an HTTP request and show the live reload response; connect to "seconds, not minutes" developer feedback loops.
4. From the DevSpaces terminal, trigger a `git push` to the feature branch to initiate the Tekton pipeline via GitLab webhook.
5. Switch to the OpenShift Pipelines UI; walk through the pipeline stages from left to right — source clone, unit test, SonarQube SAST scan, image build, push, deploy.
6. Pause at the SonarQube SAST gate failure: show the code smell violation details in the pipeline log. Key message: "The platform enforces code quality gates so developers can't accidentally ship insecure code."
7. Switch back to DevSpaces; show Roo Code AI in the editor sidebar suggesting the specific line fix for the flagged smell. Apply the suggestion, commit, push — pipeline turns green.
8. Navigate to the Argo CD UI (`rhdh-gitops` instance); show the application syncing from the updated Git commit to the target namespace. Key message: "GitOps means the platform enforces what developers intend — the cluster state is always provably derived from Git."
9. Open Kiali for the Parasol namespace; show the traffic graph with stable and canary routing split. Message: "Service Mesh gives the ops team real-time visibility into what is talking to what and how."
10. Open the OpenShift metrics view; show KEDA/HPA scaling pods in response to the load generator. Message: "The platform self-heals and right-sizes automatically — no 2am pager calls for manual scaling."
11. Navigate to External Secrets Operator CR and Vault; show the secret sync without any credential in the Git repo. Message: "Secrets never land in Git; Vault is the single source of truth."
12. Cover top Section 1 objections: "We already have Jenkins" → Jenkins doesn't integrate developer experience, security gates, and GitOps in a single platform view; "Why Tekton without plain Kubernetes?" → OpenShift Pipelines adds the RBAC, UI, and operator lifecycle that raw Tekton lacks; "Our security team won't allow external SAST" → SonarQube runs on-cluster; nothing leaves the environment.

## Key Takeaways

- The DevSpaces one-click workspace launch is the strongest developer productivity visual in the entire demo — always include it for AppDev audiences, even in short sessions
- The SonarQube failure → Roo Code fix arc is a self-contained 3-minute story that works independently for security-focused audiences
- Argo CD's application sync view is the most intuitive GitOps visualization available — avoid CLI-heavy alternatives during a live customer demo
- Vault + External Secrets is a trust signal for platform ops and security audiences; it deserves 90 seconds even in a truncated delivery

## Infrastructure Notes

- The CI/CD demo requires an active GitLab webhook; confirm webhook delivery is working in the GitLab repo settings before the customer session
- SonarQube SAST scan typically runs 2-3 minutes; for an instructor-led walkthrough, pre-trigger the pipeline and join mid-run rather than waiting from the start
- KEDA/HPA autoscaling requires the load generator to run for ~60 seconds before scaling becomes visible; pre-stage the load generator before this section
