; control_swap_reject_derived.ll — §3c reject via TRANSITIVE condition provenance.
;
; Adversarial sibling of control_swap_reject_clobber.ll: the condition does not
; read %q directly — it reads %t = q + 1. The arm still value-changes %q, and %q
; is in the condition's provenance only TRANSITIVELY (through %t). The backward
; provenance walk (ArmClassify::condProvenance) must thread through %t to reach
; %q; a non-transitive (one-hop) walk would miss it and silently mis-accept — the
; exact verify-clean miscompile class this fixture guards against.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = add i32 %q, 1         ; condition reads a DERIVED value of %q
  %c = icmp sgt i32 %t, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = add i32 %q, 3        ; VALUE-changes %q (transitively in cond provenance)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
