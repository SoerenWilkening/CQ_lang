; control_swap_reject_straightthrough_cross_handle.ll — DECLINE (a8c0 re-anchor
; boundary): a folded straight-through whose condition constrains a DIFFERENT
; handle than the arm rotates.
;
; The condition `icmp eq %p, 0` folds the straight-through incoming to `0` (p == 0
; on that edge), but the arm applies the phase to `%q`, a SEPARATE qubit. So
; `phi [phase(q), 0]` genuinely depends on both p and q — a cross-handle
; multiplexer, NOT a phase arm over one routed qubit (the `icmp_eq_inv(p)` strip
; could not return the flag to |0> while the rail carries a phase of q).
; `straightThroughConstFoldHandle` requires the compare's handle `H` to EQUAL the
; arm's phase-spine `Base`; here `H = %p` but `Base = %q`, so it returns null and
; the region declines loudly. The re-anchor does not weaken the cross-handle gate
; (Prime Directive; mirrors the eq-fold D3 cross-handle decline).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp eq i32 %p, 0                  ; condition constrains %p ...
  br i1 %c, label %merge, label %arm
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)   ; ... but the arm rotates %q
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ 0, %entry ]       ; straight-through folded from p==0
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
