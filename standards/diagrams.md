# Architecture and Systems Diagram Standards

Adapted from FrioAndes reference standards.

This document defines the authoring, formatting, review, and export standards for all architectural, data-flow, sequence, and system diagrams in the Aroma Pacífico project.

---

## 1. Source and Export Contract

| Artifact | Standard | Notes |
|---|---|---|
| Primary source | Uncompressed UTF-8 Draw.io XML (`<name>.drawio`) | Preferred editable canonical format. |
| Accepted alternative source | Mermaid code (`<name>.mmd` or Markdown fenced block) | Fully accepted; no format-only migration required. |
| Primary publication export | Self-contained editable `<name>.svg` | Embedded diagram data, vector clarity at any scale. |
| Fallback preview export | `<name>.png` (recommended 2400 px width) | High-resolution bitmap preview for slides and documentation. |
| Review evidence | Source path, renderer version, verification checklist | Visual inspection at real publication size. |

Every Draw.io diagram page must contain a direct `mxGraphModel`, a stable descriptive page name, and unique cell IDs. Compressed XML payloads, external image URLs, local `file://` references, DTDs, XML entities, and emojis are strictly prohibited. Custom vector icons must be embedded directly as data URIs.

---

## 2. Diagram Review and Verification Contract

Automated syntax checks or parser success do not constitute visual or semantic approval.
Every diagram must undergo a three-stage verification process before being considered done:

1. **Semantic check**: Does the diagram accurately reflect the architecture, trust boundaries, network zones, and data flows defined in the specifications and ADRs?
2. **Visible render**: Render the diagram to its target visual format and verify layout integrity. Ensure there are no overlapping connectors, truncated text labels, or colliding lifelines.
3. **Publication-size inspection**: Inspect the rendered SVG and PNG exports at the exact size and DPI at which they will appear in the final presentation, report, or documentation. Labels must remain legible (minimum 12 pt equivalent).

---

## 3. Iconography and Visual Hierarchy

Use native official vendor libraries for AWS and other cloud providers:
- Use official service shapes for cloud primitives (e.g., AWS S3, API Gateway, Lambda, RDS).
- Do not replace an official service icon with a generic server box, blank square, or unrelated icon.
- Neutral shapes are reserved for actors, organizations, environment boundaries, VPC/subnet perimeters, and notes.
- Never fetch icons or shapes dynamically from external URLs at render time.
- Automated linters do not verify semantic appropriateness; author and reviewer are jointly responsible for icon validity.

---

## 4. Layout, Contrast, and Legibility

- **Directionality**: Prefer left-to-right for message processing and data pipelines; prefer top-to-bottom for layered architectural tiers.
- **Typography**: Maintain readable typography with at least 12 pt text for service and component labels.
- **Contrast and accessibility**: Never rely exclusively on color to convey meaning or security state. Combine color with explicit text labels, dashed/solid stroke distinctions, or named boundaries.
- **Boundaries**: Explicitly demarcate network perimeters (VPC, public/private subnets), trust tiers, and environment boundaries (dev, test, prod).

---

## 5. Diagram Classification

| Type | Required Content |
|---|---|
| Executive Overview | High-level capabilities, major system boundaries, external actors, and business value. |
| Technical Architecture | Detailed cloud services, network subnets, routing, security groups, protocols, and high-availability patterns. |
| Data Flow | Telemetry ingestion paths, data transformations, encryption in transit/at rest, storage backends, and retention policies. |
| Sequence Diagram | Participants, lifelines, ordered request/response cycles, error branches, and timeout/retry constraints. |

---

## 6. Traceability and Versioning

Before authoring or modifying a diagram, inspect current specifications, requirements in `docs/case/case-statement.pdf`, and active decision records. Any architectural assumption introduced by a diagram must be recorded in `docs/decision-log.md`.

Diagram source files and their corresponding SVG/PNG exports must always be committed atomically in the same commit on a short-lived branch.
