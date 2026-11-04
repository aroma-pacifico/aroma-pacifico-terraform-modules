---
name: doc-agent
description: >-
  Technical documentation management, living README synchronization, project structure tracking, zero-emoji policy enforcement, prose-over-enumeration styling, and troubleshooting log maintenance for Aroma Pacífico repositories. Use this skill whenever writing, auditing, updating, or structuring documentation.
---

# Documentation Agent Skill

Adapted from FrioAndes reference standards.

Specialized skill for maintaining technical documentation, synchronizing directory layouts, upholding clean prose standards without emoji usage, and preserving institutional engineering lessons learned.

---

## Non-Negotiable Directives

1. **Strict Zero-Emoji Policy**: Emojis are strictly forbidden across all documentation, code comments, markdown files, and agent responses.
2. **All English**: Every document, summary, and log entry must be written in English.
3. **Continuous README & Structure Sync**: Whenever new files, tools, or folders are introduced or modified, immediately update corresponding READMEs and ASCII directory trees.
4. **Prose and Tables Over Lists**: Avoid excessive bulleted or numbered lists. Use descriptive paragraphs and Markdown tables for clarity and scannability.
5. **Living Troubleshooting Log**: Record difficulties encountered, friction points, root causes, and solutions in `docs/troubleshooting-log.md`.

---

## Execution Protocol

### Step 1: Detect Repository Changes
Identify added, modified, or reorganized files and any issues or bugs resolved during the work session.

### Step 2: Update Documentation
- Ensure new files and modules are documented in the main README and the module-level README.
- Update the ASCII directory layout tree to match the filesystem.
- Replace repetitive bullet points with clear narrative explanations or tables.

### Step 3: Record Troubleshooting Entries
If an edge case, error, or operational hurdle was overcome, append a standardized entry to `docs/troubleshooting-log.md`:
- Title
- Context & Symptom
- Root Cause
- Resolution Applied
- Preventive Architecture

### Step 4: Verification
Verify that zero emojis are present and that all markdown links point to valid repository paths:
```bash
grep -rnP '[\x{1F300}-\x{1FAD6}\x{2600}-\x{27BF}]' .
```
