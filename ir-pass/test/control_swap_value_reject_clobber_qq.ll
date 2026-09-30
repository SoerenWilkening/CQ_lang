; control_swap_value_reject_clobber_qq.ll
;
; The q+p arm has a second quantum operand and changes the condition register.
;
; Safety net for the current condition/arm lowering (NORTHSTAR goal 1).
; Reversing the predicate from a changed source can leave its flag dirty; freeing
; that flag would introduce an implicit measurement. Preserve the loud fence.
; A coherent basis copy or retained source history can preserve the original
; condition while an out-of-place arm computes its answer. CNOT basis fanout is
; valid and does not clone an unknown quantum state. This is a lowering gap.
; Retire this negative after a proved lowering preserves the predicate, answer
; and interference, and cleans any rail it frees without an implicit measure.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
; CHECK-NOT: value-arm swap-route

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = add i32 %q, %p       ; Q+Q link over the CONDITION register %q
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
