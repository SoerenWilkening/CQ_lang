#!/bin/bash
# r2 reviewer: re-run of repro_F1_r2 (a),(b) in the PRIVATE worktree + private cache.
. "$(dirname "$0")/env.sh"
cd "$MY" || exit 2
P() { python3 "$SP/rev_r2_probes/plant.py" "$@" || exit 3; }
echo "== (a) C18 tripwire: lib TUs get -include CQ.h"
P tests/e2e/run_slice_multi.sh 'LIB_FLAGS=(-I"$INC" -O1 -emit-llvm -S)' 'LIB_FLAGS=(-I"$INC" -include CQ.h -O1 -emit-llvm -S)'
echo -n "  WARM:     "; D "$T1" $C | tail -1
echo -n "  NO_CACHE: "; D "$T1" $C --nocache | tail -1
git checkout -q tests/e2e/run_slice_multi.sh
echo "== (b) stage-3 -O2"
P tests/e2e/stage_cache.sh 'CQ_S3_CC_FLAGS=(-c)' 'CQ_S3_CC_FLAGS=(-O2 -c)'
echo -n "  WARM:     "; D "$T3" $C | tail -1
echo -n "  NO_CACHE: "; D "$T3" $C --nocache | tail -1
git checkout -q tests/e2e/stage_cache.sh
echo "== restored, warm"; D "$T1|$T3|$T4" $C | tail -1
git status --short
