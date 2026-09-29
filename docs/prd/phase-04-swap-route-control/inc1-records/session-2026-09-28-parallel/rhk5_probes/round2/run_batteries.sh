#!/bin/bash
# run_batteries.sh TAG... : run rbattery.py for each binary tag in scratch bin/ and write
# round2/battery_<TAG>.txt. Sequential (load discipline).
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5/bin
R=$(cd "$(dirname "$0")" && pwd)
for t in "$@"; do
  python3 "$R/rbattery.py" "$S/cq-opt.$t" "$t" > "$R/battery_$t.txt" 2>&1
  echo "done $t: $(wc -l < "$R/battery_$t.txt") lines"
done
