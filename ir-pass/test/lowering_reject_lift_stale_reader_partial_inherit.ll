; lowering_reject_lift_stale_reader_partial_inherit.ll — DECLINE (bd
; test_C_libtooling-r2j3.11). Two sequential lifts over one base, where only ONE
; edge of the second phi carries the first phi's record:
;
;     int q = 7; cq_theta(&q, .5);
;     int q0 = q;
;     if (c) cq_theta(&q, .125);
;     if (d) cq_theta(&q, .25); else q = q0;
;     return cq_measure(q);
;
; On the `c && !d` path `q` is `q0`, the record from before `Ry(.125)`, but the
; wire carries it. Main accepted this at rc 0 with an empty stderr. The second
; lift inherits the first lift's record only when EVERY incoming derives from the
; first phi; here the `%7` edge holds the original `%3`, so `%6` is evidence for
; the measure of `%13`. Accept twin with both edges inherited:
; lowering_lift_reader_two_lifts_accept.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

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
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13)
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)
