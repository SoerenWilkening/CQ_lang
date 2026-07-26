; control_predmux_reject_i1phi_single_pred.ll — DECLINE (3c6m.14 L6 Inc 5, bd
; q2wk; PRD §4.4b rule (A) condition 3): the UNIQUE-INCOMING-BLOCK fence on the
; i1 phi Inc 5 admitted as an E6 condition-tree node.
;
; `%flag` here is a DEGENERATE phi: `%ijoin` has exactly ONE predecessor, so the
; phi carries a single unique incoming block. `convertPhis` gates its
; boolean-algebra path on `In.size() > 1` (In dedups by incoming BLOCK) and for a
; one-entry phi falls into the chain branch, where `Acc = In.back().second` runs
; the fold loop zero times — i.e. it RAUWs the phi straight to its incoming
; instead of building ∨ᵢ(EP(eᵢ) ∧ vᵢ). `isConvertiblePhiCond` mirrors that with
; its `SeenPreds.size() < 2` rejection so the CLAIM cannot promise a
; path-predicated condition the EMITTER will not build. Without the mirror the
; claim would rest on a taint the flatten never materializes: rule (B) admits
; `%flag` as "will taint after flatten" because it is a region-internal phi, but
; a degenerate phi RAUW'd to an untainted incoming stays classical, and the muxed
; select becomes a classical mux over tainted data (the residual-risk note at the
; E6 rule-(B) gate). E6-condtree fires instead and the region falls through
; byte-untouched to the existing loud swap-route decline.
;
; Everything else about `%flag` is deliberately IN-grammar — i1 typed, parent
; inside the region and not the entry block, incoming a compare leaf over non-i1
; operands, and the branch is genuinely tainted so rule (B) is not load-bearing —
; so the ONLY reason this declines is the unique-predecessor count. The twin with
; `%ijoin` given a second predecessor (`control_predmux_accept_i1phi_cond.ll`'s
; two-edge shape) ACCEPTS under this same plugin; keep the two in step.
;
; NOTE on the sibling degenerate form (a phi listing the SAME block twice, out of
; `br i1 %c, label %X, label %X`): it can never reach this fence. PredMux's
; adia Lever-C `foldConstantConesInFunction` runs `ConstantFoldTerminator` first,
; which rewrites the duplicate-successor branch to `br label %X` and collapses the
; now-single-entry phi away — pre-existing, plugin-independent normalization. The
; one-predecessor form below is the shape that actually survives to E6.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %inner, label %sideb
inner:
  %ca = icmp slt i32 %q, 3
  br label %ijoin
ijoin:                                            ; ONE predecessor: %inner
  %flag = phi i1 [ %ca, %inner ]
  br i1 %flag, label %ta, label %tb
ta:
  %va = add i32 %q, 3
  br label %tjoin
tb:
  %vb = mul i32 %q, 3
  br label %tjoin
tjoin:
  %tv = phi i32 [ %va, %ta ], [ %vb, %tb ]
  br label %merge
sideb:
  %u = mul i32 %q, 7
  br label %merge
merge:
  %rm = phi i32 [ %tv, %tjoin ], [ %u, %sideb ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; The PredMux claim leaves at gate=E6-condtree on `br i1 %flag` (CQ_PREDMUX_DBG=1),
; the region is untouched, and ControlDetect owns the decline:
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
