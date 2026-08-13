; spec_accept_i128_body.ll — Phase 7.1 follow-up n0ui (Tier-1) x Phase 6: a
; classical helper with an i128 INTERMEDIATE now SPECIALIZES. Adding i128 to the
; recognized ABI flips SpecializeReject::unsupportedWidth(i128) false, so a pure
; i32->i32 body whose interior widens to i128 is now specializable (it loud-
; declined "unsupported width" pre-n0ui; cf. the re-pointed
; spec_reject_intermediate_width.ll, now at i256). This pins the expansion is
; SOUND, not a silent over-accept: the clone forward-computes the i128
; intermediates (zext i32->i128 -> mul i128 -> trunc i128->i32), copies out ONLY
; the i32 RESULT (cqrt_copy_i32 — the i128 carriers are NEVER copied, so no
; cqrt_copy_i128 is ever minted), then LIFO-reverses every i128 op via its `_unc`
; twin and frees each rail (whole-clone Bennett uncompute). The i128 intermediate
; is computed-then-uncomputed, never measured, never escaped.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %w  = zext i32 %x to i128
  %sq = mul i128 %w, %w
  %t  = trunc i128 %sq to i32
  ret i32 %t
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.25)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; Caller retargets to the mangled clone.
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_1(
; Clone: forward i128-intermediate chain; out copy is i32 (carriers never copied).
; CHECK:     define internal i32 @__cq_q_helper_1(i32 %x)
; CHECK:     %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i32_to_i128(i32 %x)
; CHECK:     %[[SQ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i128(i32 %[[W]], i32 %[[W]])
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i128_to_i32(i32 %[[SQ]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[T]], i32 %[[OUT]])
; LIFO uncompute of the whole clone via the i128 `_unc` twins; every rail freed.
; CHECK:     call void @cq_template_trunc_i128_to_i32_unc(i32 %[[T]], i32 %[[SQ]])
; CHECK:     call void @cq_template_mul_i128_unc(i32 %[[SQ]], i32 %[[W]], i32 %[[W]])
; CHECK:     call void @cq_template_zext_i32_to_i128_unc(i32 %[[W]], i32 %x)
; CHECK:     ret i32 %[[OUT]]
;
; The i128 carriers are NEVER copied; no i128 core ABI minted.
; CHECK-NOT: cqrt_copy_i128
; CHECK-NOT: cqrt_alloc_i128
