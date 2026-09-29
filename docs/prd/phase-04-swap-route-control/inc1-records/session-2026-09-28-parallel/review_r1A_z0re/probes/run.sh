#!/bin/bash
# r1A probe runner.  run.sh <name> [args...]
#   src/<name>.c (+ src/<name>.lib.c, plain C, linked) or src/<name>.ll (hand IR).
#   Runs ORACLE and SUBJECT; for each ACCEPT runs stage 2b STRICT, links, runs with args.
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
L=/usr/local/opt/llvm@19/bin
P=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r1A_z0re/probes
ORA=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646
SUB=${SUB:-$W/build/ir-pass/cq-opt}
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
n=$1; shift
O=$P/out; mkdir -p $O
if [ -f "$P/src/$n.ll" ]; then cp -f "$P/src/$n.ll" "$O/$n.s1.ll"; else
  "$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$P/src/$n.c" -o "$O/$n.cq.ll" || exit 9
  if [ -f "$P/src/$n.lib.c" ]; then
    "$L/clang" -I"$W/include" -O1 -emit-llvm -S "$P/src/$n.lib.c" -o "$O/$n.lib.ll" || exit 9
    "$L/llvm-link" -S "$O/$n.cq.ll" "$O/$n.lib.ll" -o "$O/$n.s1.ll" || exit 9
  else cp -f "$O/$n.cq.ll" "$O/$n.s1.ll"; fi
fi
[ -s "$O/$n.s1.ll" ] || { echo "EMPTY s1"; exit 9; }
for who in ORA SUB; do
  B=$ORA; [ $who = SUB ] && B=$SUB
  "$B" -passes=cq-lowering -S "$O/$n.s1.ll" -o "$O/$n.$who.s2.ll" 2> "$O/$n.$who.err"; rc=$?
  if [ $rc != 0 ]; then
    echo "$n $who DECLINE rc=$rc [$(grep -m1 -o 'error: .*' "$O/$n.$who.err" | cut -c1-150)]"
  else
    w=$(grep -c 'warning' "$O/$n.$who.err")
    s2=$(python3 "$W/tools/free_pairing_check.py" "$O/$n.$who.s2.ll" 2>&1 | tail -2 | tr '\n' ' ')
    "$L/clang" "$O/$n.$who.s2.ll" "$TPL" "$RT" -o "$O/$n.$who.exe" 2>/dev/null
    "$O/$n.$who.exe" "$@" > "$O/$n.$who.trace" 2>&1
    echo "$n $who ACCEPT warnings=$w trace=$(wc -l < "$O/$n.$who.trace" | tr -d ' ') 2b=[$s2]"
  fi
done
