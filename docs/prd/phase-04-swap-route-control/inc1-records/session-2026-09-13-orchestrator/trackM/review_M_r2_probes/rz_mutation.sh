#!/bin/bash
# round-2 review — the RZ-TARGET / RZ-ANGLE mutation the fix's 8-mutation
# injection matrix does not contain, applied to the ONE Track M accept fixture
# that emits a `cqrt_rz_i1` (the F-M1 fixture, whose third construct IS the
# branch phase).  Every prefix the fixture declares is run against the mutant.
set -u
L=/usr/local/opt/llvm@19/bin
R=/Users/sorenwilkening/Desktop/CQ_mphi
SCR=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/ddf48412-8498-4d8b-9bac-51279fb090c0/scratchpad/trackM_review2
F=$R/ir-pass/test/control_swap_accept_select_mergephi_rail_then_kickback.ll
"$R/build/ir-pass/cq-opt" -load-pass-plugin "$R/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$F" > "$SCR/rzbase.ll"
prefixes="CHECK NOROUTE NOX NOFREE XCNT FCNT CNOTCNT CPCNT RYCNT RZCNT ACNT"
run_all() {  # $1 = file, $2 = label
  local caught=""
  for p in $prefixes; do
    "$L/FileCheck" "$F" --check-prefix=$p < "$1" >/dev/null 2>&1 || caught="$caught,$p"
  done
  echo "  $2 -> ${caught:+caught by${caught#,}}${caught:-** MISSED (every prefix still green) **}"
}
run_all "$SCR/rzbase.ll" "unmutated control (must be MISSED = all green)"
sed 's#@cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01)#@cqrt_rz_i1(i32 %h, double 3.000000e-01)#' "$SCR/rzbase.ll" > "$SCR/rz_target.ll"
cmp -s "$SCR/rzbase.ll" "$SCR/rz_target.ll" && echo "  !! rz-target mutation did not apply"
run_all "$SCR/rz_target.ll" "rz-on-user-register (%h_cmp -> %h, the b0 rail)"
sed 's#@cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01)#@cqrt_rz_i1(i32 %h4, double 3.000000e-01)#' "$SCR/rzbase.ll" > "$SCR/rz_target2.ll"
run_all "$SCR/rz_target2.ll" "rz-on-user-register (%h_cmp -> %h4, the prepped b1 rail)"
sed 's#@cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01)#@cqrt_rz_i1(i32 %h_cmp, double 9.000000e-01)#' "$SCR/rzbase.ll" > "$SCR/rz_angle.ll"
run_all "$SCR/rz_angle.ll" "rz-angle-changed (0.3 -> 0.9)"
sed 's#@cqrt_rz_i1(i32 %h_cmp, double 3.000000e-01)#@cqrt_rz_i1(i32 %out3, double 3.000000e-01)#' "$SCR/rzbase.ll" > "$SCR/rz_out.ll"
run_all "$SCR/rz_out.ll" "rz-on-the-merge-out-rail (%h_cmp -> %out3, the user's a)"
