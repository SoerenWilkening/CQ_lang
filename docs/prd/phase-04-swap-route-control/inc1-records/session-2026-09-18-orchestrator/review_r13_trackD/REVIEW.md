# Rule-13 INDEPENDENT REVIEW — Track D2, bd `test_C_libtooling-drbq.12`

# VERDICT: **CLEAR-WITH-ITEMS**

Four findings: **one P1 over-accept POPULATION widening of an already-open P1 whose fence carries a
FIRED, unhonoured retirement trigger** (F-1), and three P3 documentation / gate-hygiene items, two of
which are in-tree stale claims of the L7-with-a-twist species (F-2, F-3). **The mechanism itself
holds**: every construction I aimed at the new predicate declined, in the right direction, for a
reason I could read in source. The P1 is not a defect *in* `crossBlockCompareMintable` — it is the
class this landing hands new customers to, and Rule 14 says the fence for it belongs to bd `s82e`,
not to this track. It is reported in the direction CLAUDE.md §4c's own R-1 paragraph reports its
twin: **say the direction first — for `dD1` this landing is an OVER-ACCEPT.**

Binaries verified on disk before anything else (`GATES.md`): ORACLE `9bd01598d574b344…`, SUBJECT
`5ee9d14420c3533a…`, branch `drbq12-hoisted-compare-p4` tip `832ce900`. All `cited:` lines in
`trackD2/GATES.md` re-hashed: **0 stale**.

---

## 1. What I read

`CLAUDE.md` (Prime Directive; Rules 2, 3, 6, 7, 8, 9, 11, 13, 14, 19; CORRECTNESS RISK §1 the
in-place-Ry / state-prep rows, §2 "Condition-wire disposition" whole, §3 L1–L5 + L9 + L10, §4 the
F2/R4 `CondRails` retirement trigger, §4b/§4c the `chainedThetaBetweenDefAndBranch` landing and bd
`hn29`/`leyd`/`52og`, §5 the open list incl. bd `s82e` / `1m5p` / `7845` and the Q-R1-1 CORRECTION).
`$SES/PROTOCOL.md`. SUBJECT `trackD2/FILE_SURFACE.md` whole incl. §6 errata; `IMPL_D2b.md` whole
(both self-rounds, both "findings worth attention"); `trackD2/GATES.md`; `trackD2/probes/`.
`control-in-place-PRD.md` §13.2 row W and §13.10 Q1. `$PREV/trackP/` (`chainedThetaBetweenDefAndBranch`'s
origin and its availability trigger) and `$PREV/review_r13_armclassify/REVIEW.md`.

The diff hunk by hunk (`git -C <SUBJECT> diff cff8f7ac..832ce900 -- ir-pass/src/ArmClassify.cpp
ir-pass/test tests/e2e`), then, in source, the things the diff depends on and does not contain:
`anyInstructionInGap` (2780–2842), `condProvenance` (281–310), `railWireClosure` + `forwardRailHop`
(455–600), `condWireDisposition` (3067–3150), `railCondWireDisposition` (3196+), `classifyPhaseKickback`
steps 5a/5d/6 (6660–6730, 7100–7250), `classifyArms`' ordering (4433 / 4553–4564 / 4607 / 5146 F1 /
5263 F2 / 5459), `f2SeedPinnedByLiveRegister` (1939+), `ArithLowering.h`'s G6 header (140–215) and
`ArithLowering.cpp`'s G6/G7 loop (699–795), `RotationLowering::warnLiveRecordRotations` (1040–2110)
and `LoopLowering::declineDephasingUnmarkedLoopRails`' header block (4000–4090). All 13 new/converted
fixtures' headers. `bd show test_C_libtooling-drbq.12`. Track X's parked `99269301` diff.

---

## 2. Attack table

Every row: constructed probe, run on BOTH binaries through `$SES/PROTOCOL.md`'s per-probe pipeline
(`clang -O1 -g`, `cq-opt`, `free_pairing_check.py`, link+run). Sources and the runner are in
`probes/`. "right?" is my verdict on the emitted circuit, by analytic/trace reasoning (no simulation).

