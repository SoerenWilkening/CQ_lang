; control_inplace_ry_reject_stateprep_range_ordered.ll — DECLINE (F2, the RANGE
; clause under an ORDERED predicate). THIS FILE IS THE PIN FOR THE DROPPED
; `isEquality()` GATE (round-1 Rule-13 review, lens L2 finding F-L2-1's second
; half).
;
;     %t = and i32 %q, 3        ; range [0,4)
;     %c = icmp sgt i32 %t, 2   ; NOT an equality
;     arm: cq_theta(i32 3, .9)  ; seed 3
;
; The true edge is `[0,4) ∩ (> 2) = {3}` — a singleton, and it IS the seed, so
; the module is indistinguishable from `if (t > 2) r = cq_theta(t, .9)`, an
; in-place Ry on the condition register (R4). The shipped Inc-4 F2 was gated on
; `IC->isEquality()` and would have been SILENT here.
;
; ⚠ THE OLD GATE PASSED ONLY BY ACCIDENT OF CANONICALIZATION. From plain C the
; ordered spellings L2 measured (`t > 2`, `t < 1`, `t >= 3`) reach the pass as
; `icmp eq` because instcombine rewrites a singleton-range ordered compare that
; way — MEASURED, not guaranteed, and a hand-written or differently-optimized
; module keeps the ordered form. `makeExactICmpRegion` handles every integer
; predicate, so there is no reason to ask only two of them.
;
; ONE-TOKEN CONTROL: `control_inplace_ry_stateprep_range_ordered_seed0.ll` is
; this module with the seed and the pred incoming changed from `3` to `0` — the
; SAME ordered compare, the SAME singleton edge — and it ACCEPTS. So this file
; pins the VALUE test inside the range clause, not the predicate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = and i32 %q, 3
  %c = icmp sgt i32 %t, 2
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 3, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 3, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
