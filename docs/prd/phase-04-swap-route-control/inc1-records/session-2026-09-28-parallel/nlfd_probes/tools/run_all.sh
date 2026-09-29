#!/bin/bash
# run_all.sh <TAG> <label> : regenerate the probe sources and run every pair family
# (cells, musttail-vs-tail siblings, C probes, seeds) under binary TAG (S|O|path),
# writing results/<family>_<label>.txt.
set -u
H=$(cd "$(dirname "$0")" && pwd); R=$H/../results
TAG=$1; LBL=$2
P5=$H/../../../session-2026-09-25-parallel-9bhg-xdu2-16/review_r5_vsfp/probes/csrc
for f in mt3.c mt3N.c mt3T.c mt2N.c; do cp -f "$P5/$f" "$H/../src/$f"; done
python3 "$H/gen_cells.py" >/dev/null
python3 "$H/gen_c.py" >/dev/null
python3 "$H/pairs.py" "$TAG" "$H/../src/cells/pairs.txt" > "$R/cells_$LBL.txt"
python3 "$H/pairs.py" "$TAG" "$H/../src/cells/pairs_mt_vs_tc.txt" --no-build > "$R/mtvstc_$LBL.txt"
python3 "$H/pairs.py" "$TAG" "$H/../src/pairs_c.txt" > "$R/c_$LBL.txt"
python3 "$H/pairs.py" "$TAG" "$H/seed.txt" > "$R/seed_$LBL.txt"
wc -l "$R/cells_$LBL.txt" "$R/mtvstc_$LBL.txt" "$R/c_$LBL.txt" "$R/seed_$LBL.txt"
