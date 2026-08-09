; spec_reject_twin_undef_dup_transitive.ll — DECLINE (bd xy9n).
; ARM: `findUndefOperandInBody`'s TRANSITIVE reach over directly-called defined
; callees. The only row that pins it.
;
; *** ITS SIBLING FIXTURES DO NOT PIN THIS, AND THE ARM-KILL PROVED IT. *** In both
; spec_reject_twin_undef_dup.ll and ..._pretwin.ll the `undef` sits DIRECTLY in the
; clone body, so reverting the scan to body-only leaves them GREEN — an earlier arm
; aimed at them reported a clean pass while testing nothing. Here the undef lives in a
; `noinline` classical helper the specialized callee CALLS, so the clone body itself
; contains no undef operand at all and only the transitive walk finds it.
;
; THE SHAPE. `@helper` is SHARED, not cloned: the BASE output has one
; `define internal i32 @helper()` and THREE calls to it — from `@inner`, from the
; forward clone `@__cq_q_inner_1`, and from the adjoint twin `@__cq_q_inner_1_unc`. So
; the twin duplicates the CALL rather than the computation, and one static `undef` slot
; is read once per call.
;
; *** HONEST STATUS: THE DIVERGENCE IS UNPROVEN, THE GUARANTEE IS ABSENT. *** Linked at
; the shipped -O0 stage 3 and run twice (byte-identical, so not ASLR), both reads gave
; the SAME value — `cq_template_mul_i32_hl(h0, 7)` in the forward and
; `cq_template_mul_i32_hl(h0, 7)` in the twin — so this row exhibits NO wrong circuit
; today, and the Rule-13 delta lens that found the shape reported it as UNSURE for
; exactly that reason.
;
; It is fenced anyway, and the reason is the one this change already had to relearn
; once: `undef` gives NO guarantee that two dynamic reads agree, and "they happened to
; agree in the probe I ran" is precisely the reasoning behind the retracted claim
; "one slot is one materialisation" (measurably false inside a rolled loop — one static
; slot, six reads, two values). A fence resting on an accident is not a fence.
; Over-declining is safe; under-declining is the unforgivable direction.
;
; COST, measured four ways by that round: ZERO. Across 966 fixtures + 257 e2e stage-1
; modules + 251 openlibm modules the full BASE-vs-SHIP differential moves nothing
; (verdict 0, IR 0); only 8 modules reach the twin site at all and all 8 are
; undef-free; and all 115 undef/poison-bearing modules in the three corpora reach it
; zero times.
;
; RED-GREEN: the pre-change plugin ACCEPTS this module (`opt` exit 0) and emits both
; clone and twin calling the shared `@helper`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison operand duplicated into the uncompute twin

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @helper() noinline {
entry:
  %c = xor i32 undef, 7
  ret i32 %c
}

define i32 @inner(i32 %a) {
entry:
  %m = call i32 @helper()
  %y = mul i32 %a, %m
  ret i32 %y
}

define i32 @outer(i32 %t) {
entry:
  %u = call i32 @inner(i32 %t)
  %r = add i32 %u, 1
  ret i32 %r
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @outer(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}
