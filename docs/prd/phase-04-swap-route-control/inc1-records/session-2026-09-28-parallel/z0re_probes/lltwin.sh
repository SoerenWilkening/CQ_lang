#!/bin/bash
# lltwin.sh <cq-opt> <side-door.ll> <twin.ll> : lower both, STRICT 2b, link, run with
# args "5 7" and "2 9", byte-compare the traces (the hand-IR side-door pairs).
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
L=/usr/local/opt/llvm@19/bin
OPT=$1; A=$2; B=$3
T=$(mktemp -d)
for x in A B; do
  src=${!x}
  "$OPT" -passes=cq-lowering -S "$src" -o "$T/$x.s2.ll" 2> "$T/$x.err" || { echo "$x DECLINED: $(head -1 "$T/$x.err")"; exit 1; }
  echo "$x 2b: $(python3 "$W/tools/free_pairing_check.py" "$T/$x.s2.ll" 2>&1 | tail -1)"
  "$L/clang" "$T/$x.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$T/$x.exe" 2>/dev/null
done
v=SAME
for args in "5 7" "2 9"; do
  # shellcheck disable=SC2086
  "$T/A.exe" $args > "$T/A.trace"; "$T/B.exe" $args > "$T/B.trace"
  cmp -s "$T/A.trace" "$T/B.trace" || v=DIFF
  echo "args $args: $(wc -l < "$T/A.trace" | tr -d ' ') lines"
done
echo "trace: $v"
rm -rf "$T"
