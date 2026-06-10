; control_swap_reject_value_stray.ll — stray op beside a value chain declines as
; IMPURE (4.2 WI-3; PRD Part II §8.3 row "impure"; fixture pair partner:
; control_swap_reject_value_fanout.ll; mirrors the 4.1 phase probe
; control_swap_reject_measure_in_arm.ll).
;
; `if (q > 5) { p = p + 3; measure(r); }` — the arm block holds a user
; MEASUREMENT beyond the linear value chain. The WI-4 emitter replays + erases
; ONLY the chain and RegionFlatten erases the arm BLOCK: a stray op would be
; silently DROPPED from the IR (a vanishing user measurement — Rule 5) and its
; taint.MeasureCalls pointer would dangle (use-after-free in lowerMeasures).
; The arm block must be EXACTLY the linear chain feeding the merge; anything
; else is declined loudly while the block is still intact.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}impure value arm under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, i32 %w0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %r = call i32 @cq_theta_si32(i32 %w0, double 1.250000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %p1 = add i32 %p, 3
  %m2 = call i32 @cq_measure_si32(i32 %r)   ; STRAY user measurement in the arm
  br label %merge
merge:
  %pm = phi i32 [ %p1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
