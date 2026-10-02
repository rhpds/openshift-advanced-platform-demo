# Module 03 — Section 1 Live Walkthrough: Foundational App Platform

## Brief Overview

The instructor delivers Section 1 of the Advanced App Platform demo live, at the front of the room. Each group's driver follows along in their shared RHDP instance in real time. This section covers the developer inner loop, CI/CD pipeline security, GitOps delivery, and platform operations. Q&A is held at the end of the section. Timing within the section is flexible — the instructor controls pace and can compress or expand any area based on audience engagement.

## Audience and Time

- **Roles:** Red Hat Solution Architects, Technical Sales Specialists — intermediate
- **Prerequisites for this module:** Module 02 complete; group instances verified
- **Duration:** ~30 minutes (demo walkthrough + Q&A). Flexible — compress if questions are light, expand if the room is engaged.

## Learning Objectives

- Navigate Section 1 of the demo from start to finish alongside the instructor
- Identify the peak moments in Section 1 and the customer message each one carries
- Recall at least two objection responses relevant to the Foundational App Platform narrative

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Developer inner loop — Dev Spaces and MTA context | 5 min |
| 2 | CI/CD pipeline — broken build and Roo Code AI fix | 7 min |
| 3 | Argo CD GitOps delivery | 5 min |
| 4 | Platform operations — Kiali, Connectivity Link (optional layer), HPA, Vault external secrets | 10 min |
| 5 | Q&A | ~3 min |

## Demo Flow (Section 1)

The instructor follows the standard demo script for the `ocp4-adv-app-platform-demo` Section 1. Key beats, in order:

1. **Developer inner loop — Dev Spaces**
   Parasol developer opens their pre-configured Dev Spaces workspace. No local setup. Talking point: "The developer's full environment is in the cluster — reproducible, governed, no 'works on my machine.'"

2. **MTA context** *(brief)*
   Mention Migration Toolkit for Applications as the path that brought this application from a legacy runtime to the modern platform.

3. **CI/CD pipeline — the broken build**
   A SonarQube SAST scan flags a security issue in the code. The pipeline fails. Talking point: "Security is not a gate at the end — it's woven into every pipeline run."

4. **Roo Code AI fix**
   The developer uses the Roo Code AI assistant to identify and fix the flagged code. Pipeline re-runs and passes. Talking point: "AI-assisted development doesn't mean removing the guardrails — it means moving through them faster."

5. **Argo CD GitOps delivery**
   The fixed application is deployed via Argo CD. Show the sync status and the application health view. Talking point: "Every change to production is declared in Git and reconciled automatically — no manual kubectl, no drift."

6. **Platform operations — Kiali traffic graph**
   Show the live service mesh traffic graph. Talking point: "Platform teams get real-time observability of inter-service traffic without instrumenting individual applications."

6b. **Connectivity Link — governed API entry point** *(only on instances prepared with the optional RHCL layer, see 02-details)*
   Show the `parasol-gateway` gateway and the `parasol-api` HTTPRoute in the console, then three curls from the Web Terminal: 401 without an API key, 200 with the `partner1` key, 429 after ten calls in ten seconds. Talking point: "Who may call the API and how much is a platform policy in Git, not application code. The app and its route did not change."

7. **HPA autoscaling** *(brief)*
   Show the Horizontal Pod Autoscaler responding to load. Talking point: "The platform scales to demand automatically — no 2am pager for a traffic spike."

8. **Vault external secrets**
   Show the External Secrets Operator pulling a credential from HashiCorp Vault into a Kubernetes secret without the developer ever seeing the secret value. Talking point: "Secrets never live in Git, never live in application code — they're managed centrally and rotated without redeployment."

## Q&A

Hold Q&A at the end of Section 1. Common questions at this point:

- *"How long does the Dev Spaces workspace take to start?"* — Cold start is 2–3 minutes; warm start (pre-built image) is under 30 seconds. Pre-building is the recommended pattern for a customer demo.
- *"Does this require Service Mesh for every application?"* — No. Kiali and the traffic graph are valuable for microservices-heavy workloads. Single-service applications don't need it.
- *"Can Argo CD manage non-OCP targets?"* — Yes, it is cluster-agnostic. In this demo it targets OCP, but it can sync to any Kubernetes-compatible cluster.
- *"Is Vault required, or can we use OCP secrets?"* — OCP native secrets work. Vault is shown because it is the most common enterprise secrets management tool SAs encounter in the field.

## Key Takeaways

- The peak moments are the Roo Code AI fix and the Argo CD sync — every step before is setup, every step after is reinforcement
- Section 1 can be compressed to ~15 minutes by skipping MTA context and HPA; the narrative still holds
- Drivers should follow one step behind the instructor — observers learn by watching both screens simultaneously

## Instructor Notes

- If time is tight, compress beats 2 (MTA context) and 7 (HPA). These are supporting context, not peak moments.
- The peak moments in Section 1 are the Roo Code AI fix (beat 4) and the Argo CD sync (beat 5). Build toward those.
- Encourage drivers to follow along one step behind the instructor — not to race ahead. Observers should watch the instructor screen and their group's instance side-by-side.
- If a group's instance falls behind or hits an error, advise them to switch to observation mode and catch up independently after the session. Do not stop the room for one group.
