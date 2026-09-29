#!/bin/bash
# run_ab.sh SUBJECT_TAG : the NULL control (subject twice) FIRST, then ORACLE vs SUBJECT,
# over one persistent stage-1 cache so both runs read the SAME inputs.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5
R=$(cd "$(dirname "$0")/.." && pwd)
TAG=${1:-subject_v2}
export RHK5_S1=$S/s1cache
SUB=$S/bin/cq-opt.$TAG
ORA=$S/bin/cq-opt.oracle
python3 "$R/tools/ab.py" "$SUB" "$SUB" > "$R/results/ab_null_${TAG}_twice.txt" 2>&1
python3 "$R/tools/ab.py" "$ORA" "$SUB" > "$R/results/ab_oracle_vs_${TAG}.txt" 2>&1
grep -E "^\[|TOTAL" "$R/results/ab_null_${TAG}_twice.txt" "$R/results/ab_oracle_vs_${TAG}.txt"
