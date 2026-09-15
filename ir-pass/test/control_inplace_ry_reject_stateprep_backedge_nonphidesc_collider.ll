; control_inplace_ry_reject_stateprep_backedge_nonphidesc_collider.ll — DECLINE
; (F2). THE ISOLATING CONTROL for the back-edge-phi tripwire
; (bd `test_C_libtooling-om35`, round-1 Rule-13 review finding F-F1-1).
;
; THIS FILE IS HALF OF A PAIR. Its twin is
; `control_inplace_ry_reject_stateprep_backedge_phidesc_collider.ll`, which is
; THIS module with ONE operand changed: there the loop-carried phi `%v` takes
; `%carry = icmp sgt i32 %s, 2` on its back edge, and `%s` reads the region's own
; merge phi `%m`; here it takes `%carryX = icmp sgt i32 %k, 2`, which reads the
; CONDITION's own register `%k` and never reaches `%m`. Same loop, same region,
; same seed, same predicate, same constant, same pin: on the true edge `%v` is
; `false` = the arm's seed, so it is a collider in both files.
;
; WHAT IT ISOLATES. `%v` here is NOT in `PhiDesc`, so no exclusion of any kind
; applies to it and F2 must fire on EVERY binary in this family. It therefore
; carries no information about the narrowing itself — which is exactly its job:
; it is the control that makes the twin's verdict attributable to phi-descendant
; MEMBERSHIP and not to the loop, the carried phi, the pin, or the shape.
;
; MEASURED (`trackF/fix_r1_probes/run3.sh`, three binaries, byte sizes printed):
; the frozen 2026-09-14 ORACLE (`cq-opt` sha256 f7b65d8c…, from 59ac5b7), the
; UN-NARROWED subject (147cb3d6…) and the narrowed subject all DECLINE with this
; same string. Zero movement, by design. Its twin moved on the middle one.
;
; ⚠ DO NOT "CONSOLIDATE" THE PAIR. A single fixture cannot distinguish "F2 fired
; because the collider is not a phi descendant" from "F2 fired because the
; dominance skip put a phi descendant back", and that distinction is the whole
; content of the finding this pair pins.
;
; ⚠ RETIREMENT TRIGGER (L8), BY NAME — **FIRED 2026-09-14, DISCHARGED
; 2026-09-14c.** It read: "bd `test_C_libtooling-wx8g`. Like its twin, this
; module is an in-loop state prep and is stopped a second time by that open
; over-decline. The day `wx8g` lands, re-measure the PAIR together." The pair was
; re-measured and both files kept F2's string. ⚠ BUT THE CLAUSE "stopped a second
; time by that open over-decline" WAS FALSE: `wx8g`'s carve-out was
; `if (RailCond && Region.InLoop)`, guarded on a BARE RAIL, and this module's
; condition is a COMPARE — so the pair was never behind that fence and its
; holding is not evidence about the bare-rail spelling. See the twin's header and
; `trackX/X5_REDERIVATION.md`; the bare-rail measurement is
; `trackX/probes/w3` / `w3b` / `w3c`.
; ⚠ THE LIVE OBLIGATION IS UNCHANGED: this file must keep F2's string, and if it
; changes, the twin's verdict has stopped being attributable and the pair has to
; be rebuilt before it means anything.
;
; ⚠ **THE PREDICATE THE PAIR PINS WAS REPLACED ON 2026-09-15 AND THE PAIR DID
; NOT MOVE.** bd `test_C_libtooling-hrts` / `l3i1` / `dpau` replaced
; `!DT.dominates(MergeBB, I->getParent())` with `availableAtAnF2Slot(...)`, asked
; of EVERY user rather than only of phis. The old line was SUFFICIENT for
; "unavailable at both of F2's slots" and not NECESSARY; the gap was an
; OVER-DECLINE whose tripwire
; `control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll` has now
; flipped to the taint-escape string, and whose recovered ACCEPT is
; `control_inplace_ry_stateprep_acyclic_nondominated_phi_accept.ll`. MEASURED:
; this file and its `phidesc` twin BOTH keep F2's string across that landing
; (ORACLE `0e280fc6...` / subject `8cda04ca...`).
;
; ⚠ THE CYCLIC / ACYCLIC FRAMING IS RETIRED (X5, 2026-09-14c). The axis is
; AVAILABILITY: the back-edge phi is the sub-case where the candidate IS
; available at a slot and must stay a rival; the acyclic bypass phi is the
; sub-case where it is not. `wx8g` was never this pair's fence either — both
; files spell their condition as a COMPARE, while the carve-out `wx8g` retired
; was guarded on a BARE RAIL.
;
; ⚠ The IR-text `CHECK-NOT`s below are VACUOUS BY CONSTRUCTION and are kept only
; as belt-and-braces: a `DS_Error` decline writes 0 bytes to stdout, so what pins
; this file is the `not` inversion on the RUN line plus the message match
; (Rule 12(b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define i32 @main() local_unnamed_addr {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %join ]
  %v = phi i1 [ false, %entry ], [ %carryX, %join ]
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %k = add nsw i32 %q, -5
  %c = icmp eq i32 %q, 7
  br i1 %c, label %arm, label %join

arm:
  %t = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %join

join:
  %m = phi i1 [ %t, %arm ], [ false, %loop ]
  %s = select i1 %m, i32 1, i32 %k
  %carry = icmp sgt i32 %s, 2
  %carryX = icmp sgt i32 %k, 2
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %loop

exit:
  %r = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %m)
  %rv = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %v)
  %z = zext i1 %r to i32
  %zv = zext i1 %rv to i32
  %a = add nsw i32 %z, %zv
  ret i32 %a
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)

; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i1_controlled
; CHECK-NOT: cqrt_alloc_i1
