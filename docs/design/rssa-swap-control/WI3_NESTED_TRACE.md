# WI-3 emitter-fidelity clearance — depth-2 nested phase swap-route

> ⚠⚠ **THE SWAP ROUTE IS RETIRED (dated 2026-09-06, bd `test_C_libtooling-3qlq`,
> Increments 1 + 2, both LANDED on `main`).** This directory is the swap-route
> **design record** and is deliberately left as written — its arguments and its
> statevector reasoning are still quoted, and the route remains the correctness
> ORACLE the replacements were checked against. **What ships instead:**
> a **PHASE** arm is the register-free **KICKBACK** — `void cq_phi(double θ)`, the
> ordinary compare mint, `cqrt_rz_i1(f, θ)` **UNCONTROLLED** on the flag, the
> ordinary `_unc` strip, `cqrt_free(f)`, **no gate on the data register at all**
> (the motivating defect: `cqrt_rz_<W>` is TENSORED, so a routed or controlled
> W-bit Rz marks `(−1)^popcount(target)` and can never mark `|0…0⟩` — every shipped
> Grover golden was the identity on `q`; **`Rz|0⟩ = |0⟩` is RETIRED as a
> load-bearing argument**, and every "zero controlled gates" here is a statement
> about the ROUTE). A **VALUE** arm is the **CONTROLLED-COPY MERGE** — hoist the
> arm's pure chain into the pred so it runs unconditionally on the ORIGINAL
> register, mint the flag, two X-bracketed `cqrt_copy_<W>_controlled` into a fresh
> `|0⟩` rail, the chain's `_unc` by the ordinary whole-DAG spine, strip, ONE free —
> **no work rail, no route, no reverse-play in the emitter**, with the chain-final
> rail left ALLOCATED and ENTANGLED (a leak, never a dirty free — PRD §0 E1, and
> why bd `3qlq.5` is unsound by default). **`cqrt_cswap` therefore has exactly ONE
> minter left: the 7.2 `AbortParkEmit`** (MEASURED — `grep -rn 'emitRoute('
> ir-pass/src ir-pass/include` = the definition, the declaration and one call site,
> `AbortParkEmit.cpp:396`; 1 of 319 committed goldens contains one). What SURVIVES
> is the principle, not the primitive: split and join share one live condition and
> the join must be the split's undo; arm bodies still run verbatim and
> uncontrolled; adjoints are still DERIVED; and the §3c clobber decline is
> unchanged. Design of record:
> `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` (§0 ERRATA first)
> + `RETIRE_SWAP_ROUTE_INC{1,2}_NOTES.md`.
>
> **For THIS file:** the emitter it clears, `NestedRouteEmit::lowerNestedRegion`,
> is **DELETED** (3qlq Inc 1) and `ir-pass/src/NestedRouteEmit.cpp` no longer
> exists. The depth-2 homogeneous-phase nest now lowers through
> `SwapRouteEmit::emitPhaseKickbackNestRegion`: each level's condition becomes a
> root flag via `CondTreeEmit::emitCondNetwork`, the outer arm's phases ride the
> OUTER root and the inner arm's ride a `cqrt_toffoli` CONJUNCTION ancilla, and the
> networks are torn down LIFO. **No flag-per-level route.** The classification
> hazards this document found — especially the value-derived inner condition — are
> still live reading.

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

---

## WI-5 closeout re-confirmation (independent Rule-13 review, 2026-06-15)

The WI-3 clearance above was written against the *design*; WI-5 re-ran the §8
adversarial verification against the **shipped build on branch
`swap-route-control`** — a fresh, independent 5-lens review (workflow
`wi5-nested-route-clearance`): (1) emitter physics & strip-order / free-cleanliness,
(2) emitter fidelity vs the cleared §4 stream **and the actual lowered IR**,
(3) flatten & taint-set memory safety (UAF / double-free / stray-gate), (4)
detection over-accept (the Prime-Directive boundary), (5) decline-matrix fidelity
& pipeline coupling. Every concern was adversarially refuted by an independent
verifier (default-to-refuted). **Result: CLEARED — 0 confirmed defects, 0 silent
miscompiles.** Lenses 1 & 2 were fully CLEAR (0 findings); the only output was four
NITs, none a miscompile (all are loud-safe or pre-existing). The shipped lowered IR
and the e2e trace (`slice_control_nested_phase`) match this document's ground-truth
stream **byte-for-byte** — including the load-bearing inner-strip-before-outer-
route-back order, exactly four `cqrt_free`, and zero `_controlled`/`cqrt_toffoli`/
`cqrt_copy`/`phi i32`. `opt -verify` clean; full `ctest` green;
`gen_templates.py --check` clean (no ABI change — 4.3 reuses 4.1's symbol set).

**NIT dispositions:**

1. *(Lens 3, pre-existing — NOT a 4.3 regression)* A tainted control compare with a
   **second non-branch (data) use** (`int f=(q>5); if(q>5){…}; return f+…` — clang
   `-O1` CSEs to one `icmp` with `br` + `zext` uses) is left standing by
   `flattenRegion(Tree)`'s `use_empty()` guard and re-minted by `lowerOps` into a
   **second** `cq_template_icmp` flag (one routed/freed, one leaked). Verify-clean,
   memory-safe, no wrong unitary; affects the **flat 4.1/4.2 path identically** (same
   guard). A Q/C-boundary precision question — filed as `bd test_C_libtooling-ziov`,
   out of 4.3 scope.
2. *(Lens 4 — comment accuracy, FIXED)* `RegionTreeDetect.cpp`'s backedge guard
   comment over-claimed "structurally-complete." It inspects only edges OUT of
   `{Pred, Mid, InnerArm, Merge}`, so a loop-**external** latch
   (`Merge→latch→header`, `latch ∉` set) is not seen here — but such a fresh-θ nest
   lowers **soundly** (no rail/flag crosses the backedge; all frees inside the body),
   the same accepted-leak disposition the flat 4.1 path gives the identical shape.
   Comment softened with the explicit "must be widened for value-arm nests, where a
   loop-carried dirty rail WOULD be a Rule-6 collapse" forward-note.
3. *(Lens 5 — test hardening, FIXED)* Five `nested` reject fixtures
   (`distinct_base`, `theta`, `twophi`, `select`, `switch`) pinned
   `error{{.*}}control flow…`, a **substring** of `nested control flow…`, so a
   criterion-reorder regression could silently swap the string and stay green.
   Tightened to `error{{.*}}lowering: control flow…` (the `lowering: ` anchor breaks
   the `nested ` false match) — char-for-char against the string that actually fires
   (Rule 12). *(Reconciliation: the `select`/`switch` fixtures fire `control flow`,
   not the §0/§5h-predicted `select`/`switch` — clang `-O1` collapses the inner `?:`
   to an in-arm `add(select)` value chain / leaves the `switch` as the Mid
   terminator, so the OUTER branch declines first; each fixture's own comment
   documents this, and the as-built fixture is the authoritative contract.)*
4. *(Lens 5 — defensive fail-loud, FIXED)* The MD0 pre-flight cross-region guard
   (`SwapRouteEmit.cpp`) could `return` without a diagnostic iff `A.Condition` were a
   non-`Instruction` **and** `A.Merge` were null — **doubly unreachable** today
   (every region sets both). Added a fail-loud INVARIANT comment so a future
   null-`Condition` region kind cannot silently regress (Rule 1 / Prime Directive).
