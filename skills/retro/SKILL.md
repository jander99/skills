---
name: retro
description: "Run, write, generate, record, save, persist, and synthesize agent retrospectives and lessons learned after completing tasks. Self-assess session quality, identify mistakes, extract reusable patterns, and update persistent LESSONS.md files using the retrieve-verify loop. Auto-trigger setup: install OpenCode plugin hooks, Claude Code Stop hooks, and Cline TaskComplete hooks so retros fire automatically when all todos complete. Works with session_read (OpenCode), context-window reconstruction (Claude Code, Cursor, Gemini CLI), and compaction pipelines. Use when finishing a task, at session end, when asked to reflect, review, debrief, or write a post-mortem, or when setting up automatic retro triggers."
license: MIT
metadata:
  version: 2.0.0
  author: jeff
  audience: developers, agents
  workflow: retrospective, self-improvement, lessons-learned
---

## Quick Start

**Prerequisites:** Write access to `~/.agents/lessons/` (global) and optionally `<git-repo-root>/.agents/lessons/` (project-local). Git configured.

**When to run:** At session end · when asked to "reflect", "debrief", "post-mortem", or "write lessons" · auto-triggered when all todos complete.

**Output file:** `~/.agents/lessons/LESSONS.md` (global) or `<git-repo-root>/.agents/lessons/LESSONS.md` (project-local) — classified at write time. Use `retro-lessons.sh paths` to see resolved paths.

**Tools needed:** Read, Write, Bash · `session_read` (OpenCode only) · `retro-lessons.sh` (parser/retrieval)

---

## What I Do

- Run structured self-assessments using the Sailboat+Forward rubric (Wind / Anchor / Rocks / Next)
- Classify lessons as global (cross-project) or project-local (language/framework/repo-specific) and write to the correct file
- Retrieve and inject relevant past lessons before high-risk operations (the retrieve-verify loop)
- Audit whether injected lessons were Applied, Violated, or Irrelevant
- Compact LESSONS.md when it exceeds 20 entries; promote 3+ occurrence patterns to AGENTS.md
- Set up auto-trigger hooks (OpenCode plugin, Claude Code Stop hook, Cline TaskComplete hook)

---

## The Loop

The v2 retro skill runs a five-phase **reflect → store → retrieve → inject → verify** loop.

1. **Reflect** — assess the session via `session_read` transcript (OpenCode) or context-window reconstruction (all other tools). Identify correction loops, tool failures, and user redirects. Ask the human up to 3 targeted questions before writing. See [references/session-read.md](references/session-read.md).

2. **Store** — classify the lesson as **global** or **project-local** (see classification rules below), then append a v2 entry to the correct `LESSONS.md`. **Before writing, run the concurrent-write checkpoint; after writing, run finalize (see Concurrent-Write Safety below).** Increment `<!-- retro:entries:N -->`. If N+1 > 20, run compaction. Check whether any theme appears 3+ times; if so, promote to `AGENTS.md`. See [references/compaction.md](references/compaction.md) and [references/promotion.md](references/promotion.md).

   **Classification rules:**
   - **Global** → `~/.agents/lessons/LESSONS.md`: tool-agnostic lessons, workflow habits, communication patterns, cross-project debugging approaches, general engineering principles.
   - **Project-local** → `<git-repo-root>/.agents/lessons/LESSONS.md`: lessons tied to the project's language/framework (ruff/poetry, Maven, npm scripts), project-specific file paths, repo conventions, or any lesson whose Scope contains a project-specific path glob.
   - **Fallback**: if not inside a git repository, always write to `~/.agents/lessons/LESSONS.md`.

3. **Retrieve** — at session start, run `retro-lessons.sh inject --both` to pull top lessons from both global and project-local files. Before high-risk ops (git-push, git-commit, file-deletion, deployment, secrets-handling), run `retro-lessons.sh retrieve --both --operation <op>`. See [references/retrieval.md](references/retrieval.md).

4. **Inject** — format retrieved lessons into a compact `## Relevant Lessons` block (≤500 tokens, ≤5 bullets) and place in context before acting. Each bullet: `- **[tag]**: Action (Trigger: trigger)`. See [references/injection.md](references/injection.md).

5. **Verify** — after writing the Sailboat rubric, append an `> Audit:` block classifying each injected lesson as **Applied**, **Violated**, or **Irrelevant**. Violations generate a new reinforcing entry. See [references/audit.md](references/audit.md).

---


## Concurrent-Write Safety

Multiple worktrees running retro simultaneously share the same `LESSONS.md` files. Without coordination the second writer **silently overwrites** the first's entry. Use `checkpoint` → write → `finalize` to prevent data loss.

### The Problem

`LESSONS.md` lives outside individual worktree directories. Two agents that simultaneously read the file, append a new entry, and save will clobber each other — the second `Write` call overwrites the entire file with a version that does not contain the first agent's entry.

### Protocol: checkpoint → write → finalize

**Step 1 — Checkpoint (before reading/writing):**
```bash
bash skills/retro/scripts/retro-lessons.sh checkpoint ~/.agents/lessons/LESSONS.md
# or for project-local:
bash skills/retro/scripts/retro-lessons.sh checkpoint --local
```
`checkpoint` detects uncommitted content left by a concurrent worktree and commits it. **Re-read the file after checkpoint** to get the latest state before appending.

**Step 2 — Write:** Append your v2 entry as normal using the Write/Edit tool.

**Step 3 — Finalize (immediately after writing):**
```bash
bash skills/retro/scripts/retro-lessons.sh finalize ~/.agents/lessons/LESSONS.md
# or:
bash skills/retro/scripts/retro-lessons.sh finalize --local
```
`finalize` stages and commits your entry immediately so any concurrent worktree that calls `checkpoint` next sees it.

