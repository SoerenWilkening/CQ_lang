; control_swap_reject_switch_value_clobber.ll — DECLINE (G7 §3c clobber, the ONLY
; G7 fixture in the tree; the §3c clobber is a value-arm-only proof).
;
; A tainted `switch` whose VALUE arms rewrite the very register the SCRUTINEE
; reads. Routing + rewriting `%p` while the eq-flags are minted from a value
; derived from `%p` clobbers the wire the flag-STRIP reads back: the strip's
; premise (`icmp_inv` sees the same basis the mint saw) dies with the rewrite,
; and it is information-theoretically impossible to both keep `%p`'s answer and
; disentangle the scrutinee (`SwitchArmProve.cpp`, `proveSwitchValue`).
;
; ===========================================================================
; 3qlq(prep_a2): HAND DECISION — RE-SPELLED, and the old spelling is GONE for a
; reason worth stating rather than hiding.
;
; WHAT THIS FIXTURE USED TO BE. The scrutinee was `%q = cq_phi_si32(%p, θ)` — a
; DIAGONAL derivation of the routed base. `cq_phi` was an Rz, so `%q` and `%p`
; were SSA-DISJOINT but WIRE-IDENTICAL (RAUW collapses them to one handle), and
; the fixture existed to prove that G7 tests the physical WIRE and not SSA value
; identity. It reached the decline through `diagonalAliasHit`'s HOP — the walk up
; the `cq_phi` arg-0 chain.
;
; WHY IT CANNOT BE SPELLED THAT WAY ANY MORE, MEASURED. `diagonalAliasHit`
; (ArmClassify.cpp) hops only through `isPhiCall`, and `isPhiCall(V)` is
; `isCallToPrefix(V, "cq_phi_")` — the RETIRED register-form family. Since
; round-1 finding F-L6-1 that name is RESERVED and any module declaring it
; declines before analysis runs, so no module that reaches `diagonalAliasHit`
; can contain one. **Its hop loop is therefore structurally unreachable at HEAD,
; and so is `walkPhaseSpine`'s** (same prefix test). What survives is the
; ZERO-HOP arm of the same function — `Prov.count(V)` on entry — which is the
; `Hit == P` case that renders this exact string. Under D1 no value carries a
; relative phase, so "SSA-disjoint but wire-identical" has no spelling at all;
; the property that remains is the one below.
;
; THE RE-SPELLING. The scrutinee is now an ARITHMETIC derivation (`add i32 %p, 1`)
; rather than a diagonal one. `condProvenance` still puts `%p` in the scrutinee's
; read set, the straight-through base is still `%p`, and `P != condition`, so
; `proveSwitchValue` reaches `diagonalAliasHit` at zero hops and renders the
; PERMANENT string. Same clause, same message, one branch shallower.
;
; ⚠ MUTATION-VALIDATED AS A DISCRIMINATOR, both ways (prep_a2, measured on
; `build/ir-pass/cq-opt`; probes under $SP/progress/prep_a2_work/g7/):
;   * WITH the clobber (this module, and the `xor`/`mul` scrutinee variants):
;     exit 1, `arm rewrites a condition operand under quantum control`.
;   * WITHOUT it — the identical module with the arms rewriting a SECOND,
;     disjoint `cq_theta` register (`g7/f_control.ll`): exit 0, ACCEPTS.
;   * The pre-existing `control_swap_switch_value.ll` is that accepting
;     no-clobber shape as a committed fixture, so the pair is a discriminator in
;     the tree and not only in a scratch directory.
;   * A THIRD variant is NOT this decline and is recorded so it is not mistaken
;     for one: making the scrutinee `%p` ITSELF hits `proveSwitchValue`'s C2
;     mis-anchor first (`value-arm swap-route`), because the routed base and the
;     condition are then the same value. The derived scrutinee is load-bearing.
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
