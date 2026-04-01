#!/usr/bin/env bash
# retro-lessons.sh — Validate/retrieve/inject LESSONS.md (v2 schema).
# Supports dual-location: global (~/.agents/lessons/) and project-local (<repo>/.agents/lessons/).
# Project-local lessons are opt-in: only used if .agents/lessons/ directory already exists.
# Worktree-aware: always resolves to the MAIN repo root, not the active linked-worktree root.
# Pure bash + standard unix tools only. No jq/python/node/curl.
# Supports dual-location: global (~/.agents/lessons/) and project-local (<repo>/.agents/lessons/).
# Pure bash + standard unix tools only. No jq/python/node/curl.
set -euo pipefail

GLOBAL_FILE="${HOME}/.agents/lessons/LESSONS.md"
DEFAULT_FILE="$GLOBAL_FILE"

# ── path detection ────────────────────────────────────────────────────────────

# Find the MAIN git repository root from any worktree.
# 'git worktree list' always lists the main worktree first.
# Returns empty string if not in a git repo.
_main_repo_root() {
  git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2; exit}' || true
}

# Return the project-local lessons file path, or empty if:
#   a) not in a git repo, OR
#   b) .agents/lessons/ directory does not exist (opt-in — user must create it).
_local_file() {
  local root
  root=$(_main_repo_root)
  if [[ -n "$root" ]]; then
    local lessons_dir="${root}/.agents/lessons"
    # Only return a path if the directory already exists.
    # Users enable project-local lessons by creating: mkdir -p <repo>/.agents/lessons
    if [[ -d "$lessons_dir" ]]; then
      echo "${lessons_dir}/LESSONS.md"
    fi
  fi
}