### Requirements

- The directory containing `LESSONS.md` must be inside a git repository.
- If it is **not** tracked by git, both commands emit `INFO:` and exit 0 — no protection is applied.
  To enable protection for the global file:
  ```bash
  git init ~/.agents/lessons && git -C ~/.agents/lessons add LESSONS.md && git -C ~/.agents/lessons commit -m "init"
  ```
- Do **not** use `--no-verify` on these commits. If a hook rejects the commit, fix the failure before retrying.

### Quick Reference

| Situation | Action |
|---|---|
| `git status` shows `LESSONS.md` dirty before your write | Run `checkpoint`, then re-read the file, then append |
| You just appended a new entry | Run `finalize` immediately |
| LESSONS.md not in any git repo | No protection; write as normal — consider initializing git |

---

## Entry Format

v2 entries have an 8-line structure — heading + 3 retrieval headers + 4 Sailboat fields:

```markdown
## YYYY-MM-DD HH:MM | tag1 tag2
> Trigger: <when this lesson applies>
> Action: <what to do differently>
> Scope: <file-path-glob, operation-type, or general>
**Wind 🌬️:** <what went well>
**Anchor ⚓:** <what went wrong>
**Rocks 🪨:** <risks/unknowns>
**Next 🧭:** <concrete next action>
```

SYNTHESIZED variant: `## SYNTHESIZED — <title> | tag1 tag2` + same 3 headers + freeform body.

Full validation rules and examples → [references/schema.md](references/schema.md).

---

## Using the Parser

`skills/retro/scripts/retro-lessons.sh` — subcommands:

```bash
retro-lessons.sh inject --both                 # session-start: merge top lessons from global + project
retro-lessons.sh retrieve --both --operation git-push  # pre-risk: from both files
retro-lessons.sh retrieve --local --tag python  # project-specific tag search
retro-lessons.sh validate                      # check LESSONS.md file health
retro-lessons.sh count                         # show entry count
retro-lessons.sh paths                         # show resolved global and local paths
retro-lessons.sh checkpoint ~/.agents/lessons/LESSONS.md  # pre-write: commit any dirty state
retro-lessons.sh finalize ~/.agents/lessons/LESSONS.md    # post-write: commit new entry
```

Default file: `~/.agents/lessons/LESSONS.md`. Pass `--local` (project-local), `--global` (default), or `--both` (merge from both files). Use `paths` subcommand to inspect resolved paths.

---

## Tool Detection

| Tool | Method | Quality |
|------|--------|---------|
| OpenCode | `session_read` — full transcript | Excellent |
| Claude Code | Context-window reconstruction | Good |
| Cursor / Gemini CLI | Context-window reconstruction | Medium |

When `session_read` is unavailable, note in the entry: `> Reconstructed from context window (session_read unavailable)`.

Setup for auto-trigger (hooks + AGENTS.md snippet) → [references/auto-trigger.md](references/auto-trigger.md).

---

## References

| Reference | Content |
|-----------|---------|
| [references/schema.md](references/schema.md) | v2 entry format, tag rules, scope conventions, validation rules |
| [references/retrieval.md](references/retrieval.md) | When/how to retrieve — session-start vs pre-risk, retrieval algorithm, zero-match fallback |
| [references/injection.md](references/injection.md) | Injection format, two-layer injection, 500-token budget, anti-patterns |
| [references/audit.md](references/audit.md) | 5-phase audit protocol — Applied/Violated/Irrelevant, violations → new entries |
| [references/compaction.md](references/compaction.md) | Compact when N>20 — archive, pattern detection, SYNTHESIZED output |
| [references/promotion.md](references/promotion.md) | Promote 3+ occurrence patterns to AGENTS.md / CLAUDE.md |
| [references/migration.md](references/migration.md) | v1-to-v2 migration guide |
| [references/session-read.md](references/session-read.md) | `session_read` usage in OpenCode, graceful degradation |
| [references/auto-trigger.md](references/auto-trigger.md) | Hook setup for OpenCode, Claude Code, Cline; AGENTS.md snippet |
| [scripts/retro-lessons.sh](scripts/retro-lessons.sh) | Bash parser: validate, retrieve, inject, count, migrate, paths subcommands; `--global`/`--local`/`--both` flags |
| [Concurrent-Write Safety](#concurrent-write-safety) | `checkpoint`/`finalize` protocol to prevent concurrent-worktree data loss |

---

## Common Errors

| Error | Fix |
|-------|-----|
| Wrong LESSONS.md path | Run `retro-lessons.sh paths` to see resolved global and local paths |
| v1 entry (no Trigger/Action/Scope) | Run `retro-lessons.sh migrate` to upgrade to v2 format |
| Token budget exceeded at injection | Trim to ≤5 bullets; oldest entries trimmed first |
| Compaction triggered but <20 entries | Check `<!-- retro:entries:N -->` counter — may be miscounted; use `retro-lessons.sh count` |
| Audit markers missing | Note `> Audit: no injection markers found; best-effort recall used.` |
| LESSONS.md overwritten by concurrent worktree | Run `checkpoint` before reading; run `finalize` immediately after writing |

---

## Examples

```
User: "run retro"
Agent: assesses session → injects lessons → writes v2 entry → audits → appends to LESSONS.md

User: "compact lessons"
Agent: synthesizes 20+ entries → writes SYNTHESIZED blocks → resets counter → promotes patterns

User: "we're done, reflect on what happened"
Agent: session_read (OpenCode) or context-window → Sailboat rubric → Audit block → LESSONS.md
```

---

## Related Skills

- `skill-helper` — improve this skill
- `markdown-editor` — format LESSONS.md and `.retro/` archives
