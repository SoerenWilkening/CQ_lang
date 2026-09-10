# Rule-13 adversarial review, ROUND 1 — bd `test_C_libtooling-r9e5` sub-increment 1b-B.1
## (the 4.4 DATA select on a bare `_Bool` / rail-root condition)

Independent reviewer, session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-10.
Tree under review: branch `3qlq-inc1b-b-rail-select` (off `main` 87d0699), the B.1 implementation
PLUS the orchestrator's F-B1-1 fix. I did not write this code and did not rebuild or edit anything
under `ir-pass/`, `tests/`, `tools/` or `build/`.

# VERDICT — **CLEAR-WITH-ITEMS**

**No confirmed silent miscompile found.** 108 adversarial programs (65 plain C at `-O1`, 43 hand-IR
modules) run on BOTH binaries; every ACCEPT on the branch argued from the state vector; **0
accept→decline regressions**, and an independent whole-corpus differential over the 1737 pre-existing
lit fixtures reads **0 RCDIFF · 0 DIAGDIFF · 0 OUTDIFF**.

Four items, none a blocker:

| id | grade | one line |
|---|---|---|
| **F-B1R1-1** | OVER-ACCEPT-ARGUED (PRE-EXISTING, shared with Inc 1b; plain-C reachable) | rung (ii)'s measure set is the rail's **SSA VALUE**, rung (iii)'s gate set is the rail's **WIRE** — a `cq_measure` of the chained PARENT name is invisible to the fence the increment just parameterised |
| **F-B1R1-2** | ITEM (forward-looking; unreachable today, measured) | the emitter's `RailLeaves` backstop covered **three** callers and its replacement is **dead code**; the second caller (`emitValueRegion`) bypasses the whole rail ladder and is safe only by a precondition in another file — which B.2 exists to widen |
| **F-B1R1-3** | DOC | the F-1b2-4 structural ground for dropping the positional prong is inherited from the branch to the SELECT, where the read is a mid-block gate stream and not a terminator; it holds (measured) but has no select-side fixture |
| **F-B1R1-4** | DOC | `IMPL_B1.md`'s fixture/ctest table is stale by the orchestrator's own two F-B1-1 fixtures (**1759** `.ll` on disk, not 1757) |

---

## 0. What I ran, and only that (Rule 19)

* **Probe corpus** — `review_b1_r1_probes/` in this directory: `c/` 65 plain-C programs, `ll/` 43
  hand-IR modules, `run_corpus.sh [PRE|POST]`, and the two committed verdict tables
  `VERDICTS_PRE.txt` / `VERDICTS_POST.txt`. Each probe: `clang -O1` (for `.c`) → `cq-opt
  -passes=cq-lowering` → `tools/free_pairing_check.py` (stage 2b, STRICT) → link → run.
  `POST` = `build/ir-pass/{cq-opt,libCQPass.so}`; `PRE` = the saved pre-B.1 pair.
  Verdict deltas, measured from those two files:
  * **63 movers, every one DECLINE → ACCEPT** (the increment's capability),
  * **13 accept on BOTH**, and their lowered modules are **byte-identical** below the module header
    (`diff <(tail -n +4 PRE) <(tail -n +4 POST)` empty for all 13),
  * **32 decline on BOTH**,
  * **0 accept → decline**.
* **Whole-corpus differential, run by me, not inherited** — `cq-opt` on every `ir-pass/test/*.ll`
  EXCEPT the 22 files of the new `control_swap_{,reject_}select_rail_*` family, on both binaries,
  comparing return code, stdout and stderr: **`SCANNED=1737 RCDIFF=0 DIAGDIFF=0 OUTDIFF=0`**.
  This is the strongest single statement available about the two refactors that touch shared code
  (the `railMeasuredBeforeReadPoint` de-anonymisation + read-point parameter, and the
  `CmpProv`/`RailProv` split): every compare-conditioned select, every kickback and every nest in
  the corpus produces a byte-identical module and a byte-identical diagnostic.
* **`lit ir-pass/test --filter 'select_rail'` from `build/`** → 23 discovered, **23 PASS**, 1.28 s
  (the 22 new family files + the pre-existing `control_swap_accept_select_rail_alias_cond.ll`;
  22 + 1737 = 1759 = `ls ir-pass/test/*.ll | wc -l`). Run it from `build/`; from the source root all
  23 "fail" on a missing `%cq-opt` substitution, which reads exactly like a lowering regression.
* **Red-green spot check of the four measure-rung declines on the PRE binary** — all four
  (`..._measured_before`, `..._measured_sidepath`, `..._inloop_measure_after`,
  `..._inloop_measure_after_constarm`) decline there with `bare i1 register condition`, i.e. NOT the
  string their `RUN: not … FileCheck` mirrors: genuine red-green pins, not decorations.
* **A register-gate invariant scan over all 58 accepted lowered modules** (`checkinv.py`, reproduced
  in §5): for every rail carrying a `cqrt_ry_*`, **zero** `cqrt_x`, **zero** `cqrt_free`, **zero**
  `cqrt_cswap`, **zero** `cqrt_cnot` with the rail in the TARGET slot, **zero** `_unc` naming it as
  anything but a read operand, and the count of `cqrt_cnot` control uses is **even** in every module.
* I did **not** run the full `ctest` (one was already running in `build/`) and make no claim about it.

---

## 1. The analytic argument — I attacked it and it holds

The emitter's claim (BRIEF §1(a), IMPL §2) is: mint `bf = |0⟩`, `cnot(b, bf)`, run the shipped §5a
merge on `bf`, then `cnot(b, bf); free(bf)`.

State-vector check, done independently. Write the register's state as `Σ_x α_x |x⟩_b` (⊗ whatever it
is entangled with; the argument is per basis branch of `b`, which is all a control needs).

