# Module 03 — Section 2 Highlights: Advanced Developer Services

## Brief Overview

This module delivers a focused, instructor-led walkthrough of the demo's second section — Advanced Developer Services — covering Developer Hub with Lightspeed natural-language catalog queries (source Module 4, ~20 min full), Dependency Analytics and the secure Tekton pipeline with ACS, SBOM, TAS, and Conforma (source Module 5, ~15 min full), and TPA supply chain inventory (source Module 6, ~10 min full). Rather than re-running all 45 minutes, participants receive the key moments and the talking points that connect these capabilities to customer concerns about software supply chain risk, developer self-service, and compliance automation.

## Audience and Time

- **Roles:** Red Hat Solution Architects, Technical Sales Specialists — intermediate
- **Prerequisites for this module:** Modules 01 and 02 complete; participants should have the platform foundation context
- **Duration:** 20 minutes

## Learning Objectives

- Demonstrate Developer Hub Lightspeed natural-language catalog queries and the self-service template provisioning flow
- Explore the Dependency Analytics CVE detection workflow and its integration with the developer inner loop
- Demonstrate the secure Tekton pipeline: ACS image scanning, Syft SBOM generation, TAS keyless signing, and Conforma attestation policy check
- Analyze TPA supply chain inventory and CVE-to-SBOM traceability for a security or compliance audience

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Source Module 4 highlight: Developer Hub Lightspeed catalog queries | 5 min |
| 2 | Source Module 4 highlight: Self-service template provisioning | 3 min |
| 3 | Source Module 5 highlight: Dependency Analytics CVE detection | 4 min |
| 4 | Source Module 5 highlight: Secure pipeline — ACS scan, SBOM, TAS signing, Conforma | 5 min |
| 5 | Source Module 6 highlight: TPA inventory and CVE-to-SBOM traceability | 3 min |

## Detailed Steps

1. Open Red Hat Developer Hub; navigate to the Lightspeed search bar. Ask in natural language: "What microservices are owned by the platform team?" — show the results populated from the software catalog. Key message: "RHDH makes organizational knowledge accessible without having to know where it lives."
2. Navigate to the software catalog view; show service ownership, health status badges, tech docs link, and CI/CD pipeline status for the Parasol app. Message: "This is the single pane of glass for everything your development organization runs."
3. Click "Create" to launch the self-service template; walk through the provisioning flow that creates a GitLab repo, a Tekton pipeline, and an Argo CD application in one action. Message: "Golden path templates give developers self-service without giving them a blank canvas — standards are enforced at the moment of creation."
4. Switch to the DevSpaces workspace (or show a pre-recorded view); open the Dependency Analytics panel in the IDE sidebar. Show a CVE flagged against a `pom.xml` dependency with severity, CVSS score, and remediation advice. Message: "CVE detection happens at write time, not at pipeline time — developers catch it before it ships."
5. Expand the CVE detail to show the Red Hat advisory integration: "We don't just surface public CVEs; we integrate with Red Hat's curated vulnerability database to flag what actually affects your Red Hat runtime." Show the upstream advisory link.
6. Switch to the OpenShift Pipelines UI and walk the secure pipeline run. Pause at the ACS image scanning task: show the vulnerability gate output — image passes or fails based on the defined policy. Key message: "ACS enforces the image policy so no vulnerable image can reach the production namespace."
7. Show the Syft SBOM generation task output — a JSON SBOM artifact attached to the pipeline run result. Message: "Every build produces a machine-readable bill of materials; you always know what's inside the image."
8. Show the Trusted Artifact Signer (TAS) cosign signing step: the image is signed with a keyless signature using the pipeline's OIDC identity. Message: "Keyless signing means no key management burden — the signature proves this specific pipeline signed this specific image."
9. Walk the Conforma attestation policy check: show the pass/fail result and the policy statement — "Was this artifact signed by an authorized identity in an approved pipeline?" Message: "Conforma closes the loop — you can cryptographically verify the entire chain of custody."
10. Navigate to Trusted Profile Analyzer (TPA). In the SBOM inventory, perform a CVE search (use a current, recognizable CVE identifier for maximum impact). Show the result tracing which components in the catalog are affected. Message: "When the next Log4Shell hits, TPA answers 'Are we affected?' in minutes, not days."
11. Show the license compliance view in TPA: filter for components with restrictive licenses. Message: "This is your legal team's window into open source compliance — automated, not a spreadsheet."
12. Cover top Section 2 objections: "We already have Dependabot" → Dependabot doesn't integrate with a Red Hat advisory database or produce RHSA-verified remediation paths; "Our legal team owns SBOM — how does this integrate?" → TPA exports SBOM inventory in standard formats; it supplements, not replaces, existing processes; "Is TAS production-ready?" → TAS is GA; it is what Red Hat uses internally for its own release signing.

## Key Takeaways

- RHDH Lightspeed is the best opener for developer productivity skeptics — the natural language query lands with every audience regardless of technical depth
- The SBOM → TAS → Conforma chain is the strongest supply chain story in the platform; always connect it to a real, recent CVE event for maximum customer impact
- TPA's CVE-to-SBOM traceability is a unique differentiator — no competing platform in the room will have this as a built-in capability
- Dependency Analytics and the secure pipeline sub-story are modular; either can be delivered independently in a 10-minute slot for focused audiences

## Infrastructure Notes

- TPA requires external access to the Red Hat advisory and vulnerability databases; verify outbound network policy before running this demo at a customer site
- The secure pipeline adds 4-5 minutes to total pipeline execution time; pre-run the pipeline and show results rather than waiting live during the walkthrough
- ACS scan results are cached per image digest; pulling the same image tag twice may show a cached result — use a fresh build if a live scan is needed
