# RSSA swap-routed tainted control flow — scoping

**Status:** design settled, revised **2026-06-09** (statevector-checked dialogue;
supersedes the 2026-06-08 method-A / reverse-play-mandatory framing — see the
2026-06-09 revision note below). Implementing on branch `swap-route-control`. The
old controlled-op control path has been removed from the tree (commit `7cde677`);
the ROADMAP "Phase 4 — RSSA swap-routed control flow" block carries the phasing.
The compiler never inserts a measurement the user did not write (enforced by never
freeing a non-`|0⟩` rail, §3b); no measure-only mode.

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

**Revised 2026-06-09 (statevector-checked design dialogue — supersedes the
method-A / reverse-play-mandatory framing).** Four author decisions, folded into
§3a/§3b/§3c/§7 below; the older §3a "method-A is THE coherent path for rotations"
is **struck**. (1) **`Rz = diag(1, e^{iθ})`** (phase-gate convention): `Rz|0⟩ =
|0⟩`, so a phase arm's inactive work rail returns to `|0⟩` *unconditionally* — no
rail garbage, clean free. (2) **Method-A (controlled-adjoint rail cleanup) is
dropped.** Emitting a controlled gate to clean a rail buys nothing over
controlling the op in place from the start (§6a), so we never do it. (3)
**Coherence for phase arms is a cheap *flag-strip*, not reverse-play:** the flag
is `icmp(q0)` and a phase arm preserves `q`'s computational-basis value, so
`icmp_inv(q)` (uncontrolled, zero controlled gates) disentangles the flag and
leaves `q` interference-safe (§3a). Reverse-play (the full-region adjoint via
`emit_inverse`) is retained as the **on-demand** undo (user `cq_invert` / oracle
uncompute), *not* an eager per-increment step — this relaxes the 2026-06-08
"mandatory in every increment." (4) **One rejection (§3c):** an arm that
*value-changes a quantum variable the condition reads* is declined loudly —
model-independent and information-theoretically unfixable for non-injective maps;
it is **not** about arm class. The "no added measurement" invariant is unchanged
and is enforced by *never freeing a non-`|0⟩` rail* (a dirty rail is left
allocated, §3b).

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
- `swap_route_if_diamond.ll` — IR spec: one-content-arm PHASE diamond, coherent
  target output (flag-strip, zero controlled gates).
- `swap_route_ifelse.ll` — IR spec: two-arm if/else, coherent target output.
- `swap_route_if_diamond_uncompute.ll` — IR spec: the uncompute companion —
  full-region reverse-play (Case B, on-demand undo) + the 4.2 value-arm copy-out
  sketch. (Method-A controlled rail cleanup is struck — §3a.)
- `swap_route_reject_clobber.ll` — IR spec: the §3c rejection (an arm value-changes
  a variable the condition reads → loud decline).
- `prototype_semantics.py` — one-off statevector oracle (NOT part of the build;
  see §8). Validates the semantics the `.ll` specs cannot show on their face.
- `MINT_AT_COMPARE.md` + `investigation_mint_at_compare.py` — design-of-record
  + oracle for the chained-Ry stale-condition shape (test_C_libtooling-ee5):
  mint-at-compare fixes arm selection but **no flag-freeing compilation is
  source-exact** — the "condition predates a non-diagonal gate" decline is
  permanent. The guard is SSA-wire-walk hardened, seeded from the condition's
  full tainted provenance (covers both sunk-compare scheduling and derived
  conditions that hide the wire behind pure arithmetic); the branch-free
  instance of the same stale-record family is tracked pass-wide as
  test_C_libtooling-uzb.

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
the **phase-arm increment** (§3a flag-strip) adds **no new runtime ABI surface**;
the **value-/classical-permutation-arm increment** (method-B, §3a) adds exactly
one new primitive (a per-width reversible copy `cqrt_copy_<W>`). Both are coherent.
Concrete target IR: the two `.ll` specs.

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
| `R_y` (off-diagonal) | genuine superposition `cos·\|0⟩ + sin·\|1⟩` entangled with control | on a condition var → §3c reject; else deferred to §6a, on-demand reverse-play (Case B) — **not** method-A | **the one to be careful with** |

