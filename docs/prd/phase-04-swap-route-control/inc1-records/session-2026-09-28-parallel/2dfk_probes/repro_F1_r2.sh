#!/bin/bash
# bd ffm0 / 2dfk round 2 — r1's repro_F1.sh, re-spelled for the re-keyed harness
# (r1's sed patterns target the old lines and would now plant NOTHING — a null
# mutant that reports "pass" — so every edit here is checked as PLANTED).
# For each harness edit that must fail: warm the entries with the unmodified
# harness, apply the edit, run WARM and with CQ_E2E_NO_CACHE=1; both must be red.
# Restores every file from a saved copy (works on an uncommitted tree too).
# Usage: repro_F1_r2.sh <worktree>
set -u
R=$1; B=$R/build; cd "$R" || exit 2
T1='^e2e-slice-(specialize-2file|multi-2file|specialize-select|spec-lift-quantum-base|classical-call-under-control)$'
T3='^e2e-slice-(libm-real-coshl|libm-real-atan2l|spec-qram-read|spec-qram-read-under-control|spec-qrom-read-arm-escape)$'
T4='^e2e-slice-(theta-add-measure|qq-hl-arith)$'
SAVE=$(mktemp -d)
cp -f tests/e2e/run_slice.sh tests/e2e/run_slice_multi.sh tests/e2e/stage_cache.sh "$SAVE/"
restore() { cp -f "$SAVE/run_slice.sh" "$SAVE/run_slice_multi.sh" "$SAVE/stage_cache.sh" tests/e2e/; }
trap 'restore; rm -rf "$SAVE"' EXIT
v() { (cd "$B" && "$@" 2>&1 | grep -E 'tests passed'); }
plant() {  # file old new
    python3 - "$1" "$2" "$3" <<'EOF' || { echo "  NOT PLANTED: $2"; exit 3; }
import sys
p, old, new = sys.argv[1:]
t = open(p).read()
if t.count(old) != 1:
    sys.exit(1)
open(p, "w").write(t.replace(old, new, 1))
EOF
}
echo "warm-up (unmodified harness)"; v ctest -R "$T1|$T3|$T4" -j4
echo "== (a) run_slice_multi.sh lib TUs get -include CQ.h (the C18 tripwire)"
plant tests/e2e/run_slice_multi.sh 'LIB_FLAGS=(-I"$INC" -O1 -emit-llvm -S)' 'LIB_FLAGS=(-I"$INC" -include CQ.h -O1 -emit-llvm -S)'
echo -n "  WARM:     "; v ctest -R "$T1" -j4
echo -n "  NO_CACHE: "; v env CQ_E2E_NO_CACHE=1 ctest -R "$T1" -j4
restore
echo "== (b) stage 3 compiled at -O2 (the bd szpr pin)"
plant tests/e2e/stage_cache.sh 'CQ_S3_CC_FLAGS=(-c)' 'CQ_S3_CC_FLAGS=(-O2 -c)'
echo -n "  WARM:     "; v ctest -R "$T3" -j4
echo -n "  NO_CACHE: "; v env CQ_E2E_NO_CACHE=1 ctest -R "$T3" -j4
restore
echo "== (c) lib TUs at -O0"
plant tests/e2e/run_slice_multi.sh 'LIB_FLAGS=(-I"$INC" -O1 -emit-llvm -S)' 'LIB_FLAGS=(-I"$INC" -O0 -emit-llvm -S)'
echo -n "  WARM:     "; v ctest -R "$T1" -j4
echo -n "  NO_CACHE: "; v env CQ_E2E_NO_CACHE=1 ctest -R "$T1" -j4
restore
echo "== (d) run_slice.sh stage 1 at -O0 (r1: PRE-EXISTING half, bd dgn5)"
plant tests/e2e/run_slice.sh 'S1_FLAGS=(-I"$INC" -include "$INC/CQ.h" -O1 -emit-llvm -S)' 'S1_FLAGS=(-I"$INC" -include "$INC/CQ.h" -O0 -emit-llvm -S)'
echo -n "  WARM:     "; v ctest -R "$T4" -j4
echo -n "  NO_CACHE: "; v env CQ_E2E_NO_CACHE=1 ctest -R "$T4" -j4
restore
echo "== after restore (must be all green, warm)"; v ctest -R "$T1|$T3|$T4" -j4
