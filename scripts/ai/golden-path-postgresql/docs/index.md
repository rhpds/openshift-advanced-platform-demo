# Request PostgreSQL Database

Golden Path for a PostgreSQL database that follows the platform standards: one namespace per team, a persistent volume sized by environment, credentials rotated through Vault after the merge, and a Resource entity in the catalog so the owner and the consumers are visible.

The request opens a merge request in the platform repository (`rhdh/infra-app-of-apps`); the Platform Engineering team reviews it and Argo CD applies it on merge.

This template was drafted by an AI agent from the existing `request-kafka-topic` Golden Path and reviewed by the platform team.
