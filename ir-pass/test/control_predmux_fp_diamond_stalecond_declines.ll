; control_predmux_fp_diamond_stalecond_declines.ll — DECLINE (bd vyqi, W5
; matrix): a sole-phi both-arms-write fp diamond with a chained `cq_theta` (an
; in-place, NON-DIAGONAL Ry) between the compare and the branch. W5 claims and
; PredMux flattens (the E-ladder has no staleness gate — the ENTRY block is
; never moved), and the kjd1 gate-2c STALE-CONDITION wire guard then declines
; the minted select: the flag would be minted AFTER the Ry moved the condition
; wire's basis, encoding the post-Ry predicate while the SSA condition denotes
; the pre-Ry record — the copies would route on the wrong predicate,
; verify-clean. Bennett's write-once-wire assumption, re-created as a guard
; (the kjd1 fcmp-lens BLOCKER). The staleness fence survives the W5 widening.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp olt double %q, 5.000000e-01
  %q2 = call double @cq_theta_f64(double %q, double 1.250000e-01)  ; chained Ry stales the wire
  br i1 %c, label %lo, label %hi
lo:
  %a = fadd double %q2, -5.000000e-01
  br label %merge
hi:
  %b = fmul double %q2, 2.000000e+00
  br label %merge
merge:
  %zv = phi double [ %a, %lo ], [ %b, %hi ]
  %m = call double @cq_measure_f64(double %zv)
  ret double %m
}