1. `bf` is minted at `|0⟩`: `Σ_x α_x |x⟩_b |0⟩_bf`.
2. `cnot(b, bf)` — `b` in the CONTROL slot: `Σ_x α_x |x⟩_b |x⟩_bf`. Nothing about `b` moved (a CNOT
   control is diagonal on its control wire); `bf` is a basis-label copy of a source that **stays
   live**, so Rule 8 — which forbids *freeing* a superposed source by copy+uncompute — has no
   subject.
3. `copy_c(bf, T, out)` with `out = |0⟩` writes `T` iff `x = 1`; `x(bf); copy_c(bf, F, out); x(bf)`
   writes `F` iff `x = 0`. Exactly one write per basis branch ⇒ `out = b ? T : F`. The `cqrt_x`
   brackets act on `bf`, an ancilla this emitter owns; the copies write `out`. `b` is untouched.
4. `cnot(b, bf)` returns `bf` to `x ⊕ x = 0` **on every basis branch**, so `cqrt_free(bf)` is a
   proven-`|0⟩` free (Rule 6), not a hidden measurement.

Net `|b⟩ ⊗ |b ? T : F⟩` — the same unitary the compare stream realizes with `c(x) = b`. I confirmed
the *emitted* claim two ways: (i) the invariant scan above (no non-diagonal gate ever lands on a user
register in any of the 58 accepted modules, and every `cnot` control use pairs); (ii) the int/compare
twin of the owner's own program, `c/r59_int_compare_twin_of_baseline.c`, which accepts identically on
BOTH binaries at **14** trace lines against the bool form's **15** — the difference being exactly
`alloc_i1(0)->h1 ; cnot(h0,h1) … cnot(h0,h1)` against `icmp_eq_i32_hl(h0,1)->h1 … _unc`, i.e. the
reduction `IMPL_B1.md` §5 states, verified rather than asserted.

**The composition cases I could not break** (all ACCEPT on the branch, all argued):

* a relative phase already on the register (`ll/w19.ll` — kickback then select): a diagonal factor on
  the control commutes with a label-controlled permutation, so the copy still reads the same basis
  label and the phase rides through. Emitted `rz_i1(h0,.9)` then the stream — source order.
