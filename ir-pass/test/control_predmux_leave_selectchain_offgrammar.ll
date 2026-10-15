; control_predmux_leave_selectchain_offgrammar.ll — LEAVE→DECLINE (bd 20xt.5.1
; blocker (e) companion / over-accept fence).
;
; Same NESTED-region shape PredMux claims + flattens as the accept fixture
; control_predmux_accept_selectchain_foldresidue.ll, but the residual select's
; condition is a GENUINELY off-grammar `xor i1 %t, true` (a boolean NOT) — NOT a
; constant-fold residue. The 20xt.5.1 residue fold is deliberately scoped to
; constant-operand i1 and/or + constant-condition / same-arm selects (Rule 14 —
; InstSimplify only over a gated residue shape), so it CANNOT fold a `xor` and
; leaves this untouched. `collectCondTree` then rejects the `xor` (the no-NOT
; and/or-over-compare-leaves grammar) and declines loudly — proving the fold
; does not widen the accept surface for a genuinely unlowerable condition
; (Prime Directive: over-accepting is the one unforgivable miscompile).
;
; ⚠ FLIPPED TO AN ACCEPT by bd test_C_libtooling-dm7f.77 (the file keeps its
; name, L8). The fence this pinned — the residue fold must not turn an off-grammar
; NOT condition into an ACCEPT — still holds for the FOLD (it does not touch the
; `xor`); what changed is that the NOT condition is now LOWERABLE on its own: the
; select's condition `xor %t, true` is tagged a fresh REGISTER CONDITION
; (RegCondLeaf.h), lowered out of place (`xor_i1_hl(cmp, 1)`, a fresh rail) and read
; through the 4.4 copy flag. Every `cqrt_x` brackets an ancilla (`bf` / node `g`),
; never the user's register `%h`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; RUN: %filecheck %s --check-prefix=NOX < %t.ll
; NOX-NOT:     call void @cqrt_x(i32 %h)
; CHECK-LABEL: define i32 @probe(
; The NOT is lowered by M-C IN PLACE on the compare flag it negates (that flag is
; dead after it): `cqrt_xorc_i1(flag, 1)`; the flag's rail is the register
; condition from there on (its tag moves with it, ArithLowering.cpp).
; CHECK:       %[[N:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 3)
; CHECK-NEXT:  call void @cqrt_xorc_i1(i32 %[[N]], i1 true)
; CHECK:       %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[N]], i32 %[[BF]])
; ARM POLARITY (R11 round 1, C-F1), derived by hand from the source: the copy
; merge fires its UNBRACKETED copy when the condition holds and its
; `cqrt_x`-bracketed copy when it does not, so the first copy's source must be
; the select's TRUE operand and the bracketed copy's source its FALSE operand.
; `%va = select !t3, 100, %q`: TRUE = 100, FALSE = %q (the register `%h`).
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  %[[K:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 100)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[K]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %h, i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[BF]])
; CHECK:       call void @cqrt_cnot(i32 %[[N]], i32 %[[BF]])
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %inner, label %merge
inner:
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %ia, label %ib          ; nested tainted branch -> PredMux claim
ia:
  %t3  = icmp eq i32 %q, 3
  %oc  = xor i1 %t3, true                   ; off-grammar NOT (not a residue)
  %va  = select i1 %oc, i32 100, i32 %q     ; declines: xor leaf in the cond tree
  br label %ijoin
ib:
  %vb = add i32 %q, 7
  br label %ijoin
ijoin:
  %vj = phi i32 [ %va, %ia ], [ %vb, %ib ]
  br label %merge
merge:
  %r  = phi i32 [ %vj, %ijoin ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
