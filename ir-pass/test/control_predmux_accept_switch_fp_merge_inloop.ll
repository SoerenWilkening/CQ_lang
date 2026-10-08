; control_predmux_accept_switch_fp_merge_inloop.ll — ACCEPT (bd test_C_libtooling-dm7f.17, review round 2).
; The FP switch of control_predmux_accept_switch_fp_merge.ll inside a classically-bounded
; loop, measured every trip (clang -O1 of
;   for (int i = 0; i < c; i++) { double y = (double)(q + i);
;     switch (q) { case 1: y *= 3.0; break; case 2: y += 7.0; break; default: break; }
;     out += (int)cq_measure(y); }).
; PredMux's W8 claims the switch and E2 admits a region strictly inside one loop body, so
; it flattens per trip to the same select network as the straight-line accept; the 4.5
; path's "no in-loop switch" decline (ControlDetect.cpp) is never reached. Per trip the
; flags are uncomputed and freed; the f64 rails stay allocated, measured, as in the
; straight-line form. The LOOP-CARRIED form (an accumulator updated across trips) still
; declines `loop-carried tainted value crosses iterations` (a separate gap).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @main(
; CHECK:       %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(
; CHECK:       %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 2)
; CHECK:       call void @cqrt_copy_f64_controlled(i32 %[[F2]],
; CHECK:       %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:       %[[O:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[Y]], i32 %[[O]])
; CHECK:       call void @cqrt_free(i32 %[[G]])
; CHECK:       call double @cqrt_measure_f64(i32 %[[O]])
; CHECK-NOT:   switch

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare double @cq_measure_f64(double noundef)

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %16, %2
  %6 = phi i32 [ 0, %2 ], [ %20, %16 ]
  ret i32 %6

7:                                                ; preds = %2, %16
  %8 = phi i32 [ %21, %16 ], [ 0, %2 ]
  %9 = phi i32 [ %20, %16 ], [ 0, %2 ]
  %10 = add nsw i32 %8, %3
  %11 = sitofp i32 %10 to double
  switch i32 %3, label %16 [
    i32 1, label %12
    i32 2, label %14
  ]

12:                                               ; preds = %7
  %13 = fmul double %11, 3.000000e+00
  br label %16

14:                                               ; preds = %7
  %15 = fadd double %11, 7.000000e+00
  br label %16

16:                                               ; preds = %7, %14, %12
  %17 = phi double [ %11, %7 ], [ %15, %14 ], [ %13, %12 ]
  %18 = tail call double @cq_measure_f64(double noundef %17)
  %19 = fptosi double %18 to i32
  %20 = add nsw i32 %9, %19
  %21 = add nuw nsw i32 %8, 1
  %22 = icmp eq i32 %21, %0
  br i1 %22, label %5, label %7
}
