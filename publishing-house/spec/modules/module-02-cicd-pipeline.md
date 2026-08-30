# Module Outline: CI/CD Pipeline

## Brief Overview

This module demonstrates the automated CI/CD pipeline triggered by the code changes made in Module 1. Participants push code to GitLab, observe Tekton pipelines executing build-test-scan stages, see SonarQube catch the intentional code smells, use an AI assistant to fix them, and then follow the GitOps delivery flow through Argo CD from development to production.

## Audience and Time

- **Target personas:** Sales engineers, solution architects presenting to DevOps and platform engineering audiences
- **Prerequisites:** Completion of Module 1 (code changes committed), basic understanding of CI/CD pipeline concepts, familiarity with Git push workflows
- **Estimated duration:** 15 min

## Learning Objectives

- Deploy application changes through an automated Tekton pipeline triggered by a Git push
- Analyze code quality findings from SonarQube and apply AI-assisted fixes using Roo Code
- Demonstrate GitOps-based delivery and production promotion using Red Hat OpenShift GitOps

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Git Push and Tekton Pipeline Trigger | 4 min |
| 2 | SonarQube Code Quality and AI Fix | 5 min |
| 3 | GitOps Delivery with Argo CD | 6 min |

## Detailed Steps

1. From the Dev Spaces workspace, commit and push the code changes (including intentional code smells) to the GitLab repository
2. Navigate to the OpenShift Pipelines view and observe the Tekton pipeline triggered by the Git push event
3. Walk through each pipeline task as it executes: source checkout, build, unit test, image push to Quay
4. Observe the SonarQube quality gate results -- the pipeline surfaces the code smells introduced in Module 1
5. Open the SonarQube dashboard to review the specific findings (code smell details, severity, location)
6. Return to Dev Spaces and use Roo Code AI assistant to generate fixes for the flagged code smells
7. Commit and push the fixed code, triggering a new pipeline run
8. Verify the SonarQube quality gate now passes
9. Navigate to the Argo CD dashboard and observe the application sync for the development environment
10. Show the updated application running in the dev namespace
11. Demonstrate production promotion by merging to the production branch in GitLab
12. Observe Argo CD syncing the production environment with the new image

## Key Takeaways

- Tekton pipelines automate the full build-test-scan-deploy cycle, triggered by Git events
- SonarQube integration catches code quality issues before they reach production
- AI coding assistants can accelerate remediation of code quality findings
- Argo CD provides declarative, Git-based promotion across environments with full audit trail

## Infrastructure Notes

- Tekton pipelines and tasks must be pre-configured with GitLab webhook triggers
- SonarQube instance must be running with quality profiles matching the Parasol Insurance project
- Argo CD must have Application resources configured for dev and prod namespaces
- GitLab must have the source repository and GitOps configuration repository pre-populated
- Red Hat Quay registry must be accessible for image pushes