* the ARM aliasing the condition register (`ll/h01.ll`, `select i1 %b, i1 %b, i1 %c`): the emitted
  `copy_i1_controlled(bf, h_b, out)` is a Toffoli over **two distinct wires** (`bf` is the ancilla),
  perfectly correlated, giving `out = x ⊕ (¬x ∧ c)` = `b ? 1 : c`. This is bd big5 CASE A, not CASE B
  — nothing writes a rail that is also one of its own inputs.
* the register also read as DATA (`ll/h19.ll`, `zext b` beside the select): the `zext` and its `_unc`
  both read `h0`'s unchanged label, and the discharge happens.
* non-root rail leaves in `and`/`or`/`xor` trees (`c/r18`, `c/r19`, `c/r37`, `ll/w08.ll`): the root is
  a node ancilla and the rails are read-only controls of its `cnot`/`toffoli`; no copy flag is minted
  and the teardown is the exact reverse. `or` emits `cnot,cnot,toffoli` forward and
  `toffoli,cnot,cnot` reverse — checked by eye against `emitCondNode`.
* the DT-prong accepts (§2 below), two selects on one rail (`c/r07`, `ll/h07.ll`, `ll/w22.ll`),
  nested selects (`c/r65`), a select whose arm is another select's `%out` (`ll/h08.ll`), fp data
  (`c/r15`), i1/i16/i64 widths (`c/r38`, `ll/h17.ll`), a select in the join block of a flattened
  phase diamond (`ll/w15.ll`), a rolled K=3 and K=32 loop (`c/r62`: 33 `alloc_i1` / **32** `free`,
  64 `cnot`, 64 `cqrt_x` — perfect per-activation pairing, nothing accumulating across the back edge).

---

## 2. The DT prong (the accept-widening) — attacked from six directions, sound

`RailProv` gets `railCondWireDisposition`'s ladder: position-free clean ⇒ accept; else no `DT` ⇒
decline; else re-ask with `EmitPoint = Sel`. (`DT` is never null at this call site —
`ControlDetect.cpp:868` engages the lazy `std::optional<DominatorTree>` before calling — so the
`!DT` disjunct is unreachable; harmless.)

The transfer argument I was asked to attack is "nothing of the region survives on `b`". It is
**almost** false in an interesting way and the conclusion still holds: what *does* survive on `b` is
its **entanglement with `%out`**. But that is precisely what the source asked for — "compute `out`
from `b`, then rotate `b`" — so a later `Ry` on `b` yields `(Ry_b ⊗ I_out)·CopyMerge|ψ⟩`, which is
the source's own composition. The region leaves no *flag*, no *record*, and no *obligation* on `b`;
only a correlation the program created deliberately.

Measured, on both binaries:

| probe | shape | verdict | why it is right |
|---|---|---|---|
| `c/r05`, `ll/w21.ll` | S† after the select / chained theta immediately before it | ACCEPT | emitted order == source order |
| `ll/w05.ll` | select inside a loop body, theta on the rail AFTER the loop | ACCEPT | `dominates(Sel,θ)` ✓, `reachable(θ→Sel)` ✗ ⇒ 3 streams then one `ry` |
| `ll/w06.ll` | select first, theta on the rail inside a later loop | ACCEPT | one stream then 3 `ry` |
| `c/r27` | select in the preheader **as written**, theta in the body | DECLINE (both) | `-O1` hoists — over-decline, safe |
| `c/r06`, `ll/w13.ll` | theta BETWEEN the def and the select (stale name) | DECLINE (both) | `dominates(Sel,θ)` fails |
| `c/r03` | SIBLING theta on the same physical rail through a TEMPLATE parent (the F-1b-1 class) | DECLINE (both) | the round-1 1b widening of `findNonDiagonalWireGate`'s ancestry sees it |
| `c/r29`, `c/r30` | the theta on a classically-guarded side path | DECLINE (both) | dominance fails — over-decline, safe |
| `ll/h13.ll` | mixed tree, theta on the **COMPARE's** register after the select | DECLINE | the compare seeds keep the position-free walk verbatim — the deliberate asymmetry |
| `ll/w09.ll` / `ll/w11.ll` | a DISCHARGING borrow chain (`zext b`) + a post-select theta, and its compare twin | ACCEPT both | the `zext_unc(h5,h0)` lands **before** `ry(h0,.3)`; the twin is byte-identical in structure and accepts on the PRE binary, so this is a pre-existing spine mechanism working, not a new one |

