#!/bin/bash
# usage: run3m.sh <linked.ll>
SC=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4
f="$1"; b=$(basename "$f" .ll)
one() {
  out=$("$1/build/ir-pass/cq-opt" -load-pass-plugin "$1/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$f" -o "$SC/multi/$b.$2.s2.ll" 2>&1); rc=$?
  if [ $rc -eq 0 ]; then echo -n "rc0"; else
    echo -n "rc1:$(echo "$out" | grep -o 'cq [a-z ]*lowering: .*' | head -1 | sed 's/cq [a-z ]*lowering: //; s/ under quantum control.*//')"
  fi
}
printf "%-26s | ORACLE=%s | F2=%s | SUBJ=%s\n" "$b" "$(one /Users/sorenwilkening/Desktop/CQ_lang o)" "$(one /Users/sorenwilkening/Desktop/CQ_f2 f)" "$(one /Users/sorenwilkening/Desktop/CQ_l4x4 s)"
