# Rule-13 REVIEW, round 1 — bd `test_C_libtooling-l4x4` sub-increment **l4x4.b**

**Verdict: CLEAR-WITH-ITEMS.** One over-accept that produces a wrong unitary on a
branch the source leaves alone (F-1, non-finite rotation angle under the NEGATED
rail arm — plain C, `opt` exit 0, verify-clean, stage-2b clean; **fix before
landing**, one clause), one deliberate over-decline the owner must be told the
full cost of (F-2, the in-loop carve-out), one PRE-EXISTING over-decline confirmed
on `main` (F-3, IMPL Q2), and two documentation items (F-4, F-5). **No confirmed
silent miscompile for a well-formed source**; the two hazards the brief singled
out — the whole-DAG spine freeing an entangled control, and a reader of the
intermediate state between the negation's two gates — are **both established
absent**, structurally and by measurement.

Independent reviewer, round 1. Nothing was rebuilt and nothing under `ir-pass/`,
`include/`, `tests/`, `tools/` was edited in any worktree. Three read-only
binaries: **ORACLE** `/Users/sorenwilkening/Desktop/CQ_lang` (`main` 0c7380c),
**F2-BASE** `/Users/sorenwilkening/Desktop/CQ_f2` (the Track-C checkpoint),
**SUBJECT** `/Users/sorenwilkening/Desktop/CQ_l4x4` (`l4x4b-bool-ry-arm`; the tree
was committed as `267937d` while this review was in progress, so every diff below
is `578dbc4..267937d`).

Probes: **45** (42 single-TU + 3 two-TU) in `review_l4x4b_r1_probes/`, with
`run.sh [oracle|f2|subj]`, `run_multi.sh` and `sweep_f2_vs_subj.py`.

---

## 0. What I re-measured independently

| gate | my result |
|---|---|
| F2-BASE vs SUBJECT over **every** fixture in the subject tree (`sweep_f2_vs_subj.py`) | `files=1810 RCDIFF=15 DIAGDIFF=11 OUTDIFF=0`; **all 26 movers are files that do not exist at 578dbc4** (`comm -12 movers old-fixture-list` is EMPTY) |
| the same, restricted to the **1782** `.ll` fixtures common to both trees | **0 RCDIFF · 0 DIAGDIFF · 0 OUTDIFF** — decline-monotone AND byte-identical lowered IR |
| `lit -s ir-pass/test --filter 'inplace_ry_rail\|stateprep_rail\|rail_cond'` | 18 of 1810, **18 passed** (corpus count confirms 1810) |
| stock `opt -passes=verify` on 6 lowered accepts (incl. the chained-rail-off-a-template case `f03`) | clean |
| `tools/free_pairing_check.py` on 5 accepts | `4 rail mint(s) of which 4 left allocated, 0 (or 2) cqrt_free site(s): all verified, 0 violation(s), 0 unproven` |
| stderr on 8 accepts | empty (no stray M-A warning on the shipped shapes) |
| the two `git mv`'d fixtures | IR **byte-identical** to 578dbc4 modulo comments (`diff` over non-`;` lines, empty) |
| the 5 new e2e goldens, read line by line | all five match the streams my probes produce; the owner's isolated second region is exactly the 7 lines BRIEF §4 predicted |

The implementer's own three-way sweep reported "2 movers"; mine reports 26 because
the two `git mv`'d files appear under their NEW names in the subject tree. The
two readings agree.

---

## F-1 — OVER-ACCEPT-ARGUED (fix before landing). The NEGATED rail arm's Ry-additivity cancellation is exact for every FINITE angle and is NOT the identity for a non-finite one

**Reproducer, plain C at `-O1`** (`probes/x01_neg_inf_angle.c`, `x02_neg_nan_angle.c`,
`n11_neg_runtime_angle.c`):

```c
_Bool b = 0; int r = 7;  b = cq_theta(b,0.5);  r = cq_theta(r,0.25);
if (!b) { r = cq_theta(r, __builtin_inf()); }        /* or __builtin_nan(""), or a double parameter */
```

SUBJECT: `opt` **exit 0**, verify-clean, stage-2b clean, emitting

```
cqrt_ry_i32(%h1, double 0x7FF0000000000000)               ; +inf, unconditional
cqrt_ry_i32_controlled(%h, %h1, double 0xFFF0000000000000) ; -inf
```