| # | probe | one-operand delta | ORACLE | SUBJECT | right? | why |
|---|---|---|---|---|---|---|
| A0 | `dA0_baseline.c` | the bead's own customer | D `condition predates…` | **A** | ✅ | mint PER TRIP at `BI` on an unmoved rail; `h0` read only as mint/strip arg-0 and as the control; ONE flag, stripped and freed each trip. STRICT 2b `2 rail / 2 left allocated / 1 template rail 0 dirty / 1 free site: 1 verified, 0 violation` |
| A1 | `dA1_inplace_theta_on_cond_in_body.c` | + `t = cq_theta(q,.1)` in the body | D | **D** `condition predates…` | ✅ | the SSA name is invariant, the RAIL is relabelled per trip. Caught TWICE: the gap walk (the body reaches `Pred` around the back edge, and `q ∈ Members`) and the position-aware `wireGainsNonDiagonalGate` |
| A2 | `dA2_measure_in_gap_flat.c` | `cq_measure(q)` in the gap (flat, CSE'd) | D | **D** `condition measured before the control route` | ✅ | `condDataUseDisposition`'s `MeasuredEarly` is anchored at `Pred->getTerminator()`, so it is block-independent — D's R-8(c) verified by construction |
| A3 | `dA3_measure_in_gap_loop.c` | same, ROLLED | D | **D** same string | ✅ | as A2 |
| A4 | `dA4_theta_on_cond_in_gap_flat.c` | chained theta on `q` in the gap (acyclic) | D | **D** `condition predates…` | ✅ | the wire-scoped scan's core case |
| A5 | `dA5_inplace_add_in_gap.c` | `u = q+1` between two CSE'd regions | D | **A** | ✅ | ⚠ **`-O1` SINKS the add out of the gap** (`%12 = add` lands in the post-region block) — so this probe does **not** exercise the interlock; it is recorded because it looks like it does. Emitted `cqrt_addc_i32(h0,1)` runs LAST, after both mints; `u` correctly occupies `h0`; `q` is never read again |
| A6 | `dA6_value_arm_then_crossblock_phase.c` | region 1 a VALUE arm | A | **A, identical md5** | ✅ | unmoved |
| A7 | `dA7_three_seq_regions.c` | THREE sequential regions, one CSE'd compare | D | **A** | ✅ | three independent mint/gate/strip/free groups on an unmoved `h0`; STRICT 2b 3/3 verified. The `hcrg` precedence graph orders them in source order |
| B1 | `dB1_stateprep_hoisted.c` | controlled STATE PREP under a hoisted compare | D | **A** | ✅ | **a genuinely NEW surface**: `condWireDisposition` is called at `:4607`, F1 at `:5146`, F2 at `:5263`, so a cross-block compare now reaches the state-prep fences for the first time. Stream: fresh `cqrt_alloc_i32(3)` per trip, `ry_controlled`, strip, free. No new LVI hazard — the anchor is `BI`, not `Cond`, and a cross-block `Cond` dominates `BI` by SSA |
| B2 | `dB2_sharecondflag_hoisted.c` | the compare ALSO read as data | D | **D** `condition predates…` | ✅ | `!R.ShareCondFlag` holds. Verified in source that `Region.ShareCondFlag` is assigned at `:4564` / `:7129`, i.e. BEFORE both `condWireDisposition` call sites (`:4607` / `:7214`) |
| B3 | `dB3_tree_hoisted_leaf.c` | tree: invariant leaf hoisted, variant leaf in `Pred` | D `control flow` | **A** | ✅ | step 5a's widening. Per trip: two leaf flags, `cqrt_toffoli` root ancilla, `cqrt_rz_i1`, toffoli, free, both leaf strips+frees. `h0`/`h1` read only as mint arg-0 |
| B4 | `dB4_nested_loop.c` | compare hoisted out of a NESTED loop | D | **D** `control flow inside a loop body` | ✅ | the loop layer refuses nested loops before detection — D's R-4 confirmed |
| C1 | `dC1_clone_call_in_gap.c` | a `noinline` callee rotating its handle, in the gap | D | **D** `cq specialization: callee contains a quantum primitive` | ✅ | the vocabulary gap (`railRelabellingGateOn` matches `cq_theta_*` BY NAME) is not reachable through a clone: specialization refuses the callee first |
| C2 | `dC2_classical_call_arm_then_crossblock.c` | 6.5 classical-call arm then cross-block | A | **A, identical md5** | ✅ | unmoved |
| C3 | `dC3_angle_select_hoisted.c` | Rz-stem folded angle select, in a loop | D | **D** `control flow inside a loop body` | ✅ | the angle select's own cross-block decline (`AngleSelectEmit` S6) is FILED not built; the loop layer refuses first |
| C4 | `dC4_bool_compare_hoisted.c` | `_Bool` rail condition, hoisted | A | **A, identical md5** | ✅ | a rail is not a `CmpInst`; conjunct (1) keeps it on `railCondWireDisposition`, unmoved |
| E1 | `dE1_xor_bridge_in_gap.c` | `x = q ^ 1; cq_theta(x,·)` in the gap | D | **D** | ✅ | P5's own documented residual target. `railWireClosure` crosses the xor forward, so `x ∈ Members` — this is the case where the new scan is STRICTLY STRONGER than `wireGainsNonDiagonalGate` |
| E2 | `dE2_sub_bridge_in_gap.c` | `x = 5 - q` | D | **D** | ✅ | the `sub` half is unconditionally conservative |
| E3 | `dE3_mul_bridge_in_gap.c` | `x = q * 3` | D | **D** `rotation/measure operand predates…` (bd `3d8q`) | ✅ | `mul` has no in-place ABI ⇒ fresh rail ⇒ correctly NOT a member; the stale-reader fence refuses it for its own reason |
| F1 | `dF1_angle_select_crossblock.c` | CSE'd cross-block folded angle select | D `rotation angle` | **D** same | ✅ | filed-not-built residue stays on the strict side |
| F2 | `dF2_select_datamux_crossblock.c` | 4.4 data select on a CSE'd compare | A | **A, identical md5** | ✅ | bd `9ymx` already lifted the select's own blanket decline; unmoved |
| G1 | `dG1_round2_out_theta_in_gap.c` | theta on a 4.4 `%out` in the gap (L1 round-2) | D | **D** `condition data use neither escaped nor measured` | ✅ | reached a different fence; the round-2 window stays constructed-and-not-reached (see §4) |
| **D1** | **`dD1_hoisted_template_cond_then_ry.c`** | condition operand is a HOISTED TEMPLATE rail (`q & 1`), trailing NON-DIAGONAL `cq_theta(q,·)`, `q` measured | **D** `condition predates…` | **A + `warning: … non-diagonal gate over a live derived record`** | ❌ **F-1** | `cq_template_and_i32_hl(h0,1) -> h2` is **never `_unc`'d and never freed** (2b: *1 template rail left dirty*) while `cqrt_ry_i32(h0,.9)` then runs on the register `h2` copies and `h0` is measured — Rule 8 dephasing |
| **D4** | **`dD4_unrolled_twin_of_dD1.c`** | the HAND-UNROLLED twin of D1, same K | **D** | **A**, *0 dirty*, `cq_template_and_i32_hl_unc(h2,h0,1)` + `cqrt_free(h2)` **before** the trailing Ry, **no warning** | — | **the rolled and unrolled halves of one program now compute DIFFERENT unitaries** |
| D5 | `dD5_loopvariant_cond_oracle_reference.c` | same leak, condition made loop-VARIANT so P4 never fired | **A**, 1 dirty, same warning | **A, identical md5** | — | **the DEFECT is pre-existing** (bd `s82e` residual / bd `7845`). This landing widens its POPULATION |
| D2 | `dD2_hoisted_template_cond_nory.c` | D1 minus the trailing Ry | D | A, 1 dirty, no warning | ✅(benign) | a Rule-6 accepted leak: nothing interferes afterwards |
| D3 | `dD3_flat_template_cond_then_ry.c` | D1 with ONE region and no loop | A | A, identical md5 | ✅ | the FLAT form **discharges** `h2` before the Ry — the isolating control that makes D1/D4 a rolled-vs-unrolled divergence and not a general leak |
| D6 | `dD6_diagonal_control.c` | D1 with the trailing gate made DIAGONAL (`cq_phi`) | D | A | ✅(benign) | the isolating control on the hazard's other operand: no interference to destroy |

---

## 3. What I verified as SOUND, in source, because a decline is not evidence on its own

* **The P5 skip is exactly scoped and is a strict relaxation of one predicate, not of the walk.**
  `crossBlockCompareMintable` calls `anyInstructionInGap(C, Pred, Term=BI, …)` with the *same*
  arguments `chainedThetaBetweenDefAndBranch(Cond, R.Pred, BI, …)` would pass — same blocks, same
  `Cyclic` re-scan, same 512-block budget. Only `IsEvidence` differs, and
  `railRelabellingGateOn ⊆ isChainedThetaCall` (it adds `Members.count(A0)`). Short-circuit order
  means the P5 line is reached with `CrossBlockCompare == true` **only** when
  `crossBlockCompareMintable` returned `true`, so D's "one question, asked once" is literally true.
* **Both failure modes decline.** Budget exhaustion returns `true` from `anyInstructionInGap`, which
  `crossBlockCompareMintable` negates into "not mintable" ⇒ `DeclineNow`; `!DT` ⇒ `false` ⇒
  `DeclineNow`. Conjunct (2) `DT->dominates(C, Term)` is, as D says, vacuous for any module the
  verifier accepts, and is the right line to keep.
* **`ShareCondFlag` is never read stale.** `Region.ShareCondFlag = true` is assigned at `:4564`
  (`classifyArms`) and `:7129` (`classifyPhaseKickback`), both strictly before the
  `condWireDisposition` call sites at `:4607` and `:7214`. Step 5a needs no clause because its loop
  is guarded by `if (!IsTree) continue;` above it and the share path is `!IsTree && Cmp`.
* **The dtzb ORDER interlock is real, and I read G6 rather than taking the record's word.**
  `ArithLowering.cpp:700-795` loops over **every** user of the parent `P` and requires
  `provablyBefore(UI, Site, DT)`; the flag mint, emitted by control lowering *before* `lowerOps`,
  reads the condition's handle at `Pred->getTerminator()`, i.e. after everything in the gap. So an
  in-place candidate in the gap is exactly a candidate G6 refuses, and G7 refuses the prior-producer
  variant. ⚠ It is an ORDER property, not a semantic one — but it is written down as one, with a
  retirement trigger joined to the existing G6 pin rather than a new one. That is the correct
  disposition; see F-3 for the two places the record still says otherwise.
* **The tree's split obligation closes.** For a hoisted leaf `L1` and an in-`Pred` leaf `L2`, the
  gap `[L1, BI)` is covered wire-scoped by step 5a; `[L2, BI)` by step 6's in-`Pred` window; anything
  *before* `Pred` precedes `L2` in both source and circuit, so it is consistent for `L2` and is
  `L1`'s scan's business, which it does. The tree ROOT is not a `CmpInst`, so a hoisted NODE still
  dies at conjunct (1) — the node prong really is untouched.
* **The `scanForward` deletion (D2-6) is byte-neutral** for every leaf that reaches step 6 today,
  because the guard is `getParent() == Region.Pred` and `chainedThetaBetweenDefAndBranch` in that
  case *is* `scanForward` expression-for-expression. The φ-leaf loop stays unguarded, correctly.
* **The corpus claim re-derived independently** from the two committed files: 2090 + 2464 rows,
  **14 movers, all D→A, 0 A→D, 0 A→A md5 change** (`GATES.md`).
* **The e2e slice and its hand-unrolled twin are byte-identical** (`diff` empty, 14 lines).

---

## 4. Findings

### F-1 — **P1, OVER-ACCEPT (population).** The landing admits new members of bd `s82e`'s dephasing-leak class, and that fence's own retirement trigger has FIRED and is not honoured.

**Reproducer:** `probes/dD1_hoisted_template_cond_then_ry.c` (RED), `probes/dD4_unrolled_twin_of_dD1.c`
(its hand-unrolled twin at the same K), `probes/dD5_loopvariant_cond_oracle_reference.c` (the
pre-existing reference), plus two isolating controls `dD3` (flat) and `dD6` (diagonal trailing gate).

**Say the direction first: for `dD1` this landing is an OVER-ACCEPT.** A module the ORACLE refused
loudly (`cq controlled lowering: condition predates a non-diagonal gate under quantum control`) now
compiles at exit 0, and the circuit it compiles to leaves an **entangled which-path TEMPLATE rail**
(`cq_template_and_i32_hl(h0,1) -> h2`, never `_unc`'d, never freed — `free_pairing_check` reports
*1 template rail mint(s) of which 1 left dirty*, and `0 violation(s), 0 unproven`) alive while
`cqrt_ry_i32(h0, 0.9)` then runs on the register `h2` copies, and `h0` is measured. That is Rule 8
verbatim — *"a permutation that leaves a rail dirty **and** entangled still dephases under later
interference"* — and it is exactly the reading CLAUDE.md §5's Q-R1-1 CORRECTION installed.

**What is NOT new is the class.** `dD5` is the same program with the condition made loop-VARIANT so
that P4 never fired: it **ACCEPTS on the ORACLE**, with the identical dirty rail and the identical
`warning: … non-diagonal gate over a live derived record`, and its md5 is byte-identical on both
binaries. So the hazardous circuit already ships. **"Pre-existing" is true of the defect and FALSE of
its population** — this landing widens it by a spelling.

**What makes it worth a P1 rather than a note** is the second measurement. `dD4`, the hand-unrolled
twin of `dD1` at the same trip count, **accepts on the subject with `0` dirty template rails**: it
emits `cq_template_and_i32_hl_unc(h2, h0, 1)` + `cqrt_free(h2)` *before* the trailing Ry, and emits
no warning at all. `dD1` and `dD4` are the same program and they get **different unitaries**. Both
were loud declines on the oracle; both are accepts now; the divergence is newly reachable. That is
`bd 1m5p` class A's signature (*"a hoisted loop-invariant derived chain whose top rail the ROLLED
form leaves allocated and the flat form discharges"*), and CLAUDE.md files it as
owner-disposition-pending.

**The trigger that fired.** `LoopLowering::declineDephasingUnmarkedLoopRails`' header block carries:
> ⚠ RETIREMENT TRIGGER for this whole block: **any NEW member of the class**, and bd `tu9q` by name
> … Re-derive it, and the accept fixtures' headers, from whatever the conjuncts then say.

`dD1` is a new member (it exits 0 and warns twice-over — the `b11_cmp_rail_data` residual the same
block names as *"the one member THIS fence misses"*, bd `7845`, P1). Track D did not add a caller to
that fence, but it added members to the class the fence is about, and the trigger is written for
exactly that. This is the MIRROR-of-L3 lesson CLAUDE.md records as having cost a P1 filing on
2026-09-14, one increment later.

**No fence is owed HERE, deliberately.** A second spelling of another track's fence is the drbq
Inc-3 (b′) defect (Rule 14). The red-green pair to write **with** bd `s82e`'s fence is: RED `dD1`,
GREEN `dD3` (the flat twin, which discharges), isolating controls `dD6` (trailing gate diagonal) and
`dD2` (no trailing gate). ⚠ And note the instrument problem this exposes: **none of Track D's gates
could see it** — there is no fixture for the shape, stage 2b reports `0 violation(s)` (it *counts*
the dirty template rail and does not fail on it), the track's new e2e twin pair is a different shape,
and the twin matrix (which CLAUDE.md calls the only instrument that can see a leaked TEMPLATE-minted
rail) was correctly not run by this track and has no cell for a hoisted-TEMPLATE condition.

**bd-fileable text (do NOT file from here):**

> Over-accept (population): bd `drbq.12`'s cross-block-compare admission hands new members to bd
> `s82e`/bd `7845`'s in-loop dephasing-leak class, and `LoopLowering::declineDephasingUnmarkedLoopRails`'
> own retirement trigger ("any NEW member of the class … re-derive it") has fired unhonoured. Measured
> on ORACLE `9bd01598…` vs SUBJECT `5ee9d144…`, 2026-09-17, probes in
> `$SES/review_r13_trackD/probes/`: `dD1_hoisted_template_cond_then_ry.c` (condition operand is a
> hoisted loop-invariant `q & 1` template rail, compare LICM-hoisted, trailing `q = cq_theta(q,0.9)`,
> `q` measured) goes DECLINE→ACCEPT and emits a stream in which `cq_template_and_i32_hl(h0,1) -> h2`
> is never `_unc`'d and never freed while `cqrt_ry_i32(h0,0.9)` runs on the register it copies
> (`free_pairing_check`: 1 template rail left dirty, 0 violations; `opt` warns `non-diagonal gate over
> a live derived record`). Its hand-unrolled twin `dD4` at the same K ACCEPTS with 0 dirty rails,
> emitting `cq_template_and_i32_hl_unc` + `cqrt_free(h2)` BEFORE the Ry and no warning — a
> rolled-vs-unrolled unitary divergence, newly reachable. The class is pre-existing:
> `dD5_loopvariant_cond_oracle_reference.c` (same leak, loop-VARIANT condition so P4 never fired)
> accepts byte-identically on BOTH binaries with the same warning. Isolating controls: `dD3` (flat,
> discharges — ACCEPT on both), `dD6` (trailing gate diagonal — benign), `dD2` (no trailing gate —
> benign leak). Red-green pair to write WITH bd `s82e`'s fence, not as a second spelling of it
> (Rule 14). Invisible to every gate trackD2 ran: no fixture, stage 2b reports 0 violations, the
> track's e2e twin is a different shape, the twin matrix was (correctly) not run and has no
> hoisted-TEMPLATE-condition cell.

### F-2 — **P3, scoping doc, and it is addressed to the very track it misinforms.** `FILE_SURFACE.md` §1 states `condProvenance`'s narrowing direction BACKWARDS, and §6's errata do not correct it.

`trackD2/FILE_SURFACE.md` §1, in the paragraph headed **"What Track X must know"**:

> If Track X narrows or widens `condProvenance`, my `condRailMembers` seed set moves with it in the
> SAME direction … **a narrowing is an over-DECLINE for me (safe)**, a widening is an over-DECLINE
> for me too … My prong is the one consumer of that cone whose failure direction is decline-safe in
> BOTH directions.

That is false in the narrowing half and `IMPL_D2b.md` §2 says so, catching itself mid-sentence:
*"narrowing shrinks the set (fewer members, fewer… no: fewer members means fewer gates count, which
is the ACCEPT direction, so a narrowing of `condProvenance` is an over-ACCEPT risk for me exactly as
it is for R4"*. `condRailMembers` builds a **GATE** set: a smaller set means fewer gap instructions
count as evidence, which is the **accept** direction. FILE_SURFACE §6 files three errata (E1/E2/E3)
and this is not one of them — so the corrected claim lives in the implementation record and the false
one lives in the scoping document the orchestrator and Track X read. This is CLAUDE.md's
L7-with-a-twist (bd `z9t1`) in its exact shape: *a record correction that is not applied where the
claim lives is not a correction.*

⚠ It is not academic. Track X's parked branch `99269301` leaves `condProvenance` untouched and adds a
file-local narrower sibling (`condProvenanceInActivation`, used only by `clobberHoldsPerActivation`),
so the two **compose today**. But the composition leaves `ArmClassify.cpp` with two provenance walks
and a scoping note telling the next agent that narrowing the shared one is safe for D2. The source
comment at `condRailMembers` is correct about *widening* and silent about *narrowing*; it should say
both. **Fix: add E4 to `FILE_SURFACE.md` §6, and one sentence to `condRailMembers`' header.**

### F-3 — **P3, in-tree stale claim, same species as F-2 and shipped in two fixtures.** Two converted fixture headers assert a fence that was BUILT, MEASURED and REMOVED.

* `ir-pass/test/control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll:33` — *"…and its
  vocabulary **WIDENED to the dtzb in-place `add`/`sub`/`xor`**."*
* `ir-pass/test/control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll:40` — *"…and its
  vocabulary widened to the dtzb in-place `add`/`sub`/`xor`."*
* `trackD2/FILE_SURFACE.md:63` (§2) carries the same sentence; §6 E3 corrects §4 but not §2.

`railRelabellingGateOn`'s own header says the opposite, in capitals: *"THE dtzb IN-PLACE
`add`/`sub`/`xor` IS DELIBERATELY **NOT** HERE"*, and FILE_SURFACE §6 E3 records that the fence was a
measured pure over-decline and was removed. **The stale claim points in the dangerous direction**: a
reader concludes the in-place `add` is fenced by this predicate, when the whole of its safety is the
G6/G7 ORDER interlock — a different argument, with a different and already-shared retirement trigger
(*"If M-C's G6 ever admits an in-place op on a rail with a later read, this ground is gone"*). Two of
the four Rule-13 rounds CLAUDE.md L7 records were spent re-deriving a finding that had already been
corrected in a record and not in the source. **Fix: three edits, in the same change.**

### F-4 — **P3, gate hygiene.** The cited `ir-pass-lit` and corpus-sweep lines say 2090; the tree is 2091.

`ls ir-pass/test/*.ll | wc -l` = **2091**; `corpus_5ee9d144.txt` has **2090** rows and the 3rd
`ctest -R ir-pass-lit` line says *"2090 fixtures"*. The file present in the tree and absent from both
is `control_inplace_ry_reject_crossblock_cond_theta_behind_add.ll` — which is, by `trackD2`'s own
account, **the ONE fixture that individually pins `crossBlockCompareMintable`'s gap scan** (the R-3
mutant measurement). It was added after those gates ran. Nothing is wrong (a new fixture has no
oracle row to flip), but the two most-cited gate lines under-report the tree by exactly the file that
matters most. I ran the ≤1 Rule-11 spot check allowed to a reviewer:
`lit -v ir-pass/test --filter 'crossblock'` on the SUBJECT build → *Total Discovered Tests: 2091*,
**13 of 13 PASS**, that file included. **Fix: re-hash the two `GATES.md` lines at hand-off, or note
the +1 as an absence.**

