# Lesson Entry Schema v2

This document defines the v2 markdown entry format for `LESSONS.md`.
It extends the v2 base (Trigger/Action/Scope headers) with the **Start/Stop/Continue** body, replacing the legacy Sailboat fields.

## Canonical v2 Entry

```markdown
## YYYY-MM-DD HH:MM | tag1 tag2
> Trigger: <when this lesson applies — situation, operation, or context>
> Action: <what to do differently — concrete behavior>
> Scope: <operation-type, file-path-glob, or general>
**Start 🚀:** <new practice to adopt next session>
**Stop 🛑:** <habit, approach, or pattern to eliminate>
**Continue ✅:** <what worked well and should be maintained>
```

Placement rule:
- The three new lines (`> Trigger:`, `> Action:`, `> Scope:`) MUST appear directly after the `##` heading and before `**Start 🚀:**`.

## SYNTHESIZED v2 Entry Variant

SYNTHESIZED entries use the same three header lines, but the body is freeform synthesis text instead of Start/Stop/Continue fields.

```markdown
## SYNTHESIZED — <title> | tag1 tag2
> Trigger: <when this applies>
> Action: <behavioral instruction>
> Scope: <scope>
<synthesis text>
```

## Tag Normalization Rules

- Tags MUST be lowercase.
- Multiword tags MUST be hyphenated (example: `error-handling`).
- Aliases are not allowed; each concept uses one canonical tag form.
- If an entry has no explicit tags, the parser assigns `[untagged]`.

## Scope Field Conventions

Allowed `> Scope:` values:
- Operation types: `git-push`, `git-rebase`, `git-commit`, `git-merge`, `file-deletion`, `deployment`, `secrets-handling`
- File path globs: examples include `src/auth/**`, `*.sh`, `skills/retro/**`
- `general` for broad lessons not tied to a specific operation or path

## Entry Counter Contract

`LESSONS.md` MUST retain the counter comment:

```markdown
<!-- retro:entries:N -->
```

Counter rules:
- `N` is the number of raw entries currently represented in the file.
- This counter is used by compaction logic to detect when the file reaches 20+ entries.
- The comment MUST survive all schema revisions and formatting changes.

## Validation Rules

### Well-formed Entry

An entry is well-formed when all of the following are true:
- Heading matches one of:
  - `## YYYY-MM-DD HH:MM | <tags>`
  - `## SYNTHESIZED — <title> | <tags>`
- Heading is followed immediately by exactly three lines in this order:
  - `> Trigger: ...`
  - `> Action: ...`
  - `> Scope: ...`
- For standard entries, all three body fields are present in order:
  - `**Start 🚀:**`
  - `**Stop 🛑:**`
  - `**Continue ✅:**`
- For SYNTHESIZED entries, at least one non-empty synthesis body line appears after `> Scope:`.

### Legacy Sailboat Format (warn, don't error)

Entries using `**Wind 🌬️:**`, `**Anchor ⚓:**`, `**Rocks 🪨:**`, `**Next 🧭:**` are considered **legacy**.
The validator emits a WARN and suggests running `retro-lessons.sh migrate-schema <file>`.

### Malformed or Invalid Entry

An entry is malformed or invalid when any of these conditions occur:
- Missing one or more required header lines.
- Header lines exist but are out of order.
- `> Trigger:`, `> Action:`, or `> Scope:` appears after `**Start 🚀:**`.
- Standard entry missing all body fields (neither S/S/C nor Sailboat present).
- SYNTHESIZED entry uses body fields instead of synthesis text.
- Heading does not include a tag segment after `|` (parser normalizes to `[untagged]`).

## Required Examples

### Example A: Standard v2 entry (Start/Stop/Continue)

```markdown
## 2026-03-31 14:20 | tool-use git-hygiene
> Trigger: Before changing files in a shared repo or worktree
> Action: Check main repo root and branch context first, then edit
> Scope: git-commit
**Start 🚀:** Run `git worktree list --porcelain | awk '/^worktree /{print $2; exit}'` at task start to confirm main root.
**Stop 🛑:** Assumed branch/worktree context without verifying — caused edits to wrong directory.
**Continue ✅:** Reading existing file before writing prevented silent overwrites.
```

### Example B: SYNTHESIZED v2 entry

```markdown
## SYNTHESIZED — Worktree safety and branch checks | git-hygiene planning
> Trigger: Starting autonomous implementation in repositories with multiple worktrees
> Action: Validate main repo root and branch before any write operation
> Scope: general
Branch confusion is a repeated root cause for avoidable rework.
Explicit preflight checks reduce silent scope drift and keep file changes contained.
```

### Example C: Minimal valid entry (well-formed but sparse)

```markdown
## 2026-03-31 15:00 | [untagged]
> Trigger: Any task handoff
> Action: Record one concrete next move
> Scope: general
**Start 🚀:** Begin next session by reading the latest lesson.
**Stop 🛑:** Skipping handoff notes when the task feels "obviously done."
**Continue ✅:** Concise handoff entries resume quickly.
```

### Example D: Legacy Sailboat (validator warns, run migrate-schema)

```markdown
## 2026-01-15 10:00 | git-hygiene
> Trigger: Before committing
> Action: Run git status first
> Scope: git-commit
**Wind 🌬️:** Caught a dirty tree.       ← WARN: legacy format, run migrate-schema
**Anchor ⚓:** Forgot tests.
**Rocks 🪨:** CI flakiness.
**Next 🧭:** Add test step.
```
