; control_inplace_ry_reject_stateprep_range_a2_alias.ll — DECLINE (F2, the RANGE
; clause, A2/A3 on the STRAIGHT-THROUGH edge).
;
; ⚠ ALSO A ROUND-1 RULE-13 FINDING (lens L2, F-L2-2, probe
; `p/k06_a2_range_alias.c`), and it ACCEPTED at hand-back:
;
;     int q = cq_theta(3, 0.3);
;     int r = q & 1;                       /* r ALIASES the condition register */
;     if (!(q & 1)) r = cq_theta(1, 0.9);
;     return (int) cq_measure(r);
;
; The straight-through edge is the `!= 0` edge, so `-O1` folds the merge φ's
; PRED incoming `%t` to `i32 1`; F1 is then satisfied by the seed `1`, and the
; shipped F2 compared `1` against `k = 0` and stayed silent. The emitted circuit
; muxed a FRESH rail against nothing where the source muxes THE CONDITION
; REGISTER'S OWN RAIL against a prepared one — Rule 8 (no-cloning), the exact
; A2 program §14.2b says F2 exists to refuse. It refuses the `int r = q;`
; spelling (the pred incoming folds to the literal `k`) and missed this one,
; whose pred incoming folds to the RANGE-pinned value instead.
;
; The range test asks BOTH edges, so it does not care which one is the arm:
; `[0,2) ∩ (≠ 0) = {1}` = the seed. Decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = and i32 %q, 2
  %c = icmp eq i32 %t, 0
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 1, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ 1, %entry ], [ %rt, %arm ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mr
}
