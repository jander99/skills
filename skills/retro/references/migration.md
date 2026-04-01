# v1 → v2 Migration Guide

## Overview

**v1** entries use no machine-parseable headers — just a `## YYYY-MM-DD HH:MM | tags` heading
followed directly by body fields.


**v2** inserts three blockquote header lines between the `##` heading and the body:
`> Trigger:`, `> Action:`, `> Scope:`.

Migration is **non-destructive**: original body fields are preserved unchanged.
Automatic migration inserts placeholder headers; manual review fills them in with meaningful values.


> **⚠️ Always backup before migrating:**
> ```bash
> cp ~/.agents/lessons/LESSONS.md ~/.agents/lessons/LESSONS.md.bak-$(date +%Y%m%d)
> ```

---

## Automatic Migration

Run the parser script to insert placeholder headers into all v1 entries:

```bash
retro-lessons.sh migrate ~/.agents/lessons/LESSONS.md
```

**What it does:**

- Detects entries missing `> Trigger:` / `> Action:` / `> Scope:` lines.
- Inserts three placeholder lines directly after each headingless `##` heading:
  ```
  > Trigger: [migrated — fill in manually]
  > Action: [migrated — fill in manually]
  > Scope: general
  ```
- Leaves all Sailboat body fields untouched.

**Dry-run first** (preview changes without writing):

```bash
retro-lessons.sh migrate --dry-run ~/.agents/lessons/LESSONS.md
```

After automatic migration, manually review each entry to replace placeholders with real values.

---

## Manual Migration Guide

### Inferring Trigger

Look at `**Anchor ⚓:**` — the pain point _is_ the trigger condition.

> Anchor: "`poetry install` before `poetry lock` causes avoidable failures."
> → Trigger: `Running poetry install in a fresh environment`

### Inferring Action

Look at `**Next 🧭:**` — the concrete fix _is_ the action.

> Next: "Always chain `poetry lock && poetry install` — never issue them separately."
> → Action: `Chain poetry lock && poetry install in a single command`

### Setting Scope

- Use the entry's existing **tags** as hints: `git-*` tags → `git-commit` or `git-push`; tool or file tags → file-path glob (e.g., `*.sh`)
- If no tags narrow it, default to `Scope: general`
- File-specific lessons: use a path glob, e.g. `skills/retro/**`

### SYNTHESIZED Entries

When multiple related entries share the same Trigger/Action pattern, combine them into a
single `## SYNTHESIZED — <title> | tags` entry with the v2 headers and a freeform synthesis
body instead of Sailboat fields. Retain individual entry dates in the synthesis body for traceability.

---

## Before/After Example

### Before (v1 — no machine-parseable headers)

```markdown
## 2026-03-06 08:36 | planning api context-management

**Wind 🌬️:** Reusing the repo's existing Epic/Story convention and creating all issues from
the research synthesis kept the GitHub plan consistent with project norms.

**Anchor ⚓:** GitHub sub-issue creation has a hidden priority-collision edge case; parallel
attachment looked faster but required follow-up retries and explicit verification.

**Rocks 🪨:** Future bulk sub-issue creation should assume GitHub ordering conflicts are
possible and verify the final attached set instead of trusting first-pass responses.

**Next 🧭:** For future Epic creation, attach child issues sequentially or batch-verify
immediately after linking to avoid losing time to sub-issue priority collisions.
```

### After Automatic Migration (placeholders inserted)

```markdown
## 2026-03-06 08:36 | planning api context-management
> Trigger: [migrated — fill in manually]
> Action: [migrated — fill in manually]
> Scope: general

**Wind 🌬️:** Reusing the repo's existing Epic/Story convention and creating all issues from
the research synthesis kept the GitHub plan consistent with project norms.

**Anchor ⚓:** GitHub sub-issue creation has a hidden priority-collision edge case; parallel
attachment looked faster but required follow-up retries and explicit verification.

**Rocks 🪨:** Future bulk sub-issue creation should assume GitHub ordering conflicts are
possible and verify the final attached set instead of trusting first-pass responses.

**Next 🧭:** For future Epic creation, attach child issues sequentially or batch-verify
immediately after linking to avoid losing time to sub-issue priority collisions.
```

### After Manual Review (meaningful headers)

```markdown
## 2026-03-06 08:36 | planning api context-management
> Trigger: Attaching multiple sub-issues to a GitHub Epic in parallel
> Action: Attach child issues sequentially and verify the final set immediately after linking
> Scope: general

**Wind 🌬️:** Reusing the repo's existing Epic/Story convention and creating all issues from
the research synthesis kept the GitHub plan consistent with project norms.

**Anchor ⚓:** GitHub sub-issue creation has a hidden priority-collision edge case; parallel
attachment looked faster but required follow-up retries and explicit verification.

**Rocks 🪨:** Future bulk sub-issue creation should assume GitHub ordering conflicts are
possible and verify the final attached set instead of trusting first-pass responses.

**Next 🧭:** For future Epic creation, attach child issues sequentially or batch-verify
immediately after linking to avoid losing time to sub-issue priority collisions.
```

---

## Validation

After migration, run:

```bash
retro-lessons.sh validate ~/.agents/lessons/LESSONS.md

# Or validate both global and project-local at once:
retro-lessons.sh validate --both
```

- **Exit 0**: all entries have v2 headers — migration complete.
- **Exit 1**: warnings printed to stderr listing entries still missing `> Trigger:`, `> Action:`, or `> Scope:`.
- **OK message** (stderr): if file not found, reports `OK: <path> not found (no entries — skipping)`.

---

## Sailboat → Start/Stop/Continue Schema Migration

The current entry format uses **Start/Stop/Continue** fields. Older entries may use Sailboat
fields (`**Wind 🌬️:**`, `**Anchor ⚓:**`, `**Rocks 🪨:**`, `**Next 🧭:**`).
The validator warns on Sailboat format; entries still work but should be migrated.

### Automatic Schema Migration

```bash
# Preview changes without writing:
retro-lessons.sh migrate-schema --dry-run ~/.agents/lessons/LESSONS.md

# Apply in-place:
retro-lessons.sh migrate-schema ~/.agents/lessons/LESSONS.md
```

**What it does:** Renames body fields in-place:
- `**Wind 🌬️:**` → `**Continue ✅:**`
- `**Anchor ⚓:**` → `**Stop 🛑:**`
- `**Rocks 🪨:**` → `**Stop 🛑 (risks):**`
- `**Next 🧭:**` → `**Start 🚀:**`

**After running:** Review the output. If both Anchor and Rocks existed, you will have two
`**Stop 🛑:**` blocks. Manually merge them into a single one.

### Field Mapping Rationale

| Sailboat | Start/Stop/Continue | Why |
|---|---|---|
| Wind 🌬️ (what helped) | Continue ✅ | Both capture what should be maintained |
| Anchor ⚓ (what went wrong) | Stop 🛑 | Both capture what should be eliminated |
| Rocks 🪨 (risks/unknowns) | Stop 🛑 (risks) | Risks are also things to stop/address |
| Next 🧭 (concrete action) | Start 🚀 | Both capture new practices to adopt |

### Manual Schema Migration Guide

For entries where the automatic migration is insufficient:

1. **Start 🚀** ← Content from `**Next 🧭:**` (the concrete action to adopt)
2. **Stop 🛑** ← Content from `**Anchor ⚓:**` + `**Rocks 🪨:**` merged (what to eliminate and risks)
3. **Continue ✅** ← Content from `**Wind 🌬️:**` (what worked well)

Merge the two Stop sources into a single coherent statement about what to stop or avoid.
