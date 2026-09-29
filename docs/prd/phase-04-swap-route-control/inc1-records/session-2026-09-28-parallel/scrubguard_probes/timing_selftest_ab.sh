#!/bin/bash
# Self-test cost, old vs new, back to back: the OLD guard's single `--selftest` process
# (main 9a230646) against the NEW ctest shape (`ctest -R taintset-scrub-guard -j4`: the gate
# run + the three `--shard K/3 --jobs 2` entries). /usr/bin/time -p (children included).
# usage: timing_selftest_ab.sh <old-guard-source>
set -u
W="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
R="$(cd "$(dirname "$0")" && pwd)"
OLD="$W/tools/zz_guard_before_9a230646.py"
cp -f "${1:?old guard}" "$OLD"
trap 'rm -f "$OLD"' EXIT
cd "$W" || exit 2
bash "$R/timed_guard.sh" "$R/results_r2/timing_selftest_before_1.txt" --guard "$OLD" --selftest \
  | grep -E "^real|^user|^sys|^rc=|selftest:"
O="$R/results_r2/timing_selftest_after_1.txt"
{
  echo "guard $(shasum -a 256 tools/taintset_scrub_guard.py | cut -c1-16)  ctest -R taintset-scrub-guard -j4"
  echo "load before: $(uptime | sed 's/.*load averages*: //')"
  /usr/bin/time -p ctest --test-dir build -R taintset-scrub-guard -j4 --output-on-failure
  echo "rc=$?"
  echo "load after: $(uptime | sed 's/.*load averages*: //')"
} > "$O" 2>&1
grep -E "Test +#|tests passed|^real|^user|^sys|^rc=" "$O"
