; spec_reject_ret_undef_derived.ll — DECLINE (bd 3p2a).
; ARM: the CONE part of `returnDerivesFromUndef` — the walk, not just the operand.
;
; WHY THE OPERAND CHECK ALONE IS NOT THE FIX. bd u1rp's round already recorded
; this exact failure once ("an arguments-only undef/poison scan fences depth 1"),
; and it recurs verbatim here: a one-line `slotCarriesUndef(R->getReturnValue())`
; catches `ret i32 poison` and walks straight past
;
;     %c = xor i32 poison, 7
;     ret i32 %c
;
; because `%c` is an Instruction, not a Constant. Measured on the pre-change
; plugin, this module is ACCEPTED (`opt` exit 0) and `@__cq_q_leaf_1` is emitted
; carrying the `xor` verbatim — the same "returns no function of its arguments"
; certificate as the literal spelling, one hop up. So this file is what makes the
; predicate a WALK rather than a test, and it goes red the moment anyone
; "simplifies" it back.
;
; TERMINATION is structural, not budgeted: a `Seen` set over the visited values.
; A budget inside a yes/no predicate makes the ANSWER depend on the cut-off
; (bd memory budget-in-a-memo-and-probes-with-no-power-2026-08-08), and the body
; is not proven acyclic at this point — a loop-carried `phi` would diverge without
; the set.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee return value denotes no value (undef/poison)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 %a) {
entry:
  %c = xor i32 poison, 7        ; an INSTRUCTION — invisible to an operand check
  ret i32 %c
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @leaf(i32 %q)
  %d = add i32 %q, %s
  %m = call i32 @cq_measure_si32(i32 %d)
  ret void
}
