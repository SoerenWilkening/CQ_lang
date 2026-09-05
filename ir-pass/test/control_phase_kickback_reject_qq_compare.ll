; control_phase_kickback_reject_qq_compare.ll — DECLINE. A Q+Q CONDITION
; (PRD §6.3 row 4 and §9: PRE-EXISTING, unchanged by this epic).
;
;     if (q == p) cq_phi(θ);        // both operands quantum
;
; `CompareLowering::lowerCompareToFlag` mints `cq_template_icmp_<pred>_<W>_hl(q,
; lit)` — a HANDLE-and-LITERAL template. There is no Q+Q flag mint at any width,
; so the flag this region needs cannot be built.
;
; ⚠ THE MESSAGE MOVED, AND IT MOVED LAYERS — Rule-13 ROUND-2 finding F-B2-2
; (prep_b2's golden-regeneration measurement). This header used to say the string
; was `no template for opcode 'icmp i1' in tainted context` and that the
; pre-3qlq oracle "emits the same string for the same shape", so "the surface
; change churned no message here". BOTH halves were wrong. Measured from C by
; prep_b2 — the ORACLE declines this shape in the CONTROL layer
; (`control flow under quantum control`) and the subject declined it in the
; OPCODE layer — so the surface change DID churn the message, and it churned it
; downward, out of the layer that owns tainted control.
;
; THAT IS A RULE-1 PROBLEM, NOT COSMETICS, which is why the fix is a fence and
; not a `CHECK` edit. `classifyPhaseKickback` deliberately did not ask whether
; the compare was Q+Q; the region was ACCEPTED at detection and
; `lowerCompareToFlag` returned null at the emitter's step 1, leaving the tainted
; `br` NEITHER CLAIMED NOR DECLINED by the control layer. It was sound only
; incidentally — the mint is the first emission, so nothing had been mutated —
; and it named an OPCODE where the user wrote a BRANCH. `classifyPhaseKickback`
; now asks the question explicitly, for every leaf, before any emission
; (`kQQCondReason`), and P4's nest ladder asks the same one with the same string.
; P5 is exempt structurally: a switch's flags are `scrutinee == <ConstantInt>`,
; so a Q+Q eq-flag cannot be built.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  %c = icmp eq i32 %q, %p
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: quantum-quantum compare condition under quantum control
; It is the CONTROL layer that refuses, not the opcode net: the old string must not return.
; CHECK-NOT: no template for opcode
