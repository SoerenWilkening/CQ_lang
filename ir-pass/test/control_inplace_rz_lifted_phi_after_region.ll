; control_inplace_rz_lifted_phi_after_region.ll — ACCEPT. The STEM-DIFFERENTIAL
; CONTROL for `control_inplace_ry_lifted_phi_after_region.ll`: the identical
; program with an **Rz** arm (the Inc-2a control-in-place peephole, which keeps
; M-α and RAUWs the region merge φ to the BASE).
;
; bd test_C_libtooling-drbq Increment 3, round-1 Rule-13 review finding F-L5-1.
; This half accepted before the increment, during it, and after the fix — it is
; committed so the pair is a STANDING witness that the two stems agree on this
; shape, and so a future change to `resolveWireBase`'s `ControlledRotations`
; stop cannot move one stem without the other going red.
;
; The lens isolated the regression with exactly this pair: the ONLY difference
; between the two programs is the arm's stem, and the only difference between
; the two stems in this window is the RAUW target (M-β's hoisted gate vs M-α's
; base). That left no other hypothesis standing.
;
; VERBATIM `clang -O1` output for
;   volatile int OPQ = 1;
;   int slice(void) { int q=3, r=7;
;                     q = cq_theta(q,0.5); r = cq_theta(r,0.25);
;                     if (q == 5)  { r = cq_phi(r, 0.9); }     /* Rz arm, M-α */
;                     if (OPQ)     { r = cq_phi(r, 0.5); }     /* 5j5 lift */
;                     return cq_measure(q) + cq_measure(r); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NOROUTE %s < %t.cqd0.ll

@OPQ = global i32 1, align 4

define i32 @slice() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01)
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_phi_si32(i32 noundef %2, double noundef 9.000000e-01)
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %8 = load volatile i32, ptr @OPQ, align 4
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %12, label %10

10:                                               ; preds = %6
  %11 = tail call i32 @cq_phi_si32(i32 noundef %7, double noundef 5.000000e-01)
  br label %12

12:                                               ; preds = %10, %6
  %13 = phi i32 [ %11, %10 ], [ %7, %6 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %13)
  %16 = add nsw i32 %15, %14
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_phi_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; The Inc-2a peephole: ONE controlled Rz in place, no route, no work rail.
; CHECK: %[[Q:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK: %[[R:h[0-9]*]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK: %[[F:h_cmp[0-9]*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK: br i1
; CHECK: call void @cqrt_rz_i32(i32 %[[R]], double 5.000000e-01)
; CHECK: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[R]])

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi_si
; NOROUTE-NOT: cq_measure_si
