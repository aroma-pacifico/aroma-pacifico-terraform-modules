# Technical Documentation Standards & Best Practices

Adapted from FrioAndes reference standards.

This document establishes the organizational standards for technical documentation across the Aroma Pacífico project.

---

## 1. Writing Style and Structure

### Narrative Prose Over Enumerations
A common anti-pattern in technical documentation is over-relying on long, repetitive bulleted lists. When documents consist primarily of bulleted items, readability degrades and conceptual relationships between system components become obscured.

- Use cohesive paragraphs that explain context, design decisions, and system interactions.
- When comparing options, configuration properties, or environment variables, organize the information into Markdown tables rather than vertical lists.
- Reserve numbered lists exclusively for sequential procedures where the order of operations is essential.

### Table Usage
Tables provide superior scanability for reference data:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `batch_size` | Integer | `100` | Maximum number of coffee telemetry events per ingestion batch. |
| `timeout_seconds` | Integer | `30` | Socket timeout for sensor telemetry collection services. |
| `retry_limit` | Integer | `3` | Maximum retry attempts before routing events to the dead-letter queue. |

---

## 2. Dynamic Project Layout Maintenance

Repository documentation must never drift from the physical code tree. Every module addition, file reorganization, or utility script introduction must be immediately reflected in the relevant README or architecture document.

Use clean ASCII tree syntax:
```text
aroma-pacifico/
|-- AGENTS.md
|-- README.md
|-- docs/
|   `-- case/
|-- standards/
|   `-- iac-rules/
`-- .agents/
    `-- skills/
```

Avoid Unicode decorative branches, special symbols, or emojis in directory trees.

---

## 3. Strict Zero-Emoji Policy

Emojis detract from technical clarity and cause encoding irregularities across terminal environments, CI/CD runners, and legacy tooling.
- Emojis are strictly forbidden across all documentation, diagrams, code comments, and outputs.
- Replace status icons with explicit plain-text indicators: use `SUCCESS` instead of checkmarks, `WARNING` instead of caution triangles, and `ERROR` instead of crosses.

---

## 4. Capturing Real-World Troubleshooting & Solutions

Documentation serves as institutional memory. When developers and agents resolve unexpected bugs, configuration hurdles, or operational friction, record these events in `docs/troubleshooting-log.md` using the standardized schema below.

### Standard Entry Template
```markdown
### <Issue Name>

- **Context & Symptom**: Observed behavior, error message, or shell failure.
- **Root Cause**: Underlying technical reason why the issue occurred.
- **Resolution**: Concrete steps applied to unblock the situation.
- **Preventive Architecture**: How the system, configuration, or documentation was updated so future engineers avoid the problem.
```

---

## 5. Architectural Decisions and Records

Architectural decisions must never be buried as transient prose within general design documents. Every significant structural choice, technology selection, or governance boundary must be recorded as a numbered Architectural Decision Record (ADR) under `docs/adr/`.