### F-5 — **P3, fixture hygiene (minor).** Three new fixtures carry no L8 retirement trigger.

`control_inplace_ry_crossblock_cond_wire_gate_after_loop.ll`,
`control_inplace_ry_reject_crossblock_cond_wire_gate_in_gap.ll` and
`control_phase_kickback_reject_crossblock_shared_cond_flag.ll` have none (measured by grep; the other
ten do). The first two are the R-2 discriminating PAIR, whose entire evidential value is that they
split **only** on the subject — `IMPL_D2b` §5 says so and the headers say so, but nothing tells the
next agent what would make the pair stop discriminating. The third does carry its mutant measurement,
which is the stronger form, so it is the least of the three. CLAUDE.md L8 says these work.

---

## 5. The single most dangerous accept among the 14 movers

**`ir-pass/test/control_swap_reject_seq_shared_cond.ll`** — two sequential phase regions on one CSE'd
compare. It is the only one of the fourteen whose flip is a **reversal of a written safety argument**
rather than a widening: its shipped header said *"a flag minted at region 2's branch from a compare
that dominates region 1 has no proven relationship to the wire region 1 left behind"*, and this
change declares that sentence false.

**It is the right circuit today**, and I checked the mechanism rather than the prose: under the
register-free kickback a phase arm emits mint → `cqrt_rz_i1` on the FLAG → strip → free and puts
**nothing** on `q` (Rule 7), so region 1 leaves the wire exactly as it found it; and the accept is
not granted on that argument alone — `crossBlockCompareMintable` walks region 1's arm and merge and
finds no relabelling gate on `%c1`'s rail, with the shipped negative one instruction away. My `dA7`
extends it to three sequential regions and the emitted stream is three clean, independent
mint/gate/strip/free groups on an unmoved `h0`, STRICT 2b 3/3 verified.

