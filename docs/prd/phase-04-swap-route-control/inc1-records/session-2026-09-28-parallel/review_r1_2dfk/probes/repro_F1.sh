#!/bin/bash
# r1 2dfk F-1 repro: an edit to the HARNESS'S OWN stage commands is not in any
# cache key, so a WARM cache replays the pre-edit result and a test that must go
# red stays green. Run ONLY in a private worktree with its own configured build.
# Usage: repro_F1.sh <worktree>        (restores every file it touches)
set -u
R=$1; B=$R/build; cd $R
T1='^e2e-slice-(specialize-2file|multi-2file|specialize-select|spec-lift-quantum-base|classical-call-under-control)$'
T3='^e2e-slice-(libm-real-coshl|libm-real-atan2l|spec-qram-read|spec-qram-read-under-control|spec-qrom-read-arm-escape)$'
v() { (cd $B && "$@" 2>&1 | grep -E 'tests passed'); }
echo "warm-up (unmodified harness)"; v ctest -R "$T1|$T3" -j4
echo "== F-1a: run_slice_multi.sh lib TUs get -include CQ.h (trips the C18 #error in every lib)"
sed -i '' 's|"lib-no-CQ.h" -I"$INC" -O1|"lib-no-CQ.h" -I"$INC" -include CQ.h -O1|' tests/e2e/run_slice_multi.sh
echo -n "  WARM:     "; v ctest -R "$T1" -j4
echo -n "  NO_CACHE: "; v env CQ_E2E_NO_CACHE=1 ctest -R "$T1" -j4
git checkout -- tests/e2e/run_slice_multi.sh
echo "== F-1b: stage 3 compiled at -O2 (the bd szpr 'do not add -O here' pin)"
sed -i '' 's|        "$1" -c "$TMP/s2.ll" -o "$TMP/s2.o"|        "$1" -O2 -c "$TMP/s2.ll" -o "$TMP/s2.o"|' tests/e2e/stage_cache.sh
echo -n "  WARM:     "; v ctest -R "$T3" -j4
echo -n "  NO_CACHE: "; v env CQ_E2E_NO_CACHE=1 ctest -R "$T3" -j4
git checkout -- tests/e2e/stage_cache.sh
git status --short
