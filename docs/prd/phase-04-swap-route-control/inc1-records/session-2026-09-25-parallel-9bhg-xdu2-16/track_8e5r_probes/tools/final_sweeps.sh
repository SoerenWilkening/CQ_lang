#!/bin/bash
# final_sweeps.sh — the merged tree's corpus A/B and allocator-harness runs.
# Every A/B prints its denominator; the null control (the SUBJECT twice) runs FIRST.
T=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r
cd "$T"
O=final_out; mkdir -p "$O"
echo "== binaries"; shasum -a 256 cq-opt.fin cq-opt.find cq-opt.oracle_ba80 rb8_interpose.dylib
echo "== A. NULL CONTROL: subject (final cq-opt) twice, system allocator"
python3 ab.py ./cq-opt.fin:system ./cq-opt.fin:system m_corpus_all.lst $O/A_null.tsv -j 10
echo "== A2. NULL CONTROL under the independent interposer (rand: scrambled address order), subject twice"
python3 ab.py ./cq-opt.fin:rb8-rand ./cq-opt.fin:rb8-rand m_corpus_all.lst $O/A2_null_rand.tsv -j 10
echo "== B. main ba80bda1 (system) vs subject (system), shipped corpus (lit + e2e stage-1)"
python3 ab.py ./cq-opt.oracle_ba80:system ./cq-opt.fin:system m_corpus_le.lst $O/B_ab_ba80.tsv -j 10
echo "== C. subject allocator independence: cq-opt(system) vs cq-opt-debugalloc under system / lifo / nofree"
python3 ab.py ./cq-opt.fin:system ./cq-opt.find:system m_corpus_all.lst $O/C1.tsv -j 10
python3 ab.py ./cq-opt.fin:system ./cq-opt.find:lifo m_corpus_all.lst $O/C2.tsv -j 10
python3 ab.py ./cq-opt.fin:system ./cq-opt.find:nofree m_corpus_all.lst $O/C3.tsv -j 10
echo "== D. main ba80bda1 under NO REUSE (independent interposer) vs subject (system)"
python3 ab.py ./cq-opt.oracle_ba80:rb8-nofree ./cq-opt.fin:system m_corpus_all.lst $O/D.tsv -j 10
echo "== E. subject under the independent interposer's reuse policies"
python3 ab.py ./cq-opt.fin:system ./cq-opt.fin:rb8-lifo m_corpus_all.lst $O/E1.tsv -j 10
python3 ab.py ./cq-opt.fin:system ./cq-opt.fin:rb8-fifo m_corpus_all.lst $O/E2.tsv -j 10
echo "== F. alias families, 10 runs per config (reference: ba80 under rb8 nofree)"
python3 multirun.py corpus_fam.lst 10 $O/F_multi.tsv \
  $T/cq-opt.oracle_ba80:rb8-nofree $T/cq-opt.fin:system $T/cq-opt.find:lifo $T/cq-opt.find:nofree \
  $T/cq-opt.fin:rb8-fifo $T/cq-opt.oracle_ba80:system $T/cq-opt.oracle_ba80:rb8-lifo
echo "== DONE"
