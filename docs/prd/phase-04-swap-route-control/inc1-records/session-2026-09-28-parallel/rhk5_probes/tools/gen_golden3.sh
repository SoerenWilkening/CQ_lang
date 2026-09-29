#!/bin/bash
# gen_golden3.sh SLICE LIB|- : build tests/e2e/SLICE.c (+LIB) on oracle, round 1
# (subject_v2) and round 2 (r2); print 2b + warnings, the cross-binary trace
# comparisons, and write the r2 trace to results/goldens/SLICE.r2.log.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5
G="$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes/tools/gen_golden.sh"
O="$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes/results/goldens"
mkdir -p "$O"
n=$1; lib=$2
L=""; [ "$lib" != "-" ] && L="$W/tests/e2e/$lib"
for b in oracle subject_v2 r2; do
  bash "$G" "$S/bin/cq-opt.$b" "$W/tests/e2e/$n.c" $L > "$O/$n.$b.log" 2> "$O/$n.$b.err"
  echo "[$b] rc=$? $(grep -h free_pairing "$O/$n.$b.err" | sed 's/.*mint(s) of which/left/') warn=$(grep -c 'warning: <' "$O/$n.$b.err")"
done
cmp -s "$O/$n.r2.log" "$O/$n.oracle.log" && echo "r2 trace == oracle trace" || echo "r2 trace != oracle trace"
cmp -s "$O/$n.subject_v2.log" "$O/$n.oracle.log" && echo "r1 trace == oracle trace" || echo "r1 trace != oracle trace"
