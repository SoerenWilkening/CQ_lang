#!/bin/bash
# Old (main 9a230646) vs new guard, ALTERNATING so both see the same load. The old guard
# is copied into tools/ (its ROOT comes from its own path) and removed afterwards.
# usage: timing_ab.sh <main|selftest> <rounds> <old-guard-source>
set -u
W="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
R="$(cd "$(dirname "$0")" && pwd)"
WHAT="${1:?main|selftest}"; N="${2:-2}"; OLD_SRC="${3:?old guard}"
OLD="$W/tools/zz_guard_before_9a230646.py"
cp -f "$OLD_SRC" "$OLD"
trap 'rm -f "$OLD"' EXIT
extra=""
[ "$WHAT" = selftest ] && extra="--selftest"
for i in $(seq 1 "$N"); do
  bash "$R/timed_guard.sh" "$R/results/timing_${WHAT}_before_$i.txt" --guard "$OLD" $extra | grep -E "^real|^user|^sys|^rc=|problem|selftest:"
  bash "$R/timed_guard.sh" "$R/results/timing_${WHAT}_after_$i.txt" $extra | grep -E "^real|^user|^sys|^rc=|problem|selftest:"
done
