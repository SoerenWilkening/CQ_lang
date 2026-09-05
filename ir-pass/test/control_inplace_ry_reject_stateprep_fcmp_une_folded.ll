; control_inplace_ry_reject_stateprep_fcmp_une_folded.ll — DECLINE (F2, the fp
; ANCHOR's OTHER EXACT HALF: `une` pins on the edge where it is FALSE).
;
; `..._reject_stateprep_fcmp_oeq_folded.ll` covers `oeq`-TRUE. This covers
; `une`-FALSE, which is the SAME theorem written the way `clang` canonicalises
; `!=`: `!(x une K)` is `x oeq K`, so on the branch's FALSE edge `%t` IS `5.0`.
; The arm sits on that edge (Rule 9 — `-O1` routinely makes the gate arm the
; FALSE successor), the seed is `5.0`, and `%t` is live and MEASURED.
;
; ⚠ WHY BOTH HALVES NEED A FILE, and why the other two predicates do NOT
; (round-4 Rule-13 mini-fix, F-R4-1). The anchor's switch has two case groups:
;
;   `oeq` / `ueq` pin on the TRUE edge · `one` / `une` pin on the FALSE edge
;
; `oeq`-true and `une`-false are **EXACT**: ordered equality against a non-zero,
; non-NaN `ConstantFP` admits exactly ONE bit pattern, which is precisely the
; condition under which `clang` COULD have substituted the constant for the
; register. Both are therefore safety-critical and both are pinned — delete
; either `case` and exactly one of these two files goes red.
;
; `ueq`-true and `one`-false additionally admit `%x = NaN`, so the pin there is
; an OVER-APPROXIMATION: `clang` cannot substitute across them, so anything they
; catch is an over-decline. They are kept so the clause has no edge to get
; backwards (F2's whole design is to ask both edges and never reason about
; polarity), and they are deliberately LEFT UNPINNED because deleting them can
; only remove over-declines. **That asymmetry is stated rather than left to be
; rediscovered**: a future reader who deletes `FCMP_UEQ` and sees a green suite
; has NOT found dead code, and a future reader who deletes `FCMP_UNE` and sees a
; green suite has found a broken fixture. Measured 2026-09-05: all four
; predicates decline on this module shape (`$S/fix4/p/pol_{une,one,ueq}.ll`).
;
; Hand IR at this clang for the reason the `oeq` sibling spells out.
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
  %c = fcmp une double %t, 5.000000e+00
  br i1 %c, label %merge, label %arm
arm:
  %rt = call double @cq_theta_f64(double 5.000000e+00, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 5.000000e+00, %entry ]
  %mr = call double @cq_measure_f64(double %rm)
  %mt = call double @cq_measure_f64(double %t)
  %s  = fadd double %mr, %mt
  ret double %s
}
