; spec_accept_fp_arg_return.ll — bd 3c6m.54: the canonical fp-ABI specialization
; accept. A tainted DOUBLE argument to a pure-classical `double helper(double)`
; (the coshl-shape libm reduction) is detected, cloned with the fp arg AND the
; fp return REWRITTEN to i32 handles (Rule 15 — a quantum value is always an i32
; handle), lowered, and Bennett-wrapped with a `cqrt_copy_f64` copy-out. The
; caller's theta result becomes the i32 handle (RAUW-to-handle), the retargeted
; call returns an i32 handle, and `cq_measure_f64` reads it directly.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @helper(double %x) {
entry:
  %y = fmul double %x, 2.000000e+00
  ret double %y
}

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r = call double @helper(double %q)
  %z = call double @cq_measure_f64(double %r)
  ret double %z
}

; Caller: theta → alloc_f64+ry_f64; the call retargets to the i32-signature clone
; (fp arg → i32 handle, fp return → i32 handle); the measure reads the i32 result.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_1(i32 %[[H]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[R]])
;
; Clone: i32 signature; fp `_hl` template; fp copy-out via cqrt_copy_f64; fp `_unc`
; reverse; free; return the i32 handle.
; CHECK:     define internal i32 @__cq_q_helper_1(i32 %x)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f64_hl(i32 %x, double 2.000000e+00)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64(i32 %[[OP]], i32 %[[OUT]])
; CHECK:     call void @cq_template_fmul_f64_hl_unc(i32 %[[OP]], i32 %x, double 2.000000e+00)
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; CHECK:     ret i32 %[[OUT]]
;
; No fp decline; no raw fp copy in the caller; the intrinsics are gone.
; CHECK-NOT: floating-point quantum argument or return has no reversible copy
; CHECK-NOT: cq_theta_f64
