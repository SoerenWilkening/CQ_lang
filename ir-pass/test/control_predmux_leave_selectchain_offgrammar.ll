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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
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
