#!/bin/bash
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_l4x4
D=$(dirname "$0")
for c in "$@"; do
  B=$(basename "$c" .c); T=$(mktemp -d)
  "$LLVM/clang" -I$ORC/include -include CQ.h -O1 -emit-llvm -S "$c" -o "$T/a.ll" || continue
  "$LLVM/clang" -I$ORC/include -O1 -emit-llvm -S "$D/lib.c" -o "$T/b.ll" || continue
  "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/c.ll"
  for tag in orc subj; do
    r=$ORC; [ $tag = subj ] && r=$SUBJ
    "$r/build/ir-pass/cq-opt" -load-pass-plugin "$r/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/c.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
    if [ $? -eq 0 ]; then printf "%s=ACCEPT(%s) " $tag $(md5 -q $T/$tag.ll | cut -c1-8); else printf "%s=DECLINE(%s) " $tag "$(grep -o 'cq [a-z ]*: .*' $T/$tag.err|head -1|cut -c1-70)"; fi
  done
  echo "  <= $B"
  cp $T/subj.ll /tmp/${B}.subj.ll 2>/dev/null; cp $T/c.ll /tmp/${B}.s1.ll 2>/dev/null
  rm -rf $T
done
