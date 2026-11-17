#!/bin/bash
# cq-jp8qu, slow (not in the default set; about 2 min lowering + 5 min checks, 1.3 GB peak):
#   tests/eff-tape/percent_n_check.sh [plugin]
# Lowers percent_n_check.c with cqcc (K 4, the injection bundle's printf_core: 8 clones, 184 MB of IR), then
#   1. cqcheck user --light, 16 samples: the lowered %n count and printf's result against the C program: PASS;
#   2. the mutant of percent_n_mutant.py (every lowered BARE %n store writes cnt + 1): cqcheck user --light, 4 samples:
#      FAIL (exit 1).
# Run it under the machine's limits, e.g. HEAVY_MAX_MB=3072 HEAVY_MAX_T=900 nice ../wt/heavy.sh -t 900 tests/eff-tape/percent_n_check.sh
set -u
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/../.." && pwd)
PLUGIN=${1:-${CQ_PLUGIN:-$ROOT/build/pass/libCQLower.so}}
SPEC=${CQ_SPEC_DIR:-$ROOT/spec}
OUT=${CQ_BUILD_DIR:-$ROOT/build}/tests/eff-tape/percent_n
rm -rf "$OUT"; mkdir -p "$OUT/ok" "$OUT/mut"
CQ_PLUGIN="$PLUGIN" CQ_SPEC_DIR="$SPEC" python3 "$ROOT/driver/cqcc" -S "$HERE/percent_n_check.c" -o "$OUT/ok/lowered.ll" \
  --save-temps "$OUT/ok" || { echo "FAIL: cqcc"; exit 1; }
cp "$OUT/ok/linked.ll" "$OUT/mut/linked.ll"
n=$(python3 "$HERE/percent_n_mutant.py" "$OUT/ok/lowered.ll" "$OUT/mut/lowered.ll") || { echo "FAIL: no %n store found to mutate"; exit 1; }
cd "$ROOT/checker"
export CQ_PLUGIN="$PLUGIN" CQCHECK_JOBS=${CQCHECK_JOBS:-1} CQCHECK_SAMPLE_TIMEOUT=${CQCHECK_SAMPLE_TIMEOUT:-600}
python3 -m cqcheck user --o1 "$OUT/ok/linked.ll" --lowered "$OUT/ok/lowered.ll" --entry pn --samples 16 --light > "$OUT/ok/check.txt" 2>&1
a=$?
python3 -m cqcheck user --o1 "$OUT/mut/linked.ll" --lowered "$OUT/mut/lowered.ll" --entry pn --samples 4 --light > "$OUT/mut/check.txt" 2>&1
b=$?
grep -E "^cqcheck user" "$OUT/ok/check.txt"; grep -E "^cqcheck user|^  c: " "$OUT/mut/check.txt" | cut -c1-300 | head -4
rm -f "$OUT"/*/lowered.ll   # 184 MB each
fail=0
[ $a -eq 0 ] && grep -q "^cqcheck user: PASS: " "$OUT/ok/check.txt" || { echo "FAIL: the lowered %n program is not a PASS (exit $a)"; fail=1; }
[ $b -eq 1 ] || { echo "FAIL: the mutant ($n stores of cnt + 1) was not rejected (exit $b)"; fail=1; }
[ $fail -eq 0 ] && echo "ok percent_n_check: PASS, and the mutant ($n stores) rejected"
exit $fail
