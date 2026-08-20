# Module Outline: Secure Development

## Brief Overview

This module introduces the secure development workflow within the OpenShift platform, covering vulnerability scanning at the IDE level and a hardened build pipeline. Participants scan application dependencies using the Dependency Analytics plugin in Dev Spaces, then walk through a secure build pipeline that includes ACS image scanning, SBOM generation with syft, TPA upload, Tekton Chains signing and attestation, and Conforma policy validation.

## Audience and Time

- **Target personas:** Sales engineers, solution architects presenting to security, DevSecOps, and compliance audiences
- **Prerequisites:** Understanding of container image concepts, awareness of software supply chain security (SBOMs, signing, attestation), completion of Module 2 (CI/CD pipeline familiarity)
- **Estimated duration:** 15 min

## Learning Objectives

- Analyze application dependencies for known vulnerabilities using Dependency Analytics in Dev Spaces
- Secure the build pipeline with image scanning, SBOM generation, artifact signing, and policy validation using Red Hat Advanced Cluster Security, Red Hat Trusted Artifact Signer, and Conforma

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Dependency Analytics Scanning | 5 min |
| 2 | Secure Build Pipeline | 10 min |

## Detailed Steps

1. Open the Parasol Insurance application in Dev Spaces
2. Open the pom.xml file and trigger the Dependency Analytics plugin scan
3. Review the vulnerability report: known CVEs, severity ratings, recommended remediation
4. Demonstrate how developers can identify and address security issues before code even enters the pipeline
5. Navigate to the secure build pipeline in the OpenShift Pipelines view
6. Trigger or observe a pipeline run that includes the security tasks
7. Walk through the ACS image scan task: observe the scan results showing vulnerability findings against the built container image
8. Show the SBOM generation task using syft: the pipeline produces a Software Bill of Materials for the built image
9. Demonstrate the TPA upload task: the SBOM is uploaded to Red Hat Trusted Profile Analyzer for centralized tracking
10. Show the Tekton Chains signing and attestation: the pipeline produces a signed provenance attestation (SLSA compliant)
11. Walk through the Conforma validation task: the enterprise contract policy validates that all required checks passed before the image is promoted
12. Verify the signed image in Red Hat Quay with its attestation and signature metadata

## Key Takeaways

- Dependency Analytics shifts security left by surfacing vulnerabilities in the IDE before code reaches the pipeline
- ACS provides container image scanning integrated directly into CI/CD pipelines
- SBOM generation with syft and TPA upload creates a verifiable record of every component in every build
- Tekton Chains provides tamper-proof signing and SLSA-compliant attestation without modifying pipeline logic
- Conforma enforces organizational security policies as automated gates in the delivery pipeline

## Infrastructure Notes

- Dependency Analytics plugin must be pre-installed in the Dev Spaces devfile
- ACS operator installed with a secured cluster configuration for image scanning
- Tekton Chains controller configured with signing keys and attestation storage
- TPA instance accessible for SBOM upload
- Conforma (Enterprise Contract) policies defined and available for pipeline validation
- syft available as a Tekton task for SBOM generation
- Red Hat Quay must display signature and attestation metadata for signed images
