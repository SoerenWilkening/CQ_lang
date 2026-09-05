# Increment 4 implementation notes — controlled STATE PREP

> bd `test_C_libtooling-drbq` child `drbq.5`, implementing PRD §14. Written at
> HEAD `8eb6f4c` (the Inc-4 pre-implementation record) against the pre-Inc-4
> **oracle** `scratchpad/wt/pre4/build/ir-pass/cq-opt`, built from `b506b3b` —
> MD5-identical to `8eb6f4c`'s compiler (`8931bc461dc1db08e90288880f7d67be`,
> re-verified at the start of this session). A **Rule-13 core change** touching
> `ArmClassify`, `RotationLowering` and `SwapRouteEmit`.
>
> **Rule-13 rounds: 1 (§10) · 2 (§11) · 3 (§12) · 4 (§13).** Every round found
> something and every finding sits inside the previous round's fix; §9 is the
> running "what worries me" list and is the right place to aim a fifth round.

---

## §0 — What shipped

`int r = SEED; if (COND(q)) r = cq_theta(SEED, θ);` — a flat `BranchRegion`
**diamond** whose single content arm is one `@cq_theta_<sfx>` with a **classical
`ConstantInt`/`ConstantFP` arg-0** — lowers **control-in-place on a rail the
compiler mints inside the region**:

```
cq_template_icmp_<pred>_<W>_hl(c, k)   -> f      ; flag mint at the branch
[ cqrt_x(f) ]                                    ; Rule-9 polarity bracket
cqrt_alloc_<W>(SEED)                   -> h      ; the theta's !Chained arm,
cqrt_ry_<W>_controlled(f, h, θ)                  ;   at the HOISTED position
[ cqrt_x(f) ]
cq_template_icmp_<pred>_<W>_hl_unc(f, c, k)      ; strip
cqrt_free(f)                                     ; the region's ONLY free
```

The rotated rail is **FROZEN** by Increment 1's structural freeze
(`ChainWalk::railCarriesControlledRotation`, asked of the emitted gate's own
arg-1 use): never reverse-played, never freed — a controlled gate's adjoint needs
its control, and the flag is stripped and freed three instructions earlier. The
leak is O(1) per region, Rule 6's sanctioned fallback.

> **⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L3 finding F-3): "O(1)
> per region" is true of the rail THIS INCREMENT MINTS and false of the region's
> total leak.** The freeze marks the whole DAG `NotClosed`, so once the prepped
> register has a derived consumer the derived rails leak too: measured,
> `int s = r + 1; measure(r)+measure(s)+measure(q)` leaks THREE rails (`q`, the
> prepped rail, and the `cq_template_add_i32_hl` rail), and **stage 2b cannot
> count the third** — its census counts `cqrt_alloc_*` mints only
> (`free_pairing_check.py:409`), the documented bd `8h7d.5` F-4 blindness, now
> reachable through this class. The honest statement is *"O(1) rails MINTED BY THE
> REGION, plus the derived DAG hanging off the prepped register"*. The CHAINED
> twin leaks exactly the same set, so this is inherited from Inc 1, not introduced
> — but the reader will take "O(1)" literally.

**Two fences**, both new, both with their own diagnostic string and fixtures —
and **five strings after the round-1 review, not three** (see §10):

| fence | string (`cq controlled lowering: … under quantum control`) |
|---|---|
| **F1** seed identity | `state prep seed does not match the merge incoming` |
| **F1** seed identity, TAINTED incoming | `state prep merged with a quantum register` (round-1, L5 F-L5-1) |
| **F2** the edge-pinned seed | `state prep seed is proven equal to the condition register` |
| §14.2e if/else, TWO preps | `if/else state prep allocates two rails` |
| §14.2e if/else, MIXED arms | `if/else state prep beside a chained or phase arm` (round-1, L7 F-L7-8) |

No new frozen symbol, no new recognizer, no CFG surgery, no template regeneration.
`cqrt_ry_<W>_controlled` is the Inc-1 frozen-designate family, unchanged.

---

## §1 — Files changed

| file | change |
|---|---|
| `ir-pass/src/ArmClassify.cpp` | `inPlaceRotationArmTheta` gains `bool &StatePrep` and **admits any untainted arg-0** (F1 owns the narrowing); a new `if (StatePrep)` block before R3 carrying the if/else clause, F1 (three sub-clauses, one string) and F2; R4's and R6's `railWireClosure` calls wrapped in `if (!StatePrep)`; the ex-"STRUCTURALLY UNREACHABLE" `!Taint.Tainted.count(RotBase)` check **re-scoped** to `!StatePrep && …` (it became reachable — it was not deleted) |
| `ir-pass/src/RotationLowering.cpp` | the `controlled theta suffix/width` bail **hoisted above the alloc** (it was a mid-emission bail — Rule 1); the `!Chained && Ctrl` `controlled theta operand` bail **replaced by the accept path**; `Ctrl` lookup moved up so both can read it |
| `ir-pass/src/SwapRouteEmit.cpp` | **comments only** — the identity re-validation is now documented as also being a seed check by uniqued-constant representation, and M-β is documented as a **correctness requirement** for this arm class rather than the loop-bookkeeping convenience it is for Inc 3 |
| `ir-pass/test/` | +59 files in the family (20 accept / 39 decline), 2 pre-existing files re-homed, 2 pre-existing files given cross-reference headers. Corpus 1474 → **1531** |
| `tests/e2e/` | 3 new slices + goldens + CMake registration. ctest 324 → **327** |
| `docs/prd/…/inc4-records/inplace_stateprep_post4.txt` | the post-4 twin-matrix table, committed beside the pre-4 one — **the pair is the witness** |

**Nothing** in `LoopLowering`, `Uncomputation`, `ChainWalk`, `DagTraversal`,
`FreePoint`, `EmitInverse`, `WireWalk`, `TaintPropagation` or `ControlDetect` was
touched. No golden was regenerated. `tools/opcode_table.yaml` was not touched.

**Re-homed** (renamed, so `git log --follow` shows the flip):

* `control_inplace_ry_reject_state_prep.ll` → `control_inplace_ry_stateprep_cond_ordered.ll`
  — **DECLINE → ACCEPT with the IR unchanged.** Its old header named the two
  things "Inc 1 does not have"; both are what this increment ships.
* `control_inplace_ry_reject_inloop_stateprep.ll` → `control_inplace_ry_reject_stateprep_inloop_carried.ll`
  — still a decline; its string moved from `control flow` to F1's, because the
  recognizer now sees the arm and the loop-carried pred incoming is a data mux.
  **This was the only file in the 1494-fixture corpus that Inc 4 turned red.**

**Cross-referenced** (header only, no behaviour):
`control_swap_eqfold_diamond.ll` (the §14.2d **stem pair** — do not "tidy up" the
Rz/Ry asymmetry) and `control_angle_select_reject_state_prep.ll` (the **second
customer site**, S3, shipped OUT as `drbq.13`).

---

## §2 — The new diagnostic strings and their fixtures

Full message form: `cq controlled lowering: <What> under quantum control`.

### F1 — `state prep seed does not match the merge incoming` (**15 fixtures today**: 11 printing this string + 4 printing the round-1 split string; the `12` this heading carried was the count at the implementation hand-back and stopped being the count of anything after round 1 — ⚠ corrected 2026-09-05, round-2 review lens R2 F-R2-9)

Three sub-clauses under one string, because the author's fix is the same in all
three ("make the straight-through value the seed"):

1. the seed is a `ConstantInt` or `ConstantFP` — nothing else;
2. the merge φ has a **Pred-edge** incoming and it is **pointer-identical** to
   the seed (LLVM uniques both classes on type + bits, so pointer identity IS
   bit identity — and a hand-written `APFloat` test would have to use
   `bitwiseIsEqual`, never `==`, which calls `-0.0 == 0.0` true);
3. the seed's LLVM type equals `llvmWidthType(abiWidthFor(suffix))`.
   ⚠ **CORRECTED 2026-09-05 (round-1 review, lens L1 F-L1-1): it is REACHABLE and
   LOAD-BEARING, not defence in depth** — see §8 F-3, rewritten. The route is an
   UNRECOGNIZED suffix (`isThetaCall` is a name-prefix test; `resolveSources`
   validates only `allSuffixes()`), and the fixture the old note said could not be
   written is `..._reject_stateprep_unrecognized_suffix.ll`, with the one-token
   accept twin `..._stateprep_suffix_control.ll`.

`..._seed_mismatch` · `..._negzero_incoming` · `..._negzero_seed` ·
`..._undef_incoming` · `..._poison_incoming` · `..._constexpr_seed` ·
`..._runtime_seed` · `..._nonconst_incoming` · `..._select_incoming` ·
`..._prep_then_prep` · `..._inloop_carried` · `..._unrolled_k2`.

> **⚠ ROUND-1 (2026-09-05): +3 fixtures and 4 files MOVED TO THE NEW STRING.**
> `..._undef_seed` and `..._poison_seed` pin clause **1**, which the two
> `_incoming` files do NOT (their seed is `i32 0` and only the incoming is
> `undef`/`poison`, so clause 1 passes and clause 2 declines — relax clause 1 to
> `isa<Constant>` and both stay green; lens L1 F-L1-2).
> `..._unrecognized_suffix` pins clause **3** (lens L1 F-L1-1), with the accept
> twin `..._stateprep_suffix_control`. And `..._nonconst_incoming`,
> `..._prep_then_prep`, `..._inloop_carried` and `..._unrolled_k2` now assert
> **`state prep merged with a quantum register`** — their pred incoming is
> TAINTED, which is a no-cloning mux and not a seed mismatch (lens L5 F-L5-1).

### F2 — `state prep seed is proven equal to the condition register` (**40 fixtures today**, MEASURED: `grep -l 'state prep seed is proven equal' ir-pass/test/*.ll | wc -l` — 6 at hand-back + 6 from round 1 + 8 from round 2 + 15 from round 3 + 5 from round 4 — ⚠ heading count corrected TWICE, 2026-09-05: first by round-2 review lens R2 F-R2-9 (the `6` was the hand-back figure), then by the round-4 mini-fix, which found `20` still standing after round 3 had added fifteen. **Re-measure with the `grep` rather than trusting this number** — a hand-maintained count is how the retired `165/174` claim happened, and this heading has now been wrong twice for the same reason.)

`..._eqfold_coincidence` (eq / arm edge) · `..._eqfold_coincidence_ne` (ne /
straight-through edge — the polarity-freeness pair) · `..._eqfold_cast` ·
`..._eqfold_extremum` · `..._eqfold_ult` · `..._eqfold_derived_cond` (§8 F-6b —
the condition register F2 protects is the compare's own tainted operand, which on
a derived condition is a TEMPLATE rail and not `q`).

> **⚠ ROUND-1 (2026-09-05): F2 WAS REWRITTEN RANGE-BASED AND THE FAMILY GREW BY
> SIX** — five declines (`..._range_mask1`, `..._range_a2_alias`,
> `..._range_ordered`, `..._range_knownbits`, `..._range_i1_both_edges`) plus the
> Rule-12 gap `..._eqfold_ne_else` (PRD row F2-7, which shipped with no fixture),
> and one accept control (`..._stateprep_range_ordered_seed0`). The shipped
> literal test was a CONFIRMED silent miscompile on the `ne` edge; see §10 F-L2-1.

> **⚠ ROUND-2 (2026-09-05): F2's *SET* WAS WIDENED TO A BOUNDED FORWARD CLOSURE
> AND THE FAMILY GREW BY EIGHT DECLINES + ONE ACCEPT** — the six
> `..._range_forward_{add,xor,sub,or,lshr,ashr}` (transcribed from the six
> plain-C programs of finding F-R1-1, every one of them an ACCEPT at the round-1
> HEAD with the rotated register alive, lowered to a rail and MEASURED while
> receiving no rotation), plus `..._range_constleft_{ugt,eq}` and the accept
> control `..._stateprep_range_constleft_accept`. **The round-1 fix widened the
> PREDICATE and kept the SET — the bd `8h7d.5` F-1/F-3 shape a third time.** See
> §11 F-R1-1 and PRD §14.2b.

> **⚠ ROUND-3 (2026-09-05): F2 STOPPED BEING A SET AND BECAME THE QUESTION, AND
> THE FAMILY GREW BY FIFTEEN** — the semantic `LazyValueInfo` + abstract-evaluation
> rewrite; see §12.1 F-R3-1/2/3/8/9/10 for the file list.

> **⚠ ROUND-4 (2026-09-05): FIVE MORE, AND NONE OF THEM IS A FOURTH GENERATION OF
> THE SAME MISTAKE** — `..._reject_stateprep_fcmp_oeq_folded` (F-R4-1: the
> BACKWARD half was `isIntegerTy()`-gated, so NO fp register was ever asked F2's
> question), `..._reject_stateprep_fcmp_oeq_derived` (the same pin one hop
> FORWARD, which is what pins the anchor's hand-off to the existing forward
> evaluation instead of a second walker), `..._reject_stateprep_unfoldable_curated_call`
> (F-R4-3: the conservative rule was not asked for ANY `CallBase`, because the
> not-foldable early return ran before `AnyPinnedOperand` was computed) and
> `..._reject_stateprep_step_cap_over` (F-R4-4: `kF2MaxSteps` was pinned by
> nothing). Each ships with an ACCEPT control in the same round —
> `..._stateprep_fcmp_oeq_twin`, `..._stateprep_fcmp_oeq_negzero`,
> `..._stateprep_fcmp_oeq_derived_accept`, `..._stateprep_step_cap_under` —
> because three of these clauses are PRECISION clauses that a decline-only
> family structurally cannot pin (the §12.3 M5 lesson, repeated). See §13.

### §14.2e — `if/else state prep allocates two rails` (4 fixtures)

`..._ifelse_two_preps` · `..._ifelse_diff_seeds` · `..._ifelse_mixed_chained` ·
`..._ifelse_mixed_phase`, plus `..._ifelse_phase_first` which pins the OTHER arm
order (`mixed phase/value arm`, the pre-existing homogeneity flag).

> **⚠ ROUND-1 (2026-09-05, lens L7 F-L7-8): the clause now has TWO strings.**
> `..._ifelse_mixed_chained` and `..._ifelse_mixed_phase` have ONE prep each — the
> other arm is a chained Ry or a `cq_phi` — so "allocates two rails" described a
> different program. They assert
> **`if/else state prep beside a chained or phase arm`**; the two genuine
> two-prep files keep the original wording. The clause chooses by re-classifying
> the OTHER arm with the SAME `inPlaceRotationArmTheta` predicate it is inside, so
> the two cannot drift.

---

## §3 — The sets audit: "what OTHER set is computed over the same closure?"

Re-derived from the code actually changed, not copied from PRD §14.6.
**READ** = the body was read this session; **MEASURED** = a probe or mutation
established it.

| set / walker | what it decides | verdict for a state prep | how established |
|---|---|---|---|
| `inPlaceRotationArmTheta`'s accept set (sole caller `classifyArms`) | is the arm one in-place theta? | **THE CHANGE.** Its arg-0 half now REPORTS instead of refusing; the other three halves (defined in `ArmBB`, sole user is the merge φ, nothing else in the block) are asked ONCE of BOTH classes through the same code, so they cannot drift | READ + MEASURED (`..._stray_op`, `..._fanout`, `..._two_gates`, `..._theta_phi_arm` all decline `control flow`) |
| R3's `Routed` / `Region.setRoutedBase` | the routed handle | now holds a **`Constant`**. `WeakTrackingVH` on a constant is stable (constants are never erased), and `..._seq_then_chained` proves the cross-region case still works | READ + MEASURED (fixture accepts) |
| `emitInPlaceRotationRegion`'s `T->getArgOperand(0) != Base` | plan-vs-IR agreement | passes by uniqued-constant pointer identity. Documented in place as *also* a seed check by representation — it is NOT the seed fence | READ |
| **`railWireClosure` → R4 / R6** | wire disjointness, stale records | **SKIPPED, not fed an empty set.** `Out.insert(W)` runs BEFORE the taint gate, so a `Constant` comes back as a "member", and a `ConstantInt` is uniqued per `LLVMContext` — R6 would enumerate unrelated users across the function | READ + **MEASURED**: mutation M5 (remove the skip) reddens **5** fixtures, `..._seed_other_users` among them |
| R7's loop half | in-loop scoping | **STILL ASKED**, over an empty `BaseWireOrder`, so `Rollable` stays false and every iteration-local in-loop state prep declines `control flow inside a loop body` | MEASURED (`..._inloop_iterlocal`) |
| `condProvenance` / `condWireDisposition` P1/P4/P5 | condition-wire exposure | **unchanged, no edit.** P1's §13.4b widening reads `SawRotationArm`, which the same clause sets; a state prep's whole emitted stream lands before `BI` (it is Inc 1's stream **plus one alloc**, also before `BI`). P5's positional scan requires a TAINTED arg-0, so a hoisted state-prep theta is invisible to it — correct, it mints a wire and stales none | READ + MEASURED (`..._post_region_theta_cond` accepts; `..._stalecond` declines) |
| `WireWalk::findNonDiagonalWireGate` / `collectWireValues` | is there a non-diagonal gate on this wire? | unchanged — both require `CI->getArgOperand(0) == V`, and a `Constant` arg-0 is on no wire | READ |
| `declineStaleRecordOps` | pure op past a wire gate | unchanged — it runs before detection and sees an un-hoisted theta with a `Constant` arg-0, on no wire | READ |
| **`taint.ControlledRotations`** | which gate fires under which flag | one more entry, keyed on a classical-arg-0 theta. Readers: `RotationLowering` (the accept path), `ArmClassify` S10 and `AngleSelectEmit` (**double-owner guards — an extra entry STRENGTHENS them**), `TaintPropagation::resolveWireBase` (the stop fires; the pre-existing `!Tainted(Handle) break` would fire anyway), `LoopLowering::isHoistedRegionArmGate` (**additionally requires `cq_phi_`, so a theta entry cannot reach it**) | READ, every reader |
| **`taint.UserSourceRotations`** | which set the minted gate joins | **THE SET CHANGES**: `(Chained ? UserChainedRotations : UserSourceRotations)` puts a CONTROLLED gate into `UserSourceRotations` for the first time | READ |
| ↳ `isRecordedUserRotation` → `isTeardownUse` | user gate vs spine adjoint | reads BOTH sets, so the answer is the same as for a chained gate (not teardown). ⚠ behaviour-neutral today anyway: `reachesObservingSink` `continue`s on `cqrt_ry_` two lines later either way | READ |
| ↳ `warnLiveRecordRotations` | M-A's live-record warning | **does not run** (it keys on `UserChainedRotations` only). **RE-DERIVED, not quoted** — see below — and **MEASURED behaviour-neutral** by mutation M6 | READ + **MEASURED** |
| `ChainWalk::isInPlaceGateOn` / `railCarriesControlledRotation` | THE FREEZE | fires structurally: the alloc handle's first user IS the `cqrt_ry_<W>_controlled` naming it at arg 1. Same predicate, same slot, no new site | READ + MEASURED (`..._consumer_none`: one `cqrt_free` in the whole file, no `_controlled_inv`) |
| `DagTraversal` / `Uncomputation` / `FreePoint` / `EmitInverse` | the spine | unchanged — all reach the freeze through `railCarriesControlledRotation`; `EmitInverse` stays unreachable for this class BY CONSTRUCTION | READ + MEASURED (stage 2b strict on 3 slices) |
| `lowerIOSinks` lineage walk | tape sinks | keys on call-site name + `taint.Tainted` of the operand; the prepped handle is tainted at its alloc | MEASURED (`..._consumer_tape`) |
| `liftOneRegisterMergePhi` / `repropagateControlMerges` / `declineClassicalMuxes` / `declineLiftedStaleRecordOps` | classical join φs, live muxes | unchanged — `T` is a `CallInst`, never a lift candidate; as an INCOMING it resolves to itself | MEASURED (`..._lifted_phi_after` accepts) |
| Phase-6 `specialize` | clone-on-taint | keys on `taint.Tainted` per argument; the fresh handle is tainted | READ |
| `LoopLowering::railPhiRootMint` / `peelInPlaceBase` / `collectRailGates` | the loop MINT vocabulary | **a classical-arg-0 `cq_theta` IS their mint vocabulary**, so a hoisted state-prep `T` is a mint to them — which is why the IN-LOOP shape must decline at R7; there the obstruction is POSITIONAL (the hoisted `T` sits inside the body and does not dominate the header). ⚠ **CORRECTED 2026-09-05 (round-1 review, lens L6 F-3): "which set WOULD CLAIM it if R7 were lifted" is wrong — IT CLAIMS ONE TODAY.** For a FLAT prep followed by a classically-bounded loop rotating the prepped register, `T` DOMINATES the header, `railPhiRootMint` succeeds with a CONTROLLED mint, `collapseFlattenedLoopRails` claims the rail φ and the body ROLLS (HEAD rc=0, oracle rc=1; hand-unrolled K=3 twin BYTE-IDENTICAL, 24 lines; strict 2b clean). Pinned by `..._stateprep_then_rolled_loop.ll`; CONTEXT-DEPENDENT — remove the unrelated in-loop region and the same program declines, on both binaries, because `collapseFlattenedLoopRails` only runs when `InLoopFlattenedPreds` is non-empty | READ + **MEASURED** |
| `free_pairing_check.py` `classify()` | Rule-6 pairing | **classifies `cqrt_alloc_<W>` by symbol name only and never reads the seed argument at any site**, so a wrong seed is invisible to it, and the frozen rail lands in "left allocated" with no finding. Quoted with the goldens rather than as evidence | READ + MEASURED (strict, 3 slices) |
| `tools/control_flag_order_check.py` | mint < gate < strip < free | an alloc between mint and strip does not perturb it (allocs are not classified) | **MEASURED**: 1531 files, 440 flags, **0 violations** |
| `tools/golden_multiset_audit.py` | no shipped golden may move | new slices report `NEW-FILE`. ⚠ its work-rail matcher fences on the alloc literal being `0`, so a non-zero-seed rail is not a work rail to it | READ |

### The `warnLiveRecordRotations` skip, re-derived rather than quoted

PRD §14.12 worry 6 is right that the header sentence *"a source theta mints its
wire, so that wire can carry no record yet"* was written about an **uncontrolled**
source theta and predates controlled rotations by an epic. Here is the argument
from the code that exists now.

`warnLiveRecordRotations` builds, for the gate's wire `W`, a record set in three
passes: **ancestors** of `W` (backward through producer / alloc / clone-return /
copy-destination edges), **descendants** of `W`, and **descendants of every
ancestor**. For a state prep `W` is the `cqrt_alloc_<W>(SEED)` handle:

* ~~**the ancestor pass returns nothing**, because the alloc's only operand is a
  compile-time `Constant` — F1 guarantees it — so there is no producer edge to
  follow and no seed for pass 3;~~ **CORRECTED 2026-09-05 (round-1 review, lens
  L4 F-L4-3) — THE CONCLUSION IS RIGHT AND THIS MECHANISM IS WRONG.**
  `classifyRail` returns `RailKind::Record` for a `cqrt_alloc_*` call
  (`isAllocRail`), so `collectAncestorRecords` takes the `K != Opaque` branch on
  `W` ITSELF and executes `Seeds.push_back(V)` **before** reaching the alloc stop:
  `Seeds == { W }`, not empty. Pass 3 is a no-op for a DIFFERENT reason — pass 2
  already inserted `W` into the shared `Seen` set, so pass 3's
  `if (!Seen.insert(Seed).second) return;` fires immediately — and `W` stays out
  of `Records` because `RecordSet::push` short-circuits on clause 5
  (`if (V == Wire) return;`). That guard, not an absent seed, is what keeps the
  wire out of its own record set. This is the paragraph PRD §14.12 worry 6 flagged
  as most likely to be quoted rather than derived, and it was;
* **every descendant is minted strictly after the gate**, because the controlled
  Ry is the alloc handle's *first user* by construction (the emitter hoisted the
  theta and `lowerRotations` inserts the alloc immediately before it), so
  `recordAbsentAt`'s acyclic form `provablyBefore(T, R)` holds for all of them.
  The in-loop escape hatch that would break this is closed by R7.

