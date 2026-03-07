## 2026-03-06 Task 1 - v2 schema doc
- v2 entry extension is stable when Trigger/Action/Scope are mandatory and ordered directly below the heading.
- Keeping SYNTHESIZED as heading+3 headers+freeform body avoids overfitting and preserves compacted narrative value.
- Parser-facing well-formed/malformed rules should be explicit about ordering and field presence, not prose quality.
- The `<!-- retro:entries:N -->` marker must be treated as a durable contract because compaction triggers at 20+ entries depend on it.
- Tag normalization works best with lowercase canonical tags and `[untagged]` fallback for sparse entries.

## 2026-03-06 Task: T2 — Parser Script

**Implementation decisions:**
- `set -euo pipefail` requires `|| true` guards on every `grep` call used for value extraction (not just boolean checks). Boolean `if ! grep -q` patterns are safe but `x=$(grep ...)` without `|| true` fails on empty match.
- `parse_entries` stores full multi-line entry bodies in bash arrays using `$'\n'` concatenation — avoids temp files but requires careful IFS handling (kept default IFS in read loop, used `IFS=` only for literal newlines).
- `--recent N` logic: entries in array are file-order (oldest→newest); reverse last N to get newest-first output. Used array slice + manual reverse loop.
- Token estimation: `words * 1.3` truncated — `$(( (words * 13) / 10 ))` in bash integer arithmetic avoids floating point.
- `cmd_migrate` uses `prev_was_heading` state flag instead of lookahead — reads one line at a time, buffers heading, checks next line to detect v1 vs v2.
- `resolve_file()` helper was defined but not actually used in final version (each subcommand inlines the logic) — can be removed in cleanup pass if line budget matters.
- Line count: 298/300. Achieved by consolidating `resolve_file` to one line and compressing section dividers.
- `array+=("${rev[@]+"${rev[@]}"}") ` — bash namerefs with `+` suffix prevents unbound-variable error on empty arrays with `set -u`.

**Gotchas:**
- `SYNTHESIZED` heading regex needed a trailing `[[:space:]]` to distinguish `## SYNTHESIZED — title` from other `## S...` patterns; without it a heading `## Scoping rules` would match.
- `diff -u` in `--dry-run` mode exits 1 when there are differences — added `|| true` to prevent set -e from killing the script.
- `grep -cE` exits 1 when count is 0 in some systems; wrapped with `|| true`.

## 2026-03-06 Task: T8 — Migration Guide + Hooks
- migration.md covers 5 sections: Overview, Automatic Migration, Manual Migration Guide, Before/After Example, Validation
- Automatic migration uses `retro-lessons.sh migrate` to insert placeholder Trigger/Action/Scope after v1 headings; never touches Sailboat fields
- Manual inference rules: Anchor → Trigger, Next → Action, tags → Scope (default `general`)
- Before/After example uses a real LESSONS.md entry (2026-03-06 08:36 | planning api) — shows 3 stages: raw v1, post-migrate (placeholders), post-review (real values)
- Backup callout uses `$(date +%Y%m%d)` suffix convention
- Hook comment blocks inserted ONLY as comments; no logic was modified — confirmed by git diff showing only `+#` and `+//` lines
- claude-code-stop-hook.sh: block inserted between `# ===` separator and section header
- cline-task-complete-hook.sh: same pattern — between `# ===` and section header
- opencode-plugin-hook.ts: block inserted after `import` line, before type declarations
- `diff -u` produces exit 1 on diffs; captured with `|| true` to avoid breaking evidence collection
- Evidence files: task-8-migration-doc.txt (full migration.md content), task-8-hook-diffs.txt (git diff output)

## 2026-03-06 Task: T7 — SKILL.md Rewrite

**What was cut:** Verbatim path-detection bash script (35 lines), full self-assessment question matrix, tool availability table, LESSONS.md new-file template, per-step prose protocol (Steps 1–6), examples section with 4 verbose scenarios, common errors table (6 rows inline), auto-trigger scripts table. Total reduction: 328 → 152 lines.

**What was kept:** YAML frontmatter (updated to v2.0.0, description updated with "retrieve-verify loop"), Quick Start (slimmed + Prerequisites added), What I Do bullets (added in second pass to satisfy validator), The Loop (5-phase description with reference links), Entry Format (canonical v2 code block + SYNTHESIZED variant), Using the Parser (retro-lessons.sh subcommands), Tool Detection (slim table), Common Errors (slim table added in second pass), Examples (3-line compact block), References (all 8 docs + script).

**Token count:** Words: 827, Estimated tokens: 1075 (limit: 1800). Budget used: 60%.

**Validation score:** 100/100, Grade A. Required two iterations — first pass got 93/100 (missing What I Do + examples + prerequisites). Second pass added those sections (+~80 words), reached 98/100. Third pass added Common Errors table (+~60 words), reached 100/100.

**Key convention:** validate-skill.sh detects "No examples section found", "No 'What I Do' section found", "Prerequisites not documented" as warnings that cost points. These are easy fixes (~60 words each) that pay 5 points each. Worth adding even in a thin orchestrator.

**Token measurement gotcha:** `grep -n "^---$" SKILL.md | tail -1` picks up body `---` horizontal rules as the "second frontmatter fence". Always use `| head -2 | tail -1` to get exactly the second `---` (end of frontmatter), not later ones.

**YAML description:** Must mention "retrieve-verify loop" explicitly — the description field drives skill discovery and should contain all key trigger phrases. Quoted because it contains `: ` (colon-space).

## 2026-03-06 Task: T9 — E2E Validation

