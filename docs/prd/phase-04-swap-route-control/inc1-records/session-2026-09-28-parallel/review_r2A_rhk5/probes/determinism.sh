#!/bin/bash
# r2A determinism: 2x cq-opt, lifo, nofree -> same bytes (stdout+stderr), per file.
cd /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
R=docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel; P=$R/review_r2A_rhk5/probes; B=build/ir-pass
files=( "$@" )
n=0; bad=0
for f in "${files[@]}"; do n=$((n+1))
  a=$($B/cq-opt -passes=cq-lowering -S $f 2>&1 | shasum | cut -c1-12)
  b=$($B/cq-opt -passes=cq-lowering -S $f 2>&1 | shasum | cut -c1-12)
  c=$(CQ_OPT_DEBUG_ALLOC=lifo $B/cq-opt-debugalloc -passes=cq-lowering -S $f 2>&1 | shasum | cut -c1-12)
  d=$(CQ_OPT_DEBUG_ALLOC=nofree $B/cq-opt-debugalloc -passes=cq-lowering -S $f 2>&1 | shasum | cut -c1-12)
  if [ "$a" = "$b" ] && [ "$a" = "$c" ] && [ "$a" = "$d" ]; then :; else bad=$((bad+1)); echo "DIFF $f $a $b $c $d"; fi
done
echo "checked $n files, $bad differ"
