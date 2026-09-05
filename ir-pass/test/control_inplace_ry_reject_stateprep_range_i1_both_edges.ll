; control_inplace_ry_reject_stateprep_range_i1_both_edges.ll — DECLINE (F2, the
; RANGE clause). AT `i1` EVERY EDGE OF AN `i1` EQUALITY IS A SINGLETON, so an
; `i1` seed under an `i1` condition is ALWAYS ambiguous.
;
; ⚠ THIS MODULE WAS THE SHIPPED Inc-4 ACCEPT FIXTURE
; `control_inplace_ry_stateprep_i1.ll`, VERBATIM. The round-1 Rule-13 review's
; range spelling of F2 (lens L2, F-L2-1) turned it into a decline, and that is
; CORRECT rather than collateral: `icmp eq i1 %q, true` proves `%q == false` on
; the straight-through edge, and the seed IS `false`, so the module is
; byte-identical to
;
;     i1 r = q;  if (q == true) r = cq_theta(false, θ);
;
; — an ALIAS of the quantum register on the straight-through edge muxed against
; a prepared rail (Rule 8, no-cloning; the A2 reading). At `i1` there are only
; two values, so BOTH edges pin, and no `i1` seed can escape: the whole
; "`i1` condition + `i1` seed" class is ambiguous by arithmetic.
;
; ⚠ CORRECTED 2026-09-05 (round-3 Rule-13 review, lens R3 finding F-R3-8). THIS
; PARAGRAPH USED TO SAY "THE WIDTH CAPABILITY IS NOT LOST", pointing at
; `control_inplace_ry_stateprep_i1.ll` (the same `i1` prep under an `i32`
; condition) and resting on F2's same-type gate to keep it silent. THAT GATE IS
; GONE — it was skipping ALL of F2 for the whole cast family and was itself a
; CONFIRMED MISCOMPILE (F-R3-2) — and the semantic form asks about the BRANCH
; CONDITION, which is a tainted `i1` pinned to `true` on one edge and `false` on
; the other whatever width the compare is at. So the `i1` STATE-PREP WIDTH IS
; NOW OUT: that fixture is re-homed as
; `..._reject_stateprep_i1_flag_pinned.ll` and joined by
; `..._reject_stateprep_i1_arm_flag.ll` (the plain-C-reachable ARM half). This
; file keeps its own reason — the A2 alias reading above — and is unaffected.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i1_controlled

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example(i1 %u0) {
entry:
  %q = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %c = icmp eq i1 %q, true
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ false, %entry ]
  %mq = call i1 @cq_measure_i1(i1 %q)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  ret i32 0
}
