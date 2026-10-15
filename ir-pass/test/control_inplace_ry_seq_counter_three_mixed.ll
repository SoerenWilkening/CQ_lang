; control_inplace_ry_seq_counter_three_mixed.ll — ACCEPT: three ordering siblings, two forced, one overlapping.
;
; bd test_C_libtooling-dm7f.53, amended delegated ruling
; `ruling-dm7f53-p4-sibling-cond-prep-amend-forced-2026-10-15`: F2's fourth
; exclusion (`siblingConditionCompareOnWire`) is predicate-agnostic — any
; icmp of a CondWire register against a literal, used only as branch
; conditions, whose value F2's own LVI edge pin forces to the CONSTANT seed.
; The rival `t = V` then holds V's forced value on every branch the arm runs
; in: the identity on the seed. Since `…-amend-straight-through-2026-10-15`
; the pin may be on EITHER edge; fcmp, off-wire registers, data-used compares
; and non-constant seeds stay loud.
;
;   if (x < 3) Ry(t,.3); if (x < 5) Ry(t,.5); if (x > 5) Ry(t,.7);
; Region 1's colliders: `x > 5` (forced false, excluded); `x < 5` forced TRUE
; (no collision). x<3 -> Ry(.8); 3<=x<5 -> Ry(.5); x>5 -> Ry(.7); x==5 -> |0>.
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
  %2 = icmp slt i32 %1, 3
  br i1 %2, label %3, label %6

3:
  %4 = call i1 @cq_theta_i1(i1 false, double 3.000000e-01)
  %5 = zext i1 %4 to i8
  br label %6

6:
  %7 = phi i8 [ %5, %3 ], [ 0, %0 ]
  %8 = icmp slt i32 %1, 5
  br i1 %8, label %9, label %13

9:
  %10 = trunc nuw i8 %7 to i1
  %11 = call i1 @cq_theta_i1(i1 %10, double 5.000000e-01)
  %12 = zext i1 %11 to i8
  br label %13

13:
  %14 = phi i8 [ %12, %9 ], [ %7, %6 ]
  %15 = icmp sgt i32 %1, 5
  br i1 %15, label %16, label %20

16:
  %17 = trunc nuw i8 %14 to i1
  %18 = call i1 @cq_theta_i1(i1 %17, double 0x3FE6666666666666)
  %19 = zext i1 %18 to i8
  br label %20

20:
  %21 = phi i8 [ %19, %16 ], [ %14, %13 ]
  %22 = call i32 @cq_measure_si32(i32 %1)
  %23 = trunc nuw i8 %21 to i1
  %24 = call i1 @cq_measure_i1(i1 %23)
  %25 = zext i1 %24 to i32
  %26 = add nsw i32 %22, %25
  ret i32 %26
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H0]], i32 3)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H1]], i32 %[[H2]], double 3.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[H1]], i32 %[[H0]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H1]])
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H0]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H3]], i32 %[[H2]], double 5.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[H3]], i32 %[[H0]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H3]])
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H0]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H4]], i32 %[[H2]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H4]], i32 %[[H0]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H4]])
; CHECK-NEXT: %[[H5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H0]])
; CHECK-NEXT: %[[H6:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
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
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CRCNT-COUNT-3: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
