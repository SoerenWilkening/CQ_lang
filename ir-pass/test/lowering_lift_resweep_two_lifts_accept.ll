; lowering_lift_resweep_two_lifts_accept.ll — ACCEPT (bd test_C_libtooling-dm7f.1,
; DECLINE->ACCEPT; main 7b4e6359 declined it with `cq opcode lowering: operand
; predates a non-diagonal gate`). Two sequential classical ifs over one register:
;
;     int q = 7; cq_theta(&q, .5);
;     if (c) cq_theta(&q, .125);
;     if (d) cq_theta(&q, .25);
;     int v = q + 3;
;
; Both merge phis lift onto `%3`. The second phi's edges are `%11 =
; cq_theta(%8, .25)` and `%8`, both recorded uses of the first phi `%8`, so the
; second lift inherits `%6` and the `add` is exempt from `%6` and `%11`.
;
; SEMANTIC EVIDENCE (hand trace). h = alloc(7); Ry(.5); [c] Ry(.125);
; [d] Ry(.25); add_hl(h, 3) measured. On each of the four paths the add reads the
; gates `q` received on that path: the source's `q`.
; Decline twin, the edge that does NOT inherit:
; lowering_reject_lift_resweep_partial_inherit.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; DIAG-NOT: live derived record
; CHECK-LABEL: define i32 @f(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[V]])

define i32 @f(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01)
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = icmp eq i32 %1, 0
  br i1 %9, label %12, label %10

10:                                               ; preds = %7
  %11 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.500000e-01)
  br label %12

12:                                               ; preds = %10, %7
  %13 = phi i32 [ %11, %10 ], [ %8, %7 ]
  %14 = add nsw i32 %13, 3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)
