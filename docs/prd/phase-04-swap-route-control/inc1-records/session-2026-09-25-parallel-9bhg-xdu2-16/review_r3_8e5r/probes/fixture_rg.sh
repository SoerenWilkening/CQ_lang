#!/bin/bash
# Run the two new fixtures' RUN lines verbatim (pipefail, as lit does) against each binary.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2
R=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r3rev
L=/usr/local/opt/llvm@19/bin
set -o pipefail
for F in lowering_reject_lift_resweep_spec_rebuilt_consumer.ll lowering_reject_lift_resweep_surviving_consumer.ll; do
  for B in c416 head ba80; do
    for i in 1 2 3; do
      "$L/not" "$R/bin/cq-opt.$B" -load-pass-plugin X -passes=cq-lowering -S "$W/ir-pass/test/$F" 2>&1 | "$L/FileCheck" "$W/ir-pass/test/$F" > /dev/null 2>&1
      rc=$?
      echo "$F $B run$i rc=$rc $([ $rc -eq 0 ] && echo PASS || echo FAIL)"
    done
  done
  for M in lifo nofree; do
    CQ_OPT_DEBUG_ALLOC=$M "$L/not" "$R/bin/cq-opt-debugalloc.head" -passes=cq-lowering -S "$W/ir-pass/test/$F" 2>&1 | "$L/FileCheck" "$W/ir-pass/test/$F" > /dev/null 2>&1
    rc=$?
    echo "$F head-debugalloc-$M rc=$rc $([ $rc -eq 0 ] && echo PASS || echo FAIL)"
  done
done
# positive control for the harness: a fixture's RUN line against a binary that must FAIL it
# (feed the new fixture's CHECK a module that ACCEPTS: p2_N)
"$L/not" "$R/bin/cq-opt.head" -passes=cq-lowering -S "$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/review_r2_delta_8e5r/probes/p2_liftskip_verdict/p2_N.ll" 2>&1 | "$L/FileCheck" "$W/ir-pass/test/lowering_reject_lift_resweep_spec_rebuilt_consumer.ll" > /dev/null 2>&1
rc=$?
echo "HARNESS POSITIVE CONTROL (p2_N through the fixture's checks; must FAIL): rc=$rc $([ $rc -eq 0 ] && echo PASS-BAD || echo FAIL-ok)"
