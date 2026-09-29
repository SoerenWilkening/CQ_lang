#!/bin/bash
# mutlit.sh: full lit ir-pass/test on the private build under each R1B_MUT value
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
cd $SP/rev_r1B_z0re/build
for m in "$@"; do
  R1B_MUT=$m lit -j4 -s ir-pass/test > $SP/r1B_z0re/out/mutlit_$m.txt 2>&1
  echo "R1B_MUT=$m rc=$? $(grep -E 'Passed|Failed|Expectedly' $SP/r1B_z0re/out/mutlit_$m.txt | tr '\n' ' ') FAILS: $(grep -o 'FAIL: .*' $SP/r1B_z0re/out/mutlit_$m.txt | head -8 | tr '\n' ' ')"
done
