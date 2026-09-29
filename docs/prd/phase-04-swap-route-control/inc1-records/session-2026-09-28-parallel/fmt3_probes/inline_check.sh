#!/bin/bash
# Does the header (original vs nomerge) or the spelling (if/else vs ternary) decide whether
# `slice` is inlined into `main`? (It only changes the lowered IR's copy count, never the trace.)
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/fmt3
L=/usr/local/opt/llvm@19/bin
T=$(mktemp -d)
for inc in "$S/orig_inc" "$W/include"; do
  for s in slice_control_angle_select_ry_derived_base slice_control_angle_select_ry_derived_base_ternary slice_control_angle_select_ry slice_control_angle_select_ry_ternary slice_control_angle_select_ry_ne slice_control_angle_select_ry_ne_ternary; do
    "$L/clang" -I"$inc" -include CQ.h -O1 -emit-llvm -S "$W/tests/e2e/$s.c" -o "$T/t.ll"
    echo "$(basename "$(dirname "$inc/x")") $s main-calls-slice=$(grep -c 'call i32 @slice' "$T/t.ll")"
  done
done
rm -rf "$T"
