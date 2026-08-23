; control_predmux_accept_xor_negation.ll — ACCEPT (bd 3c6m.67), AND THE FIXTURE
; THAT EXISTS TO CATCH ONE SPECIFIC SILENT MISCOMPILE.
;
; A nested region whose branch condition is a two-operand `xor i1` of two
; compares — the ulp-direction test from `src/s_nextafterl.c:55`. The FALSE edge
; needs ¬(a ⊕ b), and XOR is the one node in the grammar that does NOT De
; Morgan-distribute, which is why it was never admitted alongside and/or.
;
; THE IDENTITY IS CHEAP AND IT IS THE WHOLE DESIGN:
;     ¬(a ⊕ b) = a ⊕ ¬b
; Negate exactly ONE operand and keep a SINGLE xor node. No leaf duplication, so
; the no-NOT invariant (PRD-3c6m.14 §4.3) is not actually threatened: every
; emitted tree still contains only compare leaves and and/or/xor nodes, and the
; negation still lives at a LEAF.
;
; *** WHY THIS FIXTURE IS NOT OPTIONAL. *** Before this increment
; `buildNegation` handled `Instruction::Xor` with an UNCONDITIONAL
;     return BO->getOperand(0);   // xor-true: ¬¬x = x
; which is correct ONLY because E6 admitted nothing but `xor X, 1`. Widen E6
; without touching that line and ¬(a ⊕ b) silently evaluates to `a` — the false
; edge is then predicated on the wrong condition, `opt` exits 0, the verifier is
; clean, `free_pairing_check.py` reports zero violations (every rail still pairs
; — the network is structurally perfect and only its VALUE is wrong), and the
; trace looks entirely plausible. It is the verify-clean silent miscompile this
; project exists to prevent, and no gate but this CHECK would have seen it.
;
; THE TWO ASSERTIONS THAT PIN IT, and they are a matched pair:
;   * `icmp_sge_hl(q,9)` MUST appear — the inverted twin of the `slt 9` leaf. It
;     is absent under the old `return operand(0)` bug (the false literal would
;     collapse to the bare `sgt 1` compare).
;   * `icmp_sle_i32_hl` MUST NOT appear ANYWHERE — it is the inverted twin of
;     the `sgt 1` leaf, and it shows up only if the implementation negated BOTH
;     operands. That is not a near-miss, it is the identity function:
;     ¬a ⊕ ¬b = a ⊕ b, i.e. the false edge predicated on the TRUE condition.
;     A whole-file prefix is used so the negative scans the entire module rather
;     than the tail after the last positive match.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WHOLE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ca = icmp sgt i32 %q, 1
  %cb = icmp slt i32 %q, 9
  %cc = xor i1 %ca, %cb
  br i1 %cc, label %inband, label %merge
inband:
  %v1 = add i32 %q, 1
  %c2 = icmp eq i32 %q, 4
  br i1 %c2, label %four, label %merge
four:
  %v2 = add i32 %q, 12
  br label %merge
merge:
  %rm = phi i32 [ %q, %entry ], [ %v1, %inband ], [ %v2, %four ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; the TRUE-edge literal keeps both leaves verbatim:
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 1)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 9)
; the FALSE-edge literal is a ⊕ ¬b — ONE inverted leaf, and it must be THIS one:
; CHECK-DAG: call i32 @cq_template_icmp_sge_i32_hl(i32 %[[Q]], i32 9)
; the region really did flatten and merge:
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
;
; negating BOTH operands is the IDENTITY, not a near-miss — `sle 1` must never
; be emitted, anywhere in the module:
; WHOLE-NOT: cq_template_icmp_sle_i32_hl
; the region is fully linearized:
; WHOLE-NOT: br i1
; WHOLE-NOT: phi i32
; WHOLE-NOT: select i1
