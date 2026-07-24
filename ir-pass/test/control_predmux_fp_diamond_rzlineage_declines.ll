; control_predmux_fp_diamond_rzlineage_declines.ll — DECLINE (bd vyqi, W5
; matrix): a sole-phi both-arms-write fp diamond whose merged values carry an
; Rz (`cq_phi`) lineage. W5 CLAIMS the region (the witness is structural) and
; PredMux flattens it — and then the kjd1 select ladder's gate 5 declines the
; minted select: a relative-phase carrier must never ride the basis
; controlled-copy merge (the CNOT copies a basis label, not a phase — the
; Rule-7 dephasing family, P0 0.585→0.500). The flatten-then-loud-decline
; posture is the standard PredMux discipline (guards adjudicate post-flatten
; IR); what matters is that NO copy is emitted and opt exits non-zero. The
; phase fence survives the W5 widening.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qd = call double @cq_phi_f64(double %q, double 2.500000e-01)   ; Rz — phase carrier
  %c = fcmp olt double %qd, 5.000000e-01
  br i1 %c, label %lo, label %hi
lo:
  %a = fadd double %qd, -5.000000e-01
  br label %merge
hi:
  %b = fmul double %qd, 2.000000e+00
  br label %merge
merge:
  %zv = phi double [ %a, %lo ], [ %b, %hi ]
  %m = call double @cq_measure_f64(double %zv)
  ret double %m
}
