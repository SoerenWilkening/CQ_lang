#!/bin/bash
# $1 = c file base (in rev/), no args otherwise
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d9542657-7eae-4089-ae6b-77dc3ed77cc3/scratchpad
L=/usr/local/opt/llvm@19/bin
P=/Users/sorenwilkening/Desktop/Projects/CQ_lang
n=$1
"$L/clang" -I$P/include -include CQ.h -O1 -emit-llvm -S $S/rev/$n.c -o $S/rev/$n.s1.ll
rc=$?
if [ $rc -ne 0 ]; then echo "STAGE1 FAIL $rc"; exit 1; fi
for B in oracle subj; do
  $S/$B/cq-opt -passes=cq-lowering -S $S/rev/$n.s1.ll -o $S/rev/$n.$B.s2.ll 2> $S/rev/$n.$B.err
  rc=$?
  echo "=== $n / $B : exit $rc"
  if [ $rc -ne 0 ]; then sed -n '1,4p' $S/rev/$n.$B.err; fi
done
