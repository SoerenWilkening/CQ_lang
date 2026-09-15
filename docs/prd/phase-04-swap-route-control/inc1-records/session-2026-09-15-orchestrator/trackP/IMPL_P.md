# Track P′ — the prep merge-φ leaf grammar stops asking a POSITION question and starts asking the right one

Session 2026-09-15. Worktree `/Users/sorenwilkening/Desktop/CQ_P`, branch `prep-leaf-grammar`,
based on **Track F′'s `f2-phidesc-precision` at `3637fdd2`**, not on `main`. Beads:
**bd `test_C_libtooling-hn29`**, **bd `test_C_libtooling-leyd`**, **bd `test_C_libtooling-52og`**
— three over-declines, and the first measurement of the track was that **two of them are the same
program**.

> **The headline.** All three bead shapes now lower, with STRICT stage-2b-clean streams that are the
> SHIPPED in-`Pred` streams gate for gate. **Exactly ONE shipped fixture flips**, it is the one whose
> own header carried the retirement trigger naming this change, and it flips in the ACCEPT direction.
> But the interesting half is not the accepts:
>
> * **bd `hn29`'s stated premise is FALSE and the fixture header it contradicted was RIGHT.** The bead
>   says *"the Kahn chain already schedules every kickback before every prep, so the emission order
>   would be right"* — i.e. the blocker is bookkeeping with nothing behind it. Measured, that is true
>   of ONE of the three shapes and false of the other two: widening the positional fence alone moves
>   them from `condition predates a non-diagonal gate` to `control flow`, because with the adjacency
>   broken **nothing orders the two regions** and the prep is emitted first. The fix therefore has two
>   halves, and CLAUDE.md **L6** is run in the direction it is usually not: the thing being protected
>   really was the emitter's bookkeeping — so the bookkeeping got fixed, and the fence did not get
>   deleted.
> * **bd `leyd`'s stated fence is the wrong one.** It records the decline as firing on
>   `condWireDisposition`/`railCondWireDisposition`; it fires on `classifyPhaseKickback` step 6's
>   per-leaf window. Both sites use the same `declAnchor`, which is why the anchor the bead recorded
>   could not tell them apart.
> * **bd `hn29` case (1) is not reachable in the spelling the bead gives.** `-O1` FUSES two
>   same-condition kickbacks into one diamond, so `if (b1) φ(.3); if (b1) φ(.7);` **accepts on the
>   ORACLE** and always did. The shape reproduces only once a different-condition region sits between
>   the two readers.
> * **The F′ × P′ composition is REAL, it was constructed deliberately, and it found a PRE-EXISTING
>   broken-module defect that both tracks add customers to.** See §7 and `COMPOSITION.md`.

---

## 1. What was actually in front of the beads — measured, not read (Rule 11)

`clang -O1 -g` on bd `hn29`'s own probe (`trackP/probes/p20.c` from the previous session, reproduced
here as `probes/pA1_two_preps_conjoined.c`) gives:

```llvm
%0:  %1 = cq_theta_i1(false, 0.5)   ; b0
     br i1 %1, label %2, label %4
%2:  %3 = cq_theta_i1(false, 0.5)   ; prep 1's arm
%4:  %5 = phi i1 [ %3, %2 ], [ false, %0 ]     <-- PREP 1's merge φ, block %4
     br i1 %1, label %6, label %8              <-- PREP 2's branch, also block %4
%6:  %7 = cq_theta_i1(false, 0.9)   ; prep 2's arm
%8:  %9 = phi i1 [ %7, %6 ], [ false, %4 ]     <-- PREP 2's merge φ, block %8
     %10 = select i1 %5, i1 %9, i1 false       <-- the AND tree
     br i1 %10, label %11, label %12           <-- the KICKBACK.  Pred = %8.
```

`%9` is in `Pred`; `%5` is one block back. So the firing site is
`classifyPhaseKickback` **step 6's** per-leaf loop —
`if (P->getParent() != Region.Pred || scanForward(P))` — and **not**
`condWireDisposition`, whose `Cond` here is the `select` ROOT and IS in `Pred`.

