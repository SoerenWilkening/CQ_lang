; control_inplace_ry_alias_chain_consumed.ll — ACCEPT spec: a register the arm
; rotates in place, read only through the merge φ (control-in-place-PRD §4 R6;
; bd test_C_libtooling-drbq Inc 1, finding J's positive control).
;
;     if (q > 5) cq_theta(&r, .9);
;     use(cq_measure(r));
;
; ⚠ THE ALIAS CHAIN IS GONE. The file was written for a DIAGONAL ALIAS CHAIN the
; arm fully consumes (pre-3qlq register form `int mark = cq_phi(r, .1); int r2 =
; cq_phi(mark, .2);`: three SSA names for one rail, every member's user provably
; before the branch), the control that kept finding J's closure widening a fence
; rather than an "any alias declines" ban. The 3qlq migration deleted both
; uncontrolled phases, so the module is now the plain control-in-place diamond.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r    = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c    = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %d  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %d
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; (pre-3qlq the two diagonal alias hops lowered in place on this rail here)
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  cqrt_cswap
; CHECK-NOT:  phi i32
