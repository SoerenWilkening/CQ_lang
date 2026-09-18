#!/bin/bash
# mutants.sh — the (K1)-(K4) conjunct mutation matrix for bd fn1q increment 1.
# Each mutant DELETES one conjunct from valueArmIsPureChain, rebuilds in an
# isolated worktree, and sweeps the whole fixture corpus against the SUBJECT.
# A conjunct is PINNED iff at least one fixture moves when it is deleted.
set -u
R=/Users/sorenwilkening/Desktop/Projects/CQ_lang
W=/private/tmp/claude-501/fn1q-mut
S=/private/tmp/claude-501/fn1q
SUBJ=$R/build/ir-pass/cq-opt

rm -rf "$W"; git -C "$R" worktree add --detach "$W" e107a177 >/dev/null 2>&1
git -C "$W" apply "$S/inc1.patch" || { echo "PATCH FAILED"; exit 1; }
cmake -S "$W" -B "$W/build" -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1

sweep() {  # sweep <bin> <label>
  export CQ_ORACLE="$SUBJ" CQ_SUBJECT="$1"
  ls "$R"/ir-pass/test/*.ll | xargs -P6 -n1 "$S/one.sh" > "$S/mut.$2.tsv" 2>/dev/null
  awk -F'\t' -v L="$2" '$2!="SAME"{n++} END{printf "%-14s movers=%d\n", L, n+0}' "$S/mut.$2.tsv"
}

# BOUNDARY CONTROL: the unmutated patched tree must move NOTHING against SUBJECT.
cmake --build "$W/build" --target cq-opt -j6 >/dev/null 2>&1 || { echo "BUILD FAILED (null)"; exit 1; }
sweep "$W/build/ir-pass/cq-opt" NULL

for K in K1 K2 K3 K4; do
  git -C "$W" checkout -- ir-pass/src/ArmClassify.cpp
  git -C "$W" apply "$S/inc1.patch" --include=ir-pass/src/ArmClassify.cpp 2>/dev/null
  python3 - "$W" "$K" <<'PY'
import sys
w,k=sys.argv[1],sys.argv[2]
p=w+'/ir-pass/src/ArmClassify.cpp'
s=open(p).read()
cuts={
 'K1':['    if (Taint.Tainted.count(&I))\n      return false;  // (K1)\n',
       '    for (const Value *Op : I.operands())\n      if (auto *OpI = dyn_cast<Instruction>(Op))\n        if (OnChain.count(OpI))\n          return false;  // (K1), asked directly — see the note above.\n'],
 'K2':['    if (I.mayWriteToMemory() || I.mayHaveSideEffects())\n      return false;  // (K2)\n'],
 'K3':['    for (const User *U : I.users()) {\n      auto *UI = dyn_cast<Instruction>(U);\n      if (!UI || UI->getParent() != ArmBB)\n        return false;  // (K3)\n    }\n'],
 'K4':['    if (!isSafeToSpeculativelyExecute(&I))\n      return false;  // (K4)\n'],
}
for c in cuts[k]:
    assert c in s, (k, c[:60])
    s=s.replace(c,'',1)
open(p,'w').write(s)
print("cut",k)
PY
  cmake --build "$W/build" --target cq-opt -j6 >/dev/null 2>&1 || { echo "$K BUILD FAILED"; continue; }
  sweep "$W/build/ir-pass/cq-opt" "$K"
  awk -F'\t' '$2!="SAME"{printf "    %s  %s\n", $2, $1}' "$S/mut.$K.tsv" | head -8
done
git -C "$R" worktree remove --force "$W" >/dev/null 2>&1