**That is bd `leyd`'s first work item, answered.** The bead asks *"which prong of
`condWireDisposition` fires, and whether it is answering about the OTHER prep's non-diagonal gate
sitting on a DIFFERENT wire"*. Neither: `condWireDisposition` is not reached on that conjunct at all,
and the gate the fence is nominally protecting against **does not exist in this program** — prep 2's
`cq_theta_i1(false, 0.9)` is a **SOURCE** theta whose arg-0 is a classical constant. It allocates a
fresh rail and relabels nothing. The predicate the whole family uses is
`Taint.Tainted.count(CI->getArgOperand(0))`, and it is FALSE here. The decline was a **position**
answer to a **relabelling** question.

**And bd `hn29` case (2) IS bd `leyd`.** `trackP/probes/p20.c` and
`trackX/probes/fp_x3_two_preps_two_phi_leaves.c` are the same program up to renaming and the angle
`0.9` vs `0.5`, they decline at the same site with the same string, and they were filed a session
apart as two defects. One fixture now covers both
(`control_phase_kickback_mergephi_two_leaves_cross_block.ll`).

**bd `hn29` case (1) — the Rule-11 correction.** The bead's spelling is *"a SECOND kickback on the
same φ from a later block"*. Written as `if (b1) cq_phi(.3); if (b1) cq_phi(.7);` it **accepts at exit
0 on the ORACLE, 64 lines** (`probes/pA2_second_kickback_later_block.c`), because `-O1` FUSES two
same-condition regions into ONE diamond carrying two `cq_phi` calls — bd `b6ap`'s own construct. The
declining shape needs a different-condition region wedged between the two readers
(`probes/pA2b_second_kickback_after_gap.c`, which does decline, at `pA2b.c:11:9`).

---

## 2. The fix, part 1 — `chainedThetaBetweenDefAndBranch`, the CFG-bounded positional scan

`ir-pass/src/ArmClassify.cpp`, anonymous namespace, immediately above `condWireDisposition`.

It is the **one spelling** (Rule 14) of *"can a tainted-operand `cq_theta` execute between this
condition's definition and the flag mint at the branch?"*, and it has exactly two callers — the two
that used to pair a single-block window with an unconditional cross-block bail.

**The window it replaces was complete only inside `Pred`.** `Def->getNextNode() … Term` walks off the
end of `Def`'s block and returns `false` VACUOUSLY anywhere else, which is why both callers guarded it
with `getParent() != Pred → decline`. The pairing was sound and it was an over-decline. Both beads,
and `control_phase_kickback_reject_mergephi_cross_block.ll`'s own retirement trigger, prescribe the
same fix in the same words — *"a real CFG-bounded scan (all blocks on paths from the φ's block to
`Pred`, visited-set bounded) instead of the single-block window it has today … it is NOT to be bought
by simply deleting this fence"*.

```
if (Def->getParent() == Pred)          -> the OLD LOOP, expression-for-expression.
else:
  scan the tail of Def's block  (or ALL of it when Pred can reach Def's block)
  BFS over successors, keeping only blocks with isPotentiallyReachable(B, Pred)
     Pred itself: scan [begin, Term)          and STILL push its successors
                                              on the same reachability test
  visited-set bounded; a 512-block budget DECLINES rather than falling out with false
```

**Four properties, each deliberate:**

1. **The in-`Pred` case is byte-identical.** That is what makes every flip this change produces an
   ACCEPT-direction one: its other input was an *unconditional decline*, so the change can only move
   `DeclineNow → (scan)`.
2. **`Pred`'s successors are pushed, and that clause is the whole of bd `52og`'s safety.** In an
   acyclic region no successor of `Pred` reaches `Pred`, so the clause contributes nothing. On a
   cycle it walks the body, which is how a **latch** theta — executing after trip *k*'s mint and
   before trip *k+1*'s — is found. `control_phase_kickback_reject_mergephi_inloop_latch_theta.ll` is
   the pin; delete that one `for` and it goes green with no other symptom anywhere in the tree.
3. **The IN-`Pred` residual is NOT widened**, and that is stated rather than tidied away. A theta
   after the branch inside a loop is invisible to the in-`Pred` window today and is covered by the
   wire walk only for gates on the condition's own wire. Closing it is a DECLINE-direction change
   with its own Rule-13 obligation and this track did not make it.
4. **`isPotentiallyReachable` answers conservative-TRUE on its own block budget**, which is the safe
   direction here: a true answer only adds blocks to scan.

