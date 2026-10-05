; lowering_reject_lift_stale_reader_theta.ll — DECLINE (bd test_C_libtooling-r2j3.11).
; The rotation-reader twin of lowering_reject_lift_stale_reader_measure.ll:
;
;     int r = q;
;     if (c) { cq_theta(&q, .125); r = q; cq_theta(&q, .25); }
;     int w = q + 1;
;     cq_theta(&r, .3);
;     return cq_measure(w) + cq_measure(r);
;
; `cq_theta(&r, .3)` (`%12`) rotates the name `r`, whose record (`%9`) predates the
; arm's `Ry(.25)` (`%7`). The same program without `w` (`cq_theta(&r, .3);
; return cq_measure(r) + cq_measure(q);`) was accepted by main 7b4e6359 at rc 0
; with an empty stderr, emitting `ry .3` on the post-`.25` wire. The post-lift
; reader re-ask exempts `%12` itself and `%6` (on `r`'s record); `%7` is evidence.
;
; WHY `w`: it keeps the `q` phi LIVE (so both phis lift and a union of the two
; records would exempt `%7`), and it reads `q` BEFORE `%12`, so nothing but `r`'s
; own staleness is left to decline. Main declined this exact module earlier, at
; the `add` (the dm7f.1 over-decline); a measure of `q` placed after `%12` would
; also decline (`%12` is a gate on `q`'s wire too), which is why the earlier
; spelling of this fixture could not tell a per-use exemption from a union.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

define i32 @f(i32 noundef %0, i32 %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %8, label %5

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01)
  br label %8

8:                                                ; preds = %5, %2
  %9 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %10 = phi i32 [ %7, %5 ], [ %3, %2 ]
  %11 = add nsw i32 %10, 1
  %12 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 3.000000e-01)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %12)
  %15 = add nsw i32 %14, %13
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)
