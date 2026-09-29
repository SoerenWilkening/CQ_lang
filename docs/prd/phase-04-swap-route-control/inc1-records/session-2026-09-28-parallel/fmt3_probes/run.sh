#!/bin/bash
# fmt3 probe runner.   run.sh <name> [args...]
#   src/<name>.c  (plain C + CQ.h, clang -O1)  or  src/<name>.ll (hand IR).
#   Env:  INC=<dir holding CQ.h>   (default: the worktree's include/; set it to
#                                   a variant header dir to measure a frontend option)
#         TAG=<suffix>             (output-file tag, default "base")
#         SUB=<cq-opt>             (subject binary, default the worktree build)
#   Runs the frozen ORACLE and the SUBJECT; for each ACCEPT runs stage 2b STRICT,
#   links (templates BEFORE runtime) and runs with the given args.
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
L=/usr/local/opt/llvm@19/bin
P=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/fmt3_probes
ORA=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646
SUB=${SUB:-$W/build/ir-pass/cq-opt}
INC=${INC:-$W/include}
TAG=${TAG:-base}
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
n=$1; shift
O=$P/out; mkdir -p "$O"
S1="$O/$n.$TAG.s1.ll"
if [ -f "$P/src/$n.ll" ]; then cp -f "$P/src/$n.ll" "$S1"; else
  "$L/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$P/src/$n.c" -o "$S1" || exit 9
fi
[ -s "$S1" ] || { echo "EMPTY s1"; exit 9; }
WHO=${WHO:-"ORA SUB"}
for who in $WHO; do
  B=$ORA; [ "$who" = SUB ] && B=$SUB
  "$B" -passes=cq-lowering -S "$S1" -o "$O/$n.$TAG.$who.s2.ll" 2> "$O/$n.$TAG.$who.err"; rc=$?
  if [ $rc != 0 ]; then
    echo "$n[$TAG] $who DECLINE rc=$rc [$(grep -m1 -o 'error: .*' "$O/$n.$TAG.$who.err" | cut -c1-150)]"
  else
    w=$(grep -c 'warning' "$O/$n.$TAG.$who.err")
    s2=$(python3 "$W/tools/free_pairing_check.py" "$O/$n.$TAG.$who.s2.ll" 2>&1 | tail -2 | tr '\n' ' ')
    "$L/clang" "$O/$n.$TAG.$who.s2.ll" "$TPL" "$RT" -o "$O/$n.$TAG.$who.exe" 2>/dev/null
    "$O/$n.$TAG.$who.exe" "$@" > "$O/$n.$TAG.$who.trace" 2>&1
    echo "$n[$TAG] $who ACCEPT warnings=$w trace=$(wc -l < "$O/$n.$TAG.$who.trace" | tr -d ' ') 2b=[$s2]"
  fi
done
