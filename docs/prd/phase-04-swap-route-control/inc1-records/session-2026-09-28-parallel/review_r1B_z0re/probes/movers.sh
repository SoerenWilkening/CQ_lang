#!/bin/bash
# stage1 + subject stage2 for every C probe mover; writes out/mv/<name>.s2.ll
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
L=/usr/local/opt/llvm@19/bin
D=$W/docs/prd/phase-04-swap-route-control/inc1-records
mkdir -p out/mv
grep '^D->A' $W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/z0re_probes/results/ab_v2.txt | awk -F'\t' '{print $2}' | while read k; do
  case $k in
    probe:*) src=$W/${k#probe:}; sess=$(echo $k | grep -o 'session-[^/]*' ); n=$(basename $src .c); tag=${sess:8:10}_$(echo $k | grep -o 'review_r1[AB]_d88e\|d88e_probes\|z0re_probes')_$n;;
    e2e:*) src=$W/tests/e2e/${k#e2e:}; n=$(basename $src .c); tag=e2e_$n;;
    *) continue;;
  esac
  lib=${src%.c}.lib.c
  o=out/mv/$tag
  $L/clang -I$W/include -include CQ.h -O1 -emit-llvm -S $src -o $o.a.ll 2>/dev/null || { echo "$tag CLANGFAIL"; continue; }
  if [ -f $lib ]; then $L/clang -O1 -emit-llvm -S $lib -o $o.lib.ll 2>/dev/null; $L/llvm-link -S $o.a.ll $o.lib.ll -o $o.s1.ll; else cp -f $o.a.ll $o.s1.ll; fi
  $W/build/ir-pass/cq-opt -passes=cq-lowering -S $o.s1.ll -o $o.s2.ll 2>$o.err; echo "$tag rc=$?"
done
