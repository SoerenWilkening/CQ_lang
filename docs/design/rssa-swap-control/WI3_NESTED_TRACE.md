# WI-3 emitter-fidelity clearance — depth-2 nested phase swap-route

Rule-13 written artifact for `NestedRouteEmit::lowerNestedRegion` (Phase 4.3
WI-3). The depth-2 homogeneous-phase **physics** was cleared at design
(`CLEARED-WITH-AMENDMENTS`, 2026-06-12); this document is the **emitter-fidelity**
clearance — that the *implemented* stream matches the cleared design — per
IMPLEMENTATION-4.3 §8.1/§8.2. Cleared by an independent 5-lens adversarial review
(workflow `wi3-nested-route-clearance`, 2026-06-12).

> **The review caught one REAL bug (the canonical verify-clean silent miscompile
> the green suite missed) — now FIXED.** A depth-2 nest whose inner condition is a
> single-register but VALUE-DERIVED operand built in `Mid` (`%d = add %g, 1;
> icmp %d, 9`) was wrongly accepted: criterion-5's leaf check passed (`%g`, the
> sole quantum leaf, is in-closure) but (a) `lowerCompareToFlagRail` substitutes
> rail1 for `%d` wholesale, **dropping the `+1`** → the inner flag tested
> `rail1<9` not `(rail1+1)<9` (wrong predicate), and (b) the in-`Mid` `add` is
> neither a `cq_phi` gate nor a compare, so `flattenRegionTree` never erased it →
> erasing `Mid` was a **use-after-free** on `%g` (silent on the no-assert build;
> SIGSEGV under Guard Malloc). Fix (`RegionTreeDetect.cpp` criterion 5,
> strengthened): the inner compare's tainted operand must be a **direct member of
> the rail closure** (a diagonal `cq_phi`/Rz alias of the routed base, basis value
> = rail1's), not a value-derived offshoot — over-decline otherwise (Prime
> Directive). Regression: `control_swap_reject_nested_inner_derived.ll`. The other
> four lenses cleared (CLEAR / CLEAR_WITH_NITS); the nits are folded into the
> comments below.

## The lowered stream (ground truth — `opt` on the canonical nest, then linked + run)

Source `if (q>5) { q=cq_phi(q,b); if (q<9) { q=cq_phi(q,a); } }` (cq_phi = Rz
diagonal phase; cq_theta = Ry, the sole superposition source) lowers to:

```
f1   = icmp_sgt_hl(q, 5)        ; outer flag
rail1= alloc(0)
       cswap(f1, q, rail1)      ; outer route-in
       rz(rail1, b)             ; intervening gate g on rail1
f2   = icmp_slt_hl(rail1, 9)    ; inner flag — MINTED FROM rail1, not the stale %g
rail2= alloc(0)
       cswap(f2, rail1, rail2)  ; inner route-in
       rz(rail2, a)             ; inner arm gate h on rail2
       cswap(f2, rail1, rail2)  ; inner route-back
       free(rail2)              ; (4a)
       icmp_slt_hl_inv(rail1, 9); inner STRIP f2 — AFTER inner route-back, BEFORE outer route-back
       free(f2)                 ; (4b)
       cswap(f1, q, rail1)      ; outer route-back
       free(rail1)              ; (4c)
       icmp_sgt_hl_inv(q, 5)    ; outer STRIP f1
       free(f1)                 ; (4d)
       measure(q)               ; merge phi RAUW'd → q
```

Zero `_controlled`, zero `cqrt_toffoli`, zero `cqrt_copy`, exactly **four**
`cqrt_free`, no `phi i32`. `opt -verify` clean; links and runs (the trace above
is the literal runtime output).

## §8.1 The four-row (f1,f2) basis trace

`cswap(c,a,b)` swaps a↔b iff c=1. Rz is diagonal: `rz|0⟩=|0⟩` exactly, and on a
basis state it adds a phase without changing the basis value. The flags are
quantum ancillas correlated with q's basis value. Analyze each computational
basis state |q₀⟩ (the stream is linear; phases accumulate per branch).

| population | f1 | f2 | rail1 after route-in | inner block | q at the end |
|---|---|---|---|---|---|
| q₀ ≤ 5 | 0 | (0<9)=1 | \|0⟩ | f2=1 but rail1,rail2=\|0⟩, so cswaps move \|0⟩↔\|0⟩, rz(\|0⟩)=\|0⟩ | **\|q₀⟩, no phase** |
| 5<q₀, q₀≥9 | 1 | (q₀<9)=0 | e^{ib}\|q₀⟩ | f2=0: no inner swap, rz fires on rail2=\|0⟩ | **e^{ib}\|q₀⟩, outer phase only** |
| 5<q₀<9 | 1 | (q₀<9)=1 | e^{ib}\|q₀⟩ | f2=1: route to rail2, rz(a), route back | **e^{i(a+b)}\|q₀⟩, both phases** |

