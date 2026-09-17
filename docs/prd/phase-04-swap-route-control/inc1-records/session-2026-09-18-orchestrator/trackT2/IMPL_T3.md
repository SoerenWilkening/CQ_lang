# IMPL_T3 — Group-1 implementation, bd `test_C_libtooling-tu9q`'s hoisted-template half

Session 2026-09-18, worktree `agent-ad443b9a480ffb751`, branch **`tu9q-hoisted-template`**
(mergeable) and **`tu9q-p0-p3-wip`** (preserved, NOT for merge). Every number below has its
command in `GATES.md`; nothing is copied from a record.

> **Read §0 and §6 first.** §0 says what landed and what did not. §6 is the honest list of what
> is NOT claimed, and it is longer than a reader expects.

---

## §0 — WHAT LANDED, PER PIECE

| piece | status | branch | what it buys |
|---|---|---|---|
| **bd `6n1s`** (the P1 over-accept) | **LANDED in TWO commits** — `f6713c0e` + the F-1 fix | `tu9q-hoisted-template` | a MARKED multi-block body discharges its interior rails, and conjunct (1)'s suppression is a PROMISE VERIFIED after `uncompute` rather than a prediction. ⚠ The first commit did **not** close the bead — see §9 |
| **P1** — the real multiplicity test | **LANDED** `f6713c0e` | same | the backstop `Uncomputation.cpp` §4's own comment has been asking for since bd `8h7d.5` round 5 |
| **P2** — the loop-EXIT anchor | **LANDED** `bfb809be` | same | closes bd `1m5p` **and** the LIVE `a1_apost` Rule-8 over-accept |
| **P0** — the component partition | **BUILT, MEASURED, NOT LANDED** | `tu9q-p0-p3-wip` `30b80d7f` | see §5 |
| **P3** — clause (ii-d) + the postcondition | **BUILT, MEASURED, NOT LANDED** | same | see §5 |

**The landed prefix is the one SCOPE_T2 §0 pre-authorises**: *"If the orchestrator wants to
de-risk, **P1+P2 is a complete, closed, independently valuable capability** (bd `1m5p` + the
`a1_apost` class) that touches ONE file and marks NO new body — so it cannot silence Track S′'s
fence."* It touches `Uncomputation.cpp`, `LoopLowering.cpp` and `include/LoopPlan.h`, marks no
new body, and adds no accept that depends on a marking.

**Why P0/P3 stopped**: it works — its three intended customers lower with `mint == _unc` on every
rail and `hoisted_template` measures rolled **40** == twin **40**, multiset identical — but it
moves **8** shipped fixtures, and **two of those are other owners' Rule-13 fences losing their
subject**. One of them (`loop_pairing_reject_round2_falsified`) declines *because* the multiplicity
test was missing, and P1 now supplies it, so its disposition is a question about whether that
fence is retired — an orchestrator/owner call, not an implementer's. §5 has the full ledger. This
is the brief's own instruction for the case: *"STOP at that piece, land the safe prefix, and bring
the question back to the orchestrator with the measurement."*

---

## §1 — bd `6n1s`: REGRESSION-vs-PRE-EXISTING, as a MEASUREMENT

The review owed a one-command check and could not run it (*"this role builds nothing"*). No binary
with the 2026-09-14 hash existed on the box (`git worktree list` + a scan of every `build/` found
only `9bd01598`), so the pre-group tree was exported and built once in a scratch dir at `-j2`.

**It reproduces the named oracle exactly**: `cq-opt`
`0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` — character-for-character the
`0e280fc6…` `REVIEW.md` F-1 names.

