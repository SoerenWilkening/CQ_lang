; control_swap_reject_post_region_theta_and_between.ll — DECLINE: precondition
; P5 of the Inc-4 position-aware accept (bd test_C_libtooling-lom0). A theta
; genuinely BETWEEN the compare and the branch still declines, even when a
; second, provably-post-region theta also sits on the wire.
;
; The module carries BOTH gates at once, which is the point:
;   * `%q2 = cq_theta(%q, %t2)` sits between `%c` and the `br` — the flag is
;     minted AT THE BRANCH, so it would read the post-Ry basis while `%c`'s SSA
;     operands denote the pre-Ry record. Permanent decline (MINT_AT_COMPARE.md;
;     the one-gate version is control_swap_reject_stalecond_chained_theta.ll);
;   * `%w = cq_theta(%p, 0.25)` in the merge IS in the Inc-4 accept set — it is
;     dominated by the branch and cannot reach back to it.
; A widening that looked only at the LAST gate on the wire, or that let a single
; provable gate acquit the region, would accept this. It does not: the positional
; compare→branch scan in `condWireDisposition` runs FIRST and unconditionally,
; and the wire walk's position-aware mode returns the first gate it cannot
; prove, so `%q2` decides.
;
; NOTE THE POSITIONAL SCAN IS NOT REDUNDANT WITH THE WALK. It fires on a
; tainted-operand theta between compare and branch EVEN ON ANOTHER WIRE — a
; deliberate over-decline no provenance-seeded walk can reproduce, because that
; theta is on no wire the condition names. Keeping it ahead of the position-aware
; question is what makes "P5 unchanged" true rather than approximately true.
;
; MEASURED IDENTICAL at HEAD (b4e329b) and in this tree:
;     cq controlled lowering: condition predates a non-diagonal gate
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, double %t2, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; BETWEEN compare and branch
  br i1 %c, label %arm, label %merge

arm:
  %g = call i32 @cq_phi_si32(i32 %q2, double %a)
  br label %merge

merge:
  %p = phi i32 [ %g, %arm ], [ %q2, %entry ]
  %w = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)  ; provably POST-region
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