**Measurement — none is added, ever.** The compiler never inserts a measurement
the user did not write (a hard project invariant), enforced by **never freeing a
non-`|0⟩` rail** (§3b — a dirty rail is left allocated, not reset). Coherence does
not require an eager region reverse-play: for **phase arms** it is the §3a
*flag-strip* (`icmp_inv(q)`, zero controlled gates), which leaves the routed output
correct even under downstream interference (Grover etc.) with **no
terminal-measurement assumption**; for **value arms** and explicit user inversion
it is **on-demand reverse-play** (§3a). (Two earlier drafts are struck: a
forward-only "v1" that freed rail garbage on a measure-terminal precondition; and
the 2026-06-08 "reverse-play mandatory in every increment" — replaced by the
flag-strip for the common phase case. Revised 2026-06-09.)

**Bonus — what swap-route does and does not "dissolve" re `543bd85`.** The
divergent-arm `rz(-a)·rz(-b)` hazard came from flattening exclusive arms onto one
register and reversing them at a single merge. Swap-route keeps exclusive arms on
*separate rails*, so the single-register reversal that bred the hazard never
forms — the hazard is **restructured onto disjoint rails**. For the canonical
**phase arm** no per-rail adjoint is emitted at all (the rail is `|0⟩` for free,
`Rz|0⟩ = |0⟩`, and coherence is the §3a flag-strip). The negated-rotation adjoint
(`rz(-b); rz(-a)`) appears **only** under on-demand full-region reverse-play (user
`cq_invert` / a value-arm method-B), where it is the verbatim forward stream played
backward — not a mandatory per-rail step (the 2026-06-08 "no skip-uncompute mode"
is superseded, §3/§3a). Where it does run, it reuses the same `EmitInverse` care
the Phase-5 `isStep2Emittable` guard encodes.

## 3a. The coherent path: flag-strip for phase arms, copy-out for value arms

> **Correction history.** The 2026-06-07 review struck an even earlier "compute →
> copy-out → reverse-play is the general method" claim (it dephases rotations:
> `P0` 0.585 → 0.500). The **2026-06-09** revision then struck *that* review's
> replacement — "method-A (controlled-adjoint rail cleanup) is THE coherent path
> for rotations" — because it buys nothing over control-in-place (§6a). What
> survives is below: a *flag-strip* for phase arms (no controlled gates) and
> *copy-out* for value arms. The `.ll` fixtures are regenerated to match.

The forward swap-route is a clean unitary `R` of self-inverse pieces (`cqrt_cswap`,
`cqrt_x`) plus the arm bodies. The question is not "how to reverse `R`" but "how to
leave `q` with the answer while the flag and rails return to `|0⟩`." Under the
`Rz = diag(1, e^{iθ})` convention the answer splits cleanly by arm class.

**Phase arms (`Rz` — the canonical case): flag-strip, zero controlled gates.** An
`Rz` arm adds only a *phase* to `q`; it does **not** change `q`'s
computational-basis value. Two consequences:
- The inactive work rail, routed from `|0⟩` and acted on by `Rz`, stays `|0⟩`
  (`Rz|0⟩ = |0⟩`) — clean and disentangled, freed as a no-op reset.
- The flag, minted `icmp(q0)`, is still true of the *current* `q` (same basis
  value), so `icmp_inv(q)` recomputes the stored bit and XORs the flag back to
  `|0⟩` — disentangling it from `q` with **no controlled gate and no `q0`
  preserved**. `q` keeps the conditional phase; the flag and rail are freed.

The result is coherent: correct under measurement, full-region undo, **and**
downstream interference (Grover). Statevector check (`if(q==1) rz(q,θ)`):
`(|0⟩+|1⟩)/√2 ⊗ |0⟩_f → (|0⟩_q|0⟩_f + e^{iθ}|1⟩_q|1⟩_f)/√2 →[icmp_inv]
(|0⟩ + e^{iθ}|1⟩)/√2 ⊗ |0⟩_f` — flag freed, answer kept.

