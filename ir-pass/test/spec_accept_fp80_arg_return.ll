; spec_accept_fp80_arg_return.ll — bd 3c6m.54: the x86_fp80 (long double) fp-ABI
; specialization accept — the ld80 libm census width (atan2l/coshl/lgammal/…).
; A tainted `long double` arg to `long double lhelper(long double)` clones with
; the fp80 arg AND return rewritten to i32 handles and a `cqrt_copy_f80` copy-out.
; Proves the whole reversible-fp width set {f16,f32,f64,f80} rides the same ABI;
; f80 is the widest and the census-critical one.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @lhelper(x86_fp80 %x) {
entry:
  %y = fmul x86_fp80 %x, 0xK4000C000000000000000
  ret x86_fp80 %y
}

define x86_fp80 @example(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %r = call x86_fp80 @lhelper(x86_fp80 %q)
  %z = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %z
}

; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 %u0)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_lhelper_1(i32 %[[H]])
; CHECK:     call x86_fp80 @cqrt_measure_f80(i32 %[[R]])
; CHECK:     define internal i32 @__cq_q_lhelper_1(i32 %x)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f80_hl(i32 %x, x86_fp80 0xK4000C000000000000000)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK:     call void @cqrt_copy_f80(i32 %[[OP]], i32 %[[OUT]])
; CHECK:     call void @cq_template_fmul_f80_hl_unc(i32 %[[OP]], i32 %x, x86_fp80 0xK4000C000000000000000)
; CHECK:     ret i32 %[[OUT]]
; CHECK-NOT: floating-point quantum argument or return has no reversible copy
