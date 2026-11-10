@AGENTS.md

# Claude Project Instructions - Aroma Pacífico

`AGENTS.md`, imported above, is normative: language, zero-emoji policy, trunk-based development, conventional commits, requirements origin, academic delivery model, agent publishing boundaries, and Terraform standards. It is not repeated here.

This file provides working context for Claude Code sessions operating in the Aroma Pacífico repository.

---

## 1. Project Context

The **Aroma Pacífico pilot** represents the 2026 update of a coffee traceability pilot in Cauca, Huila, and Tolima for an academic DevOps challenge.
- **Repository scope**: Architecture design, system diagrams, ADRs, cost forecasting evidence, presentation materials, and governance standards.
- **Terraform boundary**: Terraform code will reside in a dedicated IaC repository created in task B01; ADR-003 decides its layout. No `.tf` files in this repository.
- **Requirements**: `docs/case/case-statement.pdf` is the sole source of requirements. All assumptions must be recorded in `docs/decision-log.md` with an ID. Never invent values or rehearsal results.

---

## 2. Core Operational Constraints

1. **Strict Zero-Emoji Policy**: Emojis are strictly prohibited across all commit messages, PR titles, descriptions, code comments, documentation, and agent responses.
2. **Trunk-Based Development**: `main` is protected. Work exclusively on short-lived branches: `<type>/<issue-number>-<kebab-slug>` (under 48 hours).
3. **Atomic Conventional Commits**: `<type>(<scope>): <lowercase imperative subject>` (max 72 chars, no trailing period, no emojis) with a mandatory `Refs #<issue>` footer. Commit incrementally as work is completed.
4. **Agent Publishing Boundary**: Agents commit locally and may push only their own feature branch and open a PR targeting `main`. Agents never push to `main`, never force-push, and never create repositories. Implementer agents never merge. The designated reviewer agent, which runs on a different AI provider than the implementer, reviews the pull request and squash-merges it when it approves and every check is green, following the review protocol. A pull request that needs a business decision, weakens CI checks or deletes out-of-scope content goes to the human lead instead. The reviewer may delete the merged head branch. The human lead can still review or merge at any time.
5. **Academic Delivery (Plan-Only)**: Never run `terraform apply` or `terraform destroy`. Never create live cloud resources or execute deployment pipelines.

---

## 3. Standards and Discoverable Skills

| Area | Normative Standard | Discoverable Skill |
|---|---|---|
| IaC & Reference Modules | `standards/terraform-iac-best-practices.md`, `standards/iac-rules/` | — |
| Documentation | `standards/documentation.md` | `.agents/skills/doc-agent/SKILL.md` |
| Architecture Diagrams | `standards/diagrams.md` | `.agents/skills/diagram-agent/SKILL.md` |
| Git & Source Control | `standards/git-workflow.md` | `.agents/skills/git-agent/SKILL.md` |

---

## 4. Diagram Rules

- Canonical source: Draw.io uncompressed UTF-8 XML (`.drawio`) is preferred; Mermaid is accepted.
- Required exports: Editable SVG (primary publication) and PNG (preview).
- Every diagram requires an individual semantic check, a visible render, and inspection at publication size. Parser success is not visual approval.