**The 8h7d.5 question, asked of this widening — "what OTHER set was computed over the same closure
and NOT widened?"** Three answers, and the third is F-B1R1-1:

1. the **compare** seeds — deliberately position-free (over-decline; `ll/h13.ll` pins it);
2. the **same-block positional prong (c)** — stays compare-only, on the F-1b2-4 structural ground
   (F-B1R1-3 below; measured to hold at the select);
3. the **measure** set — `Rail->users()`, the rail's SSA VALUE, while the gate set is the rail's
   WIRE closure. **That one is a real hole** (F-B1R1-1).

---

## 3. Findings

### F-B1R1-1 — OVER-ACCEPT-ARGUED (PRE-EXISTING, shared with Inc 1b, plain-C reachable)
### rung (ii) asks about an SSA NAME where rung (iii) asks about a WIRE

`railMeasuredBeforeReadPoint` (`ArmClassify.cpp:1813-1864`) iterates `Rail->users()` and keeps the
`cq_measure` ones. A rail's **physical wire** can carry other SSA names — `lowerRotations` RAUWs a
whole chained-`cq_theta` chain onto ONE handle — and a `cq_measure` of the **parent** name collapses
that same register while being no user of `Rail` at all. Rung (iii) already reasons about the wire:
`findNonDiagonalWireGate` closes each seed BACKWARD through chained-theta arg-0 hops (the F-1b-1
widening). So the two rungs of one ladder are computed over two different closures.

**Program** (`c/r02_measure_parent_chained.c`, plain C, `clang -O1`):

```c
bool b0 = 0;  b0 = cq_theta(b0, 0.5);
bool b  = cq_theta(b0, 0.3);        /* b and b0 are ONE wire */
int  m  = cq_measure(b0);           /* collapses that wire */
int  a  = b ? 2 : 5;                /* the merge controls on it */
```

* **PRE** (`main` 87d0699): `rc=1`, `cq controlled lowering: bare i1 register condition under quantum control`.
* **POST** (branch): `rc=0`, stage 2b `1 verified, 0 violation(s), 0 unproven`, 16 trace lines:

```
cqrt_alloc_i1(0) -> h0 ; cqrt_ry_i1(h0, 0.5) ; cqrt_ry_i1(h0, 0.3)
cqrt_measure_i1(h0) -> 0        <-- the register is COLLAPSED here
cqrt_alloc_i1(0) -> h1 ; cqrt_cnot(h0, h1)   <-- the merge's control read
… the §5a stream, cnot strip, free …
```

Hand-IR minimal form without the ordering question: `ll/h14.ll`. A second spelling, `c/r22`, puts the
measure before the chained rotation and gets `measure_i1(h0)` then `ry_i1(h0, 0.3)` — a post-measure
gate — with the select riding it.

**Why I grade this OVER-ACCEPT-ARGUED and not CONFIRMED-MISCOMPILE.** The emitted gate ORDER matches
the source order exactly (the measurement really does precede the select in the C), so the circuit is
faithful to what was written; what is defective is the FENCE that this project uses to refuse the
whole class ("`condition measured before the control route`", PRD §13.3 item 2 / Rule 6's
loud-reject class). And the hole is **not this increment's**: the kickback twin
`c/r21_kickback_measure_parent.c` produces the IDENTICAL 5-line trace on **both** binaries
(`ry(.5); ry(.3); measure_i1(h0); rz_i1(h0,.9)`), and `c/r41`/`c/r42` show the underlying
post-measure rotation accepted identically on both with no control in the program at all. B.1
inherits the helper and therefore the hole, and **adds customers to it** — 3 of my 63 movers
(`r02`, `r22`, `h14`) are in this class.

**Recommendation (item, not blocker).** Either (a) widen the measure set to the same closure the
wire walk already computes — the rail's backward chained-theta ancestry plus its forward rail — in
BOTH callers at once (this is exactly the F-1/F-3 lesson: widen the sets together), or (b) record
the asymmetry in writing at the helper with a retirement trigger, and cross-reference bd `3d8q`
(the `cq_theta`/`cq_measure` stale-reader class, already filed) and bd `r903`. Doing nothing and
leaving the header's "the mirror of `condDataUseDisposition`'s `MeasuredEarly`" unqualified is the
option I would refuse: that sentence reads as complete and is not.