So `Records` is empty after filtering and the guard would report nothing even if
it ran. **MEASURED, mutation M6:** forcing the state-prep gate into
`UserChainedRotations` leaves the lit family green and produces **zero**
warnings on all three e2e slices.

> **⚠ AND M-A IS NOT BLINDED BY A STATE-PREP-ROOTED RAIL, which M6 did not test**
> (round-1 review, lens L4 F-L4-3). M6 shows the state-prep GATE warns nothing;
> the complementary question is whether the guard still SEES a live derived record
> on a rail whose ROOT is a controlled gate. It does — measured with a compiled
> reproducer: a record `add` off the prepped rail, a CHAINED `cq_theta` on that
> rail, and an unobserved user `cq_phi` on the record emits
> `warning: cq rotation lowering: non-diagonal gate over a live derived record`,
> exit 0, while the exempt control (the record MEASURED after the gate) warns
> nothing. Committed as `control_inplace_ry_stateprep_warn_live_record.ll`.

---

## §4 — Per-stem: state prep is Ry-ONLY, and the stem table gains NO row

There is **no Rz state prep**, and the reason is Rule 3 rather than scope:
`cq_phi` on a classical operand propagates no taint and is **deleted at lowering**
— it never allocates. Measured: `int r = 0; if (q == 5) r = cq_phi(0, .9);`
declines `control flow` on **both** binaries, and its IR really does carry
`cq_phi_si32(i32 0, 9.0e-01)` in the arm, so the shape reaches the classifier and
is refused there (`..._reject_stateprep_rz_prep.ll`).

Two consequences, stated rather than assumed:

1. **The §12.1 stem table and the §13.4 RAUW-target row gain NO new row.** The Ry
   row already says *link / never adjoint / frozen / relabelling gate /
   RAUW-to-`T`*, and state prep needs all five verbatim — including the last,
   which for this arm class is a **correctness requirement** rather than the
   loop-bookkeeping convenience it is for Inc 3 (§8 M4).
2. **`tools/inplace_twin_matrix.py`'s five-axis method cannot witness this
   increment**, because that method emits each cell twice with `cq_theta` and
   `cq_phi` in the arm and compares — and the `cq_phi` spelling of a state prep is
   a *deleted gate*, not an oracle. Hence the separate `--stateprep` pool with the
   CHAINED twin and the §14.8 reduction.

The §14.2d asymmetry is the mirror image and is **pinned as a PAIR** so nobody
tidies it up: `cq_phi_si32(i32 k, θ)` in an `if (q == k)` arm ACCEPTS and
re-anchors onto `q`'s own rail (`tryEqFoldArm`, `control_swap_eqfold_diamond.ll`),
while `cq_theta_si32(i32 k, θ)` in the same position DECLINES on F2. Sound because
`cqrt_rz_<W>_controlled` is **diagonal** — the strip recomputes the predicate over
a basis the arm did not move — while an Ry relabels it, so there is no correct
re-anchor for that stem at all.

---

## §5 — The three e2e goldens, argued line by line, and the reduction

All three run stage 2b **STRICT** and report
`4 rail mint(s) of which 4 left allocated, 2 cqrt_free site(s): 2 verified,
0 violation(s), 0 unproven`. (The 4 mints and 2 frees are per-file totals across
`slice` and the harness `main`, which inlines it.)

### `slice_control_inplace_ry_stateprep.expected.log` — the flagship

```
1  cqrt_alloc_i32(3) -> h0                                 ; q's rail
2  cqrt_ry_i32(h0, 0x1.3333333333333p-2)                   ; q = Ry(0.3)|3>
3  cq_template_icmp_eq_i32_hl(h0, 5) -> h1                  ; the FLAG, minted at the compare
4  cqrt_alloc_i32(0) -> h2                                  ; r's rail — THE SEED IS THE ARGUMENT
5  cqrt_ry_i32_controlled(h1, h2, 0x1.ccccccccccccdp-1)     ; the arm gate, controlled, in place
6  cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)                ; strip: recompute q==5, XOR back
7  cqrt_free(h1)                                            ; the flag is |0> — the ONLY free
8  cqrt_measure_i32(h2) -> 0                                ; r
9  cqrt_measure_i32(h0) -> 0                                ; q
```

Line by line. **1–2** are the ordinary source theta, untouched by this increment.
**3** is the flag mint at the branch, byte-identical to the phase path's step 1.
**4** is the whole increment: `lowerRotations` took its `!Chained` arm at the
theta's **hoisted** position, so the alloc lands *after* the flag mint — a fixed
design decision (§14.1), not an accident, and the `_negated` golden is where it
becomes visible. **5** is `cqrt_ry_<W>_controlled` where an unconditional
`cqrt_ry_<W>` would have stood: on `f=0` the rail is untouched and holds `|0⟩`,
which by **F1** is exactly the source's straight-through value of `r`; on `f=1` it
holds `Ry(0.9)|0⟩`. **6** recomputes the predicate over `h0`, which the region
never moved — and here that disjointness is **structural** (the rail was minted
inside the region) rather than R4-proved, which is the one place Inc 4 is easier
than Inc 1. **7** frees a provably-`|0⟩` flag. **8–9** read the handles: `h2`
because M-β RAUW'd the merge φ to the hoisted theta and `lowerRotations` then
RAUW'd that to the alloc handle. **There is no `cqrt_free(h2)` anywhere** — the
freeze — and no `cqrt_cswap`, no `cqrt_copy`, no work rail, no reverse-play.

### `slice_control_inplace_ry_stateprep_negated.expected.log`

Identical except lines 4–7 become

```
   cq_template_icmp_eq_i32_hl(h0, 5) -> h1
   cqrt_x(h1)                          <-- ¬flag bracket opens
   cqrt_alloc_i32(0) -> h2             <-- THE ALLOC IS INSIDE THE BRACKET
   cqrt_ry_i32_controlled(h1, h2, …)
   cqrt_x(h1)                          <-- bracket closes
```

`clang -O1` canonicalizes `!=` to `icmp eq` with the successors swapped (Rule 9),
so the gate arm is the FALSE edge. The alloc's position inside the bracket is the
§14.1 decision made visible; it is harmless physics (an allocation is
unconditional in the emitted stream and the `cqrt_x` pair flips the FLAG rail, not
the prepped one) and it is fixed here so the golden cannot drift.

### `slice_control_inplace_ry_stateprep_twin.expected.log` — and the reduction

```
1  cqrt_alloc_i32(3) -> h0
2  cqrt_ry_i32(h0, 0x1.3333333333333p-2)
3  cqrt_alloc_i32(0) -> h1
4  cqrt_ry_i32(h1, 0x0p+0)                                  <-- (i) DELETE
5  cq_template_icmp_eq_i32_hl(h0, 5) -> h2
6  cqrt_ry_i32_controlled(h2, h1, 0x1.ccccccccccccdp-1)
7  cq_template_icmp_eq_i32_hl_unc(h2, h0, 5)
8  cqrt_free(h2)
9  cqrt_measure_i32(h1) -> 0
10 cqrt_measure_i32(h0) -> 0
```

**Re-derived by hand from the two committed goldens** (no script):

* **(i)** delete line 4 — `Ry(0) = I`;
* **(ii)** move line 3 to immediately before line 6, the first controlled gate
  naming `h1` — a fresh-rail alloc acts on a wire nothing else names, so it
  commutes with every gate that does not name its handle. Order becomes
  1, 2, 5, 3, 6, 7, 8, 9, 10;
* **(iii)** renumber by first appearance: `h0→h0`, the flag (old `h2`) `→h1`,
  the prepped rail (old `h1`) `→h2`.

Result: **exactly** the flagship golden, line for line, including the measure
order. Note the twin's measures are `h1` then `h0` and the subject's are `h2` then
`h0` — the *same two rails* under the renumbering, so the reduction is complete
rather than approximate.

> **What this witness proves and what it does not.** It proves the **structure**:
> the flag comes from the same compare, the control polarity is the same, the
> strip and free are the same, the freeze applies to the same rail. It does **not**
> prove *"the fresh rail starts at |SEED⟩"*. That rests on (a) `cqrt_alloc_<W>(SEED)`
> being the same call the uncontrolled `cq_theta(SEED, θ)` mints today, pinned by
> the existing runtime goldens, and (b) **F1**. The witness deliberately does not
> share the transformation it witnesses — the twin performs a real `Ry(0)` on a
> real allocated rail and Inc 4 performs neither.
>
> **And stage 2b witnesses neither.** `free_pairing_check.py` never reads the
> alloc's seed argument, at any site, so a wrong seed is invisible to it; and the
> frozen rail lands in its "left allocated" census with no finding. Quoting a green
> 2b as evidence for this increment would be false.

**No `compare_files` twin gate was added, deliberately**: the two goldens differ
by a *reduction*, not by identity, so such a gate would assert something false.
`inc4-records/reduce_twin.py` implements the three rewrites and could become a
fourth ctest entry — recorded, not proposed (the same owner cost decision the
Inc-1 and Inc-2b instruments were given).

---

## §6 — Fixtures and the mutation table

**59 files in the family: 20 accept + 39 decline** (`ls
ir-pass/test/control_inplace_ry_stateprep_*.ll | wc -l` → 20; `…reject_stateprep_*`
→ 39). Corpus **1474 → 1531**. Two pre-existing files re-homed, two given
cross-reference headers, one file (`control_angle_select_reject_state_prep.ll`)
reused rather than duplicated as the S3 row.

**Four PRD accept rows were folded into other fixtures' headers rather than
committed as separate `.ll` files, because their `-O1` slice bodies are
byte-identical** (measured 2026-09-04; committing them would be a false coverage
claim — the DER lesson): A-4 (`else r = 0;`, differs only in a `; preds =`
comment), A-13 (`cq_measure` consumer — *is* A-1), A-24 (the `q - 5` derived-temp
fold) and A-25 (the `q * 0` identity fold) all live in
`control_inplace_ry_stateprep_diamond.ll`'s header. Two decline rows likewise:
F2-3 (`q > 4 && q < 6`) in `..._eqfold_coincidence.ll`'s and F1-7 (a global
address, which at every integer width can only appear as a `ptrtoint`
`ConstantExpr`) in `..._constexpr_seed.ll`'s.

### Mutation table

Each mutation was applied to the shipped source, **both targets rebuilt**
(`cmake --build build -j8` — never `--target CQPass` alone), the family filter
run, and the source reverted and rebuilt. ⚠ Do NOT do this while a suite is
running — see §8 F-8.

