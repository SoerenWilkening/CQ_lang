#!/bin/bash
# corpusdiff.sh (review_b1_r1) — the INDEPENDENT whole-corpus differential: run both binaries
# on every ir-pass/test/*.ll EXCEPT the new control_swap_{,reject_}select_rail_* family and
# compare return code, stderr and stdout. Round 1 measured SCANNED=1737 RCDIFF=0 DIAGDIFF=0
# OUTDIFF=0. Edit PRE= if the saved pre-B.1 binary pair has moved. ~8 min, single-threaded.
ROOT=/Users/sorenwilkening/Desktop/CQ_lang
PRE=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/05a94f34-2e8d-4c24-b48c-aaecd3961c97/scratchpad/impl_b1/pre
T=$(mktemp -d)
n=0; rcd=0; dd=0; od=0
for f in $ROOT/ir-pass/test/*.ll; do
  b=$(basename "$f")
  # skip files this increment added or renamed
  case "$b" in control_swap_select_rail_*|control_swap_reject_select_rail_*) continue;; esac
  "$PRE/cq-opt" -load-pass-plugin "$PRE/libCQPass.so" -passes=cq-lowering -S "$f" -o "$T/a.ll" 2>"$T/a.err"; ra=$?
  "$ROOT/build/ir-pass/cq-opt" -load-pass-plugin "$ROOT/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$f" -o "$T/b.ll" 2>"$T/b.err"; rb=$?
  n=$((n+1))
  [ "$ra" != "$rb" ] && { echo "RCDIFF $b ($ra vs $rb)"; rcd=$((rcd+1)); }
  cmp -s "$T/a.err" "$T/b.err" || { echo "DIAGDIFF $b"; dd=$((dd+1)); }
  if [ $ra -eq 0 ] && [ $rb -eq 0 ]; then cmp -s "$T/a.ll" "$T/b.ll" || { echo "OUTDIFF $b"; od=$((od+1)); }; fi
done
echo "SCANNED=$n RCDIFF=$rcd DIAGDIFF=$dd OUTDIFF=$od"
rm -rf "$T"
