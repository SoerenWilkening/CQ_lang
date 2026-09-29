#!/bin/bash
# Run the Rule-13 r3 guard-fooling probes (guard_fool_r3.py / guard_fool_r3b.py, bd 8e5r
# r3, imported UNMODIFIED) against THIS worktree's tools/taintset_scrub_guard.py.
# usage: run_r3_probes.sh <tag>   -> results/<tag>_r3.pch.txt, <tag>_r3.nopch.txt, <tag>_r3b.txt
set -u
W="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
P="$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r3_8e5r/probes"
O="$(cd "$(dirname "$0")" && pwd)/results"
TAG="${1:?tag}"
mkdir -p "$O"
cd "$W" || exit 2
echo "worktree $W  guard sha256 $(shasum -a 256 tools/taintset_scrub_guard.py | cut -c1-16)"
for mode in pch nopch; do
  extra=""
  [ "$mode" = nopch ] && extra="--no-pch"
  start=$(date +%s)
  python3 -B "$P/guard_fool_r3.py" "$W" $extra > "$O/${TAG}_r3.$mode.txt" 2>&1
  rc=$?
  echo "guard_fool_r3 ($mode) rc=$rc wall=$(( $(date +%s) - start ))s  -> $(tail -3 "$O/${TAG}_r3.$mode.txt" | head -2 | tr '\n' ' ')"
done
start=$(date +%s)
python3 -B "$P/guard_fool_r3b.py" "$W" > "$O/${TAG}_r3b.txt" 2>&1
rc=$?
echo "guard_fool_r3b rc=$rc wall=$(( $(date +%s) - start ))s  -> $(tail -2 "$O/${TAG}_r3b.txt" | head -1)"
