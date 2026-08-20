# Module Outline: Developer Hub

## Brief Overview

This module showcases Red Hat Developer Hub as the central self-service portal for developers on OpenShift. Participants explore Developer Lightspeed as an AI assistant, browse the software catalog to understand the organization's application landscape, and provision a new application component using a golden path template that generates a fully configured project with CI/CD pipelines and GitOps delivery.

## Audience and Time

- **Target personas:** Sales engineers, solution architects presenting to developer experience and platform engineering audiences
- **Prerequisites:** Familiarity with internal developer portals and service catalog concepts, understanding of CI/CD from Module 2
- **Estimated duration:** 15 min

## Learning Objectives

- Demonstrate Developer Lightspeed AI assistant capabilities within Red Hat Developer Hub
- Explore the Red Hat Developer Hub software catalog to discover and inspect application components
- Provision a new application using a golden path template in Red Hat Developer Hub

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Developer Lightspeed AI Assistant | 4 min |
| 2 | Software Catalog Exploration | 5 min |
| 3 | Golden Path Template Provisioning | 6 min |

## Detailed Steps

1. Navigate to the Red Hat Developer Hub landing page
2. Open the Developer Lightspeed AI assistant panel
3. Ask Lightspeed questions about the Parasol Insurance application architecture and observe AI-generated responses
4. Demonstrate how Lightspeed helps developers find information without leaving the portal
5. Navigate to the Software Catalog and browse the registered components
6. Open a Parasol Insurance component and explore its metadata: owner, lifecycle, dependencies, API definitions
7. View the component's CI/CD pipeline status, deployment history, and linked documentation
8. Show how the catalog provides a single pane of glass for the organization's application landscape
9. Navigate to the Templates section and select a golden path template for a new Quarkus microservice
10. Fill in the template parameters (application name, namespace, Git repository details)
11. Execute the template and observe the automated provisioning: GitLab repository creation, Tekton pipeline setup, Argo CD application configuration
12. Verify the newly provisioned component appears in the Software Catalog
13. Show the provisioned application's pipeline running its first build automatically

## Key Takeaways

- Developer Lightspeed provides AI-assisted developer support directly within the Developer Hub portal
- The software catalog gives developers a unified view of all applications, APIs, and infrastructure across the organization
- Golden path templates encode organizational best practices into repeatable, self-service application provisioning
- Developer Hub reduces time-to-first-commit by automating the entire project scaffolding, CI/CD, and GitOps setup

## Infrastructure Notes

- RHDH operator installed with a configured Developer Hub instance
- Developer Lightspeed plugin configured with LLM endpoint (qwen3-235b via LiteMaaS)
- Software catalog pre-populated with Parasol Insurance component entries
- At least one golden path template registered that creates a GitLab repo, Tekton pipeline, and Argo CD application
- GitLab must accept API calls from RHDH for repository creation
