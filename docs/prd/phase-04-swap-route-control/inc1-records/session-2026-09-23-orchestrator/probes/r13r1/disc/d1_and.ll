; control_predmux_reject_rail_leaf_under_xor.ll — DECLINE (bd
; test_C_libtooling-fn1q increment 2). THE `Strict` BOUNDARY OF THE RAIL LEAF.
;
; A bare rail composed under a TWO-OPERAND `xor i1` with a compare. E6 admits
; such an xor (bd 3c6m.67, the `s_nextafterl.c:55` ulp-direction test) but forces
; BOTH children into `Strict` — `collectCondTree`'s narrower substrate grammar —
; because that is what makes the ¬(a ⊕ b) = a ⊕ ¬b identity safe to apply without
; routing the kept operand through `canonicalizePred`. The rail leaf is admitted
; ONLY when `!Strict`, so it declines here.
;
; ⚠ THIS IS A SCOPED CONSERVATIVE DECLINE, NOT A CLAIM THAT THE SHAPE IS UNSOUND.
; `collectCondTree` itself carries a rail leaf at ANY position of an and/or/XOR
; tree (bd 3qlq.4, widened to interior positions by bd 4aiu), so the substrate
; downstream would very likely take it. What is missing is the ARGUMENT: relaxing
; `Strict` is the accept widening `isSupportedCondTree`'s own header refuses in
; writing — "its own decline fixtures, its own probe family, its own round, and a
; fresh proof that ¬(a⊕b) = a ⊕ ¬b is still safe when the kept operand needs
; rewriting rather than passing through". Nothing measured wants it today.
;
; ⚠ RETIREMENT TRIGGER (L8). The day `Strict` is relaxed — or the day the rail
; leaf is admitted under it — this file becomes an ACCEPT, and its emitted stream
; is the xor node's `cnot(L,G); cnot(Rv,G)` network over ONE `RailLeaves` entry
; and one compare leaf. RE-DERIVE IT THEN; DO NOT DELETE IT. A decline fixture
; whose subject no longer exists pins nothing (CLAUDE.md Rule 12 hygiene (c)).
;
; ⚠ THE IR-TEXT `CHECK-NOT`s BELOW ARE VACUOUS BY CONSTRUCTION AND THAT IS FINE
; (hygiene (b)): a `DS_Error` decline writes 0 bytes to stdout, so the property is
; pinned by the `not` inversion on the RUN line and by the stderr match, not by
; them. They are here to say WHICH accept must not appear if the shape ever
; half-lowers.
;
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = icmp sgt i32 %q, 1
  %x = and i1 %b, %c
  br i1 %x, label %arm, label %merge
arm:
  br label %merge
merge:
  %a4 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %b5 = phi i32 [ 2, %arm ], [ 6, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %m3 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %m3
  ret i32 %s2
}

; CHECK: error:
; CHECK-SAME: cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_copy_i32_controlled
