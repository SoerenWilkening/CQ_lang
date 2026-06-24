; lowering_reject_math_double_realize.ll — DECLINE: a TAINTED fp-DATA result that
; feeds BOTH a genuine data path AND a rotation's arg-1 ANGLE slot (PRD-iw81.4 §7,
; decline-matrix D11 — the "double-realize" fan-out probe).
;
; `%r = fmul q, q` is consumed two ways at once:
;   (1) `%d = fadd %r, %r`     — a genuine DATA use (measured), and
;   (2) `cq_phi(q, %r)`        — the arg-1 ANGLE slot of a rotation.
; The arg-1 angle exclusion is PER-OPERAND-USE, not global (TaintPropagation.cpp:303
; skips ONLY the `cq_phi` angle edge), so `%r` stays in `Tainted` from its data use.
; There is no sound split — realizing `%r` as basis data for the fadd AND as a
; rotation angle would double-realize the value (angle = f(quantum value), value in
; superposition: no fixed unitary; the f64 angle/data silent-miscompile family).
;
; The decline TRIGGER is the SAME single check as D1 — RotationLowering::
; declineTaintedAngle (the producer-agnostic taint-of-arg-1 fence, RotationLowering.cpp:74);
; `%r`'s extra data use does not introduce a new code path, it only makes the
; "can't split" reason concrete (the straight-line counterpart of the
; SelectClassify::selReachesRotationArg1 fan-out principle — "any arg-1 reach
; declines the WHOLE construct" — that the swap-route emitter relies on; an
; illustrative analogy, NOT a separate emitter call here). The fence fires in
; `lowerRotations`, BEFORE `lowerOps` lowers either the fmul or the fadd — so NOT
; ONE template is minted. Once iw81.4.b recognizes the math intrinsics, `%r = sin(q)`
; here declines identically (D1's ordering proof).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r   = fmul double %q, %q                       ; TAINTED fp-DATA, realized two ways
  %d   = fadd double %r, %r                        ; (1) genuine DATA use
  %qd  = call double @cq_phi_f64(double %q, double %r)   ; (2) ALSO the arg-1 ANGLE
  %m1  = call double @cq_measure_f64(double %qd)
  %m2  = call double @cq_measure_f64(double %d)
  %s   = fadd double %m1, %m2
  ret double %s
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; Declined whole construct, before lowerOps — neither the fmul nor the fadd is lowered:
; CHECK-NOT: cq_template_fmul
; CHECK-NOT: cq_template_fadd
; CHECK-NOT: cqrt_rz