| # | mutation | fixtures that RED | verdict |
|---|---|---|---|
| **M1** | disable **F1** (all three sub-clauses) | **15** (was 12 at hand-back; +`undef_seed`, +`poison_seed`, +`unrecognized_suffix` from the round-1 review) | see the CORRECTION below — "load-bearing for all of them" over-reads |
| **M1b** | keep F1, remove the **tainted-incoming STRING SPLIT** | **4**: `nonconst_incoming`, `prep_then_prep`, `inloop_carried`, `unrolled_k2` | exactly the four files whose pred incoming is TAINTED, and no others — the split is a pure re-labelling of one sub-class (round-1, L5 F-L5-1) |
| **M2** | disable **F2** | **12**: the 7 `eqfold_*` (incl. the new `eqfold_ne_else`) + the 5 `range_*` | F2 is load-bearing for the F2 family and for nothing else — it does **not** hold up any accept |
| **M2a** | keep the plain LITERAL test, disable the **RANGE** half | **5**: exactly the 5 `range_*` files | the range half is what closes the round-1 miscompile class, and nothing else depends on it |
| **M2b** | keep the range, drop the **`fromKnownBits` intersection** | **1**: `range_knownbits` | the isolating pin for the half `computeConstantRange` alone cannot see (a `zext` is a `CastInst`, outside `setLimitsForBinOp`'s table) |
| **M2c** | restore the **`isEquality()` gate** on the range test | **1**: `range_ordered` | the isolating pin for dropping it |
| **M2d** | keep the range, disable the **FORWARD CLOSURE** (ask the singleton question of `H` only — i.e. the exact round-1 spelling) | **6**: exactly `range_forward_{add,xor,sub,or,lshr,ashr}` | ⚠ **ADDED 2026-09-05 (round-2, lens R1 F-R1-1, CONFIRMED-MISCOMPILE).** The isolating pin for the SET half of F2, and the strongest row in this table: under the mutant all six do not merely fail their `CHECK` — they **ACCEPT, exit 0** (measured, one `cq-opt` invocation each), which is the shipped silent miscompile reproduced on demand. No other fixture in the corpus moves |
| **M2e** | delete `Rel = ICmpInst::getSwappedPredicate(Rel)` | **1**: `range_constleft_ugt` | ⚠ ADDED 2026-09-05 (round-2, lens R1 F-R1-5). Before this round the deletion reddened **nothing** — `clang` puts the literal on the right, so no fixture exercised the swap. `range_constleft_eq` stays GREEN under it (an `eq` cannot discriminate a swap) and `stateprep_range_constleft_accept` stays green too, which is what makes the swap a DISCRIMINATOR rather than a blanket over-decline |
| **M2f** | delete F2's `K0 && !K1` branch (the position-free `{K, H}` selection) | **2**: `range_constleft_ugt`, `range_constleft_eq` | ⚠ ADDED 2026-09-05 (round-2). The OTHER half of the same code, and the reason both const-left fixtures ship: M2e separates the predicate swap, M2f the operand selection |
| **M3** | disable the **if/else** clause | **4**: `ifelse_two_preps`, `ifelse_diff_seeds`, `ifelse_mixed_chained`, `ifelse_mixed_phase` | the clause refuses all four; `ifelse_phase_first` stays green (it dies on the pre-existing homogeneity flag, which is the point of committing both orders) |
| **M3b** | keep the clause, print **one** string for both shapes | **2**: `ifelse_mixed_chained`, `ifelse_mixed_phase` | exactly the two files where "allocates two rails" was false (round-1, L7 F-L7-8) |
| **M4** | **M-β → M-α** (RAUW the merge to `Base` = the seed `Constant`) | **19 of 20** at hand-back | the one mutation whose failure mode is **silent**, and two fixtures catch it *only* because they assert the handle: `consumer_ret` emits `ret i32 0` and `consumer_tape` emits `printf(…, i32 0)` — the tape write disappears entirely, `opt` exit 0, verify-clean. The other 17 fail LOUDLY (`cq_measure_<sfx> operand not recognized`). `consumer_none` stays green, correctly: its merge φ has no users |
| **M5** | remove the R4/R6 **skip** (point `railWireClosure` at the `Constant`) | **5**: `seed_other_users`, `prep_then_prep`, `unrolled_k2`, `lifted_phi_after`, `two_regions` | the trap is broader than the one fixture PRD §14.5 named. ⚠ **CORRECTED 2026-09-05 (round-1, L6 F-4): the five are 3 ACCEPTS + 2 DECLINES, and the two declines do not pin the vacuity** — `prep_then_prep`/`unrolled_k2` red because region 1 starts declining on R6's string, so their `CHECK` for the F1 string fails (a STRING move). Of the three accepts, `lifted_phi_after` reds only by accident of an unrelated `icmp eq i32 %o, 0` guard. **The sole DELIBERATE pin is `seed_other_users`.** |
| **M6** | put the state-prep gate in **`UserChainedRotations`** | **0**, and **0 warnings** on all three e2e slices | the set choice is behaviour-neutral today (§3). ⚠ It does **not** establish that M-A is un-blinded by a state-prep-rooted rail; that is measured separately and the guard DOES fire (§3's correction, `..._stateprep_warn_live_record.ll`) |
| **M7** | **drop the control** from the state-prep gate (`CreateCall(Ry, …)` instead of `CreateCall(CRy, …)`) — i.e. fire the arm's rotation on BOTH branches | **29 of 29 accepts** (20 of 20 at hand-back, 28 of 28 after round 1) | the wrong-unitary mutation. Every accept carries a whole-file `NOROUTE-NOT: call void @cqrt_ry_<W>(i32 <the prepped rail>, double <the arm angle>)` naming the handle AND the angle, and every accept caught it |

> **⚠ M1's VERDICT COLUMN AT HAND-BACK — "F1 is load-bearing for all 12 and for
> NOTHING ELSE" — OVER-READ ITS OWN MEASUREMENT (round-1 review, lens L1 F-L1-4).
> A red fixture is not a prevented over-accept.** For a DIAMOND, F1's second
> sub-clause and R3 (`Routed && RotBase != Routed`) are the SAME EXPRESSION, so
> most of the family keeps declining with R3's generic string when F1 is removed.
> MEASURED, this round, by running all 15 through the F1-disabled binary and
> reading the exit code and the message:
>
> | disposition without F1 | count | files |
> |---|---|---|
> | **real ACCEPT** (a genuine prevented over-accept) | **3** | `constexpr_seed`, `runtime_seed`, **`undef_seed`** |
> | declines on **R3's generic `control flow`** (a STRING move) | **11** | `seed_mismatch`, `negzero_incoming`, `negzero_seed`, `undef_incoming`, `poison_incoming`, `poison_seed`, `nonconst_incoming`, `select_incoming`, `prep_then_prep`, `inloop_carried`, `unrolled_k2` |
> | declines LATER, in `lowerMeasures`, on a different string | **1** | `unrecognized_suffix` — and with the prepped rail unmeasured the same module ACCEPTS with a STANDING `@cq_theta_si32x` (§8 F-3) |
>
> L1 predicted "2 real flips"; the measurement says **3**, and the third is
> `undef_seed` — the file this round added, which emits
> `cqrt_alloc_i32(i32 undef)` when clause 1 is relaxed. That is the bd `xy9n`
> literal-integrity shape, and it is the one the two shipped `_incoming` fixtures'
> headers claimed to be about while not being about it.

## §7 — What was RUN, with counts (Rule 19)

* `cmake --build build -j8` — **both** `CQPass` and `cq-opt`, after every source
  edit and after every mutation revert.
* **`lit ir-pass/test` (full)**: 1493 pass / **1 fail** immediately after the
  implementation — and the one failure was `control_inplace_ry_reject_inloop_stateprep.ll`,
  whose string had moved. **Final: 1531 discovered, 1530 passed, 1 expectedly
  failed (`lowering_invert_add_i32.ll`, the pre-existing Phase-7 XFAIL), 0
  failed.** Family filter: **59 / 59 pass**.
* **Whole-corpus lowered-IR sweep, HEAD vs the pre-Inc-4 ORACLE** — 1529 `.ll`
  fixtures (the corpus at the time of the sweep; two decline fixtures were added
  after it, both measured individually) + 297 buildable e2e `.c` slices, each compared on **stdout, stderr and
  exit code**. **48 files differ; every one carries the `stateprep` name; ZERO
  pre-existing files changed.** The 18 unbuildable `.c` are the `*_lib.c`
  companion TUs of multi-file slices, which `#error` when compiled standalone.
  ⚠ **The lit half of that number is 47, not 48** (round-1 review, lenses L3 and
  L7, which re-swept independently and agreed): 47 `.ll` fixtures + 2 e2e slices =
  49 differing files in total, of which the 48 above counted the `.ll` half plus
  one. Re-measured after this round's +17 fixtures: **64 of 1548**, still all
  `stateprep`, still ZERO pre-existing (§7a).
* **`tools/inplace_twin_matrix.py --stateprep --jobs 8`** against the pre-Inc-4
  `--prep-oracle`: 297 cells. Post-4 table committed as
  `inc4-records/inplace_stateprep_post4.txt` beside the pre-4 one. **0 MISMATCH.**
* **`tools/control_flag_order_check.py`**: 1531 files, 440 control flags,
  **0 violations**.
* **`tools/free_pairing_check.py` STRICT** on all three new slices' lowered IR:
  0 violations, 0 unproven.
* **`tools/cq_opt_equivalence.py --stride 8`**: 192 of 1531 fixtures **sampled**,
  **0 mismatches**. (Sampled, not full — said so per Rule 19.)
* **`tools/golden_multiset_audit.py --all`**: 295 goldens vs HEAD — **3
  NEW-FILE, 292 UNCHANGED, 0 routes collapsed, PASS.** No shipped golden moved;
  `git status` shows zero modified `.expected.log`.
* **`tools/loop_twin_matrix.py`, TWICE, with a CONTROL** — 274 cells each:
  * the **pre-Inc-4 ORACLE plugin** against the committed pre-4 expected table:
    **GREEN, exit 0**, 186 ACCEPT-IDENTICAL / 47 DECLINE / 41 other, 15
    quarantined signatures intact, 2 boundary controls green;
  * **HEAD** against the same table: **exactly 2 deviations**, both DECLINE cells
    whose *string* moved to F1 (`m_none_rcond_none_none_none` and
    `m_ry_rprep_none_none_none`), composition otherwise IDENTICAL, **0
    TRACE-DIVERGENCE**. The expected table was updated for those two rows with a
    header block giving the reason. See §8 F-8 for the four items in the FIRST
    full-suite run that were a build race of my own making, and the control that
    proves it.
* **Full `ctest -j6`, on a QUIET build with no concurrent rebuild**:
  **327 / 327 passed, 0 failed, 437 s** (`e2e-loop-twin-matrix` 336 s of it). Run
  as Rule-19 moments 1 (Rule-13 core commit) and 5 (accept/decline predicate
  change), both of which apply. The FIRST full run reported 326/327 — see §8 F-8
  for why that one failure was my own build race and how it was proved.


### §7a — ROUND-1 FIX: what was RE-RUN, with counts

Everything in §7 is the IMPLEMENTATION's run and is left as taken. This is the
round-1 fix's own run, on the same machine, with **no concurrent rebuild** (§8
F-8's lesson: a rebuild under a running suite is a different hazard from `-j`
contention, and it can produce a false PASS as easily as a false fail).

* `cmake --build build -j8` — **both** targets, after every source edit and after
  every mutation revert.
* **`lit ir-pass/test --filter stateprep`: 76 / 76 pass** (1548 discovered).
* **`lit ir-pass/test` (full): 1548 discovered, 1547 passed, 1 EXPECTEDLY FAILED
  (`lowering_invert_add_i32.ll`, the pre-existing Phase-7 XFAIL), 0 failed**,
  37.6 s. `ctest -R ir-pass-lit` PASSED.
* **Full `ctest -j6`, on a QUIET build with no concurrent rebuild: 327 / 327
  passed, 0 failed, 497 s.** Run as Rule-19 moments 1 (a Rule-13 core commit) and
  5 (an accept/decline predicate changed), both of which apply.
* **Whole-corpus lowered-IR sweep, HEAD vs the pre-Inc-4 ORACLE, RE-RUN TWICE** —
  once before the F1 string split and once after — over all **1548** `ir-pass/test`
  fixtures, comparing **stdout, stderr AND exit code**: **64 files differ, EVERY
  ONE carries the `stateprep` name, ZERO pre-existing files changed**, both times.
  (64 = the 47 the implementation's sweep measured + the 17 files this round adds.)
  Classified: **28 accept-named + 36 decline-named, and all 64 are files the
  increment or this round ADDED** (cross-checked against `git ls-files --others`;
  the list of pre-existing differing files is EMPTY). The 12 family declines that
  do NOT differ are the ones whose string was already the oracle's.
  > **⚠ CORRECTED 2026-09-05 (round-2 Rule-13 review, lens R2 finding F-R2-2,
  > DOC-FALSE). THE COUNT (12) AND EVERY TOTAL AROUND IT ARE RIGHT; THE
  > MEMBERSHIP WAS WRONG ON 3 OF 12, AND WRONG IN THE DIRECTION THAT UNDERSTATES
  > THE INCREMENT.** The list originally read `cond_qq`, `sunk_arith`, `switch`,
  > `nested`, `stray_op`, `fanout`, `two_gates`, `theta_phi_arm`, `tainted_angle`,
  > `sharecond`, `stalecond`, `rz_prep`. Three of those DO differ — Inc 4 moved
  > them, because recognising a classical-arg-0 arm theta carries the
  > classification PAST the generic `control flow` into a more specific
  > pre-existing clause:
  >
  > | file | ORACLE | HEAD |
  > |---|---|---|
  > | `..._cond_qq.ll` | `control flow` | `no template for opcode 'icmp i1' in tainted context` |
  > | `..._tainted_angle.ll` | `control flow` | `rotation angle` |
  > | `..._sharecond.ll` | `control flow` | `rotation arm shares the condition flag` |
  >
  > and three that genuinely do NOT differ were omitted: `..._compound_cond.ll`,
  > `..._fcmp_oeq_unfolded.ll`, `..._unfolded_twin.ll`. The corrected
  > non-differing twelve are: `sunk_arith`, `switch`, `nested`, `stray_op`,
  > `fanout`, `two_gates`, `theta_phi_arm`, `stalecond`, `rz_prep`,
  > `compound_cond`, `fcmp_oeq_unfolded`, `unfolded_twin`. The sentence's own
  > conclusion — "pre-existing clauses this increment does not touch" — is TRUE of
  > those twelve and was FALSE of the three it wrongly named.
* **`tools/inplace_twin_matrix.py --stateprep --prep-oracle <pre-4>` RE-RUN: 297
  cells, ZERO moved.** Data rows byte-identical to the committed post-4 table
  (modulo trailing whitespace); same tally 130 IDENTICAL / 85
  SUBJECT-DECLINES-TWIN-ACCEPTS / 40 DECLINE-BOTH / 31 DECLINE-BOTH-DIFF / 11
  SUBJECT-ACCEPTS-TWIN-DECLINES. The file is annotated, not regenerated — see its
  own header for why the zero is EXPECTED rather than a null result.
* **`ctest -R '^e2e-loop-twin-matrix$'`: PASSED, 194.5 s**, against the expected
  table with its two REGENERATED rows (274 cells, 15 quarantined signatures, 2
  boundary controls).
* **`tools/control_flag_order_check.py`**: 1548 files, **451** control flags,
  **0 violations**.
* **`tools/golden_multiset_audit.py --all`**: 295 goldens — 3 NEW-FILE, 292
  UNCHANGED, 0 routes collapsed, **PASS**. No shipped golden moved and `git status`
  shows zero modified `.expected.log`.
* **`tools/cq_opt_equivalence.py --stride 8`**: **194 of 1548 fixtures SAMPLED**,
  0 mismatches. (Sampled, not full — said so per Rule 19.)
* **The three L7 INJECTIONS re-run over all 28 accepts, on copies of the LOWERED
  output**: an `_controlled_inv` after the flag's free, a dirty `cqrt_free` of the
  prepped rail, and a `cqrt_cswap` after the free. **28 / 28 caught, on all
  three** — against 0 / 20 for the first injection at hand-back.
* **The mutation table, re-run in full** — see §6. Nine mutations, each with its
  own build of BOTH targets and its own revert.

### §7b — ROUND-2 FIX: what was RE-RUN, with counts

Same machine, no concurrent rebuild, every figure measured on the binary named.

* `cmake --build build -j8` — **both** targets, after every source edit and after
  every mutation revert.
* **`lit ir-pass/test --filter stateprep`: 85 / 85 pass.**
* **`lit ir-pass/test` (full): 1557 discovered, 1556 passed, 1 EXPECTEDLY FAILED
  (`lowering_invert_add_i32.ll`), 0 failed**, 46.3 s.
* **`ctest -R 'ir-pass-lit|stateprep|^e2e-loop-twin' -j6`: 6 / 6 PASSED** —
  `ir-pass-lit` 36.8 s, the three state-prep slices, `e2e-loop-twin-matrix`
  438.8 s (long because the `--stateprep` matrix was running beside it; the
  quiet-box figure is ~195 s) and `e2e-loop-twin-quarantine-selftest` 0.28 s.
  **`tools/loop_twin_matrix.expected.txt` did NOT move this round** — no row was
  regenerated, which is the expected result: this round changed only F2's SET,
  and the loop matrix has no cell with a tainted `op constant` user of the
  compare's operand.
* **Full `ctest -j6`, on a quiet build with no concurrent rebuild: 327 / 327
  passed, 0 failed, 358 s.** Rule-19 moments 1 and 5 both apply (a Rule-13 core
  change AND an accept/decline predicate change), so this is mandatory, not a
  judgement call.
* **Whole-corpus lowered-IR sweep, HEAD vs the pre-Inc-4 ORACLE**, all **1557**
  `ir-pass/test` fixtures, comparing stdout, stderr AND exit code:
  **73 files differ, EVERY ONE carries the `stateprep` name, ZERO pre-existing
  files changed** (checked mechanically — `git cat-file -e 8eb6f4c:<path>` fails
  for all 73). **29 accept-named + 44 decline-named**; 73 = the round-1 64 + this
  round's 9. The **12** family declines that do not differ are EXACTLY the
  corrected §7a list, which is how that correction was verified rather than
  copied.
* **`tools/inplace_twin_matrix.py --stateprep --prep-oracle <pre-4>` RE-RUN: 297
  cells, ZERO moved** — all 297 data rows `diff`-EMPTY against the committed
  `inplace_stateprep_post4.txt`, same tally 130 / 85 / 40 / 31 / 11. Annotated,
  not regenerated, **and the record now says WHY the zero is structural**: the
  generator's condition register is a bare theta result with no `BinaryOperator`
  user, so the forward closure has depth 0 in every cell. **That axis is blind to
  F-R1-1 by construction** — the six reproducers had to come from plain C.
* **`tools/control_flag_order_check.py`**: 1557 files, **452** control flags,
  **0 violations**.
* **`tools/golden_multiset_audit.py --all`**: 295 goldens — 3 NEW-FILE, 292
  UNCHANGED, 0 routes collapsed, **PASS**. No shipped golden moved.
* **`tools/cq_opt_equivalence.py --stride 8`**: **195 of 1557 SAMPLED**, 0
  mismatches. (Sampled, said so.)
* **The injection family re-run over all 29 accepts, on copies of the lowered
  output: 29 / 29 caught on all FIVE** — L7's three (`_controlled_inv` after the
  flag's free, a dirty `cqrt_free` of the prepped rail, a `cqrt_cswap`), R2's
  fourth (a standing `@cq_theta_si32` call, which was **27 / 28** before F-R2-1's
  one-line fix) and M7 (the arm gate made unconditional at the same angle).
  > ⚠ **THE HARNESS ITSELF NEEDED A CONTROL, AND TWO EARLIER SPELLINGS OF IT LIED
  > IN BOTH DIRECTIONS.** (1) Appending a `declare void @cqrt_cswap(...)` so the
  > injected module would be well-formed makes a bare `NOROUTE-NOT: cqrt_cswap`
  > fire on the DECLARE — every injection then reads "caught" for the wrong
  > reason; FileCheck is a TEXT matcher and never parses the IR, so the shipped
  > harness adds no declaration at all. (2) `..._warn_live_record.ll` carries a
  > prefix run against STDERR, which can never pass against a stdout capture and
  > read as a permanent catch. The harness now runs every prefix on the CLEAN
  > lowered IR first and scores only the prefixes that pass there — **the
  > baseline IS the control**, and it excluded exactly one prefix (`WARN`).
  > `$S/fix2/inject_all3.py`; an identity witness must not share the
  > transformation it witnesses.
* **The mutation table gains three rows** — M2d (the forward walk), M2e (the
  predicate swap), M2f (the position-free operand selection). See §6.

---

## §8 — Findings made while building

Every item below is a place the shipped code or a measurement **disagrees with
PRD §14**. Each is corrected in the PRD in place with a dated `CORRECTED` note.

### F-1 — THE HEADLINE. `clang -O1` sinks post-region ops INTO the arm, for this arm class only

`int r = 0; if (q == 5) r = cq_theta(0, .9); int s = r * 3;` **declines**.

The straight-through value of a state-prepped register is a compile-time
**constant**, so on that edge `r * 3` folds to `0`, the op has exactly one live
use left — inside the arm — and `-O1` sinks it there. The module the pass sees is

```
arm:   %rt = call cq_theta_si32(i32 0, .9)
       %rs = mul nsw i32 %rt, 3            <-- SUNK
merge: %rm = phi [ %rs, %arm ], [ 0, %entry ]
```

which is not the §14.1 accept shape: the merge's arm incoming is the `mul`, and
the arm block holds two instructions. R1's shape half refuses it.

**The CHAINED twin is immune** — its straight-through value is a live *register*,
nothing folds, and the op stays after the merge — **which is exactly why the
pre-implementation probe family could not see it.** The probes could measure that
the diamond survives `-O1` for each consumer; they could not measure what `-O1`
does to the *arm* once the region became lowerable.

Measured as **48 of the 297** `--stateprep` matrix cells reading
`SUBJECT-DECLINES-TWIN-ACCEPTS` with the `control flow` message — 12 each of
`mul3`, `spine`, `deadadd`, `deadmul` — **plus 3 more** (`printf` at i8/i64/f64,
where the sunk op is the `(int)` cast and the string is `value-arm swap-route`;
`printf_i32` needs no cast and reads IDENTICAL — the control that makes this a
characterization and not a guess).

> **⚠ CORRECTED 2026-09-05 (round-1 review, lens L7 F-L7-4): NOT "across every
> cfg/cond/width".** Re-counted from the committed post-4 table BY MESSAGE: the 48
> sit at cfg `diamond` (40), `clsbefore` (4) and `negated` (4). **`clsbetween`
> contributes ZERO** — all four of its arithmetic cells read IDENTICAL — and that
> is the **POSITIVE CONTROL FOR THE MECHANISM**, not an exception to it: a second
> region between the prep and the op makes `r`'s straight-through value
> NON-CONSTANT, so nothing folds and nothing sinks. It is the chained twin's
> discriminator reached a different way. The four `ifelse` arithmetic cells do
> decline, but on `rotation angle` (the angle-select S3 route), so they are not
> members of this class either. The number 48 is right; the quantifier was wrong,
> and it was hiding the one cfg that demonstrates the class's own boundary.

**PRD §14.12 worry 8 predicted this exactly.** Shipped: a decline, pinned by
`control_inplace_ry_reject_stateprep_sunk_arith.ll`; PRD §14.3 rows **A-15** and
**A-18** corrected; the two hand-IR fixtures that assert the post-merge shape
(`..._consumer_add.ll`, `..._consumer_none.ll`) now say in their headers that they
are hand IR and why. **OWNER QUESTION, recorded as PRD §14.13's Q7**: supporting
`arm = {state-prep theta, value-op chain}` is a NEW CAPABILITY (a value arm whose
base is minted inside the arm), and F1 would have to read *"the Pred incoming is
the arm's op chain CONST-FOLDED over the seed"* rather than *"the Pred incoming IS
the seed"* — a constant-folding obligation inside a fence, with its own soundness
argument about what the chain may contain, and it re-opens F2's question one level
down (the folded chain result could coincide with the compare literal). It is not
a fence relaxation and it was not attempted here. The user-visible cost today is
that any arithmetic on a state-prepped register in the same function declines; the
workaround is to make the register's straight-through value non-constant, i.e. to
write the CHAINED spelling `int r = cq_theta(SEED, 0.0);` — which is exactly the
manual twin, and which compiles.

### F-2 — PRD §14.3 row A-12 (Q+Q condition) is an ACCEPT in the PRD and a DECLINE in fact

`if (q == p) r = cq_theta(0, .9);` declines `no template for opcode 'icmp i1' in
tainted context`. §14's ground — "F2 needs a `ConstantInt` operand and a Q+Q
compare has none" — is TRUE and is not the operative clause: the in-place rotation
emitter mints its flag with `lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, …)`,
i.e. with **no Q+Q width**, so the tainted `icmp` falls through to `lowerOps`.

**PRE-EXISTING and arm-class-independent** — the CHAINED twin declines with the
identical string on the pre-Inc-4 **oracle** and on this binary (measured,
`$S/impl/probe/qq_chained.ll`). Inc 4 neither introduced nor widened it. Pinned as
`control_inplace_ry_reject_stateprep_cond_qq.ll`; the fix belongs to the emitter's
flag mint, not to F1/F2. Reported for the owner as a separate item.

### F-3 — F1's third clause is REACHABLE, LOAD-BEARING, and now has its fixture

> **⚠ THIS SECTION IS A RETRACTION, WRITTEN 2026-09-05 BY THE ROUND-1 RULE-13
> REVIEW (lens L1, finding F-L1-1). What it said at hand-back was:** *"F1's third
> clause is STRUCTURALLY UNREACHABLE, not 'hand-IR-only reachable' …
> `declMatchesPrototype` already requires `FT->getParamType(0) ==
> typeForAbiWidth(suffix)` … and the LLVM verifier then forces a call's argument to
> match its parameter type. So the seed's type always equals the name-derived
> width's type. The clause ships as defence in depth … no fixture can be written
> for it, and none was."* **Both the verdict and the mechanism were wrong, and the
> PRD's ORIGINAL wording — "one line, hand-IR-only reachability" — was right.**

**The mechanism.** "The LLVM verifier forces a call's argument to match its
parameter type" is FALSE: LLVM 19 **parses and verifies** a call whose
`FunctionType` differs from its callee's (`opt -passes=verify` exit 0, measured).
What blocks that route is `CallBase::getCalledFunction()`, which returns **null**
in exactly that case, so `isThetaCall` is false and the pass never sees a theta at
all. `declMatchesPrototype` is real and still closes the `fp128` route; it simply
never gets asked about a name it does not recognize.

**The reachable route is an UNRECOGNIZED SUFFIX, and it is the sibling-spelling
shape this project keeps finding.** `isThetaCall` is a bare NAME-PREFIX test
(`starts_with("cq_theta_")`) while `resolveSources` loops `wd.allSuffixes()` — its
own comment says an unrecognized suffix *"stays out of collection — and validation
— entirely"*. So `@cq_theta_si32x(i32 0, double)` IS a theta to the classifier and
has NO width: `abiWidthFor("si32x")` is `""`, `llvmWidthType("")` is null, and the
clause fires on its `!SeedTy` half.

**It is LOAD-BEARING.** `taint.ThetaCalls` is populated only from `ThetaFns`, so an
unrecognized-suffix theta is **never lowered**. Without the clause the module
ACCEPTS (R3 passes by uniqued-constant identity, the `!StatePrep` taint check is
skipped, R4/R6 are skipped, and the detection width gate asks the OTHER derivation
`abiWidthFromType`, which answers `i32`), the emitter hoists and flattens, and the
module keeps a STANDING `@cq_theta_si32x` inside a flattened region wrapped in a
flag mint/strip/free around nothing. The CHAINED sibling of the same shape is
caught elsewhere (`cq taint escape: tainted value consumed by an unknown callee`)
precisely BECAUSE its arg-0 is tainted; a state prep's arg-0 is a constant, so the
escape guard is silent and clause 3 is the only thing left.

**MEASURED, not argued.** The clause was disabled and both targets rebuilt:

* the SHIPPED fixture (which measures the prepped rail) → exit 1, but with a
  **different and much later** string,
  `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` — the
  merge value is the un-lowered theta's result, so the failure lands in
  `lowerMeasures` rather than in detection;
* the same module with the prepped rail **NOT** measured → **exit 0**, and the
  emitted module carries `%rt = call i32 @cq_theta_si32x(i32 0, double 9.0e-01)`
  — a STANDING `@cq_theta_*` — bracketed by `cq_template_icmp_eq_i32_hl`, its
  `_unc` strip and `cqrt_free`: **a flag minted, stripped and freed around
  nothing.** That module is what "load-bearing" means.

**RED-GREEN, and it is a one-token pair:**
`control_inplace_ry_reject_stateprep_unrecognized_suffix.ll` (decline) and
`control_inplace_ry_stateprep_suffix_control.ll` (accept), differing only in
`si32x` → `si32`. Both declarations are present in both files.

**AND THE FOUR WIDTH FIXTURES NEVER PINNED THIS CLAUSE** (round-1 review, lens L4
finding F-L4-2). `control_inplace_ry_stateprep_{i1,i8,i16,i64}.ll` all claimed to;
deleting the clause outright leaves all four GREEN, because on every input they
present the seed's type already equals the name-derived width's type, so the
clause is a no-op there. Their headers now say what they DO pin — `lowerRotations`'
name-derived alloc/gate symbol and the alloc's POSITION, at that width — and their
second stale claim ("before Inc 4 those two were never cross-checked at all") is
struck: `declMatchesPrototype` has done it since long before Inc 4.

### F-4 — three §14.3 decline rows print a different string than predicted, and all three are PRE-EXISTING

* **F2-8** (`p08s`, the unfolded twin) and **FP-1** (`fcmp oeq`) print
  `condition predates a non-diagonal gate`, not R4's `rotation arm on a condition
  wire`. Reason: in both, the arm's own theta **is** the non-diagonal gate on the
  condition's provenance wire, so `condWireDisposition` adjudicates before the
  rotation clause runs and `declineArm` re-spells. **There is no unmasking move,
  because the masking gate is the arm itself.** Measured identical on the oracle.
* **IE-3 / IE-4** (if/else with different seeds; prep beside a chained arm) print
  `if/else state prep allocates two rails`, not `impure phase arm`. `impure phase
  arm` is what the **oracle** prints, because there the classical-seed theta was
  not a rotation arm and the region fell through to the if/else leaf-anchor path.
  After Inc 4 the arm is recognized, so the if/else clause adjudicates first and
  the message names the real defect. A decline either way; the **clause** moved,
  so the string moved.
* **IE-5** (prep beside a phase arm) prints the if/else string when the prep arm
  is processed first and `mixed phase/value arm` when the phase arm is. **Both
  orders are committed** (`..._ifelse_mixed_phase.ll` and
  `..._ifelse_phase_first.ll`) because a reader who saw only one would conclude
  the fence is the other one — the Inc-1 `SawRotationArm` lesson ("luck is not a
  fence") run in the other direction.

### F-5 — two accept rows are hand-IR-only, and now say so

`A-15` (dtzb `r + 1`) and `A-18` (no consumer) name probes `p13c` and `p13g`, and
neither probe produces the fixture's module. `p13c` is F-1's sunk `add`. `p13g` has
`r` genuinely dead, so `-O1` **deletes the merge φ outright** and no
`BranchRegion` forms at all — for **both** arm classes (matrix cell
`sp_s0_eq_diamond_none_i32` reads DECLINE-BOTH before and after). The two fixtures
are kept, because each exercises a real code path a caller-supplied `.ll` can
present (M-C's in-place decision on a controlled-root rail; the spine's behaviour
on a live φ with no consumer), but their headers now state that they are hand IR
and what the C program does instead.

### F-6 — `p13b` (`return r;`) accepts in `slice` and declines in the probe's `main`

Worth recording because it looks like a regression and is not: the probe's
`main` calls `slice()` and discards the result, so after inlining `r` is dead in
`main` and that copy hits F-5's deleted-φ shape. At HEAD the diagnostic names
`main`; on the oracle it named `slice`, because there both declined. The
consumer-`ret` capability is real (`..._consumer_ret.ll`).

### F-6b — F2 also fires on a DERIVED condition register, and that is not in §14's prose

Measured from plain C: `int r = 2; if ((q & 6) == 2) r = cq_theta(q & 6, .9);`
folds to an arm seeded with the compare literal `2` against an `icmp eq %and, 2`,
and declines on F2. The register F2 is protecting there is **`%and`**, a rail the
flag mint's own template chain creates — not `q`. §14.2b's spelling ("a TAINTED
operand and a `ConstantInt` k") already covers it; its *prose* reads as if the
question were about the register the user compared. Committed as
`control_inplace_ry_reject_stateprep_eqfold_derived_cond.ll`, deliberately paired
with `control_inplace_ry_stateprep_cond_derived.ll` — the same condition with seed
`0`, which ACCEPTS — so the discriminator is visible as a VALUE test (0 ≠ 2 there,
2 = 2 here) rather than a shape test.

### F-7 — the 11 `!!` matrix cells are an ABSENT ORACLE, not a divergence

All 11 are the `value2` consumer, which adds a second region that `-O1` collapses
into a tainted-condition `select`. The chained twin declines `control flow` **at
that select** (source line 8, confirmed with `-g`) on **both** binaries, so the
matrix has no reference for those cells. The subject's emitted circuit was read
line by line and is the ordinary 4.4 controlled-XOR copy merge over the prepped
rail (a fresh `out` rail, one `cqrt_copy_i32_controlled` under the flag, one
`cqrt_x`-bracketed copy under the negation, strip, free). Recorded rather than
suppressed; the matrix table's header carries the same note.

> **⚠ STRENGTHENED 2026-09-05 (round-1 Rule-13 review, lens L3 findings F-4 and
> F-5). A PARTIAL ORACLE DOES EXIST, and the twin's decline has a NAME.**
>
> * **The oracle.** `int cq0 = cq_theta(3,0.5); int r = cq_theta(0, 0.9);
>   int cz = cq_theta(4,0.6); if (cz == 4) { r = r + 3; }` — an ORDINARY SOURCE
>   RAIL carrying the same `Ry(0.9)`, then the IDENTICAL second region — **lowers
>   on BOTH binaries** (exit 0, strict 2b `2 verified, 0/0`), and its region-2
>   suffix is **BYTE-IDENTICAL to the subject's, 11 lines, after handle
>   normalisation** (measured; the diff is empty). So the half that was
>   unwitnessed — *does the 4.4 copy-merge emit the right stream over a rail whose
>   root is a controlled gate?* — is now a MEASUREMENT rather than a hand reading.
>   What it still does not witness is the FIRST region, which the flagship golden
>   already owns. It costs one slice to commit and is recorded, not proposed.
> * **The twin's decline is `SelectClassify` GATE 5, and it has nothing to do with
>   the region.** Isolated by bisection: the same program with **no control region
>   at all** (`int r = cq_theta(0,0.0); r = cq_theta(r,0.9);` then the select)
>   declines identically on both binaries. The clause is
>   `hasCoherentDownstreamUse`: `rotationAncestry(Op)` stops at the `add`, so when
>   `Op` is the DERIVED operand `r+3` the operand's own producing chained Ry is not
>   in `Ancestry` and is reported as "a rotation ON a wire of the lineage —
>   coherent". The state-prep subject evades it only because F1 collapses the rail
>   to ONE SSA name (the arm theta), leaving no rotation call whose arg-0 is a
>   tainted lineage member. **This matters for the record: an unexplained twin
>   decline is exactly where "the oracle is absent" turns into "the oracle
>   disagrees", and here it is provably the former** — a known gate-5 over-decline.

---

### F-8 — four of the first full suite's six loop-matrix items were MY OWN BUILD RACE

Recorded because it cost an hour and because the failure mode is indistinguishable
from a real finding at first read. The first full `ctest -j6` (616 s) overlapped
the mutation-table rebuilds (M4–M7), which swap `build/ir-pass/cq-opt` in and out;
`e2e-loop-twin-matrix` compiles a cell's two sides as separate processes, so some
cells got **two different binaries**. The tell is unmistakable in hindsight:
`m_none_rzry_none_none_rypost` reported `rolled: cqrt_ry_i32_controlled(…)` vs
`unrolled: cqrt_ry_i32(…)`, which is **exactly mutation M7** (drop the control)
applied to one side only.

Proved, two independent ways:

* both implicated cells' EXACT sources, regenerated from the tool's own
  `sources()`, lower to **byte-identical** IR on HEAD and on the pre-Inc-4 oracle
  (`rzry/rolled`, `rzry/unrolled`, `oder/rolled`, `oder/unrolled`);
* the whole 274-cell matrix run against the **oracle plugin** is GREEN against the
  committed table, with the same composition (186/47/41, 15 quarantined, 2
  controls) as the clean HEAD re-run.

**Lesson: never run mutation rebuilds concurrently with a suite.** The suite is
embarrassingly parallel *within itself* — the tree has zero `RUN_SERIAL` /
`RESOURCE_LOCK` properties — but nothing protects it from a build mutating its own
compiler underneath it. CLAUDE.md's "contention causes false FAILURES, never false
passes" is about `-j` contention; a concurrent *rebuild* is a different hazard and
it can, in principle, produce a false PASS as easily as a false fail.

---

## §9 — What worries me

> **⚠ RE-READ THIS SECTION WITH §10 AND §11.** The round-1 Rule-13 review turned
> worry 2 into a CONFIRMED SILENT MISCOMPILE (F2 was incomplete on the `ne` edge)
> and worry 8 into three new accept classes nothing had pinned. **The round-2
> review then turned worry 9 — the one written as "the honest replacement for
> worry 2" — into a SECOND confirmed silent miscompile**, because it described
> the residual as *"instcombine deleted the register AND rewrote the compare onto
> an ancestor"* when the rewrite ALWAYS happens and the deletion only sometimes
> does; six plain-C programs sat in the half the sentence had merged away.
> **A worry that names a boundary wrongly is worse than no worry at all: it makes
> the next reader stop looking.** Worries 1, 4, 5 and 6 are unchanged and are the
> ones to budget a third round against; 9 is rewritten below and 13–16 are new.
>
> **⚠ AND NOW READ IT WITH §12 TOO. The round-3 review turned item 14 — the one
> that named the forward closure's own holes — into THREE confirmed silent
> miscompiles, 42 plain-C programs, and it found all three in the half item 14
> did not name: not the casts and not the φ/`select` it worried about, but the
> walk's DIRECTION, its OPCODE CLASS, and a TYPE GATE one line above its
> caller that could delete every decline the block would make.** Item 13's
> narrowed residual is narrowed again (§12.2, `n03_k03_derived`), item 14 is
> superseded by the semantic form, and 17–20 are new. The standing lesson,
> three rounds running: **a worry that enumerates what a syntactic fence misses
> is itself a syntactic enumeration.**



1. **The increment's headline finding is an OVER-DECLINE the probe family was
   structurally unable to see, and the same blind spot may still be open.** F-1
   exists because the state-prep source's straight-through value is a *constant*,
   which lets `-O1` do things to the arm that it cannot do to the chained twin.
   Every measurement in PRD §14 that used the chained twin as its reference
   inherits that asymmetry. I found the arithmetic-sink family because the twin
   matrix has an arithmetic-consumer axis; I have **no argument** that the axis is
   complete. What else does `-O1` do differently when a merge incoming is a
   compile-time constant? I do not know, and the honest position is that lens 2's
   job is now bigger than §14.10 scoped it.

2. **F2 is a fence on a syntactic coincidence and I still cannot prove it
   complete.** Its soundness argument — "on an eq/ne diamond exactly one edge
   proves the equality, and F1 collapses both readings to `seed == k`" — is
   airtight for the shapes measured, and the `fcmp oeq` candidate is measured
   **closed** (LLVM will not substitute across `oeq`, because `oeq` is not a
   bitwise-equality proof). That removes the suspect I had and leaves me without
   one, which is a *worse* position than having a named suspect. What is not proved
   is that `-O1` never produces a folded arm seed **without** an equality compare
   surviving to the pass. `p08s` shows the fold is not even deterministic across
   equivalent sources.

3. **The accept is DIAMOND-only through a clause that fires by ABSENCE.** F1 needs
   a Pred edge and an if/else has none. I added the explicit if/else clause so the
   decline is findable, but the general shape — "this accept class is bounded by a
   clause that cannot be satisfied rather than by one that refuses" — is how a
   later widener removes a bound without noticing there was one. The if/else clause
   is `Arms.size() > 1`, which is exactly the kind of test someone deletes while
   "generalizing to if/else".

4. **The witness is a REDUCTION, and it is weaker than what Inc 1 had.** The
   `--stateprep` pool compares the subject against a *reduced* chained twin, so a
   defect in the reduction — or one shared by subject and twin — is invisible, and
   unlike the Rz-arm pool there is no second, independently-lowered spelling to
   fall back on. It is also **not a ctest entry**, so nothing re-runs it. I ran it
   twice (pre-4 by the probe agent, post-4 here); nobody will run it a third time
   unless a reviewer does.

5. **I am relying on R4/R6 being SKIPPED, not on them being safe.** Mutation M5
   shows the trap reaches five fixtures, not the one PRD §14.5 named. I have not
   audited every other place that might come to hold a `Constant` in a rail-shaped
   slot now that `Region.RoutedBase` can be one — I checked the readers I could
   enumerate from `grep`, and the 8h7d.5 lesson is that VALUE-fed set walkers do
   not show up in a name grep.

6. **The `-O1` shape of every fixture is one observed output.** A clang or
   pipeline change moves the IR under all 59, and the ones that would go silently
   *wrong* rather than red are the F2 declines: a shape that stops folding stops
   being ambiguous and starts declining on the condition-wire fence instead, with a
   different string — which reads as a pass, not a failure.

7. **F2's priced over-decline is a real capability loss and it is silent to the
   user's intuition.** `int r = 5; if (q == 5) r = cq_theta(5, .9);` is a
   well-formed state prep and it declines. The workaround is one character, but
   nothing in the diagnostic tells the author *which* character; the message names
   the physics ("proven equal to the condition register") for a program whose
   author never mentioned the condition register. I could not do better without
   naming a compiler internal in a user-facing string.

8. **The three e2e goldens are the only place the emitted stream is executed, and
   they cover ONE consumer between them.** `measure` (twice) and, in the twin, the
   same. The `ret`, `tape`, `add`, `join-φ` and `two-region` consumers are pinned
   at the lit layer only — which does not LINK, and linking is the layer that
   proves every emitted symbol resolves and signature-matches.

9. **F2 IS NOT COMPLETE AND NOW HAS A NAMED BOUNDARY RATHER THAN A SUSPECT
   (round-1, lens L2 — ⚠ **and this item as written was itself a defect; read the
   round-2 correction under item 13 before quoting any of it**).** The range spelling closes every member where the pinned
   register SURVIVES in the IR. It cannot close the members where instcombine
   DELETED the register and rewrote the compare onto an ancestor — measured on
   five plain-C programs, one of which (`int b = (q!=5); int r = 0; if (q==5) r =
   cq_theta(b, .9);`) has a `@slice` body **BYTE-IDENTICAL to the flagship
   slice's**. Every alternative source in that class is a data MUX that CQ refuses
   whenever the register survives (measured: keep `b` live and the program
   declines `condition data use neither escaped nor measured` on BOTH binaries),
   so the residual is *"a program whose correct disposition is a decline for a
   Rule-8 reason, made indistinguishable from the accept class by a fold that
   deleted the evidence"*. That is PRD §14.11 Q3's shape, and the only fence that
   reaches it is Q3's option (b), which kills the flagship. **This is the honest
   replacement for worry 2's "I am left without a suspect": the suspect is the
   FOLD, and it is not fenceable at the IR level.**

10. **O1 — A POST-REGION RECORD READ PAST A POST-REGION IN-PLACE GATE ACCEPTS, IT
   IS REGION-INDEPENDENT, AND INC 4 ADDS A POPULATION TO IT (round-1, lens L5).**
   `int mark = r; r = cq_theta(r, .4); measure(mark); measure(r);` after a state
   prep emits `cqrt_ry_i32(h2,.4); measure(h2); measure(h2)` — both measures on
   the POST-rotation register. **This is not an Inc-4 defect**: the chained twin
   does the same on the pre-Inc-4 ORACLE, and so does a program with **no control
   region at all**. `ArmClassify`'s R6 covers the PRE-region record; nothing in
   the flat path fences a POST-region one when the reader is a sink. It is
   recorded because bd `8h7d.5` graded exactly this shape a CONFIRMED silent
   miscompile in the LOOP path and fenced it there
   (`LoopLowering::staleRailRecordRead`). Inc 4 adds a NEW POPULATION — a rail
   whose root is a controlled gate — to that known flat posture (the bd `0njv`
   class). **Owner glance, not an Inc-4 blocker, and it must not be "fixed" by
   narrowing this increment.**

11. **THE PLAIN-C R4 MESSAGE IS PINNED BY A CELL OF AN INSTRUMENT, NOT BY A
   FIXTURE (round-1, lens L5).** The whole R4 fixture family is hand IR with a
   TAINTED arm arg-0 and prints byte-identically on both binaries (measured 5/5),
   so the only place in the tree that pins what the `-O1`-folded plain-C R4
   program prints is `tools/loop_twin_matrix.expected.txt`'s
   `m_none_rcond_none_none_none` row — an instrument, which is not itself a
   Rule-12 fixture. The string split in this round makes that row *more* correct
   and does not close the gap.

12. **THE `--stateprep` MATRIX STILL IS NOT A ctest ENTRY, AND THIS ROUND MADE
   THAT WORSE, NOT BETTER.** Worry 4 already said nobody re-runs it. It now
   carries the post-round-1 dispositions as well, which means a future regression
   in F2's range clause or in the if/else string would move cells that no gate
   reads. The same is true of `tools/inplace_twin_matrix.py`'s `--stateprep` pool
   and of `inc4-records/reduce_twin.py`. All three remain recorded instruments
   pending the owner's cost decision — the Inc-1/Inc-2b precedent — but the
   surface they cover has grown.

13. **⚠ ITEM 9's BOUNDARY WAS DRAWN IN THE WRONG PLACE, AND HALF OF WHAT IT
   CALLED "RESIDUAL" WAS A LIVE MISCOMPILE (round-2, lens R1 F-R1-1).** It said
   F2 cannot close the members where instcombine *"DELETED the register **and**
   rewrote the compare onto an ancestor"*. Those are two independent events: the
   rewrite **always** happens in this family and the deletion only **sometimes**
   does. Six plain-C programs were in the "rewrite, no deletion" half — the
   register ALIVE, lowered to a rail, MEASURED by the source, and never rotated —
   and every one accepted. They are now fenced by F2's forward closure. **What
   remains is only the deleted-register half**, and it is bounded: a register is
   deleted only when nothing reads it, so the difference is a leaked ancilla no
   `cq_measure`/`ret`/tape write observes (PRD §14.11 Q3, and the argument
   explicitly does NOT extend to the fenced six). The lesson for the next round is
   the sentence, not the fix: **a boundary stated as a conjunction hides whichever
   conjunct is not always true.**

   > **⚠ CORRECTED 2026-09-05 (round-3, lens R3 finding F-R3-4). THE
   > BOUNDEDNESS ARGUMENT ABOVE HAS A MEASURED COUNTEREXAMPLE AND MUST BE READ
   > WITH ITS NARROWING.** `n03_k03_derived` is `k03` plus one line
   > (`unsigned z = s*2u;` after the region). `-O1` rewrites `s*2` into
   > `(q>>30)&2` and deletes `s`, so the *register* still has no reader — but a
   > value **derived from it is measured**, from an UNROTATED derivation. The
   > sentence is therefore *"…confined to a leaked ancilla **when no value
   > derived from the deleted register is observed either**"*, and §12.2 is the
   > final boundary statement with all eight members re-measured. **NEW
   > MEASUREMENT:** `n03`'s UNFOLDED twin declines on BOTH binaries with
   > `cq opcode lowering: operand predates a non-diagonal gate`, so the class is
   > reachable ONLY through the fold — the Inc-2b F-11 structure. It stays
   > filed at Q3, not fenced.

14. **THE FORWARD CLOSURE HAS ITS OWN NAMED HOLES AND I CAN ONLY BOUND TWO OF
   THEM.** ⚠ **SUPERSEDED 2026-09-05 (round 3): the forward closure IS GONE, and
   the three holes round 3 found were none of the ones named here — read §12
   first. This item is kept because its FAILURE is the lesson: it enumerated
   what a syntactic fence was missing, which is itself a syntactic enumeration,
   and the three real holes (direction, opcode class, and a type gate ABOVE the
   walk) were outside it. Its half-(b) — the `fromKnownBits` hull — IS now
   fixed (F-R3-9), and its half-(c) — the unpinned bound — is replaced by a
   step cap that is equally unpinned (item 19).** (a) It does not follow **casts** or **φ/`select`**, each for a written
   reason (a cast is a different physical wire; a φ result is a fresh merged
   register under CQ) — but those are arguments about what CQ *would* lower, not
   proofs that `-O1` cannot fold a seed through one into an ambiguity I have not
   imagined. (b) `ConstantRange::fromKnownBits` is a HULL, so `and q,4` reads
   `[0,5)` and its real `{4}` pin is missed (F-R1-3, measured accepting in hand
   IR); it is unreachable from plain C **only because IPSCCP's lattice has the
   same weakness**, i.e. the safety is a coincidence of two analyses failing
   together and a single LLVM change retires it. (c) The **bound** (depth 8 / 64
   values) declines when exceeded, which is safe but untested by any fixture — no
   reachable program gets near it, so nothing pins the bound's behaviour.
   **MEASURED in §11.2: every customer is at depth 1**, because `-O1` folds the
   arm's operand only when the arm's USE of it is edge-dominated, and a longer
   chain gets hoisted into the entry block where the edge fact does not reach it
   (depth-2 and depth-3 probes do not fold at all and decline `control flow` on
   BOTH binaries). So depths 2–8 are budget nobody has spent.

15. **THE `--stateprep` MATRIX IS STRUCTURALLY BLIND TO THE CLASS THIS ROUND
   FIXED, AND ITS "ZERO CELLS MOVED" READS LIKE COVERAGE.** The generator's
   condition register is a bare theta result with no `BinaryOperator` user, so the
   forward closure has depth 0 in all 297 cells. The record now says so, but the
   general problem stands: **this increment's two confirmed miscompiles were both
   found from plain C written by a reviewer, and neither instrument in the tree
   could have produced either one.** The instruments measure the axes someone
   already thought of.

16. **THE ROUND-2 FIX AGENT'S OWN INJECTION HARNESS LIED IN BOTH DIRECTIONS
   BEFORE IT WAS CONTROLLED.** Appending a `declare` so the injected module would
   be well-formed made a bare `NOROUTE-NOT: cqrt_cswap` fire on the DECLARE —
   every injection scoring "caught" for the wrong reason; and a stderr-only prefix
   (`WARN`) scored a permanent catch against a stdout capture. Both were found by
   adding a baseline control, and the 29/29 figure in §7b is the CONTROLLED one.
   **Recorded because the same failure mode is available to the next agent**: an
   identity witness must not share the transformation it witnesses, and that
   applies to the verification harness as much as to the compiler. **It happened
   TWICE in one session** — a probe loop using `set -- $B` in zsh (which does not
   word-split) ran `cq-opt` with no plugin, found no diagnostic, and scored two
   DECLINES as ACCEPTS (§11.2's warning box). Budget for the harness being wrong,
   not just the compiler.

17. **THE `i1` STATE-PREP WIDTH IS OUT, AND IT IS THE ONE CAPABILITY THIS ROUND
   COST (round-3, F-R3-8).** The branch condition is a tainted `i1` pinned to
   `true` on one edge and `false` on the other, so every `i1` seed collides on
   one of them. The ARM half was a live plain-C miscompile behind the type gate
   and MUST decline; the MERGE half is an over-decline at this clang (three
   spellings measured un-folded). Carving the condition out of the test set would
   re-open the arm half, so the two cannot be separated by anything I can prove.
   **This is an owner question, not a fix-agent one**, and it is stated in the
   fixture, the PRD and the hand-back rather than buried.

18. **THE FENCE IS NOW STRONGER THAN THE FOLDER, AND THAT DIRECTION HAS ITS OWN
   COST.** The `KnownBits` enumeration (F-R3-9) and LVI's edge idioms both see
   pins that this `clang`'s IPSCCP does not perform. Every such pin is a DECLINE
   of a program `-O1` could not actually have created — safe by the Prime
   Directive and invisible in the fixture family, because a fixture measures the
   pin and not the fold. `hb01`/`hb02` are two measured members. Nobody has
   counted how many plain-C programs are in that class; the 480-program corpus
   found exactly two, both hand `.ll`.

19. **~~NOTHING PINS `kF2MaxSteps`~~ — ⚠ CLOSED 2026-09-05 (round-4 review, lens
   R4, F-R4-4; fixed by the round-4 mini-fix).** The item as written was correct
   and is now stale, and it is struck rather than deleted because the SHAPE of the
   gap is the lesson: a numeric bound with no straddling pair is untested, not
   safe, and `grep 4096 ir-pass/test/*.ll` returned two files, NEITHER of which
   reached the code. R4 measured the branch reachable (1000/2000/4000/4090 accept;
   4200/8000 decline, 0.09–0.38 s) and the mini-fix committed the pair
   `..._stateprep_step_cap_under.ll` (N = 4090, ACCEPT) /
   `..._reject_stateprep_step_cap_over.ll` (N = 4200, DECLINE). **The exact
   boundary was measured while writing them and is recorded in both headers:**
   the walk pops `%q` and the tainted `icmp` (both anchors) plus the N chain
   members, so `Steps = N + 2`, and N=4094 accepts while N=4095 declines — the cap
   is EXACTLY 4096. The shipped pair is deliberately looser than that so an
   unrelated ±1 change in the anchor count cannot redden a fixture. **Two things
   the writing of it taught, worth more than the pin:** a 4000-wide FAN-OUT off one
   handle declines later at `uncompute: dead chain would free a measured register`
   (Rule 8), so the accept half had to be a LINEAR chain — a bound fixture can be
   silently unwritable for a reason that has nothing to do with the bound; and the
   two files are 132 KB / 135 KB, roughly ten times the previous largest fixture in
   the corpus, which is the price of pinning a 4096-step bound honestly and was
   paid rather than avoided by shrinking the constant.

20. **A MUTANT LEFT IN `build/` LIED TO THIS AGENT.** The mutation harness restored
   the shipped SOURCE and did not rebuild, so the next four measurements ran
   against the M5 binary — an accept fixture "declined", and five hand probes read
   as declines that are really accepts. Caught by adding a debug print and
   noticing the shipped logic disagreed with itself. `mutate.sh` now rebuilds on
   restore. **That is the third verification harness in this increment to lie to a
   fix agent** (§9 item 16 names the other two), and the rule that would have
   caught all three is the same: *an identity witness must not share the
   transformation it witnesses* — including the build tree.

21. **F2 HAS TWO ANCHOR MECHANISMS NOW, AND ONLY ONE OF THEM IS AN ANALYSIS.**
   (round-4 mini-fix, F-R4-1.) The BACKWARD half is `LazyValueInfo` for integers
   and a HAND-WRITTEN equality clause for floating point, because `ConstantRange`
   is an integer lattice and there is no fp query to make. That asymmetry is
   correct today and it is a maintenance hazard: the integer half tracks whatever
   LLVM learns, for free, forever; the fp half knows exactly ONE fact (an equality
   `fcmp` against a non-zero, non-NaN `ConstantFP` pins its operand on the edge
   where it holds) and will learn nothing new on its own. **If a future LLVM
   propagates an fp fact that is not that one — an ordered comparison collapsing a
   range, a `llvm.is.fpclass` narrowing, an `assume` — F2 will not see it, and no
   fixture will go red.** The retirement trigger at the caller now says this;
   quoting "F2 asks about fp" without the qualifier is how the old trigger became
   false.

22. **THE CONSERVATIVE HALF NOW SPLITS CALLS INTO TWO CLASSES, AND THE SPLIT IS A
   JUDGEMENT.** (round-4 mini-fix, F-R4-3.) An unfoldable OPAQUE call is skipped;
   an unfoldable CURATED REVERSIBLE INTRINSIC declines when any operand is pinned.
   The ground is that a curated intrinsic is a pure total function of its operands
   that CQ lowers to a rail, so "LLVM would not fold it" is a fact about LLVM's
   table rather than about the value. **That ground is an argument, not a
   measurement**, and it has a soft edge: a Phase-6 specialised clone call is ALSO
   a pure function CQ turns into a rail, and it lands on the SKIP side because
   `isCuratedReversibleIntrinsic` is false for it. I believe that is right (its
   body is arbitrary and `clang`'s lattice is genuinely overdefined there), but it
   is the sentence a fifth round should attack. **Also unchanged and now written at
   the fixture:** a `load` structurally cannot reach the rule at all, because the
   rule keys on an exactly-pinned INTEGER operand and a `load`'s only operand is a
   pointer — no reachable customer today (tainted stores decline earlier at
   `declineTaintEscapes`), but it is a SKIP, not a decline, and it is not covered.

24. **⚠ THE fp ANCHOR COSTS A REAL, `clang -O1`-REACHABLE ACCEPT, AND IT IS THE fp
   MIRROR OF AN OVER-DECLINE THE OWNER HAS ALREADY RULED ON.** (round-4 mini-fix,
   F-R4-1.) MEASURED from plain C, not argued:

   ```c
   double q = cq_theta(3.0, 0.3); double r = 5.0;
   if (q == 5.0) r = cq_theta(5.0, 0.9);        // and its `!=` twin
   ```

   ACCEPTED at the round-3 HEAD and **DECLINES now** (`$S/fix4/c/fpeq.c`,
   `fpne.c`). The one-character workaround is the same one the integer class
   already documents — `if (q == 5.0) r = cq_theta(7.0, 0.9)` ACCEPTS
   (`fpeq7.c`). **Against the pre-Inc-4 ORACLE there is no regression** (it
   declines `control flow`), so this narrows Increment 4's OWN accept class, not
   the shipped compiler's.

   **The honest asymmetry with the integer case, stated because it is the thing a
   reader would otherwise assume away:** for integers the over-decline is FORCED —
   `clang` really does substitute `k` for the register on an `icmp eq` edge, so
   the two source spellings arrive byte-identical and there is nothing to
   discriminate (PRD §14.11 Q1, `..._eqfold_coincidence.ll`). For fp at LLVM 19 it
   is NOT forced: `propagateEquality` does not cross `fcmp oeq` (`+0.0 == -0.0`)
   and R4 measured seven `-O1` dumps confirming it, so today the two fp spellings
   are distinguishable and this decline is precautionary. **It is shipped anyway**,
   because the alternative is a fence that is correct only for as long as one
   optimiser declines to do something, and the round found exactly that assumption
   written down as a retirement trigger and false. If the owner would rather have
   the fp accept back, the lever is one clause (`FpK = nullptr` unconditionally)
   and it re-opens `hf01` — which is a decision about risk, not about correctness,
   and belongs on the desk beside Q1.

25. **THE `Argument` BRANCH OF THE ANCHOR LOOP HAS NO REACHABLE CUSTOMER AND IS
   KEPT ANYWAY.** (round-4 review, F-R4-5, WEAK-PIN.) An `Argument` is tainted only
   inside a Phase-6 specialised clone, and a clone can never CONTAIN a state prep —
   measured on `p/cl01`/`cl04`/`cl05`/`cl06`, which decline `cq specialization:
   callee contains a quantum primitive (cq_*); only classical functions are lifted`
   on BOTH binaries. Outside a clone no `Argument` is tainted (a theta's arg-0 is
   classical by Rule 3). **Deleting the loop reddens nothing.** It stays as defence
   in depth; it must not be read as tested coverage, and this item exists so nobody
   later cites it as evidence that the argument direction was exercised.

---

## §10 — ROUND-1 ADVERSARIAL REVIEW (Rule 13) — every finding, graded, with its fix and its red-green evidence

Seven lenses (L1–L7), each compiling its probes on **both** binaries (HEAD = the
Inc-4 working tree; ORACLE = `scratchpad/wt/pre4/build/ir-pass/cq-opt`, built from
`b506b3b`). Between them: **314 probe programs** as reported by the lenses
themselves (L1 47, L2 79, L3 51, L4 32, L5 69, L6 36) plus L7's 3062-run fixture
sweep; every HEAD accept linked, run and put through STRICT stage 2b; three
whole-corpus sweeps; both loop gates. (Counts as each lens reported them; they
were not de-duplicated across lenses.)

> **HEADLINE: THE ROUND FOUND A CONFIRMED SILENT MISCOMPILE IN THE INCREMENT'S
> OWN HEADLINE FENCE, REACHABLE FROM ORDINARY `clang -O1` C, AND IT IS THE FACT
> TO CARRY.** `int t = q & 1; int r = 1; if (t) r = cq_theta(t, θ);` — an in-place
> Ry on the CONDITION register, the shape R4 forbids permanently — compiled at
> HEAD into a fresh-rail state prep and left the condition register unrotated.
> The pre-Inc-4 binary declined it. F2's own written proof enumerated **two** ways
> a seed can be a fold of the condition register and there is a **third**; the
> algebra was right and **the enumeration was the defect** — the bd `8h7d.5`
> F-1/F-3 lesson, in a new place, one epic later. Nine distinct plain-C spellings
> were in that class.
>
> Beside it: **two documentation claims that were load-bearing and false** (F1's
> third clause was called unreachable while being the only thing between an
> unrecognized-suffix module and an emitted region whose gate does not exist; the
> §14.2c derived-temp rationale was false for `+k`/`−k`/`^k`, which are CQ's own
> in-place ABI), **the Inc-3 F-L6-1 fixture-integrity finding RECURRING** (an
> injected `_controlled_inv` after the flag's free was caught by **0 of 20**
> accept fixtures), **three new accept classes with no fixture at all**, and
> **fifteen further DOC-FALSE / WEAK-PIN items**. **Every adversarial round this
> epic has run — Inc 1's two, Inc 2b's three, Inc 3's two, and now this one — has
> found something**, and this round's find is in the fence the increment was
> written around. That is not evidence the next round will be quiet; §9 items 9-12
> name what to aim it at.

### §10.1 The findings

| # | lens | grade | finding | fix | red-green evidence |
|---|---|---|---|---|---|
| **F-L2-1** | L2 | **CONFIRMED-MISCOMPILE** | F2 keyed on the compare's LITERAL. `-O1` pins the condition operand to a SINGLETON **by RANGE** on the `ne` edge too, so `int t = q & 1; if (t) r = cq_theta(t,θ);` folds to `cq_theta(i32 1,θ)` against `k = 0` and F2 was silent BY DESIGN. Nine plain-C spellings ACCEPTED at HEAD; ORACLE declined all nine | **F2 rewritten RANGE-BASED on BOTH edges**: `computeConstantRange(H) ∩ fromKnownBits(computeKnownBits(H)) ∩ makeExactICmpRegion(pred, k)`, asked of the predicate AND its inverse, declining on `isSingleElement() == seed`; the `isEquality()` gate DROPPED; the plain literal test KEPT (it does not depend on ValueTracking) | 5 new declines (`..._range_{mask1,a2_alias,ordered,knownbits,i1_both_edges}`) + 1 accept control (`..._range_ordered_seed0`). **Mutation M2a** (drop the range half) reds exactly those 5; **M2b** (drop the known-bits intersection) reds exactly `range_knownbits`; **M2c** (restore `isEquality()`) reds exactly `range_ordered`. Re-ran all **79** L2 probes: **8 of 79 verdicts moved, ALL accept→F2-decline**, flagship and the mask-2/3 R4 controls unchanged |
| **F-L2-2** | L2 | **CONFIRMED-MISCOMPILE** | the A2 side of the same hole: `int r = q&1; if (!(q&1)) r = cq_theta(1,.9);` — the merge's PRED incoming folds to the range-pinned `1`, so F1 is satisfied and F2 compared `1` against `k=0` | same fix (the range test asks both edges, so polarity does not enter) | `..._range_a2_alias.ll` |
| **F-L2-5** | L2 | DOC-FALSE | *"there are exactly TWO physical readings, and F2's single test covers both"* — the algebra was right, the ENUMERATION was the defect (A3: an edge proves `H != k` and `H`'s RANGE makes the survivor a singleton) | corrected in PRD §14.2b, in the code comment, and in **6 fixture headers** that carried the sentence verbatim | the 6 headers now carry the A3 counterexample and point at `..._range_mask1.ll` |
| **F-L2-3** / **F-L6-2** | L2, L6 | CONFIRMED-OVER-ACCEPT + DOC-FALSE | §14.2c's licence *"`t = f(q)` is an OUT-OF-PLACE derived rail"* is **false for `f ∈ {+k,−k,^k}`**, which is exactly CQ's in-place ABI (`cqrt_addc`/`cqrt_xorc`), and `railWireClosure` — the walker R4 is built on — calls them the SAME wire | **NOT fixable in the pass** (the folded module is IR-identical to the flagship, and forcing M-C to state its choice PREVENTS the fold). §14.2c item 1 rewritten as a genuinely ambiguous class with the sub-families separated; escalated to PRD **§14.11 Q3** | measured both directions: `int t=q+1; int u=cq_theta(t,.9);` with `q` dead emits `cqrt_addc_i32(h0,1); cqrt_ry_i32(h0,.9)` (same rail); with a second reader it is out of place and the region DECLINES |
| **F-L2-4** / **F-L1-3** / **F-L6-1** / **F-L7-5** | L2, L1, L6, L7 | CONFIRMED-OVER-ACCEPT → **RULED SOUND, DOC-FALSE ONLY** | F1 admits `ConstantInt`\|`ConstantFP` seeds; F2 asks only `ConstantInt` AND same-type — so a cross-type seed (`i64`/`i8`/`double` from a CAST of the condition register) is invisible to F2. Two lenses called it a hole; L1 showed it is SOUND and that the type gate is the load-bearing SEMANTIC discriminator, documented as a mechanical `APInt` precondition | **type gate KEPT and the rationale written at the site and in PRD §14.2c item 1** — ⚠ CORRECTED 2026-09-05 (round-2 review, lens R2 F-R2-3): this row said "and in **both** matrix headers" and round 1 changed **one** file under `tools/` (`loop_twin_matrix.expected.txt`); `inplace_twin_matrix.py` was byte-unchanged and carried NO cross-type rationale. The round-2 fix landed it there, together with the `s5` SAME-MODULE correction that rationale was owed. MEASURED all five foldable casts — `sext`, `zext`, `trunc`, `sitofp` and, decisively, the same-width `bitcast` from a `union`/`memcpy` — every one lowers OUT OF PLACE (`cq_template_bitcast_i32_to_f32(%h) -> %h_cast`, a FRESH handle), so **no bit-pattern clause is owed** | accepts `..._stateprep_cond_cast_seed.ll` (the `sext` spelling) and `..._stateprep_cond_bitcast_seed.ll` (the float whose 32 bits ARE `k`); the same-width DECLINE control is the same-TYPE spelling, `..._eqfold_coincidence.ll` |
| **F-L1-1** | L1 | DOC-FALSE + **Rule-12 gap** | F1's third clause was recorded as *"structurally unreachable, defence in depth, no fixture can be written"*. It is REACHABLE via an UNRECOGNIZED SUFFIX (`isThetaCall` is a name-prefix test; `resolveSources` validates only `allSuffixes()`) and LOAD-BEARING. The stated mechanism was also wrong: LLVM 19 parses and verifies a type-mismatched call; `getCalledFunction()` is what blocks that route | clause KEPT; §8 F-3 and PRD §14.4 **RETRACTED** in place; the mechanism restated | `..._reject_stateprep_unrecognized_suffix.ll` + the one-token accept twin `..._stateprep_suffix_control.ll`. **MEASURED counterfactual**: with the clause disabled, the same module WITHOUT the measure ACCEPTS (exit 0) and emits a STANDING `@cq_theta_si32x` inside a flag mint/strip/free — a region whose gate does not exist |
| **F-L1-2** | L1 | WEAK-PIN | `..._undef_incoming.ll` / `..._poison_incoming.ll` pin clause **2**, while their headers claim clause **1** — relax clause 1 to `isa<Constant>` and both stay GREEN | 2 new fixtures with `undef`/`poison` in BOTH slots; both headers corrected | `..._undef_seed.ll`, `..._poison_seed.ll`. **Mutation M1 measured `undef_seed` as a REAL ACCEPT with F1 off** — i.e. it is one of only THREE genuine prevented over-accepts in the whole F1 family, and it emits `cqrt_alloc_i32(i32 undef)`, the bd `xy9n` shape |
| **F-L1-4** | L1 | DOC-FALSE (verdict column) | notes M1's *"F1 is load-bearing for all 12 and for NOTHING ELSE"* over-reads: for a diamond, F1 clause 2 and R3 are the same expression, so most of the family keeps declining with R3's string | M1's verdict column replaced by a **MEASURED** three-way breakdown | with F1 disabled: **3 real ACCEPTS** (`constexpr_seed`, `runtime_seed`, `undef_seed`), **11 declines on R3's generic `control flow`** (a string move), **1 dying later in `lowerMeasures`** (`unrecognized_suffix`) |
| **F-L5-1** | L5 | DOC/UX, medium | the folded plain-C R4 program `for(){ if (a==5) a=cq_theta(a,.9); }` printed `state prep seed does not match the merge incoming` — naming a "seed" and a "state prep" the source never contains; the implied fix is not the fix | **F1's string SPLIT by the incoming's nature**: a TAINTED incoming gets `state prep merged with a quantum register` (the no-cloning mux); every other mismatch keeps the seed wording | **Mutation M1b** (remove the split) reds exactly 4 files — `nonconst_incoming`, `prep_then_prep`, `inloop_carried`, `unrolled_k2` — and no others. Both `loop_twin_matrix` rows REGENERATED from the tool's own `sources()` and re-measured; `e2e-loop-twin-matrix` GREEN (194.5 s) |
| **F-L7-8** | L7 | DOC-FALSE + wrong string | HEAD printed `if/else state prep allocates two rails` for `ifelse_mixed_chained` / `ifelse_mixed_phase`, **neither of which has two preps**; and 12 fixtures carried an "R1's OTHER THREE HALVES" block true of 4, while 5 carried a "two arms whose seeds are the SAME" block true of 1 | a **fourth `What`**, `if/else state prep beside a chained or phase arm`, chosen by re-classifying the other arm with the SAME predicate the clause is inside; the boilerplate stripped from the 8 + 4 files it does not describe | **Mutation M3b** (one string for both shapes) reds exactly those 2 files; **M3** (disable the clause) still reds exactly 4 |
| **F-L7-1** | L7 | WEAK-PIN — **the Inc-3 F-L6-1 RECURRENCE** | a POSITIVE `NOROUTE-COUNT-n` inside the NOROUTE prefix WINDOWS every negative after it, so the `_controlled_inv` NOT never scanned past the flag's `cqrt_free` — which is exactly where the spine emits. **Injected `_controlled_inv` after the free: caught by 0 of 20; caught in NO prefix at all by 7 of 20** | every count moved to its own prefix (`ACNT`/`FCNT`/`XCNT` — one per group, because a lowered module may interleave allocs and frees); `NOROUTE` is now PURE-NEGATIVE and whole-file, on all 28 accepts | the three injections (`_controlled_inv` after the free, a dirty `cqrt_free` of the prepped rail, a `cqrt_cswap` after the free) re-run over all 28 accepts on copies: **28/28 caught, on all three** |
| **F-L7-2** | L7 | WEAK-PIN | 9 of 20 `NOROUTE` blocks named a handle `%h1` that does not exist in their own lowered output (`seq_then_chained`, `two_regions`), and `two_regions` had no NOT for its SECOND gate — so the M7 anti-mutation assertion was vacuous there | every handle name is now **DERIVED from the pass output**, one NOT per emitted controlled gate | **Mutation M7** (drop the control) reds **28 of 28** accepts, up from the shipped 20 of 20 on a smaller family |
| **F-L3-1** | L3 | COVERAGE GAP (new accept class) | a LATER region whose CONDITION is read from the PREPPED rail accepts at HEAD and declines on the ORACLE — the FIRST shape putting a freshly-minted, condition-entangled rail into another region's flag-mint slot. No fixture, no §14.3 row, no slice | 2 accept fixtures + PRD rows A-27/A-28 | `..._stateprep_feeds_later_cond.ll` (chained arm on `q`), `..._stateprep_feeds_later_cond_prep.ll` (a second prep). Sound because the mint is a basis-DIAGONAL read and region 2 never moves the prepped rail |
| **F-L6-3** | L6 | DOC-FALSE + COVERAGE GAP | PRD §14.6 / notes §3 said `railPhiRootMint` is a set that *"WOULD CLAIM"* a hoisted state-prep mint if R7 were lifted. **It claims one TODAY**: for a FLAT prep followed by a classically-bounded loop rotating the prepped register, `T` dominates the header, the rail φ collapses and the body ROLLS | both rows corrected; accept fixture added; the CONTEXT-DEPENDENCE recorded as a PRE-EXISTING `LoopLowering` fact | `..._stateprep_then_rolled_loop.ll` + PRD row A-29. L6 linked and ran the hand-unrolled K=3 twin: traces **BYTE-IDENTICAL**, 24 lines, strict 2b clean |
| **F-L4-3** | L4 | DOC-FALSE (the paragraph §14.12 worry 6 named) | the `warnLiveRecordRotations` argument's stated mechanism is wrong — `Seeds == {W}`, not empty; pass 3 no-ops on the shared `Seen` set and `W` stays out of `Records` by `RecordSet`'s clause-5 `V == Wire` guard. **And M-A is NOT blinded by a state-prep-rooted rail**, which M6 could not establish | notes §3 and PRD §14.6 rewritten; the complementary direction committed as a fixture | `..._stateprep_warn_live_record.ll` (accept, emits the M-A warning) + PRD row A-30 |
| **F-L4-2** | L4 | WEAK-PIN + DOC-FALSE | `..._stateprep_{i1,i8,i16,i64}.ll` claim to pin F1's third clause; **deleting the clause leaves all four GREEN**. Their second claim, *"before Inc 4 those two were never cross-checked at all"*, is false (`declMatchesPrototype`) | all four headers rewritten to say what they DO pin (the name-derived alloc/gate symbol and the alloc's position, at that width) and to point at F-L1-1's fixture | the `i1` file was rewritten anyway (its module became a decline — see F-L2-1's `i1` note) |
| **F-L4-1** | L4 | DOC-FALSE, **introduced by Inc 4** | `RotationLowering.cpp`'s Rz bail calls itself *"the mirror of `controlled theta operand`"* — a sibling this increment DELETED (`grep` finds the string in no other site or fixture) | reworded, with the asymmetry's real ground (§14.7: there is no Rz state prep, so a classical arg-0 `cq_phi` under control can only mean the plan and the IR disagree) | — (comment) |
| **F-L4-4** | L4 | DOC-FALSE, **PRE-EXISTING** | `LoopLowering.cpp` says `taint.ControlledRotations` has "TWO writers"; there are **three** (`AngleSelectEmit` records BOTH stems, and an Rz angle-select entry DOES reach `isHoistedRegionArmGate`) | both sentences corrected; PRD §14.6's drifted line numbers refreshed | no consequence for Inc 4 (a theta entry cannot pass the `cq_phi_` test) — verified by running a state prep beside a rolled in-loop Ry region in both orders |
| **F-L4-5** | L4 | WEAK-PIN, not actionable | the hoisted `controlled theta suffix/width` bail cannot fire (16 suffixes ⊂ 9 controlled widths), so no fixture is possible | said so at the site; the hoist itself is a real Rule-1 repair and is kept | — |
| **F-L3-6** | L3 | NIT | the sibling `if (!CRy)` null-guard was still BELOW the alloc — unreachable, but if it fired it would reproduce the exact residue the hoist removed | removed and replaced by an `assert`, so there is ONE bail at ONE position, above every mutation | — |
| **F-L6-5** | L3/L6 | DOC-FALSE, PRE-EXISTING (Inc-3 leftover) | `ArmClassify`'s `SawRotationArm` comment says `!SawPhaseArm` makes P1 DECLINE for a rotation arm; the shipped fence DEFERS for one, and **Inc 4 depends on the shipped reading** | comment corrected in place, with the note that the stale sentence was an argument for reverting a fence that is load-bearing two increments later | `..._stateprep_post_region_theta_cond.ll` accepts because of it |
| **F-L6-4** | L6 | precision | mutation M5's "five fixtures pin the vacuity" is 3 accepts + 2 declines, and the two declines pin nothing (their named clause is untouched); one of the three accepts reds only by accident of an unrelated `icmp … 0` | M5's row rewritten; `seed_other_users` named as the sole DELIBERATE pin | — |
| **F-L3-2** | L3 | DOC-FALSE | the `--stateprep` matrix's `invert` axis is **VACUOUS**: the pass has no handler for `__cq_invert_begin/_end` at all (Phase 8), so 11 IDENTICAL cells are not `EmitInverse` evidence | PRD §14.10 lens-3's `cq_invert` item marked NOT DISCHARGEABLE AT HEAD; the real ground (the structural freeze, measured as 0 `_controlled_inv` everywhere) stated instead | — |
| **F-L3-3** | L3 | DOC imprecision | *"the leak is O(1) per region"* is true of the rail this increment mints and false of the region once `r` has a derived consumer (3 rails leak; **stage 2b cannot count the third**) | notes §0 corrected; PRD §14.10 corrected | measured on `int s = r + 1; …` |
| **F-L3-4/5** | L3 | STRENGTHENING + explanation | notes §8 F-7 called the 11 `!!` cells an ABSENT oracle. A PARTIAL oracle exists (an ordinary source rail with the identical second region lowers on BOTH binaries with a region-2 suffix BYTE-IDENTICAL to the subject's), and the twin's decline is `SelectClassify` gate 5, unrelated to the region | F-7 rewritten as a measurement | the 11-line normalised diff is empty; the gate-5 bisection control has NO control region at all and declines identically on both binaries |
| **F-L7-3** | L7 | DOC-FALSE | §14.2d's "stem PAIR" is not a pair: `control_swap_eqfold_diamond.ll` "with the stem changed" dies at **F1**, not F2, and `..._eqfold_coincidence.ll` is a DIFFERENT module (its pred incoming is a constant) | MEASURED all four cells of the 2×2 and rewrote §14.2d and the fixture header to say which fence each side dies on | Rz+register-incoming ACCEPT; Ry+register-incoming DECLINE on F1; Rz+constant-incoming DECLINE `control flow`; Ry+constant-incoming DECLINE on F2 |
| **F-L7-4** | L7 | DOC-FALSE ×3 | *"48 cells … across every cfg, cond and width"* — `clsbetween`'s four arithmetic cells ACCEPT | corrected in PRD §14.13, notes §8 F-1 and the `sunk_arith` header; `clsbetween` named as the **POSITIVE CONTROL for the mechanism** | re-counted by message from the committed table: the 48 are 12 each of `mul3`/`spine`/`deadadd`/`deadmul` at cfg `diamond`(40)/`clsbefore`(4)/`negated`(4); `clsbetween` 0; the 4 `ifelse` cells decline on `rotation angle` |
| **F-L7-6** / **F-L5-3** | L7, L5 | DOC-FALSE + **Rule-12 gap** | §14.9's fixture arithmetic does not reconstruct: A-17/A-22 share a file, two build-time declines were never added to the recipe, and **row F2-7 shipped NO fixture and was named nowhere** | `..._reject_stateprep_eqfold_ne_else.ll` added; §14.9's arithmetic redone honestly | it is NOT a duplicate of `..._eqfold_coincidence.ll`: measured at `-O1` the two bodies differ in exactly one thing — the merge φ's INCOMING ORDER — which is what pins F1's read-by-block |
| **F-L7-7** | L7 | DOC-FALSE | §14.3 row R7-2 predicts `nested control flow`; HEAD prints `impure phase arm` | row corrected with the reason (`armBlockIsPureSpine` adjudicates before `RegionTreeDetect` is consulted) | re-measured on HEAD and on the oracle |
| **F-L2-7** | L2 | WEAK-PIN | `..._eqfold_derived_cond.ll`'s contrast claim is about the two `.ll` files, not about two C programs — the C the reader would infer declines on F1 | header corrected, and updated for the range clause | — |
| **F-L2-6** | L2 | PLAUSIBLE (not reachable today) | `__builtin_assume(q==0)` produces a textbook accept shape and the ONLY thing declining it is `declineTaintEscapes` treating `llvm.assume` as an unknown callee — a guard written for a different purpose and mentioned nowhere in §14 | recorded as F2's **SECOND RETIREMENT TRIGGER**, at the code site and in PRD §14.2b, with the committed reproducer and the note that F2's `AC` parameter is already there and passed `nullptr` | — |
| **F-L5-2** | L5 | DOC | `SwapRouteEmit`'s `DischargedFlagGates` licence still names R4 as its ground; Inc 4 **SKIPS** R4 for this arm class | the structural sentence added (the rail is minted by the hoisted `T`, so disjointness is by construction) | L5 measured the discharge end-to-end on a derived condition: strict 2b 8 verified / 0 violations, trace reduces byte-for-byte to the chained twin's oracle trace |
| **F-L5-4** | L5 | trivial | CLAUDE.md said 58 fixtures in one place and 59 in another | corrected, and re-stated at the post-round count (76) | `ls` |
| **O1** | L5 | OWNER GLANCE, pre-existing | a post-region record read past a post-region in-place gate accepts, region-independently; Inc 4 adds a POPULATION to that known flat posture (bd `0njv`) | recorded in §9 item 10 and in the hand-off; **not** fixed here | measured three ways: after a state prep, after a chained twin on the ORACLE, and with no control region at all |

### §10.2 What the round did NOT change, and why that matters

* **No accept in §14.1's shipped shape was withdrawn** except the `i1` fixture,
  whose module was a measured over-accept and is now a decline; the `i1` WIDTH
  capability is unchanged and still pinned.
* **The whole-corpus sweep is still ZERO pre-existing files.** Every differing
  file carries the `stateprep` name, before and after this round.
* **No golden was regenerated** and no `.expected.log` is modified.
* **The two `loop_twin_matrix` rows were REGENERATED, not edited by inference** —
  both cells rebuilt from the tool's own `sources()`, compiled at `-O1` and run
  through the fixed binary, and the whole 274-cell gate re-run GREEN afterwards.

---

## §11 — ROUND-2 ADVERSARIAL REVIEW (Rule 13) — every finding, graded, with its fix and its red-green evidence

Two lenses this round: **R1** (the round-1 range fix, adversarially — 163 C
programs and 8 hand `.ll` modules through BOTH binaries, every HEAD accept put
through strict stage 2b, linked and RUN) and **R2** (fixture / doc / instrument
truth of the round-1 fixes — 28 accepts injected at two positions with four
injections, a full FileCheck-directive audit of all 76 family files, and every
published count re-measured).

**THE HEADLINE IS NOT A NEW SHAPE — IT IS THE SAME MISTAKE, ONE ROUND LATER, IN
THE SAME FUNCTION.** Round 1 turned F2 from a literal test into an edge-restricted
`ConstantRange` test. That widened the **predicate** and left the **set**: F2 still
asked its question of `H`, the tainted operand of the compare CQ is handed. `-O1`
does not leave the pinned register there — IPSCCP proves the theorem about a
register **X** and substitutes it into the arm, then a LATER InstCombine rewrites
the COMPARE downward onto an **ancestor** of X, so X ends up a **forward user** of
`H`. **Six plain-C programs accepted with X alive in the emitted circuit,
MEASURED by the source, and never rotated.** That is the bd `8h7d.5` F-1/F-3
lesson — *when you widen a set, ask in writing what OTHER set is computed over the
same closure* — for the third time, and the second time inside this epic's own
fence work.

**Every adversarial round this epic has run has found something, and the count is
now Inc 1 × 2, Inc 2b × 3, Inc 3 × 3, Inc 4 × 2** — with the Inc-4 round-2 find
sitting **inside the round-1 fix for the Inc-4 round-1 find**. §9 items 9–16 name
what to aim a third round at: item 9 is rewritten, item 13 is the narrowed
residual, item 14 the forward closure's own three holes, item 15 the fact that
both of this increment's confirmed miscompiles came from plain C a reviewer wrote
and neither instrument in the tree could have produced either, and item 16 the two
verification harnesses that lied to the fix agent in this one session.

### §11.1 The findings

| # | lens | grade | finding | fix | red-green evidence |
|---|---|---|---|---|---|
| **F-R1-1** | R1 | **CONFIRMED-MISCOMPILE** | F2 asked its singleton question of `H` ALONE. `-O1` pins a register **X**, substitutes it into the arm, and a later InstCombine rewrites the compare onto an ANCESTOR of X — so X is a FORWARD USER of the `H` CQ sees and F2 is silent. **Six plain-C spellings ACCEPTED with X lowered to a live rail that the source MEASURES and nothing rotates** (`5+(q&1)`, `(q&1)^7`, `(q&1)-4`, `(q&1)\|8`, `((unsigned)q)>>31`, `q>>31`); the pre-Inc-4 binary declined all six | **F2's SET widened to a BOUNDED FORWARD CLOSURE** (`f2ForwardClosurePinsSeed`): seeded with (`H`, `H`'s edge range), pushed forward through `H`'s TAINTED same-type integer `op constant` users with `ConstantRange::binaryOp`, every member asked the singleton question. Depth 8 / 64 values, **and the bound DECLINES**. Casts NOT followed (a different physical wire, §14.2c); φ/`select` NOT followed (a CQ semantics fact — a live classical mux is refused outright and a surviving one becomes a FRESH merged register via the 4.4 copy merge) | 6 new declines `..._range_forward_{add,xor,sub,or,lshr,ashr}.ll`, transcribed from the six C sources. **Mutation M2d** (forward walk off) reddens **exactly those six and nothing else**, and all six then **ACCEPT (exit 0)**. Re-ran all 163 R1 C probes + 8 hand modules: **exactly 6 verdicts moved, all accept → F2-decline; ZERO over-decline regressions** |
| **F-R1-2** | R1 | DOC-FALSE | (a) *"F2 recomputes **exactly** that"* — it recomputed IPSCCP's arithmetic for the wrong value (F-R1-1); (b) the residual paragraph conflated *"instcombine deletes the register"* with *"and rewrites the compare onto an ancestor"* — the rewrite ALWAYS happens, the deletion only SOMETIMES; (c) with `AC = nullptr`, `CtxI` and `DT` are **inert**; (d) the retirement trigger that bites is `DomConditionCache`, not `AssumptionCache` | all four written at the F2 site and in PRD §14.2b; the residual paragraph split, with the "always vs sometimes" distinction spelled out as the reason F-R1-1 could hide inside a paragraph labelled "the residual" | — (comments + PRD). The `CtxI`/`DT` inertness is stated as ANALYSIS from LLVM 19's two guards (`if (CtxI && AC)` and `if (!Q.AC \|\| !Q.CxtI) return;`), not as a measurement: no CQ-reachable program depends on it, because every dominating tainted branch declines earlier |
| **F-R1-3** | R1 | **CONFIRMED-OVER-ACCEPT** (hand-IR only, with the plain-C non-reachability MEASURED) | `ConstantRange::fromKnownBits` is a HULL: `and q,4` reads `[0,5)`, so the `ne 0` edge gives `[1,5)` and the true singleton `{4}` — a genuine A3 pin one bit above `..._range_mask1.ll`'s — is MISSED. `hb01`/`hb02` accept | **NOT fenced, recorded as a RETIREMENT TRIGGER with its boundary and its fix.** Not reachable from plain C at this clang because IPSCCP's lattice is a `ConstantRange` too and therefore performs NO fold — the two analyses fail TOGETHER, which is exactly why F-R1-1's class (fold succeeded, question asked of the wrong value) was a miscompile and this one is not | boundary MEASURED: `hb01` (`and q,4`, seed 4) and `hb02` (`and q,8`, seed 8) **accept**; `hb03` (`and q,5`, `ugt 4`, seed 5) and `hb04` (mask 1) still **decline**. Plain-C non-reachability MEASURED on `t01`/`t02`/`t03`: `-O1` keeps `cq_theta(i32 noundef %2, 0.9)` unfolded on both binaries. Written at the site and in PRD §14.2b with the fix for the day SCCP gains a known-bits lattice (enumerate the ≤256 `Known`-consistent values) |
| **F-R1-4** | R1 | CONFIRMED-OVER-ACCEPT, **scope not fence** | the named residual is real, correctly diagnosed, and its **boundedness argument was missing**: a register is deleted only when NOTHING reads it, so the difference between rotating that rail and rotating a fresh one prepared to the same pinned value is confined to a leaked ancilla no `cq_measure`/`ret`/tape write observes — the move the `fenv` ruling already blesses | the argument written into **PRD §14.11 Q3** and §9 item 13, **with the sentence that it does NOT extend one inch to F-R1-1, where the register IS read** — so a future agent cannot quote it to reopen an accept | members re-measured at HEAD, and the list is UNCHANGED at five: `k03`, `k04`, `r3`, `r4`, `r6` all still ACCEPT. `r6`'s `@slice` body is BYTE-IDENTICAL to the flagship slice's. ⚠ **`k03` is NOT fenced by F-R1-1's fix and an earlier draft of this row said it was** — the difference is one token: `k03` (`unsigned s=((unsigned)q)>>31;` with `s` NEVER MEASURED) has its register DELETED, while `x23` — the same expression with `cq_measure(s)` added — keeps it and is one of the fenced six. That is exactly the always-vs-sometimes boundary, and getting it wrong in the fix's own record would have re-created the defect the fix corrects. CQ has no simulator (Rule 2), so "the leak never interferes" is recorded as ANALYSIS |
| **F-R1-5** | R1 | WEAK-PIN | `clang` canonicalizes the literal to the RIGHT, so `grep "icmp [a-z]* i[0-9]* [0-9-]"` over the family returned ZERO hits and deleting `Rel = ICmpInst::getSwappedPredicate(Rel)` reddened NOTHING | 2 declines + 1 accept, splitting the two halves of that code **deliberately**, because an `eq` cannot discriminate the swap (`getSwappedPredicate(eq) == eq`) and the fixture headers say so | **M2e** (delete the swap) reddens exactly `..._range_constleft_ugt.ll`; **M2f** (delete the `K0 && !K1` operand selection) reddens exactly `..._range_constleft_{ugt,eq}.ll`; `..._stateprep_range_constleft_accept.ll` stays GREEN under both, which is what makes the swap a discriminator rather than a blanket over-decline |
| **F-R1-6** | R1 | positive result | no over-decline regression: 15 §14 accept shapes written as C, 14 ACCEPT (the 15th, `if((unsigned)q<1u) r=cq_theta(0u,.9)` with `r=0`, is a CORRECT new decline — the `ult 1` edge pins `q` to `{0}` = the seed); `--stateprep` matrix byte-identical to the committed record; no `ORACLE=ACCEPT → HEAD=DECLINE` row in 163 probes | nothing to fix | re-confirmed this round on the round-2 binary: **exactly 6 verdicts moved** out of 171 probes, all in the intended direction |
| **F-R2-1** | R2 | WEAK-PIN | `..._stateprep_suffix_control.ll` was the ONE accept of 28 that could not see a standing `@cq_theta` CALL — and it is the accept twin of `..._unrecognized_suffix.ll`, whose entire counterfactual is *"a STANDING `@cq_theta_si32x` inside a flag mint/strip/free"*. The whole-file NOT had been dropped SILENTLY, because the fixture declares both suffixes and a bare-name NOT would match the surviving `declare` | `; NOROUTE-NOT: call i32 @cq_theta` (narrowed to a CALL) plus the reason, so the next reader does not drop it again | VALIDATED BOTH WAYS on the lowered module: FileCheck **exit 1** with `%injtheta = call i32 @cq_theta_si32(i32 0, double 1.0)` injected before the first `ret`, **exit 0** clean |
| **F-R2-2** | R2 | DOC-FALSE | notes §7a's "12 non-differing declines" was wrong on 3 of 12 **in the direction that understates the increment**: `cond_qq`, `tainted_angle` and `sharecond` DO differ (Inc 4 carries them past the generic `control flow` into a more specific pre-existing clause), and `compound_cond`, `fcmp_oeq_unfolded`, `unfolded_twin` were omitted | §7a corrected with the ORACLE→HEAD table and the corrected twelve | **re-MEASURED all 15 files myself on both binaries**, not taken from the report: 3 differ exactly as named, 12 do not. The corrected twelve are exactly the 12 family declines absent from this round's 73-file sweep set |
| **F-R2-3** | R2 | DOC-FALSE | `tools/inplace_twin_matrix.py`'s `s5` "compile to the SAME MODULE" claim holds at the compare's own width (`int`) and at NO other width on that axis, because the generator's condition register is always `int cq0`; and §10.1's "written … in **both** matrix headers" was false — round 1 changed ONE file under `tools/` | the `s5` paragraph qualified with the measured table and the cast-is-out-of-place rationale it was owed; §10.1's claim corrected in place | **re-MEASURED from plain C at `-O1`**, whole-module `diff`: `int` IDENTICAL; `signed char` / `long long` / `double` DIFFER (`cq_theta_si8(i8 5,…)` vs `cq_theta_si32(i32 5,…)` + `trunc`, etc.). **And measured one step further than the report**: a same-module partner DOES exist at those widths — `r = cq_theta((T)cq0, .9)` — but it is an in-place Ry on a CAST rail, i.e. the §14.2c derived-temp class, NOT the R4 class the paragraph is about |
| **F-R2-4** | R2 | DOC-FALSE / Rule-12 recipe | four §14.3 rows named fixture files that do not exist, un-annotated: F1-7 `..._global_seed.ll`, F2-3 `..._eqfold_range.ll`, W-1 `..._width.ll`, and IE-2 misspelled | **all four ANNOTATED; two were NOT given files, deliberately** — see §11.3 | F1-7: `cq_theta_<sfx>` has no pointer-typed overload, so a global address can reach the seed slot only as a `ptrtoint` `ConstantExpr` — the same refusal on the same IR shape, and `..._constexpr_seed.ll`'s header already calls a second file "a false coverage claim". F2-3: **re-MEASURED** — `q>4 && q<6` collapses at `-O1` to `icmp eq i32 %1, 5` with the arm folded to `cq_theta(i32 5,…)`, structurally `..._eqfold_coincidence.ll`. W-1: unwritable (F-L4-5's ground). IE-2: filename corrected in all 3 places |
| **F-R2-5** | R2 | DOC-FALSE | §14.2d's round-1 correction said the honest pair is `control_swap_eqfold_diamond.ll` vs *"its own Ry twin"*; the literal one-token twin declines **`control flow`** (two arm gates) and F1 is reached only after a SECOND edit. The FIXTURE header said so and the PRD did not — **F-L7-3's own error class surviving one level up inside the fix for F-L7-3** | the parenthetical carried into the PRD table row and the concluding sentence | **re-MEASURED both modules myself**: `cq_phi`→`cq_theta` ⇒ `control flow`; with the second gate also dropped ⇒ `state prep merged with a quantum register` |
| **F-R2-6** | R2 | DOC-FALSE | §14.6's `inPlaceRotationArmTheta` row said "sole caller `:1641`" — wrong line AND wrong count, and the SECOND caller was ADDED BY ROUND 1 (the §14.2e other-arm re-classification). An audit row whose job is *"what OTHER set is computed over the same closure"* went stale about its own callers | row corrected to `:721`, callers `:1833` and `:1925`, naming the round-1 addition; and **every `ArmClassify.cpp:<line>` citation inside §14 re-measured**, because this round's insertion shifted them by +161 | each refreshed citation was checked by reading the line: `:745` `StatePrep = true;`, `:1655` `DeferredWireGate`, `:2310` R3's `Routed && RotBase != Routed`, `:2699` `isFPOrFPVectorTy`, `:3832` `classifyAngleSelect` S3 |
| **F-R2-7** | R2 | DOC-FALSE, in a committed record | `inc4-records/inplace_stateprep_post4.txt:59` still said the 48 `control flow` cells span *"every cfg/cond/width"* — the F-L7-4 correction landed in three places and not in the file §14.13 cites as its SOURCE | corrected in the record, with the breakdown | **re-counted from the table**: diamond 40 + clsbefore 4 + negated 4 = 48, **`clsbetween` 0** — its 4 cells ACCEPT and are the positive control |
| **F-R2-8** | R2 | NIT | §14.3 rows **F2-8** and **FP-1** put `rotation arm on a condition wire` in a column headed "exact string"; HEAD prints `condition predates a non-diagonal gate` | both rows struck through and given the printed string, with the note that there is no unmasking move for FP-1 (the masking gate IS the arm) | the two fixtures already assert the printed string and are green |
| **F-R2-9** | R2 | NIT | notes §2's headings `(12 fixtures)` / `(6 fixtures)` count nothing after round 1 | both headings re-measured and re-stated, and a ROUND-2 amendment block added under F2 | measured today: **15** files decline on an F1 clause (11 + 4 split), **20** on F2 |
| **F-R2-10** | R2 | NIT | *"53 files carry dated CORRECTED/AMENDED/RETRACTED notes"* does not reproduce (45 strict / 61 loose) | the figure appears only in the round-1 hand-back, not in the tree; recorded here and NOT re-published | — |

### §11.2 The forward closure's measured boundary — what it cannot see, and how deep its customers actually are

Written as MEASUREMENTS, each compiled at `-O1` and run through BOTH binaries,
because "the walk is bounded at depth 8" says nothing about where the real
customers sit.

| probe | shape | HEAD | ORACLE | reading |
|---|---|---|---|---|
| `x01`, `x05`, `x07`, `y05`, `x23`, `x22` | **depth 1** off `H`, register LIVE and MEASURED | DECLINE (F2) | DECLINE | the fenced six — every measured customer is depth 1 |
| `b5_depth2` | depth 2 (`t+1`, then `*2`), register LIVE | DECLINE `control flow` | DECLINE `control flow` | **no fold at all**: the arm's arg-0 stays the TAINTED `%4`, so it is the Inc-1 CHAINED class and R3 refuses the cross-handle mux. F2 never runs |
| `b4_deep3` | depth 3 (`+1`, `*2`, `^3`), register LIVE, seed IS the pinned value | DECLINE `control flow` | DECLINE `control flow` | same |
| `b1_sel_live` | the pinned value reached through a `select`, LIVE | DECLINE `control flow` | DECLINE | the φ/`select` direction has **no live customer today** |
| `b2_cast_live` | the pinned value reached through a `sext` to `long long`, LIVE | DECLINE `control flow` | DECLINE | the CAST direction likewise; R1's `x67`/`x68`/`x70` measured the same, because keeping the cast rail live SUPPRESSES the fold |
| `k03`, `k04`, `r3`, `r4`, `r6` | the pinned register DELETED | **ACCEPT** | DECLINE | the residual (§14.11 Q3) — unchanged at five, and `k03` is `x23` with the `cq_measure` removed |

**So the depth-8 / 64-value budget is generous relative to every measured
customer, and NOTHING PINS DEPTH ≥ 2** — that is §9 worry 14(c), stated here with
its measurement rather than as a feeling. The reason is legible: `-O1` only folds
the arm's operand when the arm's USE of it is edge-dominated, and a longer chain
gets hoisted into the entry block where the edge fact does not reach it, leaving
a TAINTED arg-0 and therefore a chained arm rather than a state prep.

> ⚠ **AND ONE PROBE-HARNESS BUG IS RECORDED BECAUSE IT ALMOST WENT INTO THIS
> TABLE.** A first run of `b4`/`b5` reported **ACCEPT on both binaries**. It was
> a zsh word-splitting bug in the probe loop (`set -- $B` does not split in zsh,
> so the plugin arguments were empty, `cq-opt` failed for an unrelated reason, and
> the `grep` for a diagnostic found nothing → scored "ACCEPT"). Re-run correctly,
> both DECLINE. Two harnesses lied to this agent in one session (see §7b's
> injection control); **budget for the harness being wrong, not just the
> compiler.**

### §11.3 What the round did NOT do, and why

* **It did not add `..._global_seed.ll` or `..._eqfold_range.ll`, although the fix
  brief said "add them".** Both were MEASURED to be duplicates (F-R2-4's evidence
  column), and this tree's own standard for that case is written in
  `..._constexpr_seed.ll`'s header: *"the two rows are ONE fixture and committing a
  second would be a false coverage claim"*. Raising the fixture count without
  raising the discrimination is the number-that-measures-the-wrong-thing failure
  this project keeps paying for (the retired `165/174` class). The rows are
  annotated with where they actually live instead. **This is a deliberate
  deviation from the brief's letter and it is recorded here rather than done
  silently.**
* **It did not fence F-R1-3 (the known-bits hull).** Fencing it means enumerating
  `Known`-consistent values, which is a new mechanism for a class that is
  **measurably unreachable from plain C at this clang** — the two analyses fail
  together. It ships as a retirement trigger with its boundary measured in both
  directions (`hb01`/`hb02` accept, `hb03`/`hb04` decline).
* **It did not adopt a `DomConditionCache`.** F-R1-2 records that F2 *could*, today,
  and that it is the trigger that actually bites — but adopting it widens the
  analysis under an accept predicate with no red-green family behind it, which is
  a round-3 decision, not a fix-agent one.
* **It did not touch anything on the owner's desk**: `angleSelectArmsAdmissible`
  clause (2c), S7 of `classifyAngleSelect` (`drbq.11`), the Rz peephole's RAUW
  target (`drbq.10`), the P4 loop-invariant-condition fence (`drbq.12`), or the
  §14.11 Q1–Q5 questions.
* **It changed no golden and no e2e slice.** `golden_multiset_audit.py --all`: 3
  NEW-FILE (Inc 4's own three), 292 UNCHANGED, 0 routes collapsed.

## §12 — ROUND-3 ADVERSARIAL REVIEW (Rule 13) — every finding, graded, with its fix and its red-green evidence

One lens this round: **R3** (the round-2 FORWARD WALK, adversarially — **450
distinct C programs** (147 new + a 140-program generated opcode sweep + 163
re-run from round-2 lens R1; 472 runs) and 8 hand `.ll` modules through BOTH
binaries, every HEAD accept put through strict stage 2b, linked and RUN).

**THE HEADLINE IS THE SAME MISTAKE A THIRD TIME, AND THIS ROUND IT WAS THREE
MISTAKES WIDE.** Round 1 widened F2's *predicate* (literal → edge range) and left
the *set*. Round 2 widened the *set* to `H`'s **forward** closure and left (i) the
**direction** — `-O1` moves the compare **sideways**, not only downward — (ii) the
**opcode class** — the walk enumerated `BinaryOperator` users while
`IntrinsicLowering.cpp` lowers a curated `llvm.*` family to real rails — and
(iii) the **type gate one line above the walk's caller**, which skipped F2
*wholesale* the moment the rotated register and the (InstCombine-narrowed)
compare sat at different widths. **42 plain-C programs accepted with the rotated
register lowered to a live rail that the source MEASURES and nothing ever
rotates.** All 42 decline on the pre-Inc-4 oracle; all 42 are strict-2b clean,
link and run.

**SO THE FIX IS NOT A FOURTH SET.** F2 now asks its question with LLVM's own
value machinery: `LazyValueInfo` on both edges of the region's branch for the
BACKWARD direction, and an abstract evaluation over the tainted user graph
(`ConstantRange` + `ConstantFolding` + `KnownBits`) for the FORWARD one, with a
conservative DECLINE wherever a pinned operand feeds something that machinery
cannot evaluate. `f2ForwardClosurePinsSeed` is DELETED — not kept as a second
spelling of the same question (the sibling-spelling lesson). The whole argument,
including what it still skips and why, is in `f2SeedPinnedByLiveRegister`'s header
and in PRD §14.2b's round-3 block.

**Every adversarial round this epic has run has found something; the count is now
Inc 1 × 2, Inc 2b × 3, Inc 3 × 3, Inc 4 × 3** — and each Inc-4 find sits inside
the previous Inc-4 fix. §9 items 17–20 name what to aim a fourth round at.

### §12.1 The findings

| # | grade | finding | fix | red-green evidence |
|---|---|---|---|---|
| **F-R3-1** | **CONFIRMED-MISCOMPILE**, 30 plain-C programs | The walk was FORWARD-ONLY from `H`, and `-O1` relocates the compare **SIDEWAYS** onto a fresh instruction that is a **SIBLING** of the rotated register: `icmp eq (sdiv X,C), K` → `icmp eq (and X,-C), K*C`, and `icmp eq (div X,C), K` → `icmp ult (add X,-K*C), C`. Two users of one root; no forward walk from `H` can reach the other. Measured across a generated 140-program sweep (op × constant × signedness): **10 accept, 130 decline, all ten the division family**. Survived every variation: `long long` root, `if/else`, two sequential regions, condition also measured, two-level composition, seed 0, negative seed, `ret` instead of `cq_measure`, register read only through `z=t*2`, and `n07_sdiv_theta2` whose own trace rotates the same wire IN PLACE two lines later | **F2 became SEMANTIC** — `f2SeedPinnedByLiveRegister`. `LazyValueInfo::getConstantRangeOnEdge` on BOTH edges about every tainted integer value LIVE ON THE EDGE recovers `%1 ∈ [20,24)` from `(Val & Mask) == C` and `%1 ∈ [15,18)` from `icmp ult (Val+Off), C`; the forward evaluation then computes `sdiv([20,24),{4}) = {5}` = the seed | `..._reject_stateprep_sideways_sdiv.ll` (rewrite A) and `..._sideways_offset.ll` (rewrite B). **All 30 flipped accept → F2-decline**, measured on the final binary. **Mutation M1** (LVI anchors off) reddens 26 files; **M2** (forward half off) reddens 17 |
| **F-R3-2** | **CONFIRMED-MISCOMPILE**, 8 plain-C programs | `K->getType() == SeedI->getType()` at the caller skipped **all of F2** whenever `-O1` narrowed the compare to the root's width (`foldICmpSExtConstant`), which is what an ordinary `long long t = q;` does. The `sext`/`zext` rail was minted after the region, measured, never rotated. **And it retires a written rationale**: "a cast is a DIFFERENT PHYSICAL WIRE, so following casts would be a pure over-decline" is true about wires and false as a licence — the cast rail being a different wire is exactly why preparing a THIRD wire is wrong when the source rotates the second one and reads it | **THE TYPE GATE IS GONE** from the semantic path. The test is `Constant *` pointer identity against the seed at the seed's own type, asked of every value wherever it lives; the fast path keeps the type test only because an `APInt` comparison needs it | `..._cast_sext_live.ll`, `..._cast_zext_live.ll`, `..._cast_trunc_live.ll`. **Mutation M7** (the shipped type gate restored) reddens **exactly** those three plus the two `i1` files. The ACCEPTS `..._cond_cast_seed.ll` / `..._cond_bitcast_seed.ll` are UNTOUCHED, and the honest discriminator is now written in both: `-O1` folded their cast away and no `sext`/`bitcast` instruction survives to be asked about |
| **F-R3-3** | **CONFIRMED-MISCOMPILE**, 4 plain-C programs | The SET was `BinaryOperator`-only while `intrinsicStem` curates **16** integer `llvm.*` intrinsics that lower to real rails. The 4 INVERTIBLE members (`bswap`, `bitreverse`, `fshl`, `fshr`) are the ones InstCombine relocates the compare across — an accident of InstCombine, not a fence | **NO OPCODE TABLE.** Once every operand is pinned, F2 asks LLVM's own `ConstantFoldCall` / `ConstantFoldInstOperands`; and `ConstantRange::intrinsic` covers exactly the set IPSCCP's `visitIntrinsicCall` uses, so the model tracks `clang` rather than approximating it | `..._intrinsic_{bswap,bitreverse,fshl,fshr}.ll` (the last spelled with the sibling `llvm.fshr`, so the family does not exercise one id twice), plus the ACCEPT `..._stateprep_intrinsic_bswap_accept.ll` — the same module with the seed 5 → 7 — which is the ONLY file that separates the EXACT fold from the conservative decline (**M5**) |
| **F-R3-4** | CONFIRMED-OVER-ACCEPT, **UNFIXED, and the boundary is re-derived** | F-R1-4's boundedness argument ("a register is deleted only when nothing reads it, so the difference is a leaked ancilla nothing observes") has a measured counterexample: `n03_k03_derived` is `k03` plus `unsigned z = s*2u;`, `-O1` rewrites `s*2` into `(q>>30)&2` and deletes `s`, so the *register* still has no reader but a value **derived from it is measured** — from an UNROTATED derivation | **NOT FIXED. F2 can only ask about registers that EXIST**, and the semantic form does not change that. §12.2 re-derives the boundary and PRD §14.11 Q3 / §9 item 13 are corrected to R3's own narrowing: *"…confined to a leaked ancilla **when no value derived from the deleted register is observed**"* | `n03_k03_derived` is the ONE of R3's 43 named programs that still ACCEPTS at HEAD. **NEW MEASUREMENT (§12.2): its UNFOLDED twin declines on BOTH binaries** with `cq opcode lowering: operand predates a non-diagonal gate` — the pass-wide stale-record guard — so the class is reachable ONLY through the fold, the Inc-2b F-11 structure exactly. No fixture is added: pinning a known over-accept as an accept fixture would bless it |
| **F-R3-5** | positive result, and it removed an over-decline | The depth-8 / 64-value walk bound was reachable by ordinary arithmetic: `bd_d09_mixed` / `bd_d11_mixed` (11-deep mixed chains, seed 999999) and `b05_fanout70_seed999` (70 fan-out users) declined on the BOUND alone, no member near the seed | The semantic form has no per-value depth bound: it is a FIXPOINT with one total step cap (`kF2MaxSteps` = 4096), which still DECLINES on exceeding | All three now ACCEPT, correctly. `control_inplace_ry_stateprep_deep_chain.ll` is the red-green (11-deep chain, every member measured, seed unreachable). ⚠ Nothing pins the step cap — see §9 item 19 |
| **F-R3-6** | positive result | No over-decline regression anywhere R3 looked: 253/253 family fixtures, 3/3 e2e slices, 297 matrix cells byte-identical to the record, 14 of 15 §14 accept shapes accepting, and not one `ORACLE=ACCEPT → HEAD=DECLINE` row in 302 probes | nothing to fix | RE-CONFIRMED on the round-3 binary over the SAME 480-program set: **44 accept→decline (42 of the 43 named + `hb01`/`hb02`), 3 decline→accept (F-R3-5's three), 0 other string changes, 0 ORACLE drift**, and full `ir-pass-lit` **1572 passed / 1 XFAIL / 0 failed** over a 1573-fixture corpus |
| **F-R3-7** | DOC-FALSE ×3 | (1) the "casts are a different wire ⇒ following them is a pure over-decline" paragraph; (2) the walk header's "MONOTONE … can only ever ADD declines", true of the walk and misleading as a summary of F2 because the type gate above it could remove EVERY decline; (3) `warnLiveRecordRotations` looks like a backstop for this class and is not | (1) and (2) rewritten at the site and in PRD §14.2b — the honest discriminator is *whether the other wire EXISTS in the module*, and there is no gate above the semantic call any more; (3) written where a reader would assume it | (3) is re-measured, not taken from the report: `cq rotation lowering: non-diagonal gate over a live derived record` FIRES on the unconditional twin `u06` and is SILENT on all 42, because the gate's wire is the fresh `cqrt_alloc` handle whose record set is empty by `RecordSet::push` clause 5 |
| **F-R3-8** | **NEW, found by the fix agent while fixing F-R3-2/3: the `i1` STATE-PREP WIDTH IS OUT** | The branch condition is itself a tainted `i1`, pinned to `true` on one edge of its own branch and `false` on the other, so EVERY `i1` seed collides. The ARM half is plain-C reachable and was a live miscompile behind the type gate: `_Bool c=(q==5); _Bool r=1; if (c) r=cq_theta(c,0.9);` arrives as `cq_theta_i1(i1 true,…)`, an in-place Ry on the FLAG | **Accepted as a real narrowing of the shipped accept class.** `control_inplace_ry_stateprep_i1.ll` (an ACCEPT) is re-homed as a decline. This is the one thing in the round that costs capability, and it is flagged for the owner rather than buried | `..._reject_stateprep_i1_arm_flag.ll` (the reachable ARM half, transcribed from `q/z02`) and `..._reject_stateprep_i1_flag_pinned.ll` (the MERGE half, the re-homed fixture). **M7 reddens both**, i.e. the type gate was the sole thing standing between the arm half and an accept. **Honesty about the merge half is IN the fixture**: 3 plain-C spellings of "the straight-through value IS the flag" (`q/z01`, `q/z03`) are NOT folded by this clang and decline earlier anyway, so the merge half is an over-decline AT THIS CLANG — kept because "absence of evidence is not a fence" and because carving the condition out would re-open the arm half. **The merge EDGE itself is not speculative**: `q/z05`/`q/z06` are plain-C programs where the straight-through incoming IS a live measured register `-O1` folds to the seed (`..._merge_edge_sideways.ll`) |
| **F-R3-9** | **NEW, and it retires round-2's F-R1-3 retirement trigger** | `ConstantRange::fromKnownBits` is a hull and cannot represent `{0,4}`; `hb01`/`hb02` were recorded as a hand-IR-only over-accept with the fix named but not built | **BUILT.** `f2Refine` enumerates the ≤ 256 `Known`-consistent values whenever `KnownBits` leaves ≤ 8 bits unknown and intersects them with the range — applied to EVERY value the walk learns about, which the semantic form makes cheap | `..._reject_stateprep_range_knownbits_enum.ll`. `hb01`/`hb02` flip accept → decline; `hb03`/`hb04` were declining and still are; `..._cond_derived.ll` (5 unknown bits) still ACCEPTS. **Mutation M4** (enumeration off) reddens exactly the new fixture |
| **F-R3-10** | **NEW, found by the fix agent, CONFIRMED-MISCOMPILE from plain C** | **NO fp SEED WAS EVER ASKED F2's QUESTION AT ALL.** The shipped clause opened with `SeedI = dyn_cast<ConstantInt>(RotBase)`, so an fp seed made the whole block vacuous — a SECOND gate beside F-R3-2's type gate, either of which alone was enough. Measured from plain C: `double t = (double)q; double r = 5.0; if (q == 5) r = cq_theta(5.0, 0.9);` folds the arm's arg-0 to `double 5.0` and leaves `%7 = sitofp i32 %1 to double` **alive and MEASURED**, unrotated | The semantic form needs **no fp arm**: the test is `Constant *` POINTER IDENTITY (LLVM uniques `ConstantFP` on `APFloat` BITS — F1's discipline reused) and `ConstantFoldInstOperands` folds the `sitofp` exactly once `%q` is pinned | `..._reject_stateprep_fp_seed_sitofp.ll`. **Mutation M8** (restore the `ConstantInt`-only seed gate) reddens exactly that one file. ONE-TOKEN CONTROL measured from plain C: the same program with seed `7.0` ACCEPTS (the `sitofp` folds to `5.0` ≠ seed), strict-2b clean, linked and run; the width control `..._stateprep_f64.ll` (an fp prep with no fp rail in the module) still accepts. ⚠ The `fcmp` CONDITION side is UNCHANGED and still declines unfolded on R4 — what moved is the SEED side. **⚠ THE GRADE'S WORDING IS CORRECTED 2026-09-05 (round-4 review, lens R4, F-R4-6): read "CONFIRMED-MISCOMPILE from plain C" as *the AMBIGUITY argument, not a wrong unitary observed on that program*.** The fixture's own header C writes `cq_theta(5.0, 0.9)` LITERALLY, so on THAT source the fresh-rail lowering is what the author asked for; what makes the module unsafe is that a SECOND source — `cq_theta(t, 0.9)` with `t` the live `sitofp` — could fold to the same IR, and R4 MEASURED that `clang -O1` does NOT produce it (`p/fp09`: `EarlyCSE` runs before `IPSCCP`, so the arm's cast is merged with the pre-branch one and `PredicateInfo` has nothing to rename). **The fixture is right to decline — the IR IS the ambiguous form — and the LABEL was inviting a later reader to believe a clang-reachable wrong unitary had been measured there.** The same correction applies to `p/wd08_i64seed_i32pin` (F-R4-6's other half), whose would-be-ambiguous twin `p/am01_ll_chained` is likewise not folded at LLVM 19 |

### §12.2 The DELETED-REGISTER residual, re-derived — the FINAL boundary statement

F-R1-4's argument was *"a register is deleted only when nothing reads it, so the
difference is confined to a leaked ancilla that no `cq_measure`, `ret` or tape
write observes"*. R3 refuted the **conclusion** and not the premise. The corrected
statement, with every member re-measured on the round-3 binary:

| program | the deleted register | what is observed | disposition | reading |
|---|---|---|---|---|
| `k03_signbit` | `s = ((unsigned)q)>>31` | `r` only | ACCEPT | nothing derived from `s` is observed — **(a)**, the leaked-ancilla half, and F-R1-4's argument stands verbatim |
| `k04_bool_flag` | `b = (q!=0)` | `r` only | ACCEPT | same |
| `r3_sel` | `t = q ? 1 : 0` | `r`, `q` | ACCEPT | `q` is the ROOT, not a derivative of the deleted register; its rail is unrotated in both readings — **(a)** |
| `r4_negflag` | `b = (q==5)` | `r`, `q` | ACCEPT | same |
| `r6_flagship_ambig` | `b = (q!=5)` | `r`, `q` | ACCEPT | same; `@slice` body BYTE-IDENTICAL to the flagship slice's |
| `n09`/`n10`/`n11` | the F-R3-1/2/3 shapes with the reader dropped | `r` only | ACCEPT | same — the one-token controls for the three fixed classes |
| **`n03_k03_derived`** | `s = ((unsigned)q)>>31` | `r`, **and `z = s*2u`** | **ACCEPT** | **(b)** — a value DERIVED from the deleted register IS observed, and it is computed from an UNROTATED derivation |

**The brief's (a)/(b) question, answered for `n03`.** `z` is computed **after**
the region in the source and reads `s` **after** `s` was rotated, so it is (b), a
stale-record read of the pre-rotation name — **not** a value computed before the
region that legitimately holds the folded constant. **MEASURED, not argued:** the
unfolded twin (`$S/fix3/q/z07_n03_unfolded.ll`, the same module with the arm's
theta taking `%s` and `z = mul %s, 2`) declines on **BOTH** binaries with
`cq opcode lowering: operand predates a non-diagonal gate` — CQ's pass-wide
stale-record guard. The emitted circuit for the folded form computes `z` from
`cq_template_lshr_i32_hl(h0,30)` / `cq_template_and_i32_hl(h3,2)`, i.e. from `q`'s
unrotated rail, while the rotation went to a fresh `cqrt_alloc_i32(1)`.

**So the final boundary statement is:**

> F2 can only ask about registers that EXIST in the module. When `-O1` DELETES
> the rotated register, the difference between "rotate that rail" and "rotate a
> fresh rail prepared to the same pinned value" is confined to a **leaked ancilla
> that nothing observes — ONLY WHEN no value derived from the deleted register is
> observed either**. When one is (`n03`), the difference IS observable and the
> program is an over-accept whose source spelling CQ refuses outright. That case
> is reachable ONLY through the fold, which is the Inc-2b F-11 structure, and it
> is filed at PRD §14.11 Q3 rather than fenced, because the only fence anyone has
> proposed for it — decline every state prep whose condition pins any register —
> kills the flagship.

#### ⚠ WIDENED 2026-09-05 (round-4 review, lens R4, finding F-R4-2). CASE (b) IS A SHAPE, NOT A PROGRAM — 6 MEMBERS, 3 OBSERVATION FORMS, ONE OF THEM `return`

The verdict above is UNCHANGED and the severity argument is not. §12.2 as first
written reads as though the observable-derivative case were one exotic program
(`n03_k03_derived`). R4 wrote five fresh plain-C members, each ORACLE-decline /
HEAD-accept, strict-2b clean, LINKED and RUN, and the class is legible as one
sentence: **a sign or flag bit tested as the condition and then SCALED**.

| program | the deleted register | what is observed | how |
|---|---|---|---|
| `n03_k03_derived` (round 3) | `s = ((unsigned)q)>>31` | `z = s*2u` | `cq_measure` |
| `p/dr01_sign_x4` | `s = q>>31` | `z = s*4u` | `cq_measure` |
| `p/dr02_sign_shl` | `s = q>>31` | `z = s<<3` | `cq_measure` — a SHIFT, not a multiply |
| `p/dr09_sign_ret` | `s = q>>31` | `z = s*4u` | **`return z`** — a tainted handle ESCAPES; no `cq_measure` of `z` at all |
| `p/dr10_sign_chain` | `s = q>>31` | `z = (s*4u)+7u` | `cq_measure`, TWO hops past the rotation |
| `p/dr12_sign_x4_meas_q` | `s = q>>31` | `z = s*4u` **and `q`** | `cq_measure` ×2 |

The whole family is one C line apart (`$S/review4/R4/p/dr*.c`):

```c
unsigned slice(void){ unsigned q=cq_theta(3u,0.3); unsigned s=q>>31; unsigned r=1u;
                      if(s) r=cq_theta(s,0.9); unsigned z=s*4u;
                      return (unsigned)cq_measure(r)+(unsigned)cq_measure(z); }
```

`-O1` rewrites `s*4` into `(q>>29)&4` and DELETES `s`, so the REGISTER has no
reader and F2 has nothing to ask about — while `z` reads the rail the source says
was rotated, through an UNROTATED derivation. `dr01`'s emitted circuit:

```
cq_template_icmp_sgt_i32_hl(h0,-1) -> h1 ; cqrt_x(h1)
cqrt_alloc_i32(1) -> h2 ; cqrt_ry_i32_controlled(h1,h2,0.9) ; cqrt_x(h1)
cq_template_icmp_sgt_i32_hl_unc(h1,h0,-1) ; cqrt_free(h1)
cq_template_lshr_i32_hl(h0,29) -> h3 ; cq_template_and_i32_hl(h3,4) -> h4   ; z, from q's UNROTATED rail
cqrt_measure_i32(h2) ; cqrt_measure_i32(h4)
```

**THE BOUNDARY STATEMENT IS RE-DERIVED, NOT INHERITED.** R4 built the unfolded
twin of the widened shape (`h/hd01_dr01_unfolded.ll`) and ran it on BOTH
binaries: it declines with `cq opcode lowering: operand predates a non-diagonal
gate`. So the final sentence above generalises VERBATIM over the six — reachable
ONLY through the fold, and CQ refuses the source spelling outright.

**AND `dr09` IS THE ONE THAT MOVES SOMETHING.** Every earlier member observed
through `cq_measure`; `dr09` observes through `return`, i.e. the derived handle
ESCAPES the function. That is worth naming because §12.2's original wording
("no `cq_measure`, `ret` or tape write observes") already listed `ret` — it was
never measured for this class until now, and it is.

**STILL NOT FENCED, STILL NO FIXTURE**, for the reasons §12.4 gives: F2 can only
ask about registers that EXIST, every proposed fence declines the flagship, and a
fixture that pinned any of the six as an ACCEPT would BLESS a known over-accept
(the `..._constexpr_seed.ll` precedent). What changes is the RECORD: PRD §14.11
Q3 and this section now describe a SHAPE with six named programs, not an anecdote.

### §12.3 The mutation table

Each row: patch the shipped source, rebuild BOTH targets, run the full
`ir-pass-lit`, restore **and rebuild** (a mutant left in `build/` is a false
measurement — that happened once in this session and is recorded in §9 item 20).

| # | mutation | fixtures red | reading |
|---|---|---|---|
| **M1** | LVI anchors off (every edge range read as FULL) | **26** | the whole BACKWARD half — all 3 round-3 classes plus every round-1/round-2 range fixture |
| **M2** | the FORWARD half off (anchors tested, users not) | **17** | the sideways, cast and intrinsic families plus the six round-2 `range_forward_*` |
| **M3** | the conservative half off (`return true` instead of `!AnyPinnedOperand`) | **1** — `..._unevaluable_pinned_operand.ll` | the one file that pins "a function of a pinned register we cannot evaluate" |
| **M4** | the `KnownBits` ≤ 8-unknown-bit enumeration off | **1** — `..._range_knownbits_enum.ll` | F-R3-9 |
| **M5** | the EXACT `ConstantFold*` half off | **1** — `..._stateprep_intrinsic_bswap_accept.ll` (an **ACCEPT** flips to a DECLINE) | ⚠ **the intrinsic DECLINE fixtures do NOT pin the exact fold** — with it gone the conservative half declines them anyway, for a weaker reason. Precision, not safety, is what the exact fold buys, and only the accept twin can see it. That accept fixture was written BECAUSE M5 first measured 0 red |
| **M6** | the literal fast path off | **0** | ⚠ **WEAK-PIN, recorded rather than papered over.** The semantic test SUBSUMES it and no fixture can separate them: on `icmp eq H,k` the true edge's exact region IS `{k}`, so anything the literal test catches LVI pins too. It is kept per the brief as an analysis-independent floor, and the honest statement is that nothing in the tree would notice its removal |
| **M7** | the shipped Inc-4 K/seed TYPE GATE restored in front of the semantic call | **5** — the 3 cast fixtures + the 2 `i1` fixtures | F-R3-2 and F-R3-8: the gate was the sole thing standing between five classes and an accept |
| **M8** | the shipped `dyn_cast<ConstantInt>(RotBase)` seed gate restored | **1** — `..._reject_stateprep_fp_seed_sitofp.ll` | F-R3-10: an fp seed used to make the whole clause vacuous |

### §12.4 What the round did NOT do, and why

* **It did not fence `n03_k03_derived`.** There is no register to ask about, and
  every fence proposed for it (decline any state prep whose condition pins a
  register live past the region) kills the flagship — measured: `q` is pinned to
  `{5}` on the flagship's arm edge and is measured after the region. §12.2 is the
  boundary statement; PRD §14.11 Q3 and §9 item 13 carry it.
* **It did not add a fixture for `n03`.** A fixture pinning a known over-accept as
  an ACCEPT blesses it. The `..._constexpr_seed.ll` precedent (a false coverage
  claim is worse than a missing one) applies.
* **It did not adopt a `DomConditionCache`.** `LazyValueInfo` reads the branch
  itself, which is what F-R1-2's trigger was pointing at; a `DomConditionCache`
  would add facts from OTHER dominating branches, and every dominating tainted
  branch declines earlier. Recorded as still-open, not done.
* **It did not touch anything on the owner's desk**: `angleSelectArmsAdmissible`
  clause (2c), S7 of `classifyAngleSelect` (`drbq.11`), the Rz peephole's RAUW
  target (`drbq.10`), the P4 loop-invariant-condition fence (`drbq.12`), or the
  §14.11 Q1–Q5 questions.
* **It changed no golden and no e2e slice.** `golden_multiset_audit.py --all`:
  3 NEW-FILE (Inc 4's own three), 292 UNCHANGED, 0 routes collapsed. The
  `--stateprep` matrix is byte-identical to the committed record (297 cells,
  130/85/40/31/11), which is EXPECTED and is **not** coverage — §9 item 15 stands
  verbatim, and this round is its third demonstration.

---

## §13 — ROUND-4 ADVERSARIAL REVIEW (Rule 13) — every finding, graded, with its fix and its red-green evidence

One lens this round: **R4** (the round-3 SEMANTIC / LVI F2, adversarially — **270
NEW C programs** (105 hand-written, 105 generated EXPR sweep, 60 generated
ordered-predicate sweep) plus the 472-program re-run baseline, **742 program-runs
on BOTH binaries**, and 32 hand `.ll` modules; every HEAD accept through strict
stage 2b, linked and RUN).

**THE HEADLINE IS THAT THE MISTAKE STOPPED REPEATING, AND THE SHAPE OF WHAT IS
LEFT CHANGED.** Rounds 1–3 each found a different subset of a syntactic
enumeration `clang -O1` could reach. Round 4 found **no `clang -O1`-reachable
in-place-Ry-on-a-read-register accept at all** — 270 new programs, 0. The 42
round-3 miscompiles all decline; the 140-program sweep goes 10 accepts → 0; a new
105-program sweep whose 50 members carry a genuine SIDEWAYS or DOWNWARD compare
rewrite (every `sdiv`/`udiv` divisor 2..100 in both rewrite shapes,
`mul`/`shl`/`xor`/`neg`/`not` downward folds, `bswap`/`bitreverse`/rotate
relocation, `sext`/`zext`/`trunc` narrowing, and fifteen two-level compositions no
round had tested) declines every one; a 60-program ordered-predicate range-collapse
sweep declines every one; all 16 curated `llvm.*` rails are pinned by the exact
fold. **That is a change of kind: the fence now tracks the MECHANISM (`IPSCCP` +
`PredicateInfo`, and `CVP` — both LVI-shaped) instead of a table of its outputs.**

**WHAT WAS LEFT WAS ONE GAP AND ONE WIDENING, AND NEITHER WAS ON THE INTEGER AXIS
THE ROUND-3 FIX WAS AIMED AT.** The gap is that floating point was structurally
invisible to the BACKWARD half — and, worse than the hand module that shows it,
the shipped comment carried a RETIREMENT TRIGGER asserting the clause would need
no change the day LLVM gained the fold. The widening is that the deleted-register
residual is six programs, not one. **The count over the epic is now Inc 1 × 2,
Inc 2b × 3, Inc 3 × 3, Inc 4 × 4.**

### §13.1 The findings

| # | grade | finding | fix | red-green evidence |
|---|---|---|---|---|
| **F-R4-1** | **CONFIRMED-MISCOMPILE (hand IR only at this clang) + DOC-FALSE** | **F2 NEVER ASKS ABOUT A FLOATING-POINT REGISTER.** The LVI anchor loop is `isIntegerTy()`-gated and `getConstantRangeOnEdge` is integer-only, so the BACKWARD half is integer-only BY TYPE, not by liveness. A live f64 `%t` pinned to 5.0 by the region's own `fcmp oeq`, with the seed 5.0, ACCEPTED — emitting a FRESH `cqrt_alloc_f64(5.0)`, rotating THAT, and measuring `%t` UNROTATED. The anchor comment explained only the `DT` half; the `isIntegerTy()` half — the one that removes an entire type family — was not discussed at all. **AND THE WRITTEN RETIREMENT TRIGGER WAS FALSE IN BOTH HALVES**: LVI is defined over `ConstantRange`, so it cannot GAIN an fp edge fact in a form F2 consumes, and F2 offered it no fp value anyway | **AN fp ANCHOR, NOT A WIDER LVI QUERY** (there is no wider query to make). In `f2SeedPinnedByLiveRegister`'s edge loop: an equality `FCmpInst` against a `ConstantFP` seeds `F2State::Cst[otherOperand]` on the edge where the equality HOLDS — `oeq`/`ueq` on the TRUE edge, `one`/`une` on the FALSE edge. The FORWARD half is REUSED unchanged (the exact `ConstantFold*` path already covers every derived fp value), so no second walker was minted. **±0.0 and NaN constants are REFUSED**: `oeq` with `0.0` admits `-0.0`, so the edge is not a singleton and pinning would claim a fact the edge does not carry — which is also exactly why `clang` cannot perform the substitution; a NaN `K` makes the equality edge unreachable (`oeq`) or universal (`ueq`) and never yields a singleton. The caller's fp paragraph and its retirement trigger are REWRITTEN | `..._reject_stateprep_fcmp_oeq_folded.ll` (R4's `h/hf01`, ORACLE `control flow` → HEAD F2 string; it ACCEPTED on the round-3 binary). Two ACCEPT controls: `..._stateprep_fcmp_oeq_twin.ll` (R4's `hf04` — the same program with the diamond removed, byte-identical on BOTH binaries, lowering to ONE in-place `cqrt_ry_f64` on `%t`'s own rail, which is what makes the decline a statement about a wrong UNITARY) and `..._stateprep_fcmp_oeq_negzero.ll` (the same module at `0.0`, which ACCEPTS and is the ONLY thing pinning the ±0.0 refusal — deleting `isZero()` reddens exactly it). **Mutation M-A** (anchor off) reddens exactly the decline; **M-B** (zero refusal off) reddens exactly the negzero accept. A THIRD decline pins the anchor's OTHER **EXACT** half — `..._reject_stateprep_fcmp_une_folded.ll`, `une` on the edge where it is FALSE, which is how `clang` canonicalises `!=` and is the polarity `-O1` usually produces. **The four predicates are NOT symmetric and the fixture says so**: `oeq`-true and `une`-false are EXACT (one bit pattern; the only condition under which `clang` COULD substitute) and are both pinned, while `ueq`-true and `one`-false additionally admit NaN, are therefore pure OVER-DECLINES, and are deliberately left UNPINNED — deleting `FCMP_UEQ` and seeing green is not dead code found, deleting `FCMP_UNE` and seeing green is a broken fixture. A FOURTH pair pins the anchor's HAND-OFF to the forward half — `..._reject_stateprep_fcmp_oeq_derived.ll` (the pin flows one hop: `%d = %t * 3.0` folds exactly to the seed `15.0`, and `%d` is measured) and its one-token accept `..._stateprep_fcmp_oeq_derived_accept.ll` (seed `16.0`) — because the anchor seeds exactly ONE fact and every other fp value is covered by REUSING `f2Model`'s exact-fold path, and NOTHING pinned that reuse at fp. The `clang -O1` shape is UNCHANGED and still declines: `..._reject_stateprep_fcmp_oeq_unfolded.ll` |
| **F-R4-2** | **CONFIRMED-OVER-ACCEPT, UNFIXED, severity correction** | The F-R3-4 deleted-register residual is **6× larger than the one program it was filed on**: five fresh plain-C members (`dr01`, `dr02`, `dr09`, `dr10`, `dr12`), each ORACLE-decline / HEAD-accept, strict-2b clean, linked and RUN, covering three observation shapes `n03` did not — `s<<3`, a post-`*4` `+7` chain, and **`return` instead of `cq_measure`**. It is a SHAPE: *a sign or flag bit tested as the condition and then scaled* | **NOT FIXED**, and correctly so: F2 can only ask about registers that EXIST, and every fence proposed declines the flagship. §12.2 is WIDENED into a six-row table with the programs; PRD §14.11 Q3 carries the same correction. The boundary statement is RE-DERIVED rather than inherited — R4 built `h/hd01_dr01_unfolded.ll` and measured it declining on BOTH binaries with `operand predates a non-diagonal gate` | No fixture, deliberately: pinning a known over-accept as an ACCEPT would bless it (`..._constexpr_seed.ll` precedent). The six programs are named in §12.2 with their sources |
| **F-R4-3** | **DOC-FALSE ×2 + WEAK-PIN, with a MEASURED over-accept behind it** | The conservative half's own paragraph says "if an instruction HAS a tainted operand that is EXACTLY PINNED and we still produce no abstract value for it, we DECLINE … it refuses the whole `load` / `extractvalue` / unmodelled-intrinsic direction". **(1)** `CallBase` took `if (!Callee \|\| !canConstantFoldCallTo(...)) return true;` BEFORE `AnyPinnedOperand` was computed, so for that entire class the rule was never asked. **(2)** A `load` cannot reach the rule AT ALL — it keys on an exactly-pinned operand and a `load`'s only operand is a POINTER. And the fixture that was supposed to pin the rule (`..._unevaluable_pinned_operand.ll`, `llvm.fshl`) IS foldable and therefore reaches the operand loop, so mutating the early return reddened nothing | **THE ORDER IS REVERSED** and the not-foldable branch now DISTINGUISHES: an OPAQUE callee (`@cq_theta`/`@cq_phi`, a specialised clone, any declaration) is still SKIPPED with its original argument, while a call `isCuratedReversibleIntrinsic` accepts — a pure total function CQ LOWERS TO A RAIL — takes the conservative DECLINE. Using that predicate (rather than a second spelling) keeps the "what CQ lowers" and "what F2 refuses to guess at" sets from drifting, Rule 14. `load` / `extractvalue` are documented as SKIPS, with the measurement that no reachable customer exists (tainted stores decline earlier at `declineTaintEscapes`) | `..._reject_stateprep_unfoldable_curated_call.ll` — a `nobuiltin`-attributed `@llvm.bswap.i32` whose operand is pinned to `{5}` and whose seed IS `bswap(5)` = 83886080. **MEASURED ACCEPT on the round-3 binary, DECLINE now**; `nobuiltin` is what makes `canConstantFoldCallTo` refuse a curated id at LLVM 19 (measured — all 16 integer and 13 fp curated ids are otherwise foldable, so this branch has NO live customer and the fixture says so). **Mutation M-C** (early return restored) reddens exactly it. The plain-`bswap` controls are unchanged: `..._reject_stateprep_intrinsic_bswap.ll` declines through the EXACT fold, `..._stateprep_intrinsic_bswap_accept.ll` accepts |
| **F-R4-4** | **CONFIRMED-OVER-DECLINE (safe direction), boundary MEASURED and now PINNED** | `kF2MaxSteps = 4096` is REACHABLE (1000/2000/4000/4090 accept; 4200/8000 decline) and exceeding it DECLINES rather than truncating silently — the correct direction — but NOTHING in the corpus pinned the constant: `grep 4096 ir-pass/test/*.ll` found two files, neither of which reaches the code | **A RED-GREEN PAIR** at N = 4090 (accept) / N = 4200 (decline). The exact boundary was measured while writing them and is in both headers: `Steps = N + 2` (the walk pops `%q` and the tainted `icmp`, both anchors, plus the N chain members), so N=4094 accepts and N=4095 declines — the cap is **EXACTLY 4096**. The shipped pair is looser on purpose so a ±1 change in the anchor count cannot redden a fixture for an unrelated reason. `kF2MaxSteps` is UNCHANGED at 4096 | `..._stateprep_step_cap_under.ll` / `..._reject_stateprep_step_cap_over.ll`. **Mutation M-D** (cap → 8192) reddens exactly the OVER file; **M-E** (cap → 1024) reddens exactly the UNDER file. ⚠ The accept half had to be a LINEAR CHAIN: a 4000-wide FAN-OUT off one handle declines later at `uncompute: dead chain would free a measured register` (Rule 8), so a bound fixture can be silently unwritable for a reason unrelated to the bound. The two files are 132 KB / 135 KB, ~10× the previous largest fixture — paid rather than avoided by shrinking the constant |
| **F-R4-5** | WEAK-PIN | The `Argument` branch of the anchor loop has **no reachable customer**: an `Argument` is tainted only inside a Phase-6 specialised clone, and a clone can never contain a state prep — `p/cl01`/`cl04`/`cl05`/`cl06` decline `cq specialization: callee contains a quantum primitive (cq_*)` on BOTH binaries. Deleting the loop reddens nothing | **Kept as defence in depth, NOT removed** — but recorded so nobody cites it as tested coverage | §9 item 25. No fixture is possible to write |
| **F-R4-6** | CONFIRMED-OVER-DECLINE (accepted cost) ×2, **and a LABEL correction on a committed artefact** | `p/wd08_i64seed_i32pin` declines because `sext({5})` folds to `i64 5`, and its would-be-ambiguous twin `p/am01_ll_chained` is NOT folded by `clang -O1` (measured IR: arg-0 stays `%2 = sext i32 %1 to i64`). **The same reading applies to the committed `..._reject_stateprep_fp_seed_sitofp.ll`**, whose §12.1 F-R3-10 grade "CONFIRMED-MISCOMPILE from plain C" is the **AMBIGUITY** argument, not a wrong-unitary observation on that program — its header C writes `cq_theta(5.0,0.9)` LITERALLY, and R4 measured that `clang -O1` does not produce the sibling that would make it ambiguous (`p/fp09`: `EarlyCSE` runs before `IPSCCP`, so the arm's cast is CSE'd and `PredicateInfo` has nothing to rename) | **No code change** — both fixtures are RIGHT to decline (the IR IS the ambiguous form). §12.1's F-R3-10 row is corrected in place: the LABEL was inviting a later reader to believe a clang-reachable wrong unitary had been measured there | §12.1's row, and this one. Both are safe-direction and both are genuine capability cost |
| **F-R4-7** | positive, and it upgrades F-R3-8 to a measured law | **Every `i1` state prep declines from plain C for a STRUCTURAL reason, and there is no `i1` accept left to construct.** Five spellings (`p/b1_01`-`b1_05`, seed true/false, `==`/`!=`/ordered `>`, `q` measured or not) all decline. The reason generalises to ANY condition, not just equality: the branch condition is itself a tainted `i1` dominating `BI`, LVI pins it `true` on one edge and `false` on the other, both edges are asked, and an `i1` seed is one of exactly those two uniqued constants | nothing to fix | The brief's request is answered in the NEGATIVE with the argument rather than with an absence of evidence. All other widths still accept (`wd01` i8, `wd02` i16, `wd03`/`wd07` i64, `wd04` f32, `wd05` f64, `wd06` i8-root) |
| **F-R4-8** | positive | The semantic form covers everything three rounds broke **plus 50 compare rewrites nobody enumerated**, all 60 ordered-predicate range collapses, all 16 curated intrinsics, `freeze`, same-width `bitcast`, `phi`/`select` merges, two-hop `bswap(bswap)` and `fshl`-then-`add`, orientation-B, `switch` singletons, `goto` diamonds, ternaries, `__builtin_expect`, compound `&&`, nested classical `if`, sequential regions, two taint roots, unsigned wraparound, double casts. **The LVI dominance boundary flagged as a crash precondition is safe**: values defined after the compare, in the arm/merge, and in a non-entry dominator (`h/hc01`-`hc03`) all decline correctly with no crash, and a crash scan of HEAD over ALL 1573 fixtures found **0** exits with a signal | nothing to fix | `gen.tsv`, `gen2.tsv`, `gen.shapes.tsv`, `gen.sideways.txt`, `p/ALLNEW.tsv` |
| **F-R4-9** | positive | **No over-decline regression anywhere**, and the cost of LVI is bounded: `lit` 1573/1572/1 XFAIL/0; the three e2e state-prep slices 3/3; the `--stateprep` matrix's 297 data rows byte-identical to the committed record (130/85/40/31/11); **0** `ORACLE=ACCEPT → HEAD=DECLINE` in 742 runs; 125 HEAD accepts strict-2b clean, linked and run; the 42/3 flip classification EXACT (42 accept→decline are precisely R3's named miscompiles, 3 decline→accept precisely F-R3-5's over-decline removals, 0 verdict-preserving message changes) | nothing to fix | **PERFORMANCE, and R4 says what it does NOT measure**: none of the three libm slices contains a state-prep arm, so F2 — and the whole `LazyValueInfo` construction — NEVER RUNS in them and their ~0.02 s delta is noise. The real rows are synthetic: 2000 tainted values × 1 region 0.09 s, × 4 regions **0.13 s vs 0.07 s**, 8000-user fan-out 0.38 s. Cost is roughly linear in (regions × tainted values) with a fresh `LazyValueInfo` per region. No blow-up, and `kF2MaxSteps` bounds the tail. ⚠ **Every figure in this row is R4's, measured on the PRE-mini-fix binary and a 1573-fixture corpus.** The post-fix witnesses are separate and are: full `ctest -j6` **327/327, 0 failed, 348.96 s**; full `lit ir-pass/test` **1582 discovered / 1581 passed / 1 XFAIL / 0 failed**; `cq_opt_equivalence --stride 8` **198 of 1582 sampled, 0 mismatches**; the `--stateprep` matrix **297 data rows byte-identical** to the record; the three e2e state-prep slices **3/3**; and a HEAD-vs-pre-Inc-4-ORACLE sweep of the whole fixture corpus in which **94 rows differ, ALL of them in the state-prep family, 0 outside it, and 0 in the `ORACLE=ACCEPT → HEAD=DECLINE` direction** |

### §13.2 The mutation table

Same discipline as §12.3: patch the shipped source, rebuild **BOTH** targets, run
the full `ir-pass-lit`, restore **and rebuild** (§9 item 20 — a mutant left in
`build/` has lied to a fix agent in this increment already).

| # | mutation | fixtures red | reading |
|---|---|---|---|
| **M-A** | the fp ANCHOR off (the edge-seeding call removed) | **3** — `..._reject_stateprep_fcmp_oeq_folded.ll`, `..._reject_stateprep_fcmp_une_folded.ll`, `..._reject_stateprep_fcmp_oeq_derived.ll` | F-R4-1. ⚠ **RE-RUN on the final 1582-fixture corpus.** It first measured **1**, on the corpus that existed when the anchor's other two declines had not been written yet; rather than leave a stale figure or quietly project a new one, the mutation was re-run after the last fixture landed. A mutation count nobody re-ran is a claim, not a measurement — and this increment has already had a mutation harness lie to a fix agent (§9 item 20) |
| **M-B** | the ±0.0 refusal off (`isZero()` dropped from the anchor guard) | **1** — `..._stateprep_fcmp_oeq_negzero.ll` (an **ACCEPT** flips to a DECLINE) | ⚠ the same lesson as M5 one round earlier: a decline-only family cannot pin a PRECISION clause. That accept fixture exists solely for this row |
| **M-C** | the conservative ordering reverted (`return true` before `AnyPinnedOperand`) | **1** — `..._reject_stateprep_unfoldable_curated_call.ll` | F-R4-3. This is the row R4 measured as reddening NOTHING before the fixture was written |
| **M-D** | `kF2MaxSteps` 4096 → 8192 | **1** — `..._reject_stateprep_step_cap_over.ll` (a DECLINE flips to an ACCEPT) | F-R4-4, the upper side of the pin |
| **M-E** | `kF2MaxSteps` 4096 → 1024 | **1** — `..._stateprep_step_cap_under.ll` (an ACCEPT flips to a DECLINE) | F-R4-4, the lower side. Together M-D/M-E bound the constant from both directions, which is what "pinned" has to mean |
| **M-F** | delete `case FCmpInst::FCMP_UNE` (the anchor's OTHER **EXACT** half) | **1** — `..._reject_stateprep_fcmp_une_folded.ll` | the `oeq`-true and `une`-false halves are independently pinned, so neither can rot behind the other |
| **M-G** | delete `case FCmpInst::FCMP_UEQ` **and** `case FCmpInst::FCMP_ONE` (the NaN-admitting halves) | **0** | ⚠ **DELIBERATE, MEASURED, AND WRITTEN INTO THE FIXTURE.** Those two predicates additionally admit `%x = NaN`, so `clang` cannot substitute across them and anything they catch is a pure OVER-DECLINE — removing them can only remove declines. They are kept so the clause has no edge to get backwards, and left unpinned because a fixture pinning them would be pinning an over-decline. A future reader who deletes `FCMP_UEQ` and sees green has NOT found dead code; one who deletes `FCMP_UNE` and sees green has found a broken fixture. That asymmetry is stated in `..._reject_stateprep_fcmp_une_folded.ll` so the 0 here is never read as "unreached, therefore removable" |

### §13.3 What the round-4 mini-fix did NOT do, and why

* **It did not fence the deleted-register residual (F-R4-2).** Unchanged reason,
  now measured over six programs instead of one: F2 can only ask about registers
  that EXIST, and every proposed fence declines the flagship (`q` is pinned to
  `{5}` on the flagship's own arm edge and is measured after the region). PRD
  §14.11 Q3 and notes §12.2 carry the SHAPE.
* **It did not remove the `Argument` anchor branch (F-R4-5).** Defence in depth is
  worth keeping; a WEAK-PIN is worth SAYING. §9 item 25.
* **It did not lower `kF2MaxSteps` to make the fixtures smaller.** That would have
  bought a 26 KB pair by narrowing a real capability, which is the wrong trade:
  the bound's only job is to stop an unbounded walk, and it should be as generous
  as the measurements allow.
* **It did not widen the fp anchor beyond equality.** An ordered `fcmp` does not
  pin a singleton, and every non-equality predicate is left to decline through
  the existing paths. §9 item 21 records that the fp half will not learn anything
  new on its own — the honest form of the retirement trigger the round found false.
* **It did not hide the anchor's PRICE.** The clause costs a `clang -O1`-reachable
  accept — `double r = 5.0; if (q == 5.0) r = cq_theta(5.0, θ);` and its `!=`
  twin accepted at the round-3 HEAD and decline now — which is the fp mirror of
  the integer over-decline PRD §14.11 Q1 already owns, with the same
  one-character workaround. It is MEASURED from C, recorded at §9 item 24 with
  the one-line lever that would give it back, and put in front of the owner
  rather than absorbed silently. **Against the pre-Inc-4 ORACLE there is no
  regression** — the narrowing is of Increment 4's own accept class.
* **It did not touch anything on the owner's desk**: `angleSelectArmsAdmissible`
  clause (2c), S7 of `classifyAngleSelect` (`drbq.11`), the Rz peephole's RAUW
  target (`drbq.10`), the P4 loop-invariant-condition fence (`drbq.12`), or the
  §14.11 Q1–Q6 questions.
* **It changed no golden, no e2e slice and no matrix record — MEASURED, and the
  identity is EXPLAINED rather than lucky.** The three state-prep slices pass
  unchanged (3/3), and `inplace_twin_matrix.py --stateprep --prep-oracle <pre-Inc-4>`
  re-ran all **297 cells** with the tally **130 IDENTICAL / 85
  SUBJECT-DECLINES-TWIN-ACCEPTS / 40 DECLINE-BOTH / 31 DECLINE-BOTH-DIFF / 11
  SUBJECT-ACCEPTS-TWIN-DECLINES** and all 297 data rows BYTE-IDENTICAL to
  `inc4-records/inplace_stateprep_post4.txt` (md5 `919c43c…` on both bodies).
  ⚠ That was NOT a foregone conclusion and was treated as a question, not an
  assumption: the matrix HAS an `fcmp` cond axis and an `f64` width, so a
  seed-matching fp equality cell would have moved. It does not, because the axis's
  `fcmp` cell is an **ORDERED** compare (`double cf = cq_theta(0.5,0.5); if (cf >
  0.5) …`) and the anchor is equality-only. **The identity is therefore evidence
  about the matrix's coverage, not about the change** — §9 item 15 on its fourth
  demonstration: neither reproducer in this round is a program in the corpus, and
  the one plain-C behaviour change the round DOES cause (§9 item 24) is invisible
  here for the same reason.

