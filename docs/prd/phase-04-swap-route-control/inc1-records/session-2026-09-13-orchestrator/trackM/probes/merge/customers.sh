#!/bin/bash
# customers.sh — the landing-3 customers (MERGE_BRIEF_M.md step 7), full four-stage
# PROTOCOL.md pipeline on the MERGED binary: clang -O1 -g | cq-opt | free_pairing_check
# (STRICT) | link (templates BEFORE runtime) | run.
# Prints, per customer: exit code, stderr byte count, the stage-2b line, the trace line
# count, and — where a golden is named as $2 — the byte-diff against it.
set -u
LLVM=/usr/local/opt/llvm@19/bin
R=/Users/sorenwilkening/Desktop/CQ_mphi
SES=$R/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator
one() {
  local src=$1 golden=${2:-}
  local T; T=$(mktemp -d)
  ( cd "$R" && "$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S "$src" -o "$T/s1.ll" ) 2>"$T/c.err" || {
    echo "$(basename "$src"): CLANGERR"; rm -rf "$T"; return; }
  "$R/build/ir-pass/cq-opt" -load-pass-plugin "$R/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2>"$T/o.err"; local rc=$?
  local bytes; bytes=$(wc -c < "$T/o.err" | tr -d ' ')
  if [ $rc -ne 0 ]; then
    echo "$(basename "$src"): DECLINE exit=$rc stderr=${bytes}B  $(grep -oE 'error: .*' "$T/o.err" | head -1)"
    rm -rf "$T"; return
  fi
  local b2b; b2b=$( cd "$R" && python3 tools/free_pairing_check.py "$T/s2.ll" 2>&1 | tail -1 )
  "$LLVM/clang" "$T/s2.ll" "$R/build/runtime/libcq_templates.a" "$R/build/runtime/libcq_runtime.a" \
      -o "$T/a" 2>"$T/l.err" || { echo "$(basename "$src"): LINKFAIL"; rm -rf "$T"; return; }
  "$T/a" > "$T/trace" 2>/dev/null
  local n; n=$(wc -l < "$T/trace" | tr -d ' ')
  local d="(no golden named)"
  if [ -n "$golden" ]; then
    if cmp -s "$T/trace" "$golden"; then d="BYTE-IDENTICAL to $(basename "$golden")"
    else d="DIFFERS from $(basename "$golden"): $(diff "$golden" "$T/trace" | head -4 | tr '\n' ' ')"; fi
  fi
  echo "$(basename "$src"): ACCEPT exit=0 stderr=${bytes}B | 2b: $b2b | ${n} lines | $d"
  cp "$T/trace" "/tmp/cust_$(basename "$src" .c).trace" 2>/dev/null
  rm -rf "$T"
}
one "$SES/probes/owner_file_2026-09-13.c"                     "$R/tests/e2e/slice_control_cascade_two_bools.expected.log"
one "$SES/probes/va.c"                                        "$SES/probes/va.trace"
one "$SES/probes/vb.c"
one "$SES/probes/vc.c"
one "$SES/probes/vd.c"
one "$SES/trackR/probes/v_vd_guard_neg.c"
one "$SES/trackM/probes/m16.c"
one "$SES/trackM/probes/impl/i2_cmpladder.c"
one "$SES/trackR/probes/b_A_intb0_boolb1.c"                   "$R/tests/e2e/slice_control_stateprep_bool_under_int_compare_fused.expected.log"
one "$SES/trackC/probes/owner_2026-09-11_2218.c"              "$R/tests/e2e/slice_measure_classical_bool.expected.log"
# The brief names `$SES/trackR/review_R1_r1_probes`' G6 as well; it does not exist —
# `find $S -name G6_quantum_mux_values.c` returns exactly ONE path, the 2026-09-11
# integration probe, which is also the module Track M pinned as the fixture
# control_swap_accept_select_mergephi_quantum_arm_then_prep.ll.
one "$SES/../session-2026-09-11-orchestrator/review_integration_probes/G6_quantum_mux_values.c"
one "$SES/probes/ve.c"
