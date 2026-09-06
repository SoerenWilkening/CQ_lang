; control_swap_reject_switch_angle.ll — DECLINE: the merge result reaches a rotation
; arg-1 ANGLE slot (G3, the BLOCKER — no downstream backstop). A double merge phi
; over the cases, used directly as a cq_phi angle. G3 fires BEFORE the G4 FP-fence.
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: rotation angle under quantum control
; NEW: cq controlled lowering: control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; 3qlq: migrated from register cq_phi (angle select -> void call on the select (PRD P2))
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %am = phi double [ 0.000000e+00, %entry ], [ 1.000000e-01, %a0 ], [ 2.000000e-01, %a1 ]
  call void @cq_phi(double %am)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