# Return the absolute path of a file (no realpath dependency).
_abs_path() {
  local path="$1"
  if [[ "$path" == /* ]]; then
    echo "$path"
  else
    echo "$(pwd)/$path"
  fi
}

# Find the git repo root for a given file path (not the CWD-based root).
_git_root_for_file() {
  local file="$1"
  local dir
  dir=$(dirname "$(_abs_path "$file")")
  git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true
}
usage() {
  cat <<'EOF'
Usage: retro-lessons.sh <subcommand> [options] [FILE]

Default FILE: ~/.agents/lessons/LESSONS.md  (use - for stdin)

Location flags (applicable to retrieve, inject, count, validate):
  --global          Use ~/.agents/lessons/LESSONS.md (default)
  --local           Use <main-repo-root>/.agents/lessons/LESSONS.md (opt-in: dir must exist)
  --both            Operate across both files (inject/retrieve merge results)

Subcommands:
  validate [FILE]            Validate all v2 entry blocks; exit 1 if any bad
  retrieve [OPTIONS] [FILE]  Filter and print matching entries
    --tag <tag>              Match entries whose heading contains <tag> (after |)
    --scope <pattern>        Match entries where > Scope: contains <pattern>
    --operation <op>         Match entries where > Scope: contains <op>
    --recent <N>             Return last N entries (newest first)
    --full                   Include full body (Start/Stop/Continue fields)
  inject [--budget N] [FILE] Print top-5 lessons formatted for prompt context
  count [FILE]               Print number of v2 entries
  migrate [--dry-run] [FILE]        Upgrade v1 entries to v2 by injecting placeholder headers
  migrate-schema [--dry-run] [FILE] Rename Sailboat fields to Start/Stop/Continue in-place
  paths                             Show resolved global and local lesson file paths
  checkpoint [--global|--local|FILE]  Commit dirty LESSONS.md before writing (concurrent-write safety)
  finalize   [--global|--local|FILE] [--date YYYY-MM-DD]  Commit LESSONS.md after writing new entry
  --help                     Show this help and exit
EOF
  exit 0
}

# ── helpers ──────────────────────────────────────────────────────────────────

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
  # Guard: if no | present, heading has no tags
  if [[ "$head" != *"|"* ]]; then
    echo "[untagged]"
    return
  fi
  local tags_part="${head##*|}"
  echo "$tags_part" | tr -s ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Estimate token count: words * 1.3, truncated
token_est() {
  local text="$1"
  local words
  words=$(echo "$text" | wc -w)
  echo $(( (words * 13) / 10 ))
}

# ── paths subcommand ──────────────────────────────────────────────────────────

cmd_paths() {
  local local_file
  local_file=$(_local_file)
  echo "Global : $GLOBAL_FILE"
  if [[ -n "$local_file" ]]; then
    echo "Local  : $local_file"
    if [[ "$local_file" == "$GLOBAL_FILE" ]]; then
      echo "Note   : local and global paths are the same (git root = home?)"
    fi
  else
    echo "Local  : (not in a git repository)"
  fi
}

# ── validate ─────────────────────────────────────────────────────────────────

cmd_validate() {
  local file="" location="global"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --global)  location="global"; shift ;;
      --local)   location="local";  shift ;;
      --both)    location="both";   shift ;;
      *)         file="$1";        shift ;;
    esac
  done

  # Helper: validate a single file
  _validate_single() {
    local f="$1"
    if [[ ! -f "$f" && "$f" != "-" ]]; then
      echo "OK: $f not found (no entries — skipping)" >&2
      return 0
    fi
    local content; content=$(_read_input "$f")
    [[ -z "$content" ]] && return 0
    parse_entries "$f"
    local errors=0 i
    for (( i=0; i<${#ENTRY_BODIES[@]}; i++ )); do
      local body="${ENTRY_BODIES[$i]}" head="${ENTRY_HEADS[$i]}" ln="${ENTRY_LINES[$i]}"
      local is_synth=0
      [[ "$head" =~ ^##[[:space:]]+SYNTHESIZED ]] && is_synth=1
      if ! echo "$body" | grep -q '> Trigger:'; then
        echo "ERROR: $f line $ln: missing '> Trigger:'" >&2; (( errors++ )) || true
      fi
      if ! echo "$body" | grep -q '> Action:'; then
        echo "ERROR: $f line $ln: missing '> Action:'" >&2; (( errors++ )) || true
      fi
      if ! echo "$body" | grep -q '> Scope:'; then
        echo "ERROR: $f line $ln: missing '> Scope:'" >&2; (( errors++ )) || true
      fi
      if [[ $is_synth -eq 0 ]]; then
        # Accept Start/Stop/Continue (current schema) or Sailboat (legacy — warn to migrate)
        local has_ssc=0 has_sailboat=0
        echo "$body" | grep -qE '\*\*Start |\*\*Stop |\*\*Continue ' && has_ssc=1
        echo "$body" | grep -qE '\*\*Wind |\*\*Anchor ' && has_sailboat=1
        if [[ $has_ssc -eq 0 && $has_sailboat -eq 0 ]]; then
          echo "WARN: $f line $ln: missing body fields (expected **Start**, **Stop**, **Continue**)" >&2
        elif [[ $has_sailboat -eq 1 && $has_ssc -eq 0 ]]; then
          echo "WARN: $f line $ln: uses legacy Sailboat format — run: retro-lessons.sh migrate-schema $f" >&2
        fi
      else
        local synth_body_line
        synth_body_line=$(echo "$body" | grep -v '^> ' | grep -v '^## ' | grep -v '^[[:space:]]*$' | head -1 || true)
        if [[ -z "$synth_body_line" ]]; then
          echo "WARN: SYNTHESIZED entry has no body content: $head" >&2
        fi
      fi
      if [[ "$(heading_tags "$head")" == "[untagged]" ]]; then
        echo "  WARN: $f line $ln: heading has no tags: $head"
      fi
    done
    return $errors
  }

  local total_errors=0
  if [[ -n "$file" ]]; then
    _validate_single "$file" || (( total_errors++ )) || true
  else
    case "$location" in
      local)
        local lf; lf=$(_local_file)
        [[ -z "$lf" ]] && { echo "WARN: not in a git repository; falling back to global" >&2; lf="$GLOBAL_FILE"; }
        _validate_single "$lf" || (( total_errors++ )) || true
        ;;
      both)
        local lf; lf=$(_local_file)
        _validate_single "$GLOBAL_FILE" || (( total_errors++ )) || true
        if [[ -n "$lf" && "$lf" != "$GLOBAL_FILE" ]]; then
          _validate_single "$lf" || (( total_errors++ )) || true
        fi
        ;;
      *) # global
        _validate_single "$GLOBAL_FILE" || (( total_errors++ )) || true
        ;;
    esac
  fi
  [[ $total_errors -gt 0 ]] && exit 1 || exit 0
}

# ── retrieve ─────────────────────────────────────────────────────────────────

# Core retrieve logic for a single file. Prints matching entries.
_retrieve_from_file() {
  local tag="$1" scope="$2" operation="$3" recent="$4" full="$5" file="$6"

  [[ ! -f "$file" && "$file" != "-" ]] && return
  parse_entries "$file"
  [[ ${#ENTRY_HEADS[@]} -eq 0 ]] && return

  local matches=() i
  for (( i=0; i<${#ENTRY_BODIES[@]}; i++ )); do
    local body="${ENTRY_BODIES[$i]}" head="${ENTRY_HEADS[$i]}"
    local tags; tags=$(heading_tags "$head")

    if [[ -n "$tag" ]] && ! echo "$tags" | grep -qi "$tag"; then continue; fi
    if [[ -n "$scope" ]] && ! echo "$body" | grep -qi "> Scope:.*$scope"; then continue; fi
    if [[ -n "$operation" ]] && ! echo "$body" | grep -qi "> Scope:.*$operation"; then continue; fi
    matches+=("$i")
  done

  if [[ ${#matches[@]} -eq 0 && ( -n "$tag" || -n "$scope" || -n "$operation" ) ]]; then
    local fallback=()
    for (( i=0; i<${#ENTRY_BODIES[@]}; i++ )); do
      local body="${ENTRY_BODIES[$i]}"
      if echo "$body" | grep -qi "> Scope:.*general"; then
        fallback+=("$i")
      fi
    done
    if [[ ${#fallback[@]} -eq 0 ]]; then
      for (( i=0; i<${#ENTRY_BODIES[@]}; i++ )); do fallback+=("$i"); done
    fi
    local fb_start=$(( ${#fallback[@]} - 3 ))
    [[ $fb_start -lt 0 ]] && fb_start=0
    matches=()
    for (( i=fb_start; i<${#fallback[@]}; i++ )); do matches+=("${fallback[$i]}"); done
  fi

  if [[ $recent -gt 0 ]]; then
    local start=$(( ${#matches[@]} - recent ))
    [[ $start -lt 0 ]] && start=0
    local trimmed=()
    for (( i=start; i<${#matches[@]}; i++ )); do trimmed+=("${matches[$i]}"); done
    local rev=()
    for (( i=${#trimmed[@]}-1; i>=0; i-- )); do rev+=("${trimmed[$i]}"); done
    matches=("${rev[@]+"${rev[@]}"}")  
  else
    local rev=()
    for (( i=${#matches[@]}-1; i>=0; i-- )); do rev+=("${matches[$i]}"); done
    matches=("${rev[@]+"${rev[@]}"}")  
  fi

  local capped=()
  for (( i=0; i<${#matches[@]} && i<5; i++ )); do capped+=("${matches[$i]}"); done
  matches=("${capped[@]+"${capped[@]}"}")  

  local first=1
  for idx in "${matches[@]+"${matches[@]}"}"; do
    [[ $first -eq 0 ]] && printf -- '---\n'
    first=0
    local body="${ENTRY_BODIES[$idx]}"
    if [[ $full -eq 1 ]]; then
      printf '%s\n' "$body"
    else
      echo "$body" | grep -E '^## |^> (Trigger|Action|Scope):' || true
    fi
  done
}

cmd_retrieve() {
  local tag="" scope="" operation="" recent=0 full=0 file="" location="global"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tag)      [[ $# -lt 2 ]] && { echo "ERROR: --tag requires a value" >&2; exit 1; }; tag="$2";       shift 2 ;;
      --scope)    [[ $# -lt 2 ]] && { echo "ERROR: --scope requires a value" >&2; exit 1; }; scope="$2";     shift 2 ;;
      --operation) [[ $# -lt 2 ]] && { echo "ERROR: --operation requires a value" >&2; exit 1; }; operation="$2"; shift 2 ;;
      --recent)   [[ $# -lt 2 ]] && { echo "ERROR: --recent requires a value" >&2; exit 1; }; recent="$2";    shift 2 ;;
      --full)     full=1;           shift ;;
      --global)   location="global"; shift ;;
      --local)    location="local";  shift ;;
      --both)     location="both";   shift ;;
      -*)         echo "WARN: unknown option $1" >&2; shift ;;
      *)          file="$1";        shift ;;
    esac
  done

  # Resolve file(s) based on location flag (only when no explicit file given)
  if [[ -n "$file" ]]; then
    _retrieve_from_file "$tag" "$scope" "$operation" "$recent" "$full" "$file"
  else
    case "$location" in
      local)
        local lf; lf=$(_local_file)
        [[ -z "$lf" ]] && { echo "WARN: not in a git repository; falling back to global" >&2; lf="$GLOBAL_FILE"; }
        _retrieve_from_file "$tag" "$scope" "$operation" "$recent" "$full" "$lf"
        ;;
      both)
        local lf; lf=$(_local_file)
        # Print from global first (labeled), then local (labeled, if different)
        _retrieve_from_file_labeled() {
          local _src_label="$1" _tag="$2" _scope="$3" _op="$4" _recent="$5" _full="$6" _file="$7"
          local _buf
          # Capture output of inner retrieve, then prefix each heading line with source label
          _buf=$(_retrieve_from_file "$_tag" "$_scope" "$_op" "$_recent" "$_full" "$_file" 2>/dev/null || true)
          if [[ -n "$_buf" ]]; then
            # Annotate each ## heading line with the source label
            echo "$_buf" | sed "s|^\(## \)|\1[${_src_label}] |"
          fi
        }
        _retrieve_from_file_labeled "global" "$tag" "$scope" "$operation" "$recent" "$full" "$GLOBAL_FILE"
        if [[ -n "$lf" && "$lf" != "$GLOBAL_FILE" ]]; then
          _retrieve_from_file_labeled "project" "$tag" "$scope" "$operation" "$recent" "$full" "$lf"
        fi
        ;;
      *) # global (default)
        _retrieve_from_file "$tag" "$scope" "$operation" "$recent" "$full" "$GLOBAL_FILE"
        ;;
    esac
  fi
}

# ── inject ───────────────────────────────────────────────────────────────────

# Core inject logic for a single file. Appends bullets to INJECT_OUTPUT.
_inject_from_file() {
  local budget="$1" file="$2" label="$3" max_bullets="${4:-5}"
  local output="" count=0 i

  [[ ! -f "$file" && "$file" != "-" ]] && return
  parse_entries "$file"
  [[ ${#ENTRY_HEADS[@]} -eq 0 ]] && return

  # newest first = reverse order
  for (( i=${#ENTRY_BODIES[@]}-1; i>=0 && count<max_bullets; i-- )); do
    local body="${ENTRY_BODIES[$i]}" head="${ENTRY_HEADS[$i]}"
    local trigger action
    trigger=$(echo "$body" | grep '> Trigger:' | head -1 | sed 's/> Trigger:[[:space:]]*//' || true)
    action=$(echo "$body" | grep '> Action:' | head -1 | sed 's/> Action:[[:space:]]*//' || true)
    [[ -z "$trigger" || -z "$action" ]] && continue

    local all_tags first_tag
    all_tags=$(heading_tags "$head")
    first_tag=$(echo "$all_tags" | awk '{print $1}')
    [[ -z "$first_tag" ]] && first_tag="untagged"

    if [[ ${#action} -gt 80 ]]; then
      action="${action:0:80}…"
    fi
    trigger="${trigger:0:80}"

    local bullet
    if [[ -n "$label" ]]; then
      bullet="- **[${first_tag}]** *(${label})*: ${action} (Trigger: ${trigger})"
    else
      bullet="- **[${first_tag}]**: ${action} (Trigger: ${trigger})"
    fi
    # Check per-source bullet cap (uses local count only, not INJECT_OUTPUT)
    if [[ $count -ge $max_bullets ]]; then break; fi

    local est; est=$(token_est "$INJECT_OUTPUT$output$bullet")
    [[ $est -gt $budget ]] && break
    output+="$bullet"$'\n'
    (( count++ )) || true
  done

  INJECT_OUTPUT+="$output"
}
cmd_inject() {
  local budget=500 file="" tag_arg="general" location="global"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --budget)  budget="$2";       shift 2 ;;
      --tag)     tag_arg="$2";      shift 2 ;;
      --global)  location="global"; shift ;;
      --local)   location="local";  shift ;;
      --both)    location="both";   shift ;;
      *)         file="$1";        shift ;;
    esac
  done

  INJECT_OUTPUT=""

  if [[ -n "$file" ]]; then
    _inject_from_file "$budget" "$file" ""
  else
    case "$location" in
      local)
        local lf; lf=$(_local_file)
        [[ -z "$lf" ]] && { echo "WARN: not in a git repository; falling back to global" >&2; lf="$GLOBAL_FILE"; }
        _inject_from_file "$budget" "$lf" ""
        ;;
      both)
        local lf; lf=$(_local_file)
        if [[ -n "$lf" && "$lf" != "$GLOBAL_FILE" ]]; then
          # True merged top-5: collect all bullets from both sources, newest-first, cap at 5
          # Build temporary arrays: one pass global, one pass local
          local _g_output="" _l_output=""
          _inject_from_file "$budget" "$GLOBAL_FILE" "global" 99
          _g_output="$INJECT_OUTPUT"
          INJECT_OUTPUT=""
          _inject_from_file "$budget" "$lf" "project" 99
          _l_output="$INJECT_OUTPUT"
          INJECT_OUTPUT=""
          # Interleave: take bullets alternately from each source to ensure both surface,
          # then cap the merged result at 5 bullets total.
          local _merged="" _count=0
          local _g_lines _l_lines _gi=0 _li=0
          mapfile -t _g_lines <<< "$_g_output"
          mapfile -t _l_lines <<< "$_l_output"
          # Remove trailing empty element that mapfile adds
          [[ ${#_g_lines[@]} -gt 0 && -z "${_g_lines[-1]}" ]] && unset '_g_lines[-1]'
          [[ ${#_l_lines[@]} -gt 0 && -z "${_l_lines[-1]}" ]] && unset '_l_lines[-1]'
          while [[ $_count -lt 5 && ( $_gi -lt ${#_g_lines[@]} || $_li -lt ${#_l_lines[@]} ) ]]; do
            if [[ $_gi -lt ${#_g_lines[@]} && -n "${_g_lines[$_gi]}" ]]; then
              _merged+="${_g_lines[$_gi]}"$'\n'
              (( _gi++ )) || true
              (( _count++ )) || true
            fi
            if [[ $_count -lt 5 && $_li -lt ${#_l_lines[@]} && -n "${_l_lines[$_li]}" ]]; then
              _merged+="${_l_lines[$_li]}"$'\n'
              (( _li++ )) || true
              (( _count++ )) || true
            fi
          done
          INJECT_OUTPUT="$_merged"
        else
          _inject_from_file "$budget" "$GLOBAL_FILE" "" 5
        fi
        ;;
      *) # global (default)
        _inject_from_file "$budget" "$GLOBAL_FILE" ""
        ;;
    esac
  fi

  [[ -z "$INJECT_OUTPUT" ]] && exit 0
  printf '## Relevant Lessons\n'
  printf '<!-- lessons-injected: %s %s -->\n\n' "${tag_arg}" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s' "$INJECT_OUTPUT"
}

# ── count ────────────────────────────────────────────────────────────────────

cmd_count() {
  local file="" location="global"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --global)  location="global"; shift ;;
      --local)   location="local";  shift ;;
      --both)    location="both";   shift ;;  # prints global+local counts
      *)         file="$1";        shift ;;
    esac
  done
  _count_single() {
    local f="$1"
    if [[ ! -f "$f" && "$f" != "-" ]]; then echo 0; return; fi
    local content; content=$(_read_input "$f")
    [[ -z "$content" ]] && { echo 0; return; }
    echo "$content" | grep -cE '^## ([0-9]{4}-[0-9]{2}-[0-9]{2}|SYNTHESIZED)' || true
  }
  if [[ -n "$file" ]]; then
    _count_single "$file"
  else
    case "$location" in
      local)
        local lf; lf=$(_local_file)
        [[ -z "$lf" ]] && { echo "WARN: not in a git repository; falling back to global" >&2; lf="$GLOBAL_FILE"; }
        _count_single "$lf"
        ;;
      both)
        local lf; lf=$(_local_file)
        local g_count; g_count=$(_count_single "$GLOBAL_FILE")
        printf 'global: %s\n' "$g_count"
        if [[ -n "$lf" && "$lf" != "$GLOBAL_FILE" ]]; then
          local l_count; l_count=$(_count_single "$lf")
          printf 'local:  %s\n' "$l_count"
        else
          printf 'local:  (same as global)\n'
        fi
        ;;
      *) # global
        _count_single "$GLOBAL_FILE"
        ;;
    esac
  fi
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
  local migrated=0
  local prev_was_heading=0 prev_head=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+(SYNTHESIZED[[:space:]]|[0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
      if [[ $prev_was_heading -eq 1 ]]; then
        # Flush previous heading that needed migration (no lines followed yet)
        printf '%s\n' "$prev_head" >> "$tmp"
        printf '> Trigger: [migrated — fill in manually]\n> Action: [migrated — fill in manually]\n> Scope: general\n' >> "$tmp"
        (( migrated++ )) || true
      fi
      prev_was_heading=1; prev_head="$line"
      continue
    fi

    if [[ $prev_was_heading -eq 1 ]]; then
      # First line after a heading — check if it's already a v2 header
      if [[ "$line" == "> Trigger:"* ]]; then
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

  if [[ $dry_run -eq 1 ]]; then
    echo "Would migrate $migrated entr$([ $migrated -eq 1 ] && echo 'y' || echo 'ies')." >&2
    diff -u "$file" "$tmp" || true
    rm -f "$tmp"
  else
    echo "Migrated $migrated entr$([ $migrated -eq 1 ] && echo 'y' || echo 'ies')." >&2
    mv "$tmp" "$file"
  fi
}

# ── migrate-schema ─────────────────────────────────────────────────────────────────────────────────
# Mechanically rename Sailboat body fields to Start/Stop/Continue in-place.
# Wind → Continue, Anchor → Stop, Rocks → Stop (risks), Next → Start.
# LLM review recommended afterward to merge the two Stop blocks into one.

cmd_migrate_schema() {
  local dry_run=0 file="$DEFAULT_FILE"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) dry_run=1; shift ;;
      *) file="$1"; shift ;;
    esac
  done
  if [[ ! -f "$file" ]]; then
    echo "ERROR: file not found: $file" >&2; exit 1
  fi

  local tmp; tmp=$(mktemp)
  # Store emoji in variables first; assign with printf to avoid shell-quoting issues.
  # Renames: Wind→Continue, Anchor→Stop, Rocks→Stop(risks), Next→Start
  local F_WIND F_ANCHOR F_ROCKS F_NEXT T_CONTINUE T_STOP T_STOP_R T_START
  F_WIND=$(printf '**Wind \U1F32C\UFE0F:**')
  F_ANCHOR=$(printf '**Anchor \u2693:**')
  F_ROCKS=$(printf '**Rocks \U1FAA8:**')
  F_NEXT=$(printf '**Next \U1F9ED:**')
  T_CONTINUE=$(printf '**Continue \u2705:**')
  T_STOP=$(printf '**Stop \U1F6D1:**')
  T_STOP_R=$(printf '**Stop \U1F6D1 (risks):**')
  T_START=$(printf '**Start \U1F680:**')

  # Apply renames using awk (handles multi-byte chars reliably without sed locale issues)
  awk -v fw="$F_WIND" -v fa="$F_ANCHOR" -v fr="$F_ROCKS" -v fn="$F_NEXT" \
      -v tc="$T_CONTINUE" -v ts="$T_STOP" -v tsr="$T_STOP_R" -v tst="$T_START" '
  {
    gsub(fw, tc)
    gsub(fa, ts)
    gsub(fr, tsr)
    gsub(fn, tst)
    print
  }' "$file" > "$tmp"

  if [[ $dry_run -eq 1 ]]; then
    echo "Schema migration preview (Sailboat → Start/Stop/Continue):" >&2
    diff -u "$file" "$tmp" || true
    rm -f "$tmp"
  else
    mv "$tmp" "$file"
    echo "Schema migrated: Sailboat → Start/Stop/Continue in $file" >&2
    echo "NOTE: Two **Stop** blocks may exist per entry where Anchor+Rocks both appeared." >&2
    echo "      Review and merge them into a single **Stop** block." >&2
  fi
}

# ── checkpoint ───────────────────────────────────────────────────────────────
# Before writing a new retro entry: commit any pre-existing uncommitted changes
# to LESSONS.md so a concurrent worktree's write is not silently overwritten.

cmd_checkpoint() {
  local file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --global) file="$GLOBAL_FILE"; shift ;;
      --local)
        local lf; lf=$(_local_file)
        [[ -z "$lf" ]] && { echo "WARN: not in a git repo; falling back to global" >&2; lf="$GLOBAL_FILE"; }
        file="$lf"; shift ;;
      *) file="$1"; shift ;;
    esac
  done
  [[ -z "$file" ]] && file="$GLOBAL_FILE"

  local repo_root
  repo_root=$(_git_root_for_file "$file")
  if [[ -z "$repo_root" ]]; then
    echo "INFO: $file is not tracked by git; no checkpoint needed" >&2
    exit 0
  fi

  local abs_file rel_path
  abs_file=$(_abs_path "$file")
  rel_path="${abs_file#${repo_root}/}"

  local dirty wt_name
  dirty=$(git -C "$repo_root" status --porcelain -- "$rel_path" 2>/dev/null || true)
  wt_name=$(basename "$PWD")
  if [[ -n "$dirty" ]]; then
    git -C "$repo_root" add -- "$rel_path"
    if ! git -C "$repo_root" diff --cached --quiet -- "$rel_path" 2>/dev/null; then
      git -C "$repo_root" commit -m "retro: checkpoint LESSONS.md before new entry [$wt_name]"
      echo "Checkpointed: committed pre-existing uncommitted changes in $file" >&2
    else
      echo "INFO: $file staged but no diff to commit; skipping" >&2
    fi
  else
    echo "No uncommitted changes in $file; no checkpoint needed" >&2
  fi
}

# ── finalize ─────────────────────────────────────────────────────────────────
# After writing a new retro entry: stage and commit LESSONS.md immediately
# so concurrent worktrees see the new entry on their next checkpoint call.

cmd_finalize() {
  local file="" date_str
  date_str=$(date +%Y-%m-%d)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --global) file="$GLOBAL_FILE"; shift ;;
      --local)
        local lf; lf=$(_local_file)
        [[ -z "$lf" ]] && { echo "WARN: not in a git repo; falling back to global" >&2; lf="$GLOBAL_FILE"; }
        file="$lf"; shift ;;
      --date) date_str="$2"; shift 2 ;;
      *) file="$1"; shift ;;
    esac
  done
  [[ -z "$file" ]] && file="$GLOBAL_FILE"

  local repo_root
  repo_root=$(_git_root_for_file "$file")
  if [[ -z "$repo_root" ]]; then
    echo "INFO: $file is not tracked by git; skipping finalize" >&2
    exit 0
  fi

  local abs_file rel_path wt_name
  abs_file=$(_abs_path "$file")
  rel_path="${abs_file#${repo_root}/}"
  wt_name=$(basename "$PWD")

  git -C "$repo_root" add -- "$rel_path"
  if ! git -C "$repo_root" diff --cached --quiet -- "$rel_path" 2>/dev/null; then
    git -C "$repo_root" commit -m "retro: add entry $date_str [$wt_name]"
    echo "Finalized: committed new retro entry in $file" >&2
  else
    echo "INFO: no staged changes in $file; nothing to finalize" >&2
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
  migrate)         cmd_migrate  "$@" ;;
  migrate-schema)  cmd_migrate_schema "$@" ;;
  paths)           cmd_paths    "$@" ;;
  checkpoint)      cmd_checkpoint "$@" ;;
  finalize)        cmd_finalize   "$@" ;;
  *)          echo "Unknown subcommand: $subcmd" >&2; usage ;;
esac
