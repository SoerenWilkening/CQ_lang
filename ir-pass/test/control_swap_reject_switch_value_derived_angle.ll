; control_swap_reject_switch_value_derived_angle.ll — DECLINE (the WI-3 Rule-13
; clearance probe): a VALUE switch whose DERIVED routed base `%6 = cq_theta(%4,
; sitofp(%4))` carries a QUANTUM-DERIVED (tainted) rotation angle. The switch
; value twin of control_swap_reject_value_derived_tainted_angle.ll (the diamond
; fixture). `clang -O1` output (attribute groups and metadata trimmed) for
;
;     int example(int u0, int v0) {
;       int q = u0; cq_theta(&q, 0.5);
;       int p = v0; cq_theta(&p, 0.25);
;       cq_theta(&p, (double)p);        /* derived routed base, TAINTED angle */
;       switch (q) {
;       case 0: p = p + 3; break;
;       case 1: p = p + 5; break;
;       default: break;
;       }
;       return cq_measure(p);
;     }
;
; A rotation angle derived from quantum data has no fixed unitary today (Rule 3;
; NORTHSTAR goal 1 makes it a GAP, bd 94ad, not a physics decline), so the
; program must fail LOUDLY and source-located, and the value-switch emitter
; must not turn it into a circuit. The switch's straight-through incoming is the
; tainted-angle gate itself, so the forward G3 walk from the merge
; (`mergeReachesRotationArg1`) cannot see it: the angle is UPSTREAM of the merge.
;
; WHO DECLINES IT TODAY. Pre-3qlq the base was the register form
; `%pd = cq_phi(%p, sitofp(%p))` and `proveSwitchValue` declined it BEFORE
; `emitSwitchValueRegion` mutated anything (its derived-base own-angle guard in
; SwitchArmProve.cpp, the Rule-9 detect-before-mutate pin, string `rotation angle
; under quantum control`). That guard matches only the retired `cq_phi_<sfx>`
; family (`isPhiCall`; its own comment calls it VACUOUS since 3qlq), so for the
; in-place Ry base the decline now comes from
; `RotationLowering`'s `declineTaintedAngle` in `lowerRotations`, which runs
; after `lowerControlRegions` (loud either way; the pre-mutation question is reported with bd
; jttf). The asserted string is that clause's.
;
; History: the 3qlq migration turned the base into a register-free `cq_phi(f)`
; OUTSIDE the switch (no derived base at all); bd jttf (2026-10-05) re-spelled
; it as the tainted-angle in-place Ry above, which restores the derived routed
; base this file was written for. (The retired stdout `CHECK-NOT`s were vacuous
; on a decline, R10, and are not carried over.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved); jttf: re-spelled register-free 2026-10-05

define i32 @example(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01) #2
  %5 = sitofp i32 %4 to double
  %6 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %5) #2
  switch i32 %3, label %11 [
    i32 0, label %7
    i32 1, label %9
  ]

7:                                                ; preds = %2
  %8 = add nsw i32 %6, 3
  br label %11

9:                                                ; preds = %2
  %10 = add nsw i32 %6, 5
  br label %11

11:                                               ; preds = %2, %9, %7
  %12 = phi i32 [ %6, %2 ], [ %10, %9 ], [ %8, %7 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #3
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
