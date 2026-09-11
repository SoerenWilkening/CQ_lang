; control_inplace_ry_reject_stateprep_range_forward_or.ll — DECLINE (F2, the
; RANGE clause reaching FORWARD: the pinned register is a USER of the compare's
; operand, not the operand itself).
;
; ⚠ A ROUND-2 RULE-13 FINDING, NOT A DESIGN ROW — one of the SIX plain-C
; spellings that ACCEPTED after the round-1 fix (round-2 review, lens R1 finding
; F-R1-1, CONFIRMED-MISCOMPILE, probe `p/y05_and_or.c`):
;
;     int q = cq_theta(3,0.3); int t = (q&1)|8; int r = 9;
;     if (t != 8) r = cq_theta(t, 0.9);
;     return (int) cq_measure(r) + (int) cq_measure(t);
;
; `ipsccp` proves the pin about the DERIVED register and substitutes it into the
; arm's `cq_theta`; a later `instcombine` rewrites the COMPARE down onto an
; ANCESTOR of that register, so the operand CQ is handed is not the register the
; theorem is about — which is a FORWARD USER of it, and which is ALIVE in the
; emitted circuit and MEASURED by the source while receiving no rotation at all.
; The round-1 fix widened F2's PREDICATE and kept F2's SET; this is the bd
; `8h7d.5` F-1/F-3 lesson a third time. The full mechanism, with the isolated
; `opt` pipelines that measured it and the unconditional control that fixes
; CQ's own reading of `cq_theta(t,θ)`, is written once in
; `..._range_forward_add.ll` and in the walk's header in `ArmClassify.cpp`.
;
; THIS FILE'S ALGEBRA: the `ne 0` edge pins `%t` to `{1}`, and `{1} | 8 = {9}` = the seed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %t = and i32 %q, 1
  %c = icmp eq i32 %t, 0
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 9, double 9.000000e-01)
  br label %merge
merge:
  %rm  = phi i32 [ %rt, %arm ], [ 9, %entry ]
  %fwd = or disjoint i32 %t, 80
  %mr  = call i32 @cq_measure_si32(i32 %rm)
  %mf  = call i32 @cq_measure_si32(i32 %fwd)
  %s   = add i32 %mr, %mf
  ret i32 %s
}
