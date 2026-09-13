
; control_swap_reject_select_mergephi_unclaimed.ll — DECLINE (bd `boi6` D-B /
; Track M, probe `m20`; the same shape as boi6's `p5`). GREEN ON BOTH BINARIES.
;
; A φ whose two incomings ARE on one wire (`%armv`'s arg-0 IS `%seed` — a CHAINED
; arm theta, an IN-PLACE Ry) and whose diamond is guarded CLASSICALLY, so no
; tainted `br` and therefore NO REGION. Rung 0 asks `plan.Regions` and finds
; nothing; gate 2 fires `control flow`.
;
; ⚠ READ THIS TOGETHER WITH `control_swap_accept_select_mergephi_rail.ll`, because
; the pair is the whole distinction Track M rests on and `SCOPE_boi6.md` §0.3 got
; it backwards for the owner's file. THIS module's arm theta is CHAINED, so an
; in-place NON-DIAGONAL Ry sits on the condition's own wire and gate 2c
; (`findNonDiagonalWireGate`) would answer DIRTY even if a region existed. The
; owner's prep is a SOURCE theta (`cq_theta_i1(i1 false, .5)`) with a constant
; seed on the other edge, so the backward closure stops at the classical arg-0
; and the producing theta is ON-ANCESTRY EXEMPT — the wire is CLEAN. MEASURED,
; not argued: probes `m11`/`m12`/`m26` accept on the ORACLE with COMPAREs over
; that same φ.
;
; So this file keeps declining for TWO independent reasons, and the outer one
; (no region) is the one the string names. bd `drbq.7` owns the wire half.

; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main(i32 %n) {
entry:
  %seed = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  %c = icmp sgt i32 %n, 3
  br i1 %c, label %arm, label %merge
arm:
  %armv = call zeroext i1 @cq_theta_i1(i1 zeroext %seed, double 2.000000e-01)
  br label %merge
merge:
  %p = phi i1 [ %armv, %arm ], [ %seed, %entry ]
  %sel = select i1 %p, i32 2, i32 5
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %p)
  %z1 = zext i1 %m1 to i32
  %m2 = call i32 @cq_measure_si32(i32 %sel)
  %s = add nsw i32 %z1, %m2
  ret i32 %s
}

; CHECK: cq controlled lowering: control flow under quantum control
