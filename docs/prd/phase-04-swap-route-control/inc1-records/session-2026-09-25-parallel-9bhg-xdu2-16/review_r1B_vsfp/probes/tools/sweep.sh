#!/usr/bin/env bash
# crash-only sweep: every r2A_9bhg + d88e probe program (.c with optional .lib.c) on sub and comp;
# reports rc not in {0,1} (abort/crash) and the per-binary verdict counts. Denominator printed.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r1Bv
N=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
L=/usr/local/opt/llvm@19/bin
D=$S/sweep; mkdir -p $D
n=0; bad=0; acc_sub=0; acc_comp=0; tiny=0
for dir in $N/review_r2A_9bhg/probes/src $N/d88e_probes/src; do
  for c in $dir/*.c; do
    case $c in *.lib.c) continue;; esac
    b=$(basename $c .c); tag=$(basename $(dirname $(dirname $dir)))_$b
    lib=$dir/$b.lib.c; s1=$D/$tag.s1.ll
    if [ -f $lib ]; then
      $L/clang -O1 -emit-llvm -S -Wno-everything $lib -o $D/$tag.lib.ll 2>/dev/null || continue
      $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything $c -o $D/$tag.c.ll 2>/dev/null || continue
      $L/llvm-link -S $D/$tag.c.ll $D/$tag.lib.ll -o $s1 2>/dev/null || continue
    else
      $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S -Wno-everything $c -o $s1 2>/dev/null || continue
    fi
    [ $(wc -c < $s1) -lt 200 ] && { tiny=$((tiny+1)); continue; }
    n=$((n+1))
    for t in sub comp; do
      $S/bin/cq-opt.$t -passes=cq-lowering -S $s1 -o /dev/null 2>/dev/null; rc=$?
      if [ $rc -ne 0 ] && [ $rc -ne 1 ]; then echo "CRASH $t rc=$rc $tag"; bad=$((bad+1)); fi
      if [ $rc -eq 0 ]; then [ $t = sub ] && acc_sub=$((acc_sub+1)) || acc_comp=$((acc_comp+1)); fi
    done
  done
done
echo "programs=$n tiny_skipped=$tiny crashes=$bad accepts_sub=$acc_sub accepts_comp=$acc_comp"
