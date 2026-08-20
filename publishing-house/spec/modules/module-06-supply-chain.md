# Module Outline: Trusted Software Supply Chain

## Brief Overview

This module provides a deep dive into the Trusted Profile Analyzer dashboard, building on the artifacts generated in Module 5. Participants explore the TPA SBOM dashboard to inspect dependency trees, vulnerability correlations, and provenance metadata for the Parasol Insurance application. The module concludes with an OpenShift topology view that ties together the full application lifecycle demonstrated across all modules.

## Audience and Time

- **Target personas:** Sales engineers, solution architects presenting to security, compliance, and executive audiences
- **Prerequisites:** Completion of Module 5 (secure build pipeline), understanding of SBOMs and software provenance concepts
- **Estimated duration:** 10 min

## Learning Objectives

- Analyze software supply chain artifacts in the Red Hat Trusted Profile Analyzer dashboard, including SBOM dependencies and vulnerability correlations
- Demonstrate the end-to-end application lifecycle from development through secure delivery using the OpenShift topology view

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | TPA SBOM Dashboard Deep Dive | 7 min |
| 2 | OpenShift Topology View Wrap-Up | 3 min |

## Detailed Steps

1. Navigate to the Trusted Profile Analyzer dashboard
2. Locate the SBOM for the Parasol Insurance application uploaded during the secure build pipeline (Module 5)
3. Explore the dependency tree: drill into direct and transitive dependencies
4. Review vulnerability correlations: which dependencies have known CVEs, severity distribution, remediation status
5. Show the provenance metadata: link the SBOM back to the Tekton Chains attestation and the specific pipeline run
6. Demonstrate how TPA provides a centralized, searchable view of all SBOMs across the organization
7. Discuss how this supports compliance auditing and incident response (e.g., quickly finding all deployments affected by a new CVE)
8. Switch to the OpenShift web console topology view
9. Show the Parasol Insurance application components deployed across namespaces
10. Trace the full lifecycle: from Dev Spaces workspace to Git commit, through Tekton pipeline, signed by Chains, validated by Conforma, delivered by Argo CD, observed by Service Mesh -- all visible in the platform

## Key Takeaways

- TPA provides a centralized dashboard for inspecting SBOMs, tracking vulnerabilities across all builds, and supporting compliance audits
- The dependency tree view enables rapid assessment of exposure when new CVEs are disclosed
- Provenance metadata links every deployed artifact back to its build pipeline and source commit
- The OpenShift topology view demonstrates how the platform unifies the entire application lifecycle in a single pane of glass

## Infrastructure Notes

- TPA instance must have at least one SBOM uploaded from the Module 5 pipeline run
- The SBOM must contain sufficient dependency data for a meaningful dashboard exploration
- OpenShift topology view must show the Parasol Insurance application components across relevant namespaces
