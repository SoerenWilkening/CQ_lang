; control_inplace_ry_reject_stateprep_tree_fcmp_leaf_derived.ll — DECLINE (F2),
; bd test_C_libtooling-dm7f.52. The COMPOUND-CONDITION twin of
; `control_inplace_ry_reject_stateprep_fcmp_oeq_derived.ll`: the same module with
; the branch condition `and i1 %c, %b` (an `fcmp` LEAF beside a `_Bool` rail)
; instead of the bare `fcmp %c`.
;
; THE RETIREMENT TRIGGER THIS DISCHARGES, committed in
; `control_inplace_ry_reject_stateprep_compound_cond.ll` (now
; `control_inplace_ry_stateprep_compound_cond.ll`): "THE DAY COMPOUND CONDITIONS
; ARE ADMITTED TO ANY CONTROL ACCEPT PATH, F2 MUST BE ASKED OF EVERY LEAF OF THE
; FLAG NETWORK". dm7f.52 admits them for the in-place Ry / state prep. F2's
; INTEGER half was already tree-complete (LVI's `getConstantRangeOnEdge` and
; `isImpliedCondition` decompose a logical `and`/`or`), but its fp ANCHOR read
; only `BI->getCondition()` as an `FCmpInst` — so on this module `%t` was pinned
; to nothing, `%d = %t * 3.0` never folded to the seed `15.0`, and the region
; would ACCEPT a fresh rail at 15.0 where the source could have meant an in-place
; Ry on the live, measured `%d` (the sibling fixture's ambiguity). The anchor now
; asks every `fcmp` the edge FORCES (`forcedFcmpLeaves`: through an `and` on the
; true edge, an `or` on the false edge), so `%c` pins `%t` on the true edge and
; the forward evaluation reaches `%d` exactly as for the bare `fcmp`.
;
; ONE-TOKEN CONTROL: `control_inplace_ry_stateprep_tree_fcmp_leaf_derived_accept.ll`
; is this module with the seed `15.0` → `16.0`, and it ACCEPTS.
; Hand IR (the sibling's note: `clang -O1` does not substitute across `fcmp oeq`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_f64_controlled

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  %t = fmul double %q, 2.000000e+00
  %c = fcmp oeq double %t, 5.000000e+00
  %cc = and i1 %c, %b
  br i1 %cc, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 1.500000e+01, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 1.500000e+01, %entry ]
  %d = fmul double %t, 3.000000e+00
  %mr = call double @cq_measure_f64(double %rm)
  %md = call double @cq_measure_f64(double %d)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %s  = fadd double %mr, %md
  ret double %s
}
