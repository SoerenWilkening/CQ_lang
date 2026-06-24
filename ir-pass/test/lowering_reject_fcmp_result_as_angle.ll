; lowering_reject_fcmp_result_as_angle.ll — BOUNDARY DECLINE probe (8rvn,
; Phase 7.1 iw81.4). Pins the forward boundary the iw81.4.b Rule-13 synthesis
; flagged FOR this increment (bd 8rvn comment, 2026-06-24): once 8rvn admits the
; new fp fcmp predicates, the i1 compare RESULT must NEVER reach a rotation's
; arg-1 ANGLE slot. An fcmp result is an integer FLAG (i1), never an angle — the
; angle fence is keyed on arg-1 TAINT (RotationLowering::declineTaintedAngle),
; independent of `compareInScope`, so broadening the predicate set does NOT open
; an angle hole (the f64 angle/data silent-miscompile family stays closed).
;
; Construction: `fcmp ult` is now an IN-SCOPE predicate (it would lower to
; `cq_template_fcmp_ult_f64_hl` in pure data position). Its i1 result is laundered
; toward the `double` angle slot through `uitofp i1 -> double` and handed to
; `cq_phi`'s arg-1. The cast result is a tainted fp value; the angle fence fires
; in `lowerRotations` (which runs BEFORE `lowerOps`/`rewriteCompare`), so the
; whole construct loud-declines and NEITHER an fcmp template NOR an `rz` is ever
; minted — exactly like the D1/D11 math-result-as-angle probes, but seeded at a
; now-admissible COMPARE rather than an arithmetic producer.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; The construct declines BEFORE lowerOps — no fcmp template, no rz, ever minted:
; CHECK-NOT: cq_template_fcmp
; CHECK-NOT: cqrt_rz

declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c   = fcmp ult double %q, 1.0                    ; i1 FLAG — `ult` is in scope after 8rvn
  %ang = uitofp i1 %c to double                     ; laundered toward the angle slot
  %qd  = call double @cq_phi_f64(double %q, double %ang)   ; %ang in the arg-1 ANGLE slot
  %m   = call double @cq_measure_f64(double %qd)
  ret double %m
}
