#!/bin/bash
# usage: run3.sh <file.c>  — measures ORACLE / F2BASE / SUBJECT
LLVM=/usr/local/opt/llvm@19/bin
SC=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4
SUBJ=/Users/sorenwilkening/Desktop/CQ_l4x4
ORAC=/Users/sorenwilkening/Desktop/CQ_lang
F2B=/Users/sorenwilkening/Desktop/CQ_f2
f="$1"; b=$(basename "$f" .c)
$LLVM/clang -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o $SC/s1/$b.ll 2>/dev/null || { echo "$b CLANGFAIL"; exit; }
brs=$(grep -c 'br i1' $SC/s1/$b.ll); sel=$(grep -c ' = select ' $SC/s1/$b.ll)
one() {
  local root="$1" tag="$2"
  out=$("$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" -passes=cq-lowering -S $SC/s1/$b.ll -o $SC/s1/$b.$tag.s2.ll 2>&1)
  rc=$?
  if [ $rc -eq 0 ]; then echo -n "rc0"; else
    msg=$(echo "$out" | grep -o 'cq [a-z ]*lowering: .*' | head -1 | sed 's/cq [a-z ]*lowering: //; s/ under quantum control.*//')
    echo -n "rc1:$msg"
  fi
}
printf "%-34s brs=%s sel=%s | ORACLE=%s | F2=%s | SUBJ=%s\n" "$b" "$brs" "$sel" "$(one $ORAC o)" "$(one $F2B f)" "$(one $SUBJ s)"
