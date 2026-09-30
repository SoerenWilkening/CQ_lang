; control_swap_reject_switch_value_clobber.ll
;
; The switch scrutinee is p+1; both value arms change p, which its equality flags read.
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
; CHECK: error{{.*}}cq controlled lowering: arm rewrites a condition operand under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %p0) {
entry:
  %p = call i32 @cq_theta_si32(i32 %p0, double 7.000000e-01)
  %q = add i32 %p, 1                       ; the scrutinee READS %p (condProvenance)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = add i32 %p, 1                      ; ... and the arms REWRITE it — the §3c clobber
  br label %merge
a1:
  %v1 = add i32 %p, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
