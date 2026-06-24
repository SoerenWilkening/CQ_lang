; lowering_reject_intrinsic_fp_noncurated.ll — DECLINE: a NON-curated fp-math
; intrinsic (`@llvm.exp10.f64`) over a tainted operand (PRD-iw81.4 §6 D8 / §7
; hazard 1). This is the sharp adversarial probe of the PER-ID gate: iw81.4.b
; curates `exp` AND `exp2` but NOT `exp10` — so a tainted `exp10(q)` must ride the
; loud kMsgUnknownCallee escape decline (`intrinsicStem(exp10)` is empty, the call
; is not curated). This pins that the fp admit is an EXACT-`Intrinsic::ID` set, NOT
; a name-prefix or a blanket "any fp intrinsic" accept (the cq_theta_evil hazard).
; A future agent who widens the recognizer must not silently sweep exp10 in.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.exp10.f64(double)

define double @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @llvm.exp10.f64(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_exp
