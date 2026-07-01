; lowering_reject_libm_unknown_name.ll — DECLINE: the EXACT-name discipline (Prime
; Directive, the cq_theta_evil hazard). LibmLowering matches a call name EXACTLY
; against the curated set (both the `double` and `…f` spelling), NEVER a prefix or
; substring. Two off-pattern shapes that MUST still ride the loud unknown-callee
; escape decline:
;   * `@cbrt_helper` — a user function whose name merely CONTAINS the curated stem
;     `cbrt` as a prefix. A `starts_with("cbrt")` accept would be the silent-
;     miscompile bug; exact-name membership rejects it.
;   * `@j0` — a real libm function (Bessel) that is simply NOT in the curated set.
; Neither is lowered; both decline at kMsgUnknownCallee. (A curated name whose
; callee has an in-module BODY is likewise not carved — LibmLowering requires a
; DECLARATION — and is owned by the specializer / escape path instead.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @cbrt_helper(double)
declare double @j0(double)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r = call double @cbrt_helper(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_cbrt