**Value arms (`add`, `mul`, `x`, `toffoli` — §4.2): compute → copy-out →
reverse-play.** A value arm *does* change `q`'s basis value, so the flag-strip
above is invalid (see §3c) — but the answer is **basis-valued**, so it can be
copied. Run `R`, CNOT the result into a fresh register (`cqrt_copy_<W>`), then
reverse-play `R†` to restore `q0` and zero the rail (which makes the trailing
`icmp_inv` flag-uncompute trivially valid, since `q == q0` again). This is Bennett
compute-copy-uncompute; it preserves a basis-valued result. It is **wrong for
`Rz`/`Ry`**: a CNOT copies a basis *label*, not a *phase*, so `R†` cancels exactly
the phase/superposition that was the answer. The copy is the design's **only new
ABI** — per-width (`cqrt_copy_i32`, …), one transversal-CNOT copy per width,
*not* a single symbol, *not* cloning. See `swap_route_if_diamond_uncompute.ll`.

Both paths reuse the existing `EmitInverse` machinery and need no
`ChainWalk`/`FreePoint` lineage analysis — the uncompute target is the verbatim
forward stream.

**`Ry` arms.** `Ry` is the one non-diagonal rotation (`Ry(θ)|0⟩ = cos|0⟩ +
sin|1⟩` — it *creates* superposition, so it is neither a phase arm nor a
basis-valued value arm). An `Ry` arm **on a condition variable** changes `q`'s
value, so it falls under the §3c rejection (the flag cannot be stripped from `q`,
and the answer cannot be copied as a basis label). An `Ry` arm on a *non-condition*
register has no flag-input hazard; coherent reuse of its superposition answer is
deferred to the §6a control-in-place path, with **full-region reverse-play** (Case
B) available meanwhile. The 2026-06-08 "§7.3 open question" for coherent `Ry` is
thereby **scoped out**, not left dangling: under whole-region reverse-play `q0` is
restored *before* the flag uncompute, so the data-derived flag uncomputes
correctly there regardless of arm class.

### 3b. Soundness obligation: free only a proven-`|0⟩` rail; never free dirty

The "no added measurement" invariant has exactly one teeth at this layer:

- **`free` only on a proven-`|0⟩` rail.** `cqrt_free` is **compiler-emitted only**
  (never user-facing) — confirmed in the runtime/header. On real hardware
  reclaiming a qubit is a reset = projective measurement; freeing a rail still
  entangled with the flag/`q` is a **hidden measurement that collapses `q`** before
  the user's own measure (verified: changes outcome statistics for value /
  non-diagonal arms). So a rail is freed only where it is provably `|0⟩`:
  - **phase arms** — the rail is `|0⟩` for free (`Rz|0⟩ = |0⟩`), so `free` is
    emitted right after the route-back, gated through the `FreePoint` discipline
    (never when `Escaped`/`Measured` — there the caller owns the handle);
  - **value arms** — `|0⟩` only after the method-B reverse-play, so `free` follows
    the reversed adjoint.
- **A rail that is not provably `|0⟩` is left allocated, not freed.** This is the
  struck "v1" bug inverted: v1 freed dirty rails (a hidden measurement); the fix is
  to *not free* them. An un-freed dirty rail is a qubit "leak," accepted in the
  qubits-not-scarce regime (§0); it is reclaimed only by a later full-region
  reverse-play (§3a / Case B), where it returns to `|0⟩` before its `free`.

The terminality "measure before interference" gate from the forward-only sketch is
**gone**: phase-arm coherence is guaranteed by the §3a flag-strip, and value-arm /
whole-region coherence by on-demand reverse-play — never by a measurement
precondition.

### 3c. The one rejection: clobbering the control's own data

The flag is `icmp(q0)` — computed from the condition's quantum inputs. The hazard
is **overwriting the computational-basis value of a register the condition was
derived from**, after which the flag references a value no longer present in any
live register. Precisely:

> **Reject (loud `DiagnosticInfoUnsupported`) iff an arm performs a value-changing
> write to a quantum variable the branch condition transitively reads.**

This is *not* about arm class. The boundaries, by SSA-value provenance (detection
is pure analysis before any mutation, Rule 9):

