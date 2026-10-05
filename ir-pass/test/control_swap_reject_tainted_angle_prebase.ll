; control_swap_reject_tainted_angle_prebase.ll — DECLINE: the DERIVED BASE's own
; angle is quantum-derived. `clang -O1` output (attribute groups and metadata
; trimmed) for
;
;     int example(int u0, double a) {
;       int q = u0; cq_theta(&q, 0.5);
;       cq_theta(&q, (double)q);        /* derived base, TAINTED angle */
;       if (q > 5) cq_phi(a);           /* a phase region on the derived base */
;       return cq_measure(q);
;     }
;
; `%5 = cq_theta(%3, sitofp(%3))`, the pre-region rotation whose result the phase
; region's condition reads, carries a TAINTED angle (the sitofp of the handle's
; own value). The arm's angle is classical, so only a check of the BASE's angle
; catches this. A rotation angle derived from quantum data has no fixed unitary
; today (Rule 3; NORTHSTAR goal 1 makes it a GAP, bd 94ad), so the module must
; fail loudly and source-located.
;
; WHO DECLINES IT TODAY. Pre-3qlq the base was the register form
; `%qd = cq_phi(%q, sitofp(%q))`, caught pre-mutation by `taintedAngleGate`'s
; base check; before that check existed it was a broken-module abort (rotation
; lowering cross-type-RAUW'd the f64 angle to an i32 handle inside an emitted
; call that was never erased — LLVM ERROR, exit 134). That base check matches
; only the retired `cq_phi_<sfx>` family, so for the in-place Ry base the decline
; now comes from `RotationLowering`'s `declineTaintedAngle`, which runs after
; `lowerControlRegions` (loud and source-located; the pre-mutation question is reported with bd jttf). The
; asserted string is that clause's.
;
; History: the 3qlq migration turned the base into a register-free `cq_phi(f)`
; ahead of the region (no derived base at all); bd jttf (2026-10-05) re-spelled
; it as the tainted-angle in-place Ry above.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved); jttf: re-spelled register-free 2026-10-05

define i32 @example(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %4 = sitofp i32 %3 to double
  %5 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #2
  %6 = icmp sgt i32 %5, 5
  br i1 %6, label %7, label %8

7:                                                ; preds = %2
  tail call void @cq_phi(double noundef %1) #3
  br label %8

8:                                                ; preds = %7, %2
  %9 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare void @cq_phi(double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
