# RSSA-based tainted control flow — idea, advantages, perspectives

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
> **For THIS file:** the "one line" pitch, the two arguments and the principles
> below are the route's. Read them as the design that motivated the current
> lowering, not as its description.

**Status:** design settled, revised 2026-06-09 (statevector-checked dialogue;
supersedes the 2026-06-08 method-A framing — see `SCOPING.md` §3a). Implementing
on branch `swap-route-control`. The concise pitch + principles; `SCOPING.md` is the
detailed spec, `docs/prd/phase-04-swap-route-control/PRD.md` the 4.1 PRD, and the
`swap_route_*.ll` files are the IR target fixtures. The compiler never inserts a
measurement the user did not write — enforced by *never freeing a non-`|0⟩` rail*.
The common phase-arm (`Rz`) case is coherent with **zero controlled gates** (route
uncontrolled, free the `|0⟩` rail, strip the `icmp` flag); the one rejection is an
arm that value-clobbers a variable the condition reads. The ROADMAP "Phase 4 — RSSA
swap-routed control flow" block tracks phasing.

> ⚠ **"ZERO CONTROLLED GATES" DESCRIBES THE ROUTE, AND THE FLAT PATH NO LONGER
> EMITS ONE** (bd `test_C_libtooling-drbq` Inc 2a, 2026-09-02). This file and
> `SCOPING.md` are the swap-route *design record* and are deliberately left as
> written; read every "zero controlled gates" in them as a statement about the
> ROUTE. As shipped, the §6a control-in-place peephole lowers every FLAT phase
> region (diamond, if/else, sequential, the rolled in-loop region, `ShareCondFlag`,
> multi-Rz spines, Rz on the condition register) to ONE
> `cqrt_rz_<W>_controlled(f, q, θ)` per arm gate — no work rail, no `cqrt_cswap`.
> ~~The 4.3 depth-2 nest and the 4.5 switch still emit the route exactly as
> described here.~~ ⚠ **FALSE since 3qlq Inc 1 (2026-09-05); corrected 2026-09-06.**
> They do not: `NestedRouteEmit.cpp` is DELETED and `SwitchRouteEmit`'s phase path
> mints a kickback gate. **Nor is the Inc-2a controlled gate this banner announces
> still emitted** — `cqrt_rz_<W>_controlled` is DECLARED-BUT-UNEMITTED and every
> phase arm is the kickback (see the 3qlq banner at the top of this file). Read
> this paragraph as the MIDDLE of three generations.
> The two are the SAME unitary (`cswap·Rz_w·cswap` with `w=|0⟩` **equals**
> `cRz`, no global-phase residue), which is why the route stays the correctness
> oracle for the peephole. See `docs/prd/phase-04-swap-route-control/
> CONTROL_IN_PLACE_INC2A_NOTES.md`.

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
2. **Arm-body handling** — chosen per arm: a **phase arm (`Rz`)** leaves the rail
   `|0⟩` for free and is made coherent by the §3a flag-strip (no rail reversal); a
   **value arm** uses compute → copy-out → reverse-play; full-region reverse-play
   is the **on-demand** undo, not an eager default. A vacuum-fixing arm leaves no
   garbage (Zhou-Ralph fast path); a genuinely-in-place rotation can be controlled
   in place (§6a, later). *Gate-physics, layered on the skeleton.*
3. **Optimization (later)** — pick the cheapest of the above per arm.

### The quantum-correctness layer is two gates

Of the unitary primitives, only **`R_z`** (phase) and **`R_y`** (superposition)
are non-classical; `add`, `mul`, `icmp`, `cqrt_x`, `cqrt_toffoli`, `cqrt_cswap`
are *permutations* (reversible classical). The routing (`cqrt_cswap`) is itself a
permutation, so the control-flow skeleton is coherence-transparent — **coherence
is created or broken only by `R_z`/`R_y`.** Under the `R_z = diag(1, e^{iθ})`
convention, `R_z|0⟩ = |0⟩`: a routed phase arm leaves its rail at `|0⟩` and — since
`R_z` preserves `q`'s basis value — the `icmp` flag is stripped from the current
`q` with **no controlled gate** (§3a). `R_y` (genuine superposition) and value arms
are deferred (method-B / §6a); a value-clobber of a condition variable is rejected
(§3c). So the quantum-correctness layer is a *two-gate* layer; the 4.1 default is
to **swap-route phase arms uncontrolled and flag-strip** — control-in-place is the
later §6a refinement, not the mechanism. See `SCOPING.md §3`/§3a/§3c.

## Prototype scope (correctness first)

- Branch **only** with the controlled SWAP: route in → uncontrolled body → route
  back → merge. One mechanism, no special cases.
- **Phase arms (`Rz`)** — the 4.1 scope: the inactive rail is `|0⟩` for free
  (`Rz|0⟩ = |0⟩`) and freed clean; the `icmp` flag is stripped via `icmp_inv(q)`,
  leaving `q` interference-safe with zero controlled gates (§3a).
- **Value arms** (`add`/`mul`/`x`/…) — 4.2: compute → copy-out (`cqrt_copy_<W>`) →
  reverse-play. A dirty rail is **left allocated** (never freed dirty — that would
  be a hidden measurement), reclaimed by on-demand reverse-play.
- **Reject** an arm that value-clobbers a variable the condition reads (§3c) — the
  one shape no control model can keep coherent.
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
