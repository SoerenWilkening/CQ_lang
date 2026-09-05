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
; wire — over-decline is safe), on a theta user anywhere on the condition's
; tainted PROVENANCE wire — seeded via condProvenance, so it covers both the
; sunk-compare layout (control_swap_reject_stalecond_sunk_compare.ll) and the
; derived-condition layout (control_swap_reject_stalecond_derived_cond.ll) —
; and on a compare outside the pred block (the scan cannot be bounded).
; Minting the flag at the COMPARE's program point was investigated and
; REJECTED (test_C_libtooling-ee5): it fixes arm selection but no flag-freeing
; compilation of this shape is source-exact — the decline is PERMANENT. See
; docs/design/rssa-swap-control/MINT_AT_COMPARE.md (oracle:
; investigation_mint_at_compare.py).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %t2, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained Ry AFTER the compare
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
