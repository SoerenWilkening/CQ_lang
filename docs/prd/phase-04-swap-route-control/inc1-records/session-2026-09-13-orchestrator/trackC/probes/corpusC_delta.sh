#!/bin/bash
# corpusC_delta.sh — the DELTA half of Track C's ORACLE-vs-MERGED sweep, run by
# the landing agent 2026-09-13. `corpusC.sh` VERBATIM in its row format
# (exit code, diagnostic string, md5 of the lowered IR when accepting); only the
# input list differs.
#
# WHY A DELTA AND NOT A RE-RUN: the merged binary's sha256 is
# c662bd0ca0e7d8a4… — BYTE-IDENTICAL to the SUBJECT the implementer swept at
# 12:33 (the landing's only source edits were comment-only, which the hash
# proves mechanically). PROTOCOL.md §"non-redundancy": a gate result is a fact
# about a BINARY, so those 3021 rows are CITED, not re-run. What was NOT in that
# sweep is swept here:
#   (1) $SES/trackC/review_C_r1_probes  — written by the REVIEWER at 12:50,
#       after the sweep, and living in the worktree (corpusC.sh reads probe dirs
#       out of the ORACLE checkout).
#   (2) the 8 fixtures this landing ADDS to ir-pass/test (6 Track C + 2 Track L
#       H-10 pins) — corpusC.sh deliberately takes ir-pass/test from the ORACLE
#       checkout so added fixtures are not counted as movers; they still owe a
#       verdict pair.
#   (3) $SES/trackL/ready/*.c — the two slices the H-10 pins register.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_21mg
S=$SUBJ/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator
OUT=$1
: > $OUT

list_inputs() {
  find "$S/trackC/review_C_r1_probes" -name '*.c' | sort
  find "$S/trackL/ready" -name '*.c' | sort
  for f in $SUBJ/ir-pass/test/*.ll; do
    b=$(basename "$f")
    [ -f "$ORC/ir-pass/test/$b" ] || echo "$f"
  done
}

list_inputs | while read -r f; do
  T=$(mktemp -d); rel=${f#$SUBJ/}
  if [[ "$f" == *.c ]]; then
    "$LLVM/clang" -I$ORC/include -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
      || { echo "$rel|CLANGERR|CLANGERR" >> $OUT; rm -rf $T; continue; }
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
