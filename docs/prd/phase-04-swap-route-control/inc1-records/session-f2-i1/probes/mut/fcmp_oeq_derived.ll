; control_inplace_ry_reject_stateprep_fcmp_oeq_derived.ll — DECLINE (F2). The fp
; ANCHOR's pin flows FORWARD: the seed is the fold of a value DERIVED from the
; register the `fcmp` pins, not of the pinned register itself.
;
; `%t` is pinned to `5.0` on the equality edge by `fcmp oeq double %t, 5.0`;
; `%d = fmul double %t, 3.0` therefore folds EXACTLY to `15.0`, which IS the arm's
; seed — and `%d` is live and MEASURED. Same ambiguity as
; `..._reject_stateprep_fcmp_oeq_folded.ll`, one hop further out.
;
; ⚠ WHY IT IS A SEPARATE FILE (round-4 Rule-13 mini-fix, F-R4-1). The fp anchor
; seeds exactly ONE fact — the equality operand — and every other fp value is
; covered by REUSING the existing forward evaluation (`f2Model`'s exact
; `ConstantFoldInstOperands` path), which is the "answer the closure question by
; reusing the closure, not by minting a second walker" discipline the bd 8h7d.5
; F-1/F-3 pair taught. **Nothing pinned that reuse at fp**: the anchor's own
; fixture is answered by the anchor alone, so a change that broke the forward
; hand-off for `ConstantFP` values would leave it green. This file goes red
; instead.
;
; ONE-TOKEN CONTROL: `..._stateprep_fcmp_oeq_derived_accept.ll` is this module
; with the seed `15.0` → `16.0` and nothing else, and it ACCEPTS — so the decline
; is the FOLD matching, not the shape.
;
; Hand IR at this clang, for the reason spelled out in the sibling fixture:
; `propagateEquality` does not substitute across `fcmp oeq`, and `EarlyCSE` runs
; before `IPSCCP`, so `clang -O1` does not produce this module. The shape it does
; produce is `..._reject_stateprep_fcmp_oeq_unfolded.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_f64_controlled

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %t = fmul double %q, 2.000000e+00
  %c = fcmp oeq double %t, 5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 1.500000e+01, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 1.500000e+01, %entry ]
  %d = fmul double %t, 4.000000e+00
  %mr = call double @cq_measure_f64(double %rm)
  %md = call double @cq_measure_f64(double %d)
  %s  = fadd double %mr, %md
  ret double %s
}