**What passed (all clean, zero fixes needed):**
- `validate-skill.sh` → 100/100 Grade A, 0 errors, 0 warnings, 3 suggestions only
- SKILL.md token budget: 827 words → ~1075 estimated tokens (limit 1800) ✅
- All 9 reference docs present with ≥20 lines (min: session-read.md at 57, max: injection.md at 153)
- All 3 hook scripts contain v2 TRIGGER + RETRO WORKFLOW comments ✅
- retro-lessons.sh all 7 subcommands functional against synthetic e2e-test.md ✅
- migrate --dry-run on 228-line LESSONS copy: 14 entries correctly identified for migration ✅

**Key gotcha found:**
- Token budget script from task spec uses `grep -n "^---$" | tail -1` which in a SKILL.md with many `---` section dividers (11 total!) returns the second-to-last line (143), leaving only 2 lines in the "body". The correct approach is `head -2 | tail -1` to get the second `---` (the frontmatter close at line 10). Fixed in evidence file.
- Inherited wisdom note was correct: use `|| true` guards — `validate` subcommand exits 1 on bad entries (as expected for the v1-style entry in the synthetic file).

**Final validate-skill.sh score: 100/100 Grade A**

## 2026-03-06 Task: F3 — Second Validation Pass
**validate-skill score:** 100/100 Grade A — ZERO errors, ZERO warnings, 3 suggestions (cosmetic only)
- Suggestion "Consider adding version to metadata" is a false positive: version is at `metadata.version: 2.0.0` in YAML frontmatter (not top-level `version:` field)
- All 14 files verified: SKILL.md + 9 references + 4 scripts

**promotion format check result:** PASS (G5 guardrail satisfied)
- The `- **[tag]**: Action (Trigger: trigger)` injection format is preserved unchanged in injection.md (lines 75, 86) and SKILL.md (line 45)
- AGENTS.md promotion uses subsection-based bullets (## Learned Rules → ### Tag → plain bullets) — this is intentional v2 design, distinct from injection format
- G5 constraint is about the injection format, not the AGENTS.md file bullets — both are correct

**reference completeness finding:**
- SKILL.md references table contains 8 of 9 reference docs: schema, retrieval, injection, audit, compaction, promotion, session-read, auto-trigger
- `references/migration.md` EXISTS but is NOT listed in SKILL.md references table
- Validator still passes (it checks file existence, not table completeness)
- This is a minor gap — migration.md is referenced in SKILL.md prose indirectly (migration.md was T1)

**evidence files:** `.sisyphus/evidence/task-f3-validation.txt`, `.sisyphus/evidence/task-f3-agents-format.txt`

## 2026-03-06 Task: F2 — Integration Test

**Status**: Full loop completed successfully. All 6 subcommands ran without crashes.

**inject**: Returns 4 of 5 entries (v1 entry silently skipped — no Action to extract). Outputs `## Relevant Lessons` block with bullet format. SYNTHESIZED entry appears first (most recent). Exit 0.

**retrieve --tag git**: Returns 2 entries — `git rebase` (tagged "git") and SYNTHESIZED (tagged "git api deploy"). Tag matching works on multi-tag headings. Exit 0.

**retrieve --operation deploy**: Returns exactly 1 entry (`deploy production`) where Trigger contains "deploy". Exit 0.

**validate**: Correctly exits 1 and reports ERROR at line 30 (the v1 entry) for all 3 missing headers. Exit codes are semantically correct (0=clean, 1=issues found).

**migrate --dry-run**: Shows correct diff (adds placeholder `> Trigger:`, `> Action:`, `> Scope:` to v1 entry). File confirmed unchanged after dry-run. Minor UX issue: prints "Migrated 1 entry." instead of "Would migrate 1 entry." — misleading phrasing.

**migrate (actual)**: Inserts placeholders successfully. File modified in-place. Exit 0.

**validate after migrate**: Exits 0 — all entries now have required headers. migrate→validate round-trip is clean.

**count**: Returns 5 both before and after migrate. Count is stable across migration.

**Issues to track**:
1. `inject` silently omits v1 entries — spec says 5 bullets max but only 4 shown. Consider outputting v1 entries with a degraded format.
2. `migrate --dry-run` prints "Migrated N entries." when it should say "Would migrate N entries." — confusing phrasing.

---
## Fix Pass Session — 2026-03-06

**All 12 fixes applied and validated at 100/100 Grade A.**

### Key findings:

**FIX 4 — migrate regex**: `[[ "$line" =~ ^'> Trigger:' ]]` silently failed because single-quoted patterns inside `=~` match literal quote chars. Fixed to `[[ "$line" == "> Trigger:"* ]]`.

**FIX 8 — --operation flag**: It was matching `> Trigger:` lines but the spec says it should match `> Scope:`. Conceptually: "operation" is the context in which to apply the lesson, matching scope makes more sense.

**FIX 9 — injection.md markers**: Both the section-structure code block and the audit-trail block had `tag1,tag2`. Both fixed to `tag1 tag2`. No occurrences missed.

**FIX 11 — pipe idiom**: `inject` reads a FILE argument (or `-` for stdin). The pipe example was missing the `-` argument, so inject would fall back to default LESSONS.md instead of reading piped retrieve output.

**FIX 12 — migration.md**: Script emits `[migrated — fill in manually]` but docs showed `(TODO: infer from Anchor)`. The "After Automatic Migration" example block had two occurrences — both fixed.

**Validation**: 100/100, 0 errors, 0 warnings. Only 3 cosmetic suggestions (name uniqueness check, add version, add decision matrix).
