# Gemini & Antigravity Rules - Aroma Pacífico

These rules apply to Google Gemini Code Assist, Gemini CLI, and the Antigravity IDE when operating within the `aroma-pacifico` repository.

All operations must strictly conform to [`AGENTS.md`](AGENTS.md), which is the normative project constitution.

---

## 1. Zero-Emoji Mandate (Strict)

Emojis are strictly prohibited across all code, comments, documentation, commit messages, PR descriptions, and AI agent outputs. Use clean, professional plain text only.

---

## 2. Source Control Mandates (Trunk-Based Development)

1. **Trunk Protection**:
   - `main` is protected. Never commit directly to `main`.
   - Verify branch before editing: `git branch --show-current`. Branch off `main` if on trunk: `git checkout -b <type>/<issue-number>-<slug>`.
   - Short-lived branches must stay under 48 hours and under 400 lines.

2. **Atomic Commits As You Go**:
   - As files and units are created or modified, execute atomic staging (`git add <files>`) and commits immediately.
   - Do not defer commits to the end of a session.

3. **Conventional Commits**:
   - Structure: `<type>(<scope>): <lowercase imperative subject>` (max 72 chars, no trailing period, no emojis).
   - `Refs #<issue>` footer is mandatory on all commits.
   - All messages must be in English.

4. **Agent Publishing Boundary**:
   - Agents commit locally and may push only their own assigned feature branch to open a PR to `main`.
   - Agents never push to `main`, never merge, never force-push, and never create repositories. The lead reviews and merges.
   - No tool attribution trailers (`Co-Authored-By` for an AI tool), generation notes or session URLs in commits or PR bodies.

---

## 3. Academic Delivery & Requirements Traceability

- **Plan-Only Execution**: Deliver design, modular Terraform, cost forecasts, and presentation artifacts. Never run `terraform apply` or `terraform destroy`. Never create live cloud resources.
- **Requirements Source**: `docs/case/case-statement.pdf` is the sole source of requirements.
- **Decision & Assumption Log**: Record all unstated assumptions in `docs/decision-log.md` with an ID. Never invent measurements or approval results.

---

## 4. Discoverable Skills

| Agent Role | Discoverable Skill | Standard |
|---|---|---|
| Documentation Agent | `.agents/skills/doc-agent/SKILL.md` | `standards/documentation.md` |
| Diagram Agent | `.agents/skills/diagram-agent/SKILL.md` | `standards/diagrams.md` |
| Git Agent | `.agents/skills/git-agent/SKILL.md` | `standards/git-workflow.md` |

---

## 5. Diagram Standards

- Canonical format: Draw.io uncompressed UTF-8 XML (`.drawio`) is preferred; Mermaid is accepted.
- Publication contract: Export both editable SVG (primary publication) and PNG (preview).
- Visual verification: Every diagram requires an individual semantic check, a visible render, and inspection at publication size. Parser success is not visual approval.
