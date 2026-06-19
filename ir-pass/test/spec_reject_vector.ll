; spec_reject_vector.ll — Phase 6.4 WI-4.1: a callee body with a VECTOR/SIMD data
; op has no per-lane reversible-copy story (`cqrt_copy` is scalar), so it is a
; non-reversibilizable construct (PRD §2.11). Here a classical `<2 x i32>`
; pass-through argument feeds a vector `add`; `touchesVector` rejects the op
; (taint-agnostic — over-declining a classical vector op is always safe, Prime
; Directive). The tainted scalar `i32` argument is a clean handle, so the per-Site
; arg-ABI check passes and the body scan reaches the vector op. Recorded in
; `plan6.Diagnosed`, so the carve-out does NOT also emit `kMsgUnknownCallee`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x, <2 x i32> %v) {
entry:
  %s = add <2 x i32> %v, %v
  %e = extractelement <2 x i32> %s, i64 0
  %y = add i32 %x, %e
  ret i32 %y
}

define i32 @example(i32 %u0, <2 x i32> %v) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, <2 x i32> %v)
  %z = call i32 @cq_measure_si32(i32 %r)
  ret i32 %z
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (vector SIMD)
; CHECK-NOT: cq taint escape
