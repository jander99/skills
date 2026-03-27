#!/usr/bin/env bash
set -euo pipefail

print_candidate() {
  local path="$1"
  local kind="$2"
  if [ -e "$path" ]; then
    printf 'FOUND\t%s\t%s\n' "$kind" "$path"
  fi
}

probe_help() {
  local bin="$1"
  if [ ! -x "$bin" ]; then
    return 0
  fi

  local flags=("--help" "-help" "-?" "help")
  local flag
  for flag in "${flags[@]}"; do
    if output=$("$bin" "$flag" 2>&1 | awk 'NR<=20 { print }' || true); then
      if [ -n "${output//[[:space:]]/}" ]; then
        printf 'PROBE\t%s\t%s\n' "$bin" "$flag"
        printf '%s\n' "$output"
        return 0
      fi
    fi
  done
}

echo "== AnyLogic install discovery =="
echo "Platform: $(uname -s)"
echo

echo "-- Candidate application paths --"
print_candidate "/Applications/AnyLogic.app" "mac-app"
print_candidate "/Applications/AnyLogic 8.app" "mac-app"
print_candidate "/Applications/AnyLogic 9.app" "mac-app"
print_candidate "$HOME/Applications/AnyLogic.app" "mac-app"
print_candidate "$HOME/Applications/AnyLogic 8.app" "mac-app"
print_candidate "$HOME/Applications/AnyLogic 9.app" "mac-app"
print_candidate "/Applications/AnyLogic.app/Contents/MacOS/AnyLogic" "mac-binary"
print_candidate "/Applications/AnyLogic 8.app/Contents/MacOS/AnyLogic" "mac-binary"
print_candidate "/Applications/AnyLogic 9.app/Contents/MacOS/AnyLogic" "mac-binary"
print_candidate "$HOME/Applications/AnyLogic.app/Contents/MacOS/AnyLogic" "mac-binary"
print_candidate "$HOME/Applications/AnyLogic 8.app/Contents/MacOS/AnyLogic" "mac-binary"
print_candidate "$HOME/Applications/AnyLogic 9.app/Contents/MacOS/AnyLogic" "mac-binary"
print_candidate "C:/Program Files/AnyLogic 8 Professional/anylogic.exe" "windows-binary"
print_candidate "C:/Program Files/AnyLogic 9 Professional/anylogic.exe" "windows-binary"
print_candidate "/opt/AnyLogic/AnyLogic" "linux-binary"
print_candidate "/usr/local/AnyLogic/AnyLogic" "linux-binary"
echo

echo "-- PATH lookup --"
if command -v AnyLogic >/dev/null 2>&1; then
  command -v AnyLogic
fi
if command -v anylogic >/dev/null 2>&1; then
  command -v anylogic
fi
echo

echo "-- Lightweight help probes --"
probe_help "/Applications/AnyLogic.app/Contents/MacOS/AnyLogic"
probe_help "/Applications/AnyLogic 8.app/Contents/MacOS/AnyLogic"
probe_help "/Applications/AnyLogic 9.app/Contents/MacOS/AnyLogic"
probe_help "$HOME/Applications/AnyLogic.app/Contents/MacOS/AnyLogic"
probe_help "$HOME/Applications/AnyLogic 8.app/Contents/MacOS/AnyLogic"
probe_help "$HOME/Applications/AnyLogic 9.app/Contents/MacOS/AnyLogic"
if command -v AnyLogic >/dev/null 2>&1; then
  probe_help "$(command -v AnyLogic)"
fi
if command -v anylogic >/dev/null 2>&1; then
  probe_help "$(command -v anylogic)"
fi

echo
echo "Done. Treat PROBE output as observed capability, and treat missing output as unverified rather than unsupported."