| arm shape | example | verdict |
|---|---|---|
| phase op on a condition variable | `if(q>5) rz(q,a)` | **accept** — value preserved, flag recomputable |
| value op on a *non-condition* register | `if(q>5) p=p+3` | **accept** — `q` untouched (method-B, §4.2) |
| *read* of a condition variable | `if(q>5) p=q+1` | **accept** — `q`'s value survives |
| value-change of a condition variable | `if(q>5) q+=3`, `if(q==1) x(q)` | **reject** |

*(Reading note, 2026-06-10 — PRD Part II §8.3: this table's "accept" column
means "**not rejected by §3c**", not "routable in 4.2" — e.g. `if(q>5) p=q+1`
is no §3c clobber yet still declines `control flow` until a mux-capable
increment.)*

Why reject rather than patch it: when `q` is clobbered, the induced map
`q0 → cond(q0)?f(q0):q0` is either injective (a legitimate unitary, but the
compiler cannot cheaply prove the disjoint-image condition that makes it one) or
**non-injective** (`if(q==1) x(q)` → the constant `0` — irreversible). For the
non-injective case **no control model and no Bennett copy can produce a clean,
disentangled answer**: by conservation of information the lost which-branch data
must live in an ancilla entangled with the result, removable only by measurement.
Statevector witness (`if(q==1) x(q)`): `(|0⟩+|1⟩)/√2 ⊗ |0⟩_f → |0⟩_q ⊗
(|0⟩_f+|1⟩_f)/√2` — `q` is now constant `|0⟩` and carries no branch information, so
`icmp_inv(q)` cannot recompute the flag; the flag holds the last copy. The result
is model-independent: control-in-place reaches the identical end state. So the true
options for the hazard are **reject** or **don't-uncompute** (leave the flag dirty,
measure-/undo-terminal only); the author chose **reject**. (Bennett-with-history
was considered and dropped: the clobbered `q0` is dead, so preserving it buys no
coherent reuse — Bennett stays the tool for Phase-6 function lifting, not control.)

The predicate is **vacuous for pure-phase 4.1** (phase arms never value-write) and
becomes active with value arms (4.2); it ships in 4.1 as a decline fixture +
adversarial probe regardless (Rule 12).

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
- **Phase 5 uncompute:** **not deleted** — reused as the on-demand full-region
  reverse-play (the verbatim forward stream played backward via `EmitInverse`:
  classical inverses for the classical bulk, `rz/ry(θ) → rz/ry(-θ)` for rotations
  — *not* a controlled-adjoint rail cleanup, which is dropped), and its
  escape/measure analysis is reused for the §3b free-on-clean-rail guard.

## 6. Trade-offs

Stated in the §0 regime (qubits not scarce; optimization out of scope):

| | swap-route (proposed) | controlled-op (today) |
|---|---|---|
| arm gates | verbatim, uncontrolled | each needs a `_controlled` template |
| phi | one uniform CSWAP | per-type reduction |
| nested control | **recursive — same emitter, no flag-conjunction** (§6a) | nested-AND detect + Toffoli conjunction + ordered uncompute |
| uncompute | phase arms: uncontrolled `icmp_inv` flag-strip (zero controlled gates) · value arms: classical inverse / on-demand reverse-play | required |
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
2. Work-register reclamation: per §3b, `free` only on a proven-`|0⟩` rail; a dirty
   rail is **left allocated** and reclaimed by on-demand reverse-play (§3a). For
   phase arms the rail is `|0⟩` for free, so it is freed eagerly. **[Resolved
   2026-06-09.]**
3. ~~`R_y` data-derived flag uncompute~~ — **resolved 2026-06-09 (§3a, §3c).** An
   `R_y` arm on a *condition* variable clobbers `q`'s value → §3c rejection; on a
   *non-condition* register coherent reuse is deferred to §6a, with reverse-play
   (Case B) available. No eager-keep-the-answer obligation for `R_y` remains, so
   there is no "preserve `q0`" problem.
4. Staging: clean-slate build (old path removed). **Order fixed 2026-06-09:**
   phase arms (§3a flag-strip, no new ABI) → value/permutation arms (method-B,
   `cqrt_copy_<W>`) → nested → `select` → `switch`; shapes within 4.1 are
   if-diamond → if/else. The §6a control-in-place path coexists later.
