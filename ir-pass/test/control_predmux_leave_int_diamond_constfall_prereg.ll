; control_predmux_leave_int_diamond_constfall_prereg.ll — LEAVE (bd 0rwu, W7
; CONTAINMENT pin, the one E4 does NOT cover): an a8c0 straight-through
; const-fold diamond with an EMPTY arm.
;
; This is the single shape that forced W7's interior-instruction fence, and it
; is worth stating why the OTHER fences do not reach it. The a8c0 re-anchor
; (`straightThroughConstFoldHandle`) is the only path in `ArmClassify` that
; ACCEPTS a `ConstantInt` straight-through: it proves the branch's equality
; condition makes the folded literal equal the routed qubit on that edge, and
; re-anchors `Routed` to the qubit. Every other a8c0 diamond in the suite holds
; a `cq_phi` CALL in its arm, so E4 (no calls but tainted-arg pure bodies)
; excludes it from any PredMux claim — see control_swap_straightthrough_constfold.ll.
; An EMPTY arm holds NOTHING for E4 to reject: the arm block is a bare `br`, the
; whole region passes E2/E3/E4/E6/E7, and the merge phi
;     %qm = phi i32 [ %q, %arm ], [ 0, %entry ]
; is a sole 2-incoming muxable INTEGER phi with DISTINCT incomings and a
; `ConstantInt` on the entry edge. Witness clauses (a)-(c) all hold. Without
; clause (d) — the interior-instruction fence, so labelled in PredMuxFlatten.cpp —
; W7 would therefore STEAL A SHIPPED ACCEPT — the exact failure mode
; the W anti-overlap witness exists to prevent, and one no measurement in the
; libm census would have surfaced (its 2 target cells both have interior arms).
;
; Clause (d) — the non-constant incoming must be an instruction defined in a
; region INTERIOR block — excludes it: `%q` is defined in the region ENTRY. That
; is not a coincidence of this fixture but structural, and it is what makes the
; fence a PROOF rather than a shape observation: a8c0 requires `H == Base`, where
; `H` is the non-constant operand of the ENTRY block's equality condition and is
; therefore defined in the entry or earlier — never in an interior block.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='cqrt_copy_i32_controlled' --implicit-check-not='cq_template_icmp' < %t.cqd0.ll
; RUN: env CQ_PREDMUX_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 0
  br i1 %c, label %merge, label %arm      ; q==0 -> merge (straight-through)
arm:                                      ; EMPTY arm — nothing for E4 to reject
  br label %merge
merge:
  %qm = phi i32 [ %q, %arm ], [ 0, %entry ]   ; straight-through FOLDED to 0
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; The region keeps its a8c0 owner, which classifies an EMPTY phase arm (no gates)
; and correctly dissolves the diamond to the identity — the routed qubit is
; measured directly, with NO flag mint, NO out rail and NO controlled copy.
;
; WHICH LINES ACTUALLY WITNESS THAT, stated precisely because the Rule-13 round
; caught an earlier draft getting it wrong. That draft asserted "both negatives
; below turn red on one" leak, using leading `CHECK-NOT: cqrt_copy_i32_controlled`
; and `CHECK-NOT: cq_template_icmp_eq_i32_hl`. Measured against a byte-accurate
; emulation of the (d)-removed leak: the second negative is UNFALSIFIABLE — a leak
; here mints `icmp_NE_i32_hl`, so a negative naming `icmp_eq` can never fire — and
; the first fired only incidentally, via a trailing `declare` line, because a
; leading `CHECK-NOT` is scanned only over [start of input .. first CHECK match].
; Both are now `--implicit-check-not` flags on the RUN line, which scan the WHOLE
; output and are predicate-agnostic (`cq_template_icmp` matches either polarity).
; The two lines that were genuinely sensitive all along are kept and are the
; primary witnesses:
;   * the final positive CHECK — a leak measures the controlled-copy OUT rail, not
;     the qubit `%[[H]]`, so this line fails; and
;   * the DBG line — a CLAIM prints nothing, so `gate=W-witness` disappearing is
;     the direct observation that the region was claimed rather than left.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])

; The real witness that the region was LEFT rather than claimed-and-degenerate.
; DBG: CQ_PREDMUX_DBG: leave @probe entry=entry merge=merge gate=W-witness
