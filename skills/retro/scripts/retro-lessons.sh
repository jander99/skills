#!/usr/bin/env bash
# retro-lessons.sh — Validate/retrieve/inject LESSONS.md (v2 schema).
# Pure bash + standard unix tools only. No jq/python/node/curl.
set -euo pipefail
DEFAULT_FILE="${HOME}/.agents/lessons/LESSONS.md"

usage() {
  cat <<'EOF'
Usage: retro-lessons.sh <subcommand> [options] [FILE]

Default FILE: ~/.agents/lessons/LESSONS.md  (use - for stdin)

Subcommands:
  validate [FILE]            Validate all v2 entry blocks; exit 1 if any bad
  retrieve [OPTIONS] [FILE]  Filter and print matching entries
    --tag <tag>              Match entries whose heading contains <tag> (after |)
    --scope <pattern>        Match entries where > Scope: contains <pattern>
    --operation <op>         Match entries where > Trigger: contains <op>
    --recent <N>             Return last N entries (newest first)
    --full                   Include full body (Sailboat fields)
  inject [--budget N] [FILE] Print top-5 lessons formatted for prompt context
  count [FILE]               Print number of v2 entries
  migrate [--dry-run] [FILE] Upgrade v1 entries to v2 by injecting placeholder headers
  --help                     Show this help and exit
EOF
  exit 0
}

# ── helpers ──────────────────────────────────────────────────────────────────

resolve_file() { local arg="${1:-}"; [[ -z "$arg" || "$arg" == "-" ]] && echo "-" || echo "$arg"; }