**Why it is nonetheless the dangerous one:** its correctness is now *contingent on a convention that
lives in another file*. If `SwapRouteEmit` ever again puts a gate on the user's register for a phase
arm — and CLAUDE.md records that **three** earlier phase-arm forms did exactly that, and that all
three made every shipped Grover golden the identity — this fixture silently becomes a miscompile,
with no fence tying the two together. Its L8 trigger names the wrong direction (*"if
`condWireDisposition`'s cross-block prong is narrowed back"*); the trigger it actually needs is
*"if any phase-arm emitter puts a gate on `q`"*.

---

## 6. What I did NOT attack

I built nothing and ran no suite (one `lit --filter` spot check, per PROTOCOL's review row), so I
have no opinion on `ir-pass-lit` beyond the 13 fixtures I filtered, on `^e2e-`, on
`cq-opt-equivalence-full`, or on the twin matrices — and the twin matrix is the instrument most
likely to have something to say about F-1, so its absence is the biggest hole in this round. I did
not attack: the 512-block budget's decline path with a pathological or irreducible CFG, nor a
multi-latch loop; the `switch` (4.5) path and `RegionTreeDetect`'s depth-2 nest, both of which keep
the unconditional decline and are FILED rather than built; a CROSS-FUNCTION spelling of anything (bd
`1yeu` — every instrument in the tree, mine included, is one function per module); the 7.5 QRAM and
7.6 tape surfaces; `-O2`/`-O3`; the injection matrix's MISSED-0 claim (I read it, I did not re-run
it); and the *fix* direction of F-1 — I measured the hazard and deliberately did not design its
fence, because that fence is bd `s82e`'s and a second spelling of it is the defect Rule 14 names.
Finally, I attacked the L1 round-2 window by construction exactly once (`dG1`) and it reached a
different fence; the residual `IMPL_D2b` R-7 carries is therefore still **"probably empty", never
"closed"** — and I did not build the case where a taint-GROWTH event manufactures a member of the
condition's own rail, which is the only shape that could make it live.
