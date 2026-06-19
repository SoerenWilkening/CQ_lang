; spec_overaccept_probe_i128_return.ll — Phase 6.4 WI-4.3 over-accept probe. A
; callee returning a width with no reversible copy (here i128) declines via the
; return-ABI gate: `abiWidthFromType(i128)` is empty, so there is no `cqrt_copy_*`
; for the Bennett copy-out. Reached BEFORE the body whitelist (the return check is
; scanBody step 2), so the i128 RETURN — not the i128 intermediate — is the
; rejecting fact. Guards against a weakening that accepts a non-i32 return width.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i128 @helper(i32 %x) {
entry:
  %w = zext i32 %x to i128
  ret i128 %w
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i128 @helper(i32 %q)
  %z = call i32 @cq_measure_si32(i32 %q)
  ret i32 %z
}

; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
; CHECK-NOT: @__cq_q_helper
