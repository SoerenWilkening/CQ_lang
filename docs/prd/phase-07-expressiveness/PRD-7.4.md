# Phase 7.4 PRD — Controlled `break` / loop early-exit (value-arm, rolled-in-place)

> **Status: Increment 1 DONE 2026-06-25 (`y05j.1`) — the `tryBreak` recognizer +
> the `-O1` fused-exit decomposition + the value-arm-vs-quantum-bounded partition +
> all decline diagnostics, PURE ANALYSIS (no emission, no ABI). Cleared by three
> independent adversarial Rule-13 rounds (89 + 28 + 58 probes); the first two found
> + fixed a Risk-4 false-accept (a genuinely quantum-bounded loop with a
> loop-invariant guard / non-terminating bound mis-recognized as a value-arm
> break), now closed by a ScalarEvolution finite-classical-trip-bound proof (B5
> `hasFiniteClassicalTripBound`, superseding an unsound structural "bound
> references the counter" check). A 2026-06-26 coverage widening (owner ask) then
> added general CLASSICAL non-unit strides (`for(i<n;i+=2)…break`) via a structural
> constant-step termination proof (`boundProvablyTerminates`); a further adversarial
> round found + fixed a clang-reachable two-counter-diverging overflow false-accept
> (`boundComparesInductionToInvariant` — the bound must compare the induction against
> a loop-invariant limit), cleared across i8–i128 (a 57-probe sweep, 0 false-accepts).
> DECLINE-SAFE gaps deferred to Inc 2 (owner 2026-06-26): constant-bound-no-merge-phi
> and multiplicative/non-AddRec counters; plus an Inc-2 single-classical-exit
> precondition note (E2). **Increment 2 DONE 2026-06-26 (`y05j.2`) — the capture +
> whole-loop reverse-play EMISSION.** Staging owner-confirmed (AskUserQuestion): the
> reverse-play is a NEW POST-LOWERING stage `lowerBreakReversePlay`
> (`BreakReversePlay.cpp`) on the lowered body (`emitInverseChain` consumes lowered
> calls), with `emitBreakForward` (pre-lowering) doing the forward transform (rail
> collapse, terminator strip to the classical bound, `R`/`idx`/`out` mint, exit-phi
> RAUW); the adjoint spine is extended with `cqrt_xorc` (re-emit) / `cqrt_addc`
> (immediate-negate) branches. The CANONICAL xor capture+reverse-play was cleared
> CORRECT by independent adversarial review (reversible-semantics sim-replay over
> every amplitude branch n=0–6 + line-by-line hand-trace: `out` = first-break answer,
> `R`/`idx`/rail → |0>/q0, clean frees, `out` disentangled, O(1) scratch, first-fire
> idempotent, n=0 zero-trip clean). THREE adversarial Rule-13 rounds found + fixed
> SEVEN over-accept holes, each now a conservative `emitBreakForward` precondition
> E1–E11 (decline `kMsgBreakUnemittable`): E6 PreB dominates the exit; E7 counter
> start == 0; **E8** every non-final rail value consumed only by the mutation chain
> (closes the add strength-reduction AND multi-op intermediate-read silent
> miscompiles); E9 break-cond reads only rail+invariants (closes counter-read); E10
> rail-op immediate loop-invariant; E11 body coverage (closes the stray-taint
> half-transform). A FOURTH (FINAL) adversarial round (2026-06-26) added two more
> (NINE holes total): **E12** — the reverse-play companion loop REUSES the forward
> zero-trip ENTRY guard (`Rgn.GuardCond`/`GuardLoopOnTrue`, captured pre-lowering)
> rather than a re-invented signed `sgt(n,0)`; for an UNSIGNED `n ≥ 2^31` the
> `-O1` entry guard is `icmp eq n,0` (enter iff `n != 0`) so a signed `sgt(n,0)`
> would skip the WHOLE reverse-play while the forward captures into `R`/`idx`,
> freeing them DIRTY (a Rule-6 hidden measurement — a silent miscompile; positive
> fixture `lowering_loop_break_unsigned.ll`); and the in-body **side-effect guard**
> — `tryBreak`'s body scan declines any `mayHaveSideEffects()` op (a `cq_measure` /
> side-effecting call / volatile store), since the rolled break replays the body
> ~2n times (full-trip forward + reverse-play) and an observable/irreversible op
> there violates Rule 5 + is unrecoverable (rides L1; reject fixture
> `lowering_reject_break_measure_in_body.ll`). DECLINE-SAFE over-declines (filed): transparent const-comparison
> strength-reduction (`q<0`), narrow i8/i16 trunc rails. Full suite 49 ctest / 534
> lit green; e2e golden `slice_loop_break.c` byte-clean. PRD drafted 2026-06-25 (epic
> `y05j`), design owner-confirmed (AskUserQuestion 2026-06-25/26).** Builds directly on Phase
> 7.3 (rolled-in-place bounded loops, epic `799w`, DONE) and reuses the Phase-7.2
> exit-cascade vocabulary (epic `65wb`) **conceptually only** — the actual
> mechanism is the **O(1)-carried copy-not-move capture (index-gated) + whole-loop
> Bennett reverse-play**, not the straight-line §4 cascade (see §2.1, which
> corrects the ROADMAP "near-free cascade reuse" framing). New analysis +
> emission in `ir-pass/src/LoopLowering.cpp` (a `tryBreak` sibling of `tryCaseA`)
> over the existing `lowerLoops` stage; **no new frozen runtime ABI** (reuses
> `cqrt_alloc_<W>` / `cqrt_copy_<W>_controlled` / `cqrt_toffoli` / `cqrt_x` /
> `cqrt_cnot` / `cqrt_copy_<W>` / the `emitInverseChain` adjoint spine /
> `cqrt_free`). Does not duplicate
> [`ROADMAP.md`](../../../ROADMAP.md) §"Phase 7 — 7.4" or
> [`docs/design/rssa-swap-control/SCOPING.md`](../../../docs/design/rssa-swap-control/SCOPING.md)
> §4 — captures the 7.4-specific decisions, deliverables, and done criteria.
>
> **Framing correction (owner discussion 2026-06-25, `bd memories
> 7.4-break-design-crux`).** The ROADMAP §7.4 one-liner ("the 7.2 exit-priority
> cascade with the rolled loop's exit as the merge point — near-free reuse") was
> written against the **historical unrolled-loop** model (`SCOPING.md` §4 NB +
> §5, pre the 2026-06-24 rolled-in-place decision). The §4 cascade is a *fixed
> permutation at a single straight-line function tail*, executed **once**. A
> rolled loop re-executes its single `break` site **K times**, so a one-register
> per-iteration cswap re-parks and corrupts. The sound rolled lowering is **not**
> the cascade: it is **Bennett compute → copy → uncompute over the whole loop**,
> with the capture gated by a done-flag and the loop's adjoint replayed to
> disentangle the which-iteration ancilla. An earlier analysis wrongly held this
> "fundamentally unsound (un-uncomputable which-path → Rule-5 measurement)"; that
> conflated *carries which-path info* (true) with *cannot be disentangled*
> (false — whole-loop reverse-play disentangles it, exactly as 7.3 Case B
> reverse-plays per-iteration). Governing memories:
> `[[7.4-break-design-crux]]`, `[[owner-dynamic-circuits-in-model]]`,
> `[[divergent-arm-uncompute-soundness-guard]]`, `[[swap-route-detect-known-limits]]`.
>
> **Owner scope decisions (AskUserQuestion 2026-06-25):**
> 1. **Capture = O(1) carried ancilla** (not O(K) per-iteration registers) — keeps
>    7.3's **dynamic (runtime-classical) trip count**, needs **no static-K, no
>    unroll, no register file, no `_controlled` rotations**. Realized by a
>    **copy-not-move** capture (`cqrt_copy_<W>_controlled`, rail left intact) +
>    a **first-break index register `idx`** so the per-iteration break/latch
>    scratch is uncomputed **in-iteration** (the §2.2a resource derivation,
>    refined from the initial "done-flag" sketch after the owner's O(K)-scratch
>    question 2026-06-25). Carried state = `rail + R + idx`, independent of K.
> 2. **Answer class = value-arm only.** A phase-class escaping answer cannot be
>    CNOT-copied out (Rule 7 dephases) and a data-comparison phase-break is
>    **degenerate** (`Rz` does not change the data, so the break fcmp is
>    iteration-invariant — fires at iteration 0 or never). Phase-arm breaks
>    **decline loudly**.

---

## 0. Invariant recap (not new — the ground 7.4 stands on)

- **Over-declining is safe; over-accepting is a silent miscompile** (Prime
  Directive). A break that captures the wrong iteration's value, re-captures, or
  leaves an entangled `idx`/scratch register dangling is a verify-clean miscompile;
  every new accept-predicate ships a decline fixture + adversarial probe (Rule 12).
- **Verify-clean ≠ correct** (Rule 2). 7.4 touches loop recognition
  (`LoopLowering.cpp`) and adds a **new uncompute schedule** (whole-loop
  reverse-play) over the Phase-5 spine (`EmitInverse`/`FreePoint`/`Uncomputation`)
  — the modules where every silent miscompile has lived. Cleared by independent
  adversarial Rule-13 review, **not** by a green suite (Rule 13).
- **Taint is the only Q/C boundary** (Rule 3). 7.4 adds **no** taint source and
  **no** new opcode taint rule. The break flag is a stock `icmp`/`fcmp` on a live
  tainted value — already tainted by forward propagation; the done-flag and
  capture register are compiler-minted `i32` handles (`cqrt_alloc_<W>`), never new
  taint sources.
- **Coherent-first; never insert a measurement** (Rule 5). 7.4 emits **zero**
  measurements. The "stop iterating" semantics of `break` are realized
  **coherently** — the loop physically runs its full classical trip count; the
  first-break index `idx` freezes the captured value; reverse-play disentangles. No
  measurement collapses the superposed break condition.
- **Method matches arm class** (Rule 7). The captured answer is **basis-valued**
  (the break body mutates data); it is copied out with `cqrt_copy_<W>` (CNOT) and
  the scratch reversed — **method-B Bennett**. A **phase** answer cannot be copied
  this way (a CNOT copies a basis label, not a phase — the P0 0.585→0.500
  dephasing) ⇒ phase-arm break **declines** (§2.6).
- **No-cloning / linearity** (Rule 8). The capture is a **controlled
  computational-basis CNOT-copy** (`cqrt_copy_<W>_controlled`) of the basis-valued
  answer into a `|0⟩` register — copying a basis label is legal (not cloning a
  basis-independent superposition); the rail is left intact. The final copy-out is
  the same basis CNOT of the *answer* (a function of the input — legal), and
  whole-loop reverse-play restores the scratch. The output ends correlated with the
  **input** (the computation) and disentangled from the **which-iteration** ancilla
  — the textbook Bennett guarantee, valid for any unitary forward pass.
- **Free only a proven-`|0⟩` rail** (Rule 6). The capture register `R`, the index
  `idx`, and the rail are returned to `|0⟩` by the whole-loop reverse-play before any
  `cqrt_free` — never freed dirty. The only escaping handle is the copied-out
  answer (`out`), which the user measures/escapes.
- **`clang -O1` is the validated floor** (Rule 9). `-O1` **fuses** the tainted
  break condition with the classical loop bound into a single
  `select(break, true, bound)` and emits a **tainted** loop-exit branch (§1.1,
  verified). 7.4 must **decompose** that select to tell a value-arm break apart
  from a genuinely quantum-bounded loop; detection is pure SSA/CFG analysis before
  any mutation.

---

## 1. Scope

7.4 widens the accepted-C subset so a **classically-bounded** loop (7.3) that
contains a **single tainted-condition early `break`** whose escaping answer is
**value-class** lowers coherently — the loop runs its full classical trip count
rolled in place, and the break is realized by an index-gated copy-not-move capture
+ whole-loop reverse-play. `CQ.h` does not change — `break` is plain C. **No new
frozen ABI** (ROADMAP §7.4): 7.4 reuses `cqrt_alloc_<W>`,
`cqrt_copy_<W>_controlled`, `cqrt_toffoli`,
`cqrt_x`/`cqrt_cnot`, `cqrt_copy_<W>`, the `emitInverseChain` adjoint spine, and
`cqrt_free`.

### 1.1 The load-bearing empirical finding (verified 2026-06-25, Rule 11)

A classically-bounded loop with a tainted-condition `break`
(`for (i<n) { q = mutate(q); if (cond(q)) break; }`) compiles at `-O1` to a
**single rolled block** with (verified IR, `/tmp/break.ll`):

```
  %i   = phi i32   [0, preheader],  [%i.next, latch]       ; classical counter
  %q   = phi <W>   [%q0, preheader], [%q.next, latch]       ; tainted rail (header phi)
  %q.next = <body mutation of %q>                           ; the per-iteration op
  %brk  = <icmp/fcmp on %q.next>                            ; TAINTED break flag
  %i.next = add i32 %i, 1
  %bound  = icmp eq i32 %i.next, %n                         ; CLASSICAL loop bound
  %exit   = select i1 %brk, i1 true, i1 %bound              ; FUSED, tainted
  br i1 %exit, label %loopexit, label %latch                ; TAINTED loop-exit branch
loopexit:
  %ans = phi <W> [%q0, preheader], [%q.next, latch]         ; exit merge phi
```

Two facts fall out: (1) `clang -O1` **fuses** the tainted break flag and the
classical bound into one `select(%brk, true, %bound)` — there is **no** separate
clean break diamond; the exit branch is **tainted**. (2) This shape is
**indistinguishable by terminator-taint alone** from a genuinely
quantum-bounded loop (`while(q<k)`): both present a tainted exit condition. Today
both decline identically via `taintedExit` (`LoopLowering.cpp:112-126`) →
`diagnoseUnderControl(TE, "loop")` → `cq controlled lowering: loop under quantum
control` (PRD-7.3 §2.6, the L1 permanent decline). **7.4's recognizer must
decompose the `select` to separate the two.**

### 1.2 What 7.4 actually is

7.4 is a **loop-recognition + Bennett-over-the-loop** problem, not a tainted-CFG
(swap-route) problem — the loop CFG is preserved (rolled). It refines the 7.3 L1
decline:

- **L1 stays** for a genuinely quantum-bounded loop: an exiting condition that is
  a **bare** live tainted `icmp`/`fcmp` (the bound itself is quantum), or a fused
  exit whose **non-`brk`** operand is **also** tainted (no classical bound to
  fall through to). Permanent decline (different model — ROADMAP "Beyond the
  freeze").
- **7.4 accepts** the **classical-bound-plus-tainted-break** decomposition: an
  exit `select(%brk, true, %bound)` (or `select(%brk, %bound, ...)` /
  `or i1 %brk, %bound` — the `-O1` polarity variants) where `%brk` is a single
  tainted break flag, `%bound` is **classical**, and the loop is otherwise a
  proven 7.3 rolled loop. The captured answer (the exit merge phi) must be
  **value-class** (§2.6).

The mechanism (the heart, §2.2): an index-gated copy-not-move capture register + a
whole-loop reverse-play. **Declined (loud), not lowered:** phase-arm break
(Rule 7), multiple break sites, nested-loop break, `continue`, non-reconverging
break (to cleanup/distinct exits), genuinely quantum-bounded loop, and any body
op not cleanly invertible (§2.7, §2.10 matrix).

---

## 2. Design decisions

### 2.1 The mechanism is whole-loop Bennett, not the §4 cascade (framing correction, owner 2026-06-25)
The ROADMAP "near-free §4 cascade reuse" holds only for *routing a value out at a
single straight-line tail* (Phase 7.2 controlled-`return`). A **rolled** loop
re-executes its one `break` site K times, so a single exit register cswap'd
per-iteration **re-parks** (iteration j+1 swaps the captured value back out
because `cond(|0⟩)` is unconstrained). The sound rolled lowering keeps the loop
CFG and applies **Bennett compute → copy → uncompute over the whole loop body**.
This is the **O(1) capture / dynamic-K** path the owner selected; it needs **no
unroll** (the alternative O(K) per-iteration-register + §4-first-wins-cascade
materialization was considered and declined — it gives up the dynamic bound and
needs a trip-sized register file).

### 2.2 The capture + reverse-play (the heart; SSA/CFG identity before mutation, Rule 9)
**Capture by COPY, not move; gate first-fire by a first-break INDEX register so
the per-iteration scratch is uncomputed in-iteration → O(1) carried ancilla
(the §2.2a derivation).** For a recognized value-arm break loop `L`, `lowerLoops`
emits (all `cqrt_*`, no new ABI):

1. **Mint two `|0⟩` carried rails before the loop:** the capture register `R =
   cqrt_alloc_<W>(0)` and the **first-break index** `idx = cqrt_alloc_iN(0)` (`iN`
   = the loop-counter width, i32/i64; `idx == 0` ≡ *not yet fired*; `idx`
   subsumes a done-flag — see §2.8). Both are **loop-carried** (header phis:
   `[0, preheader], [·, latch]`). All other registers are **per-iteration scratch
   that returns to `|0⟩` before the backedge** (step 2).
2. **In the body, after the break flag `%brk = cond(rail)` is computed
   (`rail` = `%q.next`, the post-mutation rail):**
   - `fire = %brk ∧ (idx == 0)` — a `cqrt_toffoli` into a scratch flag
     (`idx == 0` itself a scratch eq-flag); `fire` = *capture at this iteration*.
   - **COPY (not move) the rail into `R` under `fire`:**
     `cqrt_copy_<W>_controlled(fire, rail, R)` — a computational-basis CNOT-copy
     (Rule-8-legal for the basis-valued answer; **the rail is left INTACT**, the
     load-bearing choice vs. a `cqrt_cswap` move).
   - **Record the iteration:** `idx ← idx ⊕ (fire ? i+1 : 0)` — a
     `cqrt_copy_iN_controlled(fire, ⟨i+1⟩, idx)` (the classical counter `i+1`
     materialized as a basis register; `+1` so iteration 0 is distinguishable from
     "not fired").
   - **Uncompute the scratch in-iteration** (the O(1) move): `fire` is recomputed
     and cleared as `fire ⊕= (idx == i+1)` (true iff *this* iteration was the
     first fire); the `idx == 0` eq-flag is cleared as
     `⊕= ((idx == 0) ∨ (idx == i+1))` (its pre-`idx`-write value, from the current
     `idx` + classical `i`); `%brk` is cleared by recomputing `cond(rail)` (the
     rail is intact). Every scratch register is back to `|0⟩` before the backedge —
     so the body is a **clean per-iteration unitary on `(rail, R, idx)` only**, and
     no flag accumulates across iterations.
3. **At the loop exit, consolidate the never-broke branches:**
   `cqrt_copy_<W>_controlled(idx == 0, rail, R)` so `R` holds the escaping answer on
   **every** amplitude branch (the first-break value where `idx≠0`, the full-trip
   value where `idx==0`).
4. **Copy the answer out:** `out = cqrt_copy_<W>(R)` (a computational-basis CNOT —
   legal for the basis-valued answer, Rule 7/8). `out` is what the post-loop
   `cq_measure`/escape consumes; the exit merge phi is RAUW'd to `out`.
5. **Whole-loop reverse-play (the new schedule, §2.3):** replay the body's
   **adjoint** the same (dynamic) number of times — a second, backward-counted
   loop whose body is `emitInverseChain` of the (already-clean) forward body
   (controlled-copies, the `idx` write, and the scratch logic, all
   self-inverse / invertible). This restores `R → |0⟩`, `idx → |0⟩`, the rail's
   post-capture churn, and `%q` to its pre-loop state — disentangling `out` from
   the which-iteration ancilla. Then `cqrt_free` `R` and `idx` (now proven `|0⟩`,
   Rule 6).

### 2.2a Why O(1) carried, not O(K) (the resource derivation — owner question 2026-06-25)
The naive scheme threatens **two new flags per iteration** — the break flag
`%brk` and the latch scratch `fire = %brk ∧ ¬done` — and, with a `cqrt_cswap`
**move**-capture, *neither is uncomputable in-iteration*: the move zeroes the
fired-branch rail, so `%brk = cond(rail)` cannot be recomputed; and `fire` records
*which* iteration first fired (which-path), un-recoverable from `(%brk, done)`
alone. Both then accumulate → **O(K)** scratch, which in a rolled loop needs a
trip-sized scratch array (bounded/static K) — forfeiting dynamic-K. Two choices
restore O(1): **(i) copy-not-move** keeps the rail intact, so `%brk` recomputes →
in-iteration uncompute; **(ii) the first-break index `idx`** makes `fire`
recomputable as `idx == i+1`, so it too uncomputes in-iteration. The only state
crossing the backedge is then **`rail + R + idx`** — three fixed-width registers,
**independent of K**. The O(K)-scratch fallback (a trip-sized scratch array) is
**rejected** here (it gives up the dynamic bound, §2.1). `idx` carries genuine
which-path info but step-5 reverse-play **uncomputes it** — it is *not* an
un-disposable X1 dirty rail (PRD-7.3 §2.7); the reverse-play is precisely the
schedule the X1 case lacked. Leaving `idx` dangling (a "leak") is **forbidden**:
it is entangled with `out`, so a dangling `idx` dephases `out` under downstream
interference (the Grover/QPE hazard, Rule 5) — reverse-play is **mandatory**.

### 2.3 Whole-loop reverse-play is a THIRD uncompute schedule (the core new machinery + Rule-13 zone)
7.3 ships two schedules: **Case A** in-place (no reverse-play — the answer stays
on the rail) and **Case B** *per-iteration* in-body uncompute (the temp is
recovered within each iteration before the backedge). 7.4 needs a **third**:
the capture register `R` and the first-break index `idx` are **cross-iteration**
live ranges (written at the break iteration, read at the loop exit), which neither
A nor B cleans. 7.4 emits the loop's adjoint as a **backward-counted companion
loop** after the forward loop: for `i = n-1 … 0`, apply `emitInverseChain` of the
forward body. The forward body is a **clean per-iteration unitary on
`(rail, R, idx)`** (the value op + the controlled COPY + the `idx` write + the
in-iteration scratch uncompute, §2.2 step 2 — all self-inverse / invertible), so
its adjoint inverts it; running it the same `n` times (the **same classical** trip
count) restores the pre-loop state. This reuses
`emitInverseChain` (`EmitInverse.cpp:251`) verbatim — the **driver** (a new
backward loop nest) is the only new code. **This is the genuinely-new spine
surgery and the central Rule-13 hazard** (the `divergent-arm-uncompute-soundness-guard`
lesson: the adjoint must replay the body exactly K times with the matching trip
count and matching captured-state, not once at a merge).

### 2.4 Where the break stage slots (orchestration)
7.4 extends the existing `lowerLoops` stage (`CQLoweringPass.cpp:115`, `:266`) —
a `tryBreak` sibling tried **before** `tryCaseA` (a break loop is not a pure
persistent-accumulator). It inherits the 7.3 ordering constraints verbatim:
**before** `detectControlRegions` (so the fused tainted exit is partitioned here,
not mis-declined as a generic `nested control flow…` region), **before**
`declineClassicalMuxes` (so the exit merge phi RAUW'd to `out` never reaches
`kMsgClassicalPhi`), and **before** `lowerRotations` (pre-RAUW `@cq_theta`/`@cq_phi`
SSA identity). The `FreePoint`/`Uncomputation` backedge guards
(`FreePoint.cpp:40,262,300`; `Uncomputation.cpp:244`) remain the **defense-in-depth
backstop** for any break/loop shape the recognizer did not affirmatively accept.
A `LoopBreakRegion` representation (header/latch/preheader/exit-merge + the break
flag SSA value + the classical-bound operand + the captured-value classification)
is added to `LoopPlan.h` rather than overloading `tryCaseA`'s rail vocabulary.

### 2.5 The accept predicate (the §2.2 recognizer; evaluated on SSA/CFG identity before mutation)
A natural loop `L` with a tainted exit is **break-lowerable** iff **ALL** hold:

- **(B1) Classical trip with one tainted break, decomposed.** Exactly one exiting
  branch of `L` has a tainted condition, and that condition decomposes (the `-O1`
  fused forms) into a **single tainted break flag** `%brk` (a stock `icmp`/`fcmp`
  on a live tainted value) **disjoined** with a **classical** bound `%bound`
  (`select(%brk, true, %bound)`, `or i1 %brk, %bound`, and the `clang -O1`
  successor-swapped polarities, Rule 9). If the non-`%brk` operand is **also**
  tainted, or no classical bound exists ⇒ **L1 permanent decline** (genuinely
  quantum-bounded, §2.6). The decomposition is the load-bearing analysis; an
  over-broad `select` match (a real data-mux, two tainted operands) is the
  over-accept hazard (Risk 4).
- **(B2) Reconverging to a single loop exit.** The break edge and the natural-exit
  edge converge to **one** loop-exit merge block carrying **one** merge phi (the
  escaping answer). A break to a distinct cleanup/exit (non-reconverging) ⇒
  decline (reuse the 7.2 `uncondSucc==null` reconvergence fence, conceptually).
- **(B3) Value-class escaping answer.** The exit merge phi's incoming values are
  **basis-valued** (the break body mutates data; the answer is a `cqrt_copy_<W>`-able
  basis value), **not** a phase. A phase answer ⇒ decline (Rule 7, §2.6).
- **(B4) Invertible, single-site, non-nested body.** The loop body (the forward
  pass) is composed only of cleanly-invertible tainted ops (value ops + the
  capture machinery) that `emitInverseChain` already adjoints; **exactly one**
  break site; **no** tainted control nested in the body beyond the break itself
  (reuse 7.3 L2); **no** tainted-index memory in the body (reuse 7.3 L3); `L` is
  **not** an inner loop of another tainted loop (nested-break is deferred, §2.7).
- **(B5) Otherwise a proven 7.3 rolled loop.** Single latch, classical induction,
  and the loop-carried rail is a recognized persistent in-place handle (Case-A
  style) whose only non-in-place consumer is the break capture.

Anything failing (B1)–(B5) is **not claimed** by `tryBreak` (Prime Directive),
falling to the matching loud decline (§2.10).

### 2.6 Phase-arm break declines — Rule 7 + degeneracy
A break whose escaping answer is a **phase** (e.g. a `cq_phi` accumulator measured
after the loop) cannot use the §2.2 copy-out: `cqrt_copy_<W>` is a CNOT, which
copies a basis label, not a phase, so step 4 + the reverse-play would **dephase**
the answer (the canonical method-B-on-a-phase-arm miscompile, Rule 7). Moreover a
break whose **condition** compares the phase rail as data is **degenerate**: `Rz`
(`cq_phi`) does not change the computational-basis value, so the break `fcmp` is
**iteration-invariant** — it fires at iteration 0 or never, expressing no real
loop-dependent early exit. **Permanent decline** with a dedicated message
(`cq loop lowering: early break preserves a phase answer` — mirror-exact, §2.10).
This is the honest scope floor: the natural, soundly-lowerable break is the
**data-mutating** (value-arm) loop.

### 2.7 Increment sequencing beyond single-break (what is near-term vs. genuinely deferred)
The v1 emission proves the mechanism on a **single** break site (Inc 1/2). The
follow-ons split by *why* they are not in the first cut — and the split matters,
because two of them are **near-term extensions of the same mechanism**, not deep
deferrals:

- **Multiple break sites in one loop — NEAR-TERM (Increment 3), not cascade-gated.**
  The O(1) `idx` is a **monotone latch**, and the sites execute in **program
  order**, so the **first** `fire_k = %brk_k ∧ (idx==0)` to go true captures and
  locks `idx`; every later site/iteration sees `idx≠0` and skips. This *is* C's
  "first `break` reached wins," handled by the single latch — **no per-site
  exit-priority cascade is needed** (the §4 cascade was the abandoned
  O(K)-per-iteration-register design's tool; the index latch subsumes it). The
  only deltas vs. single-break: the recognizer decomposes
  `%brk_1 ∨ … ∨ %brk_S ∨ %bound`, and `idx` encodes `(iteration, site)`
  (`i·S + k + 1`) so each `fire_k` stays in-iteration-uncomputable as
  `idx == encode(i,k)`. Same physics, same O(1) carried state. **Caveat:** sites
  reachable under *classical* body control only; a break gated by a *tainted*
  in-body diamond is the separate tainted-control-in-loop gap (7.3 L2).
- **Nested-loop break — DEFERRED, but gated on SUBSTRATE, not break-complexity.**
  The inner break **self-contains** (allocates `R/idx`, captures, reverse-plays,
  cleans to `|0⟩`, reusable each outer iteration), so the inner break composes
  fine. The real blocker is **upstream of 7.4**: 7.3's **nested-quantum-loop guard**
  (`markIfIterationLocal`, PRD-7.3 §2.5) currently declines any outer loop
  containing a quantum inner loop, because whole-loop reverse-play over a nested
  loop is an unproven interaction. Nested break therefore needs that guard lifted
  for the "provably self-contained inner loop" case — a **7.3-substrate core change
  carrying its own Rule-13 hazard (nested reverse-play)**, sequenced after
  single + multiple break and tracked with an explicit **blocked-on:
  nested-quantum-loop substrate** dependency.
- **`continue`** — a **different mechanism**, not a break variant: a tainted
  `continue` skips the rest of *this iteration's* body, i.e. **intra-iteration
  tainted control** (the body tail becomes controlled) — the
  tainted-control-in-loop-body capability 7.3 L2 declines. ROADMAP scopes 7.4 to
  `break`; deferred as its own capability.
- **Mixed break + early-`return`** in the same loop — composes the 7.2 return park
  cascade with the 7.4 capture (a two-mechanism interaction surface). Deferred, low
  priority.

### 2.8 The first-break index register `idx` (subsumes the done-flag)
`idx` is a coherent integer rail of the **loop-counter width** (`iN`,
`cqrt_alloc_iN`, i32/i64 — **no new symbol**); `idx == 0` ≡ *not yet fired*, and
on the first fire it holds `i+1` (the `+1` keeps iteration 0 distinct from "not
fired"). It subsumes a 1-bit done-flag (`done ≡ idx≠0`) **and** carries the *where*
the latch fired — the extra information that lets the per-iteration scratch be
uncomputed in-iteration (§2.2a). The `fire = %brk ∧ (idx==0)` conjunction and the
`idx==i+1` re-derivation lower to the existing `cqrt_toffoli` / `cqrt_x` /
`cqrt_cnot` surface (eq-against-a-classical-constant is a bounded `cqrt_x` /
compare-flag sequence; the negated control reuses `emitRoute`'s self-inverse
`cqrt_x` bracket, AbortParkEmit.cpp). The classical counter `i+1` is materialized
as a basis register via `cqrt_alloc_iN(i+1)` (a known value, freed after the
controlled write). Signedness/width of the captured value follow the rail's `<W>`
exactly as 7.3 (handles are always `i32`, Rule 15).

### 2.9 No measurement, full classical trip count (the rolled semantics)
`break` does **not** shorten the loop — the loop runs its full **classical** trip
count `n` (the rolled CFG is preserved); the early-exit is realized **virtually**
by `idx` freezing the first-break value into `R` and the post-capture iterations
running harmlessly (the COPY left the rail live, so it keeps churning; the churn is
reverse-played). This is the only coherent
reading of "stop iterating under quantum control without measurement" (Rule 5).
The trip count stays **dynamic-classical** (7.3 §2.1) — the backward reverse-play
loop runs the **same** runtime `n` times; no static-K is required.

### 2.10 Decline-diagnostic partition (Rule 12) — mirror char-for-char
Each decline ships a source-located `DiagnosticInfoUnsupported(DS_Error)` (`!dbg`
attached) with a mirror-exact negative fixture:

| shape | structural signature (SSA/CFG, pre-mutation) | disposition + message |
|---|---|---|
| value-arm break (the accept) | classical-bound ∨ single tainted `%brk`; reconverging; value-class merge phi; invertible single-site body | **accept** — index-gated copy-not-move capture + reverse-play (no diagnostic) |
| genuinely quantum-bounded (L1) | bare tainted exit `icmp`/`fcmp`, or fused exit with **both** operands tainted | **permanent decline** — `cq controlled lowering: loop under quantum control` (existing) |
| phase-arm break | classical-bound ∨ tainted `%brk`; exit merge phi is **phase**-class (incoming a `cq_phi` rail) | **permanent decline** — `cq loop lowering: early break preserves a phase answer` (new) |
| non-reconverging break | break edge and natural exit reach **distinct** blocks / no single merge phi | **decline → defer** — `cq loop lowering: early break does not reconverge` (new) |
| multiple break sites | >1 exiting block with a tainted decomposed `%brk` | **decline in Inc 1/2 → accept in Inc 3** (§2.7, near-term; index latch, no cascade) — interim `cq loop lowering: multiple early-break sites` |
| nested-loop break | `L` is an inner/outer of another tainted loop; break crosses loops | **decline → defer** (§2.7, blocked-on nested-quantum-loop substrate) — `cq loop lowering: early break across nested loops` (new) |
| non-invertible / unrecognized body | a body op not adjointed by `emitInverseChain`; or any tainted handle live across the backedge not in (B5) | **decline** — existing `kMsgLoopBackedge` / `kMsgClassicalPhi` residual net |
| tainted control / QRAM in body | tainted-condition `br`/`switch` (beyond the break) or tainted `load`/`store`/`gep` ∈ `L` | **decline** — existing 7.3 L2/L3 (`ControlDetect`/`kMsgQramLoop`) |

---

## 3. Deliverables

1. **Break recognition (`tryBreak` in `LoopLowering.cpp`)** — pure-analysis,
   before mutation: the §2.5 (B1)–(B5) accept predicate, including the **`-O1`
   `select`/`or` decomposition** that separates a value-arm break from a genuinely
   quantum-bounded loop (the L1 partition), and a `LoopBreakRegion` in
   `LoopPlan.h`. **No ABI.**
2. **Increment 1 — recognition + decline partition** (§2.5, §2.6, §2.10): flip the
   classical-bound-tainted-break shape from the L1 `loop under quantum control`
   decline into an affirmative accept candidate; add the new phase-arm /
   non-reconverging / multiple-site / nested decline diagnostics with mirror-exact
   negative fixtures; confirm the genuinely-quantum-bounded L1 decline still fires
   unchanged. Positive recognition fixture
   `lowering_loop_break_value.ll`. **No ABI.**
3. **Increment 2 — capture + whole-loop reverse-play emission** (§2.2, §2.3): the
   index-gated copy-not-move capture (`cqrt_copy_<W>_controlled(fire, rail, R)` +
   `idx` write + **in-iteration** scratch uncompute, §2.2 step 2), the loop-exit
   consolidation, the `cqrt_copy_<W>` copy-out + exit-phi RAUW, and the
   **backward-counted reverse-play companion loop** via `emitInverseChain`, then the
   `cqrt_free` of `R`/`idx`. Positive fixture + the **e2e golden** showing the trace:
   forward body ×n, capture, copy-out, reverse body ×n, balanced frees. **No ABI**
   (reuses `cqrt_copy_<W>_controlled`/`cqrt_toffoli`/`cqrt_copy_<W>`/`emitInverseChain`/`cqrt_free`). **This is
   the core uncompute-spine change** — clears independent adversarial Rule-13
   review before commit.
4. **Decline fixtures (Rule 12)** — one mirror-exact `RUN: not … | FileCheck` per
   §2.10 decline row: `lowering_reject_break_phase_answer.ll`,
   `lowering_reject_break_nonreconverging.ll`,
   `lowering_reject_break_multiple_sites.ll`,
   `lowering_reject_break_nested_loop.ll`, plus a regression-pin that a genuinely
   quantum-bounded loop still hits the existing L1 message
   (`lowering_reject_loop_quantum_bound.ll` unchanged).
5. **≥1 e2e golden smoke (Rule 16)** in `tests/e2e/` — `slice_loop_break.c`: a
   classically-bounded data-mutating loop with a tainted value-arm break, measured
   after the loop; `opt -verify` clean, linked
   (`libcq_templates.a` before `libcq_runtime.a`), golden trace diff clean.
6. **Increment 3 — multiple break sites (near-term, §2.7):** generalize the
   recognizer to `%brk_1 ∨ … ∨ %brk_S ∨ %bound` and the emission to S capture
   points sharing one `R`/`idx` (with `idx` encoding `(iteration, site)`); the
   index latch gives first-in-program-order-wins with **no** cascade. Positive
   fixture `lowering_loop_break_multi_site.ll` + e2e golden. (No ABI.)
7. **Filed follow-ons (genuinely deferred, §2.7):** nested-loop break (blocked-on
   the nested-quantum-loop substrate, a 7.3 extension + its own Rule-13 nested
   reverse-play hazard), `continue` (a separate intra-iteration tainted-control
   capability), mixed break+return (7.2×7.4 interaction) — each a `bd` issue.

---

## 4. Done criteria

- A classically-bounded, data-mutating loop with a **single tainted value-arm
  break**, measured after the loop, lowers **rolled**: the loop CFG is preserved,
  the body lowers in place, the break is realized by an index-gated
  `cqrt_copy_<W>_controlled` (copy-not-move) capture + a `cqrt_copy_<W>` copy-out +
  a **whole-loop reverse-play** that returns `R`/`idx`/rail to `|0⟩`, with **O(1)**
  carried ancilla (`rail + R + idx`, per-iteration scratch uncomputed in-iteration),
  **zero** measurements inserted — `opt -verify` clean, e2e golden trace diff clean.
- A **runtime-classical** bound lowers identically to a constant bound — **no**
  compile-time trip count required (the reverse-play loop runs the same dynamic
  `n`).
- Every off-pattern shape declines **loudly**, source-located, with its own
  mirror-exact negative fixture (§2.10): phase-arm break (permanent), genuinely
  quantum-bounded (permanent, existing L1), non-reconverging, multiple-site,
  nested-loop, non-invertible body, tainted-control/QRAM in body.
- **No new frozen runtime symbol** is minted (verify against the runtime header).
- **Rule-13 clearance:** the break recognizer (the §2.5 predicate + the `select`
  decomposition), and **especially** the capture + **whole-loop reverse-play**
  schedule (§2.2/§2.3) are cleared by **independent adversarial review** with
  analytic/trace reasoning + reading the actual lowered IR — a green suite alone
  does not clear them (Rule 13; core uncompute-spine change). The review
  explicitly checks: the `idx==0` gate makes the capture idempotent (no re-capture,
  no double-capture) and every per-iteration scratch register is `|0⟩` at the
  backedge (no O(K) accumulation, copy-not-move keeps the rail intact for the
  in-iteration `%brk` uncompute); the reverse-play replays the body **exactly `n`
  times** with the matching trip count so `R`/`idx`/rail end provably `|0⟩`; `out`
  ends disentangled from the which-iteration ancilla (no dangling entangled `idx`);
  a phase answer is never copied out (Rule 7); and a fused exit with **two** tainted
  operands is never mis-decomposed as a value-arm break (never mis-read a
  quantum-bounded loop as classical, Risk 4).

---

## 5. Out of scope (declines, or other phases)

- **Phase-arm break** — permanent decline (§2.6, Rule 7); the data-comparison
  phase break is degenerate.
- **Genuinely quantum-/measurement-bounded `while`** — permanent decline (existing
  7.3 L1, §2.6); the amplitude-amplification case stays past the freeze (ROADMAP
  "Beyond the freeze").
- **Multiple break sites** — declined in Inc 1/2, **accepted in Increment 3**
  (§2.7, near-term; the index latch subsumes any cascade), not a deferral.
- **Nested-loop break / `continue` / mixed break+return** — declined now,
  **deferred follow-ons** (§2.7; nested break blocked-on the nested-quantum-loop
  substrate, `continue` a separate intra-iteration-control capability), not
  permanent rejections.
- **QRAM / tainted-index memory inside the break body** — reuse the existing 7.3
  L3 decline; QRAM-in-loop is `iw81.13`.
- **The O(K) per-iteration-register + §4-cascade materialization** — considered and
  declined (owner 2026-06-25, §2.1); it gives up the dynamic bound.
- Any change to the trace-only runtime posture or to classical (untainted) `break`
  (compiled exactly as C does).

---

## 6. Risks (the verify-clean ones first)

1. **Reverse-play replays the body the wrong number of times / from the wrong
   state** — if the backward companion loop's trip count or per-iteration adjoint
   does not exactly mirror the forward pass, `R`/`idx`/rail are left dirty (a hidden
   measurement on `cqrt_free`, Rule 6) or `out` stays entangled with `idx` (dephases
   under interference, Rule 5) — verify-clean and trace-plausible. **The central
   Rule-13 hazard.** Mitigation: the backward loop is driven by the **same**
   induction bound as the forward loop; the adjoint is `emitInverseChain` of the
   captured forward body in reverse program order; a probe diffing the trace's
   forward/backward op counts and asserting balanced `R`/`idx` frees.
2. **Per-iteration scratch not uncomputed in-iteration → O(K) accumulation / dirty
   carry** (the owner's 2026-06-25 question) — if the capture **moves** (`cqrt_cswap`)
   instead of **copies**, the fired-branch rail is zeroed and `%brk` can no longer
   be recomputed → `%brk`/`fire` accumulate across iterations (O(K), and in a rolled
   single-register form they corrupt). Or if `fire` is not cleared via `idx==i+1`,
   the reused scratch register carries garbage into the next iteration's
   `cqrt_toffoli`. Either is a verify-clean wrong unitary. Mitigation: capture is
   `cqrt_copy_<W>_controlled` (rail intact, §2.2 step 2); `fire` and the `idx==0`
   eq-flag are uncomputed in-iteration from the **current** `idx` + classical `i`;
   `%brk` is uncomputed by recomputing `cond(rail)`; a probe asserting **every**
   per-iteration scratch register is `|0⟩` at the backedge (trace shows balanced
   compute/uncompute within each iteration) and that the carried set is exactly
   `{rail, R, idx}`.
3. **First-fire gate not idempotent → re-capture or double-capture** — if the
   capture is gated on `%brk` alone (not `%brk ∧ (idx==0)`), a later iteration whose
   `cond(rail)` is again true overwrites/XORs `R` (corruption). Mitigation: the
   `(idx==0)` control is mandatory (§2.2); `idx` advances to `i+1` only on the first
   fire; an adversarial probe with a break condition that re-fires on later
   iterations.
4. **A fused exit with two tainted operands mis-decomposed as a value-arm break**
   — accepting `select(%brk, %x, %bound)` where `%bound` is **also** tainted (a
   real data-mux or a quantum-bounded loop) would emit a runtime branch on a qubit
   misread as classical. Mitigation: (B1) requires the non-`%brk` operand to be
   **classical** (`!taint.Tainted.count`); the canonical real `-O1`
   quantum-bounded shape (the §1.1 fused select with a tainted bound) is a probe
   ensuring the taint is still seen → L1 decline.
5. **A phase answer copied out (Rule 7 dephase)** — if (B3) keys on a value width
   being non-empty rather than on the answer being genuinely basis-valued, a phase
   rail (which has a valid `<W>`) is mis-accepted and CNOT-copied → dephase.
   Mitigation: (B3) classifies the exit merge phi's incoming **lineage**
   (a `cq_phi`/Rz rail is phase-class) exactly as the 7.2 `retLineageCarriesPhase`
   walk (`ControlDetect.cpp:203-223`); probe a phase accumulator with a (degenerate)
   data break.
6. **The exit merge phi left dangling / RAUW'd before `out` exists** — if the
   copy-out RAUW races the recognizer, the merge phi survives into
   `declineClassicalMuxes` (`kMsgClassicalPhi`, loud but a blocker) or points at a
   freed `R`. Mitigation: the RAUW of the merge phi → `out` is ordered after the
   copy-out and before `declineClassicalMuxes` (§2.4); `R`/`idx` are freed only after
   reverse-play.
7. **Reverse-play companion loop perturbs LoopInfo / the forward recognizer**
   — emitting a second loop after the forward loop is new CFG construction; a
   later re-built `LoopInfo` (e.g. a subsequent loop's recognizer) must not
   mis-claim the backward loop. Mitigation: the backward loop carries no tainted
   *source* (only adjoint replays of already-lowered ops); 7.4 marks its blocks so
   a re-scan skips them (mirror `taint.IterationLocalBlocks`).

---

## 7. Increments (each red → green → clear, Rule 12/13)

1. **Break recognition + decline partition** — `tryBreak` (the §2.5 predicate) +
   the `-O1` `select`/`or` decomposition that separates a value-arm break from the
   L1 quantum-bounded decline; the new phase-arm / non-reconverging / multiple-site
   / nested decline diagnostics + mirror-exact negatives; confirm the existing L1
   quantum-bounded decline unchanged. (No ABI; pure analysis + diagnostics.)
2. **Capture + whole-loop reverse-play emission** — the index-gated copy-not-move
   capture (+ in-iteration scratch uncompute), the exit consolidation, the
   `cqrt_copy_<W>` copy-out + exit-phi RAUW, the **backward-counted reverse-play
   companion loop** (`emitInverseChain`), the `cqrt_free` of `R`/`idx`; the positive
   lit fixture + the e2e golden. (No ABI; reuses the `_unc`/controlled-copy spine.)
   **This is the core control/uncompute change** — it clears independent adversarial
   Rule-13 review before commit (Risks 1–5).
3. **Multiple break sites (near-term, §2.7)** — generalize the §2.5 recognizer to
   `%brk_1 ∨ … ∨ %brk_S ∨ %bound` and the emission to S capture points sharing one
   `R`/`idx` (`idx` encoding `(iteration, site)`); first-in-program-order-wins is
   the index latch, **no** cascade. Flip the `multiple early-break sites` interim
   decline → accept; the multi-site positive fixture + e2e golden. (No ABI.) Builds
   directly on Inc 2; the same Rule-13 review extends to cover the per-site latch
   encoding and in-iteration uncompute.

> Increments 1–3 may interleave at the fixture level, but **the break recognizer
> (incl. the `select` decomposition) and the capture + whole-loop reverse-play must
> each clear independent adversarial Rule-13 review before commit** — 7.4 adds a new
> uncompute schedule over the spine where every silent miscompile has lived, and the
> verify-clean hazards (Risks 1–5) must be confirmed discharged, not assumed. The
> genuinely-deferred follow-ons (§2.7, Deliverable 7 — nested-loop break,
> `continue`, mixed break+return) are **not** part of this phase's done-criteria.
