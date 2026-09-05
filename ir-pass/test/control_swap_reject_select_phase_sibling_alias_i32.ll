; control_swap_reject_select_phase_sibling_alias_i32.ll — DECLINE: the INTEGER
; twin of control_swap_reject_select_fp_phase_sibling_alias.ll (kjd1 clearance
; probe a2b). The gate-5 SSA-anchoring hole predates the fp un-staging (the
; 4.4/WI-5 clearance was rendered over direct-lineage spellings only), so the
; wire-anchored fix covers both type families; this pins the integer side.
;
;
; ===========================================================================
; 3qlq(prep_a2): HAND DECISION — RE-SPELLED. The ALIAS-REBASE evasion is a
; statement about SSA ANCHORING, not about phases: `%q1 = cq_theta(%q0, ...)` is
; a rebase that gives the SAME physical handle a NEW SSA name, so a gate-5 walk
; anchored on the SSA value the select names misses a rotation written against
; the OLD name. The original spelled the sibling gate as an Rz (`cq_phi`) because
; a DIAGONAL gate made the "same wire, different name" story cleanest; the
; anchoring hole itself never needed diagonality, and the rebase — the thing
; being evaded — is a `cq_theta` in both versions.
;
; RE-SPELLING: the select names `%q0` (the OLD alias) while the rebase `%q1` is
; the live handle, so the operand's wire is rotated under a different SSA name.
; MEASURED on `build/ir-pass/cq-opt`: exit 1, the same string this file always
; asserted ($SP/progress/prep_a2_work/pv/alias.ll).
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, i32 %x) {
entry:
  %q0  = call i32 @cq_theta_si32(i32 %u0, double 1.000000e+00)
  %q1  = call i32 @cq_theta_si32(i32 %q0, double 5.000000e-01) ; rebase: same handle, new name
  %y   = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c   = icmp sgt i32 %y, 5
  %sel = select i1 %c, i32 %q0, i32 %x        ; names the OLD alias of a live wire
  %m   = call i32 @cq_measure_si32(i32 %sel)
  %m2  = call i32 @cq_measure_si32(i32 %q1)
  %s   = add i32 %m, %m2
  ret i32 %s
}
