; control_inplace_ry_reject_seq_counter_f2_nonarm_edge.ll — **NOW AN ACCEPT**: a sibling pinned on the STRAIGHT-THROUGH edge.
;
; ⚠ The `reject_` in the name is history (bd `gahu` precedent, L8): e47edd90
; pinned this as outside the arm-edge scope; the straight-through amendment
; covers it.
;
; bd test_C_libtooling-dm7f.53, amended delegated ruling
; `ruling-dm7f53-p4-sibling-cond-prep-amend-straight-through-2026-10-15`: F2's
; sibling-condition exclusion (`siblingConditionCompareOnWire`) also covers a
; sibling compare that F2's own LVI edge pin forces to the seed on region 1's
; STRAIGHT-THROUGH (not-taken) edge. The -O1 rival `else t = V` is a
; controlled permutation whose control predicate (¬C ∧ V ≠ seed) is
; unsatisfiable on every basis state: the identity operator. Forcedness IS the
; F2 pin (one spelling, R12); each covered collider is tagged `!cq.f2.sibling`
; and its structure re-asked after the round-2 fixpoint
; (`declineRound2QuantumPrepSeeds`, both entry points).
;
;   int x (rotated); bool t = 0; if (x < 3) Ry(t,.3); if (x < 2) Ry(t,.7);
; `x < 2` is forced false (= the seed) on the x >= 3 edge.
; Analytic trace: slt(x,3) flag -> cRy(.3) on a fresh t, strip, free; slt(x,2)
; flag -> cRy(.7) on the SAME rail, strip, free. x < 2 -> Ry(1.0);
; 2 <= x < 3 -> Ry(.3); else |0>. Adversarial probe (dm7f.53 round 3): the
; rival `if (x<3) Ry(t,.3); else t = (x<2); if (x<2) Ry(t,.7);` compiles to the
; same stage-1 IR (up to a preds comment) and the SAME gate trace.
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
  %8 = icmp slt i32 %1, 2
  br i1 %8, label %9, label %13

9:
  %10 = trunc nuw i8 %7 to i1
  %11 = call i1 @cq_theta_i1(i1 %10, double 0x3FE6666666666666)
  %12 = zext i1 %11 to i8
  br label %13

13:
  %14 = phi i8 [ %12, %9 ], [ %7, %6 ]
  %15 = call i32 @cq_measure_si32(i32 %1)
  %16 = trunc nuw i8 %14 to i1
  %17 = call i1 @cq_measure_i1(i1 %16)
  %18 = zext i1 %17 to i32
  %19 = add nsw i32 %15, %18
  ret i32 %19
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H0]], double 1.000000e+00)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H0]], i32 3)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H1]], i32 %[[H2]], double 3.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[H1]], i32 %[[H0]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H1]])
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H0]], i32 2)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H3]], i32 %[[H2]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[H3]], i32 %[[H0]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H3]])
; CHECK-NEXT: %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H0]])
; CHECK-NEXT: %[[H5:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H2]])
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
