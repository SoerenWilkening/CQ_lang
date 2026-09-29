#!/bin/bash
# Regenerates results.txt: every probe x {old,new} header on the ORACLE cq-opt (bit-identical to the
# subject's), args "83 3"; then the headline probes on the session's COMPOSED binary; then the
# width probes under the MUTANT header (nomerge only on cq_theta_si32).
cd "$(dirname "$0")"
{
for f in src/*.c src/*.cpp src/*.ll; do n=$(basename "$f"); n=${n%.*}
  case $n in *.lib1) continue;; sinl*|inl*) continue;; sel1_twin) HDRS=new ./run.sh $n 83 3; continue;; rd2) NOHDR=1 ./run.sh $n 83 3; continue;; cpp1) CC=clang++ ./run.sh $n 83 3; continue;; esac
  ./run.sh $n 83 3
done
echo "== MUTANT header (nomerge removed from every cq_theta_* except si32)"
for p in f80 f16 n5 n6b; do HDRS=mut ./run.sh $p 83 3; done
echo "== COMPOSED binary cq-opt.r2A_composed_rhk5r2_z0rer2_nlfd (verdict only)"
COMP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.r2A_composed_rhk5r2_z0rer2_nlfd
for p in zt_a1 fpzt_a1 fp1 fp3 a6 n9 sel1 vol1 cc3 cc5; do for H in old new; do
  "$COMP" -passes=cq-lowering -S out/$p.$H.s1.ll -o /dev/null 2>out/$p.$H.comp.err; rc=$?
  echo "$p[$H] COMPOSED rc=$rc $(grep -m1 -o 'error: .*' out/$p.$H.comp.err | sed 's/.*ptr): //' | cut -c1-100)"; done; done
} > results.txt 2>&1
rm -f out/*.exe
