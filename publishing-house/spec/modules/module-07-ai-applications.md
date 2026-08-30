# Module Outline: AI-Enhanced Applications

## Brief Overview

This module demonstrates how to integrate AI capabilities into enterprise applications on OpenShift. Participants work through a business scenario where Parasol Insurance needs automated email triage, implement an LLM-powered email routing feature using Quarkus and LangChain4j, and deploy the AI-enhanced application through the same secure CI/CD pipeline used in earlier modules.

## Audience and Time

- **Target personas:** Sales engineers, solution architects presenting to developer, AI/ML, and line-of-business audiences
- **Prerequisites:** Familiarity with the CI/CD pipeline from Module 2, basic understanding of LLM concepts (prompts, inference), Quarkus application structure from Module 1
- **Estimated duration:** 15 min

## Learning Objectives

- Implement an AI-powered email routing feature in a Quarkus application using LangChain4j and an LLM endpoint
- Deploy an AI-enhanced application through the secure CI/CD pipeline using Red Hat OpenShift Pipelines, Red Hat OpenShift GitOps, and Red Hat Developer Hub

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Email Triage Problem Setup | 3 min |
| 2 | LLM-Powered Email Routing with Quarkus LangChain4j | 7 min |
| 3 | Deploying AI Feature Through Secure Pipeline | 5 min |

## Detailed Steps

1. Present the business scenario: Parasol Insurance receives high volumes of customer emails that need to be triaged and routed to the correct department
2. Explain the current manual process and why automated, intelligent routing adds business value
3. Open Dev Spaces with the Parasol Insurance application source code
4. Navigate to the email routing service component
5. Review the LangChain4j integration code: how the Quarkus application calls the LLM endpoint for email classification
6. Examine the prompt template that instructs the LLM to categorize emails by department (claims, billing, policy changes, general inquiries)
7. Show the Kafka integration: incoming emails arrive on a Kafka topic, are processed by the LLM, and routed to department-specific topics
8. Test the email routing locally in Quarkus dev mode with sample email payloads
9. Observe the LLM-generated classifications and routing decisions
10. Optionally show Developer Hub with the AI application component registered in the catalog
11. Commit and push the AI feature code to GitLab
12. Observe the Tekton pipeline executing the build, including the security scanning steps from Module 5
13. Watch Argo CD sync the AI-enhanced application to the target environment
14. Verify the deployed application is processing emails with LLM-powered routing in the live environment

## Key Takeaways

- Quarkus with LangChain4j provides a lightweight, cloud-native framework for integrating LLMs into enterprise Java applications
- LLM-as-a-Service (LiteMaaS) enables AI capabilities without requiring dedicated GPU infrastructure
- AI features are deployed through the same secure, governed pipeline as any other application change -- no special process needed
- Kafka enables event-driven AI processing patterns suitable for high-volume enterprise workloads
- The OpenShift platform provides a unified experience from AI development through secure production deployment

## Infrastructure Notes

- LiteMaaS LLM endpoint must be accessible from the cluster for inference calls
- LangChain4j dependencies must be available in the Quarkus application's Maven configuration
- Kafka cluster must have topics configured for the email triage workflow (incoming, per-department routing)
- The Tekton pipeline and Argo CD configuration must support the AI-enhanced application build and deployment
- Dev Spaces devfile should include any additional extensions for LangChain4j development
