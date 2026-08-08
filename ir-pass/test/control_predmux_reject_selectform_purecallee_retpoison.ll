; control_predmux_reject_selectform_purecallee_retpoison.ll — DECLINE
; (bd 3c6m.14.2). ARM: the DELETED pure-callee disjunct in the shielded-cone
; call admission.
;
; *** THIS IS THE FIXTURE FOR THE ONE THAT WAS EXHIBITED END-TO-END. *** The
; bd 3c6m.14.2 ticket filed the pure-callee clause as "a REAL FENCE GAP with an
; unproven exploit". It is not unproven. On the pre-fix plugin this exact module
; produced a verify-clean SILENT MISCOMPILE:
;
;   opt exit 0 · opt -verify clean · free_pairing_check STRICT 6/6 verified
;   define internal i32 @__cq_q_leaf_1(i32 %a) { ret i32 poison }
;
; — a Bennett clone RETURNING LITERAL POISON as an i32 QUBIT HANDLE, which the
; caller then feeds to `cq_template_icmp_sgt_i32_hl` AND to that compare's `_unc`
; adjoint on a rail it goes on to `cqrt_free`. Linked against the runtime and run
; at the shipped -O0 stage 3, the poison handle materialised as `h0` — the `%q`
; rail itself — so the circuit computed
;     (q > 3) ∧ (q > 0)      instead of      (q > 3) ∧ (leaf(q) > 0)
; i.e. the wrong unitary, silently. Trace, verbatim, from that run:
;     cq_template_icmp_sgt_i32_hl(h0, 3) -> h3
;     cq_template_icmp_sgt_i32_hl(h0, 0) -> h4      <-- must have been leaf(q)'s rail
;
; WHY THE OLD PROOF LET IT THROUGH: `isSpeculatablePureCalleeBodyImpl` skips
; terminators, so a body whose only instruction IS a terminator passes
; VACUOUSLY. Nothing about the RETURNED VALUE was ever examined.
;
; THIS SHAPE IS ALSO WHY THE FIX IS A DELETION AND NOT A SECOND PROOF. A
; body-opcode whitelist over the callee — the ticket's direction (a), which was
; written first — would NOT have caught it: there is no non-terminator
; instruction to whitelist. Catching it needs a return-value check, which is one
; more clause on a proof whose measured population was already empty (1 of 949
; fixtures, 0 of 238 slices), and whose next clause (the curated immarg, see
; control_predmux_reject_selectform_curated_poison_immarg.ll) was itself found by
; the Rule-13 round to be a fresh silent miscompile. The clause was deleted.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; Pure, total, terminating, acyclic, exactly-defined, non-varargs — it passes
; every clause of `isSpeculatablePureCalleeBody` because there is nothing in it
; to fail one.
define i32 @leaf(i32 %a) {
  ret i32 poison
}

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = call i32 @leaf(i32 %q)
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
