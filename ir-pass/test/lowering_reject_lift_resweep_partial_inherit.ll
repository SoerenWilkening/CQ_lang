; lowering_reject_lift_resweep_partial_inherit.ll — DECLINE (bd
; test_C_libtooling-dm7f.1). The pure-op twin of
; lowering_reject_lift_stale_reader_partial_inherit.ll:
;
;     int q0 = q;
;     if (c) cq_theta(&q, .125);
;     if (d) cq_theta(&q, .25); else q = q0;
;     int v = q + 3;
;
; The second phi's `%7` edge holds the ORIGINAL `%3` (`q0`), not the first phi, so
; the second lift does not inherit `%6`; on the `c && !d` path the `add` would
; read `q0` from a wire that carries `Ry(.125)`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

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

12:                                               ; preds = %7, %10
  %13 = phi i32 [ %11, %10 ], [ %3, %7 ]
  %14 = add nsw i32 %13, 3
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)
