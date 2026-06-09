; control_swap_reject_clobber.ll — §3c PERMANENT reject (SCOPING §3c).
;
; The one shape the swap-route emitter must DECLINE loudly even once it accepts
; phase-arm diamonds/if-else: an arm that VALUE-CHANGES a quantum variable the
; branch condition transitively reads. The flag is `icmp(q0)`; once the arm
; overwrites q's computational-basis value, NO control model and NO Bennett copy
; can produce a clean disentangled answer (conservation of information). This
; stays a permanent decline through 4.2+; it is NOT a "pending" transitional one.
;
; Detection is pure SSA-value analysis BEFORE any mutation (Rule 9): the arm's
; merge contribution is a value-changing redefinition (`add`, not a rotation) of
; %q, and %q is the diamond's straight-through (Pred-edge) incoming, which is in
; the transitive taint provenance of the branch condition.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = add i32 %q, 3        ; VALUE-changes %q — clobbers the condition's input
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
