; lowering_reject_tainted_angle_theta.ll
;
; The sitofp result feeds the second cq_theta call, whose angle is argument 1.
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

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = sitofp i32 %q to double                  ; TAINTED angle producer
  %q2 = call i32 @cq_theta_si32(i32 %u1, double %ang)
  %m = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
