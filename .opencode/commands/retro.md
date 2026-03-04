---
description: Run a structured retrospective on the current session — assess what worked, what didn't, write persistent lessons to LESSONS.md, and promote recurring patterns to AGENTS.md.
arguments:
  - name: mode
    description: "compact (synthesize LESSONS.md entries), promote (force pattern promotion check), setup (show auto-trigger installation guide for OpenCode/Claude Code/Cline/Cursor), or omit for a standard retro"
    required: false
---

Use the retro skill to run a retrospective on the current session.

Follow the retro skill instructions in @skills/retro/SKILL.md exactly.

## Key Steps

1. Detect tool availability — use `session_read` if in OpenCode; otherwise reconstruct from context window
2. Self-assess using the Sailboat+Forward rubric: Wind (what helped), Anchor (what went wrong), Rocks (risks remaining), Next (one concrete action)
3. Write a dated entry to `LESSONS.md` in the project root (create file if absent)
4. If `mode` is `compact` or entry count exceeds 20, run the compaction pipeline (see references/compaction.md)
5. Scan for patterns appearing 3+ times and promote them to `AGENTS.md ## Learned Rules` (see references/promotion.md)
6. Report a brief summary of what was written

## Mode Behaviour

- **No argument** — Standard retro: assess session, write one entry, check for promotable patterns
- **`compact`** — Skip session assessment; go straight to synthesizing all LESSONS.md entries into patterns
- **`promote`** — Skip session assessment; scan existing entries and force a promotion check only
- **`setup`** — Show the auto-trigger installation guide: read `skills/retro/references/auto-trigger.md` and present the hook scripts + AGENTS.md snippet relevant to the user's tool

## Additional Context

- "None notable" is a valid entry for any field — never fabricate content
- When `session_read` is unavailable, note `> Reconstructed from context window` in the entry
- The `<!-- retro:entries:N -->` comment in LESSONS.md tracks the entry count for compaction
- Promoted rules in AGENTS.md are append-only — never remove existing learned rules automatically

## Expected Output

A brief confirmation such as:

```
✅ Retro written to LESSONS.md (entry #8)

Wind 🌬️: Phased approach (read-then-write) prevented overwrites.
Anchor ⚓: Assumed package.json was at root; it was in a subpackage.
Rocks 🪨: CI pipeline not yet validated with new config.
Next 🧭: Add "locate package.json first" to pre-coding checklist.

No patterns promoted (need 3+ occurrences; branch-check miss is at 2×).
```
