# Issue a8c0 — straight-through const-fold re-anchor (design + Rule-13 record)

`test_C_libtooling-a8c0` · branch `dugh-repropagate-control-merge`. Fixes a
verify-clean OVER-DECLINE of the most idiomatic tainted conditional phase:
`if (x != 0) x = cq_phi(x, θ); measure(x)`.

## The over-decline

`clang -O1` reaches a phase-arm diamond's straight-through (Pred→merge) edge ONLY
when the branch proves the routed qubit holds a single value, so it
value-propagates that phi incoming to a `ConstantInt` k (Rule 9). For `if (x != 0)
x = cq_phi(x, θ)` the else edge folds to `0`, so the merge is `phi [phase(x), 0]`.
`classifyArms`' phase-arm gate `Base == Routed` then fails — `Routed` is the folded
`0`, `Base` is the qubit — and the region declines, even though
`phi [phase(x), 0] ≡ phi [phase(x), x]` (x == 0 on that edge). The idiomatic
conditional phase (phase kickback / QPE-style) was un-lowerable; only an inequality
condition whose else edge stays a *range* (`if (x > 2) …`) avoided the fold.

## The fix (`ArmClassify::straightThroughConstFoldHandle`)

The Pred-edge analog of `tryEqFoldArm` (which handles a folded *arm* base). Called
in the per-arm loop just before the `Base == Routed` gate; when it matches it
re-anchors BOTH `Routed = H` and `Region.RoutedBase = H` (so
`SwapRouteEmit::emitRegion` cswaps/RAUWs the qubit H, not the folded constant —
the emitter prefers `RoutedBase`, SwapRouteEmit.cpp:516). Returns H iff ALL hold:

- `Routed` (== the straight-through incoming) is a `ConstantInt` k;
- DIAMOND (`Region.Arm` set, `Region.ArmFalse` null);
- `Region.Condition` is an `ICmpInst` that `isEquality()`;
- condition operands are { `ConstantInt` C, non-constant handle H }, position-free;
- **`H == Base`** (the arm rotates the proven handle) — the load-bearing gate that
  keeps a value arm (`Base` is the value op) and a cross-handle mux (`H != Base`)
  declining;
- `H` tainted; `C == k` (type + APInt value);
- **soundness**: `Region.Pred`'s conditional branch (whose condition IS the icmp)
  has exactly one successor == the merge block, and its truth value PROVES `H == C`
  on that straight edge (`eq` → merge is the TRUE successor; `ne` → the FALSE
  successor). Rests on the LLVM invariant that `BranchInst` successor(0) is the
  cond-true edge, successor(1) the cond-false edge.

Any miss returns null → the pre-existing loud declines run unchanged (Prime
Directive). The re-anchored routed base is ALWAYS identical to the condition
operand — the same wire the existing phase-diamond invariant already routes
(`if (q > 5) { q = cq_phi(q) }` routes q), so a8c0 introduces no new physical wire
into the routed position that the condition-wire guards don't already cover.

## Verified

- **e2e golden** `e2e-slice-control-phase-ifne` (`if (q != 0) q = cq_phi(q, a)`) —
  links + byte-diffs the routed phase-arm trace (¬flag `cqrt_x` brackets, Rz on the
  rail, `icmp_eq_inv` strip, merge RAUW'd to q).
- **Lit** accept `control_swap_straightthrough_constfold.ll` + declines
  `control_swap_reject_straightthrough_{value_arm,cross_handle}.ll`.
- **Owner probes**: non-zero k (`q != 5`), `icmp ne` polarity, and a **malicious
  wrong-polarity input** (merge = the `q != 0` edge, phi hand-set to 0) that
  correctly **declines** — the soundness guard refuses to route q unless the
  straight edge genuinely proves `q == k`.
- Full suite green; the demo `foo.c` (compound `(b>4)||(b==0)`) and genuine value
  collapses still decline.

## Rule-13 clearance

**Verdict: CLEAN — no silent miscompile in the accepted shape.** Independent
adversarial reviewer, analytic reasoning + adversarial probes lowered/verified/
linked/executed + full ir-pass-lit.

| Lens | Result |
|---|---|
| Equality-proof soundness (polarity) | **clean** — `eq`+true-edge / `ne`+false-edge ⟹ `H==C` on the straight edge; bogus fold and mismatched-constant (`C != k`) both decline. The straight edge is a direct edge (no H mutation), so routing H reproduces k exactly. |
| Folded ≡ un-folded | **clean** — `phi [phase(q), 0]` lowers byte-for-byte identical to the long-cleared hand-written `phi [phase(q), q]`; a8c0 only recovers the SSA handle clang folded away. |
| Cross-handle / value arm | **clean** — `H != Base` (cross-handle) and a value-op `Base` (value arm) both decline; the re-anchor never turns a data-mux into a phase arm (Rule 7). |
| Emitter interaction | **clean** — `RoutedBase` read only at SwapRouteEmit:516 (phase path); the Pred/straight-through incoming is never read there; flag strip `icmp_eq_inv(H,C)` valid (Rz diagonal, H unchanged); value-arm validator / emitValueRegion never reached; e2e clean, `opt -verify` clean. |
| Guard non-bypass | **clean** — stale-condition (`nonDiagonalGateBeforeBranch`), compound condition (non-`ICmpInst`), if/else (`ArmFalse`), nested (`RegionTreeDetect`), switch/select/ClassicalCallArm all decline or miss by construction. |
