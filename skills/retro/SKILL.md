---
name: retro
description: "Run, write, generate, record, save, persist, and synthesize agent retrospectives and lessons learned after completing tasks. Self-assess session quality, identify mistakes, extract reusable patterns, and update persistent LESSONS.md files. Auto-trigger setup: install OpenCode plugin hooks, Claude Code Stop hooks, and Cline TaskComplete hooks so retros fire automatically when all todos complete. Works with session_read (OpenCode), context-window reconstruction (Claude Code, Cursor, Gemini CLI), and compaction pipelines. Use when finishing a task, at session end, when asked to reflect, review, debrief, or write a post-mortem, or when setting up automatic retro triggers."
license: MIT
metadata:
  version: 1.3.0
  author: jeff
  audience: developers, agents
  workflow: retrospective, self-improvement, lessons-learned
---

## Quick Start

**Prerequisites:** Write access to `~/.agents/lessons/` (universal cross-tool) or tool-specific config dir (see Step 4), and project directory (for optional `.retro/`)

**Tools Used:** Read, Write, Edit, Bash (for `git branch --show-current`), session_read (OpenCode only — optional)

**Trigger phrases:** "run retro", "do a retrospective", "what did you learn", "write lessons learned", "debrief", "post-mortem", "reflect on this session"

**Output files:**
- `~/.agents/lessons/LESSONS.md` — Rolling lessons-learned log, universal across all tools and projects (primary, always written)
- `.retro/YYYY-MM-DD-HH-MM.md` — Per-session archive (optional, when dir exists or created)

**Works across:** OpenCode (full transcript via `session_read`) · Claude Code · Cursor · Gemini CLI (context-window reconstruction)

---

## What I Do

- Run structured self-assessments after completing any task or session
- Extract reusable lessons using the Sailboat rubric (Wind / Anchor / Rocks / Next)
- Write persistent `LESSONS.md` entries to `~/.agents/lessons/LESSONS.md` (universal, cross-tool, cross-project)
- Archive per-session retros to `.retro/` if desired
- Detect available tools and gracefully degrade (full transcript → context reconstruction)
- Compact `LESSONS.md` when it exceeds 20 entries (rolling synthesis)
- Promote recurring patterns (3+ occurrences) to durable rules in `AGENTS.md` / `CLAUDE.md`
- Feed forward: generate one concrete "next session" action item per retro
- **Auto-trigger setup**: provide hook scripts and AGENTS.md snippets that fire the retro automatically when all tasks complete (OpenCode plugin hook, Claude Code Stop hook, Cline TaskComplete hook, universal prompt fallback)

## When to Use Me

Use this skill when you:
- Finish a task and want to capture what worked and what didn't
- Are asked to reflect, debrief, post-mortem, or write lessons learned
- End a coding session and want to leave persistent notes
- Want to identify and promote recurring patterns to permanent rules
- Need to compact a growing `LESSONS.md` into concise synthesized insights
- Are setting up a self-improvement loop for an AI agent
- Want to **auto-trigger** retros: install hooks so the retro fires automatically when all tasks complete

---

## The Retrospective Rubric

Every retro entry uses the **Sailboat+Forward** schema — four fields, always all four:

| Field | Symbol | Question | Example |
|-------|--------|----------|---------|
| **Wind** | 🌬️ | What helped? What worked well? | "Breaking task into sub-steps before coding prevented rework" |
| **Anchor** | ⚓ | What slowed us down or went wrong? | "Assumed file encoding was UTF-8; wasted 2 tool calls debugging" |
| **Rocks** | 🪨 | What risks or unknowns remain? | "Auth logic not tested for edge-case token expiry" |
| **Next** | 🧭 | One concrete action for the next session | "Add encoding check to file-reading checklist" |

**Tags** (pick 1–3 per entry):
`tool-use` · `planning` · `communication` · `error-handling` · `testing` · `api` · `performance` · `security` · `context-management` · `assumptions`

---

## Execution Protocol

### Step 1: Assess Tool Availability

```
IF session_read tool is available (OpenCode):
  → Use session_read to get full session transcript
  → Analyze all messages: what was attempted, what failed, what succeeded
ELSE (Claude Code, Cursor, Gemini CLI, etc.):
  → Reconstruct from current context window:
    - Review the conversation visible in context
    - Note tool calls and their outcomes
    - Identify correction loops (when you had to retry something)
    - Note any user corrections or clarifications needed
```

### Step 2: Self-Assessment Questions

> **Reflection Lens** — assess each axis before writing your entry:
>
> | Axis | What to examine |
> |------|----------------|
> | **Human ↔ LLM** | Communication clarity, assumptions stated, questions asked vs. needed |
> | **LLM ↔ Tool** | Unnecessary tool calls, missed tool opportunities, wrong tools chosen |
> | **LLM ↔ Project** | Convention alignment, scope discipline, codebase pattern adherence |

Work through these questions against the transcript or context:

