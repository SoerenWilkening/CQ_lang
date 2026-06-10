; control_swap_reject_stalecond_chained_theta.ll — DECLINE: a chained Ry sits
; between the compare and the branch.
;
; `c = (q > 5); q = cq_theta(q, t2); if (c) { rz(q, a) }` — the condition is
; compared BEFORE a chained, tainted-operand `cq_theta` (an in-place,
; NON-diagonal Ry) on the same wire. The swap-route emitter mints the flag at
; the BRANCH position, so the minted flag would read the post-Ry basis — a
; predicate of the WRONG state: the wrong arm fires AND icmp_inv cannot return
; the flag to |0> (independent statevector probe, §8 adversarial review
; 2026-06-10: q overlap 0.853 vs source semantics, residual flag P(1)=0.118 — a
; verify-clean silent miscompile, pre-existing since the WI-3 accept).
;
; Contrast the ACCEPTED stale-condition fixture
; (control_swap_ifelse_derived_stalecond.ll): there the gate between compare
; and use is an Rz — DIAGONAL, basis-preserving — so mint-at-branch equals the
; source compare. Diagonality is precisely the load-bearing property; an
; intervening Ry breaks it. The guard declines conservatively on ANY
; tainted-operand cq_theta between the compare and the branch (even on another
; wire — over-decline is safe), and on a compare outside the pred block (the
; scan cannot be bounded). The principled fix — minting the flag at the
; COMPARE's program point — is a deferred design question (bd follow-up).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %t2, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained Ry AFTER the compare
  br i1 %c, label %arm, label %merge
arm:
  %q3 = call i32 @cq_phi_si32(i32 %q2, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q3, %arm ], [ %q2, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
