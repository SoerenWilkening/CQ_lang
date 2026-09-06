; control_inplace_ry_alias_chain_consumed.ll — ACCEPT spec: a DIAGONAL ALIAS CHAIN
; that the arm FULLY CONSUMES (control-in-place-PRD §4 R6; bd
; test_C_libtooling-drbq Inc 1, finding J's positive control).
;
;     int mark = cq_phi(r, .1);
;     int r2   = cq_phi(mark, .2);
;     if (q > 5) r2 = cq_theta(r2, .9);
;     use(cq_measure(r2));
;
; `r`, `mark` and `r2` are three SSA names for ONE physical rail, so R6's alias
; closure has three members — and the region still ACCEPTS, because every member's
; every user is either the next hop in the chain (pre-region, hence provably before
; the branch), the arm's own gate, or the merge φ. NOTHING reads a record the
; controlled Ry invalidates.
;
; This is the control that makes finding J's fix a fence rather than a ban: the
; closure widening must decline the four `..._stale_diag_alias_*` shapes and leave
; this one lowering. Without it the fix could have been "any alias declines", which
; would take the whole `cq_phi`-then-`cq_theta` idiom with it.
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
; the two diagonal hops lower IN PLACE on %[[R]] — that is what makes them aliases
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  cqrt_cswap
; CHECK-NOT:  phi i32
