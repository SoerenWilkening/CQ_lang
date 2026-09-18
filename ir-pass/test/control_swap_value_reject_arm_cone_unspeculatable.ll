; control_swap_value_reject_arm_cone_unspeculatable.ll — DECLINE, and it is the
; DISCRIMINATOR for the cone's (K4) conjunct (bd test_C_libtooling-fn1q, inc 1).
;
; `if (q > 5) { p += k / n; }` — the cone is the same shape
; control_swap_value_accept_arm_cone.ll accepts, with ONE difference: a `udiv` by a
; RUN-TIME classical `%n`, which `isSafeToSpeculativelyExecute` refuses because the
; divisor may be zero.
;
; ⚠ WHY THIS MUST DECLINE RATHER THAN BE HOISTED ANYWAY, and it is the whole
; reason the conjunct is not optional: the hoist runs the op UNCONDITIONALLY, and
; that is not a choice — the condition is QUANTUM, so the emitted circuit has no
; classical branch to hide the division behind. A source program in which `n` is
; zero on the arm's non-taken path has NO undefined behaviour; the hoisted form
; does. Over-declining is safe; hoisting a trapping op is a miscompile the trace
; cannot see (it is a classical fault, not a wrong gate).
;
; Without this file the (K4) conjunct would be indistinguishable from "hoist every
; classical arm op", and the next reader would have no way to tell which it is.
; The ACCEPT side of the same opcode family is
; control_swap_value_reject_speculation.ll's sibling
; control_swap_value_accept_div_const.ll (a non-zero CONSTANT divisor).
;
; ⚠ THE `not` INVERSION ON THE RUN LINE IS WHAT PINS THE PROPERTY. A `DS_Error`
; decline writes 0 bytes to stdout, so an IR-text `CHECK-NOT` here would be
; VACUOUS (CLAUDE.md Rule 12, fixture-hygiene defect (b)). The message match on
; stderr and the non-zero exit are the assertion.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@k = global i32 0
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %kk = load i32, ptr @k, align 4
  %k1 = udiv i32 %kk, %n            ; CONE candidate — divisor may be ZERO
  %v1 = add i32 %p, %k1
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: cq controlled lowering: impure value arm under quantum control
