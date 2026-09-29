#!/bin/bash
# The three e2e sources whose stage 1 moves under the option-(B) nomerge header (the Ry-stem
# angle-select slices): stage 2 on the ORACLE, STRICT 2b, link, run, diff against the golden.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
L=/usr/local/opt/llvm@19/bin
NM=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3/inc_nomerge
O=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3/asel
ORA=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646
mkdir -p "$O"
for n in slice_control_angle_select_ry slice_control_angle_select_ry_derived_base slice_control_angle_select_ry_ne; do
  "$L/clang" -I"$NM" -include CQ.h -O1 -emit-llvm -S "$W/tests/e2e/$n.c" -o "$O/$n.B.s1.ll"
  "$ORA" -passes=cq-lowering -S "$O/$n.B.s1.ll" -o "$O/$n.B.s2.ll" 2> "$O/$n.err"; rc=$?
  echo "== $n stage2 rc=$rc"
  python3 "$W/tools/free_pairing_check.py" "$O/$n.B.s2.ll" | tail -1
  "$L/clang" "$O/$n.B.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$O/$n.B.exe" 2>/dev/null
  "$O/$n.B.exe" > "$O/$n.B.trace"
  diff "$W/tests/e2e/$n.expected.log" "$O/$n.B.trace"
done
