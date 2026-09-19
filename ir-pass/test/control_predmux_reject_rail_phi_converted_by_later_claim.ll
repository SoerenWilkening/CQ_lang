; control_predmux_reject_rail_phi_converted_by_later_claim.ll — DECLINE, and the
; RE-ASK that makes increment 5a's placement conjunct a CHECKED property rather
; than a POINT-IN-TIME one (bd test_C_libtooling-woa0; found by Rule-13 ROUND 3 on
; the M4 fix, finding F-R3-1, P2).
;
; WHAT THE CONJUNCT PROMISES AND WHERE THE PROMISE STOPS. M4 admits a rail φ at
; E6 only when `RPB == S->Entry || !S->InRegion->count(RPB)` — "a φ THIS flatten
; will not convert". That is true of the region being claimed and FALSE of the
; pipeline: `flattenPredMuxRegions` claims ONE region per call inside a
; `while (...)` fixpoint, and nothing re-asks E6 about a region already emitted.
;
; THE COMPOSITION, measured on the shipping M4 binary before this fence existed:
;   1. the outer region (entry `%entry`, merge `%Bm`) holds the rail-φ block `%A`
;      as an INTERIOR block, so M4 correctly refuses it at E6;
;   2. `%A` then claims — its φ is at `%A`'s OWN entry, which M4 admits — and
;      flattens, which makes `%A`'s terminator UNCONDITIONAL;
;   3. on the next fixpoint pass the outer region's E6 loop walks only
;      CONDITIONAL terminators, so it no longer sees the rail φ, claims, and
;      `convertPhis(%A)` SELECT-CHAINS the very φ that `%A`'s already-emitted
;      predicate tree was built from.
;
; ⚠ WHY A FENCE AND NOT AN ARGUMENT. Before this file the composition landed on a
; loud decline ONLY because `collectCondTree` refuses the resulting
; `xor`-of-`select` — which Rule-13 round 2 named "a downstream accident, not a
; fence", verbatim, one round before round 3 built this shape. Round 3 argued
; analytically that it cannot produce a wrong unitary (`convertPhis`' RAUW is
; value-preserving, and the unsound `buildNegation` select arm is intra-region)
; and both constructed instances declined — but it did not prove it exhaustively,
; and an argument plus an absence of a probe is not a proof. This is CLAUDE.md's
; L1 one stage over, and its standing cure is what is now applied: RECORD the
; question at the site that asks it, RE-ASK it after the fixpoint, in BOTH entry
; points, declining loudly.
;
; PROVENANCE: hand-written, and deliberately so — the shape needs an outer region
; that CLAIMS on a later pass, which `clang -O1` is unlikely to emit (round 3's
; natural-block-order twin `x2` is byte-identical on all three binaries, so block
; order is the whole trigger). Kept verbatim from
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-26-orchestrator/probes/woa0/x3_outer_declines_then_claims.ll`.
;
; NON-VACUITY, MEASURED BY MUTATION (both directions):
;   ORACLE (M4, git 18d18728)  -> rc=1, `control flow under quantum control`
;                                 — the DOWNSTREAM ACCIDENT, a different owner
;   FIXED                      -> rc=1, the string below, from the re-ask
; So this file is RED on the pre-fence binary for a reason that is not "it stopped
; declining": it declines there with the WRONG OWNER, which is the defect.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; ⚠ THE GATE-PREFIXED LINE IS THE LOAD-BEARING ASSERTION, not the error string
; (the increment-3 round-2 lesson, and round 3's F-R3-8 on this very family): the
; same string would be printed by this owner for ANY converted recorded φ, so the
; event line below pins WHICH φ in WHICH block was converted. A string-only pin
; goes green on a binary that converts a different φ for a different reason.
; ⚠ THIS PARAGRAPH DOES NOT SPELL EITHER PREFIX, BECAUSE NAMING A FileCheck
; DIRECTIVE IN PROSE CREATES ONE — CLAUDE.md's standing lesson, paid for three
; times in three sessions and once in this very fixture family.
; CHECK: error{{.*}}cq controlled lowering: emitted predicate tree's rail phi converted by a later flatten
; DBG: CQ_PREDMUX_DBG: converted recorded rail phi @probe blk=A phi=%rp
; DBG: error{{.*}}cq controlled lowering: emitted predicate tree's rail phi converted by a later flatten
;
; ⚠ RETIREMENT TRIGGER (L8). This is a DECLINE-direction fence over a composition
; that is REALIZABLE, so by the 2026-09-11 owner ruling it is compiler structure,
; not physics. The route that removes the defect rather than fencing it is the one
; bd `test_C_libtooling-41g3` names: RECORD the φ so `convertPhis` cannot
; select-chain it at all (for a rail φ the boolean-algebra path yields
; `and(EP, %rail)`, which IS in `collectCondTree`'s grammar because a rail leaf is).
; The day that lands, this file becomes an ACCEPT and its emitted stream must be
; re-derived from scratch. DO NOT DELETE IT THEN, and do not weaken the E6
; conjunct instead — that is the change that produced the wrong unitary this
; family exists for.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)

define i32 @probe(i32 %u) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 9
  br i1 %c, label %Bt, label %Bm
Bt:
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %Bt2, label %A
Bt2:
  br label %A
A:
  %rp = phi i1 [ %b, %Bt2 ], [ false, %Bt ]
  br i1 %rp, label %Aarm, label %Am
Aarm:
  br label %Am
Am:
  %v  = phi i32 [ 2, %Aarm ], [ 5, %A ]
  %v2 = phi i32 [ 3, %Aarm ], [ 6, %A ]
  br label %Bm
Bm:
  %o  = phi i32 [ 7, %entry ], [ %v, %Am ]
  %o2 = phi i32 [ 8, %entry ], [ %v2, %Am ]
  %m1 = call i32 @cq_measure_si32(i32 %o)
  %m2 = call i32 @cq_measure_si32(i32 %o2)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
