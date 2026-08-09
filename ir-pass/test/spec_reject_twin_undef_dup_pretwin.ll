; spec_reject_twin_undef_dup_pretwin.ll — DECLINE (bd xy9n).
; ARM: the PLACEMENT of the twin-duplication fence — `ensureTwin`, not
; `synthUncomputeTwin`.
;
; *** THE FIRST PLACEMENT OF THAT FENCE SHIPPED THE FULL MISCOMPILE PAST IT, and the
; Rule-13 DELTA round caught it. *** `ensureTwin` short-circuits as soon as a
; `<clone>_unc` DEFINITION already exists:
;
;   void ensureTwin(Function *Clone) {
;     std::string TName = (Clone->getName() + "_unc").str();
;     if (Function *F = Clone->getParent()->getFunction(TName))
;       if (!F->isDeclaration())
;         return;                     <-- returns BEFORE synthUncomputeTwin
;     synthUncomputeTwin(*Clone);
;   }
;
; so a fence living inside `synthUncomputeTwin` is simply never reached when the twin
; is pre-supplied. This module pre-defines `@__cq_q_inner_1_unc` with a body, and on
; the mis-placed draft the outer wrap then called a forward clone and an adjoint twin
; whose bodies EACH carry their own `%c = xor i32 undef, 7` — two independent
; materialisations, `opt` exit 0, `opt -verify` clean, and
; `free_pairing_check.py` 4/4 verified, 0 violations. The rail damage is the bd xy9n
; defect verbatim: `cqrt_copy_i32` XORs f_7(x) into a rail holding f_73903(x), leaving
; it dirty AND entangled, and the `cqrt_free` two lines later is a hidden measurement.
;
; So the fence belongs at the CHOKE POINT (`ensureTwin`'s entry), not at the site that
; happens to do the cloning. Same lesson as bd 7udx's guard living at the ERASE rather
; than at any one claim: put it where the property is decided, not where the mechanism
; is implemented.
;
; Its sibling spec_reject_twin_undef_dup.ll pins that the fence EXISTS; this row pins
; WHERE. Deleting the fence reddens both; moving it back into `synthUncomputeTwin`
; reddens only this one.
;
; REACH, STATED HONESTLY: the trigger is an input module that predefines the
; pass-internal mangled symbol `@__cq_q_inner_1_unc`. That is legal IR and no
; non-adversarial trigger was found — clone names are deterministic
; `__cq_q_<callee>_<mask>` and cannot collide by accident, a cache HIT re-reads a twin
; that WAS fenced, and a pre-existing DECLARATION does not short-circuit. It is
; nonetheless exactly the threat model this change already adopted for
; `isEmittedRuntimeCallee`, whose fixture
; lowering_reject_undef_literal_paired_alias_unc.ll defends against an input defining
; `@cq_template_add_i32_hl_unc` as a `GlobalAlias`. Accepting one and refusing the
; other would be incoherent.
;
; RED-GREEN: the pre-change plugin ACCEPTS this module (`opt` exit 0), and so did the
; mis-placed draft.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: undef/poison operand duplicated into the uncompute twin

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)

define i32 @inner(i32 %a) {
entry:
  %c = xor i32 undef, 7
  %y = mul i32 %a, %c
  ret i32 %y
}

define i32 @outer(i32 %t) {
entry:
  %u = call i32 @inner(i32 %t)
  %r = add i32 %u, 1
  ret i32 %r
}

define internal void @__cq_q_inner_1_unc(i32 %out, i32 %a) {
entry:
  %c = xor i32 undef, 7
  %h_op = call i32 @cq_template_mul_i32_hl(i32 %a, i32 %c)
  call void @cqrt_copy_i32(i32 %h_op, i32 %out)
  call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %a, i32 %c)
  call void @cqrt_free(i32 %h_op)
  ret void
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @outer(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}
