# Auto-Retro Trigger — AGENTS.md / CLAUDE.md Snippet

Copy the relevant section below into your project's `AGENTS.md`, `CLAUDE.md`, or `.cursorrules`
file to activate the universal (prompt-instruction-based) retro auto-trigger.

This is the **fallback layer** — it works on every tool regardless of whether native hooks exist.
For tools with native hooks (OpenCode, Claude Code, Cline), use the hook scripts in `scripts/`
*in addition* to this snippet for belt-and-suspenders reliability.

---

## Section to add to AGENTS.md / CLAUDE.md / .cursorrules

```markdown
## Auto-Retro Rule

When ALL items in your task/todo list reach a terminal state (every item is either
"completed" or "cancelled", and at least one item is "completed"):

1. **Pause** — do not stop immediately.
2. **Ask the user 1–2 targeted questions** before writing. Examples:
   - "What frustrated you most this session?"
   - "Was there anything you wanted me to do differently?"
   Wait for their answers. Never skip this step, even in auto-trigger mode.
3. **Load the `retro` skill** and follow its full instructions.
4. **Determine where to write lessons:**
   - **Global** → `~/.agents/lessons/LESSONS.md` (always write here)
   - **Project-local** → `<git-repo-root>/.agents/lessons/LESSONS.md` — **only if `.agents/lessons/` directory already exists**. Do NOT create it.
   - **Fallback** (not in a git repo) → `~/.agents/lessons/LESSONS.md`
5. **Worktree awareness:** Get the main repo root with:
   `git worktree list --porcelain | awk '/^worktree /{print $2; exit}'`
   Use this path (not `$(pwd)` or `git rev-parse --show-toplevel`) for project-local lessons.
6. Write using **Start/Stop/Continue** format (see Retro Rubric below).
7. **Promoted rules = one-liners only.** When a pattern meets the 3× promotion threshold,
   write it as a single imperative sentence ≤120 chars in `## Learned Rules`. No paragraphs.
8. Only stop after the retro entry has been written.

### For Claude Code only — sentinel file

When you mark the last task as "completed", create a sentinel file namespaced to the main repo:

    _retro_hash=$(printf '%s' "$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2; exit}' || git rev-parse --show-toplevel 2>/dev/null || true)" | md5sum 2>/dev/null | cut -c1-8 || printf '%s' "$(git rev-parse --show-toplevel 2>/dev/null || true)" | cksum | awk '{print $1}')
    echo "tasks completed" > ~/.agents/.retro-pending-${_retro_hash}

This allows the Stop hook (`.claude/hooks/stop-retro-check.sh`) to re-trigger you
even if the context-window instruction is missed during long sessions.

### Retro Rubric (quick reference)

Use the **Start/Stop/Continue** schema:
- **Start 🚀**: What new practices or habits should we begin?
- **Stop 🛑**: What went wrong, caused friction, or should be eliminated?
- **Continue ✅**: What worked well and should be maintained?

Append the entry to the resolved `LESSONS.md` path with v2 format:

    ## YYYY-MM-DD HH:MM | <tag1> [<tag2>]
    > Trigger: <when this lesson applies>
    > Action: <what to do differently>
    > Scope: <operation-type, file-path-glob, or general>
    **Start 🚀:** ...
    **Stop 🛑:** ...
    **Continue ✅:** ...

### Promoted Rule Format (one-liners only)

Rules promoted to `## Learned Rules` MUST be a single imperative bullet ≤120 chars:

    - ALWAYS <action> when <trigger>. <!-- tag: <tag>, promoted: YYYY-MM-DD -->

To compress existing long-form rules: keep only the imperative action and its trigger.
Remove all explanatory prose. See `references/promotion.md` for the full conversion process.
```

---

## Setup Check (Skill Self-Verification)

When invoked via `/retro setup` or when auto-triggered for the first time in a project:

1. **Locate config file**: Check for `AGENTS.md`, `CLAUDE.md`, or `.cursorrules` in the **project root** only. Do not check or modify global config files.
2. **Search for trigger blurb**: `grep -Ei "retro|retrospective" <found-config-file>`
3. **If NOT found**: Display the snippet above and ask: _"I notice this project doesn't have the retro auto-trigger in AGENTS.md. Would you like me to add it?"_
4. **If confirmed**: Append the snippet to the appropriate project-root file. If neither `AGENTS.md` nor `CLAUDE.md` exists, create `AGENTS.md` at the project root.
5. **If declined**: Note the preference and skip auto-trigger checks in future sessions.

> This check runs once per project. After confirming (or declining), the skill will not ask again.

---

## Claude Code settings.json template

Add to `.claude/settings.json` to activate the Stop hook:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/stop-retro-check.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Cline hooks directory layout

```
.clinerules/
└── hooks/
    └── TaskComplete          ← copy scripts/cline-task-complete-hook.sh here
```

Or globally:

```
~/Documents/Cline/Hooks/
└── TaskComplete              ← copy scripts/cline-task-complete-hook.sh here
```

---

## OpenCode plugin config

In your `opencode.config.ts`:

```typescript
import { defineConfig } from "@opencode-ai/opencode";
import retroAutoTrigger from "./skills/retro/scripts/opencode-plugin-hook";

export default defineConfig({
  plugins: [retroAutoTrigger()],
});
```

---

## Tool Coverage Summary

| Tool      | Trigger Mechanism                   | Reliability | Setup Required |
|-----------|-------------------------------------|-------------|----------------|
| OpenCode  | `tool.execute.after` plugin hook    | ⭐⭐⭐⭐⭐ High  | `opencode.config.ts` |
| Claude Code | `Stop` hook + sentinel file       | ⭐⭐⭐⭐ Good  | `settings.json` + hook script |
| Cline     | `TaskComplete` hook                 | ⭐⭐⭐⭐⭐ High  | Hook script in `.clinerules/hooks/` |
| Cursor    | AGENTS.md prompt instruction only   | ⭐⭐⭐ Medium  | Add snippet to `.cursorrules` |
| Any tool  | AGENTS.md / CLAUDE.md instruction  | ⭐⭐⭐ Medium  | Add snippet to AGENTS.md |

**Two-layer approach (recommended):** Use the native hook for your tool *plus* the
AGENTS.md snippet. The hook catches the trigger even when context is long and the
LLM has "forgotten" the instruction.
