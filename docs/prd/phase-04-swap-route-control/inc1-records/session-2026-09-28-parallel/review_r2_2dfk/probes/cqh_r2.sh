#!/bin/bash
# r2 probe (C'): a SEMANTIC include/CQ.h edit (every cq_theta angle doubled; the
# header still compiles) with NO reconfigure, i.e. CQ_S1_BASE as the last
# configure computed it — Rule 19's CQ.h inner loop is `ctest -R frontend-lit` +
# e2e with no build step. WARM vs CQ_E2E_NO_CACHE=1, over run_slice.sh (T4),
# run_slice_multi.sh (T1) and a python stage1_file harness.
. "$(dirname "$0")/env.sh"
cd "$MY" || exit 2
TT="$T1|$T4|^e2e-railbank-dynamic-admission-matrix$"
echo "== warm-up (unmodified)"; D "$TT" $C | tail -1
python3 "$SP/rev_r2_probes/plant.py" include/CQ.h '    _Float16:           cq_theta_f16               \
)(x, angle)' '    _Float16:           cq_theta_f16               \
)(x, (angle) * 2.0)' || exit 3
echo -n "  WARM:     "; D "$TT" $C | tail -1
echo -n "  NO_CACHE: "; D "$TT" $C --nocache | tail -1
git checkout -q include/CQ.h
echo "== restored, warm"; D "$TT" $C | tail -1
git status --short
