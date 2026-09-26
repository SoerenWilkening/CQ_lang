#!/bin/bash
# pins_r2.sh <label> <debugalloc-driver> <sys-driver> <N>
# Re-runs the 8e5r pins by hand N times each: the k65 lit fixture (lifo/nofree/sys +
# FileCheck + two diffs) and the four um24 `nofree` decline lines (`not` = rc 1, not a
# crash). Prints PASS/FAIL counts with denominators. The driver may be a wrapper that
# maps CQ_OPT_DEBUG_ALLOC onto an interposer (for the frozen oracle).
L=$1; DA=$2; SYS=$3; N=$4
S=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2
FC=/usr/local/opt/llvm@19/bin/FileCheck
W=$(mktemp -d)
K=$S/ir-pass/test/spec_scrub_dangling_key_clone_classical_mul.ll
kp=0; kf=0
for i in $(seq 1 $N); do
  CQ_OPT_DEBUG_ALLOC=lifo "$DA" -passes=cq-lowering -S $K > $W/l.ll 2>/dev/null; r1=$?
  CQ_OPT_DEBUG_ALLOC=nofree "$DA" -passes=cq-lowering -S $K > $W/n.ll 2>/dev/null; r2=$?
  "$SYS" -passes=cq-lowering -S $K > $W/s.ll 2>/dev/null; r3=$?
  $FC $K --implicit-check-not=cq_template_mul < $W/l.ll > /dev/null 2>&1; r4=$?
  diff -q $W/l.ll $W/n.ll > /dev/null; r5=$?
  diff -q $W/l.ll $W/s.ll > /dev/null; r6=$?
  if [ $r1$r2$r3$r4$r5$r6 = 000000 ]; then kp=$((kp+1)); else kf=$((kf+1)); fi
done
echo "$L k65 pin: PASS $kp / FAIL $kf of $N"
for f in iosink_reject_mux_literal_callee lowering_reject_break_uncollected_clone \
         lowering_reject_inplace_rail_stale_w1_xor_bareout lowering_reject_inplace_rail_stale_w1_xor_derived; do
  p=0; c=0; o=0
  for i in $(seq 1 $N); do
    CQ_OPT_DEBUG_ALLOC=nofree "$DA" -passes=cq-lowering -S $S/ir-pass/test/$f.ll > /dev/null 2>&1; rc=$?
    if [ $rc = 1 ]; then p=$((p+1)); elif [ $rc -ge 128 ]; then c=$((c+1)); else o=$((o+1)); fi
  done
  echo "$L um24 nofree $f: clean-decline(rc1) $p / crash $c / other $o of $N"
done
rm -rf $W