| binary | `t5j_twoblock_noexit_rot.c` |
|---|---|
| pre-group `0e280fc6` (`74eabd2c`) | **DECLINE**, exit 1, `cq loop lowering: rolled body leaks a rail entangled with a register rotated after the loop` at `:8:20` (that release's spelling, pre-bd-`c767`) |
| session ORACLE `9bd01598` (`cff8f7ac`) | **ACCEPT**, exit 0, 18 trace lines, 4 `ashr` mints / **0** `_unc` / **0** `cqrt_free`, WARNING only |

⇒ **REGRESSION.** The reviewer's *reasoned expectation* was right and is now measured.

**And the mechanism is read in source rather than inferred.** At `74eabd2c`, `markIfRailLocal` has
exactly TWO call sites, both inside `collapseFlattenedLoopRails` — which returns early unless
`taint.InLoopFlattenedPreds` is non-empty. `t5j` has **no tainted control flow at all**, so nothing
ever marked it. At `cff8f7ac` there is a THIRD call site, `LoopLowering.cpp:5471-5474` — bd
`tu9q`'s round-1 root-mint escape — which marks a body with **no region in it**. Conjunct (1) then
suppressed the dephasing fence on a body the spine had never been asked to discharge.

⚠ Note what that says about the review's own root-cause line. It named `computeFreePoint`'s
`IterationLocalBlocks` MEMBERSHIP guard. That is a true statement about a different partition: the
customer here is the **M-B interior** partition, which never calls `computeFreePoint`
(`Uncomputation.cpp` says so in its own words), and the rail is dropped in
`planInteriorComponent`'s **convergence loop** by the `DT.dominates(U, At)` conjunct inside
`provablyBeforePerActivation`. Same defect, different mechanism, and the fix lands at the
mechanism.

### §1.1 — the fix, and why it is a placement rather than a decline

`useCompleteBeforeDischarge` asks the obligation the scan actually owes —

> (‡) no execution of `U` lies between the discharge `At` and the NEXT execution of the rail's
> own mint `R`

— instead of the strictly stronger `DT.dominates(U, At)`. A use that did not run cannot violate
(‡); a use that DID run violates it only by running after `At` with no intervening `R`, and that is
exactly what the barrier walk refuses. **Dominance is sufficient for a DIFFERENT statement ("U ran
before At on every path to At") which this scan does not owe.**

**The half that makes it safe is in §4 and is unchanged**: every gate whose ADJOINT is emitted is
still re-proved under the full `DT.dominates(G, At)`, so a conditional IN-PLACE gate on the rail
(which `recoverDataDag` walks into `D.Calls`) still refuses the whole component. What is relaxed is
only a READER the reversal never touches. Both sites say so.

**Scoped to one marked body, deliberately.** All three of `U`, `At` and `R` must key to the same
`markedHeaderOf`. The identical argument would admit an ACYCLIC diamond-use interior rail; that is
a real over-decline and it is **FILED, not taken** (§7), because it moves modules with no loop in
them and this increment's witness set is the loop family. The scoping also makes the change
byte-inert for every acyclic module — measured, not assumed (0 of 1191 fixtures in the two affected
families moved).

### §1.2 — the fence half (review finding F-1's second option, and F-2)

`declineDephasingUnmarkedLoopRails` conjunct (1) gains
`markedBodyRailsHaveInBodyDischargePoint`: *does every interior out-of-place template rail minted
in `L`'s own blocks have an in-body post-dominator to be discharged at?* — the question
`dagInsertPoint` will ask, asked in the vocabulary this stage has (pre-`lowerOps`, so
`mintsOutOfPlaceTemplateRail`, **by calling it**, never re-spelled).

F-2 is landed in the same change (`CLAUDE.md` L7-with-a-twist): conjunct (1)'s argued header and
`bodyBlocksMarked`'s retirement triggers are corrected **at the site**, including the trigger that
header did not carry — *what the marking proves*.

⚠⚠ **THAT CONJUNCT WAS A PREDICTION AND IT WAS WRONG, AND THE LIST BELOW USED TO OMIT THE ONE
THAT MATTERS** (independent Rule-13 round, 2026-09-18, F-1 / F-3; corrected here and at the source
site in the same change — `CLAUDE.md` L7-with-a-twist).

The conjunct is a SUFFICIENT condition, not an oracle: it models only the "is there an in-body
post-dominator" refusal. An earlier revision of this section listed the refusals it does **not**
model as *"clause (d), `preservesBasisUnderRecord`, or a `ReversedGates` overlap"* — three exotic
mechanisms — and **left out `planInteriorComponent` §4's per-gate `DT.dominates(G, At)` on an
ARM-MINTED interior rail, which is the refusal a MULTI-BLOCK BODY PRODUCES BY CONSTRUCTION**, i.e.
the one this predicate's own shape class generates. The list read as exhaustive over rare cases
while missing the ordinary one, and that omission **is** F-1's mechanism: `g8_arm_use_derived_owned_rot.c`
has `bodyBlocksMarked` true, the post-dominator fold true, and four coherent which-path records
leaked at a non-diagonal gate at `opt` exit 0.

**SO THE SUPPRESSION IS NO LONGER TRUSTED — IT IS VERIFIED.** Conjunct (1) RECORDS the promise and
`declineUndischargedMarkedBodyRails` checks it at the tail of the pass, after `uncompute`, in BOTH
entry points, where the discharge is a FACT. It declines with the EXISTING bd `s82e` string, so the
fence keeps its verdict and its pins. That is the `declineSurvivingIntrinsicCalls` pattern the
predicate's own header used to name and decline; F-1 is the measured reason to take it.

---

## §2 — WHAT THE PIECES MEASURE

### §2.1 — bd `6n1s` witness and controls (ORACLE `9bd01598` → subject)

| probe | ORACLE | subject |
|---|---|---|
| `t5j_twoblock_noexit_rot` (RED) | ACCEPT 18 lines, `1 left dirty`, **0** free sites | ACCEPT **26** lines, `0 left dirty`, 4 mints / **4** `_unc` / **4** free |
| `t5i_straddle_nobreak_rot` (single-block control) | ACCEPT 32, `0 left dirty`, 2 free verified | **UNMOVED** |
| `t5k_twoblock_unmarked_control` (marking refused) | DECLINE `rolled body leaks…` | **UNMOVED** |
| `t5h_rail_straddles_break_rot` (the break spelling) | ACCEPT 11-ish, `1 left dirty`, 0 free | ACCEPT 16, `0 left dirty`, 2 free sites |

### §2.2 — P2's customers

| probe | ORACLE | subject |
|---|---|---|
| `m_none_oder_none_none_none` (bd `1m5p` class A) | rolled **25** vs twin **27**, `sqrt_f64_unc` **0 vs 1** | rolled **27** == twin **27**, **MULTISET IDENTICAL**, order-divergent |
| **`a1_apost`** (the LIVE Rule-8 over-accept) | rolled **26** vs twin **28**, `sqrt_f64_unc` **0 vs 1**, stderr = the live-record WARNING | rolled **28** == twin **28**, **MULTISET IDENTICAL**, **stderr 0 bytes** |

The `a1_apost` row is the one to read twice. The whole hoisted chain (`sitofp → fadd → sqrt`) is
adjointed **LIFO in the loop-exit block, strictly BEFORE `cqrt_ry_i32(%h, 0.7)`** — so the
which-path record is discharged before the interference. **The warning going silent is the
witness that the record is discharged**, not that the warn stage stopped looking: that is round-1
lens 7's own test (SCOPE_T2 §6), and `warnLiveRecordRotations` still fires on the sibling shapes.

⚠ **The claim is COUNT + MULTISET + a commutation argument, never byte identity** (owner ruling
S3, `$THIS/DECISIONS.md`). Both pairs are order-divergent by construction: the rolled form
discharges at the loop exit, the twin at function scope after the last copy. They commute because
everything between the two positions READS the chain's members and writes only its own ancillas —
disjoint support.

### §2.3 — the fixture batch

| fixture | verdict | red-green |
|---|---|---|
| `loop_pairing_accept_twoblock_body_straddle.ll` (NEW) | ACCEPT | **FAILS on the ORACLE** (prefix CHECK **and** prefix COUNT), passes on the subject |
| `loop_pairing_accept_oneblock_body_control.ll` (NEW) | ACCEPT | PASSES on BOTH — the unmoved isolating control |
| `loop_leak_dephase_reject_twoblock_unmarked_control.ll` (NEW) | DECLINE | DECLINES on BOTH — the marking is the door |
| `loop_pairing_accept_hoisted_chain_exit_discharge.ll` (NEW) | ACCEPT | **FAILS all three prefixes on the ORACLE** |
| `loop_pairing_reject_root_hoisted_template_data.ll` | CONVERTED in place | new `EXITD` prefix fails on the ORACLE |
| `control_phase_kickback_inloop_reject_hoisted_temp.ll` | CONVERTED in place | new `EXITD` + `FCNT` fail on the ORACLE |
| `control_phase_kickback_mixed_preheader_add_outofplace_leak_control.ll` | CONVERTED in place | new `EXITD` + `FCNT` fail on the ORACLE |

**No `git mv`** (L8 / bd `gahu`); historical headers kept verbatim under a conversion banner.

⚠ **ONE CONVERSION'S L8 TRIGGER FIRED AND NAMED THE WRONG MECHANISM**, and that is the part worth
carrying. `loop_pairing_reject_root_hoisted_template_data`'s header predicted *"when the
hoisted-template half of bd `tu9q` is built, this file becomes an ACCEPT that DISCHARGES"* and
attributed the flip to widening the ROOT admission (clause (ii-c)/(ii-d)). **It does not**: the rail
discharges with `invariantRegisterRoots` COMPLETELY UNCHANGED and the body UNMARKED, because P2 is
a PLACEMENT. *A retirement trigger can be right about the verdict and wrong about the cause.* The
correction is written into the file.

⚠ **TWO OF THE THREE CONVERSIONS WERE NOT PREDICTED BY THE SCOPING.** SCOPE_T2 §5 named only the
first. `control_phase_kickback_inloop_reject_hoisted_temp` and `…_preheader_add_outofplace…` are
P2 movers, and each had a census that CONFLATED the hoisted rail with the per-trip one (*"ONE free
in the body: the flag alone (the bit rail is the leak)"*). Only the hoisted half moved; the
sentence came apart and both halves are now stated separately.

---

## §3 — THE THREE ROUNDS (self-run)

Budgeted up front per Rule 13. Recorded as *what it attacked / what it found / what it fixed / what
was re-measured*, including the rounds that found nothing, because a round with no finding is data
about the attack and not about the code.

### Round 1 — the pairing itself (SCOPE_T2 §6 lens 1-3)

* **Attacked**: K-adjoints-against-one-forward in both directions; the null×null cell of
  `markedHeaderOf`; the `_unc` ORDER across a split.
* **FOUND (F-R1-1)**: the preheader-`G` / body-`At` direction is **unreachable today**, and the
  reason is NOT the one §0.1(a) gives for it. The convergence loop drops the rail before §4 is
  reached. That is stated at the new test rather than left as a claim — a green suite is not
  evidence the test is dead, and the test is what P2 makes reachable.
* **FOUND (F-R1-2)**: the null×null cell is sound **only because the per-endpoint `canRepeat`
  tests run FIRST**. Written at the definition with the over-accept it becomes if either is ever
  narrowed or reordered.
* **FOUND (F-R1-3) — the relaxation's own soundness argument, checked rather than
  asserted.** §1.1 claims *"what is relaxed is only a READER the reversal never touches"*. That is
  an argument about a CASE SPLIT over `R->users()`, so the split was enumerated: (a) a template
  producer whose own rail IS owned by this component is in `D.Calls` and §4's unrelaxed
  `DT.dominates(G, At)` refuses it; (b) an IN-PLACE gate on `R` writes `R`, so `recoverDataDag`
  must have it in `D.Calls` for the adjoint to be correct at all — §4 refuses it too; (c) a
  template producer whose rail is NOT owned (measure-owned, which is `t5j`'s `and`) is a pure
  reader and is the only case the relaxation admits; (d) a measure would have made `R` a
  non-candidate. **So a CONDITIONAL in-place gate cannot reach the relaxed leg**, which is the
  attack that would have broken it.
* **FOUND (F-R1-4) — the null×null premise is an ORDERING claim, so the order was MEASURED.** At
  all three call sites the per-endpoint `canRepeat` tests precede `multiplicityAgrees` in program
  order (`Uncomputation.cpp` §4 `:1202` → `:1240` → `:1242`; §2.9 `:1265` → `:1276`;
  `reverseTerminalGroup` `:633` / `:756` → `:771`). The comment was corrected from *"BESIDE this
  one"* to name the ordering and to say that **REORDERING** — the cheaper mistake, and the one a
  tidy-up makes — is what turns the predicate into an over-accept.
* **FIXED**: all four, in prose at the site. No behavioural change.

### Round 2 — the loop shapes (lens 4-7)

* **Attacked**: multi-exit / `break`; nested loops against the OUTERMOST-vs-innermost asymmetry; a
  hoisted rail whose borrowed parent is gated inside `L`; the `a1_apost` warning.
* **FOUND (F-R2-1, and it is an INSTRUMENT finding)**: `loopExitDischargePoint`'s null
  (multi-exit) path has **NO constructed customer at `-O1`**. THREE C shapes were built:
  `p2b_multiexit_hoisted_chain` (early `return` in the loop) declines EARLIER at the 2c
  condition-wire fence; `p2d_two_exit_blocks` (`goto` to a distinct landing block) is renormalised
  by `-O1` to ONE exit block and ACCEPTS **with** the discharge; `p2c_parent_gated_inside` is fully
  UNROLLED by `-O1` (2 `sqrt` chains, 39 lines) so it has no loop to test. Recorded rather than
  papered over: it is the conservative branch (null ⇒ leak ⇒ today's behaviour) and it is validated
  only by its consumers, not by a customer. `8h7d.10`'s lesson applies verbatim — *a fence with no
  reachable customer and no failing fixture is a prediction, not a test.*
* **FOUND (F-R2-2)**: the break spelling `t5h` is **structurally identical to `t5j`** after `-O1`
  — the `break` is if-converted into one extra disjunct on the LATCH (`%15 = select i1 %12, i1
  true, i1 %14`), so the body is three blocks with one exit, exactly as the no-break shape. *The
  break is a spelling, not a cause*, which is the review's own §C.3 conclusion reproduced on the
  subject.
* **FOUND (F-R2-4) — the OUTERMOST walk IS exercised, and it took THREE probes to reach it.**
  `p2e_nest_outermost` (a 2-deep nest with a tainted region in the innermost body) declines at the
  **2c condition-wire fence**; removing the post-loop rotation (`p2f_nest_outermost_norot`) moves
  the decline to `cq controlled lowering: control flow inside a loop body under quantum control` —
  the nested-loop wall `CLAUDE.md` §2 lists. **So a nest with in-loop tainted CONTROL can never
  reach `Uncomputation` at all**, which is why lens 5 looked unreachable. The third shape,
  `p2g_nest_datarail`, has NO tainted control flow: `int p = a*3;` minted outside BOTH loops and
  read as DATA in the innermost body. It ACCEPTS, **both loops survive as rolled `!llvm.loop` back
  edges** (checked in the lowered IR — the 4-iteration trace is the runtime, not an unroll), and
  `cq_template_mul_i32_hl_unc(h1, h0, 3)` + `cqrt_free(h1)` appear **exactly once, after the WHOLE
  nest**. Had the walk taken the INNERMOST loop the discharge would sit at the inner exit and fire
  once per OUTER trip against a once-executed mint; §2.9 would then refuse it and the rail would
  leak. **The OUTERMOST choice is therefore measured, not only argued** — and this was listed in an
  earlier revision of §8 as an attack I had NOT done, which is now false and is corrected here.
* **FOUND (F-R2-5) — the reviewer's closing lens, "a rail minted in ONE ARM of an in-body classical
  `if`", is CLEAN and the reason is the half that did NOT change.** That shape is the one where
  being wrong is a wrong unitary rather than a leak: the mint runs on one path, so a discharge at
  the JOIN would adjoint a gate that never fired. `p2h_arm_minted_rail` declines earlier at bd
  `3d8q`'s fence; with the post-loop rotation removed, `p2i_arm_minted_rail_norot` ACCEPTS and the
  mint, its `_unc` and its `cqrt_free` are **all three in the ARM BLOCK itself** (`%8`), STRICT 2b
  `2 verified, 0 unproven`. The relaxation touches only the USE side; §4's unrelaxed
  `DT.dominates(G, At)` is what keeps the discharge on the mint's own path, which is F-R1-3's case
  split confirmed by construction rather than by reading.
* **FOUND (F-R2-3)**: **the warning does NOT go silent on `t5j`**, and the reason is a different
  guard. `recordIsExemptAt` clause 4 exempts a record measured before the gate via
  `provablyBeforePerActivation`, whose dominance conjunct FAILS for the CONDITIONALLY-executed
  `cq_template_and_i32_hl(%h_op, 2)` rail's own measure. Same dominance-vs-conditional-execution
  shape this increment fixes, in a guard `RotationLowering.cpp` owns. **NOT fixed here** — a second
  spelling of another owner's predicate is the drbq Inc-3 (b′) defect (Rule 14). FILED (§7). It
  DOES go silent on `a1_apost`, which is the case lens 7 asks about.

### Round 3 — windows and compositions (lens 8-11)

* **Attacked**: the L1 round-2 window on the new grant; the composition with Track S′'s fence; the
  L3-mirror obligation on `mintsOutOfPlaceTemplateRail`.
* **FOUND (F-R3-1)**: the LANDED prefix adds **no** taint-growth event and **no** new marking, so
  it owes no `adjudicateTaintDelta` re-ask. `markedHeaderOf` READS `IterationLocalBlocks` and never
  writes it. The L1 window that SCOPE_T2 §2.5(2) names (`collapseFlattenedLoopRails`' marking at
  `:3891-3907` runs before `repropagateControlMerges` with **no** `recordRound1RailGrant`) is
  **PRE-EXISTING and is NOT widened by the landed prefix** — it is widened by P3, which did not
  land. bd `0kjo` keeps its pre-existing population and gains none.
* **FOUND (F-R3-1b) — the new conjunct-(1) call reaches loops the old one never did, so "does it
  MUTATE `taint`?" had to be answered, not assumed.** `markedBodyRailsHaveInBodyDischargePoint`
  calls `mintsOutOfPlaceTemplateRail`, which conjunct (3) also calls — but conjunct (1) used to
  `continue` BEFORE conjunct (3) ran, so the new call fires on marked loops that predicate had
  never been asked about. If it wrote anything into `taint` this would be a new mutation on a new
  population, at a stage inside the round-2 window. **Checked in source**: it takes `TaintSet &`
  but every use is a read — `inPlaceValueRailOperand(BO, const TaintSet &)` and
  `railValueConsumerDisposition(BO, V, const TaintSet &, …)` both take it **by CONST reference**,
  and the only direct touches are `taint.InPlaceRailIdx.find(BO)` and `taint.InPlaceRailOps.count(BO)`.
  It is PURE with respect to `taint`; the non-const parameter is a signature artefact.
  ⚠ RETIREMENT TRIGGER worth carrying: the day either of those two helpers takes `taint` by
  non-const reference, this conjunct becomes a WRITER on a new population and F-R3-1 has to be
  re-derived.
* **FOUND (F-R3-2)**: the landed prefix **cannot silence Track S′'s fence**, structurally: it marks
  no body, and conjunct (1)'s suppression is now strictly NARROWER than before (a second conjunct
  was added, never relaxed). The composition risk SCOPE_T2 §6 lens 9 names belongs to P3.
* **FOUND (F-R3-2b) — the JOINT fold's subset step, argued rather than left for the reviewer to
  reconstruct** (§8 item 3 asks for exactly this, so here is the argument to attack).
  `markedBodyRailsHaveInBodyDischargePoint` folds ONE post-dominator over the union `S` of every
  interior rail's block and its users' blocks, and claims that is an upper bound on any single
  component's `At` (the component's block set `T` is a subset of `S`). The step that needs care is:
  **does `pdom(S) ∈ OwnBlocks(L)` imply `pdom(T) ∈ OwnBlocks(L)` for `T ⊆ S`?**
  It does, and the reason is the contrapositive rather than a tree-path argument: if ANY block in
  `S` exits `L`, then a common post-dominator of that block must post-dominate BOTH its in-loop and
  its out-of-loop successor, so it lies outside `L` — and `pdom(S)` is therefore NOT an own block,
  and the predicate has already returned `false`. So reaching the `true` branch means **no block in
  `S` exits the loop**, and every post-dominator of a subset of non-exiting own blocks is itself
  reached without leaving `L`. A user inside a SUBLOOP is handled by the other conjunct
  (`LI.getLoopFor(Common) == L` fails), which is also the conservative direction.
  ⚠ What this argument does NOT cover, and the reviewer should push there: a loop whose EXIT BLOCK
  is itself inside an OUTER loop. `pdom` can then be an own block of the outer loop, the
  `LI.getLoopFor(Common) == L` conjunct refuses it, and the fence arms — believed conservative, and
  **not constructed**.
* **FOUND (F-R3-3)**: `taint.IterationLocalBlocks`' raw-`BasicBlock *` exposure (§5.1 of the
  scope) gains a NEW KIND of consumer here — `markedHeaderOf` makes the set decide a
  MULTIPLICITY question, not only a suppression. The asymmetry that keeps it safe is written at
  the definition: a stale-true gives a block a NON-null key, and a non-null key can only make
  `multiplicityAgrees` return **false** where the other endpoint keys null — so the added
  population's failure mode at the new site is a **REFUSAL (a leak), not a grant**. FILED (§7).

⚠ **What NO round did**: attack a multi-latch or irreducible loop against the new use-side leg;
attack the 512-block budget path; run any suite beyond the two gates in `GATES.md`; or attack the
composition with Group 2's binaries or Track V's matrix. §6 lists these as not-claimed.

---

## §4 — MEASURED, NOT ESTIMATED (summary; commands in `GATES.md`)

* clean-worktree build reproduces the session ORACLE **exactly**, both hashes, before the first edit.
* pre-group build reproduces the 2026-09-14 oracle **exactly**.
* targeted lit `loop|uncompute|inloop|kickback_mixed|railbank|break|lowering_` at every step:
  **984 PASS + 1 XFAIL, 0 FAIL** on the landed tip.
* Rule-12 mutation of the new fence conjunct: forced to `return false` it flips **17** shipped
  fixtures ⇒ live, exercised code. Reverting it reproduces the pre-mutant `cq-opt` hash **bit for
  bit**.
* Rule-12 red-green by BINARY MUTATION for all four new accept fixtures and all three conversions.
* the probe harness self-attacks: `onbin.sh` with no fixture argument exits **2**; `batch.sh` with
  no tag exits **2**; `probe.sh` refuses an empty or quantum-free source and refuses a stage-2b run
  that printed `cannot read` (the review's own F-4 lesson, adopted rather than re-learned).

---

## §5 — P0 + P3: BUILT, MEASURED, NOT LANDED (branch `tu9q-p0-p3-wip` `30b80d7f`)

It works for its customers. `s2`, `hoisted_template` and `short_sext` all lower with `mint == _unc`
on every rail; `hoisted_template` measures rolled **40** == hand-unrolled twin **40**, trace
MULTISET IDENTICAL. The (ii-d) postcondition has **real customers**, which SCOPE_T2 §5 F8 doubted.

**The 8 movers, each explained:**

| # | fixture | move | mechanical? |
|---|---|---|---|
| 1-3 | `…region_derivedbase_live`, `…hoisted_template…`, `…short_sext…` | DECLINE → ACCEPT | ✔ the intended conversions |
| 4-6 | this branch's own P2 conversions | per-trip rails now discharge too | ✔ re-derive counts |
| 7 | `loop_pairing_reject_round2_falsified` | **DECLINE → exit 0** | ✘ see below |
| 8 | `control_inplace_ry_reject_rail_inloop_carried_invariant_read` | string move to the postcondition | ✘ see below |

**Mover 7 is the reason this stopped.** That fixture's own header gives its decline's premise
verbatim: *"`%m2`'s forward gate is in the loop PREHEADER and runs ONCE, while a marked body's
discharge point runs K times. `Uncomputation.cpp`'s §4/§2.9 pair asks each endpoint SEPARATELY
whether it repeats and never whether the two repeat EQUALLY … so leaving the grant standing is K
adjoints against ONE forward gate."* **P1 is exactly that missing test and P2 is exactly the right
point.** MEASURED on the WIP binary: the emitted module mints `cq_template_mul_i32_hl(%out1, 2)`
ONCE in the preheader and adjoints it ONCE in the loop-EXIT block, while the body's own `lshr` rail
is minted and discharged per trip. The hazard is refuted by construction. **But retiring another
owner's Rule-13 fence is not an implementer's call**, and that fixture is the WITNESS for
`declineRound2FalsifiedRailGrants`' L1 window, which may still own shapes P1 does not reach.

**Mover 8** still DECLINES (safe direction) but at the postcondition's string instead of `control
flow inside a loop body under quantum control`. The measurement that matters is the other one:
**with the postcondition removed that module COMPILES**, so the postcondition is holding a verdict,
not decorating a message. The cost is a shipped fence losing its only pin — the defect
`CQLoweringPass.cpp` records in those words for the stale-reader slot.

**Two narrowings were tried; both are recorded at the clause so they are not re-derived:**

* **KEPT — every user of the rail must be inside `L`.** Without it,
  `loop_pairing_reject_root_invariant_read_after_loop` (clause (ii-c)'s "EVERY user" quantifier,
  pinned) and `lowering_uncompute_interior_loop_consumer_and_after` (SCOPE_T2 §4's *"most
  load-bearing control for P2"*) BOTH moved. Neither is the shape (ii-d) is for. This narrowing
  took the mover count 14 → 8.
* **REJECTED — "refuse a loop that carries a claimed rail".** It looks like the right multiplicity
  regime and is **wrong**: two of the three intended customers carry one (their bodies end
  `r = cq_theta(r, 0.1);`), and the conjunct returned both to a decline while ALSO flipping mover 7
  to exit 0.

**One real defect was found and fixed inside P3 by measurement**: the postcondition must ask its
question in the POST-LOWERING vocabulary. `control_phase_kickback_mixed_preheader_volatile_imm…` is
admitted by (ii-d) on `mintsOutOfPlaceTemplateRail`'s **pre-commit forecast** and then lowered IN
PLACE by M-C as `cqrt_addc_i32` — no rail exists, so the obligation is vacuous and firing on it was
a false decline. ⚠ **That also falsifies SCOPE_T2 §3.4's source reading**, which states
`mintsOutOfPlaceTemplateRail` *"returns **false** for an op that lowers IN PLACE"*. At this stage it
returns **true**, because the commit that would make it false has been refused by the (1a) fence.

---

## §6 — WHAT IS **NOT** CLAIMED

1. **Four gates were run by me, and no more.** `ir-pass-lit` (twice at the same hash — once at
   15:07 and again at the delivered tip, because four fixtures were edited in between), ONE corpus
   sweep, the two new e2e slice entries, and the per-fixture/per-probe inner loop. NOT run: the
   full `ctest -j6`, `^e2e-` as a layer, any twin matrix, `cq-opt-equivalence-full`. A skipped
   layer is a deferred cost, not a saved one.
   ⚠ **The corpus sweep is the number to read**: **6566 rows, 16 movers, ZERO VERDICT FLIPS.**
   Every mover is `ACCEPT → ACCEPT` with a different lowered-IR md5 and every one is an expected P2
   customer. No `A→D` and no `D→A` anywhere in the tree.
   ⚠ And the gates are facts about the DELIVERED binary, not a near-miss of it: the two
   comment-only commits made after the sweep rebuild `cq-opt` **BIT-IDENTICALLY**
   (`7c1163ad94d06320` before and after), verified independently by a non-comment line diff of both
   commits (0 lines).
2. **ONE e2e slice PAIR was added, not the two pairs SCOPE_T2 §5 asks for.**
   `e2e-slice-loop-hoisted-chain-exit-discharge{,-unrolled}` is the Rule-16 witness for P2 and for
   the `a1_apost` closure (rolled **28** == unrolled **28**, goldens byte-DIVERGENT and
   MULTISET-IDENTICAL, generated with `run_slice.sh`'s own stage-1 flags rather than a near-miss of
   them). ⚠ The scope's SECOND pair is P3's (`slice_loop_pairing_hoisted_template{,_unrolled}`)
   and **is not here, because P3 is not here.** ⚠ **An earlier revision of this file said "No e2e
   slice was added"; that was true when written and is now false** — corrected at the site rather
   than left to a reader to reconcile (`CLAUDE.md` L7-with-a-twist).
3. **Stage 2b cannot witness the landed capability**, and it is structural: `free_pairing_check.py`
   analyses per straight-line STREAM, so a discharge at a JOIN or a LOOP EXIT is `U3-extern-rail`
   UNPROVEN by construction. Measured twice: the two-block lit witness reports `0 verified, 2
   unproven` where its single-block control reports `2 verified`; the new rolled slice reports
   `1 verified, 0 violation(s), 3 unproven` where its hand-unrolled twin reports `5 verified, 0
   unproven` under STRICT 2b. **That asymmetry measures the instrument's reach, not the rail.** The
   rolled slice therefore carries `--allow-unproven` with that reason and a retirement trigger
   written at its registration; the twin runs STRICT.
4. **The fence half NEVER closed the general hole, and as of 2026-09-18 it is no longer asked to.**
   It models the post-dominator sub-case; §4's per-gate dominance on an ARM-MINTED rail (the one a
   multi-block body produces by construction), clause (d), `preservesBasisUnderRecord` and a
   `ReversedGates` overlap are all outside it. What closes the hole is the POSTCONDITION
   (`declineUndischargedMarkedBodyRails`), which asks the question on the emitted module instead of
   predicting it. ⚠ An earlier revision of this item omitted §4's dominance from that list; that
   omission was F-1's mechanism and is corrected at the site as well as here.
5. **No module was constructed on which `markedBodyRailsHaveInBodyDischargePoint` answers
   `false`, and the independent round measured it returning `true` on ALL 19 of its probes** —
   including the F-1 witness, where `true` is a FALSE NEGATIVE. Combined with the 6566-row corpus
   sweep's ZERO verdict flips, the conjunct declined nothing anywhere in the tree: **bd `6n1s`'s P1
   was closed, for the shapes it is closed for, by the USE-SIDE relaxation alone.** The conjunct is
   kept because a sufficient condition sound in the decline direction costs nothing, but it must not
   be read as the fix's fence (F-2; stated at the source site too).
6. **`loopExitDischargePoint`'s null path has no constructed customer** (§3 F-R2-1).
7. **The warning still fires on `t5j`** for an unrelated, now-understood reason (§3 F-R2-3).
8. **No injection (mutation) matrix was run over the new accept fixtures**, and no
   `negative_vacuity_check.py` batch — see §7; the red-green binary-mutation validation in `GATES.md`
   is a different and weaker instrument, and saying otherwise would be the mislabelled-number defect
   this project has paid for twice.
9. **No quarantine rows were measured**, because no twin-matrix cell was run: the twin matrices are
   the merge-and-gate agent's gate and Track V owns the files. `QUARANTINE_HANDOFF.md` states what
   the landed prefix is EXPECTED to move and why the numbers are not in it.
10. **P0/P3 is not cleared**, by me or by anyone. It is preserved with its measurements.

---

## §7 — TO FILE (bd text in §bd of the hand-off)

* the **acyclic diamond-use residual** of `useCompleteBeforeDischarge` (an interior rail minted in
  `entry` and read in both arms of a classical `if` still leaks) — an over-decline with a known
  mechanism and no measured customer;
* the **`recordIsExemptAt` clause-4 dominance gap** (§3 F-R2-3) — the M-A warning fires on a
  conditionally-measured record, `RotationLowering.cpp`'s to own;
* the **`IterationLocalBlocks` scrub**, pre-existing, whose population this increment widens with a
  new KIND of reader (§3 F-R3-3);
* the **e2e gap** (§6.2) and the **stage-2b stream-model limitation** (§6.3);
* the **P0/P3 dispositions** — movers 7 and 8 (§5).

---

## §7a — THE GENERALISABLE FINDING: **THREE artefacts predicted this flip and ALL THREE named the wrong cause**

Not a defect in anything, and the most transferable thing this increment produced.

The 2026-09-15 work left three separate written predictions that a hoisted template rail would one
day gain a `_unc`, and each attributed that future flip to **widening the ROOT ADMISSION**:

* `ir-pass/test/loop_pairing_reject_root_hoisted_template_data.ll` — *"IF A `_unc` OR A `cqrt_free`
  EVER APPEARS IN THIS FILE, clause (ii-c) has over-widened and the multiplicity miscompile above is
  LIVE"*, with an L8 trigger naming bd `tu9q`'s root-mint half;
* `ir-pass/test/control_phase_kickback_inloop_reject_hoisted_temp.ll` — *"These are the lines that
  FIRE if `invariantRegisterRoots` is ever widened to admit a hoisted template rail"*;
* `trackT/probes/adv/b1_mixed_nonlive.c` — *"If a `_unc` appears here, (ii-c) over-widened and the
  K-adjoints-against-one-forward-gate multiplicity miscompile is live."*

**All three fired. All three were wrong about the mechanism, and the third is wrong in the
strongest possible way**: `invariantRegisterRoots` is COMPLETELY UNCHANGED by the landed prefix, the
loop bodies are UNMARKED, and the multiplicity is **1 : 1** (one mint in the preheader, one adjoint
at the loop exit) — the exact opposite of the K : 1 it predicts. The flip is a **PLACEMENT**.

**The lesson is not "write fewer triggers"** — L8 says triggers work, and these three correctly
predicted the VERDICT years of reviews would otherwise have had to rediscover. It is this: **a
retirement trigger predicts a verdict, and a verdict has more than one cause.** When one fires,
re-derive the mechanism from the binary instead of reading the cause off the trigger — otherwise the
next agent converts a fixture with a confident and false explanation attached, and that explanation
outlives the measurement. Two of the three are corrected in place on this branch; the third is a
probe in another session's directory and is recorded here instead.

---

## §8 — FOR THE INDEPENDENT REVIEWER: the three most dangerous things, in order

1. **`useCompleteBeforeDischarge`'s case split (F-R1-3) — AND THE SCOPE THAT SPLIT DOES NOT COVER.**
   ⚠ **F-3(2), 2026-09-18:** the split is written over `R->users()`, i.e. *what the reversal
   touches*. F-1's mechanism is a gate that is **not a user of `R` at all** — the ARM's producer of a
   SECOND interior rail. **State the split's scope when reading it**: it argues the relaxation does
   not admit a *bad adjoint*; it says **nothing** about whether the component the relaxation keeps
   alive will be PLANNED at all, and conjunct (1) has already promised the fence that it will be.
   That gap is now covered by the postcondition, not by the split.
   The split itself is sound *because* every user the reversal will ADJOINT is re-proved under the
   unrelaxed `DT.dominates(G, At)` in §4. That rests on one claim: **an in-place gate on the owned
   rail is always in `D.Calls`.**
   Attack it. If `recoverDataDag` can ever fail to walk an in-place gate on an owned rail — a
   width-punned one, one behind a `!cq.branchphase` membership refusal, one the 7.4 break teardown
   minted — then a CONDITIONAL such gate reaches the relaxed leg and the adjoint fires on one arm
   of a diamond inside a marked body. That is a wrong unitary, not a leak, and nothing else in the
   change would notice.

2. **P2's OUTERMOST walk at DEPTH ≥ 3, and the `Loop::contains` / `LI.getLoopFor` asymmetry.**
   SCOPE_T2 §6 lens 5 says *"one of the two is wrong in exactly one of the two sites"*. ⚠ **An
   earlier revision of this section said I had built no nested customer; that is now false** —
   `p2g_nest_datarail` is a real 2-deep nest (both loops survive as rolled `!llvm.loop` back edges)
   whose hoisted `mul` rail is discharged exactly ONCE after the WHOLE nest (§3 F-R2-4). What is
   still owed is **DEPTH 3** and the deliberate attack on the asymmetry itself: the anchor walk uses
   `Loop::contains` (subloops INCLUDED — "is the mint inside this cycle at all") while
   `markedHeaderOf` uses `LI.getLoopFor` (INNERMOST — "how often does this block run"), and only one
   depth has been measured. `r1_triple_nest_mid_rail` is the seed the scope names.
   ⚠ Carry the reason the first two attempts failed, or the next agent repeats them: a nest with
   in-loop tainted CONTROL cannot reach `Uncomputation` at all — it is claimed first by the 2c
   condition-wire fence and then by `control flow inside a loop body under quantum control`. The
   customer has to be a DATA rail.

3. **`markedBodyRailsHaveInBodyDischargePoint` models another file's placement.** It predicts
   `dagInsertPoint`'s answer, from `LoopLowering.cpp`, BEFORE `lowerOps`, using a JOINT
   post-dominator fold over all interior rails (an upper bound on any single component's `At`).
   Two things to attack: the fold's SUBSET argument — is `pdom(T) ∈ OwnBlocks(L)` really implied by
   `pdom(S) ∈ OwnBlocks(L)` for `T ⊆ S`, in a loop with an exit block inside an outer loop? — and
   the fact that it has **no `false`-answering customer**, so its decline path is a prediction
   validated only by mutation (17 fixtures depend on its `true`).

**And one that is not a defect but will mislead a reader**: `t5j_twoblock_noexit_rot.c` still emits
the M-A warning after the fix. It is NOT about the `ashr` rails (all four are discharged) — it is
`recordIsExemptAt` clause 4 failing on a CONDITIONALLY-executed measure. §3 F-R2-3, filed.

---

## §9 — THE INDEPENDENT ROUND'S F-1 / F-2 / F-3, FIXED (2026-09-18, `cq-opt df2445fcaf82cf00`)

> **The round's own headline, kept because it frames the fix:** *"The landed code is a net
> improvement and I found no module it makes worse … 10 of 16 accepting probes MOVED and all 10
> moved `leak → discharge`. **F-1 is not a regression introduced by this branch.** F-1 is that the
> branch does not close the bead it is named for."* That is exactly right, and §0's status line
> ("bd `6n1s` LANDED") was therefore **wrong** and is corrected here: bd `6n1s` is closed **now**.

### §9.1 — F-1, and why fix (a) was attempted first and then filed

`g8_arm_use_derived_owned_rot.c` is `t5j` with the arm minting an **interior** rail
(`int e = d + 7; s += cq_measure(e & 2);` instead of a direct measure). Reproduced on the delivered
SUBJECT before any edit: ACCEPT exit 0, 19 lines, `2 left dirty`, **0 `cqrt_free`**, four coherent
which-path copies of `y >> k` alive across `cqrt_ry_i32(h0,0.9)` and `cqrt_measure_i32(h0)`.

**Root cause, confirmed in the emitted module** (`%4` header / `%9` arm / `%11` join): the component
is `{%h_op, %h_op2}`, `At` is the join `%11`, and §4's per-gate `DT.dominates(G, At)` is FALSE for
the ARM's producer `%h_op2` — so `planInteriorComponent` abandons the **whole** component. Conjunct
(1) had meanwhile suppressed the fence, because `bodyBlocksMarked` **and**
`markedBodyRailsHaveInBodyDischargePoint` are both `true` here.

**Fix (a), the placement, was traced and is a SEPARATE INCREMENT — recorded so the next agent starts
from a design and not a sketch.** Discharging `{h_op2}` in the arm and `{h_op}` at the join is
sound and I verified each step, but it needs (i) a component partition **finer than a component**
keyed on **control-equivalence** — bd `tu9q` P0's multiplicity key does **not** separate them,
because both rails are in the SAME marked body — and (ii) a **per-activation** cross-plan ordering
check, because P0's shipped `provablyBefore(At_inner, At_outer)` FAILS here (`%9` does not dominate
`%11`) while the property that actually holds is "no execution of the inner adjoint lies after the
outer free within an activation". A new partition key plus a new ordering predicate is a new
increment with its own Rule-13 budget, inside a one-fix scope. **FILED.**

### §9.2 — fix (b) as landed: the suppression is a PROMISE, verified after `uncompute`

Conjunct (1) no longer `continue`s. It computes `SuppressedByMarking`, lets conjuncts (2) and (3)
run, and at conjunct (3)'s hit **records** the offending rail instead of declining
(`markedBodyRailObligations`, `WeakTrackingVH` so it follows `lowerOps`' RAUW).
`declineUndischargedMarkedBodyRails` checks the ledger at the late slot — after `uncompute`, in
**BOTH** entry points, immediately after `emitDeferredDephasingDecline` so bd `bbu0`'s verdict still
speaks first — and declines with the **EXISTING bd `s82e` string**, so the fence keeps its verdict
and its pins rather than starting a new family.

⚠ **The record is taken at conjunct (3), NOT at conjunct (1), and that is what keeps it from being a
mass over-decline**: the hazard needs conjuncts (2) and (3) too, so a loop with no post-loop chained
rotation records nothing. Suppressing at (1) now only means *"do not decline YET"*.

### §9.3 — an over-decline the FIRST cut caused, and how it was caught

The first cut asked only *"is there an `_unc`/`cqrt_free` in the loop?"* and turned
`lowering_reject_live_record_post_gate_record_loop.ll` from its **owner-ruled WARNING** (bd `lyyf`:
the dephasing-by-leftover-record class is the USER's circuit, reported and LOWERED) into a DECLINE.
Read in the emitted module: the offending rail is the WIRE `w = q*2`, rotated in place and then
**`cq_measure`d**. `railIsInterior` calls it interior because it has a NON-measure user (the
`cqrt_ry`) — **which is a different question from "is it measured"**.

So the postcondition asks the question it means: a rail is not a **coherent** record if it is either
(a) adjointed+freed in-body **or** (b) **MEASURED** in-body. Clause (b) is the physics
`measureOwnedInvariantRail`'s header already states from the other side, and it is written at the
site with the measurement that forced it. `g8` still declines (its rails' users are template
producers, not measures), so the clause does not weaken the fix.

### §9.4 — F-2 and F-3, landed AT THE SITE and not only here (`CLAUDE.md` L7-with-a-twist)

* **F-2** — `markedBodyRailsHaveInBodyDischargePoint`'s header now says it has **no measured customer
  in either direction**: the round measured it returning `true` on **all 19** of its probes
  (including the F-1 witness, where `true` is a false negative), and this branch's 6566-row sweep had
  **zero verdict flips**, so it declined nothing anywhere. **bd `6n1s`'s P1 was closed, for the
  shapes it is closed for, by the USE-SIDE relaxation alone.** It is kept (sound in the decline
  direction, costs nothing) but must not be read as the fix's fence.
* **F-3(1)** — the list of refusals the predicate does not model omitted **§4's per-gate dominance on
  an ARM-MINTED rail, the one a multi-block body produces BY CONSTRUCTION**. Corrected at the source
  site and in §1.2 / §6.4 here.
* **F-3(2)** — §8 item 1's case split is written over `R->users()`; F-1's mechanism is a gate that is
  **not a user of `R` at all**. The split's SCOPE is now stated: it argues the relaxation admits no
  bad *adjoint*; it says nothing about whether the component it keeps alive is **planned at all**.

### §9.5 — what §9 does NOT claim

1. **Fix (a) is not built.** The arm-minted interior rail still DECLINES; the placement is filed with
   its design (§9.1). This is a decline of a program that is compilable in principle, i.e. an
   over-decline by the owner's 2026-09-11 ruling — **filed as such, not presented as the answer**.
2. **`declineUndischargedMarkedBodyRails` has exactly ONE constructed customer** (`g8`, plus `g8k`'s
   family via the pre-existing route). Its other decline paths — a NULL handle, a rail whose mint
   left its loop — are conservative branches with no constructed customer.
3. Gates run at `df2445fcaf82cf00`: `ir-pass-lit` (1/1 Passed), the two e2e slice entries (2/2), the
   targeted lit filter (985 + 1 XFAIL, 0 FAIL), the vacuity check, the injection matrix (8
   mutations, MISSED 0, N/A 0) and a **PROBES-ONLY** corpus sweep. **NOT** run: the full `ctest`,
   `^e2e-` as a layer, the twin matrices, `cq-opt-equivalence-full`, and the full `ir-pass/test` half
   of the corpus sweep — that half is covered by `ir-pass-lit` at the same hash, and re-sweeping it
   would be the redundant gate PROTOCOL §6.1 forbids.

### §9.6 — THE BLAST RADIUS: two SHIPPED goldens pinned the same Rule-8 hazard, and only ONE half is now fenced

The merge gate asked Group 1 to **measure, not assume**, whether the F-1 fix moves
`tests/e2e/slice_control_inplace_ry_loop_leak{,_unrolled}` — bd `bbu0`'s byte-identical twin pair,
whose headers both asserted *"IT IS RULE-6 CORRECT"*. Measured on `df2445fcaf82cf00`:

| half | verdict on the fix | disposition |
|---|---|---|
| `…_loop_leak.c` (ROLLED) | **DECLINES** — `rolled body leaks a rail entangled with a rotated register` | case **(ii)**, converted |
| `…_loop_leak_unrolled.c` | **byte-IDENTICAL to its old golden, exit 0, UNCHANGED** | case **(iii)**, NEW P1 bead |

**The decline is CORRECT, and the argument is on the operands.** From the (now deleted) golden:
`cq_template_mul_i32_hl(h2, 7) -> h3` is a COHERENT copy of `h2`'s basis label;
`cqrt_tape_write_i32(t0, h3) -> h4` COPIES it into the output tape and does **not** collapse it;
`h3` is never `_unc`'d and never freed; `cqrt_ry_i32_controlled(h5, h2, 0.9)` — **non-diagonal, on
`h2`** — then runs with that record standing, and `h2` is the measured observable. Rule 8 verbatim.
⚠ **Only the tape-write RESULT (`h4`, `h7`) is an `OutputRails` member**; its OPERAND `h3` is an
ordinary interior template rail, so *"it is the program's own output"* does **not** excuse it — a
reading I checked in `TaintPropagation.h`'s contract before acting on it.

⚠ **THE `twin-identical` GATE WAS GREEN THROUGHOUT, AND COULD NOT HAVE BEEN OTHERWISE.** It
`compare_files`s the two goldens; the unrolled twin leaks the SAME rail in the SAME place, so the
comparison passed. `CLAUDE.md` L10 already states the general form — *"a cell whose two halves
agreed because BOTH were wrong is precisely what ACCEPT-IDENTICAL cannot see; only a fence can"* —
and this is a **second measured instance, on a REGISTERED e2e pair** rather than a matrix cell.
Stage 2b was equally blind: every leaked rail here is TEMPLATE-minted.

**What was done** (coordinator option (ii), the 2026-09-14 stale-reader precedent): both goldens
**DELETED** rather than regenerated; all three ctest entries unregistered (**449 → 446** `add_test`,
**0** duplicate names, sweep still LAST, `ctest -N -R inplace-ry-loop-leak` → `Total Tests: 0`);
both `.c` files **KEPT** with conversion headers and L8 triggers (a deleted fixture can be
resurrected by a merge — L8, bd `gahu`); the rolled decline pinned by
`ir-pass/test/loop_leak_dephase_reject_inplace_ry_loop_leak_slice.ll`, the slice's verbatim stage-1
module, **validated NON-VACUOUS by binary mutation** (ORACLE: `EXPECTED-DECLINE but opt exit 0 ->
FAIL`; fix: `DECLINE + message matches -> PASS`).

⚠ **THE ASYMMETRY IS THE FILING, AND IT IS NOT A THING THIS INCREMENT CLOSED.**
`declineUndischargedMarkedBodyRails` is **LOOP-SCOPED by construction** — it verifies a promise
conjunct (1) makes about a MARKED LOOP BODY — so it structurally **cannot** reach the unrolled twin,
which has no loop and still compiles the identical hazard at exit 0. **Net: the hazard's population
shrank by one spelling and the residue is now named**, as a new P1 in `BD_TEXT.md` with its
red-green pair (RED = the kept unrolled `.c`, GREEN = the same program with the trailing
`cq_measure(r)` removed, control = the same with `s = r * 7` deleted). Do not read §9 as covering it.
