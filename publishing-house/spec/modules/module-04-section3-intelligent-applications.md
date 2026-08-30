# Module 04 — Section 3 Highlights: Intelligent Applications

## Brief Overview

This module covers the demo's third section — Intelligent Applications — which shows how OpenShift AI capabilities are integrated into the application platform to enable AI-enhanced enterprise applications (source Module 7, ~15 min full). The instructor walks through the AI positioning story, the RHDH self-service provisioning of the prepared LangChain4j Quarkus branch, and the intelligent email routing application demonstration. Emphasis is on positioning Red Hat's approach to AI as pragmatic and enterprise-ready — not experimental — and on handling the most common customer skepticism: "We don't have GPUs."

## Audience and Time

- **Roles:** Red Hat Solution Architects, Technical Sales Specialists — intermediate
- **Prerequisites for this module:** Modules 01–03 complete; participants should understand the demo environment baseline
- **Duration:** 15 minutes

## Learning Objectives

- Explore Red Hat's positioning for AI-enhanced applications on OpenShift, including the external LLM endpoint pattern using LiteLLM and HashiCorp Vault
- Demonstrate the RHDH self-service provisioning of the AI-enhanced feature branch and DevSpaces workspace
- Demonstrate the LangChain4j Quarkus intelligent email routing application and explain the end-to-end flow from user email to LLM classification
- Analyze common customer objections for AI on OpenShift, including GPU requirements, model vendor lock-in, and production readiness

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | AI positioning on OpenShift — the pragmatic enterprise approach | 3 min |
| 2 | RHDH self-service provisioning of the AI feature branch | 3 min |
| 3 | LangChain4j Quarkus application walkthrough — code and config | 5 min |
| 4 | Live demo: intelligent Parasol email routing | 2 min |
| 5 | Objection handling: GPUs, models, and enterprise readiness | 2 min |

## Detailed Steps

1. Frame the AI positioning before touching the demo: "OpenShift is where enterprise AI runs — not because Red Hat makes models, but because enterprise AI needs the same things enterprise applications need: security, governance, observability, and a platform ops team that can support it." Emphasize model-agnostic infrastructure over any specific LLM.
2. Explain the external LiteLLM endpoint architecture: the demo uses `litellm-prod-frontend.apps.maas.redhatworkshops.io` running Qwen3-235b, accessed via an API key stored in HashiCorp Vault. This is the production-realistic pattern for organizations that want to use an external or managed LLM without embedding credentials in code or container images.
3. In Red Hat Developer Hub, navigate to the self-service template for the AI-enhanced feature branch. Show the template provisioning a new GitLab branch with the prepared LangChain4j dependency already configured in the `pom.xml` — no manual setup.
4. Launch the DevSpaces workspace from the RHDH catalog link; show the LangChain4j Quarkus project opened automatically with the AI branch checked out.
5. In the application source, navigate to `EmailRoutingService.java`; show the `@RegisterAiService` annotation and the `routeEmail(String email)` method signature. Message: "Quarkus LangChain4j reduces an LLM call to a typed Java method — no HTTP client boilerplate, no prompt assembly code."
6. Show the Vault secret mount in the DevSpaces workspace that provides the LiteLLM API key as an environment variable — no hardcoded credentials anywhere in the codebase.
7. Show the `application.properties` LiteLLM endpoint configuration pointing to the external MaaS endpoint via the Vault-sourced key.
8. Run the application in Quarkus dev mode (`quarkus dev` in the integrated terminal); wait for the startup log to confirm the AI service is initialized.
9. Send a sample Parasol Insurance customer email in the running app's UI (e.g., a policy cancellation request): show the LLM classifying and routing it to the correct department with a rationale.
10. Send a second email with ambiguous or borderline intent (e.g., a complaint that could be billing or claims): show the LLM correctly classifying it and explain the chain-of-thought reasoning shown in the response.
11. Objection handling:
    - "We don't have GPUs" → This demo intentionally uses an external LiteLLM endpoint to demonstrate the model-agnostic pattern. Customers can use OpenShift AI with self-hosted models, an external endpoint, or a managed service — the platform works with all three. GPU nodes are not required for the inference platform architecture.
    - "Is Quarkus the only supported framework?" → LangChain4j is the Java/Quarkus integration library; Spring AI provides the same abstraction for Spring Boot; Python LangChain and LlamaIndex are supported in OpenShift AI notebooks and model serving. The pattern, not the framework, is what Red Hat supports.
    - "Is this production-ready?" → The pattern shown — external LiteLLM endpoint + Vault secrets + Quarkus AI extension + GitOps delivery — is the Red Hat-recommended production architecture for enterprise AI-enhanced applications.

## Key Takeaways

- The "model-agnostic platform" message is more powerful than any specific model — position OpenShift AI as where enterprise AI runs, not as an LLM provider competing with OpenAI
- The LangChain4j `@RegisterAiService` pattern shows AI can be a first-class Java method, not a separate ML system bolted on — this resonates strongly with Java-shop customers
- The Vault secret integration for LLM API keys is a security story as much as an AI story; always call it out explicitly for security-conscious audiences
- This section plays best for customers who are AI-curious but haven't committed to a model vendor; use it to position OpenShift as the neutral, enterprise-grade inference platform

## Infrastructure Notes

- The external LiteLLM endpoint (`litellm-prod-frontend.apps.maas.redhatworkshops.io`) must be reachable from the demo environment; verify outbound internet connectivity before any session where this module appears
- Response time from the LiteLLM endpoint is typically 2-5 seconds for a warm model; run one test request before the session to warm the model and avoid cold-start latency in front of the audience
- The Vault secret for the LiteLLM API key is pre-provisioned in the demo environment; no manual Vault setup is required
