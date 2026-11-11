# Contributing to Aroma Pacífico

This file is the repository-local guide for contributing to Aroma Pacífico.
All contributions are strictly governed by [`AGENTS.md`](AGENTS.md), which is the normative project constitution.

---

## 1. Language and Style

- **English only**: Code, comments, documentation, commit messages, branch names, and PR titles and descriptions must be in English.
- **Zero emojis**: Emojis are strictly forbidden across all repository files, commit messages, PRs, and outputs.

---

## 2. Requirements and Assumptions

- **Requirements source**: `docs/case/case-statement.pdf` is the sole source of requirements.
- **Decision log**: Every assumption or design choice not in the case statement must be registered with a unique ID in `docs/decision-log.md`. Never invent values or measurements.

---

## 3. Branching — Trunk-Based Development

`main` is always releasable and protected. Direct commits to `main` are strictly prohibited.

- Branch from `main`, merge back to `main` via pull requests.
- **Branch naming**: `<type>/<issue-number>-<short-kebab-slug>`
  - Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
  - Example: `feat/12-telemetry-ingestion`, `chore/0-bootstrap-agent-rules`.
- **Maximum branch lifetime**: 48 hours. Aim for small diffs (< 400 lines).
- Delete the feature branch after squash-merging to `main`.

---

## 4. Commits — Conventional Commits

Every commit must follow the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/) specification:

```text
<type>(<scope>): <lowercase imperative subject (max 72 chars, NO EMOJIS)>

[optional body explaining why this change was made, wrapped at 72 chars]

Refs #<issue-number>
```

- **Subject**: Imperative mood, lowercase, no trailing period, maximum 72 characters.
- **Body**: Explains *why* the change was made and technical trade-offs.
- **`Refs #`**: Mandatory footer referencing the issue number.
- **Breaking changes**: `feat(scope)!:` or `BREAKING CHANGE:` in the footer.
- **Atomic staging**: Stage and commit incrementally as units of work are completed.

To use the commit template automatically:
```bash
git config commit.template .gitmessage
```

---

## 5. Pull Requests

The PR title is a Conventional Commit header (max 72 characters, no emojis), because GitHub squash-merges use the title as the commit message on `main`.

Use `.github/pull_request_template.md` and provide:
1. Two to three sentences on what changed and why.
2. Issue traceability: `Closes #<issue>` or `Refs #<issue>`.
3. Acceptance criteria addressed and how each is satisfied.
4. Verification evidence (actual commands run and output shown).
5. Risk and rollback considerations.

### Rules:
1. Implementer agents never merge; self-merge is prohibited. The designated reviewer agent, which runs on a different AI provider than the implementer, reviews the pull request and squash-merges it when it approves and every check is green, following the review protocol. A pull request that needs a business decision, weakens CI checks or deletes out-of-scope content goes to the human lead instead. The reviewer may delete the merged head branch. The human lead can still review or merge at any time.
2. All CI checks must pass.
3. Squash merge only.
4. Never force-push a branch under review.

---

## 6. Working with AI Agents

AI agents operating in this repository adhere to [`AGENTS.md`](AGENTS.md):
- **Plan-only academic delivery**: Agents never run `terraform apply` or `terraform destroy`, and never create live cloud resources.
- **Publishing boundary**: Agents commit locally and may push only their own feature branch to open a PR. Agents never push directly to `main`, never force-push, and never create repositories. Implementer agents never merge. The designated reviewer agent, which runs on a different AI provider than the implementer, reviews the pull request and squash-merges it when it approves and every check is green, following the review protocol. A pull request that needs a business decision, weakens CI checks or deletes out-of-scope content goes to the human lead instead. The reviewer may delete the merged head branch. The human lead can still review or merge at any time.
