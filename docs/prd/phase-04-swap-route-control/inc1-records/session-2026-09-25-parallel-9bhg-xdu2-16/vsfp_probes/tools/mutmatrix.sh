#!/bin/bash
# mutmatrix.sh [MUTANT...] : full lit under every mutant binary (via the litora site
# config) with a per-test TIMEOUT (a mutant can make the pass NON-TERMINATING — M3 did,
# and a lit run without a timeout hangs instead of reporting); prints lit's own
# discovered count, the result lines seen, and the failing/timed-out fixtures. A run
# that discovers 0 tests is reported as BROKEN, never as "0 failed". APPENDS.
V=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp
cd "$V" || exit 1
OUT=$V/mutmatrix.txt
touch "$OUT"
if [ $# -gt 0 ]; then LIST=("$@"); else LIST=(); for b in bin/cq-opt.M* bin/cq-opt.B* bin/cq-opt.D*; do LIST+=("${b#bin/cq-opt.}"); done; fi
for name in "${LIST[@]}"; do
  VSFP_CQ_OPT=$V/bin/cq-opt.$name lit --timeout 60 litora > "mm_$name.log" 2>&1
  disc=$(grep "Total Discovered Tests" "mm_$name.log" | sed 's/[^0-9]//g')
  seen=$(grep -c "^\(PASS\|FAIL\|XFAIL\|XPASS\|TIMEOUT\): " "mm_$name.log")
  nf=$(grep -c "^\(FAIL\|TIMEOUT\): " "mm_$name.log")
  fails=$(grep "^\(FAIL\|TIMEOUT\): " "mm_$name.log" | sed 's/^\([A-Z]*\): CQ IR-pass :: /\1:/; s/ (.*//' | tr '\n' ' ')
  if [ -z "$disc" ] || [ "$disc" = 0 ]; then
    echo "$name BROKEN (no tests discovered): $(tail -1 "mm_$name.log")" >> "$OUT"
  else
    echo "$name discovered=$disc seen=$seen failed=$nf :: $fails" >> "$OUT"
  fi
done
echo "done $*" >> "$OUT"
