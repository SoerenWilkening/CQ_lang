; control_swap_nested_phase_derived.ll — ACCEPT spec (§8 derived-base probe):
; depth-2 phase nest whose OUTER condition is a DERIVED compare that provably
; survives clang -O1 — an FP carrier `q + 1.0 > 5.0` (an integer `q+1>5` folds to
; `icmp sgt q,4` and exercises nothing; document, don't fight, the canonicalizer).
;
; The derived outer cond drives the diagonal-alias closure on the outer level:
; the condition's provenance includes the `fadd`, yet the routed handle is still
; the f64 cq_theta and every arm a pure cq_phi_f64 (Rz) — the merge is FP because
; the QUANTUM HANDLE is f64 (NOT an angle; a phase nest on an f64 handle is the
; same class as control_swap_diamond_derived_f64.ll). Detection accepts; emission
; routes the f64 rails.
;
; WI-1 lands DETECTION only — recognized as the accept shape, declined
; transitionally `nested control flow`, so this XFAILs. WI-3 lands the emitter and
; this XPASSes — delete the XFAIL then.
;
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %a, double %b) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %d  = fadd double %q, 1.000000e+00
  %c1 = fcmp ogt double %d, 5.000000e+00
  br i1 %c1, label %mid, label %merge
mid:
  %g  = call double @cq_phi_f64(double %q, double %b)
  %c2 = fcmp olt double %g, 9.000000e+00
  br i1 %c2, label %arm, label %merge
arm:
  %h  = call double @cq_phi_f64(double %g, double %a)
  br label %merge
merge:
  %qm = phi double [ %q, %entry ], [ %g, %mid ], [ %h, %arm ]
  %m  = call double @cq_measure_f64(double %qm)
  ret double %m
}
; Structural markers (WI-3): the f64 routed stream — the outer flag minted off the
; DERIVED fadd handle, the rails f64 (the alloc seed carries the width as `double
; 0.0`, NOT `i32 0`; handles themselves stay i32), the inner flag minted FROM rail1.
; CHECK:     call i32 @cq_template_fadd_f64_hl(i32 %{{.*}}, double 1.000000e+00)
; CHECK:     call i32 @cq_template_fcmp_ogt_f64_hl(i32 %{{.*}}, double 5.000000e+00)
; CHECK:     call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_cswap(i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}})
; CHECK:     call i32 @cq_template_fcmp_olt_f64_hl(i32 %{{.*}}, double 9.000000e+00)
; CHECK:     call double @cqrt_measure_f64(
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: phi double
