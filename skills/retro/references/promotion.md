# Pattern Promotion to AGENTS.md / CLAUDE.md

Promotion elevates a recurring lesson from a volatile log entry into a durable, always-active rule.

## When to Promote

A pattern is ready to promote when it appears in **3 or more** LESSONS.md entries with the same
root cause — regardless of how similar the surface-level task was.

Examples of promotable patterns:
- 3 entries all have Anchor mentioning "forgot to check current branch" → promotable
- 4 entries have Wind mentioning "reading file before writing prevented data loss" → promotable
- 2 entries mention the same thing → NOT yet promotable (wait for a third)

## What NOT to Promote

Avoid promoting:
- **Task-specific rules**: "Always use Tailwind for this project's buttons" — too narrow
- **Coincidental patterns**: Two similar entries in the same session (one task, not a real pattern)
- **Negative rules that are already obvious**: "Don't delete production databases" — not useful
- **Preferences masquerading as patterns**: stylistic choices that aren't errors

The litmus test: *Would this rule have prevented an Anchor event in 3+ different tasks?*
If yes → promote. If unsure → wait for another occurrence.

## Promotion Format

### Target File Priority

1. `AGENTS.md` (OpenCode, multi-tool)
2. `CLAUDE.md` (Claude Code)
3. Create `AGENTS.md` if neither exists

### Section Structure

Find or create a `## Learned Rules` section. Group rules by tag category:

```markdown
## Learned Rules

> Auto-promoted from LESSONS.md by the `retro` skill on YYYY-MM-DD.
> These rules are active in every session. To remove a rule, delete its bullet.

### Planning
- Always verify the current branch with `git branch --show-current` before any file modification.
- Ask 1–2 clarifying questions before starting any task where the scope is ambiguous.

### Tool Use
- Run `ls` or `glob` to confirm directory structure before assuming file locations.
- Read a file before writing to it — never overwrite without understanding current contents.

### Error Handling
- On first file read failure, check both the path and the working directory before retrying.
```

### Appending Rules

When adding a new promoted rule:
1. Locate the existing `## Learned Rules` section
2. Find the matching tag subsection (or create it)
3. Append the new bullet — do NOT remove existing bullets
4. Add a comment noting the promotion date: `<!-- promoted: YYYY-MM-DD -->`

## Demotion (Removing a Promoted Rule)

If a promoted rule turns out to be wrong or too aggressive:
1. Delete the specific bullet from `AGENTS.md` / `CLAUDE.md`
2. Add an Anchor entry in `LESSONS.md` noting: "Promoted rule `[X]` was over-broad; removed."

This creates a meta-lesson: what kinds of patterns should NOT be promoted.
