# RSSA swap-routed tainted control flow — scoping

**Status:** design **settled** by the author (2026-06-08) and moving to
implementation on branch `swap-route-control`. The old controlled-op control path
has been removed from the tree (commit `7cde677`); the ROADMAP "Phase 4 — RSSA
swap-routed control flow" block carries the phasing. Coherent-first, no
measure-only mode (see the 2026-06-08 revision note below).

**Revised 2026-06-07 after a critical review** (statevector-checked). Material
corrections: §3a (the coherent-path generality was *inverted* — now fixed),
§3/§6 (the regime assumption is now stated; "coherence only from `R_z`/`R_y`" and
"classical ops are free permutations" are qualified), §6a (the in-place carve-out
is re-scoped to genuinely-in-place unitaries), §1/§3 (the `543bd85` provenance is
corrected). Items the review *confirmed sound*: the routing permutation, the
diagonal-arm method-A rail-clean, and that nested control gets **cheaper**, not
harder (§6a).

**Revised 2026-06-08 (implementation kickoff).** Two author decisions supersede
the earlier draft and are folded in below. (1) **No "measure-only" mode — the
compiler never inserts a measurement the user did not write.** Coherence is
restored unitarily by region-local **reverse-play** uncompute, which is
*mandatory in every increment*, not deferred; the forward-only / measure-terminal
"v1" sketch is **struck** (§3, §3b, §4, §9). (2) **Staging is by arm-body class**,
not by measurement regime: rotation arms (§3a method-A, no new ABI) first, then
classical-permutation arms (§3a method-B, `cqrt_copy_<W>`). Also: the old
controlled-op control path has been removed from the tree (branch
`swap-route-control`) so this design is built without it shaping it.

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
the **rotation-arm increment** (method-A, §3a) adds **no new runtime ABI
surface**; the **classical-permutation-arm increment** (method-B, §3a) adds
exactly one new primitive (a per-width reversible copy `cqrt_copy_<W>`). Both are
coherent. Concrete target IR: the two `.ll` specs.

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

**Measurement — none is added, ever.** The compiler never inserts a measurement
the user did not write (a hard project invariant). There is **no "measure-only"
mode**: coherence is restored *unitarily* by region-local **reverse-play** (the
adjoint of the forward stream), so the routed output is correct even under
downstream interference (Grover etc.) with **no terminal-measurement assumption**.
Reverse-play uncompute is therefore **mandatory in every increment**, not a
deferred refinement — the inactive rail is returned to `|0⟩` by adjointing the
arm body, never by relying on a measurement to render its garbage harmless. (An
earlier draft floated a forward-only "v1" that kept rail garbage and leaned on a
measure-terminal precondition; that mode is struck — it is not built.)

**Bonus — what swap-route does and does not "dissolve" re `543bd85`.** The
divergent-arm `rz(-a)·rz(-b)` hazard came from flattening exclusive arms onto one
register and reversing them at a single merge. Swap-route keeps exclusive arms on
*separate rails*, so the single-register reversal that bred the hazard never
forms. But reverse-play uncompute is mandatory (§3 — there is no skip-uncompute
mode), so the negated-rotation adjoint (`rz(-b); rz(-a)`) is still emitted on each
rail (§3a / the uncompute fixture); swap-route must reproduce the same care the
Phase-5 `isStep2Emittable` guard encodes. The hazard is **restructured onto
disjoint rails**, not waved away by omitting uncompute.

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
from `q` — the pre-body `q0` must be **preserved** to uncompute it (leaving the
flag dirty is **not** an option: there is no measure-only mode, §3). This is the
genuine open question for coherent `R_y` (§7.3), and is why the in-place fixture
is correctly scoped **diagonal-only** for now.

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

### 3b. Soundness obligation: reverse-play, then free on a clean rail

There is no measure-only shortcut (§3), so the single soundness obligation is that
every rail is **uncomputed back to `|0⟩` by reverse-play before it is freed**:

- **`free` only on a proven-`|0⟩` rail.** `cqrt_free` is **compiler-emitted only**
  (never user-facing) — confirmed in the runtime/header. On real hardware
  reclaiming a qubit is a reset = projective measurement; freeing a rail still
  entangled with the flag/`q` is a **hidden measurement that collapses `q`** before
  the user's own measure (verified: changes outcome statistics for non-diagonal
  arms). Because reverse-play runs unconditionally, the rail is `|0⟩` at the free
  point *by construction*; emit `free` **after** the reversed adjoint, routed
  through the same `FreePoint` discipline the data-uncompute path already uses
  (never when `Escaped`/`Measured` — there the caller owns the handle).

The terminality "measure before interference" gate from the forward-only sketch is
**gone**: coherence is guaranteed by the mandatory reverse-play, not by a
measurement precondition. This is the one §3b carry-over.

## 4. Multiple tainted returns

Give **each return site its own return register**. Each park is an uncontrolled
`cqrt_cswap(c_k, live, R_k)`: it routes the live data away, so the remaining work
runs uncontrolled on whatever is left. Program-order semantics are restored by an
**exit priority cascade** — apply the site swaps lowest-priority first, the
first-return condition last so it wins. No per-site "already-returned" flag is
needed. **Validated for all basis inputs** in the oracle (Demo C); because the
cascade is a fixed permutation, linearity extends it to superposed conditions.
Two caveats the doc should keep honest: (i) Demo C tests only *basis* conditions
with `x` bodies — coherent return *values* are untested; and (ii) "remaining work
runs uncontrolled on whatever is left" applies real gates to parked-to-`|0⟩`
rails, leaving branch-correlated garbage on the live register across the function
tail — that garbage is uncomputed by the **same §3a reverse-play obligation** as
any other rail (no measure-only escape hatch). This is the natural lowering of D4
(bounded + reconverging return/break) and falls out of the swap model rather than
needing the done-flag predication sketched earlier. *(NB: `return`/`break` are out
of the initial scope and are currently permanent Phase-4 rejections P2/P3 — this
is the design path to lifting them, not a shipped capability.)*

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

### 6a. Selection rule — swap-route everything uniformly first; control-in-place is a later refinement

The **first increment swap-routes everything uniformly** — one mechanism, no
per-arm classification (simpler emitter, correctness-first). The control-in-place
specialization below is a *deferred optimization*, not an initial requirement.

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
   (§3a-A) — preserve the pre-body `q0` to clean the flag (leaving it dirty is
   off the table — no measure-only mode), or find a coherent alternative. And the
   `R_z` phase-compensation bookkeeping when routed.
4. Staging: the old control path is already removed (branch `swap-route-control`),
   so this is a clean-slate build, not a coexist-then-migrate. Open: order the
   arm-body classes (rotation method-A first, then classical method-B) and the
   shapes (if-diamond → if/else → nested) within that. (Coexisting with the
   eventual §6a control-in-place path is fine; the first increment needs only the
   uniform emitter.)
5. **Reverse-play scope (replaces the struck terminality guard):** confirm the
   region-local reverse-play reuses the existing `EmitInverse` spine cleanly for
   every arm-body class, and that the §3b free-on-clean-rail point is the
   `FreePoint` post-dominator the data-uncompute path already computes — there is
   no separate "terminal" definition to enforce.
6. **`cqrt_copy_<W>` (new):** confirm the per-width set and its reversible-copy
   semantics before the classical-arm (method-B) increment lands; it is the
   design's only new ABI.

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

## 9. Next step (in progress)

The old controlled-op control path has been removed (branch `swap-route-control`);
a transitional stub diagnoses tainted control flow loudly until the emitter lands.
Implement the swap-route emitter targeting `swap_route_if_diamond.ll` first, then
`swap_route_ifelse.ll`, **coherent from the start** — region-local reverse-play
uncompute (§3a method-A for rotation arms) and the §3b free-on-clean-rail
discipline are in scope from the first increment; there is **no measure-only
intermediate**. Staging is by arm-body class: rotation arms (method-A, no new ABI)
first, then classical-permutation arms (method-B, `cqrt_copy_<W>`). The ROADMAP
"Phase 4 — RSSA swap-routed control flow" block tracks the phasing.
