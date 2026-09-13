; control_peel_reject_stateprep_two_region_foreign_clone.ll — DECLINE
; `control flow`, and it is the MEASUREMENT behind R-1's sharpest open question
; (bd `test_C_libtooling-rb9x`, increment R-1; `SCOPE_R.md` §3b).
;
; THE QUESTION §3b ASKS. R-1 excludes EVERY value `peelIndependentMergePhis`
; manufactured, on the PREIMAGE ground. The weaker ground people reach for —
; *"the clone is the same compare, on the same wire, as `Region.Condition`"* —
; is true of a ONE-diamond module and false of a two-diamond one: the peel clones
; PER PEELED REGION, so a function with two peelable diamonds produces a clone of
; the OTHER region's condition, which is a DIFFERENT compare on a DIFFERENT wire
; and can still be pinned on THIS region's edge. R-1 excludes that clone too,
; which is strictly MORE than the wire argument licenses — and exactly what the
; preimage argument does license. This file is that shape.
;
; THE SHAPE. Region A is the `i1` state prep; region B is a peelable diamond whose
; condition `%g` is an OPERAND ANCESTOR of region A's condition (so `%g` itself is
; in F2's `CondWire` and is already excluded by the 2026-09-11 narrowing), while
; the peel's clone of `%g`, a sibling, is not:
;
;     %g  = icmp sgt %q, 5            ; region B's condition AND A's cond ancestor
;     %c  = icmp eq (zext %g), 1      ; region A's condition
;     if (%c) b1 = cq_theta(i1 false, .5);      ; <- the prep F2 judges
;     if (%g) { … }  + a peelable `int` φ       ; <- the peel clones %g HERE
;
; ⚠ MEASURED, AND IT IS THE POINT OF THE FILE: **the composition declines
; `control flow` BEFORE F2 is ever asked** — on the ORACLE `fbbe0820ef4b176a` and
; on the R-1 binary alike, with the identical anchor `br i1 %g, label %armB,
; label %mB`. Bisected: region A alone ACCEPTS on both binaries, region B alone
; ACCEPTS on both binaries, and the PAIR declines. The fence is
; `SwapRouteEmit.cpp`'s `sequentialChainAlias`, whose `reorderable()` admits only
; `BranchRegion` and `PhaseKickback` — a state-prep / in-place-rotation region is
; not reorderable, so the `hcrg` precedence graph refuses the chain (the bd `35t0`
; family, an over-decline filed independently of this increment).
;
; SO THIS COMPOSITION IS UNREACHABLE AT HEAD — but `reorderable()` is NOT the
; only wall, and the 2026-09-13 Rule-13 round (`review_R1_r1.md`, item 3a) is the
; measurement that says so. `sequentialChainAlias` is consulted ONLY when two
; regions ALIAS blocks (`A.Pred == B.MergeBB`); two diamonds separated by a
; padding block never ask it. The reviewer built both:
; `review_R1_r1_probes/td2_pad.ll` (B's arm is itself a prep) still declines
; `control flow` on BOTH binaries, while `review_R1_r1_probes/td3_valueB.ll` (B a
; 2-φ VALUE region, padded, no alias) **ACCEPTS on both binaries, byte-identically**
; — so the padded two-diamond composition IS reachable past `reorderable()`. It is
; still not an instance of the §3b hazard, because in `td3_valueB` F2 never fires
; (the `zext`+`icmp eq` between the two conditions breaks the fold chain). Read
; "unreachable" as a statement about the spellings built for this increment and
; NOT as a theorem (L5) — which is precisely why R-1's source comment states the
; PREIMAGE argument and refuses to be re-grounded on the wire.
;
; ⚠ AND THE HAZARD IS SEMANTICALLY DOMINATED — the second, INDEPENDENT argument,
; contributed by the same review (item 3b), and the one to read before blocking
; any widening on this file. Whenever a foreign clone is pinned on this region's
; edge, its ORIGINAL is reached by the same walk and folds to the same constant:
; the clone is a bit-copy (`S.CondCmp->clone()`) so the two have the SAME operands
; — if the clone is visited as a user of a popped `V`, so is the original; the
; original is TAINTED (`MergePhiPeel.cpp` gates the whole peel on
; `taint.Tainted.count(BI->getCondition())`), so F2's `if (!Taint.Tainted.count(I))
; continue;` does not skip it; and they fold identically, because `f2Model`'s
; `ICmpInst` arm reads only the operand ranges and the predicate and `f2Refine`
; passes `CxtI = nullptr` at all four call sites, i.e. it is position-insensitive,
; so a merge-block clone and a pred-block original cannot diverge. Therefore
; exactly one of two things is true of a foreign clone: either the original is NOT
; in `CondWire`, and it still collides so F2 declines WITH OR WITHOUT R-1 (the
; exclusion is a no-op); or the original IS in `CondWire`, and the value the clone
; computes is already blessed as a non-collider ON THIS VERY EDGE by the shipped
; 2026-09-11 narrowing. **R-1 cannot produce an accept the shipped `CondWire`
; exclusion does not already license.**
;
; ⚠ RETIREMENT TRIGGER (L8), and it is the live one: the day bd `35t0` is closed
; — i.e. the day `reorderable()` admits a state-prep region, or the precedence
; graph is replaced — THIS FILE BECOMES AN ACCEPT, and R-1 is then excluding a
; clone of a compare that is NOT the judged region's condition. Do not delete this
; file then: re-derive BOTH arguments against the module that results, and check
; that the accepted stream prepares `%p` on a fresh rail and never rotates `%q` or
; `%g`'s wire. ⚠ What that day does NOT do is make the preimage-vs-wire
; distinction load-bearing for SOUNDNESS — the domination argument above covers
; the foreign clone without it, so this file is not a reason to block the `35t0`
; widening (that would be L6: a structural guard read as a semantic one). The
; preimage argument keeps its own job, which is the clone whose original is
; neither in `CondWire` nor reachable, and the honest ground for the one-diamond
; case; the domination argument sits BESIDE it, not instead of it.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so the IR-text negative below
; is VACUOUS documentation; the property is pinned by the `not` inversion on the
; RUN line plus the string, mirrored character-for-character.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_ry_i1_controlled

define i32 @main() local_unnamed_addr {
entry:
  %q  = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %g  = icmp sgt i32 %q, 5
  %gz = zext i1 %g to i32
  %c  = icmp eq i32 %gz, 1
  br i1 %c, label %armA, label %mA
armA:
  %t  = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %mA
mA:
  %p  = phi i1 [ %t, %armA ], [ false, %entry ]
  br i1 %g, label %armB, label %mB
armB:
  %tb = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %mB
mB:
  %pb = phi i32 [ %tb, %armB ], [ 0, %mA ]
  %mx = phi i32 [ 2, %armB ], [ 5, %mA ]
  %m0 = tail call i32 @cq_measure_si32(i32 noundef %q)
  %m1 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %p)
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %pb)
  %m3 = tail call i32 @cq_measure_si32(i32 noundef %mx)
  %z1 = zext i1 %m1 to i32
  %s1 = add nsw i32 %m0, %z1
  %s2 = add nsw i32 %s1, %m2
  %s3 = add nsw i32 %s2, %m3
  ret i32 %s3
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
