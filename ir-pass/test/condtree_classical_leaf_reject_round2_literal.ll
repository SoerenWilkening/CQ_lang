; condtree_classical_leaf_reject_round2_literal.ll — DECLINE (bd
; test_C_libtooling-xdu2.13, CLAUDE.md L1).
;
; `%c2 = icmp sgt %y, 7` reads the merge φ of a 6.5 classical-call arm. At ROUND-1
; taint the φ is data-untainted (a classical call result and a constant), so the
; 4.4 select over `and (%c2), (%q != 0)` admits `%c2` as a classical `_hl`
; LITERAL. The 6.5 emitter then RAUWs the φ to its `%out` rail and
; `repropagateControlMerges` taints `%c2` — a quantum value in a classical
; literal slot (a Rule-3 crossing). The literal was RECORDED at emission
; (`taint.CondLiteralGates`) and is RE-ASKED after the round-2 fixpoint in both
; entry points (`declineQuantumCondLiterals`), which declines LOUDLY. Mutation
; M-R2 (skip the re-ask) turns this into an exit-0 module carrying
; `cq_template_and_i1_hl(…, i1 %c2)` with `%c2` lowered to a template flag.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: classical condition literal became quantum-derived under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %c2 = icmp sgt i32 %y, 7
  %q2 = icmp ne i32 %q, 0
  %t = and i1 %c2, %q2
  %z = select i1 %t, i32 1, i32 99
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
