; lowering_reject_select_fp_backstop_operand_angle.ll — DECLINE (fp-data-select-
; PRD §5 matrix 2c, the LEG-3 BACKSTOP): an ACCEPTED fp-data select whose
; tainted fp OPERAND separately feeds a rotation arg-1. Gate 3 walks the select
; RESULT's users, never the operands (an operand angle-use is not a result
; route), and gate 5's coherence walk deliberately cedes arg-1 uses to the angle
; fences — so detection accepts and the merge is EMITTED (mutate-then-decline).
; The backstop still fires: theta lowering RAUWs %q to a handle it INSERTS into
; taint.Tainted (RotationLowering theta loop), so the cq_phi's arg-1 is a
; tainted value at the phi loop and `declineTaintedAngle` exits `opt` non-zero.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: under quantum control
; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %u1, double %x) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %p   = call double @cq_theta_f64(double %u1, double 5.000000e-01)
  %c   = fcmp ogt double %q, 5.000000e-01
  %sel = select i1 %c, double %q, double %x             ; ACCEPTED fp-data select
  %q2  = call double @cq_phi_f64(double %p, double %q)  ; the OPERAND as ANGLE -> backstop
  %m   = call double @cq_measure_f64(double %sel)
  %m2  = call double @cq_measure_f64(double %q2)
  ret double %m
}