On the `b = 1` branch **the source is the identity**. The emitted pair is
`Ry(−∞)·Ry(+∞)`, which under the project's `Ry(θ) = [[cos(θ/2), −sin(θ/2)],
[sin(θ/2), cos(θ/2)]]` is `NaN`, not `I` — the compiler destroys a register on a
branch where the source touches nothing. NaN behaves identically
(`0x7FF8…`/`0xFFF8…`). The run-time-angle spelling accepts too
(`cqrt_ry_i32_controlled(%h, %h1, double %cqnegangle)` where
`%cqnegangle = fneg double %0`) and **cannot be fenced at compile time** — the
Inc-2b clearance blocker F-11's exact structure.

**It is reachable only through l4x4.b.** The COMPARE twin is faithful: ORACLE emits
`cqrt_x(%h_cmp); cqrt_ry_i32_controlled(%h_cmp, %h1, +inf); cqrt_x(%h_cmp)` — ONE
gate inside the bracket, so its non-firing branch is untouched
(`probes/x01c_neg_inf_cmp.c`).

**The sibling emitter that also duplicates an angle already has this fence, and
the l4x4.b clause is one conjunct short.** `angleSelectArmsAdmissible`
(`ArmClassify.cpp`) refuses a non-finite `ConstantFP` arm outright
(`if (CA && !CA->getValueAPF().isFinite()) return false;`, and again on the
difference) and was NARROWED TO CONSTANT ARMS by the Inc-2b Rule-13 clearance for
precisely the "not fenceable at compile time" reason. l4x4.b's one value clause,
`ArmClassify.cpp:2976`, asks `valueCarriesUndef` and nothing else — its own comment
correctly identifies *why* a negated arm needs a value fence ("the emitter emits
the rotation twice … would be read as TWO DIFFERENT VALUES") and then fences only
the `undef` half of that argument.

**Weight, stated honestly.** The source must itself name a non-gate angle on the
firing branch, so this is not the Inc-2b case of a *well-formed* source producing
a manufactured `inf`. That is why the verdict is CLEAR-WITH-ITEMS and not BLOCK.
But the compiler is still introducing an effect the source did not name, on a
branch the source leaves alone, and the Prime Directive's direction is not in
doubt. **Recommended fix:** beside the `valueCarriesUndef` clause at `:2976`,
require the negated rail arm's angle to be a **finite `ConstantFP`** (reuse
`angleSelectArmsAdmissible`'s spelling — Rule 14), with the run-time case an
explicit owner decision rather than a silent accept. Cost: one conjunct, one
decline fixture; **no shipped accept fixture or e2e slice uses a non-finite or a
run-time angle**, so nothing green moves.

---

## F-2 — OVER-DECLINE (deliberate, scoped l4x4.c) — and the cost is TOTAL for the shape, not partial

`ArmClassify.cpp:2940` declines every in-loop rail region with
`control flow inside a loop body` (probe `t5`, measured). The circuit it refuses —
`for k in 1..K: CRy(b, r, θ)` with `b` loop-invariant — is a perfectly valid
bounded circuit, and R7's (b)/(b′) clauses are about the *rotated* register and
would carry unchanged. So this is an over-decline by construction, and the
increment says so.

What the record does **not** say plainly, and the owner should hear: **the compare
spelling cannot express this shape at all**, so the carve-out closes the only
door. Measured: `t5c`, the compare twin, declines `condition predates a
non-diagonal gate` on ORACLE, F2 and SUBJECT alike (`-O1` LICM-hoists the
invariant compare and `condWireDisposition`'s P4 prong refuses a cross-block
condition; `railCondWireDisposition` deliberately has no P4 prong, which is
exactly why the rail form reaches `classifyArms` and the compare form does not).
Net effect for the customer: **"Grover as a rolled loop with a `_Bool`-controlled
rotation or state prep" does not compile in any spelling.** Carving it out is a
defensible increment boundary — H-5's eight-miscompiles-in-six-rounds history is a
real reason — but it should be filed as l4x4.c with that sentence attached, not as
"the capability has no witness".

---

## F-3 — OVER-DECLINE, PRE-EXISTING, CONFIRMED (IMPL Q2 — please file)

A 6.5 classical-call-arm region immediately followed by a flat control region
declines `control flow`. **Measured on the COMPARE twin** (`probes/impl/multi/w1c_caller.c`,
two TUs) on **ORACLE, F2 and SUBJECT alike**, with
`CQ_CTRL_DBG=1` giving the anchor `%14 = icmp sgt i32 %11, 0` — the *second*
region's condition. Mechanism confirmed by reading:
`SwapRouteEmit.cpp:2459` `sequentialChainAlias`'s inner `reorderable()`
(`:2460-2463`) admits only `BranchRegion` and `PhaseKickback`, so a
`ClassicalCallArm` predecessor is an alias ordering cannot resolve and
`declineRegion` fires. Arm-class-independent, predates every branch in this
session. It cost real work in this increment (the H-2 fixtures had to interpose an
opaque classical diamond to move the rail region out of that block), and it will
cost the next one the same. **File it.**

---

## F-4 — DOC. Two of the increment's own probes do not exercise what their headers claim, and the record cites them for two §2.6 partition rows

* **`probes/impl/p5_classical_call_arm_rail.c`** — header: *"the 6.5 arm on a rail …
  must keep declining."* It **ACCEPTS**, on the SUBJECT *and* on `main`, emitting
  `cqrt_alloc_i1; cqrt_cnot; 2 × cqrt_copy_i32_controlled; cqrt_x; cqrt_cnot;
  cqrt_free` — i.e. `-O1` folds the `const noinline` callee to a `select i32` and
  the program is handled by **r9e5's 1b-B.1 rail data-select with `CopyRailRoot`**,
  never reaching `classifyClassicalCallArm` at all.
* **`probes/impl/p6_eqfold_rail.c`** — header: *"EQ-FOLD."* It is a plain `cq_phi`
  branch phase and lowers to `cqrt_rz_i1`, shipped by Inc 1b; no eq-fold anywhere.

**The partition itself is fine** — I verified the CLASSICAL-CALL, VALUE, EQ-FOLD
and PHASE rows are pinned by the hand-IR fixtures
(`control_swap_reject_{value,phase}_rail_cond.ll`,
`control_inplace_ry_reject_rail_ifelse.ll`), which decline `bare i1 register
condition` on all three binaries, and that on the SUBJECT that string can now only
come from `declineRailClass` or an emitter backstop (the pre-l4x4.b gate now says
`control flow` for a non-rail non-compare). But IMPL §1's table cites `p5`/`p6` as
the measurement for two rows, and they measure something else. Fix the two probe
headers, or replace them.

## F-5 — DOC. The VALUE class on a rail can decline with a string other than `kBareRailCondReason`

`t16_i1_stateprep` (`_Bool r; if (b) r = cq_theta(0, 0.9);` — an `int` prep
truncated to `_Bool`) declines **`value-arm swap-route`**, because several
value-specific clauses sit ABOVE the §2.6 re-decline at `:3971`. Still loud, still
correct; SCOPE §2.6's table reads as though the value class always answers
`bare i1 register condition`, and a future `fg9k` reviewer will trip on it.

---

## 1. THE SPINE AND THE CONTROL REGISTER (brief item 1) — it NEVER claims `b`. Established structurally and measured.

**Structurally, two independent exclusions, not one.**

1. `isTerminalHandle(h_b)` (`ChainWalk.cpp:718-737`) iterates `h_b`'s users. The
   emitted `cqrt_ry_<W>_controlled(h_b, h_r, θ)` is **not** an in-place gate on
   `h_b` — the `ry`-stem clause (`ChainWalk.cpp:260-262`) requires
   `getArgOperand(1) == H`, and the generic `if (N.contains("_controlled")) return
   false;` immediately below refuses arg-0 — and it is not a measure, output or
   copy-out sink, so the loop reaches `return false`. **`h_b` is never a terminal,
   so the whole-DAG spine never recovers it, never adjoints its chain and never
   frees it.**
2. It can never be an **M-B interior** candidate either, and here the increment's
   own argument is weaker than the truth. IMPL §3 rests on
   `preservesBasisUnderRecord`'s `_controlled` disqualify list. That holds — but a
   rail leaf is by definition a **`cq_theta_i1` result**, so its rail ALWAYS
   carries an uncontrolled `cqrt_ry_i1`, and `isInteriorConsumer` arm (a) refuses
   it through `preservesBasisUnderRecord` because **`Ry` is not a basis
   permutation**. The rail is excluded by a property of what it *is*, independently
   of the `_controlled` list. Worth writing at the site (H-9 asks for exactly
   this): it means a future widening of that list cannot silently re-open the door.

**Measured, 9 programs, in every one: no `cqrt_free(h_b)` and no `cqrt_ry_i1(h_b, −θ)`
adjoint** — `b` dead (`r01`), `b` measured (`r02`), `b` a CHAINED theta with BOTH
names dead (`r05` — one rail, `ry_i1(h,.3); ry_i1(h,.2)`, gate on `h`, no
reversal), `b` borrowed by a live `zext` chain (`t14`), `b` NOT measured with the
borrow the only measured value (`s02`), the borrow dead (`r04`), two regions on one
`b` (`t13`, `g02`, `z02`), negated (`t7`), S† after the region (`t8`). Stage 2b on
five of them: `4 rail mint(s) of which 4 left allocated, 0 violation(s)`.

**The one uncompute that DOES cross the controlled gate is valid, and it is worth
saying why**: `t14`/`s02` emit `cq_template_zext_i1_to_i32_unc(%h_cast, %h)` AFTER
`cqrt_ry_i32_controlled(%h, …)`. That is sound precisely because a control operand
is read-only and block-diagonal in the control's own basis — the gate moves no
basis label on `h` — so the borrow un-copies cleanly and `cqrt_free(%h_cast)` is a
proven-|0⟩ free (stage 2b: `2 verified`). The leak of `h_b` itself is the Rule-6
REQUIRED direction (`Ry(θ)|0⟩ ≠ |0⟩`), and it is the same disposition the compare
form gives its condition register.

**`cq_invert` (brief item 1's last clause) is INERT and that is pre-existing.**
`cq_invert_begin(); if (b) r = cq_theta(r,.9); cq_invert_end();` emits
`cqrt_ry_i32_controlled(%h, %h1, +0.9)` — *not* the adjoint — and leaves
`@__cq_invert_begin/_end` as unresolved externs, so stage 3 fails to LINK rather
than miscompiling. The COMPARE twin on the ORACLE does exactly the same
(`probes/i01c_invert_cmp.c`). Phase 8, not l4x4.b's.

## 2. THE NEGATION ORDER (brief item 2) — no reader can be placed between the two gates. The additivity argument is sound for every finite angle; F-1 is its only hole.

**Structural.** `T->moveBefore(BI)` followed by `TNeg->insertBefore(BI)` makes the
pair **adjacent, immediately before the region's terminator**, with at most the
emitter's own `fneg` (a classical instruction) between them for a run-time angle.
Nothing in the pipeline can land a gate in that slot: every other emitter inserts
at ITS OWN `BI` or at its consumer's position, and an `IRBuilder<>(BI)` insertion —
which is how `cqrt_free`, strips and later regions' mints are placed — lands
**after** `TNeg`, not between. `flattenRegion` splices the (now empty) arm block at
the terminator, also after.

**Measured**, 8 negated programs — the diamond (`t7`), a data read of the rotated
register after (`n10`), two regions with the negated one first (`g02`), negated
then a phase kickback on the same `b` (`g03`), the state prep with an `int` seed
(`g04`) and with a `_Bool` seed (the owner's isolated second region, `o1`), θ = 0.0
(`n12`), a run-time angle (`n11`) — **in every one the stream is exactly
`ry(h_r, θ); cry(h_b, h_r, −θ)` with nothing between**, and
`Ry(θ)Ry(−θ) = I` holds exactly per qubit under the tensored `cqrt_ry_<W>`.
`−θ` is `APFloat::changeSign` / `fneg`, so the Inc-2b `½·ulp(A−B)` fence genuinely
has no subject — that part of SCOPE §2.3's recommendation is correct.

State vector for the owner's shape, re-derived: with `b0` in
`α|0⟩ + β|1⟩` and `h1 = |0⟩`, `Ry(.5)` then `CRy(b0, h1, −.5)` gives
`α|0⟩_b Ry(.5)|0⟩ + β|1⟩_b |0⟩` — exactly `if (b0 == 0) b1 = cq_theta(b1, 0.5)`.

R6 still holds for the negated form: a pre-region record read after declines
`stale rail record read past a controlled Ry` (`y04`).

## 3. H-1 (brief item 3)

**(a) `WeakTrackingVH`.** RAUW updates value handles, so the entry *becomes* the
`i32` handle the moment pass 1 lowers the rail's theta; the subsequent erase of
the now use-less call does not touch it. A null (erase with no replacement) and a
control that is *still* a `@cq_theta_*` call both take the **LOUD** bail
(`controlled rotation control handle`) with `continue`, never a fall-through to the
uncontrolled gate. The bail sits above the alloc, with its two siblings.

**(b) the CONTROL-THETAS-FIRST ordering.** No-op by construction for every module
without a rail control: `dyn_cast_or_null<CallInst>(E.second)` on a
`cq_template_icmp_*_hl` result succeeds but `isThetaCallHere` fails, so
`ControlThetas` stays empty and `ThetaOrder` reproduces `taint.ThetaCalls`
verbatim. **Independently confirmed: 0 OUTDIFF over the 1782 fixtures common to
both trees.** For a module WITH a rail control it permutes **handle names only**,
not emitted positions — measured with the rail declared LAST (`h01`): `%h` is the
rail's alloc, `%h1`/`%h2` the earlier registers, and the gate stream still follows
source order, because `lowerRotations` inserts at each theta's own position. The
only consumer of `BirthOrder` is `DagTraversal.cpp:169`, a **tie-break** used only
when neither gate dominates the other, which the same comment records as
unreachable ("dominance is a TOTAL order here"). The walk itself terminates
(`ControlThetas.insert(...).second`), stops at a non-theta parent, and the
`ThetaCalls.insert(It+1, …)` is safe (LLVM's `SmallVectorImpl::insert` recomputes
the index across a grow).

**(c) the two awkward controls.** A CHAINED control lowers correctly (`r05`). A
control theta with a quantum-derived angle declines loudly upstream
(`unsupported quantum-derived rotation angle`, `h03`) and nothing is emitted.
A chained rail whose PARENT is a TEMPLATE (`(_Bool)(q & 1)`, `f03`) reaches the
use-site check as a pre-`lowerOps` `iN` value — the correction recorded in IMPL
§2b is right, `isIntegerTy(32)` would have refused a shape that has nothing to do
with H-1 — and the finished module is **stock-`opt -verify` clean** (checked on 6
lowered accepts). `f03`'s stream is also correct end to end: the `and` rail is
uncomputed and freed BEFORE any gate on `q`.

## 4-8. The rest of the brief's list

**4 (the partition at four accept sites).** Verified by reading that
`declineRailClass()` dominates every `Saw*` accept in `classifyArms` except the
rotation one (`grep` of `Saw*Arm = true` / `declineRailClass()` /
`RailLadderProven = true`: sites 2857, 2883, 3764, 3983 all guarded; 3729 is the
target). A classifyArms `Accept` with no class set is caught twice more —
`emitRegion`'s rail dispatch requires `ClassArm == InPlaceRotation`, and
`emitInPlaceRotationRegion` requires `R.RailLadderProven`. `Arms` is built as
`{Arm} ∪ {ArmFalse}`, so `Arms.size() > 1` ⟺ `R.ArmFalse` non-null, which makes
the classifier's two-arm decline and the emitter's two-`ArmInfo` construction
consistent. `classifyClassicalCallArm` returns `NotApplicable` for a non-compare
condition and defers; the mixed Ry + `cq_phi` arm declines `mixed phase/value arm`
/ `impure phase arm` above the rail clause.

**5 (the skipped `HasDataUse`/`ShareCondFlag`).** The skip is right — H-4's
argument holds and I could not construct a data use of a rail that needs
`condDataUseDisposition`. The rival `if (b) b = cq_theta(b, θ)` declines
`state prep merged with a quantum register` (F1 clause 2) both folded (`p3`) and,
per the committed fixture, unfolded. The seed-is-`b` and other-`i1`-pinned
variants (`f02`, `f01`) decline at F1's first clause. A later region reading `b` as
a compare (`z02`) is folded by `-O1` back to a second rail region and lowers
correctly. **Q5's claim that R4 is a backstop here, never the fence that fires, is
confirmed** — I could not make R4 fire on the rail path.

I did find one *accept* that R4 would have refused for the compare form, and I
judge it **CORRECT**: `y01` (`_Bool b = cq_theta((_Bool)(q&1), .5); if (b) q =
cq_theta(q, .9);`) rotates an ANCESTOR of the rail's wire, and lowers to
`and; icmp; and_unc; free; ry_i1(h_cmp,.5); cry(h_cmp, h, .9)`. R4's reason for a
compare region is the **flag strip**, which does not exist here; the derived `and`
rail is discharged before the first gate on `q`, and `h_cmp` is a correct record of
the PRE-region low bit, which is what the source says. `probes/y02`, `y03` (a
derived record live across such a region) decline `operand predates a non-diagonal
gate` identically on ORACLE and SUBJECT.

**6 (F2 on the rail).** Re-derived: the owner's `_Bool` seed under `b0` pinned
`false` on the arm edge is admitted because Track C's narrowing excludes values on
the CONDITION'S OWN BACKWARD WIRE and the rail IS the condition (`o1`,
`t16b` accept and emit `alloc_i1(0); ry_i1_controlled(h, h1, .9)` — correct: `|0⟩`
when `b=0`, `Ry(.9)|0⟩` when `b=1`). The I-4 residual I could construct — a second
live `i1` `c = !b` pinned to the seed's value on the arm edge (`f01`) — declines,
though at F1 rather than F2, so it does not actually exercise the residual; I could
not build a plain-C program that reaches F2's singleton test with a non-condition
anchor on a rail region.

**7 (in-loop).** See F-2. The string `control flow inside a loop body` is shared
with 6 other sites (`ControlDetect.cpp:632/:679/:811`,
`ArmClassify.cpp:3624/:4728/:6214`) and the fixture mirrors it exactly. The
irreducible-cycle hole I looked for is **not** open: `regionEntryInLoop` is
reducibility-independent, so an irreducible cycle declines in `ControlDetect`
before `Region.InLoop` is ever set.

**8 (`markRailCondRead`).** The two new sites are the only rail reads this
increment emits — both branches of the Gates loop mark, and the negated form's
UNCONDITIONAL twin reads no rail, so marking `TNeg` alone is right. `grep -c` of
`markRailCondRead(` in `ir-pass/src` = **6**, as IMPL states. The record is
load-bearing at **all three** new consumer shapes; I built the window myself rather
than reusing the implementer's: the DIAMOND rung (iii) (`w2`), the rung (ii) half
(`w3`), the **PREP** (`multi/w4_prep_caller.c`), the **NEGATED PREP**
(`multi/w5_prep_neg_caller.c`) and the **NEGATED in-place arm**
(`multi/w6_neg_inplace_caller.c`) — every one `bare i1 register condition` on
ORACLE and F2, and on the SUBJECT `condition predates a non-diagonal gate` /
`condition measured before the control route` from `reverifyRailCondReads`.

**9 (Q2).** See F-3.

**10 (every accept `-O1`-reachable + state vector; every decline invalid?).**
All 14 accept fixtures' shapes are `-O1`-reachable except the hand-IR ones their
headers already label. Widths measured from plain C: **i1, i8, i16, i32, i64, f32,
f64, f80** all lower to the matching `cqrt_ry_<W>_controlled`, every one declared
at `runtime/cq_runtime.h:229-237` — no new symbol, confirmed
(`git status --porcelain runtime/ tools/ include/` empty at 578dbc4..267937d for
`runtime/`, `tools/`, `include/`). Declines I checked and judge CORRECT (i.e. the
circuit really is unprovable or the program is a different one): `t6`/`p3` (F1),
`t9` (rung ii), `t24`/`y04` (R6), `p1`/`p2` (rung iii), `y02`/`y03` (the pass-wide
stale-record guard, identical on the ORACLE), the four §2.6 hand-IR fixtures, the
multi-gate arm, the undef angle, `v01` (a merge-φ condition is not a rail leaf —
bd `boi6`), `r03`/`u01` (multi-φ regions — bd `b6ap`), `z01`/`z01c` (specialization,
identical on the ORACLE; its message *"floating-point quantum argument"* is
mis-worded for an `i1` argument, pre-existing).

**One observation, not a finding.** The M-A `DS_Warning`
`non-diagonal gate over a live derived record` fires for `t15` (derived rotated
base) and for the compare form of `y01`, and does **not** fire for `y01` itself,
whose live derived record is the condition's own `icmp` rail. That is the
already-recorded arm-class-independent M-A gap (CLAUDE.md: "M-A does NOT fire for
an ESCAPING condition record"), not something this increment introduced.

---

## What I would ask the implementer to do before landing

1. **F-1**: add the finite-`ConstantFP` conjunct at `ArmClassify.cpp:2976` (reuse
   `angleSelectArmsAdmissible`'s spelling) plus one decline fixture; decide the
   run-time-angle case explicitly rather than by omission.
2. **F-2**: file l4x4.c with the measured sentence "the compare spelling cannot
   express this shape either, so the carve-out closes the only door".
3. **F-3**: file the pre-existing `ClassicalCallArm`-then-flat-region over-decline.
4. **F-4 / F-5**: correct the two probe headers and SCOPE §2.6's value-class row.
5. Write the second, stronger exclusion from §1 above at the `preservesBasisUnderRecord`
   site (a rail leaf always carries an uncontrolled `cqrt_ry_i1`, so it is excluded
   independently of the `_controlled` list) — H-9 asks for exactly that, and it is
   the sentence that survives a future widening of that list.