**Soundness of the block set, as a two-line argument.** A gate `T` executes between `Def` and some
activation of `Term` only if `Def →* T` and `T →* Pred`; both make `T`'s block a member of the walk's
set, and the set is closed under successors-on-a-path-to-`Pred` because every block on a path to
`Pred` reaches `Pred`. The only part of `Def`'s own block that is skipped is the prefix before `Def`
— which for both call sites consists of φ nodes only (`Def` is a `PHINode`), and which is scanned
anyway when `Pred` can reach `Def`'s block.

### 2a. Where it is called, and the species scoping that keeps the blast radius at zero

* **`condWireDisposition`** gains one defaulted parameter, `bool CondIsClaimedRailPhi = false`. When
  false the `Cond->getParent() != R.Pred → DeclineNow` prong is **unchanged**, so every compare
  condition at the flat kickback, the value arm, the in-place Ry arm and the state prep keep it —
  **including the LICM-hoisted loop-invariant compare** that CLAUDE.md §2 names as the reason
  *"Grover's condition register must be loop-variant"*. Exactly one caller passes `true`:
  `classifyPhaseKickback`, for a φ ROOT, i.e. `!IsTree && !Tree.RailPhiLeaves.empty()` — the same
  expression `PhiAnchor` already uses, and a case where step 5c has ALREADY run rung 0
  (`preppedRailPhiRegionIdx`, the ONE spelling, CALLED). The positional loop inside the function is
  replaced by a call to the helper unconditionally, which is a no-op for an in-`Pred` condition.
