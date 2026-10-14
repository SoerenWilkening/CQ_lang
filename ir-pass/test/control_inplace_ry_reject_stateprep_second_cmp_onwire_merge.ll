; control_inplace_ry_reject_stateprep_second_cmp_onwire_merge.ll — DECLINE.
;
; THE FIXTURE THAT STOPS R-1 FROM BEING WIDENED INTO "ANY SECOND COMPARE"
; (bd `test_C_libtooling-rb9x`, increment R-1; `trackR/probes/r_R1b`).
;
; A USER-WRITTEN second tainted compare on the condition's own operand rail,
; defined in the MERGE block (so F2's BACKWARD half cannot see it — the `Cand`
; list filters on `DT->dominates(&In, BI)`) and read as DATA:
;
;     %1 = @cq_theta_si32(0, .5)      ; the condition's rail
;     %2 = icmp eq %1, 1              ; the branch condition
;     if (%2) b1 = cq_theta(i1 false, .5);
;     %clone = icmp eq %1, 1          ; <- the collider: the SAME compare,
;     …                               ;    written by the author, not cloned
;     measure(%clone as i32)
;
; F2's FORWARD half walks every tainted user of the pinned rail `%1` with no
; position filter, folds `%clone` to a singleton `i1` on each edge, and matches
; it against the `i1` seed. It is NOT in `CondWire` (a sibling of the condition
; is not in the condition's BACKWARD cone), and it is NOT in `TaintSet::PeelClones`
; (nothing manufactured it — the merge here carries ONE phi, so
; `peelIndependentMergePhis` never runs). So both exclusions miss it and the
; decline stands.
;
; ⚠ WHY IT MUST STAND, in the words R-1's argument is made of. R-1 excludes the
; peel's clones on the PREIMAGE ground: a value the compiler manufactured has no
; source program behind it, so there is no rival for F2 to protect against. That
; ground does not reach this module — the author DID write this compare, so the
; rival `b1 = <that flag>; cq_theta(&b1, .5)` is a well-formed program and the fold
; image is genuinely ambiguous. A widening spelled as "a second tainted compare
; identical to the region's condition is never a collider" would turn this file
; GREEN and would be an over-accept with no argument behind it.
;
; CONTRAST, and it is the whole increment: `control_peel_stateprep_bool_seed_int_cond.ll`
; is the same collision where the second compare is the PEEL's clone, and it
; ACCEPTS. `…_second_cmp_onwire_pred.ll` is this module with the compare moved
; ABOVE the branch, so the exclusion must cover both positions and this one
; covers neither.
;
; MEASURED: DECLINE on the ORACLE `fbbe0820ef4b176a` AND on the R-1 binary,
; same string, same anchor.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so the IR-text negative below
; is VACUOUS documentation; the property is pinned by the `not` inversion on the
; RUN line plus the string, mirrored character-for-character.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i1_controlled

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %u = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %3, label %5
3:
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %clone = icmp eq i32 %1, 1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %um = tail call i32 @cq_measure_si32(i32 noundef %u)
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %10 = zext i1 %9 to i32
  %cz = zext i1 %clone to i32
  %11 = add nsw i32 %8, %10
  %12 = add nsw i32 %11, %cz
  %13 = add nsw i32 %12, %um
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
