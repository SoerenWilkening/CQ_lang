#!/bin/bash
# The COMMITTED include/CQ.h vs the Phase-1 measured nomerge variant: stage-1 IR must be
# byte-identical (modulo ModuleID/source_filename) on every probe, so Phase-1's measurements
# carry over to the shipped header.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
L=/usr/local/opt/llvm@19/bin
NM=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3/inc_nomerge
O=$(mktemp -d)
n=0; d=0
for c in "$W"/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/fmt3_probes/src/*.c "$W"/tests/e2e/slice_control_angle_select_ry*.c; do
  "$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$c" -o "$O/a.ll" || { echo "COMPILE FAIL committed $c"; continue; }
  "$L/clang" -I"$NM" -include CQ.h -O1 -emit-llvm -S "$c" -o "$O/b.ll" || { echo "COMPILE FAIL variant $c"; continue; }
  n=$((n+1))
  if ! diff <(grep -v '^; ModuleID\|^source_filename' "$O/a.ll") <(grep -v '^; ModuleID\|^source_filename' "$O/b.ll") > /dev/null; then
    d=$((d+1)); echo "DIFFERS $c"
  fi
done
echo "hdr_equiv: $n sources compiled with both headers, $d differ"
rm -rf "$O"
