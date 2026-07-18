# PRD — bd 20xt.5 (d): PredMux tolerates `unreachable` switch-defaults

**Status:** DONE (Increment (d) shipped, Rule-13-cleared). Branch
`3c6m.14-control-l6`. Extends the 3c6m.14 L6 PredMux design of record
(`../3c6m.14-L6-control-predication/PRD.md`) — read that first; this PRD covers
ONLY the delta.

## 0. Context and scope

atan2l's top-level special-case/quadrant control did not flatten under PredMux.
Root cause (verified, bd 20xt.5): `clang -O1` lowers atan2l's exhaustive
quadrant `switch i32 %m` (a 2-bit sign pack, cases `{0,1,2,3}`) with a
`default: __builtin_unreachable()` — a shared `default.unreachable` block.
LLVM's `PostDominatorTree` treats every `unreachable`-terminated block as a
SECOND function exit alongside `ret`, so every block that can reach the switch
gets a **virtual-root** immediate post-dominator
(`PDT.getNode(E)->getIDom()->getBlock() == nullptr`). PredMux's standard merge
lookup (`recoverRegion`, `PredMuxFlatten.cpp`) bailed there **silently**, so the
whole nest fell through to the loud `nested control flow under quantum control`
decline.

**This increment (d):** teach `recoverRegion` to recompute the region merge
**ignoring `unreachable` exits**, and tolerate `unreachable` arm terminators in
the E3 single-exit gate. It is a **general** capability (any acyclic tainted
region whose post-dominance is poisoned only by `unreachable` — exhaustive
switches, `__builtin_unreachable`, `__builtin_assume`-lowered dead arms — now
flattens), not an atan2l special-case. **Freeze-orthogonal** — no new runtime
symbol, no YAML change.

**Out of scope (filed follow-ons, NOT this increment):**
- (e) the residual tainted i32 select-chain in the flattened atan2l (fold
  residues `and i1 false, %x` / `or i32 0, %x` from cq-lowering's own
  promotion, which `SelectClassify::collectCondTree` declines) — a PredMux
  flatten-residue / SelectClassify-robustness increment.
- (clone) the inner-`atanl` clone-control (9 internal tainted branches + QROM
  reads under control + the coherent-escape gate bypass on the clone-read path).

atan2l STILL declines after (d) (now at (e)); census COMPILES is UNCHANGED
(Rule 2 honesty — do not claim atan2l compiles).

## 1. Algorithm (delta to 3c6m.14 §4.1)

`recoverRegion` merge lookup becomes a two-branch selection:

```
Node = PDT.getNode(E)
if Node && Node->getIDom() && Node->getIDom()->getBlock():
    Mg = Node->getIDom()->getBlock()          # STANDARD path — byte-identical today
else:
    Mg = mergeIgnoringUnreachable(E)          # (d): virtual-root ipdom
    if !Mg: return false                       # leave (decline stays)
```

`mergeIgnoringUnreachable(E)` — pure analysis, no mutation (Rule 9):
1. Forward-reachable node set from `E`, **excluding** `unreachable`-terminated
   blocks (edges INTO an unreachable block are dropped — never taken).
2. Exits = `ret` blocks with no in-node successor. A non-`ret` node with NO
   in-node successor (all successors were unreachable) is an off-pattern
   dead-end → **bail** (`nullptr`; over-decline is safe). Multiple `ret`s that
   fail to reconverge yield `nullptr` on their own (the intersection excludes
   disjoint-exit suffixes — no virtual bottom needed).
3. Iterative post-dominator SETS (BitVector, fixpoint):
   `PostDom(exit) = {exit}`; `PostDom(B) = {B} ∪ ⋂_{S ∈ in-node succ} PostDom(S)`.
4. `ipdom(E)` = the member of `PostDom(E) \ {E}` with the LARGEST post-dom set
   (post-dominators form a strict chain, so the immediate one has the max
   popcount). Empty ⇒ `nullptr`.

E3 gate (3c6m.14 §4.2): `UnreachableInst` terminators are now TOLERATED inside
the region (still reject `ret`/`indirectbr`/`invoke`/`callbr` — real
multi-exits). Everything else in the ladder (E2/E4/E6/E7, topo order, the
flatten) is **unchanged** — the `unreachable` block has no successors (so no
merge-phi lists it as an incoming) and contributes no live value:
`topoOrderRegion` includes it as a sink; the coordinated teardown erases it with
the other arms. Its BODY, if non-empty: an **impure** instruction (store /
non-curated call) is excluded at **E4** (→ leave); a **pure** instruction is
hoisted by `moveBody` but is provably **dead** — a successorless block dominates
nothing outside itself, so its SSA values have zero external uses — and
`sweepDead` erases the whole cone before `lowerOps` (no spurious gate, no leaked
tainted producer; Rule-13-verified inert, `control_predmux_accept_unreachable_dead_body.ll`).

