#!/bin/bash
# twin_ir.sh SRC.c : const-trip (3) rolled vs the SAME stage-1 IR fully unrolled by
# opt loop-unroll-full (no other -O1 re-canonicalisation), both lowered by the SUBJECT.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aeb4c8cbea3df61df
L=/usr/local/opt/llvm@19/bin; SUB=$W/build/ir-pass/cq-opt
src=$1; b=$(basename ${src%.c}); 
sed 's/i < n; ++i)/i < 3; ++i)/' $src > $b.k3.c
$L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S $b.k3.c -o $b.k3.s1.ll || exit 9
grep -q "llvm.loop" $b.k3.s1.ll || { echo "$b: NOT ROLLED at -O1 (skip)"; exit 0; }
sed 's/"llvm.loop.unroll.disable"/"llvm.loop.unroll.full"/' $b.k3.s1.ll > $b.k3m.s1.ll
$L/opt -passes='loop-unroll<O3>' -S $b.k3m.s1.ll -o $b.k3u.s1.ll
grep -q "llvm.loop" $b.k3u.s1.ll && { echo "$b: unroll failed"; exit 0; }
[ -s $b.k3.s1.ll ] && [ -s $b.k3u.s1.ll ] || { echo EMPTY; exit 9; }
out=""
for v in k3 k3u; do
  $SUB -passes=cq-lowering -S $b.$v.s1.ll -o $b.$v.s2.ll 2> $b.$v.err; rc=$?
  if [ $rc != 0 ]; then out="$out $v=DECLINE[$(grep -o 'lowering: .*' $b.$v.err | head -1 | cut -c1-60)]"; continue; fi
  $L/clang $b.$v.s2.ll $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o $b.$v.exe 2>/dev/null || { out="$out $v=LINKFAIL"; continue; }
  ./$b.$v.exe > $b.$v.trace; out="$out $v=A($(wc -l < $b.$v.trace))"
done
if [ -f $b.k3.trace ] && [ -f $b.k3u.trace ]; then cmp -s $b.k3.trace $b.k3u.trace && out="$out IDENTICAL" || out="$out DIFF"; fi
echo "$b:$out"
