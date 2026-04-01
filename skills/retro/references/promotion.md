# Pattern Promotion to AGENTS.md / CLAUDE.md

Promotion elevates a recurring lesson from a volatile log entry into a durable, always-active rule.

## When to Promote

A pattern is ready to promote when it appears in **3 or more** LESSONS.md entries with the same
root cause — regardless of how similar the surface-level task was.

### Audit-Informed Promotion (v2)

Audit classifications from `references/audit.md` provide an additional signal:

- **Applied 3+ times across distinct sessions** → strong promotion candidate. The lesson demonstrably changed behavior; it belongs in AGENTS.md as a standing rule.
- **Violated 1+ times** → promote with **high urgency**. A lesson that is being ignored despite injection is a systemic failure point. Promote it to AGENTS.md immediately so it fires even without lesson retrieval.
- **Irrelevant 3+ times** → do NOT promote. Staleness is a signal the trigger is too narrow or the situation is rare. Remove from promotion pipeline.

Same-session duplicates still do not count: Applied occurrences must span at least 2 distinct retro sessions.

Examples of promotable patterns:
- 3 entries all have Stop mentioning "forgot to check current branch" → promotable
- 4 entries have Continue mentioning "reading file before writing prevented data loss" → promotable
- 2 entries mention the same thing → NOT yet promotable (wait for a third)
- **Same-session duplicates do not count**: Multiple entries written in the same session about the same issue count as 1 occurrence. Occurrences must span at least 2 distinct retro sessions.

## What NOT to Promote

Avoid promoting:
- **Task-specific rules**: "Always use Tailwind for this project's buttons" — too narrow
- **coincidental patterns**: Two similar entries in the same session (one task, not a real pattern)
- **Negative rules that are already obvious**: "Don't delete production databases" — not useful
- **Preferences masquerading as patterns**: stylistic choices that aren't errors

The litmus test: *Would this rule have prevented a Stop event in 3+ different tasks?*
If yes → promote. If unsure → wait for another occurrence.

For Violated lessons: *Did this lesson fail to prevent the exact Stop it warned about?*
If yes → promote immediately, regardless of Applied count.

## Promotion Format — One-Liners Only

**Every promoted rule MUST be a single bullet ≤120 characters.**

Format:
```markdown
- ALWAYS/NEVER/BEFORE/AFTER/WHEN <imperative action>. <!-- tag: <tag>, promoted: YYYY-MM-DD -->
```

Examples of **correct** one-liner rules:
```markdown
- ALWAYS run `git worktree list --porcelain | awk '/^worktree /{print $2; exit}'` before project-local writes. <!-- tag: git-hygiene, promoted: 2026-03-31 -->
- NEVER commit without running `git status` to confirm no untracked files remain. <!-- tag: git-hygiene, promoted: 2026-03-31 -->
- BEFORE writing any file, read its current contents to avoid silent overwrites. <!-- tag: tool-use, promoted: 2026-03-31 -->
```

Examples of **wrong** format (do not use):
```markdown
- You MUST verify paths and check the current branch. Worktrees create broken contexts.
  Additional note: also run ruff format. (← multi-sentence paragraph, NO)
- Always check branch context first, then proceed to edit. Make sure to run lsp_diagnostics
  after any change to ensure type safety. (← multi-sentence run-on, NO)
```

**Compression rule:** Strip all explanatory prose. Keep only the imperative action and its trigger condition. If the lesson requires explanation to be understood, the lesson is not ready to be a rule — wait until you can express it in one sentence.

### Target File Priority

1. `~/.agents/AGENTS.md` (universal, preferred — cross-tool global rules)
2. `~/.config/opencode/AGENTS.md` (OpenCode global)
3. `AGENTS.md` in project root (project-level)
4. `CLAUDE.md` (Claude Code)
5. Run `mkdir -p ~/.agents` and create `~/.agents/AGENTS.md` if none exists

### Section Structure

