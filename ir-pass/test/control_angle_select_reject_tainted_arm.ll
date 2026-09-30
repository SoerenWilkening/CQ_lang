; control_angle_select_reject_tainted_arm.ll
;
; One selected angle is quantum data; the current classical by-difference path cannot use it.
;
; Known lowering gap: coherent quantum-derived angles (NORTHSTAR goal 1; bd 94ad).
; The current gate ABI takes a classical double angle. Passing a quantum handle
; into that slot would miscompile the program, so this test pins the loud fence.
; An angle register and bit-controlled rotation ladder can implement the operation;
; its absence is a compiler gap, not a no-unitary proof. Never insert a measure.
; Retire this negative when that lowering preserves the data and angle semantics
; and has analytic and trace evidence for this consumer.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
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
