# Infrastructure as Code (IaC) Reference Module Rules

This index provides an English summary of the 27 normative Terraform rules maintained in this directory (`pc-iac-001.md` through `pc-iac-027.md`). Each rule is binding for all Terraform module development and IaC delivery across the project.

| ID | Title | Summary |
|---|---|---|
| PC-IAC-001 | Mandatory Structure for Reference Modules | Defines the mandatory file and directory structure for Terraform reference modules, requiring core files and an examples/sample directory. |
| PC-IAC-002 | Mandatory Variables and Declaration Standards | Mandates explicit type, description, and validation attributes on variables while forbidding environment-specific defaults. |
| PC-IAC-003 | Naming Conventions for Terraform Elements and AWS Resources | Enforces lowercase snake_case naming for resources and outputs without redundant resource type prefixes in names. |
| PC-IAC-004 | Mandatory Tagging Standards | Requires consistent resource tagging across all cloud resources using standard governance tags including Project, Environment, and ManagedBy. |
| PC-IAC-005 | Provider Configuration and Aliases | Prohibits declaring provider blocks inside reusable child modules and standardizes provider alias inheritance from the root. |
| PC-IAC-006 | Version Pinning and Core Stability | Requires explicit minimum Terraform core versions and pessimistic provider constraint pinning using the ~> operator. |
| PC-IAC-007 | Output Declaration Standards | Mandates descriptions and appropriate typing for all module outputs while exposing only deliberate integration attributes. |
| PC-IAC-008 | State Management and Remote Backend | Enforces remote state storage in encrypted, versioned S3 buckets with state locking enabled, strictly prohibiting local state files. |
| PC-IAC-009 | Data Types, Type Conversions, and Logic in Locals | Standardizes type conversions and centralizes complex expression processing inside locals.tf to keep resource blocks declarative. |
| PC-IAC-010 | Resource Control with for_each and Lifecycle Rules | Mandates for_each over count for resource multiplicity and specifies proper use of lifecycle blocks such as prevent_destroy. |
| PC-IAC-011 | Data Sources and External Data Consumption | Governs the deterministic query of existing resources and external state using narrow, resilient data source filters. |
| PC-IAC-012 | Data Structures and Reusability in Locals | Defines the internal organization of locals.tf to structure intermediate representations and avoid duplicate logic. |
| PC-IAC-013 | Module Invocation Structure and Ordering | Enforces consistent attribute ordering in module blocks, prioritizing source, version, multiplicity, and input arguments. |
| PC-IAC-014 | Dynamic Blocks and Splat Expressions | Restricts dynamic block usage to truly variable nested attributes and standardizes splat expressions for attribute extraction. |
| PC-IAC-015 | Remote and Versioned Module Consumption | Mandates consuming reference modules through versioned Git repository tags and forbids unversioned local directory paths in root stacks. |
| PC-IAC-016 | Secrets Management and Sensitive Data Protection | Forbids plaintext secrets in configuration and state, mandating sensitive flags and external secret store integrations. |
| PC-IAC-017 | Cross-Domain Communication via Data Sources | Standardizes asynchronous cross-stack data sharing via SSM Parameter Store and tagged data lookups instead of tight coupling. |
| PC-IAC-018 | Code Testing and Validation Standards | Requires multi-stage validation including format checks, linters, security scans, and native plan-mode unit tests. |
| PC-IAC-019 | Restricted Use of terraform_remote_state | Restricts terraform_remote_state in favor of explicit data sources and parameter lookups to minimize cross-domain blast radius. |
| PC-IAC-020 | General Security Governance and Resource Hardening | Enforces security baselines including mandatory encryption at rest, encryption in transit, private endpoints, and audit logging. |
| PC-IAC-021 | Configuration Centralization in Locals | Forbids inline complex collection definitions in module calls, requiring normalization in root locals.tf. |
| PC-IAC-022 | Domain Separation of Responsibilities | Separates infrastructure into distinct lifecycle layers and domain boundaries such as networking, compute, security, and data. |
| PC-IAC-023 | Single Functional Responsibility for Modules | Enforces high cohesion and single responsibility per reference module, avoiding composite multi-service monoliths. |
| PC-IAC-024 | Traceability for Complex Configurations | Requires clear lineage and source documentation for composite data structures passed across configuration boundaries. |
| PC-IAC-025 | Mandatory Root Governance Processing | Assigns responsibility to the root stack for injecting environment context, governance policies, and mandatory tags into child modules. |
| PC-IAC-026 | Transformation Pattern in Sample Configurations | Defines standard sample directory patterns demonstrating how consumers transform and map inputs into the module safely. |
| PC-IAC-027 | Automated Cost Estimation in CI/CD Pipelines | Mandates Infracost CLI v2 cost estimation in pull request CI and CD promotion workflows, publishing monthly delta breakdowns to job summaries without requiring cloud credentials. |
