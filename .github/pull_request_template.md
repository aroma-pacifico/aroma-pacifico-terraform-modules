<!--
PR title must be a Conventional Commit header — it becomes the squashed commit on main.
Example: feat(architecture): define telemetry ingestion pipeline
CI rejects a title that does not parse or contains emojis.
-->

## What and why

<!-- Two or three sentences. What changed, and why it was needed. Not a file list. -->

## Issue Traceability

<!-- Closes #N (completes issue) or Refs #N (partial progress) -->
Refs #

## Acceptance criteria addressed

<!-- Quote each criterion from the issue and state how it is satisfied. -->
- [ ] _criterion_ — how it is satisfied

## Verification

<!-- Concrete terminal commands executed and their output. Not "should work". -->

```
```

## Terraform plan

<!-- Infrastructure changes only. Delete this section otherwise.
     Academic delivery is plan-only: never apply or deploy.
     Call out EVERY destroy and EVERY replacement in prose ABOVE the plan.

     Resources destroyed: none
     Resources replaced:  none
-->

<details>
<summary>Plan output</summary>

```
```

</details>

## Risk and rollback

<!-- What breaks if this is wrong, and how to undo it. -->

## Checklist

- [ ] English throughout (code, comments, documentation, commit messages, PR title/body)
- [ ] Zero emojis across all commits, titles, and descriptions
- [ ] All commits follow Conventional Commits and reference the issue (`Refs #`)
- [ ] Branch is short-lived (< 48h) and branched from latest `main`
- [ ] No secrets, credentials, cloud keys, or proprietary data committed
- [ ] Documentation and architecture diagrams updated if behavior changed
- [ ] Architectural decisions recorded as numbered ADRs in `docs/adr/`

**Review and merge**

- [ ] Reviewed and approved by someone who did not author it
- [ ] Squash merge to `main`