## 2. Correctness (delta to 3c6m.14 §6.1 — the only new obligation)

`unreachable` is UB: the source ASSERTS no execution reaches it (Rule 5). So for
every input **basis state with defined behaviour**, the original path `π(x)`
never enters an `unreachable` block. Extend §6.1's per-basis-state induction:

- `BP(unreachable-block)(x) = false` for every `x` (never on any path).
- The edge INTO an unreachable block (a switch default = `∧ ne`, or a br arm)
  has `EP = false` for every `x`, and is never consumed: an unreachable block
  has no successors, so it contributes **no merge-phi incoming**, and no phi
  anywhere lists it as an incoming block ⇒ `blockPred`/`edgePred` are never
  invoked for it, so the default `∧ ne` predicate is **never even built**.
- The reachable case/arm edges fully cover the live basis states (the switch is
  exhaustive over the reachable cases precisely because the default is
  `unreachable`), so at the merge exactly one `EP` is true — §6.1's mutual
  exclusivity is inherited unchanged, and the select-chain fallback is the
  sound last-reachable-incoming.

Hence dropping the `unreachable` block during flatten preserves bit-identical
values on every defined basis state — §6.1 with the unreachable arm excised. ∎

**Defense in depth:** the merge helper's result is re-validated structurally by
the SAME downstream E2 (acyclic) / E3 (single-exit) / topo-order gates. A wrong
merge can only make E3 fail (`escape`/`sideentry`/`mergepred`) → **leave**,
never miscompile. An E3-passing merge IS a valid single-exit merge by
construction.

**Blast-radius containment (Rule 13):** the new `else` branch fires ONLY where
today's code silently bailed (`return false` at the virtual-root check). A
standard-ipdom region can NEVER contain a reachable `unreachable` block (a
successorless block reachable from `E` without crossing `Mg` would contradict
`Mg` post-dominating `E`), so BOTH edits — the merge recompute AND the E3
`UnreachableInst` tolerance — are dead code on the standard path. Hence every
existing ACCEPT and every real-ipdom DECLINE is byte-identical. The ONLY
behaviour change is the **virtual-root decline subset**: an unreachable-poisoned
region may now flatten (fully E-ladder-gated) — the intended feature — or still
leave; and the helper also runs on non-`unreachable` virtual roots (infinite
loops → E2 declines; disjoint multi-`ret` → `mergeIgnoringUnreachable` returns
nullptr). It can NEVER change an existing accept or a real-ipdom decline.

## 3. Decline / leave matrix (Rule 12 — each row has a fixture)

| shape | disposition | fixture |
|---|---|---|
| exhaustive tainted `switch` w/ `unreachable` default nested under a tainted br (the atan2l shape) | **ACCEPT** (flatten) | `control_predmux_accept_unreachable_default_switch.ll` + e2e `slice_predmux_unreachable_switch.c` |
| non-empty PURE body inside the `unreachable` block (hoisted then dead-swept) | **ACCEPT** (flatten, body swept) | `control_predmux_accept_unreachable_dead_body.ll` |
| `unreachable` arm ALONGSIDE a live `ret` arm (real multi-exit) | leave → existing decline | `control_predmux_leave_unreachable_multiret.ll` |
| `unreachable`-default switch arm (or `unreachable` body) holding a STORE (E4 must still fire) | leave → taint-escape decline | `control_predmux_leave_unreachable_store_arm.ll` |
| `unreachable` inside a loop body | leave → E2 cycle decline | existing `control_predmux_leave_inloop.ll` (unchanged) |
| `ret` inside region (no unreachable) | leave → existing decline | existing `control_predmux_leave_multiexit.ll` (unchanged) |

## 4. Verification

- `opt -verify` clean on the flattened accept fixture + e2e output.
- e2e `slice_predmux_unreachable_switch.c`: deterministic 62-line trace,
  1 `ry` + 1 `measure` (Rule 5), analytically correct on every basis state
  (`out = (q>100)? 2q : (m==3? q-4 : (m==2? q^7 : (m==1? 5q : q+10)))`, the
  `unreachable` default never a merge incoming), clean flag uncompute + frees,
  0 double-frees.
- Full `ctest` green (182 → 185 with the 3 lit fixtures + 1 e2e); ir-pass-lit
  and every existing accept/decline fixture byte-identical (zero-blast-radius
  confirmed).
- Rule-13 independent adversarial review: see `RULE13_CLEARANCE.md`.
