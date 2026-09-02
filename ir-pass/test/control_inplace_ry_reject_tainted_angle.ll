; control_inplace_ry_reject_tainted_angle.ll — DECLINE: the arm rotation's ANGLE
; is quantum-derived (control-in-place-PRD §4 R2; Rule 3; bd
; test_C_libtooling-drbq).
;
; The arg-1 angle of a rotation is CLASSICAL, per-operand-use, always: a
; quantum-derived angle names no fixed unitary, and the emitter would have to pass
; a qubit HANDLE in the `double` slot — the f64/angle miscompile family.
;
; This is checked in the rotation-arm clause and not by the pre-existing
; `taintedAngleGate`, and that is the finding worth pinning: `taintedAngleGate`
; walks a `cq_phi` SPINE from the arm's merge incoming and inspects a derived
; base, so it never looks at a `cq_theta` sitting AT the incoming and returns null
; for this module. Same predicate (`rotationAngleIsTainted`, one spelling), same
; message, new asker.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, double %a) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r   = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %ang = call double @cq_theta_f64(double %a, double 2.500000e-01)
  %c   = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double %ang)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
