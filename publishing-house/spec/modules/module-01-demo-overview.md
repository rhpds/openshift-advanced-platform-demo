# Module 01 — Demo Overview: Story, Structure, and Customer Message

## Brief Overview

The session opens with the instructor framing the demo from the customer's perspective: what problem Parasol Insurance is solving, why it matters to an enterprise buyer, and how the three demo sections build toward a compelling outcome. Participants leave this module knowing the narrative spine of the demo and the core message each section delivers — before they open a single browser tab.

## Audience and Time

- **Roles:** Red Hat Solution Architects, Technical Sales Specialists — intermediate
- **Prerequisites for this module:** None
- **Duration:** 15 minutes

## Learning Objectives

- Describe the Parasol Insurance business narrative and the enterprise problems it illustrates
- Identify the core customer message and primary differentiation angle for each of the three demo sections
- Explain how the three sections connect into a single coherent story for an enterprise buyer

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | The customer problem: who is Parasol Insurance and why do they care | 5 min |
| 2 | The three-section structure and what each proves | 7 min |
| 3 | Reading the room: which sections to emphasise for which buyer | 3 min |

## Instructor Notes

**The Parasol Insurance narrative**

Parasol Insurance is a mid-size insurer modernising its application platform. They have developer velocity problems (slow inner loop, manual pipeline steps), governance and security concerns (no software supply chain visibility, no secrets management policy), and are beginning to explore AI-enhanced applications. The demo shows a single day in the life of Parasol's platform team — moving from a broken CI pipeline through a governed GitOps delivery to an AI-enhanced customer service feature.

The three sections correspond to three maturity layers of the platform:

- **Section 1 — Foundational App Platform:** Inner dev loop, CI/CD security, GitOps delivery, platform operations. The pitch: "We make developers productive and give platform teams control."
- **Section 2 — Advanced Developer Services:** Developer Hub self-service, Tekton supply chain security (ACS, SBOM, TAS, TPA), dependency vulnerability detection. The pitch: "We give developers a paved road and give security teams full supply chain visibility."
- **Section 3 — Intelligent Applications:** OpenShift AI positioning, self-service AI feature provisioning via RHDH, LangChain4j intelligent email routing. The pitch: "We let teams build and run AI-enhanced applications without leaving the platform."

**Reading the room**

Different buyers respond to different sections. Suggest to participants:
- Platform / infrastructure buyers → lean into Section 1 (GitOps, Kiali, HPA, Vault)
- Developer / AppDev buyers → lean into Section 2 (Developer Hub, self-service, secure pipeline)
- Innovation / AI buyers → open with Section 3 framing, then support with Sections 1 and 2 as the foundation
- Short time slot (<30 min): Section 2 alone covers the widest range of differentiation messages

## Key Takeaways

- Every minute of the demo should connect to something the customer is trying to solve — Parasol Insurance is the vehicle, not the destination
- The three sections are independent enough to be reordered or skipped; they are not dependent on each other technically during the demo
- Knowing which section resonates with a given buyer is more valuable than knowing every feature in every section
