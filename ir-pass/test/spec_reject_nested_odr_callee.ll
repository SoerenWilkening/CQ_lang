; spec_reject_nested_odr_callee.ll — DECLINE twin of spec_accept_odr_callee.ll
; (bd test_C_libtooling-p3kd.2): an ODR callee is lifted only as the TOP callee of
; a candidate (the call is retargeted to its clone, so the analyzed body is the
; body that runs). Reached as a NESTED callee, its call can stay a CLASSICAL call
; to the LINKED body inside a clone (`buildClone` leaves a mask-0 inner call
; alone), and `synthUncomputeTwin` copies the clone verbatim, so the linked body
; runs TWICE. With `@bump` external, main 7b4e6359 emits (measured):
;   __cq_q_inner_1:      %c = call i32 @bump(i32 3)
;                        add_i32_hl(a, %c) ... add_i32_hl_unc(h_op, a, %c)
;   __cq_q_inner_1_unc:  %c = call i32 @bump(i32 3)          <- second execution
;                        add_i32_hl(a, %c); cqrt_copy_i32(h_op, out); ...
;   __cq_q_outer_1:      ... call @__cq_q_inner_1_unc(%t, %a); cqrt_free(%t)
; The twin zeroes `%t` only if both executions of `@bump(3)` return the same
; value. For an exact definition that is the analyzed body (`scanBody` proved it
; pure). For a `linkonce_odr` one the linker may bind a differently optimized
; variant of the same source (LLVM's derefinement: e.g. one that still reads an
; indeterminate value this copy folded away), which need not be deterministic:
; then `%t` is dirty and `cqrt_free(%t)` is a hidden measurement. So a nested
; callee must have an EXACT definition (`calleeBodyTrusted(F,
; AssumeOfLinkedCall)`), and this declines, character for character.
; This is conservative for a nested ODR callee that WOULD be cloned (a tainted
; argument): building that needs the mask-0 test at `buildClone`'s inner loop,
; a follow-up outside this change.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define linkonce_odr i32 @bump(i32 %x) {
entry:
  %y = add i32 %x, 1
  ret i32 %y
}

define i32 @inner(i32 %a) {
entry:
  %c = call i32 @bump(i32 3)
  %y = add i32 %a, %c
  ret i32 %y
}

define i32 @outer(i32 %a) {
entry:
  %t = call i32 @inner(i32 %a)
  %y = mul i32 %t, 3
  ret i32 %y
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @outer(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK: error{{.*}}in function bump{{.*}}cq specialization: callee has a non-link-exact definition (interposable/derefinable linkage); the linker may bind a different body
