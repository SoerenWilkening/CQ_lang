#!/bin/bash
# Round-2 final battery on ONE guard sha, sequential (load discipline); outputs under
# results_r2/final_*; aborts if the guard changes under it. usage: final_battery_r2.sh
set -u
W="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
R="$(cd "$(dirname "$0")" && pwd)"
O="$R/results_r2"
REV="$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r1_scrubguard/probes"
SCR="${SCR:-/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/sg_failopen_final}"
mkdir -p "$O" "$SCR"
cd "$W" || exit 2
SHA=$(shasum -a 256 tools/taintset_scrub_guard.py | cut -c1-16)
stamp() { echo "[$(date +%H:%M:%S)] guard $SHA load $(uptime | sed 's/.*load averages*: //') :: $*"; }
check_sha() {
  now=$(shasum -a 256 tools/taintset_scrub_guard.py | cut -c1-16)
  [ "$now" = "$SHA" ] || { echo "GUARD CHANGED UNDER THE BATTERY ($SHA -> $now) — aborting"; exit 3; }
}
stamp "1 ctest -R scrub -j4"
{ echo "guard $SHA"; ctest --test-dir build -R scrub -j4 --output-on-failure; echo "rc=$?"; } > "$O/final_ctest_scrub.txt" 2>&1
grep -E "Test +#|tests passed|rc=" "$O/final_ctest_scrub.txt"; check_sha
stamp "2 review r1 corpus (gate semantics)"
CQ_GUARD_JOBS=3 python3 -B -u "$REV/guard_fool_r1.py" "$W" > "$O/final_guard_fool_r1.txt" 2>&1
grep -E "^controls bad|^elapsed" "$O/final_guard_fool_r1.txt"; check_sha
stamp "3 r3 corpora"
CQ_GUARD_JOBS=3 bash "$R/run_r3_probes.sh" final_r2; check_sha
stamp "4 fail-closed: databases (main) + reviewer's fail_open.py"
python3 -B "$R/fail_closed.py" > "$O/final_fail_closed.txt" 2>&1; echo "fail_closed rc=$?"; tail -1 "$O/final_fail_closed.txt"
CQ_GUARD_JOBS=3 python3 -B -u "$REV/fail_open.py" "$W" "$SCR" > "$O/final_fail_open.txt" 2>&1
grep -cE "^ok " "$O/final_fail_open.txt" | sed 's/^/fail_open ok rows: /'; grep -E "^BAD" "$O/final_fail_open.txt"; check_sha
stamp "5 composition (read-only)"
CQ_GUARD_JOBS=3 python3 -B -u "$R/composition.py" \
  /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d \
  /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82 \
  > "$O/final_composition.txt" 2>&1
cut -c1-200 "$O/final_composition.txt"; check_sha
stamp "done"
