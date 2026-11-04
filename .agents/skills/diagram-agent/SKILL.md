---
name: diagram-agent
description: >-
  Create, inspect, lint, render, or review architecture, data-flow, and sequence diagrams as uncompressed Draw.io XML or Mermaid with official vendor iconography and SVG/PNG exports. Use for any diagram request.
---

# Diagram Agent Skill

Adapted from FrioAndes reference standards.

Use uncompressed UTF-8 `.drawio` XML as the preferred canonical source; Mermaid is fully accepted. Publish an editable SVG and a PNG preview for every diagram.

Before authoring, read current specifications, `docs/case/case-statement.pdf`, and relevant architecture documents. Record the source paths and revision used.

Use native Draw.io vendor libraries and the exact official service shape when one exists (AWS/cloud native). Neutral shapes are allowed for actors, boundaries, notes, and components without an official shape. Never load icons from remote URLs.

Follow `standards/diagrams.md` for iconography, layout, contrast, and export standards.

---

## Execution and Verification Protocol

1. **Authoring**: Create uncompressed UTF-8 `.drawio` XML (or clean Mermaid in `.mmd` or Markdown).
2. **Export**: Export both `.svg` (primary publication) and `.png` (high-resolution preview).
3. **Visual & Semantic Inspection**:
   - Verify semantics: Match network boundaries, services, and data flows to specifications.
   - Verify layout: Check for label collisions, overlapping connectors, and clipped text.
   - Publication size inspection: Ensure labels are readable (minimum 12 pt equivalent) at actual display size.
4. **Atomic Commit**: Commit source (`.drawio` or `.mmd`) together with exported `.svg` and `.png` files in the same commit.
