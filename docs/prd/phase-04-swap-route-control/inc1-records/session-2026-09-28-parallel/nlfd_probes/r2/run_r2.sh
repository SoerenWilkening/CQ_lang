#!/bin/bash
# run_r2.sh <TAG> <LABEL> : round 2 — every probe family (mine + both reviewers'), each against
# its twin, under binary TAG (S | O | OB | path). Verdicts use tools/trace_twin_equiv.py for
# non-identical accepted pairs (TRACE-EQUIV). Output: ../results/r2/<family>_<LABEL>.txt
set -u
H=$(cd "$(dirname "$0")" && pwd); T=$H/../tools; R=$H/../results/r2
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/nlfd
TAG=$1; LBL=$2; mkdir -p "$R"
python3 "$T/gen_cells.py" >/dev/null; python3 "$T/gen_c.py" >/dev/null
python3 "$T/pairs.py" "$TAG" "$H/../src/cells/pairs.txt" > "$R/cells_$LBL.txt"
python3 "$T/pairs.py" "$TAG" "$H/../src/cells/pairs_x.txt" > "$R/x_$LBL.txt"
python3 "$T/pairs.py" "$TAG" "$H/../src/pairs_c.txt" > "$R/c_$LBL.txt"
python3 "$T/pairs.py" "$TAG" "$T/seed.txt" > "$R/seed_$LBL.txt"
python3 "$T/pairs.py" "$TAG" "$H/pairs_mine_r2.txt" > "$R/mine_r2_$LBL.txt"
python3 "$T/pairs.py" "$TAG" "$H/pairs_r1A.txt" --src "$SP/rev/r1A" > "$R/r1A_$LBL.txt"
for q in q1 q2 q4; do
  python3 "$T/pairs.py" "$TAG" "$H/pairs_r1B_$q.txt" --src "$SP/rev/r1B" > "$R/r1B_${q}_$LBL.txt"
done
wc -l "$R"/*_"$LBL".txt | tail -1
