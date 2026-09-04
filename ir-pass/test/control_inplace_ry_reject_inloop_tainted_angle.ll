; control_inplace_ry_reject_inloop_tainted_angle.ll — DECLINE (PRD §13.2 row R2):
; a TAINTED ANGLE on an in-loop Ry arm.
;
; Rule 3: the arg-1 angle of a rotation is CLASSICAL, per-operand-use. A
; quantum-derived angle has no fixed unitary and the emitter would replay it as a
; handle tag — the f64/angle miscompile family. R2 is asked before the loop clause
; and before R6, so the loop is irrelevant to the verdict and the message is the
; angle one.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

declare double @cq_theta_f64(double, double)
define i32 @example(i32 %u0, i32 %u1, double %a0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %ta = call double @cq_theta_f64(double %a0, double 5.000000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double %ta)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
