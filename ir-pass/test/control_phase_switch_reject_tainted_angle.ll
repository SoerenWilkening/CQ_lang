; control_phase_switch_reject_tainted_angle.ll
;
; A switch arm feeds quantum-derived data to register-free cq_phi argument 0.
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

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)

define i32 @example(i32 %u0, double %a0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = call double @cq_theta_f64(double %a0, double 1.000000e-01)
  switch i32 %q, label %merge [
    i32 0, label %c0
    i32 1, label %c1
  ]
c0:
  call void @cq_phi(double %ang)
  br label %merge
c1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: rotation angle under quantum control
