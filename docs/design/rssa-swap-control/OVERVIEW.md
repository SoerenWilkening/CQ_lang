# RSSA-based tainted control flow — idea, advantages, perspectives

**Status:** design exploration, branch `rssa-swap-control`. The concise pitch +
principles; `SCOPING.md` is the detailed spec and the `swap_route_*.ll` files are
the IR target fixtures. **Roadmap update is pending review of this doc.**

## The idea (one line)

Lower tainted (quantum-dependent) control flow by **reinterpreting** `br`/`phi`
as controlled-SWAP data routing, instead of **destroying** the CFG and
synthesizing a controlled form of every gate. Classical control flow is left
exactly as LLVM compiles it.

## What we did before — and why it is not RSSA

Phase-4 is controlled-form **flattening**: detect a tainted `br`-diamond → mint a
control flag → replace each arm gate with a `_controlled` template → dissolve the
`phi` (controlled-add / RAUW / angle-difference) → uncompute the flag → **erase
the `br`, splice the arms, delete the blocks** (`CFGLinearization`). That is the
*opposite* of RSSA on its defining axis: RSSA **preserves** the SSA control
structure and makes it reversible; Phase-4 **removes** labels, `br`, and `phi`
and controls the gates. None of the RSSA hallmarks are present (parameterized
labels, phi on both splits *and* joins, destructive uses, reversible joins). It
was controlled-gate flattening over stock LLVM SSA — not RSSA.

## Why this is better — the two arguments

**1. Conserve classical control flow (most important).**
We reinterpret tainted `br`/`phi` (route / merge) rather than tearing the CFG
apart, and we leave *all classical (untainted) control flow untouched* — reusing
LLVM's control-flow machinery instead of reinventing it. No `CFGLinearization`,
no per-type `phi` dissolution, no `_controlled` template per gate.

**2. Drastic simplification of the hard edge cases.**
"Controlled X" uniformly becomes **route the operand to where X happens, run X
uncontrolled, route back** — for *any* X:

- **Controlled `return`** → route the live value into a per-site return register
  at the return point; the rest of the function runs uncontrolled on the parked
  register; an exit priority cascade selects the first-fired return.
  *(Phase-4: permanently rejected — P2.)*
- **Controlled `break`** → identical, with the loop exit as the merge point.
  *(Phase-4: permanently rejected — P3.)*
- **Controlled recursion / function call** → route the argument into the callee's
  input iff the condition holds, then **call the function unconditionally** (no
  controlled specialization of the callee needed) and route the result back;
  bounded recursion is the unrolled form.
  *(Phase-4: unsupported; Phase-6 planned a clone-on-taint specialization that
  swap-routing makes unnecessary.)*

The uniformity *is* the simplification: one routing pattern replaces a zoo of
special cases and several permanent rejections.

## The RSSA design principles it rests on

- **Phi on both splits and joins:** the merge is the *adjoint* of the branch —
  `br` routes in, `phi` routes back, sharing the same live control.
- **The condition stays live:** the control qubit is kept (never measured),
  playing the role RSSA's orthogonalizing assertion plays classically.
- **Reversibility by routing + reverse-play:** the region is a clean unitary; its
  inverse is the instruction stream reversed and adjointed — uncompute = play it
  backward (reuses the existing `EmitInverse` machinery).

### Three layers (the mental model)

1. **RSSA skeleton** — the control-flow lowering (route / merge / return cascade).
   Always present; conserves the CFG. *This is the RSSA part.*
2. **Arm-body handling** — chosen per arm: general gates leave garbage that is
   *kept* and reversed region-locally (the correctness-first default); a
   number-conserving / vacuum-fixing arm leaves none (Zhou-Ralph fast path); a
   known cheap-to-control gate can simply be controlled in place. *Gate-physics,
   layered on the skeleton.*
3. **Optimization (later)** — pick the cheapest of the above per arm.

### The quantum-correctness layer is two gates

Of the unitary primitives, only **`R_z`** (phase) and **`R_y`** (superposition)
are non-classical; `add`, `mul`, `icmp`, `cqrt_x`, `cqrt_toffoli`, `cqrt_cswap`
are *permutations* (reversible classical). The routing (`cqrt_cswap`) is itself a
permutation, so the control-flow skeleton is coherence-transparent — **coherence
is created or broken only by `R_z`/`R_y`.** Classical garbage is uncomputed by its
classical inverse (mechanical, no risk); `R_z` is phase bookkeeping; `R_y` is the
one gate that needs genuine care. So the quantum-correctness layer is a *two-gate*
layer, and the default is to control `R_z`/`R_y` in place (clean) and swap-route
the classical structure. See `SCOPING.md §3`.

## Prototype scope (correctness first)

- Branch **only** with the controlled SWAP: route in → uncontrolled body → route
  back → merge. One mechanism, no special cases.
- Inactive-rail garbage is **kept** (the reversibility witness) and uncomputed
  region-locally before any coherent reuse — not measured, not ignored forever.
- Quantum-data-bounded loops and recursion are **statically unrolled** to their
  upper bound.
- No efficiency tuning yet.

## Far-term perspectives (compiler optimizations)

- **Controlled-in-place peephole** for known cheap gates (controlled-`rz`/`ry`) —
  clean without rails.
- **Number-conserving fast path** (Zhou-Ralph, Nat. Commun. 2:413): vacuum-fixing
  arms route with zero garbage and are coherent immediately.
- **Loop qubit reuse** via Bennett / BennettVM-style pebbling — scheduling the
  region-local reversals to reclaim rails (`O(log N)` live vs `O(N)`).
- **Coherent / Grover support:** region-local uncompute (reverse-play) before
  interference; free for arms that satisfy the inert-reference condition
  (`U|ref⟩ = |ref⟩`).

## See also

- `SCOPING.md` — detailed spec (§3 defines the two-gate quantum-correctness
  layer; §6a the per-arm selection rule).
- `swap_route_if_diamond.ll`, `swap_route_ifelse.ll`,
  `swap_route_if_diamond_uncompute.ll` — IR target fixtures.
