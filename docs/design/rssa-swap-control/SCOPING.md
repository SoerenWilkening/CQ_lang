# RSSA swap-routed tainted control flow — scoping (DRAFT)

**Status:** design exploration on branch `rssa-swap-control`. Not yet on the
ROADMAP; no beads issues filed. Do not push toward closure (issue filing /
ROADMAP edits) until the design is settled.

**Revised 2026-06-07 after a critical review** (statevector-checked). Material
corrections: §3a (the coherent-path generality was *inverted* — now fixed),
§3/§6 (the regime assumption is now stated; "coherence only from `R_z`/`R_y`" and
"classical ops are free permutations" are qualified), §6a (the in-place carve-out
is re-scoped to genuinely-in-place unitaries), §1/§3 (the `543bd85` provenance is
corrected). Items the review *confirmed sound*: the routing permutation, v1
measure-only for diagonal arms, and that nested control gets **cheaper**, not
harder (§6a).

**Scope & regime (read first).** This design optimizes for **correctness and
maintainability in a single regime**: qubits are **not** treated as scarce, and
optimization (rail reuse / pebbling / collapsing tiny wraps) is **explicitly out
of scope**. Consequences — extra work registers per arm, unrolled loops, "route
everything uniformly" — are intentional regime choices, not defects to weigh.
Where this trades space for circuit depth it trades *favorably* (parallel
mutually-exclusive arms run in `O(max)` depth instead of controlled-op's `O(sum)`),
but that is a side benefit, not the goal.

**Artifacts in this folder**
- `OVERVIEW.md` — the concise idea / advantages / perspectives doc.
- `swap_route_if_diamond.ll` — IR spec: one-content-arm diamond, target output.
- `swap_route_ifelse.ll` — IR spec: two-arm if/else, target output.
- `swap_route_if_diamond_uncompute.ll` — IR spec: the coherent path —
  garbage-free uncompute (§3a). **Note:** its method-(B) "general" label is being
  corrected to match §3a below.
- `prototype_semantics.py` — one-off statevector oracle (NOT part of the build;
  see §8). Validates the semantics the `.ll` specs cannot show on their face.

---

## 0. Prior art & provenance (what we reuse vs what is ours)

This design is an *assembly of known parts*, not a new theory of reversible
control. Knowing which layer comes from where tells us where to spend rigor.

| layer | source of truth | reused or ours |
|-------|-----------------|----------------|
| control **structure** (SSA skeleton, join = adjoint of split, live condition, single-assignment) | **RSSA** (Mogensen 2015) | reused |
| lowering **mechanics** (CSWAP/Fredkin "control the data not the gate"; compute→copy→uncompute) | quantum-compiling folklore + **Bennett 1973** | reused |
| **quantum-correctness layer** (superposed control, no-cloning, the `R_z`/`R_y` coherence handling, reverse-play uncompute) | **none of the above** — §3/§3a here + the simulator oracle | **ours** |

**The trap to avoid:** "it's RSSA, therefore it's proven." RSSA is *classical* —
it proves classical reversibility (one path runs; the path bit is recomputed from
an entry assertion). The quantum coherence correctness is not something RSSA or
BennettVM hands us; it is the original part, and it is exactly what §3 (the
`R_z`/`R_y` handling) and the simulator's `0.10` dephasing number address.
*(The §3a correction below is a live example: Bennett's compute-copy-uncompute is
a classical-function theorem, and applying it to a phase/superposition answer
silently destroys it — exactly the kind of unearned generality this trap warns of.)*

**On Bennett / BennettVM as a reference.** Good for: a concrete in-code encoding
of RSSA, and the boundary between what RSSA structure makes reversible for free
vs what needs Bennett history/pebbling. **Not authoritative for our core
problem:** BennettVM is an *interpreter* whose program counter reads a *definite*
predicate — it never branches on a *superposed* qubit, which is the entire reason
we need CSWAP routing. It is classical-reversible (no coherence reasoning) and
dynamic-length (a VM, not a static compiler). Our own Phase-4/5 lowering already
handles superposed control further than BennettVM does. Treat it as a structural
cousin, not an authority.

## 1. Motivation

Phase 4 lowers a tainted `br`-diamond by **flattening it into controlled ops**:
detect diamond → mint flag → substitute every arm gate with its `_controlled`
template → dissolve the `phi` per data type (RAUW handle / controlled-add /
angle-difference) → uncompute the flag → linearize the CFG.

The cost of that shape is structural, not incidental:
- a `_controlled` runtime variant is required for **every** gate an arm can hold;
- `phi` dissolution is **per-type** (handle vs classical-data vs angle);
- the uncompute machinery (Phase 5: `ChainWalk`/`FreePoint`/`EmitInverse`) is
  where the hard correctness bugs live — e.g. the divergent-arm
  `rz(-a)·rz(-b)`-on-both-paths hazard, which the Phase-5 `isStep2Emittable`
  same-block guard prevents (productionized in `543bd85`; that commit *retains*
  the guard and adds post-dominator last-use placement — it is **not** a revert of
  a shipped miscompile, and the swap-route claim should not lean on it as one).

## 2. Proposed model (RSSA swap-routing)

Lower tainted control by **routing data, not by controlling gates**:

| construct | lowering |
|-----------|----------|
| tainted `br c` | mint flag; `cqrt_cswap` the operand(s) into a per-arm work register |
| arm body | arm gates copied **verbatim, uncontrolled** onto the routed register |
| tainted `phi` | `cqrt_cswap` the active result back (the **adjoint** of the split) |

This is the quantum reading of Mogensen RSSA: phi lives on both the split and the
join, and the join is literally the inverse of the split sharing the same live
flag. It maps onto **existing** runtime symbols — `cqrt_cswap`,
`cqrt_alloc_i32`/`cqrt_free`, plain `cqrt_rz/ry/x` (all already in the ABI) — so
v1 adds **no new runtime ABI surface**; the coherent path adds exactly one new
primitive (a per-width reversible copy — §3a). Concrete target IR: the two `.ll`
specs.

The maintainability win is that arm bodies pass through **unchanged**: the pass
never needs a `_controlled` variant of any gate, and `phi` becomes one uniform
operation (a CSWAP) instead of three type-specific reductions. *(The `R_z`/`R_y`
"control-in-place" specialization of §6a is a later, optional refinement; v1
swap-routes everything uniformly — see §6a.)*

## 3. The quantum-correctness layer is (almost) two gates: R_z and R_y

The whole tainted-control machinery is **phase-transparent except for `R_z` and
`R_y`** — but "phase-transparent" is not the same as "coherence-free," and the
distinction matters (it is what §3a got wrong in the earlier draft). The unitary
instruction set splits:

- **Basis-mapping ops:** `cqrt_x`, `cqrt_toffoli`, `cqrt_cswap` are genuine
  permutations (basis → basis, no phase). `add`/`mul`/`icmp` are *classical
  functions* but **not reversible as written** — `add:(i32,i32)→i32` and `icmp→i1`
  are non-injective, so realizing them reversibly needs a Bennett embedding with
  ancilla (the `cq_template_*` helpers already allocate fresh handles for this).
  "Sub undoes add" holds only for the *in-place* embedding (`a += b`). So the
  classical bulk is mechanical but **not free**: it carries its own ancilla and
  uncompute obligation.
- **Genuinely quantum:** `R_z` and `R_y` — the only unitaries that create phase or
  superposition.

**Phase vs reduced coherence.** Phase is created only by `R_z`/`R_y`. But reduced
coherence (the off-diagonal of the logical qubit's reduced density matrix) is
*also* degraded whenever an **entangling permutation leaves a rail dirty**: a
`cqrt_cswap` routing a superposed register on a superposed flag entangles the rail
with the control, and an un-uncomputed rail **dephases under later interference**.
Demo B quantifies exactly this (`P(c=0)` 0.85 → 0.75 for an `R_y` rail). So the
uncompute obligation is broader than "an `R_y` inside a block": it is **any rail
left non-`|0⟩` and entangled with the flag** before interference (which includes
`add`/`x`/`mul` arms — their rails carry *classical* which-path garbage that still
dephases; only diagonal `R_z` and identity leave the rail at `|0⟩`).

| op class | inactive-rail residue | uncompute | risk |
|---|---|---|---|
| diagonal / basis-preserving (`R_z`, identity) | rail stays `\|0⟩` (an eigenstate, only a phase) | trivial; rail-free | low — phase bookkeeping |
| classical permutation (`add`, `x`, `toffoli`, `mul`, …) | a classical value entangled with the flag | the classical inverse (`sub`, …) | mechanical, but **must** be uncomputed before interference / before `free` |
| `R_y` (off-diagonal) | genuine superposition `cos·\|0⟩ + sin·\|1⟩` entangled with control | controlled-`R_y(-θ)` before any interference | **the one to be careful with** |

**Measurement.** Two regimes, and the earlier "no measurement is required or
enforced anywhere" was wrong on the v1 side:
- **Coherent path (§3a):** no measurement needed — coherence is restored by
  region-local cleanup.
- **v1 (forward-only, §8):** the rail residue is kept and **ignored**, which is
  sound **only if the output is terminal (measured) before any interference**. v1
  therefore *requires* a measure-terminal precondition and must be **gated** by a
  terminality/escape check — reuse `FreePoint`'s existing escape/measure analysis
  rather than emitting unconditionally (see §3b, §7.5).

**Bonus — what swap-route does and does not "dissolve" re `543bd85`.** The
divergent-arm `rz(-a)·rz(-b)` hazard came from flattening exclusive arms onto one
register and reversing them at a single merge. Swap-route keeps exclusive arms on
*separate rails*, so **v1 sidesteps it — but only because v1 emits no uncompute at
all.** The negated-rotation uncompute (`rz(-b); rz(-a)`) **returns** in the
coherent path (§3a / the uncompute fixture), so the hazard is *deferred*, not
dissolved; the coherent path must reproduce the same care the Phase-5 guard
encodes.

## 3a. The coherent path: two methods, scoped by arm class

> **Correction (2026-06-07 review).** An earlier draft labelled compute → copy-out
> → reverse-play **"the general method (correct for any arm body, diagonal or
> not)."** That is **false** and was verified wrong by statevector simulation: for
> a phase/superposition body it **erases the answer** (interference `P0` 0.585 →
> 0.500, fully dephased). The generality of the two methods is the *reverse* of
> that draft. Corrected below; the `.ll` fixture's method-(B) header is being
> updated to match.

The forward swap-route is a clean unitary `R` of self-inverse pieces (`cqrt_cswap`,
`cqrt_x`) plus the arm bodies; `R†` is the stream reversed with each body gate
adjointed. There are **two** ways to keep the answer while cleaning scratch, and
the correct one depends on **what the answer is**.

**(A) Keep-in-place + controlled-adjoint rail cleanup — for rotation bodies
(`R_z`, `R_y`).** The answer is a *phase* (`R_z`) or *superposition* (`R_y`)
carried by `q` itself, so `q` must **not** be reverse-played. Leave the answer on
`q`; clean only the work rail with a controlled-adjoint of the body on the inactive
branch. Demo B confirms the rail cleanup restores coherence (`P(c=0)` 0.75 → 0.85).
*Caveat — the data-derived flag uncompute:* the flag was minted `icmp(q0)`.
Cleaning it with `icmp_inv(q)` is valid only when the body is **basis-preserving**
(`R_z`), so that `icmp(q) == icmp(q0)`. For an off-diagonal `R_y` arm under a
**data-derived** flag, `q ≠ q0` after the body, so the flag cannot be recomputed
from `q` — it must be left dirty (measure-only) or the pre-body `q0` preserved to
uncompute it. This is the genuine open question for coherent `R_y` (§7.3), and is
why the in-place fixture is correctly scoped **diagonal-only**.

**(B) Compute → copy-out → reverse-play — for classical-permutation bodies ONLY**
(`add`, `mul`, `x`, `toffoli`, …). Run `R`, CNOT the **basis-valued** result into a
fresh register (`cqrt_copy_<W>`), then reverse-play `R†` to restore `q0` and zero
the rail (which makes the `icmp_inv` flag uncompute trivially valid). This is
Bennett compute-copy-uncompute and it preserves a basis-valued result. It is
**wrong for `R_z`/`R_y`**: a CNOT copies a basis *label*, not a *phase*, so `R†`
cancels exactly the phase/superposition that was the answer.

Both reuse the existing `EmitInverse` machinery (rotation-negate / `_inv` /
self-adjoint) and need no `ChainWalk`/`FreePoint` lineage analysis — the uncompute
target is the verbatim forward stream. See `swap_route_if_diamond_uncompute.ll`.
Method (B)'s copy is the **only new ABI** the design adds, and it is **per-width**
(`cqrt_copy_i32`, … — one transversal-CNOT copy per width, *not* a single symbol,
*not* cloning).

### 3b. v1 soundness obligations (new — from review)

v1 (forward-only, garbage kept) is correct **only** under two guards the spec must
enforce, not assume:
1. **Terminality.** The routed output must be measured (or otherwise terminal)
   before any cross-branch interference. Gate emission on a `FreePoint`-style
   escape/measure check; reject (loudly) otherwise. "Sound iff measured" with no
   check is a verify-clean silent-miscompile risk.
2. **`free` only on a clean rail.** `cqrt_free` is **compiler-emitted only** (never
   user-facing) — confirmed in the runtime/header. On real hardware reclaiming a
   qubit is a reset = projective measurement; freeing a rail still entangled with
   the flag/`q` is a **hidden measurement that collapses `q`** before the user's
   measure (verified: changes outcome statistics for non-diagonal arms; safe for
   diagonal `R_z` whose rail returns to `|0⟩`). Rule: emit `free` only after the
   rail is proven `|0⟩` — i.e. after its uncompute, or for diagonal-only arms —
   routed through the same `FreePoint` discipline the controlled-op path already
   uses (free **after** the reversed adjoint; never when `Escaped`/`Measured`).

## 4. Multiple tainted returns

Give **each return site its own return register**. Each park is an uncontrolled
`cqrt_cswap(c_k, live, R_k)`: it routes the live data away, so the remaining work
runs uncontrolled on whatever is left. Program-order semantics are restored by an
**exit priority cascade** — apply the site swaps lowest-priority first, the
first-return condition last so it wins. No per-site "already-returned" flag is
needed. **Validated for all basis inputs** in the oracle (Demo C); because the
cascade is a fixed permutation, linearity extends that to superposed conditions
**for measurement**. Two caveats the doc should keep honest: (i) Demo C tests only
*basis* conditions with `x` bodies — coherent return *values* are untested; and
(ii) "remaining work runs uncontrolled on whatever is left" applies real gates to
parked-to-`|0⟩` rails, leaving branch-correlated garbage on the live register
across the function tail — fine under measure-only, but its uncompute is the same
§3a obligation. This is the natural lowering of D4 (bounded + reconverging
return/break) and falls out of the swap model rather than needing the done-flag
predication sketched earlier. *(NB: `return`/`break` are out of v1 scope and are
currently permanent Phase-4 rejections P2/P3 — this is the design path to lifting
them, not a shipped capability.)*

## 5. What changes vs what stays

- **Replace** (for tainted `br` + `phi`): the diamond paths of
  `ControlDetection`, `ControlledSubstitution`, `MergeDissolution`, and the
  `br`/`phi` removal in `CFGLinearization` → a single swap-route emitter.
  *Caveat:* "a single emitter" is the goal, but the detection matchers and width
  dispatch don't vanish — complexity **moves** into rail allocation, per-width
  `alloc`/`cswap`/`copy`, and reverse-play ordering. Net surface area is expected
  to drop (especially nesting — §6a), but this is a migration, not a deletion.
- **Keep for now:** `select` lowering — a `select` has **no operations in its
  arms** (its operands are already-computed values), so it is purely the *merge*
  step: one or two **controlled-XOR copies** into a fresh register
  (`out ^= c ? a : b`). XOR-copy *reads* the operands without consuming them
  (a CNOT-style computational-basis copy, **not** cloning), so both stay live — no
  no-cloning issue. The only residual corner is XOR-copying a *coherent quantum
  handle* interfered downstream (entangling-copy = which-path): the `R_y` bucket of
  §3, not a classical-data problem.
- **Untouched:** classical (untainted) control flow — compiled exactly as C does,
  at runtime. Only tainted `br i1` is rewritten.
- **Loops:** still require a static upper bound; a loop bounded by quantum data
  must be unrolled (no runtime branch on a qubit). Note unrolled iterations are
  *sequential* (no parallel-arm depth win) and accumulate rails — the one place the
  regime's space cost is paid without the §6 depth payoff.
- **Phase 5 uncompute:** **not deleted** — reused as the region-local reverse-play
  (classical inverses for the classical bulk, controlled-adjoint for `R_y`), and
  its escape/measure analysis is reused for the §3b guard.

## 6. Trade-offs

Stated in the §0 regime (qubits not scarce; optimization out of scope):

| | swap-route (proposed) | controlled-op (today) |
|---|---|---|
| arm gates | verbatim, uncontrolled | each needs a `_controlled` template |
| phi | one uniform CSWAP | per-type reduction |
| nested control | **recursive — same emitter, no flag-conjunction** (§6a) | nested-AND detect + Toffoli conjunction + ordered uncompute |
| uncompute | classical inverse (bulk) / controlled-adjoint (rotations) | required |
| qubits | + work register(s) per arm *(intentional — see §0)* | none extra |
| circuit depth | **`O(max)` over parallel arms** (disjoint rails) | `O(sum)` — arms serialize on `q` |
| coherence | preserved via §3a; rotations carry the quantum content | preserved |

The qubit row is a **declared regime choice**, not a con to minimize (§0). The
depth row is the corresponding upside for mutually-exclusive arms. Efficiency
tuning (collapsing the CSWAP wrap for tiny arms; the loop pebble-game schedule) is
**out of scope**.

### 6a. Selection rule — swap-route is the v1 default; control-in-place is a later refinement

For **v1, swap-route everything uniformly** — one mechanism, no per-arm
classification (simpler emitter, correctness-first). The control-in-place
specialization below is a *deferred optimization*, not a v1 requirement.

When it is added, the carve-out is about **footprint × coherence**, two orthogonal
axes the earlier "rz/ry vs classical" split conflated:

| axis | clean for control-in-place | needs a register regardless |
|------|----------------------------|-----------------------------|
| **footprint** | *genuinely-in-place* unitaries — single/multi-target rotations (`R_z`/`R_y`/`R_x`), Pauli/`x`, in-place `add` (`a += b`) | register-producing ops — `mul`, `icmp`, out-of-place arithmetic (a reversible `mul` needs `\|a,b,0⟩→\|a,b,ab⟩` + uncomputed ancilla **no matter how it is controlled**) |
| **coherence** | phase/superposition carriers (`R_z`/`R_y`) | classical-basis (`add`/`mul`/`x`/`icmp`) |

So "control-in-place leaves no work register, hence no which-path garbage" is true
**only in the in-place∧rotation quadrant** (`R_z`/`R_y`, Pauli). For
register-producing ops the register exists either way, so swap-routing them **costs
nothing extra** and wins by running the body uncontrolled — which *strengthens*
the swap-route case for `mul`/`icmp`/arithmetic. The carve-out should therefore
read "control-in-place for *genuinely-in-place single-target unitaries*", not "for
`rz`/`ry` vs classical ops".

**Nested control is the headline maintainability win.** Today, nesting needs
dedicated machinery: detect the nested-AND pattern (`matchNestedAnd`), build a flag
conjunction (`cqrt_toffoli` AND-ing the flags), control the inner body on it, and
uncompute the conjunction in the right order (`cqrt_toffoli_inv`) — the ordering is
exactly where one real bug class lived. Swap-route deletes all of that: a `br`
inside an arm runs **the same emitter recursively on the enclosing arm's live rail**
(natural in SSA — inside the arm the live handle *is* the routed register). The
`c1 ∧ c2` semantics fall out of the **routing structure** with **no conjunction
ancilla** (the inner effect reaches `q` only if both route-backs carry it —
verified on all four basis combinations). The only residual obligation is the
coherent path: nested reverse-play must compose over the region tree (mechanical
stack-unwind, not bespoke conjunction logic). This is a strict reduction in both
implementation cost and correctness surface.

## 7. Open questions

1. `select`: trivial (a controlled-XOR copy — §5); fold into the emitter or keep
   as-is. Phase-4's P6 rejection was really the *coherent-handle* corner (copying
   an `R_y` superposition interfered downstream), not classical-data aliasing,
   which XOR-copy handles fine — so P6 may relax for classical operands.
