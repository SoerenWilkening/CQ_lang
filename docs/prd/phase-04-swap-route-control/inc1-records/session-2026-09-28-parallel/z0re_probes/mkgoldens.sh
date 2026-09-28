#!/bin/bash
# Generate (or check, with --check) the z0re e2e goldens by the run_slice(.sh|_multi.sh)
# recipe by hand: clang -O1 -include CQ.h [+ plain lib, llvm-link] -> cq-opt ->
# free_pairing_check (STRICT) -> clang link (templates before runtime) -> run (no args).
# usage: mkgoldens.sh <cq-opt> [--check]
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
L=/usr/local/opt/llvm@19/bin
E=$W/tests/e2e
OPT=$1; MODE=${2:-gen}
T=$(mktemp -d)
one() {  # $1 = slice basename (no .c), $2 = optional lib basename
  local s=$1 lib=${2:-}
  "$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$E/$s.c" -o "$T/$s.cq.ll" || { echo "$s STAGE1-FAIL"; return; }
  local in="$T/$s.cq.ll"
  if [ -n "$lib" ]; then
    "$L/clang" -I"$W/include" -O1 -emit-llvm -S "$E/$lib.c" -o "$T/$s.lib.ll"
    "$L/llvm-link" -S "$T/$s.cq.ll" "$T/$s.lib.ll" -o "$T/$s.s1.ll"; in="$T/$s.s1.ll"
  fi
  if ! "$OPT" -passes=cq-lowering -S "$in" -o "$T/$s.s2.ll" 2> "$T/$s.err"; then
    echo "$s DECLINED: $(grep -m1 -o 'lowering: .*' "$T/$s.err")"; return
  fi
  local b2; b2=$(python3 "$W/tools/free_pairing_check.py" "$T/$s.s2.ll" 2>&1 | tail -1)
  "$L/clang" "$T/$s.s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" -o "$T/$s.exe" 2>/dev/null
  "$T/$s.exe" > "$T/$s.trace"
  if [ "$MODE" = --check ]; then
    if cmp -s "$T/$s.trace" "$E/$s.expected.log"; then echo "$s MATCH  [$b2]"; else echo "$s DIFF"; fi
  else
    cp -f "$T/$s.trace" "$E/$s.expected.log"
    echo "$s WROTE $(wc -l < "$T/$s.trace" | tr -d ' ') lines  [$b2]"
  fi
  if [ -s "$T/$s.err" ]; then echo "   stderr: $(head -1 "$T/$s.err")"; fi
}
one slice_z0re_runtime_seed_prep
one slice_z0re_runtime_seed_prep_spec spec_lift_classical_lib
one slice_z0re_angle_select_runtime_base
one slice_z0re_angle_select_runtime_base_spec spec_lift_classical_lib
one slice_z0re_runtime_seed_loop
one slice_z0re_runtime_seed_loop_unrolled
one slice_z0re_runtime_seed_f64
rm -rf "$T"
