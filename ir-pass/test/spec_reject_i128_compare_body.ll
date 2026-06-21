; spec_reject_i128_compare_body.ll — Phase 7.1 follow-up n0ui (Tier-1) DECLINE
; probe. icmp is OUT of the i128 frozen surface, so a clone-body `icmp i128` must
; decline at DETECTION (source-located on the helper body op), mirroring
; CompareLowering's i128 fence — NOT over-accept into the clone and backstop LATE
; at lowerOps naming the synthesized clone (the WI-1.13 "detection mirrors
; lowerOps" invariant). The i128 ARITHMETIC intermediate (zext/icmp operand width)
; is a recognized Tier-1 width, but the COMPARE at i128 has no template; the
; scanBody compare-width gate keys on the OPERAND width == "i128" (exact mirror of
; CompareLowering, so a legitimate fcmp f32/f64 in a clone stays accepted).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %w = zext i32 %x to i128
  %c = icmp ugt i128 %w, 100        ; icmp at i128: OUT of the frozen surface
  %z = zext i1 %c to i32
  ret i32 %z
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.25)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; Source-located on the helper body op, with the precise "unsupported width" kind
; (not a late, clone-named lowerOps backstop).
; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported width)
; CHECK-NOT: @__cq_q_helper
; CHECK-NOT: cq_template_icmp{{.*}}i128