# Populates ENTRY_HEADS / ENTRY_LINES / ENTRY_BODIES from FILE (or stdin if -)
parse_entries() {
  local file="$1"
  ENTRY_HEADS=(); ENTRY_LINES=(); ENTRY_BODIES=()
  local lineno=0 cur_entry="" cur_head="" cur_line=0 in_entry=0
  while IFS= read -r line; do
    (( lineno++ )) || true
    if [[ "$line" =~ ^##[[:space:]]+(SYNTHESIZED[[:space:]]|[0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
      if [[ $in_entry -eq 1 ]]; then
        ENTRY_HEADS+=("$cur_head")
        ENTRY_LINES+=("$cur_line")
        ENTRY_BODIES+=("$cur_entry")
      fi
      cur_head="$line"; cur_line=$lineno; cur_entry="$line"; in_entry=1
    elif [[ $in_entry -eq 1 ]]; then
      cur_entry+=$'\n'"$line"
    fi
  done < <(_read_input "$file")
  if [[ $in_entry -eq 1 ]]; then
    ENTRY_HEADS+=("$cur_head"); ENTRY_LINES+=("$cur_line"); ENTRY_BODIES+=("$cur_entry")
  fi
}

_read_input() {
  local f="$1"
  if [[ "$f" == "-" ]]; then cat; else cat "$f"; fi
}

# Extract tag(s) from a heading line (text after last |, trimmed, lowercased)
heading_tags() {
  local head="$1"
  local after_pipe="${head##*|}"
  echo "$after_pipe" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Estimate token count: words * 1.3, truncated
token_est() {
  local text="$1"
  local words
  words=$(echo "$text" | wc -w)
  echo $(( (words * 13) / 10 ))
}

# ── validate ─────────────────────────────────────────────────────────────────

cmd_validate() {
  local file="${1:-$DEFAULT_FILE}"
  if [[ ! -f "$file" && "$file" != "-" ]]; then
    mkdir -p "$(dirname "$file")"
    printf '<!-- retro:entries:0 -->\n' > "$file"
    exit 0
  fi
  local content; content=$(_read_input "$file")
  [[ -z "$content" ]] && exit 0

  parse_entries "$file"
  local errors=0 i
  for (( i=0; i<${#ENTRY_BODIES[@]}; i++ )); do
    local body="${ENTRY_BODIES[$i]}" head="${ENTRY_HEADS[$i]}" ln="${ENTRY_LINES[$i]}"
    local is_synth=0
    [[ "$head" =~ ^##[[:space:]]+SYNTHESIZED ]] && is_synth=1

    # Check Trigger/Action/Scope lines
    if ! echo "$body" | grep -q '> Trigger:'; then
      echo "ERROR: entry at line $ln: missing '> Trigger:'" >&2; (( errors++ )) || true
    fi
    if ! echo "$body" | grep -q '> Action:'; then
      echo "ERROR: entry at line $ln: missing '> Action:'" >&2; (( errors++ )) || true
    fi
    if ! echo "$body" | grep -q '> Scope:'; then
      echo "ERROR: entry at line $ln: missing '> Scope:'" >&2; (( errors++ )) || true
    fi

    if [[ $is_synth -eq 0 ]]; then
      for field in '\*\*Wind' '\*\*Anchor' '\*\*Rocks' '\*\*Next'; do
        if ! echo "$body" | grep -qE "$field"; then
          echo "WARN: entry at line $ln: missing body field matching $field" >&2
        fi
      done
    fi
  done
  [[ $errors -gt 0 ]] && exit 1 || exit 0
}

# ── retrieve ─────────────────────────────────────────────────────────────────

cmd_retrieve() {
  local tag="" scope="" operation="" recent=0 full=0 file="$DEFAULT_FILE"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tag)      tag="$2";       shift 2 ;;
      --scope)    scope="$2";     shift 2 ;;
      --operation) operation="$2"; shift 2 ;;
      --recent)   recent="$2";    shift 2 ;;
      --full)     full=1;         shift ;;
      -*)         echo "WARN: unknown option $1" >&2; shift ;;
      *)          file="$1";      shift ;;
    esac
  done
  [[ ! -f "$file" && "$file" != "-" ]] && exit 0
  parse_entries "$file"
  [[ ${#ENTRY_HEADS[@]} -eq 0 ]] && exit 0

  local matches=() i
  for (( i=0; i<${#ENTRY_BODIES[@]}; i++ )); do
    local body="${ENTRY_BODIES[$i]}" head="${ENTRY_HEADS[$i]}"
    local tags; tags=$(heading_tags "$head")

    # AND filters
    if [[ -n "$tag" ]] && ! echo "$tags" | grep -qi "$tag"; then continue; fi
    if [[ -n "$scope" ]] && ! echo "$body" | grep -qi "> Scope:.*$scope"; then continue; fi
    if [[ -n "$operation" ]] && ! echo "$body" | grep -qi "> Trigger:.*$operation"; then continue; fi
    matches+=("$i")
  done

  # --recent: take last N (newest = last in file = last in array)
  if [[ $recent -gt 0 ]]; then
    local start=$(( ${#matches[@]} - recent ))
    [[ $start -lt 0 ]] && start=0
    local trimmed=()
    for (( i=start; i<${#matches[@]}; i++ )); do trimmed+=("${matches[$i]}"); done
    # reverse for newest-first
    local rev=()
    for (( i=${#trimmed[@]}-1; i>=0; i-- )); do rev+=("${trimmed[$i]}"); done
    matches=("${rev[@]+"${rev[@]}"}")
  fi

  local first=1
  for idx in "${matches[@]+"${matches[@]}"}"; do
    [[ $first -eq 0 ]] && printf -- '---\n'
    first=0
    local body="${ENTRY_BODIES[$idx]}"
    if [[ $full -eq 1 ]]; then
      printf '%s\n' "$body"
    else
      # header-only: heading + Trigger/Action/Scope lines
      echo "$body" | grep -E '^## |^> (Trigger|Action|Scope):'
    fi
  done
}

# ── inject ───────────────────────────────────────────────────────────────────

cmd_inject() {
  local budget=500 file="$DEFAULT_FILE"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --budget) budget="$2"; shift 2 ;;
      *)        file="$1";   shift ;;
    esac
  done
  [[ ! -f "$file" && "$file" != "-" ]] && exit 0
  parse_entries "$file"
  [[ ${#ENTRY_HEADS[@]} -eq 0 ]] && exit 0

  local output="" used=0 count=0 i
  # newest first = reverse order
  for (( i=${#ENTRY_BODIES[@]}-1; i>=0 && count<5; i-- )); do
    local body="${ENTRY_BODIES[$i]}" head="${ENTRY_HEADS[$i]}"
    local trigger action
    trigger=$(echo "$body" | grep '> Trigger:' | head -1 | sed 's/> Trigger:[[:space:]]*//' || true)
    action=$(echo "$body" | grep '> Action:' | head -1 | sed 's/> Action:[[:space:]]*//' || true)
    [[ -z "$trigger" || -z "$action" ]] && continue

    local tags; tags=$(heading_tags "$head")
    local bullet="- **[${tags:-[untagged]}]**: ${action} (Trigger: ${trigger})"
    local est; est=$(token_est "$output$bullet")
    [[ $est -gt $budget ]] && break
    output+="$bullet"$'\n'
    (( used=est )) || true; (( count++ )) || true
  done

  [[ -z "$output" ]] && exit 0
  printf '## Relevant Lessons\n%s' "$output"
}

# ── count ────────────────────────────────────────────────────────────────────

cmd_count() {
  local file="${1:-$DEFAULT_FILE}"
  if [[ ! -f "$file" && "$file" != "-" ]]; then echo 0; exit 0; fi
  local content; content=$(_read_input "$file")
  [[ -z "$content" ]] && { echo 0; exit 0; }
  local n
  n=$(echo "$content" | grep -cE '^## ([0-9]{4}-[0-9]{2}-[0-9]{2}|SYNTHESIZED)' || true)
  echo "$n"
}

# ── migrate ──────────────────────────────────────────────────────────────────

cmd_migrate() {
  local dry_run=0 file="$DEFAULT_FILE"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) dry_run=1; shift ;;
      *)         file="$1"; shift ;;
    esac
  done
  if [[ ! -f "$file" ]]; then
    echo "ERROR: file not found: $file" >&2; exit 1
  fi

  local tmp; tmp=$(mktemp)
  local migrated=0 skip_next=0
  local prev_was_heading=0 prev_head=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+(SYNTHESIZED[[:space:]]|[0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
      if [[ $prev_was_heading -eq 1 ]]; then
        # Flush previous heading that needed migration (no lines followed yet)
        printf '%s\n' "$prev_head" >> "$tmp"
        printf '> Trigger: [migrated — fill in manually]\n> Action: [migrated — fill in manually]\n> Scope: general\n' >> "$tmp"
        (( migrated++ )) || true
      fi
      prev_was_heading=1; prev_head="$line"; skip_next=0
      continue
    fi

    if [[ $prev_was_heading -eq 1 ]]; then
      # First line after a heading — check if it's already a v2 header
      if [[ "$line" =~ ^'> Trigger:' ]]; then
        # Already v2 — pass through
        printf '%s\n' "$prev_head" >> "$tmp"
        prev_was_heading=0; prev_head=""
      else
        # v1 entry — inject headers
        printf '%s\n' "$prev_head" >> "$tmp"
        printf '> Trigger: [migrated — fill in manually]\n> Action: [migrated — fill in manually]\n> Scope: general\n' >> "$tmp"
        (( migrated++ )) || true
        prev_was_heading=0; prev_head=""
      fi
    fi
    printf '%s\n' "$line" >> "$tmp"
  done < "$file"

  # Handle trailing heading with no following lines
  if [[ $prev_was_heading -eq 1 ]]; then
    printf '%s\n' "$prev_head" >> "$tmp"
    printf '> Trigger: [migrated — fill in manually]\n> Action: [migrated — fill in manually]\n> Scope: general\n' >> "$tmp"
    (( migrated++ )) || true
  fi

  echo "Migrated $migrated entr$([ $migrated -eq 1 ] && echo 'y' || echo 'ies')." >&2

  if [[ $dry_run -eq 1 ]]; then
    diff -u "$file" "$tmp" || true
    rm -f "$tmp"
  else
    mv "$tmp" "$file"
  fi
}

# ── dispatch ─────────────────────────────────────────────────────────────────

[[ $# -eq 0 ]] && usage

subcmd="$1"; shift
case "$subcmd" in
  --help|-h)  usage ;;
  validate)   cmd_validate "$@" ;;
  retrieve)   cmd_retrieve "$@" ;;
  inject)     cmd_inject   "$@" ;;
  count)      cmd_count    "$@" ;;
  migrate)    cmd_migrate  "$@" ;;
  *)          echo "Unknown subcommand: $subcmd" >&2; usage ;;
esac
