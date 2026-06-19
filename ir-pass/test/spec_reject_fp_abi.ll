; spec_reject_fp_abi.ll — Phase 6.4 WI-4.1: a TAINTED floating-point argument has
; no reversible copy (`cqrt_copy_f*` does not exist — `cqrt-copy-abi-invariant`),
; so a tainted arg that is not an i32 handle declines loudly (the per-Site arg-ABI
; check (A), PRD §2.4/§2.11). Here a handle is `bitcast` to `float` before the
; call, so the helper's tainted parameter arrives as `float`. The `bitcast` is
; itself left un-lowered by CastLowering (out of scope — not a pointer/clone
; concern), but DETECTION declines the specialization first. Recorded in
; `plan6.Diagnosed`, so the carve-out does NOT also emit `kMsgUnknownCallee`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(float %x) {
entry:
  %b = bitcast float %x to i32
  %y = add i32 %b, 1
  ret i32 %y
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qf = bitcast i32 %q to float
  %r = call i32 @helper(float %qf)
  %z = call i32 @cq_measure_si32(i32 %r)
  ret i32 %z
}

; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
; CHECK-NOT: cq taint escape
