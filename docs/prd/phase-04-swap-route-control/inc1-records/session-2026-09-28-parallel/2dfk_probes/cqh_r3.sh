#!/bin/bash
# bd dbjh (2dfk round 3) — r2's CQ.h plant (review_r2_2dfk/probes/cqh_r2.sh),
# re-run against THIS tree: every cq_theta angle doubled in include/CQ.h, the
# header still compiles, NO reconfigure and NO build (so CQ_S1_BASE stays what the
# last configure computed — Rule 19's CQ.h inner loop). WARM vs CQ_E2E_NO_CACHE=1
# over r2's set: run_slice_multi.sh (T1), run_slice.sh (T4) and a python
# stage1_file harness. Both must now agree. Restores CQ.h from a saved copy.
# Usage: cqh_r3.sh <worktree>
set -u
R=$1; B=$R/build; cd "$R" || exit 2
T1='^e2e-slice-(specialize-2file|multi-2file|specialize-select|spec-lift-quantum-base|classical-call-under-control)$'
T4='^e2e-slice-(theta-add-measure|qq-hl-arith)$'
TT="$T1|$T4|^e2e-railbank-dynamic-admission-matrix$"
SAVE=$(mktemp -d); cp -f include/CQ.h "$SAVE/CQ.h"
trap 'cp -f "$SAVE/CQ.h" include/CQ.h; rm -rf "$SAVE"' EXIT
v() { (cd "$B" && "$@" 2>&1 | grep -E 'tests passed'); }
echo "== warm-up (unmodified)"; v ctest -R "$TT" -j4
python3 - include/CQ.h <<'EOF' || { echo "NOT PLANTED"; exit 3; }
import sys
p = sys.argv[1]
old = "    _Float16:           cq_theta_f16               \\\n)(x, angle)"
new = "    _Float16:           cq_theta_f16               \\\n)(x, (angle) * 2.0)"
t = open(p).read()
if t.count(old) != 1:
    sys.exit(1)
open(p, "w").write(t.replace(old, new, 1))
print("planted in CQ.h")
EOF
echo -n "  WARM:     "; v ctest -R "$TT" -j4
echo -n "  NO_CACHE: "; v env CQ_E2E_NO_CACHE=1 ctest -R "$TT" -j4
cp -f "$SAVE/CQ.h" include/CQ.h
echo "== restored, warm"; v ctest -R "$TT" -j4