* **`classifyPhaseKickback` step 6's φ-leaf loop** drops `P->getParent() != Region.Pred ||
  scanForward(P)` for `chainedThetaBetweenDefAndBranch(P, Region.Pred, Term, Taint)`.

**The COMPARE leaves keep `scanForward`, and that is not an oversight.** A cross-block compare leaf
never reaches step 6 — step 5a declines it `control flow` on the identical *"only a BOUNDED window
when the leaf is in `Pred`"* ground. Giving compare leaves the CFG scan is a separate widening of a
separate decline string over fixtures this track never measured (Rule 16). A retirement trigger is in
the source: the day step 5a is widened, delete `scanForward` and give both loops the helper.

**Why a φ may have this and a compare may not.** A compare is a SNAPSHOT of a predicate taken at a
program point; a claimed prep merge φ, like the `cq_theta_i1` rail leaf beside it, **IS the register**
(CLAUDE.md §1: *"the φ IS the rail"*). That is why `railCondWireDisposition` is allowed to drop the
prong entirely for a rail. ⚠ This change does **not** transplant that ground onto the φ — bd `4aiu`
refused to do that unmeasured and the refusal stands. It keeps the prong and makes it real, which
leaves the φ strictly more conservative than the rail and strictly less than the compare.

---

## 3. The fix, part 2 — the emission ORDER, which is the half bd `hn29` said was already there

`emitPhaseKickbackRegion` consumes the φ **as a value**; the prep's M-β RAUWs that φ to the hoisted
`cq_theta` and `flattenRegion` then frees it. So the kickback must be emitted FIRST. Today that is
supplied for free by `ArmClassify` step 5c's theorem, whose **hypothesis is
`P->getParent() == Region.Pred`**: only then is `kickback.Pred == prep.MergeBB`, only then does the bd
`hcrg` `Aliases` test fire, and only then is `Precedes[kickback] = {prep}` FORCED.

This increment admits φ leaves that do not satisfy that hypothesis. **Measured on
`probes/a1_clean_gap2.ll`**: with the positional fence widened and nothing else, the module moves from
`condition predates a non-diagonal gate` to `control flow` — `emitPhaseKickbackRegion`'s
`CondV != R.Condition` identity check (bd `3qps`) firing on a φ the prep already replaced and freed.
`control_phase_kickback_reject_mergephi_cross_block.ll`'s header predicted exactly this: *"Break the
adjacency and that edge does not fire: nothing then orders the two."*

**The record.** `classifyPhaseKickback` collects `preppedRailPhiRegionIdx`'s answer — CALLED, never
re-derived — and commits it to `Region.PrepRegionIdxs` at the single `Accept` exit.
`SwapRouteEmit::lowerControlRegions` gains a second edge loop, keyed on
`Kind == ControlRegion::PhaseKickback`, that turns each into `Precedes[kickback] = {prep}`.

⚠ **THE SAME FIELD, THE OPPOSITE DIRECTION FROM THE SELECT'S**, and the asymmetry is the two
emitters' opposite needs: `SelectMergeEmit` RE-READS its condition and wants M-β to have run (bd
`boi6` F-M1's "prep before select"), while `emitPhaseKickbackRegion` wants the φ still live. The
`Kind` test at the top of each loop is what keeps them apart, and both directions are now written out
at the field's declaration in `ControlPlan.h` — whose previous text said a kickback records NOTHING,
and which is corrected **in the source**, not only here (CLAUDE.md L7 / the `z9t1` lesson: *a record
correction that is not applied to the source is not a correction*).

⚠ **ONLY CROSS-BLOCK LEAVES ARE RECORDED**, and that is what makes the increment zero-risk in the
DECLINE direction *by construction rather than by argument*. Every kickback that lowered before this
change carries an EMPTY `PrepRegionIdxs`, its plan is bit-identical, and the new edge loop is a
literal no-op for it. A record-everything-and-dedupe spelling would have been equivalent only *given*
that the alias edge always exists, which is a claim about `coordinated()` and
`sequentialChainAlias`'s own preconditions that this track has not measured. Narrowing the WRITE is
cheaper than proving the dedupe total. (The dedupe is kept as defence in depth.)

**Cycles.** A select gains only INCOMING edges and so can never sit on one; a kickback now gains
OUTGOING ones, so this is stated rather than argued away. A cycle needs `prep.Pred ∈
doomedBlocks(kickback)`, i.e. the prep sitting AFTER the kickback in the CFG while its merge φ
dominates the kickback's branch — no dominance relation permits that. The enforcement is not that
sentence: it is the Kahn backstop, which leaves regions unscheduled and declines LOUDLY.

**Three stale in-source claims were corrected in the same change**, each because it would otherwise
be re-read as still true: `ControlPlan.h`'s `PrepRegionIdxs` paragraph, step 5c's *"WHY THIS DOES NOT
NEED A `plan` MUTATION"* heading and its theorem's totality, and step 5c's *"AT MOST ONE φ LEAF CAN
SATISFY THE IN-`Pred` REQUIREMENT"* paragraph (whose conclusion survives — it was never about blocks
— but whose premise no longer exists).

---

## 4. Measured: every bead shape, three ways

`ORACLE` = `main` `74eabd2c` (`0e280fc6…`), `BASE` = `3637fdd2` = Track F′ (`8cda04ca…`),
`SUBJECT` = this branch (`7916923f…`). Runner: `probes/run3.sh`.

| probe | bead | ORACLE | BASE | SUBJECT |
|---|---|---|---|---|
| `pA1_two_preps_conjoined.c` | `hn29`(2) ≡ `leyd` | D `predates` @`:12:12` | D same | **A, 82 lines** |
| `pA2_second_kickback_later_block.c` | `hn29`(1) as written | **A, 64** | A, 64 | A, 64 — `-O1` fuses; bead spelling not reachable |
| `pA2b_second_kickback_after_gap.c` | `hn29`(1) unfused | D `predates` @`:11:9` | D same | **A, 69 lines** |
| `pA3_inloop_phi_kickback.c` | `52og` | D `predates` @`:9:13` | D same | **A, 85 lines** |
| `a1_clean_gap2.ll` | the shipped fixture's module | D | D | **A, 23** |
| `a2_two_prep_phi_leaves.ll` | `pA1` as hand IR | D | D | **A, 27** |
| `a3_inloop_outside_prep.ll` | `pA3` as hand IR | D | D | **A, 26** |
| `d1_chained_on_wire_in_gap.ll` | fence, on-wire | D | D | **D — still bites** |
| `d2_offwire_theta_in_gap.ll` | fence, OFF-wire | D | D | **D — still bites** |
| `d3_xor_bridge_in_gap.ll` | fence, xor bridge + theta | D | D | **D — still bites** |
| `d4_measure_in_gap.ll` | rung (ii) cross-block | D `measured before` | D same | **D same — unmoved** |
| `d5_bare_xor_in_gap.ll` | the V12 residual (see §6) | D | D | **A, 25** |
| `c5_bare_xor_in_pred.ll` | `d5`'s in-`Pred` twin | **A, 21** | A, 21 | A, 21 — unmoved |

### 4a. The streams, read as unitaries (Rule 2 — no simulator, analytic/trace reasoning)

**`a1_clean_gap2` is the argument in one line: the emitted gates are the SHIPPED in-`Pred` accept's,
gate for gate and operand for operand.**

```
%h  = cqrt_alloc_i1(%u0);  cqrt_ry_i1(%h, 0.5)
%h1 = cqrt_alloc_i1(false); cqrt_ry_i1_controlled(%h, %h1, 0.25)
cqrt_rz_i1(%h1, 0.9), !cq.branchphase
cqrt_measure_i1(%h1)
```

That is `control_phase_kickback_mergephi_rail.ll`'s stream. **The widening adds an ACCEPT, not a
STREAM.** `h1` is read only as the diagonal gate's target and left ALLOCATED (Rule 6 — `Ry(θ)|0⟩ ≠
|0⟩`); nothing minted, stripped or freed, because for a φ the register IS the flag (Rule 7); no
`cqrt_x` touches a user register.

**`a2_two_prep_phi_leaves` / `pA1`** — two preps, then
`alloc(g); toffoli(h1,h2,g); rz_i1(g, .3) !branchphase; toffoli(h1,h2,g); free(g)`. `cqrt_rz_i1` is
diagonal, so it multiplies exactly the `b1 = b2 = 1` component by `e^{i·0.3}`; the second `toffoli`
returns `g` to `|0⟩` on every branch, so its single `cqrt_free` is a proven-`|0⟩` one; `h1`/`h2` are
read ONLY as toffoli CONTROLS, never `cqrt_x`-bracketed, never freed; `h0` is untouched by the
kickback. Linked and run: 14 trace lines, exactly that sequence.

**`a3` / `pA3` (bd `52og`) is ROLLED, and it is measured so, three ways:**

* the `cqrt_rz_i1` sits INSIDE `header`, with the induction φ and the back edge intact;
* the lowered IR is **44 lines at K=3 and 44 lines at K=1000** (plain C, no `-g`);
* its runtime trace is **BYTE-IDENTICAL** to the hand-unrolled three-`cq_phi` twin's
  (`probes/pA3t_unrolled_twin.c`; `diff` empty).

K activations of a diagonal gate give `e^{iKφ}` on `|b1=1⟩` — which is what
`for (i<K) if (b1) cq_phi(φ)` says.

**`pA2b`** emits `rz(h1,.3); rz(h0,.4); rz(h1,.7)` — three kickbacks in SOURCE order on the right
registers.

### 4b. STRICT stage 2b on every new accept

```
pA1_two_preps_conjoined         4 rail mint(s) of which 3 left allocated, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven
pA2b_second_kickback_after_gap  2 rail mint(s) of which 2 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven
pA3_inloop_phi_kickback         2 / 2 left allocated, 0 free sites: 0 verified, 0 violation(s), 0 unproven
a1_clean_gap2                   2 / 2, 0 free sites, 0 violation(s), 0 unproven
a2_two_prep_phi_leaves          4 / 3, 1 free site: 1 verified, 0 violation(s), 0 unproven
a3_inloop_outside_prep          2 / 2, 0 free sites, 0 violation(s), 0 unproven
d5_bare_xor_in_gap              2 / 2, 0 free sites, 0 violation(s), 0 unproven
```

⚠ Stage 2b is **structurally blind to a leaked TEMPLATE-minted rail** (CLAUDE.md), so this is cited as
what it is: rail-pairing clearance, not leak clearance.

---

## 5. Fixtures — Rule 12, red first, and one hygiene trap walked into and recorded

Six files. Every RED state in §4 was measured on the ORACLE **and** on Track F′'s binary before the
subject existed, which is the red half of red-green taken twice.

| file | verdict | what it pins |
|---|---|---|
| `control_phase_kickback_reject_mergephi_cross_block.ll` | **converted DECLINE → ACCEPT** | the shipped fixture whose own retirement trigger named this change |
| `control_phase_kickback_mergephi_two_leaves_cross_block.ll` | new ACCEPT | bd `hn29`(2) ≡ bd `leyd`, the two-φ-leaf tree |
| `control_phase_kickback_mergephi_inloop_outside_prep.ll` | new ACCEPT | bd `52og`, rolled, with a `ROLLED`-prefix loop-structure check |
| `control_phase_kickback_reject_mergephi_cross_block_theta.ll` | new DECLINE | a chained Ry on the φ's own wire in the gap |
| `control_phase_kickback_reject_mergephi_cross_block_offwire_theta.ll` | new DECLINE | **the positional prong's unique subject** — a theta no wire walk can see |
| `control_phase_kickback_reject_mergephi_inloop_latch_theta.ll` | new DECLINE | the BACK-EDGE clause; delete `for (S : successors(Pred))` and only this goes green |

⚠ **The `reject_` in the converted file's name is HISTORY and the file is deliberately NOT renamed** —
bd `test_C_libtooling-gahu`'s standing precedent and CLAUDE.md L8's reason: a `git mv` can be
RESURRECTED by a merge, leaving one module under two names with contradictory verdicts and no gate
able to see it. **Add it to `gahu`'s list; do not move it.**

⚠ **FIXTURE HYGIENE — I walked into the exact trap Track F′ recorded this session, in the same file
family.** A section heading `; ---- ROLLED: the gate is INSIDE the loop …` was parsed by FileCheck as
a **positive `ROLLED` directive** and the fixture failed on prose. F′'s record says it *"bit twice,
the second time in the sentence explaining it"*; this is the third. The heading was rewritten to name
the prefix in lowercase quotes, and **all six files were then scanned mechanically** for a prefix name
followed by a colon at the start of a comment — two hits remained and both are genuine directives
(`PHI-NOT: = phi`). Counts live in their own whole-file prefixes and every negative prefix is pure
(Rule 12(a)).

### 5a. The injection matrix, and the two things its FIRST run found

`probes/injection_matrix.py`, 17 mutations × 3 accept fixtures. **Final: 51 mutations, MISSED 0, N/A
6 — every N/A an `n/a-shape`** (the toffoli pair exists only in the two-leaf tree; the rolled fixture
has no `PHI-NOT` to violate). The empty-argv control exits 1 with a refusal rather than printing a
green-looking line (the 2026-09-14 hole, re-checked).

The FIRST run reported **MISSED 1** and **one harness HOLE**, and both were fixed rather than
explained:

* **MISSED — `M15 a phi appears` on the rolled fixture.** It carries no `PHI-NOT` because a ROLLED
  loop must keep its induction φ, so an injected φ was invisible to all ten of its prefixes. Fixed in
  the FIXTURE, not in the matrix: a new `PHICNT` prefix pins `COUNT-1: = phi` followed by `NOT: = phi`
  — exactly one φ, the induction variable, and no other.
* **HOLE — `M16` read `N/A` on the two-leaf tree**, where the branch phase fires on the AND ancilla
  `%g` and not on `%h1`, so an anchor spelled `%h1` never matched. A mutator reading N/A is a HOLE,
  not a pass (PROTOCOL S3). Respelled to match the target generically and pin only the destination.

### 5b. SOURCE mutation — the gate the fixtures could not be, and the finding it produced

⚠ **A DECLINE FIXTURE THAT WAS ALSO RED ON THE PRE-CHANGE BINARY MEASURES NOTHING ABOUT THE CHANGE.**
All three new decline fixtures declined on BASE too — through the OLD unconditional cross-block bail.
So `probes/source_mutation.sh` removes one clause of the increment at a time, rebuilds, and asserts
that a NAMED fixture flips; the restore at the end rebuilds and **verifies the binary is bit-identical
to the subject hash**, which it is, so every gate line in `GATES.md` remains a fact about the shipped
source.

| mutation | clause removed | measured |
|---|---|---|
| **S-M1** | the `push(S)` over `successors(Pred)` — the BACK-EDGE clause | `…_inloop_latch_theta.ll` **FAILS**; the three accepts unmoved |
| **S-M2** | the cross-block walk returns `false` at once — the SCAN | `…_cross_block_offwire_theta.ll` **FAILS**; `…_cross_block_theta.ll` (on-wire) **passes**; `…_inloop_latch_theta.ll` **FAILS** |
| **S-M3** | the `PhaseKickback` precedence edge | `…_reject_mergephi_cross_block.ll` **FAILS**; `…_mergephi_inloop_outside_prep.ll` **FAILS**; `…_two_leaves_cross_block.ll` **passes** |

**S-M3's split is the §3 argument, measured.** The two-leaf tree keeps lowering without the edge
because its hcrg chain (`kickback.Pred == prep2.MergeBB`, `prep2.Pred == prep1.MergeBB`) already
Kahn-sorts to kickback → prep2 → prep1; the other two have no such chain and the edge is the only
thing ordering them. That is bd `hn29`'s premise being true of one shape and false of two, in one
table.

⚠ **AND S-M1's FIRST RUN DID NOT FLIP ITS FIXTURE — a real finding, not a harness bug, and it is why
`…_inloop_latch_theta.ll` was rebuilt.** The file's first version put the latch theta on the
condition's OWN wire (`cq_theta_i1(%b1, …)`) and its header asserted *"delete that one `for` … and this
file goes green with no other symptom"*. It stayed red: an on-wire latch theta is refused by
`wireGainsNonDiagonalGate` unaided, because `provablyBefore(BI, T)` needs
`!isPotentiallyReachable(T, BI)` and the back edge makes the latch reach the branch. **A decline
fixture reached by two roads measures neither.** The module was rebuilt around an OFF-WIRE operand
(`%b0`), which `condProvenance(%b1) = {%b1, %t}` does not contain and no forward user edge reaches, so
exactly one road remains — and S-M1 then flips it. The false sentence was removed from the fixture
header in the same change (CLAUDE.md L7 / the `z9t1` lesson), and the same distinction was written
into `…_cross_block_theta.ll`, which is *deliberately* doubly covered and now says so **with the S-M2
measurement behind it** rather than as an assertion.

---

## 6. Rule-13, self-review round — the over-accept vectors, and the one that changed the design

These are my own rounds and **clear nothing** (Rule 13: a green suite does not clear a core change,
and neither does the author's own reading). They are recorded so an independent round has somewhere to
start.

**V1 — the scanned block set is too small.** Argued in §2 and stated as a two-line theorem. The only
skipped region is the prefix of `Def`'s block before `Def`, which is φ-nodes-only at both call sites
and is scanned anyway when `Pred` reaches `Def`'s block.

**V2 — `isPotentiallyReachable` gives up.** Conservative-TRUE; adds blocks to scan. Safe.

**V3 — the `Cyclic` clause is vacuous.** It is, for the φ species (only φs precede a φ in its block).
It is one reachability query of defence in depth, and it is the clause that would matter first if the
helper ever gained a non-φ caller.

**V4–V6 — the order edge.** `preppedRailPhiRegionIdx` returns the region whose `Merge == P`, i.e. the
one whose M-β rewrites `P`. A conflicting constraint leaves the Kahn sort unsatisfiable, which is a
loud decline, not a silent pick.

**V7 — the emitter's `collectCondTree` re-derivation drifts.** It cannot: the edge guarantees the
kickback is emitted while every φ is live, which is the condition under which the re-derivation sees
the classifier's tree.

**V8/V9 — a block-lifetime alias the new order exposes.** The `Aliases` pre-flight is untouched and
still runs for every ordered pair: if `A.Pred` is any block `B`'s flatten erases and the pair is not
the sanctioned chain, the module declines loudly. That protection does not depend on my edge.

**V12 — the one that changed what I believed, and it is the reason `d5` is an accept and not a
finding.** My positional scan looks for `cq_theta_*` only, exactly like the prong it replaces. But the
rail-relabelling gate set also contains the **dtzb in-place `add`/`xor`** (CLAUDE.md), so cross-block I
am newly admitting programs with a tainted `xor` on the φ's rail between the φ and the branch. Rather
than argue from M-C's G6, I measured the in-`Pred` twin:

```
c5_bare_xor_in_pred.ll   ACCEPT on the ORACLE, 21 lines, and the stream is
    %h_op = cq_template_xor_i1_hl(i32 %h1, i1 true)     <-- a FRESH handle
    cqrt_rz_i1(i32 %h1, 0.9), !cq.branchphase           <-- %h1 untouched
