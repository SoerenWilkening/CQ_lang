; spec_mangle_padding.ll — Phase 6.2 WI-2.2: the mangle-padding / bit-order pin
; (DD-5). A THREE-parameter callee with ONLY arg0 tainted has mask `0b001`. The
; mangle renders the mask MSB-first, ZERO-PADDED to `callee->arg_size()`, param0
; the RIGHTMOST char — so the clone is `@__cq_q_f_001`, NOT `@__cq_q_f_1`. The
; padding is load-bearing: an unpadded mask would collapse `0b001` and `0b1` both
; to "1" and alias different-arity clones under `llvm-link` (DD-5). Both classical
; params (%b, %c) pass through their `_hl` templates at their original i32.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a, i32 %b, i32 %c) {
entry:
  %t = add i32 %a, %b
  %r = mul i32 %t, %c
  ret i32 %r
}

define void @example(i32 %u0, i32 %b, i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %y = call i32 @f(i32 %q, i32 %b, i32 %c)
  %m = call i32 @cq_measure_si32(i32 %y)
  ret void
}

; Retarget to the ZERO-PADDED, 3-char mangle (param0 rightmost): `_001`, not `_1`.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[Y:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_f_001(i32 %[[H]], i32 %b, i32 %c)
;
; Clone: both classical params pass through their `_hl` templates unchanged.
; CHECK:     define internal i32 @__cq_q_f_001(i32 %a, i32 %b, i32 %c)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %a, i32 %b)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[T]], i32 %c)
;
; The unpadded "_1" mangle must NEVER be emitted (the collision class).
; CHECK-NOT: @__cq_q_f_1(
