# Module 01 — Demo Narrative and Delivery Preparation

## Brief Overview

This module introduces the Parasol Insurance customer narrative that anchors the entire Advanced App Platform demo. Participants learn how to frame the demo as a coherent business story — a legacy Java EE insurance application being modernized — rather than a product feature tour. They also review environment access procedures and the pre-demo checklist drawn from the source 01-overview.adoc and 02-details.adoc presenter reference pages, and receive an overview of audience-tailoring strategies for different customer personas.

## Audience and Time

- **Roles:** Red Hat Solution Architects, Technical Sales Specialists, Partner Solution Architects
- **Prerequisites for this module:** Active RHDP account; no prior exposure to this demo required
- **Duration:** 20 minutes

## Learning Objectives

- Demonstrate the Parasol Insurance narrative arc, mapping each demo section to a specific customer pain point
- Analyze an audience profile and configure the demo scope to prioritize relevant modules for different buyer personas
- Verify environment access and complete the pre-demo checklist before a customer delivery

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | The Parasol Insurance story — framing the business narrative | 5 min |
| 2 | Audience tailoring and demo scoping strategies | 5 min |
| 3 | Environment access and pre-demo checklist walkthrough | 5 min |
| 4 | Pre-demo objections and Q&A scripting | 5 min |

## Detailed Steps

1. Review the Parasol Insurance business context: an insurance carrier with a legacy Java EE policy management system facing pressure to modernize for digital-first competitors.
2. Identify the three business value messages that map to each demo section: developer velocity and modernization (Section 1), security and supply chain compliance (Section 2), competitive differentiation through AI (Section 3).
3. Explain the discovery question approach from 01-overview.adoc: open with "What is driving your modernization initiative?" to surface which section resonates most.
4. Walk through the audience-tailoring decision tree: AppDev audiences → Sections 1+2; Platform/Ops audiences → Sections 1+3; Security → Section 2 only; Executive → narrative overview, skip deep dives.
5. Log in to catalog.demo.redhat.com and provision the `ocp4-adv-app-platform-demo` catalog item; note the typical 20-30 minute provisioning time and plan accordingly.
6. Navigate the environment access guide from 02-details.adoc: OpenShift console URL, GitLab URL, per-user namespace assignments, DevSpaces browser URL, Argo CD endpoints.
7. Walk through the pre-demo checklist from 02-details.adoc step by step: verify DevSpaces is running, GitLab webhooks are active, Argo CD apps are synced and healthy, LiteLLM endpoint is responding, Vault is unsealed.
8. Review the Q&A scripting guidance from 01-overview.adoc for questions asked before the demo starts: "Why not just use GitHub Actions?", "We already have Tekton", "Is this on-prem only?", "Does this require OpenShift?".

## Key Takeaways

- The Parasol Insurance narrative gives the demo an emotional and business anchor — customers connect with a story before they connect with a product
- The demo is modular; all three sections can be delivered independently or together depending on audience and time available
- Environment verification is the highest-leverage pre-delivery step — the pre-demo checklist prevents the majority of live demo failures
- Pre-demo objections are scope-qualification opportunities, not blockers; answer briefly and redirect to the demo

## Infrastructure Notes

- Instructor should provision one instance for the projected walkthroughs (Modules 2–4); participants provision separately for Module 5
- Allow at least 30 minutes between catalog order and the start of the enablement session to account for provisioning
- LiteLLM endpoint (litellm-prod-frontend.apps.maas.redhatworkshops.io) requires outbound internet access; verify network policy if running at a customer site or air-gapped event