Find or create a `## Learned Rules` section. Group rules by tag category:

```markdown
## Learned Rules

> Auto-promoted from LESSONS.md by the `retro` skill on YYYY-MM-DD.
> These rules are active in every session. To remove a rule, delete its bullet.

### Planning
- ALWAYS verify the current branch with `git branch --show-current` before any file modification. <!-- tag: git-hygiene, promoted: 2026-03-31 -->
- BEFORE starting any ambiguous task, ask 1–2 clarifying questions about scope. <!-- tag: planning, promoted: 2026-03-31 -->

### Tool Use
- ALWAYS run `ls` or `glob` to confirm directory structure before assuming file locations. <!-- tag: tool-use, promoted: 2026-03-31 -->
- BEFORE writing, read the file — never overwrite without understanding current contents. <!-- tag: tool-use, promoted: 2026-03-31 -->

### Error Handling
- ON first file read failure, check both the path and the working directory before retrying. <!-- tag: error-handling, promoted: 2026-03-31 -->
```

### Appending Rules

When adding a new promoted rule:

**Step 0 — Dedup check (do this first):**
Take the most distinctive 5–10 word phrase from your new rule.
`grep` (case-insensitive) for that phrase in the target file (AGENTS.md or CLAUDE.md).
- If a ≥80% semantic match is found: **skip the append**. Instead, add a note to the current LESSONS.md entry: `<!-- Rule already promoted on YYYY-MM-DD — skipped dedup -->`
- If no match: proceed to step 1 below.

1. Locate the existing `## Learned Rules` section
2. Find the matching tag subsection (or create it)
3. Append the new bullet — do NOT remove existing bullets
4. Inline comment with promotion date: `<!-- tag: <tag>, promoted: YYYY-MM-DD -->`

## Demotion (Removing a Promoted Rule)

If a promoted rule turns out to be wrong or too aggressive:
1. Delete the specific bullet from `AGENTS.md` / `CLAUDE.md`
2. Add a Stop entry in `LESSONS.md` noting: "Promoted rule `[X]` was over-broad; removed."

This creates a meta-lesson: what kinds of patterns should NOT be promoted.

---

## Converting Existing Long-Form Rules in AGENTS.md

When an AGENTS.md file has multi-sentence, paragraph-style rules in `## Learned Rules`, compress them to one-liners using this process:

### Detection

Rules that need compression satisfy ANY of these:
- More than one sentence (contains `. ` mid-bullet or a second bullet for the same idea)
- Longer than 120 characters
- Contains explanatory prose ("This helps because...", "Note:", "Additional context:")

### Compression Steps

For each long-form rule:

1. **Identify the imperative action** — the thing the agent must DO or AVOID.
2. **Identify the trigger** — the situation where this rule fires.
3. **Write one sentence**: `ALWAYS/NEVER/BEFORE/AFTER <action> when/before <trigger>.`
4. **Verify ≤120 chars.** If longer: drop the trigger clause, or split into two separate rules.
5. **Replace** the old bullet with the new one-liner. Add `<!-- tag: <tag>, promoted: YYYY-MM-DD -->`.

### Conversion Example

**Before** (long-form, 2 sentences):
```markdown
- You MUST run `poetry run` from the **main workspace root**, never from inside a worktree. Worktrees create broken venvs.
- You MUST run `ruff` from the **main workspace root** (e.g., `cd /home/jeff/workspaces/firehose && poetry run ruff format .worktrees/.../file.py`).
```

**After** (one-liners):
```markdown
- NEVER run `poetry run` or `ruff` from inside a worktree — always from the main workspace root. <!-- tag: worktree, promoted: 2026-03-31 -->
```

### Batch Conversion Workflow

To clean up an existing AGENTS.md:
1. Read the `## Learned Rules` section.
2. For each non-compliant bullet, apply the compression steps above.
3. Rewrite the section in-place.
4. Validate: every rule ≤120 chars, one sentence, imperative verb, inline tag comment.
