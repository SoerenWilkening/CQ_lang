; spec_overaccept_probe_fp_arg.ll — bd 3c6m.54 over-accept probe. A tainted fp128
; ARGUMENT in the arg-1 slot (with a classical i32 in arg-0 to exercise a non-zero
; mask bit other than bit 0). fp128 has no reversible copy
; (`abiWidthHasReversibleFpCopy(fp128)` is false — not shipped on this x86-64
; build), so the per-Site arg-ABI check (A) declines it. Guards against a
; weakening that admits EVERY fp width instead of exactly {f16,f32,f64,f80}, or one
; that checks only arg-0. (The arg-0 named negative is `spec_reject_fp_abi.ll`; the
; reversible-fp arg accepts are `spec_accept_fp_*.ll`.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define i32 @helper(i32 %c, fp128 %x) {
entry:
  %b = fptosi fp128 %x to i32
  %y = add i32 %c, %b
  ret i32 %y
}

define i32 @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qe = fpext double %q to fp128
  %r = call i32 @helper(i32 7, fp128 %qe)
  %z = call double @cq_measure_f64(double %q)
  %zi = fptosi double %z to i32
  ret i32 %zi
}

; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
; CHECK-NOT: @__cq_q_helper
