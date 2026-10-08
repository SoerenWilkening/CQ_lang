; control_predmux_accept_switch_fp_merge.ll — ACCEPT (bd test_C_libtooling-dm7f.17).
; A tainted `switch` whose merge phi is `double` DATA. clang -O1 of
;   int q = c; cq_theta(&q, .5); double y = (double)q;
;   switch (q) { case 1: y = y * 3.0; break; case 2: y = y + 7.0; break; default: break; }
;   return (int)cq_measure(y);
; At e0af16ed this declined `control flow under quantum control` at SwitchClassify
; G4, whose type-only rule read every fp merge as an angle. Owner ruling 2026-10-08
; (CLAUDE.md R3): fp merge values can carry quantum data; angle use is decided at the
; rotation consumers. PredMux now claims the switch (witness W8, the switch analogue
; of W5: no 4.5 owner accepts an fp merge), flattens it to a select chain, and the
; kjd1 fp controlled-copy merge lowers it. Traced by hand: q==1 → y*3, q==2 → y+7,
; otherwise (double)q.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @main(
; CHECK:       %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(
; CHECK-DAG:   %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %[[Y]], double 7.000000e+00)
; CHECK-DAG:   %[[MUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f64_hl(i32 %[[Y]], double 3.000000e+00)
; CHECK:       %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 2)
; CHECK:       %[[O1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[F2]], i32 %[[ADD]], i32 %[[O1]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[F2]], i32 %[[MUL]], i32 %[[O1]])
; CHECK:       %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:       %[[O2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[Y]], i32 %[[O2]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[O1]], i32 %[[O2]])
; CHECK:       call double @cqrt_measure_f64(i32 %[[O2]])
; CHECK-NOT:   switch

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare double @cq_measure_f64(double noundef)

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = sitofp i32 %3 to double
  switch i32 %3, label %9 [
    i32 1, label %5
    i32 2, label %7
  ]
5:
  %6 = fmul double %4, 3.000000e+00
  br label %9
7:
  %8 = fadd double %4, 7.000000e+00
  br label %9
9:
  %10 = phi double [ %4, %2 ], [ %8, %7 ], [ %6, %5 ]
  %11 = tail call double @cq_measure_f64(double noundef %10)
  %12 = fptosi double %11 to i32
  ret i32 %12
}
