; control_inplace_ry_reject_stateprep_range_mask1.ll — DECLINE (F2, the RANGE
; clause, A3 reading on the `ne` edge).
;
; ⚠ THIS FIXTURE IS A ROUND-1 RULE-13 FINDING, NOT A DESIGN ROW. It ACCEPTED at
; the Inc-4 hand-back and the acceptance was a CONFIRMED SILENT MISCOMPILE
; reachable from ordinary `clang -O1` C (round-1 review, lens L2 finding
; F-L2-1, probe `p/k08_and1_measure_cond.c`):
;
;     int q = cq_theta(3, 0.3);
;     int t = q & 1;                    /* a template rail derived from q      */
;     int r = 1;
;     if (t) r = cq_theta(t, 0.9);      /* an IN-PLACE Ry on the CONDITION rail */
;     return (int) cq_measure(r) + (int) cq_measure(t);
;
; `-O1` emits exactly the module below: the arm's `cq_theta(%t, .9)` folds to
; `cq_theta(i32 1, .9)`, because on the `%t != 0` edge a 1-bit-masked value must
; be 1. The shipped F2 asked only "is the compare LITERAL `k` the seed?" — `k` is
; 0 and the seed is 1, so it was silent BY DESIGN, and the region lowered as a
; state prep on a FRESH rail while `%t` was never rotated at all. Measured
; emitted stream: `and_i32_hl(h0,1) -> h1 ; icmp_eq_i32_hl(h1,0) -> h2 ; x(h2) ;
; alloc_i32(1) -> h3 ; ry_i32_controlled(h2,h3,.9)` — `h1` receives NO rotation,
; and the source's `r` and `t` are ONE register read twice while the circuit has
; two. The pre-Inc-4 binary declined it `control flow`.
;
; THE FENCE IS NOW THE QUESTION THE OBJECT ASKS: does EITHER edge of this branch
; pin the compare's tainted operand to the SEED's value? `computeConstantRange`
; gives `%t = and %q, 1` the range `[0,2)`; the `ne 0` edge intersects that to
; the SINGLETON `{1}`, which IS the seed. Decline. This is the same arithmetic
; `clang`'s IPSCCP used to create the ambiguity
; (`SCCPInstVisitor::handleCallResult` intersects the operand's lattice range
; with `makeAllowedICmpRegion` and substitutes on `isSingleElement()`).
;
; THE ONE-TOKEN CONTROL is `control_inplace_ry_stateprep_cond_derived.ll`:
; `and %q, 6` / `icmp eq %a, 2` / seed 0 — neither edge is a singleton there
; (`{2}` on one, a six-element set on the other), so it still ACCEPTS. The
; discriminator is the VALUE, not the shape.
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
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 1, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 1, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}
