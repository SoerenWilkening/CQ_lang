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
| **bd `6n1s`** (the review's P1 over-accept) | **LANDED** `f6713c0e` | `tu9q-hoisted-template` | a MARKED multi-block body discharges its interior rails; conjunct (1) stops reading "marked" as "discharged" |
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

⚠ **It is a SUFFICIENT condition, not an oracle, and it does not close the general hole.** It
models the post-dominator sub-case only. A marked body whose rail is refused by clause (d), by
`preservesBasisUnderRecord`, or by a `ReversedGates` overlap still leaks with the fence silenced.
The TOTAL answer is the postcondition pattern — built on the WIP branch (§5), not here.

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
* **FOUND (F-R3-2)**: the landed prefix **cannot silence Track S′'s fence**, structurally: it marks
  no body, and conjunct (1)'s suppression is now strictly NARROWER than before (a second conjunct
  was added, never relaxed). The composition risk SCOPE_T2 §6 lens 9 names belongs to P3.
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

1. **No suite beyond two gates was run by me.** `ir-pass-lit` once and one corpus sweep, both at
   hand-off, both in `GATES.md`. NOT run: the full `ctest`, `^e2e-`, the twin matrices, the
   equivalence sweep. A skipped layer is a deferred cost.
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
4. **The fence half does not close the general hole** (§1.2). It models the post-dominator
   sub-case; clause-(d) and `preservesBasisUnderRecord` refusals still leak with the marking
   granted.
5. **No module was constructed on which `markedBodyRailsHaveInBodyDischargePoint` answers
   `false`.** It is validated by MUTATION (17 fixtures depend on its `true`), which shows it is
   live code, not that it has a customer.
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

## §8 — FOR THE INDEPENDENT REVIEWER: the three most dangerous things, in order

1. **`useCompleteBeforeDischarge`'s case split (F-R1-3).** The relaxation is sound *because* every
   user that the reversal will ADJOINT is re-proved under the unrelaxed `DT.dominates(G, At)` in
   §4. That rests on one claim: **an in-place gate on the owned rail is always in `D.Calls`.**
   Attack it. If `recoverDataDag` can ever fail to walk an in-place gate on an owned rail — a
   width-punned one, one behind a `!cq.branchphase` membership refusal, one the 7.4 break teardown
   minted — then a CONDITIONAL such gate reaches the relaxed leg and the adjoint fires on one arm
   of a diamond inside a marked body. That is a wrong unitary, not a leak, and nothing else in the
   change would notice.

2. **P2's OUTERMOST walk against a NEST, and the `Loop::contains` / `LI.getLoopFor` asymmetry.**
   SCOPE_T2 §6 lens 5 says *"one of the two is wrong in exactly one of the two sites"* — and **I
   did not build a nested customer**. The anchor walk uses `Loop::contains` (subloops INCLUDED:
   "is the mint inside this cycle at all") and `markedHeaderOf` uses `LI.getLoopFor` (INNERMOST:
   "how often does this block run"). Both are argued at their sites and neither is measured against
   a 3-deep nest. `r1_triple_nest_mid_rail` is the seed the scope names.

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
