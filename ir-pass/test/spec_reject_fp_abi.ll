; spec_reject_fp_abi.ll — bd 3c6m.54: after the fp-ABI lift, a tainted arg of a
; REVERSIBLE-fp width {f16,f32,f64,f80} is ADMITTED (see spec_accept_fp_arg_return.ll);
; the residual FpAbi decline is a tainted arg of a width with NO reversible copy.
; Here fp128 — `abiWidthFromType(fp128)` is empty (not shipped on this x86-64
; build; the only sound c_type is a real 128-bit fp) so it is not in
; `abiWidthHasReversibleFpCopy`, and the per-Site arg-ABI check (A) declines it.
; Recorded in `plan6.Diagnosed`, so the carve-out does NOT also emit
; `kMsgUnknownCallee`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define i32 @helper(fp128 %x) {
entry:
  %t = fptosi fp128 %x to i32
  ret i32 %t
}

define i32 @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qe = fpext double %q to fp128
  %r = call i32 @helper(fp128 %qe)
  %z = call double @cq_measure_f64(double %q)
  %zi = fptosi double %z to i32
  ret i32 %zi
}

; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
; CHECK-NOT: cq taint escape
