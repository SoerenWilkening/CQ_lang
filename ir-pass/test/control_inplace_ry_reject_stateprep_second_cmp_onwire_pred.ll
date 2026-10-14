; control_inplace_ry_reject_stateprep_second_cmp_onwire_pred.ll — DECLINE.
;
; THE SECOND POSITION (bd `test_C_libtooling-rb9x`, increment R-1;
; `trackR/probes/r_R5`). `…_second_cmp_onwire_merge.ll` puts the user's second
; compare in the MERGE block, where only F2's FORWARD half can reach it. This
; module puts the SAME compare in the ENTRY block, ABOVE the branch, where it
; DOMINATES `BI` and is therefore also a `Cand` entry that LVI is asked about
; directly on each edge (`ArmClassify.cpp`'s backward half).
;
; ⚠ WHY BOTH POSITIONS ARE FIXTURED. F2 has two halves that reach a collider by
; different routes, and R-1's record is consulted at the ONE test both halves
; funnel through. A hypothetical widening that filtered only the forward walk —
; or only the `Cand` list — would leave the other route open, and exactly one of
; these two files would notice. Neither position is excluded by R-1 (nothing here
; is manufactured), so BOTH must stay red; they are the pair that says so.
;
; This module is also the position-half of the reason R-1 is spelled at the TEST
; rather than at the anchor: the anchor is where the `Cand` list is consulted,
; and the 2026-09-11 measurement of an anchor-spelled `CondWire` was that ALL 40
; F2 fixtures flip. R-1 inherits that discipline verbatim.
;
; MEASURED: DECLINE on the ORACLE `fbbe0820ef4b176a` AND on the R-1 binary,
; same string, same anchor.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so the IR-text negative below
; is VACUOUS documentation; the property is pinned by the `not` inversion on the
; RUN line plus the string, mirrored character-for-character.
; bd p3kd.21 R11 r2 F1 (bd r2j3.35, 2026-10-15): `main` now MEASURES the value it
; returns. A register returned from `main` reaches the process exit status without
; `cq_measure`, which NORTHSTAR goal 1 forbids and the pass now refuses
; (spec_reject_gate_sub_main_return.ll); the measurement is outside this fixture's
; subject, which is unchanged.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i1_controlled

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %clone = icmp eq i32 %1, 1
  %2 = icmp eq i32 %1, 1
  br i1 %2, label %3, label %5
3:
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %5
5:
  %6 = phi i1 [ %4, %3 ], [ false, %0 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %10 = zext i1 %9 to i32
  %cz = zext i1 %clone to i32
  %11 = add nsw i32 %8, %10
  %12 = add nsw i32 %11, %cz
  %cq.main.m = call i32 @cq_measure_si32(i32 %12)
  ret i32 %cq.main.m
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
