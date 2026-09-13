#!/bin/bash
# corpusC.sh — Track C's ORACLE-vs-SUBJECT sweep. `corpus.sh` from
# session-2026-09-11-orchestrator/review_integration_probes VERBATIM in its row
# format and its two-TU handling, with three deliberate deltas, each noted:
#
#   (1) SUBJ is /Users/sorenwilkening/Desktop/CQ_21mg.
#   (2) The corpus is widened per PROTOCOL.md: the 1893 PRE-EXISTING
#       `ir-pass/test/*.ll` (taken from the ORACLE checkout, so the 6 fixtures
#       this increment ADDS are not silently counted as movers) plus every
#       session probe dir named there, including the 2026-09-13 ones.
#   (3) THE DECLINE TAG FALLS BACK TO THE FULL FIRST `error:` LINE. The upstream
#       `grep -oE 'cq [a-z0-9 ]+: [^"]+'` requires a literal "cq " + space, so it
#       matches NOTHING in the measure sink's own dialect
#       (`cq_measure_<sfx> operand not recognized; …`) and renders every measure
#       decline as a bare `D:` — exactly the strings this increment moves. Mover
#       DETECTION is unaffected either way (D: vs A:md5 still differs); only the
#       NAMING was lossy, so this is a strict superset.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_21mg
R=$ORC/docs/prd/phase-04-swap-route-control/inc1-records
OUT=$1
: > $OUT

list_inputs() {
  # the pre-existing lit corpus (from the ORACLE checkout)
  find "$ORC/ir-pass/test" -name '*.ll' | sort
  # every session probe corpus PROTOCOL.md names
  for d in session-9pum/probes session-9pum/review_a1_r1_probes session-9pum/review_a1_r2_probes \
           session-b6ap/probes session-b6ap/review_b6ap_r1_probes session-b6ap/review_b6ap_r2_probes \
           session-f2-i1/probes session-f2-i1/review_f2_r1_probes \
           session-l4x4/probes session-l4x4/review_l4x4b_r1_probes session-l4x4/fix_l4x4b_r1_probes \
           session-boi6/probes session-r903/probes \
           session-2026-09-11-orchestrator/probes \
           session-2026-09-11-orchestrator/review_integration_probes \
           session-2026-09-13-orchestrator/probes \
           session-2026-09-13-orchestrator/trackC/probes \
           session-2026-09-13-orchestrator/trackL/probes \
           session-2026-09-13-orchestrator/trackM/probes \
           session-2026-09-13-orchestrator/trackR/probes; do
    [ -d "$R/$d" ] || continue
    find "$R/$d" \( -name '*.c' -o -name '*.ll' \) | sort
  done
}

list_inputs | while read -r f; do
  T=$(mktemp -d); rel=${f#$R/}; rel=${rel#$ORC/}
  if [[ "$f" == *.c ]]; then
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
    if [ $? -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll"|cut -c1-8)"
    else
      d=$(grep -oE 'cq [a-z0-9 ]+: [^"]+' "$T/$tag.err"|head -1|sed 's/ under quantum control//'|cut -c1-80)
      [ -n "$d" ] || d=$(grep -m1 'error:' "$T/$tag.err"|sed 's/.*in function [^:]*: //'|cut -c1-80)
      echo "D:$d"
    fi; }
  echo "$rel|$(v $ORC o)|$(v $SUBJ s)" >> $OUT
  rm -rf $T
done
echo DONE >> $OUT