### F-B1R1-2 — ITEM (forward-looking; unreachable today, measured)
### the emitter's `RailLeaves` backstop covered THREE callers; its replacement is dead code

`emitSelectRegion` had, before B.1, a pre-emission guard:

```cpp
if (!Tree.RailLeaves.empty()) { diagnoseUnderControl(Sel, kBareRailCondReason); return; }
```

That guard was **caller-independent** and `emitSelectRegion` has **three** callers
(`grep -rn 'emitSelectRegion(' ir-pass/src`): the plan dispatch `SwapRouteEmit.cpp:2362`,
**`SwapRouteEmit::emitValueRegion` at `SwapRouteEmit.cpp:593`** (which builds its OWN
`ControlRegion S; S.Kind = SelectRegion;` at `:590` and calls the emitter directly, so
`classifySelectRegion` — and therefore the entire rail ladder: rung (ii), the DT prong, gates 4/5/6
— **never runs**), and the header declaration.

Its replacement is `if (Net.RootIsRail) { diagnoseUnderControl(Sel, "control flow"); return; }`, and
that guard **can never fire**. Derived from the source, not guessed: `SelectMergeEmit` passes
`CopyRailRoot=true`; in `emitCondNetwork`, `CopyRoot = CopyRailRoot && isCondRailLeaf(Root)`; if
`CopyRoot` the tail sets `Out.RootIsRail = false`, and if not, `Out.RootIsRail = isCondRailLeaf(Root)`
is false by the same test. So `Net.RootIsRail` is unconditionally false at
`SelectMergeEmit.cpp:220`. No fixture can redden it, and its comment ("Nothing of this emitter's has
been emitted yet — for a bare rail root the copy IS the network's only emission") is true only for
the bare-rail-root case it can never see; for a tree with nodes the leaf mints and node ancillas
would already be on the floor.

**Today this is safe, and I measured it rather than assuming it.** `classifyArms`
(`ArmClassify.cpp:2155-2165`) requires `isa<CmpInst>(Region.Condition)` before anything else, so no
rail can reach `emitValueRegion`:

| probe | shape | PRE | POST |
|---|---|---|---|
| `ll/v01.ll` | value arm under a COMPOUND rail condition (`xor i1 %b, %c`) | `control flow` | `control flow` |
| `ll/v02.ll` | value arm under a BARE rail condition | `bare i1 register condition` | `bare i1 register condition` |
| `ll/v03.ll` | all-constant data mux under a bare rail branch | `bare i1 register condition` | `bare i1 register condition` |
| `c/r53`,`c/r54` | the plain-C spellings | identical | identical |

**Why it is an item anyway.** B.2 (this same bd) is *defined* as the increment that widens
`classifyArms` to admit a rail condition. The moment it does, `emitValueRegion` hands
`emitSelectRegion` a rail-root select with `CopyRailRoot=true` and it will **lower**, with rung (ii)
and the DT prong unasked — a decline silently becoming a lowering because a guard was deleted in a
different increment. That is this project's own recorded failure shape (a last-line-of-defence guard
removed, the remaining protection being a precondition in another file, nobody writing the
dependency down). Ask for one of: an emitter-level assertion that the region came from
`classifySelectRegion`, a re-ask of the rail ladder inside `emitValueRegion`'s hand-off, or — at
minimum — the dependency stated at `SwapRouteEmit.cpp:590` and carried into B.2's brief as a
precondition.

### F-B1R1-3 — DOC: the F-1b2-4 structural ground is inherited, holds, and is unpinned at the select

