#!/bin/bash
# check.sh [N]: run check1.sh on up to N (default 800) TUs whose bitcode has no result yet, or a result
# older than the object, in one heavy.sh run (xargs -P 8). Resumable: rerun until it reports 0 pending.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
N=${1:-800}
mkdir -p "$CHK/res"
[ -f "$PLUGIN" ] || { echo "check: no plugin at $PLUGIN (build first)" >&2; exit 1; }
"$HEAVY" "$here/control.sh" || exit 1
list=$CHK/pending.txt
python3 "$here/tus.py" | awk -F'\t' '$4=="bitcode"{print $1}' | while read -r o; do
  r="$CHK/res/$(printf '%s' "$o" | tr '/' '%')"
  [ -f "$r" ] && [ "$r" -nt "$KOUT/$o" ] || echo "$o"
done > "$list"
total=$(wc -l < "$list" | tr -d ' ')
echo "check: $total pending, running $(( total < N ? total : N ))"
[ "$total" -eq 0 ] && exit 0
"$HEAVY" -t 600 sh -c 'head -n "$1" "$2" | xargs -P 8 -n 1 "$3"' check "$N" "$list" "$here/check1.sh"
