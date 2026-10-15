; control_inplace_ry_seq_counter_prepped.ll — ACCEPT: the Dicke counter spelling, prepped target.
;
; bd test_C_libtooling-dm7f.53 (CQ_FINDINGS F3), the compare-conditioned twin:
;   int x (rotated); bool t; cq_theta(&t,.1);
;   if (x == 0) cq_theta(&t,.3); if (x == 1) cq_theta(&t,.7);
; Each region mints its own eq flag (`_hl` compare template), fires
; `cqrt_ry_i1_controlled` on t's rail and strips + frees the flag (proven |0>).
; x=0: Ry(.4); x=1: Ry(.8); otherwise Ry(.1). The UNPREPPED spelling (t = 0)
; declines F2 — see control_inplace_ry_reject_seq_counter_stateprep_f2.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.d53.ll
; RUN: %filecheck %s < %t.d53.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.d53.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.d53.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.d53.ll

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 1.000000e-01)
  %3 = icmp eq i32 %1, 0
  br i1 %3, label %4, label %6

4:
  %5 = call i1 @cq_theta_i1(i1 %2, double 3.000000e-01)
  br label %6

6:
  %7 = phi i1 [ %5, %4 ], [ %2, %0 ]
  %8 = icmp eq i32 %1, 1
  br i1 %8, label %9, label %11

9:
  %10 = call i1 @cq_theta_i1(i1 %7, double 0x3FE6666666666666)
  br label %11

11:
  %12 = phi i1 [ %10, %9 ], [ %7, %6 ]
  %13 = call i32 @cq_measure_si32(i32 %1)
  %14 = call i1 @cq_measure_i1(i1 %12)
  %15 = zext i1 %14 to i32
  %16 = add nsw i32 %13, %15
  ret i32 %16
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H1]], double 1.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H0]], i32 0)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H2]], i32 %[[H1]], double 3.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H2]], i32 %[[H0]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H2]])
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H0]], i32 1)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H3]], i32 %[[H1]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H3]], i32 %[[H0]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H3]])
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H0]])
; CHECK-NEXT: %[[H5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])
;
; Whole-file, pure negatives (a positive in a prefix windows the negatives
; after it): no route / copy / adjoint gate, every arm theta and region phi
; consumed; FCNT/CRCNT count the frees and the controlled Ry gates.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: call i1 @cq_theta
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = trunc
; NOROUTE-NOT: zext i1 {{.*}} to i8
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CRCNT-COUNT-2: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
