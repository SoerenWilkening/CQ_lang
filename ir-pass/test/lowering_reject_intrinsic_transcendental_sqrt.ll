; lowering_reject_intrinsic_transcendental_sqrt.ll — Phase 7.1 Increment E
; over-accept fence (green forever). An fp transcendental (`llvm.sqrt`/`sin`/…)
; is NOT an idiom intrinsic: it is a separate Phase-6 Path-1 curated libm-
; substitution problem (PRD §2.6 "OUT"), not a reversible bit-permutation/pure-
; total integer op. isCuratedReversibleIntrinsic returns false, so the tainted
; call rides the loud kMsgUnknownCallee escape decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_sqrt

declare double @cq_theta_f64(double, double)
declare double @llvm.sqrt.f64(double)

define void @example(double %u) {
entry:
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @llvm.sqrt.f64(double %q)
  %k = call double @llvm.sqrt.f64(double %r)
  ret void
}
