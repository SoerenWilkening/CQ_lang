; control_swap_reject_switch_angle.ll — DECLINE: the merge result reaches a rotation
; arg-1 ANGLE slot (G3, the BLOCKER — no downstream backstop). A double merge phi
; over the cases, used directly as a cq_phi angle. G3 fires BEFORE the G4 FP-fence.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
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
