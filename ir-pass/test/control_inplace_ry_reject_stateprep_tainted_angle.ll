; control_inplace_ry_reject_stateprep_tainted_angle.ll
;
; A literal state-preparation seed does not make its quantum-derived angle classical.
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
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ad = sitofp i32 %q to double
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double %ad)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
