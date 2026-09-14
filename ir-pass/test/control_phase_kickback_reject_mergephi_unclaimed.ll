; control_phase_kickback_reject_mergephi_unclaimed.ll — DECLINE (bd `3qps`,
; Track P). RUNG 0, THE WHOLE PROOF, AND WHAT HAPPENS WHEN IT FINDS NOTHING.
;
; THE SHAPE: a 2-incoming `i1` merge φ whose diamond is guarded by an UNTAINTED
; compare, so `detectControlRegions` never makes a region for it and
; `plan.Regions` holds no `BranchRegion` with this `Merge`. `isCondRailPhiShape`
; — deliberately WEAK (any 2-incoming `i1` φ) — says yes; `preppedRailPhiRegionIdx`
; says `kNoParent`; the kickback declines.
;
; ⚠ THE STRING IS THE SHAPE'S PRE-INCREMENT ONE, AND THAT IS LOAD-BEARING. A φ
; that is the WHOLE condition keeps `branch phase on a bare i1 condition` — the
; message that shape took on the frozen ORACLE, and the honest one (an `i1` value
; this consumer does not lower). Admitting the φ at the GRAMMAR moved it out of
; `collectCondTree`'s `IsCondTree` split, so step 5c reproduces that split
; explicitly. Left alone it silently re-labelled a SHIPPED DISCRIMINATOR —
; `control_phase_kickback_reject_bare_i1_loop_phi.ll` (bd `boi6`) went to
; `control flow` with no change of disposition, caught by `ir-pass-lit` and not by
; any reasoning about this file. The complementary case, a φ as a LEAF of a tree,
; keeps `control flow` (see `control_phase_kickback_reject_mergephi_nest.ll`).
;
; ⚠ THAT ASYMMETRY IS THE DESIGN. The SYNTACTIC half is weak on purpose, because
; the PROOF is not a shape question: it is `ArmClassify::classifyArms`' own
; COMMITTED `Merge`/`ClassArm`/`Shadow` verdict, ASKED BY CALLING THE ONE OWNER
; (Rule 14 — the drbq Inc-3 (b′) defect was a second spelling of a predicate the
; tree already owned). `preppedRailPhiRegionIdx` is that one owner's reader, and
; bd `3qps` made it shared rather than copied: the 4.4 DATA SELECT and this
; kickback call the SAME function, so every rung-0 decline fixture on the select
; side — `control_swap_reject_select_mergephi_{unclaimed,other_class,two_rails,
; value_region,three_incoming}.ll` — pins this consumer's rung 0 too.
;
; ⚠ AND THE ORDER THAT MAKES RUNG 0 ANSWERABLE IS PROVEN, NOT ASSUMED:
; `detectControlRegions` handles each block's TERMINATOR first, and a prep
; diamond's `br` lives in `Pred` while the φ and the `br` that reads it live in
; the MERGE block, which comes later in block order. If that ever stops holding
; the outcome is THIS decline, never a miscompile.
;
; ⚠ ORACLE: `branch phase on a bare i1 condition` at `59ac5b7` — string AND
; disposition both unchanged by this increment.
; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i1 %u0, i32 %n) {
entry:
  %c = icmp sgt i32 %n, 3
  br i1 %c, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK: cq controlled lowering: branch phase on a bare i1 condition under quantum control
