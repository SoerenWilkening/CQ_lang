; lowering_reject_lift_resweep_prefix_sibling.ll — DECLINE (bd
; test_C_libtooling-dm7f.1: the counter-example that makes the post-lift exemption
; PER USE). `clang -O1` of
;
;     int q = 7; cq_theta(&q, .5);
;     int r = q;
;     if (c) { cq_theta(&q, .125); r = q; cq_theta(&q, .25); }
;     int v = r + 3;
;     return cq_measure(v) + cq_measure(q);
;
; Two phis lift onto `%3`: `%9` (`r`, record `%6`) and `%10` (`q`, record `%6`,
; `%7`). After the RAUW the `add` of `r` and an `add` of `q` would be the same
; instruction. A union of every lift's gates exempts `%7` too and, MEASURED on a
; mutant of exactly that, accepted at rc 0 with `add_hl(h, 3)` emitted after
; `ry .25`. The per-use record gives the `add` `r`'s record only, so `%7` is a
; gate it does not record.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

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
  %11 = add nsw i32 %9, 3
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)
