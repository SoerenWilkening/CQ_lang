#!/usr/bin/env bash
# r1B_vsfp mutation re-measure. Sequential; each mutant: patch, touch, build cq-opt, hash, full lit.
set -u
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r1Bv
WT=$S/sub_wt; cd $WT
OUT=$S/mut; mkdir -p $OUT
SP=ir-pass/src/Specialization.cpp; AL=ir-pass/src/ArithLowering.cpp
mut_apply() {
  case $1 in
    M0) sed -i '' 's|^// bd `test_C_libtooling-vsfp` — see Specialization.h. Mirrored|// bd `test_C_libtooling-vsfp` — see Specialization.h (r1B null mutant). Mirrored|' $SP ;;
    B1) sed -i '' 's|^bool declinePhantomCloneArgReads(Module &M, const TaintSet &taint) {|bool declinePhantomCloneArgReads(Module \&M, const TaintSet \&taint) { if (true) return false;|' $SP ;;
    B2) sed -i '' 's|OpCI && llvm::is_contained(taint.ThetaCalls, OpCI))|OpCI \&\& false \&\& llvm::is_contained(taint.ThetaCalls, OpCI))|' $SP ;;
    B3) perl -0pi -e 's/if \(!Callee->getArg\(A\)->use_empty\(\)\)\n            continue;/if (false \&\& !Callee->getArg(A)->use_empty())\n            continue;/' $SP ;;
    B4) sed -i '' 's|          if (!taint.Tainted.count(Op))|          if (false \&\& !taint.Tainted.count(Op))|' $SP ;;
    D1) sed -i '' 's|    if (PassesP \&\& !ReadsP)|    if (false \&\& PassesP \&\& !ReadsP)|' $AL ;;
    D2) sed -i '' 's|      if (A >= Callee->arg_size() \|\| !Callee->getArg(A)->use_empty()) {|      if (false) {|' $AL ;;
  esac
}
if [ "${1:-}" = "--dry" ]; then shift; for m in "$@"; do git checkout -q -- $SP $AL; mut_apply $m; echo "$m: $(git diff --numstat | tr "\n" " ")"; git diff -U0 | grep "^[+-] " | head -2; done; git checkout -q -- $SP $AL; exit 0; fi
for m in "$@"; do
  git checkout -q -- $SP $AL
  mut_apply $m
  nd=$(git diff --stat | tail -1)
  touch $SP $AL
  cmake --build build --target cq-opt CQPass cq-opt-debugalloc -j6 > $OUT/$m.build.log 2>&1 || { echo "$m BUILDFAIL" >> $OUT/summary.txt; continue; }
  h=$(shasum -a 256 build/ir-pass/cq-opt | cut -c1-16)
  cp -f build/ir-pass/cq-opt $S/bin/cq-opt.$m
  (cd build && lit ir-pass/test --timeout 60 > $OUT/$m.lit.txt 2>&1)
  disc=$(grep 'Total Discovered' $OUT/$m.lit.txt | awk '{print $NF}')
  fails=$(grep -c '^FAIL:\|^TIMEOUT:' $OUT/$m.lit.txt)
  [ -z "$disc" ] && { echo "$m BROKEN: no denominator (lit did not run)" >> $OUT/summary.txt; continue; }
  echo "$m hash=$h diff=[$nd] discovered=$disc failed=$fails" >> $OUT/summary.txt
  grep '^FAIL:\|^TIMEOUT:' $OUT/$m.lit.txt | sed "s/^/   $m /" >> $OUT/summary.txt
done
git checkout -q -- $SP $AL; touch $SP $AL
cmake --build build --target cq-opt CQPass cq-opt-debugalloc -j6 > $OUT/restore.build.log 2>&1
echo "RESTORED hash=$(shasum -a 256 build/ir-pass/cq-opt | cut -c1-16)" >> $OUT/summary.txt