5. **Reverse-play scope:** confirm the region-local reverse-play reuses the
   existing `EmitInverse` spine cleanly for every arm-body class (method-B and
   user `cq_invert`), and that the §3b free point is the `FreePoint` post-dominator
   the data-uncompute path already computes — there is no separate "terminal"
   definition. **[Resolution pinned 2026-06-10, PRD Part II §8.5:**
   `emitInverseChain` reverses the body chain only (first real invocation, 4.2
   WI-4); the route cswaps are bracketed by the emitter's own `emitRoute`
   because `emitInverseCall` threads the involution handle into arg 0 — the
   cswap FLAG slot; the §3b free point is the trivially-post-dominating
   single-block region point, `computeFreePoint` generalizing at 4.3.
   Discharged when 4.2 WI-4 lands.]**
6. **`cqrt_copy_<W>` (new):** confirm the per-width set and its reversible-copy
   semantics before the value-arm (method-B) increment lands; it is the design's
   only new ABI. **[Resolved 2026-06-10 as a written design decision — PRD
   Part II §8.1 (`docs/prd/phase-04-swap-route-control/PRD.md`): the 5 integer
   widths `i1/i8/i16/i32/i64` only (an FP merge φ is an angle, never data);
   keep-sources-live transversal-CNOT basis copy `|x⟩|0⟩→|x⟩|x⟩`, an
   involution, no `_inv` twin, never frees its source (Rule 8); hand-written
   `cqrt_*` core ABI (`runtime/cq_runtime.{h,c}`, the `cqrt_cswap` precedent),
   NOT the generated YAML surface. Lands with 4.2 WI-1.]**

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
  *(The "should be added" sentence and the coverage-gap closure above are
  superseded by the 2026-06-10 annotation below — kept as historical text.)*
  **[2026-06-10: the method-B demo obligation is STRUCK by owner decision —
  no statevector simulations at this stage. The B-keep boundary is documented
  analytically in PRD Part II §8.2 (two-channel closed forms + witness numbers
  recorded by independent review, 2026-06-10) and is cleared by independent
  adversarial review (4.2 WI-7) reasoning against those closed forms. The
  oracle `.py` files in this directory remain as historical design artifacts
  only — not gates.]**

## 9. Next step

**4.1 (phase arms) landed and closed 2026-06-10** (epic `e4baa67`; derived-base
addendum `9786cef`): `ControlDetect`/`ArmClassify`/`SwapRouteEmit`/`RegionFlatten`
lower the phase-arm if-diamond and if/else exactly as §3a specifies — route
uncontrolled, free the `|0⟩` rail, strip the flag with `icmp_inv(q)`, zero
controlled gates, no new ABI — with the §3c clobber reject and the tainted-angle /
stale-condition guard families alongside (see `MINT_AT_COMPARE.md` for the
chained-Ry stale-condition verdict: permanent decline, purity theorem). Every
not-yet-built shape declines loudly.

**Next: 4.2 — value/permutation arms (method-B, `cqrt_copy_<W>`).** Entry gates
(status 2026-06-10): **(i) PRD/WI breakdown — DONE** (PRD Part II §§7–10 +
`IMPLEMENTATION-4.2.md`, bd epic filed); **(ii) §7.6 copy-ABI width
set/semantics — RESOLVED** as a design decision (PRD §8.1; lands WI-1);
(iii) the §8 method-B demo — **STRUCK by owner decision 2026-06-10** (no
simulations at this stage; the B-keep boundary is documented analytically in
PRD §8.2, cleared by the WI-7 independent adversarial review); (iv) §3c
activation + the Defect-2 string fix — scoped WI-3; (v) first real
`emitInverseChain` invocation (§7.5, resolution pinned) — lands WI-4. Then 4.3 nested → 4.4
select → 4.5 switch. Reverse-play stays the on-demand undo, not an eager step
(§3a). The ROADMAP "Phase 4 — RSSA swap-routed control flow" block and
[`docs/prd/phase-04-swap-route-control/PRD.md`](../../prd/phase-04-swap-route-control/PRD.md)
track the phasing.
