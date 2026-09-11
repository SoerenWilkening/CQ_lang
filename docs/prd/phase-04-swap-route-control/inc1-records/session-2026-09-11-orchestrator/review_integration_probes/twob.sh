#!/bin/bash
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_l4x4
R=$ORC/docs/prd/phase-04-swap-route-control/inc1-records
ok=0; bad=0; unp=0
while read -r rel; do
  f="$R/$rel"; T=$(mktemp -d)
  base=$(basename "$f"); dir=$(dirname "$f")
  if [[ "$f" == *.c ]]; then
    if [[ "$base" == *_caller.c ]]; then
      stem=${base%_caller.c}; libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null|head -1)
      "$LLVM/clang" -I$ORC/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null
      if [ -n "$libf" ]; then "$LLVM/clang" -I$ORC/include -O1 -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"; else cp "$T/a.ll" "$T/s1.ll"; fi
    else "$LLVM/clang" -I$ORC/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null; fi
  else cp "$f" "$T/s1.ll"; fi
  "$SUBJ/build/ir-pass/cq-opt" -load-pass-plugin "$SUBJ/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2>/dev/null
  out=$(python3 $ORC/tools/free_pairing_check.py "$T/s2.ll" 2>&1)
  v=$(echo "$out" | grep -oE '[0-9]+ violation\(s\)' | grep -oE '^[0-9]+')
  u=$(echo "$out" | grep -oE '[0-9]+ unproven' | grep -oE '^[0-9]+')
  if [ "$v" = "0" ] && [ "$u" = "0" ]; then ok=$((ok+1)); else echo "NOTCLEAN $rel :: $out"; [ "$v" != "0" ] && bad=$((bad+1)) || unp=$((unp+1)); fi
  rm -rf $T
done
echo "stage2b clean=$ok violations=$bad unproven=$unp"