```

The `xor` lowers **OUT of place** onto a fresh rail — G6 refuses the in-place conversion because the
φ is read later by its own branch — so the kickback's control is not stale. `d5`'s cross-block
acceptance is therefore **consistency with a shipped, cleared accept**, not a new surface. ⚠ And the
retirement trigger is the one `railCondWireDisposition`'s header already carries: *"If M-C's G6 ever
admits an in-place op on a rail with a later read, this ground is gone"* — it now has a **third** pin
(`d5`/`c5`) besides the kickback's and the select's.

**V13 — rung (ii) cross-block.** `railMeasuredBeforeReadPoint` asks `isPotentiallyReachable` for every
measure wherever it sits (the F-B1-1 fix), so it is position-total and needs nothing from me.
Measured: `d4_measure_in_gap.ll` declines `condition measured before the control route` identically on
all three binaries.

**Two of my own lenses were then MEASURED rather than left as questions**, and both came back clean:

* **(b) — can a cross-block COMPARE leaf ride into step 6 behind a φ leaf, where its `scanForward`
  window is vacuous?** `probes/v1_crossblock_cmp_leaf_with_phi_leaf.ll` puts a compare leaf in the
  prep's merge block, a φ leaf beside it, a chained `cq_theta_si32(%q, …)` in the gap that the vacuous
  window would miss, and joins them with a `select`. **DECLINE `control flow`, byte-identically on all
  three binaries** — step 5a refuses the cross-block compare leaf before step 6 exists. The vacuous
  window is unreachable, as the source comment claims.
* **(a) — the back-edge clause against a non-trivial loop body.**
  `probes/v3_inloop_theta_in_guarded_side_block.ll` hides the chained theta in a
  CLASSICALLY-GUARDED side block of the body (`if (i < n)`), reached on one path only and re-fronting
  the mint solely through the back edge. **DECLINE `condition predates a non-diagonal gate` on all
  three** — on ORACLE/BASE through the old bail, on SUBJECT through the CFG walk, which is the clause
  doing exactly its job on a body no fixture had. `probes/v2_inloop_theta_in_kickback_arm.ll` (the
  theta inside the kickback's OWN arm) declines `control flow` on all three: an arm holding anything
  but `cq_phi` never reaches this classifier.

**What an independent round should attack first**, in the order I would: (a′) the back-edge clause
against a multi-latch or irreducible body that `flatRegionRollableInLoop` nonetheless admits (v3
covers only the single-latch guarded case); (c) the 512-block budget's decline path, which no fixture
reaches; (d) the F × P composition in §7.

---

## 7. The F′ × P′ composition — constructed deliberately, and it found something

Full three-way rows and the attribution method are in **`COMPOSITION.md`**. The short form:

`probes/fxp1_composed_crossblock_nondominated_phi.ll` is Track F′'s own recovered accept
(`acc1_dead_nondominated_phi.ll` — a state prep whose only F2 witness reaches the seed through a DEAD,
NON-DOMINATED join φ) transcribed to `i1`, with one extra block between the prep's merge and the phase
kickback's branch. It needs F′ for the prep and P′ for the leaf, and it is **the first deliberately
constructed instance of the composition bd `test_C_libtooling-hlhh` predicts**:

```
ORACLE   DECLINE  'state prep seed is proven equal to the condition register'   <- F2
BASE     DECLINE  'condition predates a non-diagonal gate'                      <- my fence
SUBJECT  exit 134  PHI node operands are not the same type as the result!
                   %p = phi i1 [ %h_op, %gapX ], [ false, %Y ]
