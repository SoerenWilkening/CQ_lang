; spec_overaccept_probe_fp_arg.ll — Phase 6.4 WI-4.3 over-accept probe. A tainted
; floating-point ARGUMENT (here in the arg-1 slot, with a classical i32 in arg-0
; to exercise a non-zero mask bit other than bit 0) has no reversible copy. The
; per-Site arg-ABI check (A) declines it: a tainted argument must arrive as an i32
; handle. Guards against a weakening that checks only arg-0 or ignores the arg
; type. (Complements the arg-0 named negative `spec_reject_fp_abi.ll`.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %c, float %x) {
entry:
  %b = bitcast float %x to i32
  %y = add i32 %c, %b
  ret i32 %y
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qf = bitcast i32 %q to float
  %r = call i32 @helper(i32 7, float %qf)
  %z = call i32 @cq_measure_si32(i32 %r)
  ret i32 %z
}

; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
; CHECK-NOT: @__cq_q_helper
