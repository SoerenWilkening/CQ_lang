#!/bin/bash
# Final A/B sweeps of the e2e module sets + the probe battery, oracle vs new2.
P=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
echo "### multi-TU e2e modules"
python3 "$P/p9/ab_sweep.py" "$P/frozen/cq-opt.main983" "$P/frozen/cq-opt.new2" "$P/p9/multi.lst" --null
echo "### standalone e2e modules"
python3 "$P/p9/ab_sweep.py" "$P/frozen/cq-opt.main983" "$P/frozen/cq-opt.new2" "$P/p9/single.lst" --null
echo "### probe battery (pre / ora / new2)"
bash "$P/p9/run.sh" "pre ora new2" rt1 rt2 rt3 rq1 rq2 rx1 ya yb yc yo ob1 ob2 ob3 ob4 ob5 ob6 ob7 ob8 ob9 rp1 rq3 rfc rfq r65 r65c rloop rsel rs1 rm2 fp2
echo "### new2 vs preE streams on the accepts"
bash "$P/p9/cmp.sh" pre new2 rt1 rt2 rt3 ob1 ob2 ob3 ob4 ob5 ob6 ob7 ob8 rfc rloop rsel fp2
echo "### new2 vs the pre-conjunct subject (6b8bebc7; tag 'new' was run when build/ was that binary)"
bash "$P/p9/cmp.sh" new new2 rt1 rt2 rt3 ob1 ob2 ob3 ob4 ob5 ob6 ob7 ob8 ob9 ya yb fp2
bash "$P/p9/cmp.sh" new1 new2 rfc rloop rsel
