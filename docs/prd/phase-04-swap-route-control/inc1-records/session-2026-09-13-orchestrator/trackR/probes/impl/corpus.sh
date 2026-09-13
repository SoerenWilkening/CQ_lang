#!/bin/bash
# corpus.sh (Track R, R-1) — ORACLE-vs-SUBJECT sweep. A row is
#   <rel>|<oracle verdict>|<subject verdict>
# where a verdict is A:<md5 of the lowered IR, 8 chars> or D:<diagnostic>.
# Both binaries are run on the SAME stage-1 file.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_rb9x
S=$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records
OUT=$1
: > $OUT
LIST=$(mktemp)
ls $SUBJ/ir-pass/test/*.ll | sort >> $LIST
for d in $S/session-2026-09-13-orchestrator/probes \
         $S/session-2026-09-13-orchestrator/trackR/probes \
         $S/session-2026-09-13-orchestrator/trackM/probes \
         $S/session-2026-09-13-orchestrator/trackL/probes \
         $S/session-2026-09-13-orchestrator/trackC/probes \
         $S/session-9pum/probes $S/session-9pum/review_a1_r1_probes $S/session-9pum/review_a1_r2_probes \
         $S/session-b6ap/probes $S/session-b6ap/review_b6ap_r1_probes $S/session-b6ap/review_b6ap_r2_probes \
         $S/session-f2-i1/probes $S/session-f2-i1/review_f2_r1_probes \
         $S/session-l4x4/probes $S/session-l4x4/review_l4x4b_r1_probes $S/session-l4x4/fix_l4x4b_r1_probes \
         $S/session-boi6/probes $S/session-r903/probes \
         $S/session-2026-09-11-orchestrator/probes $S/session-2026-09-11-orchestrator/review_integration_probes; do
  [ -d "$d" ] || continue
  find "$d" \( -name '*.c' -o -name '*.ll' \) | sort >> $LIST
done
N=$(wc -l < $LIST)
echo "# corpus: $N files | oracle=$(shasum -a 256 $ORC/build/ir-pass/cq-opt|cut -c1-16) subject=$(shasum -a 256 $SUBJ/build/ir-pass/cq-opt|cut -c1-16)" >> $OUT
while read -r f; do
  T=$(mktemp -d); rel=${f#$SUBJ/}
  if [[ "$f" == *.c ]]; then
    base=$(basename "$f"); dir=$(dirname "$f")
    if [[ "$base" == *_caller.c ]]; then
      stem=${base%_caller.c}
      libf="$dir/${stem}_lib.c"; [ -f "$libf" ] || libf=$(ls "$dir"/lib*.c 2>/dev/null | head -1)
      "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/a.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR" >> $OUT; rm -rf $T; continue; }
      if [ -n "$libf" ] && [ -f "$libf" ]; then
        "$LLVM/clang" -I$SUBJ/include -O1 -emit-llvm -S "$libf" -o "$T/b.ll" 2>/dev/null && "$LLVM/llvm-link" -S "$T/a.ll" "$T/b.ll" -o "$T/s1.ll" 2>/dev/null || cp "$T/a.ll" "$T/s1.ll"
      else cp "$T/a.ll" "$T/s1.ll"; fi
    elif [[ "$base" == *_lib.c || "$base" == lib*.c ]]; then rm -rf $T; continue
    else
      "$LLVM/clang" -I$SUBJ/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null || { echo "$rel|CLANGERR|CLANGERR" >> $OUT; rm -rf $T; continue; }
    fi
  else cp "$f" "$T/s1.ll"; fi
  v(){ local root=$1 tag=$2
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
    if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll"|cut -c1-8)"; else echo "D:$(grep -oE 'cq [a-z0-9 ]+: [^\"]+' "$T/$tag.err"|head -1|sed 's/ under quantum control//'|cut -c1-80)"; fi; }
  echo "$rel|$(v $ORC o)|$(v $SUBJ s)" >> $OUT
  rm -rf $T
done < $LIST
echo DONE >> $OUT
