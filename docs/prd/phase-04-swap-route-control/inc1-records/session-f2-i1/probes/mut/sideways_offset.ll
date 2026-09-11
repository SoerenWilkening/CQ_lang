; control_inplace_ry_reject_stateprep_sideways_offset.ll — DECLINE (F2-semantic:
; the SECOND of InstCombine's two division rewrites, the RANGE-CHECK form).
;
; Round-3 Rule-13 review, lens R3 finding F-R3-1. Companion to
; `..._sideways_sdiv.ll`: for a NON-power-of-two divisor InstCombine rewrites
;
;     icmp eq (udiv X, 3), 5   ->   icmp ult (add X, -15), 3
;
; so the compare's operand is a fresh `add` and the rotated register is again a
; SIBLING (`udiv %1, 3`). The plain-C source is
; `$S/review3/R3/p/t02_udiv3_eq5.c`:
;
;     int q = cq_theta(3,0.3); unsigned t = ((unsigned)q) / 3u; unsigned r = 5;
;     if (t == 5) r = cq_theta(t, 0.9);
;     return (int) cq_measure(r) + (int) cq_measure(t);
;
; This is the shape that makes the ORDERED half of F2 load-bearing: the compare
; is `ult`, not an equality, and it still pins — `LazyValueInfo` recovers
; `%1 ∈ [15,18)` from its `Val + Offset` idiom and the forward evaluation gives
; `udiv([15,18), {3}) = {5}` = the seed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %o = add i32 %q, -15
  %c = icmp ult i32 %o, 3
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_ui32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 5, %entry ]
  %t  = udiv i32 %q, 7
  %mr = call i32 @cq_measure_ui32(i32 %rm)
  %mt = call i32 @cq_measure_ui32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}
