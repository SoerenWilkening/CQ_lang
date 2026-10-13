; control_angle_select_reject_runtime_arm_quantum.ll — DECLINE: the boundary of
; the run-time-arm widening (bd test_C_libtooling-dm7f.6). The true arm is a
; CLASSICAL run-time parameter (now admitted); the false arm is QUANTUM, the
; result of a `cq_theta_f64` on a live register.
;
;     double qf = 1.0; cq_theta(&qf, 0.25);
;     cq_theta(&r, (q == 5) ? x : qf);       // qf is quantum data in the angle
;
; Admitting run-time arms must not admit a quantum one: that is the f64/angle
; miscompile family (CLAUDE.md R3), whose lowering is the angle register of bd
; `94ad`, not this emitter. S1 asks the arms' TAINT before anything else, so the
; caller's pre-existing `rotation angle` decline fires. Not red-green against the
; pre-change binary (it declined every run-time arm with the same string); the
; fixture pins that the widening did not swallow this cell.
;
; RETIREMENT TRIGGER (L7): when bd `94ad` lowers a quantum-valued angle, this
; becomes an accept of that lowering and this decline must flip with it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)

define i32 @example(i32 %u0, i32 %u1, double noundef %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %qf = call double @cq_theta_f64(double 1.000000e+00, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double %x, double %qf
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
