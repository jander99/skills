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
