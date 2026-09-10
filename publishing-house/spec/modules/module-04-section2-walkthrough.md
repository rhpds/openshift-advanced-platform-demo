# Module 04 — Section 2 Live Walkthrough: Advanced Developer Services

## Brief Overview

The instructor delivers Section 2 of the Advanced App Platform demo live. Each group's driver continues following along in their shared RHDP instance. This section covers Developer Hub self-service and catalog capabilities, Dependency Analytics CVE detection, the secure Tekton pipeline (ACS image scan, Syft SBOM, TAS keyless signing, Conforma attestation), and TPA supply chain traceability. Q&A is held at the end. **This is the minimum viable endpoint for the session** — if time runs short due to questions in Sections 1 or 2, stopping here is a complete outcome.

## Audience and Time

- **Roles:** Red Hat Solution Architects, Technical Sales Specialists — intermediate
- **Prerequisites for this module:** Module 03 complete
- **Duration:** ~30 minutes (demo walkthrough + Q&A). Flexible — compress if time is tight coming out of Section 1.

## Learning Objectives

- Navigate Section 2 of the demo from start to finish alongside the instructor
- Identify the peak moments in Section 2 and the supply chain security narrative they carry
- Recall at least two objection responses relevant to Developer Hub and software supply chain security

## Demo Flow (Section 2)

The instructor follows the standard demo script for Section 2. Key beats, in order:

1. **Developer Hub — Lightspeed natural-language catalog query**
   Developer asks RHDH Lightspeed in natural language: "What services does Parasol expose?" Hub returns a structured answer from the software catalog. Talking point: "Developer Hub is not a static portal — it understands your catalog and answers questions about it."

2. **Self-service template provisioning**
   Developer uses a RHDH scaffolder template to provision a new service — repository, pipeline, GitOps config, and environment namespace created automatically. Talking point: "A developer can go from idea to a working pipeline in minutes, without opening a ticket to platform or security."

3. **Dependency Analytics CVE detection**
   The newly scaffolded service has a dependency with a known CVE. Dependency Analytics flags it in the IDE before the code is committed. Talking point: "We catch supply chain risk at the developer's desk, not at the security audit."

4. **Secure Tekton pipeline — ACS image scan**
   The pipeline runs an ACS image scan on the built container. A critical CVE blocks promotion. Talking point: "No image with a critical vulnerability reaches production — the pipeline enforces it automatically."

5. **Syft SBOM generation**
   The pipeline generates a Software Bill of Materials using Syft. Talking point: "Every build produces a machine-readable inventory of what's in the image — required for an increasing number of government and enterprise procurement standards."

6. **TAS keyless signing**
   The image is signed using Red Hat Trusted Artifact Signer (Sigstore-based, keyless). Talking point: "Keyless signing removes the private key management burden while giving you a cryptographically verifiable provenance chain."

7. **Conforma attestation**
   Conforma enforces a policy: only signed images with a passing ACS scan and a valid SBOM can be promoted. Talking point: "Policy is code — it lives in Git, it's versioned, and it's enforced automatically at every pipeline run."

8. **TPA supply chain traceability**
   Show TPA linking a CVE advisory to the specific SBOM components that are affected, across every image in the catalog. Talking point: "When a new CVE drops at 2am, you know in minutes which of your applications are affected — without manually checking every image."

## Q&A

Hold Q&A at the end of Section 2. Common questions:

- *"Does Developer Hub require all teams to use the same scaffolder templates?"* — No. Templates are optional golden paths. Teams can adopt them incrementally. Hub catalogs whatever exists, templated or not.
- *"How does keyless signing work without a private key?"* — It uses short-lived certificates issued by Fulcio (a certificate authority) tied to the CI identity (OIDC). The transparency log (Rekor) provides auditability.
- *"What's the difference between ACS and Dependency Analytics?"* — Dependency Analytics catches known CVEs in open-source dependencies at development time, in the IDE. ACS scans the full built container image at pipeline time — a different layer, catching a different class of issues.
- *"Is TPA a replacement for a full SBOM management platform?"* — For many customers, yes. For organisations with existing tools (e.g. Black Duck, Snyk), TPA can complement via API integration.

## Instructor Notes

- If time is tight coming into Section 2, compress beat 1 (Lightspeed query) — it is impressive but not the core supply chain narrative. Beats 4–8 are the heart of Section 2.
- The peak moment in Section 2 is beat 8 (TPA CVE-to-SBOM traceability). It is the most visually striking and the most frequently referenced by SAs in post-demo feedback.
- Remind participants: this is the minimum viable endpoint. If the room has rich Q&A engagement and time runs out here, that is a successful session — not a failure.
- If a group's driver is falling behind, encourage them to watch the instructor screen and not worry about keeping up in the instance. Following along in the instance is ideal; understanding the flow is the actual goal.
