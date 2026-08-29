; lowering_uncompute_interior_leak_escaped_rail.ll — LEAK PROBE (M-B Increment
; 5a, bd test_C_libtooling-6uqc). INVARIANT 1: an interior candidate that ESCAPES
; (here by `ret`) is not a candidate.
;
; `%h_op`'s users are the forward `mul` and a `ReturnInst`. A `ret` is not a
; `CallInst` at all, so `isInteriorTerminalHandle` rejects the rail on the
; "every user must be a call" clause — deliberately BEFORE any name test, because
; the set of non-call users that could keep a handle live (a `ret`, a router
; φ/select, a `store`) is open-ended and each one means a different owner. The
; caller owns a returned handle's reversal (PRD §2.6); freeing it here would be a
; use-after-free across the call boundary that `opt -verify` cannot see.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_escaped(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %b = mul i32 %a, 5
  %m = call i32 @cq_measure_si32(i32 %b)
  ret i32 %a
}

; CHECK-LABEL: define i32 @leak_escaped(
; CHECK: %[[A:.*]] = call i32 @cq_template_mul_i32_hl
; CHECK: call i32 @cq_template_mul_i32_hl(i32 %[[A]]
; CHECK: call i32 @cqrt_measure_i32
; CHECK: ret i32 %[[A]]
; CHECK-NOT: cq_template_mul_i32_hl_unc
; CHECK-NOT: call void @cqrt_free
