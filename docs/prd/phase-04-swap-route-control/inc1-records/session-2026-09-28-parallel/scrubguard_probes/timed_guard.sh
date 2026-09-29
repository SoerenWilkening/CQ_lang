#!/bin/bash
# Timed run of a guard (default: this worktree's tools/taintset_scrub_guard.py) with the
# load average before and after; wall, user and sys seconds come from /usr/bin/time -p.
# usage: timed_guard.sh <out-file> [--guard <path>] [guard args...]
set -u
W="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
OUT="${1:?out file}"; shift
G="$W/tools/taintset_scrub_guard.py"
if [ "${1:-}" = "--guard" ]; then G="$2"; shift 2; fi
cd "$W" || exit 2
{
  echo "guard $G sha256 $(shasum -a 256 "$G" | cut -c1-16)  args: $*"
  echo "load before: $(uptime | sed 's/.*load averages*: //')"
  /usr/bin/time -p python3 -B "$G" --compile-commands "$W/build/compile_commands.json" "$@"
  echo "rc=$?"
  echo "load after: $(uptime | sed 's/.*load averages*: //')"
} > "$OUT" 2>&1
tail -6 "$OUT"