This is exactly `if(q>5){rz(b); if(q<9){rz(a);}}`: the inner phase `a` lands iff
**f1∧f2**, with NO conjunction ancilla — the AND is implicit because the inner
level routes `rail1`, which holds q's amplitude only on the f1=1 path (it is
`|0⟩` on f1=0). A phase nest **copies nothing out**, so there is no kept-source
deviation channel — coherence is exact.

Every `cqrt_free` lands on a register provably `|0⟩` in population on **all** rows
(rail2 after its `|0⟩`-restoring route-back; f2 after its strip; rail1 after the
outer route-back; f1 after its strip), so each free is a clean reset, not a hidden
measurement (Rule 6). Both strips recompute the uncontrolled `icmp_inv` on a
register whose basis value equals q₀ (Rz preserves the basis), returning each flag
to `|0⟩`.

## §8.2 The strip-order proof (the verify-clean-invisible core hazard)

The inner strip `icmp_slt_inv(rail1, 9)` must come **after** the inner route-back
and **before** the outer route-back. f2 was minted as `c2(v)` where `v` is rail1's
value at mint time (`q₀` on f1=1, `0` on f1=0). The strip recomputes `c2(rail1)`
and XORs; f2 returns to `|0⟩` iff rail1 still holds `v`.

- **§4 order (correct):** at the strip, the inner route-back has restored rail1 to
  `v` and the outer route-back has **not** yet run. So the strip recomputes `c2(v)`
  = mint, XOR → 0. Clean on every row — in particular the (f1=1, q₀≥9) population
  where f2=0 was minted as `c2(q₀)=0`.
- **Misordered (strip after the outer route-back):** the outer route-back swaps
  q↔rail1 on f1=1, emptying rail1 to `|0⟩`. The strip then recomputes `c2(0)=1`.
  On the (f1=1, q₀≥9) population, f2 = `0 ⊕ 1 = 1` — **dirty**. `free(f2)` on a
  `|1⟩` ancilla entangled with q (via the routing history) is a hidden measurement
  that collapses q. The symbol multiset is identical to the correct stream, so
  `opt -verify` and an order-blind scan cannot see it.

This single sub-order is pinned by the dedicated `ORD`-prefix ordered FileCheck in
`control_swap_nested_phase_diamond.ll` (inner strip CHECK, then the outer
route-back cswap CHECK, in its own pass) — the only automated layer that catches
the misorder.

## Memory-safety note (the flattenRegionTree erase order)

The implementation deviates from IMPLEMENTATION-4.3 §4 step-6's *literal* order
(which would erase the arm gates before the compares). The Mid intervening gate
`%g` is **read by** the inner compare `%c2`, so `%g` is not use-empty until `%c2`
is gone. `flattenRegionTree` therefore owns the full teardown in a single
use-before-def order: RAUW merge phi → q + erase; both branches; both compares
(BEFORE the gates); arm gates in reverse lineage (inner-arm gate `%h` before its
producer `%g`); splice the **single shared merge** into Pred exactly once; erase
InnerArm, Mid, Merge. Every erased instruction is scrubbed from `taint`
(`PhiCalls` included, so `lowerRotations` re-emits no stray uncontrolled `rz`).
The shared merge is erased exactly once (no double-free), and the merge phi is
erased here — before `declineClassicalMuxes` — so the live 3-incoming tainted phi
never false-declines `classical phi` (§6.1).

## Loop guard (the WI-1 backedge forward-note)

A loop-resident nest (routed base a loop-carried phi, or the region on a backedge)
has no proven sound swap-route lowering in 4.3: the emitter erases the 3-incoming
merge phi and frees its rails *before* — and bypassing — the `FreePoint` /
`declineClassicalMuxes` backedge guards the flat path defers to. `recoverRegion
Tree` therefore declines any nest with a backedge — a region edge whose successor
dominates its source (textbook backedge test, fresh `DominatorTree` per call) —
`nested control flow`. The cleared flat 4.1 path declines the analogous loop
diamond too (`declineClassicalMuxes`: "tainted value muxed by a classical-condition
phi"), so the disposition is consistent and safe (Prime Directive). Regression:
`control_swap_reject_nested_loop.ll`. The acyclic §5g/§5h-accept shapes have no
backedge → no false decline.
