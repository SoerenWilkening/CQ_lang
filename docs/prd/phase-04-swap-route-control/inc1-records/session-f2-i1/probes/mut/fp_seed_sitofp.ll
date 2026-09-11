; control_inplace_ry_reject_stateprep_fp_seed_sitofp.ll — DECLINE. The F-R3-2
; CAST family AT FLOATING POINT, and it was reachable by a SECOND gate that the
; round-3 lens did not name.
;
; ⚠ FOUND BY THE ROUND-3 FIX AGENT while checking that the new `Constant *`
; identity test really does cover an fp seed (notes §12.1 F-R3-10). It is the
; `-O1` image of PLAIN C, measured 2026-09-05:
;
;     double slice(void){ int q = cq_theta(3,0.3);
;                         double t = (double)q;        /* a live sitofp RAIL   */
;                         double r = 5.0;
;                         if (q == 5) r = cq_theta(5.0, 0.9);
;                         return cq_measure(r) + cq_measure(t); }
;
; `-O1` folds the arm's arg-0 to `double 5.000000e+00` on the proving edge and
; leaves `%7 = sitofp i32 %1 to double` alive and MEASURED. The shipped F2 could
; not see it for TWO independent reasons, either of which alone was enough:
; the K/seed TYPE GATE (`i32` vs `double`), and `SeedI = dyn_cast<ConstantInt>
; (RotBase)` — an fp seed made the whole clause vacuous, so **no fp seed was
; ever asked F2's question at all**.
;
; THE SEMANTIC FORM NEEDS NO fp ARM. The test is `Constant *` POINTER IDENTITY
; against the seed (LLVM uniques `ConstantFP` on the `APFloat` BITS — F1's
; discipline reused), and once `%q` is pinned to `{5}` on the arm edge the
; `sitofp` is EXACTLY folded by `ConstantFoldInstOperands`. No opcode table, no
; fp-specific clause, and `-0.0` vs `0.0` correctly stays a non-match.
;
; THE ONE-TOKEN CONTROL is the same program with the seed `7.0`
; (`$S/fix3/y/y02_fp_seed_noncoll.c`): the `sitofp` folds to `5.0`, which is not
; the seed, and it ACCEPTS — measured, strict-2b clean, linked and run. The
; width control is `control_inplace_ry_stateprep_f64.ll`, an fp state prep with
; no fp rail in the module at all, still accepting.
;
; ⚠ NOTE WHAT THIS DOES NOT WIDEN. `fcmp` conditions still reach no clause here
; and still decline on R4 unfolded (`..._reject_stateprep_fcmp_oeq_unfolded.ll`):
; `propagateEquality` will not substitute across `oeq` (`+0.0 == -0.0`). What
; changed is the SEED side, not the CONDITION side.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, 6
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 5.000000e+00, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 5.000000e+00, %entry ]
  %t  = sitofp i32 %q to double
  %mr = call double @cq_measure_f64(double %rm)
  %mt = call double @cq_measure_f64(double %t)
  %s  = fadd double %mr, %mt
  ret double %s
}
