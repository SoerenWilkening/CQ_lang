; control_swap_reject_select_phase_sibling_alias_i32.ll — DECLINE: the INTEGER
; twin of control_swap_reject_select_fp_phase_sibling_alias.ll (kjd1 clearance
; probe a2b). The gate-5 SSA-anchoring hole predates the fp un-staging (the
; 4.4/WI-5 clearance was rendered over direct-lineage spellings only), so the
; wire-anchored fix covers both type families; this pins the integer side.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q0  = call i32 @cq_theta_si32(i32 %u0, double 1.000000e+00)
  %p   = call i32 @cq_phi_si32(i32 %q0, double 7.000000e-01)   ; Rz on the OLD alias
  %q1  = call i32 @cq_theta_si32(i32 %q0, double 5.000000e-01) ; rebase: same handle
  %c   = icmp sgt i32 %q1, 5
  %sel = select i1 %c, i32 %q1, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  %m2  = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
