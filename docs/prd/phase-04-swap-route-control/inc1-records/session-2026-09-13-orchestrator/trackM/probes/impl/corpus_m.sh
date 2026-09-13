#!/bin/bash
# Track M corpus sweep — ORACLE (CQ_lang, frozen e96f89c) vs SUBJECT (CQ_mphi).
# Row = rel|ORACLE verdict|SUBJECT verdict.  A:<md5 of lowered IR>  D:<diagnostic>
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_mphi
R=$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records
OUT=$1
: > $OUT
DIRS=$(cd $R && ls -d session-9pum/probes session-9pum/review_a1_r1_probes session-9pum/review_a1_r2_probes \
   session-b6ap/probes session-b6ap/review_b6ap_r1_probes session-b6ap/review_b6ap_r2_probes \
   session-f2-i1/probes session-f2-i1/review_f2_r1_probes \
   session-l4x4/probes session-l4x4/review_l4x4b_r1_probes session-l4x4/fix_l4x4b_r1_probes \
   session-boi6/probes session-r903/probes \
   session-2026-09-11-orchestrator/probes session-2026-09-11-orchestrator/review_integration_probes \
   session-2026-09-13-orchestrator/probes session-2026-09-13-orchestrator/trackM/probes \
   session-2026-09-13-orchestrator/trackL/probes session-2026-09-13-orchestrator/trackR/probes 2>/dev/null)
run_one(){ f=$1 rel=$2
    T=$(mktemp -d)
    if [[ "$f" == *.c ]]; then
      base=$(basename "$f"); dir=$(dirname "$f")
      if [[ "$base" == *_caller.c ]]; then
        stem=${base%_caller.c}
        libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
        "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR" >> $OUT; rm -rf $T; return; }
        if [ -n "$libf" ] && [ -f "$libf" ]; then
          "$LLVM/clang" -I$SUBJ/include -O1 -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"
        else cp "$T/a.ll" "$T/s1.ll"; fi
      elif [[ "$base" == *_lib.c || "$base" == lib*.c ]]; then rm -rf $T; return
      else
        "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR" >> $OUT; rm -rf $T; return; }
      fi
    else cp "$f" "$T/s1.ll"; fi
    v(){ local root=$1 tag=$2
      "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
      if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll"|cut -c1-8)"; else echo "D:$(grep -oE 'cq [a-z0-9 ]+: [^\"]+' "$T/$tag.err"|head -1|sed 's/ under quantum control//'|cut -c1-80)"; fi; }
    echo "$rel|$(v $ORC o)|$(v $SUBJ s)" >> $OUT
    rm -rf $T
}
for d in $DIRS; do
  [ -d "$R/$d" ] || continue
  find "$R/$d" \( -name '*.c' -o -name '*.ll' \) ! -name '*.s1.ll' ! -name '*.s2.ll' | sort | while read -r f; do run_one "$f" "${f#$R/}"; done
done
# the shipped ir-pass fixtures too
find $SUBJ/ir-pass/test -name '*.ll' | sort | while read -r f; do run_one "$f" "ir-pass/test/$(basename $f)"; done
echo DONE >> $OUT
