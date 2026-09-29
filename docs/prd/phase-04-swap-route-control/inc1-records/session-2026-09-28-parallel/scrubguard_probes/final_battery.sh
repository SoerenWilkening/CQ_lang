#!/bin/bash
# The final measurement battery on ONE guard sha, sequential (load discipline), each step's
# output under results/final_* with the sha and load recorded. usage: final_battery.sh
set -u
W="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
R="$(cd "$(dirname "$0")" && pwd)"
O="$R/results"
cd "$W" || exit 2
SHA=$(shasum -a 256 tools/taintset_scrub_guard.py | cut -c1-16)
stamp() { echo "[$(date +%H:%M:%S)] guard $SHA load $(uptime | sed 's/.*load averages*: //') :: $*"; }
check_sha() {
  now=$(shasum -a 256 tools/taintset_scrub_guard.py | cut -c1-16)
  [ "$now" = "$SHA" ] || { echo "GUARD CHANGED UNDER THE BATTERY ($SHA -> $now) — aborting"; exit 3; }
}
stamp "1 ctest -R scrub"
{ echo "guard $SHA"; ctest --test-dir build -R scrub -j4 --output-on-failure; echo "rc=$?"; } > "$O/final_ctest_scrub.txt" 2>&1
tail -4 "$O/final_ctest_scrub.txt"; check_sha
stamp "2 r3 probes"
bash "$R/run_r3_probes.sh" final; check_sha
stamp "3 fail-closed databases"
python3 -B "$R/fail_closed.py" > "$O/final_fail_closed.txt" 2>&1; echo "rc=$?"; tail -1 "$O/final_fail_closed.txt"; check_sha
stamp "4 source mutants S0 S1 (the changed spelling check) + forced id collision (S3)"
python3 -B -u "$R/source_mutants.py" S0 S1 > "$O/final_source_mutants_S0_S1.txt" 2>&1; grep -E "^S[0-9]|^total" "$O/final_source_mutants_S0_S1.txt"
python3 -B -u "$R/id_collision.py" > "$O/final_id_collision.txt" 2>&1; cut -c1-160 "$O/final_id_collision.txt"; check_sha
stamp "done"
