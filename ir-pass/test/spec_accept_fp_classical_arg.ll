; spec_accept_fp_classical_arg.ll — bd 3c6m.54: a MIXED fp signature — a tainted
; fp arg-0 (rewritten to i32) beside a CLASSICAL fp arg-1 kept at its fp type
; (the atan2l(tainted y, classical x) shape). The classical `double %x`
; pass-through flows as the `_hl` template's classical operand (a runtime fp
; value, not a compile-time literal), proving a classical fp param is NOT promoted
; to a handle (Rule 3 / quantum-classical-handling §5.2). The mask is 0b01, so the
; clone is `__cq_q_atan2ish_01(i32 %y, double %x)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @atan2ish(double %y, double %x) {
entry:
  %s = fadd double %y, %x
  %p = fmul double %s, %y
  ret double %p
}

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r = call double @atan2ish(double %q, double 5.000000e-01)
  %z = call double @cq_measure_f64(double %r)
  ret double %z
}

; The clone: arg-0 tainted-fp → i32 handle; arg-1 classical-fp → KEPT `double`.
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_atan2ish_01(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK:     define internal i32 @__cq_q_atan2ish_01(i32 %y, double %x)
; The classical fp param is the `_hl` classical operand; the Q+Q fmul is all-handle.
; CHECK:     %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fadd_f64_hl(i32 %y, double %x)
; CHECK:     %[[MUL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f64(i32 %[[ADD]], i32 %y)
; CHECK:     call void @cqrt_copy_f64(i32 %[[MUL]], i32 %{{[a-zA-Z0-9_.]+}})
; LIFO reverse-play: fmul `_unc` before fadd `_unc`.
; CHECK:     call void @cq_template_fmul_f64_unc(i32 %[[MUL]], i32 %[[ADD]], i32 %y)
; CHECK:     call void @cq_template_fadd_f64_hl_unc(i32 %[[ADD]], i32 %y, double %x)
; CHECK-NOT: floating-point quantum argument or return has no reversible copy