Inc 1b round 2 dropped the compare path's same-block positional prong (c) for RAIL seeds on a
**structural** ground, written at `railCondWireDisposition`: *"a condition rail is always read later
by its own branch in `R.Pred`, so M-C's G6 refuses the in-place conversion on it — the `xor` lowers
OUT of place onto a fresh rail and cannot alias"*, pinned by
`control_phase_kickback_rail_inplace_xor_bridge.ll`. B.1 copies the decision to the select
(`SelectClassify.cpp`: "the same-block positional prong stays COMPARE-only"), where the later read
is **not a branch** but the two `cqrt_cnot` the emitter inserts mid-block.

**Measured: the ground still holds.** `ll/x01.ll` — `%x = xor i1 %b, true; %c = θ(%x,.9); select i1
%b, …` — emits `cq_template_xor_i1_hl(h0, 1) -> h1` then `ry_i1(h1, .9)`: **out of place**, so the
`ry` moves `h1` and the select's `cnot`s read `h0` unchanged. `ll/x02.ll` (bridge AFTER the select)
correctly goes in place (`cqrt_xorc_i1(h0,1)` after the free). `c/r23`/`c/r24` are the plain-C pair.
`ll/x03.ll` is the kickback spelling, identical on both binaries.

The item is a *documentation* one and it is the same species as the sentence F-1b-1 retired: the
shipped ground names only the branch, so a reader checking it at the select finds a claim that does
not literally apply. Restate it as "the region's own emitted stream is always a later reader of the
rail — the branch's kickback gate for 1b, the two `cqrt_cnot` for 1b-B.1" and give the select its own
`..._rail_inplace_xor_bridge.ll` accept, so the shared retirement trigger ("if M-C's G6 ever admits
an in-place op on a rail with a later read, the prong must return") reddens on both paths and not one.

### F-B1R1-4 — DOC: `IMPL_B1.md`'s counts are stale by the fix that followed it

Measured on this tree: `ls ir-pass/test/*.ll | wc -l` = **1759**, not the **1757** the IMPL §4 table
records; `ls ir-pass/test/*select_rail*.ll | wc -l` = **23**, not 20. The +2 are the orchestrator's
F-B1-1 fixtures (`control_swap_reject_select_rail_inloop_measure_after{,_constarm}.ll`), added after
the IMPL was written. The ctest/e2e figures in that table are correspondingly the pre-fix ones. Not
a defect — but the whole point of Rule 19's "report only what you ran" is that a number in a record
is a measurement with a date, and this one has neither.

---

## 4. Over-declines found (all safe; none needs action)

* `c/r08` / `c/r09` — a select and a kickback on ONE rail, written in plain C: `-O1` sinks the value
  into the phase diamond and hands the pass one MIXED region ⇒ `bare i1 register condition`. The
  capability exists (`ll/w04.ll`, `ll/w15.ll`, `ll/w19.ll` all ACCEPT in hand IR), and the shipped
  slice `slice_control_select_bool_two_regions.c` already documents the `cq_measure(a)` that is
  needed to keep the two regions apart. Correctly scoped to B.2.
* `c/r26` — a cross-block rail from C becomes a phi ⇒ `control flow`; the hand-IR cross-block form
  `ll/h05.ll` accepts, so the fixture's claim is about the phi and not the block.
* `c/r39`, `ll/w17.ll` — a select inside a tainted ARM block ⇒ `control flow`.
* `ll/w14.ll` — `zext b` as an arm together with a post-select theta ⇒ `control flow` (gate 5/6).
* `c/r27` — the LICM-hoisted select with a body theta ⇒ `condition predates a non-diagonal gate`,
  identical on both binaries.
* `c/r31` — the classically-guarded side-path measure declines on REACHABILITY even when the guard is
  never taken. Inherited verbatim from Inc 1b (OQ-1b-R2-4) and already recorded as OQ-B1-2.
* `c/r45` / `c/r46` — an **`i1` quantum ARGUMENT** at the specialization boundary declines with
  `cq specialization: floating-point quantum argument or return has no reversible copy`, which is a
  **mis-branded** string for an `i1`. Identical on both binaries ⇒ PRE-EXISTING, not this
  increment's; worth a one-line bd note. (`c/r55`/`c/r56` show a callee that CONTAINS a `cq_*`
  declines earlier, so `lowerCloneSelect`'s deliberate rail-tree `continue` at
  `Specialization.cpp:288` is unreachable from C today and its "buildClone backstop" claim is
  untested by any probe I could write.)
