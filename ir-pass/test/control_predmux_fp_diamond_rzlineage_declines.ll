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
;
; 3qlq(prep_a2): HAND DECISION — the register `cq_phi` here was NEVER the subject.
; This fixture pins an uncompute / mux / measurement-ordering / specialization rule
; and used `%r = cq_phi_<sfx>(%x, θ)` only as "a gate on a handle".  D1 removes that
; spelling, so the gate is re-spelled `cq_theta_<sfx>` — the OTHER in-place rotation
; on the same rail, which is what the corpus uses everywhere else for the same job.
; MEASURED on the Inc-1 binary: the swap reproduces this fixture's ORIGINAL asserted
; diagnostic, so the CHECK lines are UNCHANGED and the property is pinned by exactly
; the text it was pinned by before.  (prep_a measured the same 16 files against the
; pre-3qlq ORACLE; this is the independent re-measurement on the SUBJECT.)
; ⚠ Note what the swap does NOT preserve: Rz is DIAGONAL and Ry is not, so a rule
; that turned on diagonality would move.  None of these 16 do — that is what the
; character-for-character reproduction of the diagnostic establishes.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qd = call double @cq_theta_f64(double %q, double 2.500000e-01)   ; Rz — phase carrier
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
