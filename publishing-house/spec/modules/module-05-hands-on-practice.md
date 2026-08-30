# Module 05 — Hands-On Practice and Q&A

## Brief Overview

Participants select one demo module from the full Advanced App Platform demo (source Modules 1–7) and run it end-to-end in their own provisioned RHDP instance. This is the shift from observation to delivery — the first time participants drive the demo themselves, with the instructor and any co-presenters available for coaching and support. The module closes with a structured debrief, peer feedback exchange, and open Q&A covering delivery best practices, common failure modes, and first-customer-delivery preparation.

## Audience and Time

- **Roles:** Red Hat Solution Architects, Technical Sales Specialists — intermediate
- **Prerequisites for this module:** Modules 01–04 complete; each participant needs a live RHDP instance provisioned (ordered from catalog.demo.redhat.com before the session starts)
- **Duration:** 45 minutes

## Learning Objectives

- Demonstrate one complete demo module end-to-end in the live RHDP demo environment
- Analyze what worked, what was unclear, and what required recovery during the hands-on run
- Explore best practices from peers and instructor for maximizing demo impact and handling environment failures

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Module selection and instance verification | 5 min |
| 2 | Hands-on execution — participant-driven, instructor-supported | 25 min |
| 3 | Debrief: share highlights and recovery moments | 10 min |
| 4 | Q&A and first-delivery preparation | 5 min |

## Detailed Steps

1. Instructor presents the module selection grid with realistic time guidance:
   - Source Module 1 (Dev Inner Loop): ~30 min full run; ~10 min for highlights only
   - Source Module 2 (CI/CD Pipeline): ~15 min full run
   - Source Module 3 (Platform Ops): ~20 min full run
   - Source Module 4 (Developer Hub): ~20 min full run
   - Source Module 5 (Secure Dev): ~15 min full run
   - Source Module 6 (Supply Chain): ~10 min full run
   - Source Module 7 (AI-Enhanced Apps): ~15 min full run
2. Participants declare their module choice. Instructor groups participants by module selection where possible to facilitate peer observation and comparison.
3. Each participant verifies their RHDP instance is provisioned and accessible — confirm OpenShift console login, GitLab access, and the specific resources needed for their chosen module.
4. Instructor opens the source Showroom content in a shared browser tab as a reference guide; participants run their chosen module using it as scaffolding.
5. Participants begin hands-on execution. Instructor and co-presenters circulate, observing timing, talking points, confidence with navigation, and where participants hesitate or get stuck.
6. Instructor notes common failure or hesitation patterns across the room for the debrief discussion.
7. At the 25-minute mark, instructor calls time on the hands-on portion regardless of completion state. Incomplete runs are intentional — timing pressure is a realistic delivery constraint.
8. Structured debrief: each participant (or small group for the same module) shares in 60 seconds: what landed well, what felt awkward, one thing they would do differently next time.
9. Instructor synthesizes patterns from the debrief and shares SA field tips:
   - Pre-caching pipeline results to avoid live wait time during customer demos
   - Browser tab management: pre-open all tabs before starting to avoid visible URL navigation
   - Handling unexpected environment failures: "Let me show you the expected outcome on a screenshot while we restart the pipeline" keeps the narrative alive
   - Bridging dead air during pipeline execution: use the time to ask discovery questions or explain the architecture, not to stare at a progress bar
   - The "peak moment" technique: identify the strongest visual in your module and build the narrative toward it; everything else is setup
10. Open Q&A: common participant questions include "When should I skip a module?", "How do I handle a customer who wants to go off-script?", "What's the most common mistake SAs make before this demo?", "Can I run this demo from my laptop instead of RHDP?"
11. Distribute the pre-demo checklist (from Module 01) and the objection bank (compiled across Modules 02–04) as take-home reference materials for the first customer delivery.

## Key Takeaways

- Demo delivery is a perishable skill that degrades quickly without practice — one run per quarter at minimum before a customer-facing delivery is the recommended cadence
- The biggest risk in a live demo is environment failure, not knowledge gaps — always run the pre-demo checklist; always have a fallback (screenshots, recording, or a paired colleague's instance)
- Every module has a "peak moment" — the visual or result that causes customers to lean forward. Identify it before the session; build the narrative toward it, not through it
- Peer feedback from other SAs who have delivered the same module is often more actionable than instructor feedback — create or join a Slack channel for ongoing demo tips and field reports

## Infrastructure Notes

- Each participant needs their own provisioned RHDP `ocp4-adv-app-platform-demo` instance for this module; instructor should confirm catalog access for all attendees at least one day before the session
- If a participant's RHDP instance fails to provision, they should pair with a neighbor who has a working instance — paired delivery is also a valid learning format
- The facilitator should have a pre-provisioned backup instance ready to demonstrate live recovery from an environment failure as a deliberate teaching moment
- For virtual delivery: screen sharing + a shared Slack or Teams thread for real-time Q&A during the hands-on segment allows the instructor to observe participants without interrupting them
