; control_phase_kickback_reject_tainted_angle.ll — DECLINE. A TAINTED ANGLE
; (Rule 3, the f64/angle miscompile family).
;
; The one operand of a register-free `cq_phi` is its ANGLE, and an angle is
; CLASSICAL — always, at every width. Here it is the result of a `cq_theta_f64`,
; i.e. quantum data being fed into a gate's classical slot. Lowering it would
; either coerce a quantum value to a `double` literal or allocate a qubit for an
; angle; both are the family Rule 3 exists to close.
;
; THE STRING IS DELIBERATELY THE RETIRED FAMILY'S OWN. `cq controlled lowering:
; rotation angle under quantum control` is what `ArmClassify::taintedAngleGate`
; already emitted for a tainted arg-1 angle on `cq_phi_<sfx>`; the rule did not
; change when the surface did, so the message must not either (Rule 12 — message
; churn is a defect in its own right).
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %d0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = call double @cq_theta_f64(double %d0, double 2.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: rotation angle under quantum control
