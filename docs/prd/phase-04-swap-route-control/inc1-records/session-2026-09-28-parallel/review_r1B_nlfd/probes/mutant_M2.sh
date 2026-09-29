#!/bin/bash
# r1B mutant M2: delete the `isMustTailCall()` conjunct of the m5pn demotion (demote EVERY call's tail kind in a clone).
# Boundary controls: base hash before, mutant hash != base, restore -> hash == base.
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
T=$SP/rev_r1B_ev3m; F=$T/ir-pass/src/SpecializeClone.cpp
B() { cmake --build $T/build -j4 --target CQPass cq-opt cq-opt-debugalloc cq-scrub-selftest > /dev/null 2>&1; shasum -a 256 $T/build/ir-pass/cq-opt | cut -c1-24; }
base=$(shasum -a 256 $SP/r1B_bin/cq-opt.composed | cut -c1-24); echo "base=$base now=$(shasum -a 256 $T/build/ir-pass/cq-opt | cut -c1-24)"
python3 - "$F" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read(); a='CI && CI->isMustTailCall())'; assert s.count(a)==1; open(p,'w').write(s.replace(a,'CI)'))
PY
m=$(B); echo "M2=$m"; [ "$m" != "$base" ] || { echo "MUTANT==BASE, abort"; exit 1; }
(cd $T/build && lit -j4 -q ir-pass/test > $SP/r1B_lit_M2.log 2>&1; echo "LIT_RC=$?" >> $SP/r1B_lit_M2.log)
grep -c '^FAIL\|^  FAIL' $SP/r1B_lit_M2.log; grep 'FAIL' $SP/r1B_lit_M2.log | head -20
cat $SP/r1B_SpecializeClone.cpp.orig > $F; touch $F
r=$(B); echo "restored=$r"; [ "$r" == "$base" ] && echo BOUNDARY-OK || echo BOUNDARY-FAIL
