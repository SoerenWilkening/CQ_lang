; control_swap_reject_switch_angle_sitofp.ll — DECLINE: the INTEGER merge result
; reaches a rotation arg-1 ANGLE via an int->fp cast (`sitofp i32 %qm to double`).
; The Rule-13 H3 over-accept: G3 is the SOLE backstop for the switch (the emitter
; RAUWs the merge to an untainted handle, so declineTaintedAngle cannot fire later),
; so G3 must cross sitofp/uitofp. The f64/angle miscompile family (Rule 3).
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: rotation angle under quantum control
; NEW: cq controlled lowering: condition data use neither escaped nor measured under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: condition data use neither escaped nor measured under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %ang = sitofp i32 %q to double
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
