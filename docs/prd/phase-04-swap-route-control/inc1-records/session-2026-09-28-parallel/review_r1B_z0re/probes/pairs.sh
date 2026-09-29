#!/bin/bash
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
D=$W/docs/prd/phase-04-swap-route-control/inc1-records
S25=$D/session-2026-09-25-parallel-9bhg-xdu2-16
S28=$D/session-2026-09-28-parallel/z0re_probes/src
mkdir -p pr
for spec in "$S25/d88e_probes/src a01" "$S25/d88e_probes/src a02" "$S25/d88e_probes/src l12" "$S25/d88e_probes/src l17" "$S25/review_r1A_d88e/probes/src r03" "$S25/review_r1B_d88e/probes/src za" "$S25/review_r1B_d88e/probes/src zb" "$S25/review_r1B_d88e/probes/src zf" "$S25/review_r1B_d88e/probes/src zi" "$S25/review_r1B_d88e/probes/src zm" "$S25/review_r1B_d88e/probes/src zxd" "$S25/review_r1B_d88e/probes/src zj" "$S28 lv" "$S28 li" "$S28 zk"; do
  set -- $spec; d=$1; b=$2
  for args in "-3 11" "40 1"; do
    for X in C T; do
      cp -f $d/$b$X.c pr/${b}${X}.c; lib=""; [ -f $d/$b$X.lib.c ] && { cp -f $d/$b$X.lib.c pr/${b}${X}.lib.c; lib=pr/${b}${X}.lib.c; }
      ./run.sh S pr/${b}${X}.c $lib -- $args > pr/${b}${X}.out 2>&1
    done
    vc=$(sed -n 1p pr/${b}C.out | cut -c1-40); vt=$(sed -n 1p pr/${b}T.out | cut -c1-40)
    if diff <(sed 1,2d pr/${b}C.out) <(sed 1,2d pr/${b}T.out) >/dev/null; then r="TRACE-IDENTICAL ($(sed 1,2d pr/${b}C.out | wc -l | tr -d ' ') lines)"; else r="TRACE-DIFF"; fi
    echo "$b [$args] C:{$vc} T:{$vt} $r  2b:$(grep -o '[0-9]* violation(s), [0-9]* unproven' pr/${b}C.out)|$(grep -o '[0-9]* violation(s), [0-9]* unproven' pr/${b}T.out)"
  done
done
