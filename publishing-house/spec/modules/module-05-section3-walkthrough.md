# Module 05 — Section 3 Live Walkthrough: Intelligent Applications

## Brief Overview

The instructor delivers Section 3 of the Advanced App Platform demo live, time permitting. Each group's driver follows along in their shared RHDP instance. This section covers OpenShift AI positioning, RHDH self-service provisioning of an AI feature branch, and the LangChain4j Quarkus intelligent email routing application. Q&A is held at the end. **This module is explicitly time-permitting.** If the session reaches its scheduled end during or before this module, SAs are encouraged to work through Section 3 independently using their own RHDP instance after the event.

## Audience and Time

- **Roles:** Red Hat Solution Architects, Technical Sales Specialists — intermediate
- **Prerequisites for this module:** Module 04 complete (or in progress if time-boxing)
- **Duration:** ~25 minutes (demo walkthrough + Q&A). May be shortened or skipped depending on remaining session time.

## Learning Objectives

- Navigate Section 3 of the demo from start to finish alongside the instructor
- Explain the OpenShift AI positioning and how it connects to the Parasol narrative
- Recall at least two objection responses for AI-related customer concerns (GPU requirements, model lock-in, production readiness)

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | OpenShift AI positioning and MaaS endpoint | 5 min |
| 2 | RHDH self-service AI feature provisioning | 5 min |
| 3 | LangChain4j intelligent email routing application | 8 min |
| 4 | Objection handling — GPU, lock-in, production readiness | 4 min |
| 5 | Q&A | ~3 min |

## Demo Flow (Section 3)

The instructor follows the standard demo script for Section 3. Key beats, in order:

1. **OpenShift AI positioning**
   Brief framing: OpenShift AI is not a new product layer — it is AI/ML workload support built into the platform the customer already runs. Talking point: "You don't need a separate AI platform. The one you have already runs models."

2. **External LLM endpoint (MaaS)**
   Show that the demo uses an external LiteLLM endpoint hosted on RHDP infrastructure, not a GPU on the demo cluster. Talking point: "You can start with an externally hosted model — including open-source models — and move to on-cluster inference when the use case justifies dedicated hardware."

3. **RHDH self-service AI provisioning**
   Developer uses a RHDH scaffolder template to provision an AI feature branch: a new Quarkus service, a GitOps namespace, and a model-serving endpoint configuration — all wired together automatically. Talking point: "AI features get the same paved road as everything else — a template, a pipeline, and a governed delivery path."

4. **LangChain4j intelligent email routing application**
   Show the Parasol intelligent email routing application in action: incoming customer emails are classified by an LLM and routed to the appropriate claims handler. Show a misrouted email being corrected and the model context that drove the classification. Talking point: "This is a production-ready pattern — LangChain4j on Quarkus, connected to an enterprise-grade model endpoint, with full observability."

5. **Objection handling**
   Cover the three standard AI objections at this point in the demo:
   - *"We don't have GPUs."* — Start with external or shared model endpoints (MaaS pattern). Move to on-cluster inference when the use case justifies dedicated hardware. Many production AI applications run on CPU-only inference for smaller models.
   - *"We don't want model vendor lock-in."* — The demo uses open-source models (Qwen3) via LiteLLM. The application code is model-agnostic; swapping models is a configuration change, not a code change.
   - *"Is this production-ready?"* — LangChain4j on Quarkus is a supported, GA stack. The pattern shown is not a prototype — it is the same architecture Red Hat uses in its own AI-enhanced applications.

## Q&A

Hold Q&A at the end of Section 3 (or as the final Q&A of the session if this is the last module completed). Common questions:

- *"What models are supported?"* — Any model with an OpenAI-compatible API endpoint works with LiteLLM. In the RHDP demo, Qwen3-235B is used. Customers can bring their own models.
- *"How does this compare to OpenAI or Azure OpenAI?"* — This is on-platform, data stays in your cluster (or your cloud region), and the model is open-source. For regulated industries, that matters. For others, it can run alongside existing cloud AI subscriptions.
- *"Can we show this with a customer's own data?"* — The demo is pre-configured with Parasol data. For a custom PoC, the LiteLLM endpoint and the Quarkus application can be reconfigured. That is a PoC engagement, not a demo scope.

## Key Takeaways

- The email routing application and the AI objection handling are the must-deliver moments — compress or skip beats 1–3 if time is short
- Section 3 is the most commonly skipped in time-constrained customer deliveries; knowing how to position the skip gracefully is itself a delivery skill
- Post-session independent practice is the expected path for SAs who did not reach Section 3 during the event — the Showroom content is the guide

## Instructor Notes

- If time is running short, the most impactful beats are 4 (email routing application) and 5 (objection handling). Skip or compress beats 1–3 if necessary.
- If the session ends before this module is reached, close with: "We ran rich on questions — that is a good sign. Section 3 is available in your RHDP instance. I encourage you to work through it on your own. The Showroom content walks you through every step."
- Make it explicit that Section 3 is the most common section SAs skip in time-constrained customer demos. Knowing how to position the skip is itself a delivery skill.

## After the Session

Participants who want to continue practicing independently should:

1. Order their own `ocp4-adv-app-platform-demo` instance from the RHDP catalog (catalog.demo.redhat.com).
2. Use the source Showroom content as a step-by-step guide.
3. Target one section per practice session — a full run of Section 2 or Section 3 in isolation takes 15–20 minutes.
4. Recommended cadence before a first customer delivery: one full run of each section, on separate days, with at least one timed run of the section they plan to lead.
