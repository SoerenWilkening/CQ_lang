#!/bin/bash
# Round-3 final battery on ONE guard sha, sequential (load discipline); outputs under
# results_r3/final_*; aborts if the guard changes under it. usage: final_battery_r3.sh
set -u
W="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
R="$(cd "$(dirname "$0")" && pwd)"
O="$R/results_r3"
REV1="$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r1_scrubguard/probes"
REV2="$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r2_scrubguard/probes"
SCR="${SCR:-/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/sg_failopen_r3}"
mkdir -p "$O" "$SCR"
cd "$W" || exit 2
export CQ_GUARD_JOBS=3
SHA=$(shasum -a 256 tools/taintset_scrub_guard.py | cut -c1-16)
stamp() { echo "[$(date +%H:%M:%S)] guard $SHA load $(uptime | sed 's/.*load averages*: //') :: $*"; }
check_sha() {
  now=$(shasum -a 256 tools/taintset_scrub_guard.py | cut -c1-16)
  [ "$now" = "$SHA" ] || { echo "GUARD CHANGED UNDER THE BATTERY ($SHA -> $now) — aborting"; exit 3; }
}
stamp "1 ctest -R scrub -j4"
{ echo "guard $SHA"; echo "load before: $(uptime | sed 's/.*load averages*: //')"
  /usr/bin/time -p ctest --test-dir build -R scrub -j4 --output-on-failure; echo "rc=$?"
  echo "load after: $(uptime | sed 's/.*load averages*: //')"; } > "$O/final_ctest_scrub.txt" 2>&1
grep -E "Test +#|tests passed|^real|^user|^rc=" "$O/final_ctest_scrub.txt"; check_sha
stamp "2 review r2 corpus (gate semantics)"
python3 -B -u "$REV2/guard_fool_r2.py" "$W" > "$O/final_guard_fool_r2.txt" 2>&1
grep -E "^controls bad|^elapsed" "$O/final_guard_fool_r2.txt"; check_sha
stamp "3 review r1 corpus (gate semantics)"
python3 -B -u "$REV1/guard_fool_r1.py" "$W" > "$O/final_guard_fool_r1.txt" 2>&1
grep -E "^controls bad|^elapsed" "$O/final_guard_fool_r1.txt"; check_sha
stamp "4 r3 corpora"
bash "$R/run_r3_probes.sh" final_r3; check_sha
stamp "5 fail-closed: databases (main), reviewer r1 fail_open.py, reviewer r2 fail_open_r2.py"
python3 -B "$R/fail_closed.py" > "$O/final_fail_closed.txt" 2>&1; echo "fail_closed rc=$?"; tail -1 "$O/final_fail_closed.txt"
python3 -B -u "$REV1/fail_open.py" "$W" "$SCR" > "$O/final_fail_open_r1.txt" 2>&1
grep -cE "^ok " "$O/final_fail_open_r1.txt" | sed 's/^/fail_open r1 ok rows: /'; grep -E "^BAD" "$O/final_fail_open_r1.txt"
python3 -B -u "$REV2/fail_open_r2.py" "$W" "$SCR" > "$O/final_fail_open_r2.txt" 2>&1
grep -cE "^ok " "$O/final_fail_open_r2.txt" | sed 's/^/fail_open r2 ok rows: /'; grep -E "^BAD" "$O/final_fail_open_r2.txt"; check_sha
stamp "6 composition (read-only)"
python3 -B -u "$R/composition.py" \
  /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d \
  /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82 \
  > "$O/final_composition.txt" 2>&1
cut -c1-200 "$O/final_composition.txt"; check_sha
stamp "7 source mutants (round 3: P0 null + P1..P8)"
python3 -B -u "$R/source_mutants_r3.py" > "$O/final_source_mutants_r3.txt" 2>&1
grep -E "^P[0-9]|^total" "$O/final_source_mutants_r3.txt"; check_sha
stamp "done"
