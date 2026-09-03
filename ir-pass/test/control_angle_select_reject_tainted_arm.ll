; control_angle_select_reject_tainted_arm.ll — DECLINE (S1): ONE of the select's
; angle operands is TAINTED (bd drbq Inc 2b).
;
; `%qf` is a quantum register whose value is used as the TRUE angle. That is the
; f64/angle miscompile family verbatim (Rule 3: the arg-1 angle of a rotation is
; classical; quantum-derived data in it has no fixed unitary), and the
; by-difference lowering makes it no better — `A - B` would be a quantum
; subtraction whose result the emitter would hand to a `double` angle slot.
;
; S1 returns `NotApplicable`, so the pre-existing gate-3 decline fires unchanged:
; this is one of the shapes whose disposition and diagnostic are BYTE-IDENTICAL
; before and after the increment.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %qf = call double @cq_theta_f64(double 1.000000e+00, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double %qf, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
