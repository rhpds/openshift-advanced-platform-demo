# Module Outline: Developer Experience

## Brief Overview

This module covers the developer inner loop on OpenShift, demonstrating how the platform accelerates application development. Participants walk through the Migration Toolkit for Applications positioning talk track, then launch Red Hat OpenShift Dev Spaces for one-click development environments. They add new features to the Parasol Insurance Quarkus application using dev mode with live reload, and explore Dev Spaces governance controls from the platform engineer persona.

## Audience and Time

- **Target personas:** Sales engineers, solution architects presenting to developer and platform engineering audiences
- **Prerequisites:** Familiarity with IDE-based development, basic Java/Quarkus understanding, OpenShift web console navigation
- **Estimated duration:** 30 min

## Learning Objectives

- Demonstrate the one-click developer workspace provisioning using Red Hat OpenShift Dev Spaces
- Build and test application features in Quarkus dev mode with live reload inside a cloud-hosted IDE
- Configure Dev Spaces governance policies from the platform engineer persona to enforce development standards

## Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | MTA Application Modernization Talk Track | 5 min |
| 2 | Dev Spaces One-Click Launch | 5 min |
| 3 | Adding Features with Quarkus Dev Mode | 12 min |
| 4 | Dev Spaces Governance (PE Persona) | 8 min |

## Detailed Steps

1. Present the Migration Toolkit for Applications positioning: how MTA accelerates Java application modernization to cloud-native on OpenShift (talk track only, not shown live)
2. Navigate to the OpenShift web console as the developer user
3. Launch a Dev Spaces workspace using the pre-configured devfile for the Parasol Insurance application
4. Observe the one-click provisioning: workspace starts with all dependencies, extensions, and configurations pre-loaded
5. Open the Quarkus application source code in the Dev Spaces IDE
6. Start Quarkus in dev mode and verify live reload is active
7. Add a new feature to the Parasol Insurance application (intentional code smells included for later CI/CD module)
8. Demonstrate Kafka integration by observing message flow in the dev environment
9. Optionally show Roo Code AI assistant capabilities within the IDE
10. Switch to the platform engineer persona via Keycloak SSO
11. Navigate to the Dev Spaces admin dashboard
12. Review and configure workspace governance policies (resource limits, idle timeout, allowed container images)
13. Demonstrate how governance controls affect the developer experience without blocking productivity

## Key Takeaways

- Dev Spaces eliminates "works on my machine" problems with standardized, reproducible cloud workspaces
- Quarkus dev mode enables rapid iteration with live reload directly in a cloud IDE
- Platform engineers can enforce governance policies on developer workspaces without restricting developer productivity
- MTA provides a structured path for modernizing legacy Java applications to cloud-native architectures

## Infrastructure Notes

- Dev Spaces operator must be installed and configured with appropriate workspace resource limits
- Devfile registry accessible at registry.devfile.io
- Keycloak SSO must have both developer and platform engineer users configured
- Kafka cluster must be running with topics available for the Parasol Insurance application
- Intentional code smells in the committed code are required for the CI/CD module that follows