2. Work-register reclamation: per §3b, `free` only on a proven-`|0⟩` rail (after
   uncompute, or diagonal-only), via the `FreePoint` discipline. Open: leave
   allocated for a later uncompute pass vs free eagerly per arm.
3. `R_y` handling: the data-derived **flag uncompute** for an off-diagonal arm
   (§3a-A) — leave the flag dirty (measure-only) or preserve `q0` to clean it? And
   the `R_z` phase-compensation bookkeeping when routed.
4. Staging: build the swap-route emitter **alongside** the Phase-4 framework,
   migrate fixtures one shape at a time, then remove the old `br`/`phi` machinery
   — rather than a big-bang replacement. (Coexisting with the eventual §6a
   control-in-place path is fine; v1 needs only the uniform emitter.)
5. **v1 terminality guard (new):** the precise, mechanically-checkable definition
   of "terminal" and where it is enforced (reuse `FreePoint` escape/measure). Until
   this exists, v1 must be flagged experimental / measure-only.
6. **`cqrt_copy_<W>` (new):** confirm the per-width set and its reversible-copy
   semantics before the coherent path lands; it is the design's only new ABI.

## 8. Prototype status

- **The prototype is the IR** (`swap_route_if_diamond.ll`, `swap_route_ifelse.ll`):
  the exact target output, in FileCheck idiom, that the new lowering must emit.
  They are the spec the pass is built against.
- `prototype_semantics.py` is a **one-off semantics oracle**, not a deliverable
  and not part of the build. It shows what `.ll` text cannot: swap-route ≡
  controlled-op under measurement (max diff `3e-16`), the §3 `R_y` coherence
  numbers, and the §4 return cascade. **Coverage gaps to close** (review): it
  models control as an *independent single qubit*, not the multi-qubit
  `flag = icmp(q,5)` the fixtures derive from the data (argued sound for
  measurement, not simulated); it uses only `R_y` arms (Demo A/B) and basis
  conditions (Demo C); and it **never runs method (B)** — a demo that runs path B
  and *measures the output register* would have caught the §3a inversion and should
  be added. Safe to delete once the numbers here are trusted; regenerable on demand.

## 9. Next step (proposed, not started)

Implement the swap-route emitter behind a flag, targeting `swap_route_if_diamond.ll`
first, then `swap_route_ifelse.ll`, **with the §3b guards in place from the start**.
No ROADMAP / beads changes until we agree this scope.