```

The isolating control `probes/fxp2_deadphi_i1_template_noF2.ll` (the same module with no F2 witness)
**exits 134 on the ORACLE too**, so the defect is **PRE-EXISTING on `main`** — a DEAD `i1` φ whose
incoming is a tainted `i1` pure op survives `declineClassicalMuxes`' liveness filter, `lowerOps` RAUWs
the op to an `i32` template handle, and the module is broken. What the two tracks do is **add
customers**: F′ takes `fxp1c_nogap_control.ll` from a clean F2 decline to 134, and P′ takes `fxp1`
from a clean fence decline to 134. CLAUDE.md's formulation applies verbatim — *"pre-existing is true
of the defect and FALSE of its population"*.

It is LOUD (exit non-zero, nothing emitted), so it is not the unforgivable bug; it is nonetheless a
Rule-1 "no third path" violation with no source location, and it is **filed, not fixed here** —
fixing it is a decline-direction change to `declineClassicalMuxes`' liveness filter over fixtures this
track never measured.

---

## 8. What this does NOT do

* **The compare-leaf cross-block decline (step 5a, `control flow`) is untouched**, deliberately, with
  a retirement trigger in the source. Same question, different string, different fixture population.
* **`railCondWireDisposition`'s prong-free treatment is NOT transplanted onto the φ.** bd `4aiu`
  refused it unmeasured; the refusal stands and this change does not need it.
* **The in-`Pred` positional residual** (a theta after the branch inside a loop) is not closed.
* **`AllowRailPhi` is still `false`** for the depth-2 phase NEST, the Ry-stem angle select and
  `Specialization`'s forward-only copy. Unmoved.
* **The pre-existing dead-φ broken-module defect (§7) is filed, not fixed.**
