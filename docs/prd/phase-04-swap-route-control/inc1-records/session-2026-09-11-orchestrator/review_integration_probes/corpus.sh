#!/bin/bash
# corpus.sh — uniform ORACLE-vs-SUBJECT sweep over every session probe corpus.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_l4x4
R=$ORC/docs/prd/phase-04-swap-route-control/inc1-records
OUT=$1
: > $OUT
for d in session-9pum/probes session-9pum/review_a1_r1_probes session-9pum/review_a1_r2_probes \
         session-b6ap/probes session-b6ap/review_b6ap_r1_probes session-b6ap/review_b6ap_r2_probes \
         session-f2-i1/probes session-f2-i1/review_f2_r1_probes \
         session-l4x4/probes session-l4x4/review_l4x4b_r1_probes session-l4x4/fix_l4x4b_r1_probes; do
  [ -d "$R/$d" ] || continue
  find "$R/$d" \( -name '*.c' -o -name '*.ll' \) | sort | while read -r f; do
    T=$(mktemp -d); rel=${f#$R/}
    if [[ "$f" == *.c ]]; then
      # two-TU pairs: a *_caller.c is linked with every sibling *_lib.c / lib*.c
      base=$(basename "$f"); dir=$(dirname "$f")
      if [[ "$base" == *_caller.c ]]; then
        stem=${base%_caller.c}
        libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
        "$LLVM/clang" -I$ORC/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR" >> $OUT; rm -rf $T; continue; }
        if [ -n "$libf" ] && [ -f "$libf" ]; then
          "$LLVM/clang" -I$ORC/include -O1 -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"
        else cp "$T/a.ll" "$T/s1.ll"; fi
      elif [[ "$base" == *_lib.c || "$base" == lib*.c ]]; then rm -rf $T; continue
      else
        "$LLVM/clang" -I$ORC/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR" >> $OUT; rm -rf $T; continue; }
      fi
    else cp "$f" "$T/s1.ll"; fi
    v(){ local root=$1 tag=$2
      "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
      if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll"|cut -c1-8)"; else echo "D:$(grep -oE 'cq [a-z0-9 ]+: [^\"]+' "$T/$tag.err"|head -1|sed 's/ under quantum control//'|cut -c1-80)"; fi; }
    echo "$rel|$(v $ORC o)|$(v $SUBJ s)" >> $OUT
    rm -rf $T
  done
done
echo DONE >> $OUT
