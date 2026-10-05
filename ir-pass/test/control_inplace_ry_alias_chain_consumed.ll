; control_inplace_ry_alias_chain_consumed.ll — ACCEPT spec: an ALIAS CHAIN that
; the arm FULLY CONSUMES (control-in-place-PRD §4 R6; bd test_C_libtooling-drbq
; Inc 1, finding J's positive control). `clang -O1` output (attribute groups and
; metadata trimmed) for
;
;     int example(int u0, int u1) {
;       int q = u0; cq_theta(&q, 0.5);
;       int r = u1; cq_theta(&r, 0.3);
;       cq_theta(&r, 0.1);              /* alias hop 1, in place */
;       cq_theta(&r, 0.2);              /* alias hop 2, in place */
;       if (q > 5) cq_theta(&r, 0.9);   /* the controlled Ry on the last name */
;       return cq_measure(r);
;     }
;
; `%4`, `%5` and `%6` are three SSA names for ONE physical rail (each hop is an
; in-place Ry, lowered on the same handle), so R6's alias closure has three
; members, and the region still ACCEPTS, because every member's every user is
; either the next hop in the chain (pre-region, hence provably before the
; branch), the arm's own gate, or the merge φ. NOTHING reads a record the
; controlled Ry invalidates.
;
; This is the control that makes finding J's fix a fence rather than a ban: the
; closure widening must decline the stale-alias shapes
; (control_inplace_ry_reject_stale_measure.ll and its siblings) and leave this
; one lowering. Without it the fix could have been "any alias declines", which
; would take the whole gate-then-controlled-gate idiom with it.
;
; History: pre-3qlq the two hops were the register form `int mark = cq_phi(r,
; .1); int r2 = cq_phi(mark, .2);` (in-place Rz). The 3qlq migration deleted
; both as uncontrolled phases, which left the module equal to
; control_inplace_ry_alias_after_region.ll; bd jttf (2026-10-05) re-spelled the
; hops as the in-place Ry gates above.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; the two hops lower IN PLACE on %[[R]] — that is what makes them aliases
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; then the region, on the same rail, after both hops:
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: ret i32 %[[M]]
;
; NEG-NOT: cqrt_cswap
; NEG-NOT: phi i32
; NEG-NOT: cq_theta_si32
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define i32 @example(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 1.000000e-01) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 2.000000e-01) #2
  %7 = icmp sgt i32 %3, 5
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 9.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %2
  %11 = phi i32 [ %9, %8 ], [ %6, %2 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