**Planning**
- Did I ask enough clarifying questions before starting?
- Did I break the task into sub-steps, or dive in immediately?
- Did I verify my branch / working directory before making changes?

**Execution**
- How many correction loops were there? (each loop = signal of a missed assumption)
- Were there tool calls that failed and had to be retried? Why?
- Did I read before writing? (avoid overwriting without understanding)
- Did I use the right tool for each job?

**Communication**
- Did I explain my reasoning before taking action?
- Did the user need to redirect me mid-task?
- Did I surface uncertainty or proceed blindly?

**Output Quality**
- Is the result complete and tested (or at least verifiable)?
- Did I leave the workspace clean (no temp files, no stale branches)?
- Did I commit on the right branch?

### Step 3: Ask Human Questions

Pose **up to 3 targeted questions** to the human based on your self-assessment:
- **1 fixed**: "Is there anything I missed or got wrong about the overall task?"
- **Up to 2 dynamic**: drawn from gaps observed across the three axes above (e.g., if you noticed you called a tool multiple times unnecessarily, ask "Did you feel I was using [tool] too aggressively?")

Wait for human responses before writing the LESSONS.md entry. If no human responds within the session, note "No human feedback received" in the Rocks section.

### Step 4: Write the LESSONS.md Entry

Resolve the LESSONS.md path using the detection logic below, then append. If creating from scratch, use the **New File Template** in the [LESSONS.md Format](#lessonsmd-format) section below — it includes the required `<!-- retro:entries:0 -->` counter that compaction depends on.

#### Path Resolution (run once per session)

Preferred target is `~/.agents/lessons/LESSONS.md` — the canonical cross-tool home used by vercel-labs/skills and documented by gptme as the cross-platform lessons standard.

```bash
# Detect the right LESSONS.md location
if [ -d "$HOME/.agents" ]; then
  # Universal cross-tool home (vercel-labs/skills, gptme standard) — preferred
  LESSONS_PATH="$HOME/.agents/lessons/LESSONS.md"
  mkdir -p "$HOME/.agents/lessons"
elif [ -n "$OPENCODE_CLIENT" ] || [ -f "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/opencode.json" ]; then
  LESSONS_PATH="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/LESSONS.md"
elif [ -d "${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}" ]; then
  LESSONS_PATH="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}/LESSONS.md"
elif [ -d "$HOME/.claude" ]; then
  LESSONS_PATH="$HOME/.claude/LESSONS.md"
elif [ -d "${CURSOR_CONFIG_DIR:-$HOME/.cursor}" ]; then
  LESSONS_PATH="${CURSOR_CONFIG_DIR:-$HOME/.cursor}/LESSONS.md"
elif [ -d "$HOME/.gemini" ]; then
  LESSONS_PATH="$HOME/.gemini/LESSONS.md"
elif [ -n "${CONTINUE_GLOBAL_DIR:-}" ] || [ -d "$HOME/.continue" ]; then
  LESSONS_PATH="${CONTINUE_GLOBAL_DIR:-$HOME/.continue}/LESSONS.md"
elif [ -d "$HOME/.codeium/windsurf" ]; then
  LESSONS_PATH="$HOME/.codeium/windsurf/LESSONS.md"
else
  # Final fallback: create ~/.agents/lessons/ on first use
  mkdir -p "$HOME/.agents/lessons"
  LESSONS_PATH="$HOME/.agents/lessons/LESSONS.md"
fi
```

> **Note for non-shell tools** (Claude Code, Cursor, Gemini CLI): evaluate the conditions above in order and write to the first matching path. In practice, if you can see `~/.agents/` exists, always prefer `~/.agents/lessons/LESSONS.md`.

```markdown
## YYYY-MM-DD HH:MM | <tag1> [<tag2>]

**Wind 🌬️:** <what helped or worked well>

**Anchor ⚓:** <what went wrong or slowed progress>

**Rocks 🪨:** <risks or unknowns remaining>

**Next 🧭:** <one concrete action for next session>
```

**Writing rules:**
- Be specific: name the actual file, tool, or command involved
- Keep each field to 1–2 sentences
- If nothing went wrong: "Anchor: None notable" is valid (don't fabricate)
- If nothing was accomplished: still write the entry — document the reason

### Step 5: Archive (Optional)

If `.retro/` directory exists in the project (or user asks to archive):

```bash
mkdir -p .retro
# Write full session notes to: .retro/YYYY-MM-DD-HH-MM.md
```

The archive file can include more verbose notes, tool call counts, correction loop analysis.

### Step 6: Entry Counter + Compaction Check

After writing the new entry, update the entry counter in `LESSONS.md`:

1. **Read** `<!-- retro:entries:N -->` at the top of the file (fallback: count `## YYYY-` date headings if comment is absent).
2. **Increment** N by 1 and rewrite the comment in-place: `<!-- retro:entries:N+1 -->`.
3. **If N+1 > 20**: run compaction (see [references/compaction.md](references/compaction.md)), then reset the counter to the number of preserved entries.

**Pattern promotion check:** Scan the last 20 entries.
- If any theme appears in **3 or more** entries → candidate for promotion
- Promoted rules go into `~/.agents/AGENTS.md` (universal) or `~/.config/opencode/AGENTS.md` (OpenCode global) or project-level `AGENTS.md` / `CLAUDE.md` under a `## Learned Rules` section
- Example promotion: 3 entries all mention "forgot to check branch" → add rule: "Always verify branch with `git branch --show-current` before any file modifications"

---

## Tool Availability Matrix

| Tool | session_read | Context Quality | Notes |
|------|-------------|-----------------|-------|
| OpenCode | ✅ Full transcript | Excellent | Use `session_read` for complete history |
| Claude Code | ❌ Not available | Good (long context) | Reconstruct from context window |
| Cursor | ❌ Not available | Medium | Context may be truncated |
| Gemini CLI | ❌ Not available | Medium | Context may be truncated |

When `session_read` is unavailable, explicitly note in the retro entry:
`> Note: Reconstructed from context window (session_read unavailable)`

---

## LESSONS.md Format

### New File Template

```markdown
# Lessons Learned

> Auto-generated by the `retro` skill. Each entry follows the Sailboat+Forward schema.
> Entries with 3+ recurrences are promoted to `AGENTS.md` as durable rules.

<!-- retro:entries:0 -->

```

### Mature File (with entries)

```markdown
# Lessons Learned

> Auto-generated by the `retro` skill.

<!-- retro:entries:7 -->

## 2026-03-04 14:30 | planning tool-use

**Wind 🌬️:** Breaking the migration task into read-first / write-second phases eliminated destructive overwrites.

**Anchor ⚓:** Assumed `package.json` was in the project root; it was in a monorepo subpackage. Cost 3 tool calls.

**Rocks 🪨:** The CI pipeline hasn't been tested with the new config yet.

**Next 🧭:** Add "locate package.json first" to pre-coding checklist in AGENTS.md.

---
```

The HTML comment `<!-- retro:entries:N -->` is the entry counter used by compaction logic.

---

## Examples

**Minimal invocation:**
```
User: "run retro"
Agent: [assesses session] → appends to LESSONS.md → reports summary
```

**Explicit on session end:**
```
User: "we're done, do a retro before wrapping up"
Agent: [reads transcript or reconstructs] → writes entry → checks for patterns → reports
```

**Compaction trigger:**
```
User: "compact lessons learned"
Agent: [synthesizes 20+ entries into patterns] → rewrites LESSONS.md → promotes rules to AGENTS.md
→ Grade: 89/100 before compaction, patterns reduced to 3 durable AGENTS.md rules
```

**Promotion (OpenCode full transcript):**
```
User: "session is done, please do a retro and promote any patterns"
Agent: [session_read available] → reads all 47 messages → finds 2 branch-check misses
     → writes Anchor: "forgot git branch --show-current twice"
     → count reaches 3 → promotes to AGENTS.md ## Learned Rules
```

---

## Common Errors & Fixes

| Error | Symptom | Fix |
|-------|---------|-----|
| Writing on wrong branch | Commit lands on `main` | Check `git branch --show-current` before any edit |
| Assuming file structure | Tool call fails on missing path | `ls` / `glob` before `read` |
| Skipping clarification | Mid-task redirect from user | Ask 1-2 questions upfront on ambiguous tasks |
| Overwriting without reading | Data loss | Always `read` before `write` on existing files |
| Fabricating retro content | Meaningless entries | "None notable" is always valid |
| session_read unavailable | Cannot access full transcript | Fall back to context-window reconstruction (see [references/session-read.md](references/session-read.md)) |

---

## References

| Reference | Use When |
|-----------|----------|
| [references/compaction.md](references/compaction.md) | LESSONS.md has >20 entries; need synthesis |
| [references/promotion.md](references/promotion.md) | Promoting patterns to AGENTS.md / CLAUDE.md |
| [references/session-read.md](references/session-read.md) | Using `session_read` in OpenCode for full transcript |
| [references/auto-trigger.md](references/auto-trigger.md) | Setting up automatic retro triggers (hooks + AGENTS.md) |

### Auto-Trigger Scripts

| Script | Tool | Description |
|--------|------|-------------|
| [scripts/opencode-plugin-hook.ts](scripts/opencode-plugin-hook.ts) | OpenCode | Plugin hook — fires when all todos complete |
| [scripts/claude-code-stop-hook.sh](scripts/claude-code-stop-hook.sh) | Claude Code | Stop hook — checks sentinel, re-prompts retro |
| [scripts/cline-task-complete-hook.sh](scripts/cline-task-complete-hook.sh) | Cline | TaskComplete hook — injects retro prompt |

## Related Skills

- `skill-helper` — For improving this skill itself
- `markdown-editor` — For formatting LESSONS.md and .retro/ archives
- `find-skills` — If you need additional self-improvement patterns