* `c/r32` / `c/r44` — a `cq_invert` bracket around a select is **ignored by the pass on both
  binaries** (the `__cq_invert_{begin,end}` markers survive to the link and the link fails). Phase-8
  work, pre-existing, and I note it only because the brief asked me to check `cq_invert`: there is no
  EmitInverse interaction to review because there is no consumer.

## 5. Leaks (all Rule-6 safe, none new in kind)

Per accepted select region: `%out` and both materialized sources are left allocated (3 i32 rails),
exactly as the compare path leaves them; the copy ancilla is the region's ONE free. When the register
itself is dead after the select (`c/r10`, `c/r48`, `c/r49`, `ll/h06.ll`) it is **left allocated** —
its only remaining users are the two `cqrt_cnot`, which `ChainWalk::isInPlaceGateOn` does not
recognize, so the DAG is not closed, no `_unc` is emitted and `FreePoint` places no free. That is the
right answer (the register is entangled with `%out`) and it is what `..._rail_dead_register.ll`
already pins. OQ-B1-3's worry that a chain BORROWING the register would now always leak is **too
pessimistic**: `ll/h19.ll` and `ll/w09.ll` show the borrow chain's `zext_unc` + `free` being emitted
normally, because `Uncomputation::preservesBorrowedParent` refusing `cqrt_cnot` only means the caller
falls through to the two-disjunct interval scan, which admits it. Rolled-loop accounting at K=32
(`c/r62`): 33 `cqrt_alloc_i1` / **32** `cqrt_free` / 64 `cqrt_cnot` / 64 `cqrt_x` / 96
`cqrt_alloc_i32` — one mint-and-free per activation, nothing accumulating across the back edge, and
the same 3-rail-per-activation leak the compare path has.

The invariant scan (`checkinv.py`, over all 58 accepted lowered modules) is reproduced here because
it is the mechanical form of the increment's central promise:

```python
# for every %r that is arg0 of a `cqrt_ry_*`:  no cqrt_x(%r), no cqrt_free(%r),
# no cqrt_cswap naming %r, no cqrt_cnot with %r in the TARGET slot,
# no _unc naming %r as anything but a read operand, and #cnot-control-uses(%r) is EVEN.
# RESULT: 58 modules, 0 violations.
```

## 6. Areas I probed and found nothing in

Round 2 (`repropagateControlMerges`): a select's condition cannot *become* a rail at round 2 (a rail
is a `cq_theta_i1` result, tainted from round 1), and every arm-taint-growth shape I could build
(`c/r51`–`c/r54`, 6.5 classical-call arm; `ll/h08.ll`, `ll/w18.ll`, nested selects) either declines
identically on both binaries or is emitted in SSA order, which forces the arm's producing region to
be lowered first — `materializeCopySource` therefore never sees a value that later RAUWs to a handle.
The RAUW-ordering hazard (the stream is created with the `i1` `%b` in an `i32` slot and relies on
`lowerRotations`): every path where the theta is *not* lowered is a `DS_Error` decline that writes no
module, so the broken intermediate cannot escape. `emitCondNetwork`'s `CopyRoot` cannot coexist with
tree nodes (a bare rail root has none — confirmed in `collectCondTree`). `NegL`/`NegR` are set only
by `SwapRouteEmit`'s P4 nest conjunction, never by the tree walk, so `bracket()` can never put a
`cqrt_x` on a rail from this path. Stage-2b blindness: I counted rails dynamically rather than
trusting it (§5).

## 7. What round 2 should do

1. Decide F-B1R1-1 (widen the measure set to the wire, in both callers, or write the asymmetry down).
2. Carry F-B1R1-2 into B.2's brief as a stated precondition, and consider restoring an emitter-level
   assertion now rather than at the moment it becomes load-bearing.
3. Build the select-side `inplace_xor_bridge` accept (F-B1R1-3) so the shared retirement trigger has
   two pins.
4. Assume a fifth thing is here. The eight-findings-over-six-rounds history on the neighbouring
   function is the base rate; one clean round is not evidence of absence.
