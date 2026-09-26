#!/bin/bash
# r2_sweeps.sh — measurements after the Rule-13 delta round (bd ec7r / a66j / sjwe).
# Subject = the final tree's cq-opt; the ONLY movers allowed vs c416f04d's binary
# (cq-opt.fin, 57f03484) are the new fixtures and the deliberately changed gate.
# Null control (the SUBJECT twice) runs FIRST; every A/B prints its denominator.
T=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2
P=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r2_delta_8e5r/probes
cd "$T"
cp -f "$W/build/ir-pass/cq-opt" cq-opt.r2
cp -f "$W/build/ir-pass/cq-opt-debugalloc" cq-opt.r2d
ls "$W"/ir-pass/test/*.ll > r2_lit.lst
ls "$P"/p1_liftskip/k1.ll "$P"/p2_liftskip_verdict/p2_*.ll > r2_probes.lst
cat r2_lit.lst m_corpus_e2e.lst > r2_le.lst
cat r2_le.lst corpus_fam.lst r2_probes.lst > r2_all.lst
O=r2_out; mkdir -p "$O"
echo "== binaries"; shasum -a 256 cq-opt.r2 cq-opt.r2d cq-opt.fin cq-opt.oracle_ba80
echo "== corpus sizes"; wc -l r2_lit.lst m_corpus_e2e.lst corpus_fam.lst r2_probes.lst r2_all.lst
echo "== A. NULL CONTROL: subject twice (system)"
python3 ab.py ./cq-opt.r2:system ./cq-opt.r2:system r2_all.lst $O/A_null.tsv -j 10
echo "== B. c416f04d (cq-opt.fin) vs subject — the delta"
python3 ab.py ./cq-opt.fin:system ./cq-opt.r2:system r2_all.lst $O/B_c416_vs_r2.tsv -j 10
echo "== C. main ba80bda1 vs subject, shipped corpus (lit + e2e) + reviewer probes"
cat r2_le.lst r2_probes.lst > r2_le_probes.lst
python3 ab.py ./cq-opt.oracle_ba80:system ./cq-opt.r2:system r2_le_probes.lst $O/C_ba80_vs_r2.tsv -j 10
echo "== D. subject allocator independence: cq-opt vs cq-opt-debugalloc lifo / nofree"
python3 ab.py ./cq-opt.r2:system ./cq-opt.r2d:lifo r2_all.lst $O/D1.tsv -j 10
python3 ab.py ./cq-opt.r2:system ./cq-opt.r2d:nofree r2_all.lst $O/D2.tsv -j 10
echo "== DONE"
