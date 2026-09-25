#!/bin/bash
# Final A/B sweeps of the e2e module sets + the probe battery, ORACLE vs new3 (the
# final subject, cq-opt 8b837d1f).
P=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
echo "### ir-pass/test corpus"
ls /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/ir-pass/test/*.ll > "$P/p9/corpus.lst"
python3 "$P/p9/ab_sweep.py" "$P/frozen/cq-opt.main983" "$P/frozen/cq-opt.new3" "$P/p9/corpus.lst" --null
echo "### multi-TU e2e modules"
python3 "$P/p9/ab_sweep.py" "$P/frozen/cq-opt.main983" "$P/frozen/cq-opt.new3" "$P/p9/multi.lst" --null
echo "### standalone e2e modules"
python3 "$P/p9/ab_sweep.py" "$P/frozen/cq-opt.main983" "$P/frozen/cq-opt.new3" "$P/p9/single.lst" --null
echo "### probe battery (pre / ora / new3)"
bash "$P/p9/run.sh" "pre ora new3" rt1 rt2 rt3 rq1 rq2 rx1 ya yb yc yo ob1 ob2 ob3 ob4 ob5 ob6 ob7 ob8 ob9 rp1 rq3 rfc rfq r65 r65c rloop rsel rs1 rm2 fp2 fp3
echo "### new3 vs preE streams on the accepts"
bash "$P/p9/cmp.sh" pre new3 rt1 rt2 rt3 ob1 ob2 ob3 ob4 ob5 ob6 ob7 ob8 rfc rloop rsel fp2 fp3
echo "### new3 vs new2 (the pointer scrub must move nothing where new2 accepted)"
bash "$P/p9/cmp.sh" new2 new3 rt1 rt2 rt3 ob1 ob2 ob3 ob4 ob5 ob6 ob7 ob8 ob9 ya yb fp2 rfc rloop rsel
echo "### stage 2b on every new3 accept"
cd "$P/p9"
for m in rt1 rt2 rt3 ob1 ob2 ob3 ob4 ob5 ob6 ob7 ob8 ob9 ya yb rfc rloop rsel fp2 fp3; do
  printf '%-6s ' "$m"
  python3 /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/tools/free_pairing_check.py "$m.new3.s2.ll" 2>&1 | tail -1 | sed 's/.*cqrt_free site(s): //'
done
