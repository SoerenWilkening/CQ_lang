; lowering_reject_math_result_as_angle.ll — DECLINE: a TAINTED fp-DATA result
; used as a rotation ANGLE in straight-line code (PRD-iw81.4 §7 hazard 1,
; decline-matrix D1 — the carve-precondition headline probe).
;
; THE CLAIM THIS PINS (iw81.4.a): a tainted math result reaching a rotation
; angle — `cq_phi(sin(q))` — MUST loud-decline, never lower a soft-float ANGLE
; through an fp-DATA template (the f64 angle/data silent-miscompile family). The
; probe uses a tainted `fmul` (PRD §2.1, `cq_template_fmul_f64`) as the fp-DATA
; producer: `cq_phi(q * q)`.
;
; WHY IT HOLDS: `fmul(q,q)` is ordinary tainted data, and `cq_phi`'s one operand
; is its angle. The fence is `deleteGlobalPhases` (TaintPropagation), which
; declines a surviving `cq_phi` with a tainted angle and runs BEFORE `lowerOps`
; (where intrinsic lowering lives). It keys on taint membership, not on the
; producer, so it fires while the fp producer is STILL its source call.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %ang = fmul double %q, %q                       ; TAINTED fp-DATA result (the recognized-math proxy)
  call void @cq_phi(double %ang)  ; %ang in the arg-1 ANGLE slot
  %m   = call double @cq_measure_f64(double %q)
  ret double %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; Declined by deleteGlobalPhases, BEFORE lowerOps — so no fp template is ever minted:
; CHECK-NOT: cq_template_fmul
; CHECK-NOT: cqrt_rz
