# §bd — exact `bd` text for Group 1 (Track T2)

⚠ **I cannot write `bd` from a worktree** (`.beads/` is per-checkout; a write here creates a DB the
main checkout never sees). Everything below is for the orchestrator or a Wave-0 agent in the MAIN
checkout to apply. ⚠ `bd update --notes` **REPLACES** notes — use `--append-notes`.

---

## bd `test_C_libtooling-6n1s` — **CLOSE** (⚠ in TWO commits, not one)

> ⚠⚠ **THE FIRST COMMIT DID NOT CLOSE THIS BEAD, AND AN EARLIER REVISION OF THIS ENTRY SAID IT
> DID.** The independent Rule-13 round of 2026-09-18 (`review_r13_group1/REVIEW.md`, finding F-1)
> measured `g8_arm_use_derived_owned_rot.c` — `t5j` with the ARM minting an INTERIOR rail, ONE TOKEN
> from the witness `f6713c0e` closes — still ACCEPTING at exit 0 with four coherent which-path
> records alive across `cqrt_ry_i32(h0,0.9)` and `cqrt_measure_i32(h0)`, on the ORACLE, on
> `f6713c0e`'s subject **and** on the P0+P3 branch. It DECLINES on the pre-group `0e280fc6`, so it
> is the same regression from bd `tu9q`.1's third `markIfRailLocal` call site.
>
> **CLOSED 2026-09-18 by `f6713c0e` PLUS the F-1 fix** on branch `tu9q-hoisted-template`,
> `cq-opt df2445fcaf82cf00`.
>
> **WHY THE FIRST FIX MISSED IT.** Conjunct (1) suppressed on `bodyBlocksMarked &&
> markedBodyRailsHaveInBodyDischargePoint`, and BOTH are true for that module: the body is marked
> and the post-dominator fold is the join, an own marked block. The rails still leak because
> `planInteriorComponent` §4 abandons the WHOLE component on its per-gate `DT.dominates(G, At)` —
> the ARM's producer does not dominate the join. **The fence modelled ONE refusal mechanism and a
> multi-block body produces a DIFFERENT one by construction. A prediction about another file's
> placement is not a fence.**
>
> **THE FIX IS PREDICT-AND-VERIFY.** Conjunct (1) now RECORDS the suppression (at conjunct (3), so a
> loop with no post-loop rotation records nothing) and `declineUndischargedMarkedBodyRails` checks
> it at the tail of the pass, after `uncompute`, in BOTH entry points, using the EXISTING bd `s82e`
> string. A rail counts as discharged if it is adjointed+freed **or MEASURED** in-body — the second
> clause was forced by a measured over-decline (see below).
>
> ⚠ **THE PLACEMENT FIX — (a), which the round ranked first — IS NOT BUILT AND IS FILED.**
> Discharging the arm-minted rail in the arm and the header rail at the join is sound and was traced
> step by step, but it needs a component partition FINER than a component keyed on
> CONTROL-EQUIVALENCE (bd `tu9q` P0's multiplicity key does not separate them — both rails are in the
> SAME marked body) plus a PER-ACTIVATION cross-plan ordering check (P0's shipped
> `provablyBefore(At_inner, At_outer)` fails here). That is a new increment with its own Rule-13
> budget. **So the arm-minted shape now DECLINES where it is compilable in principle — an
> over-decline by the owner's 2026-09-11 ruling, filed as such.**
>
> ⚠ **AN OVER-DECLINE THE FIRST CUT OF THE FIX CAUSED, recorded because it is the instructive part.**
> Asking only "is there an `_unc`?" turned `lowering_reject_live_record_post_gate_record_loop.ll`
> from its owner-ruled WARNING (bd `lyyf`) into a DECLINE: its rail is the WIRE `w = q*2`, rotated in
> place and then `cq_measure`d, and `railIsInterior` calls it interior because it has a NON-measure
> user — a different question from "is it measured". Caught by lit, fixed by the MEASURED clause.
>
> **RED-GREEN by BINARY MUTATION over three binaries.** RED
> `loop_leak_dephase_reject_arm_minted_interior_rail.ll` fails on the ORACLE **and** on P0+P3
> (`opt` exit 0 where a decline is expected) and passes on the fix; GREEN
> `loop_pairing_accept_arm_minted_measure_owned_control.ll` (ONE token — the arm's rail
> measure-owned) fails three prefixes on the ORACLE and passes on the fix; CONTROL
> `loop_leak_dephase_reject_arm_minted_unmarked_control.ll` DECLINES on every binary, UNMOVED.
>
> **F-2 and F-3 are landed AT THE SITE in the same change** (`CLAUDE.md` L7-with-a-twist): the
> predicate's header now records that it returned `true` on all 19 of the round's probes and
> declined nothing in a 6566-row sweep — **the P1 was closed, for the shapes it is closed for, by
> the USE-SIDE relaxation alone** — and its "refusals I do not model" list now names §4's per-gate
> dominance on an ARM-MINTED rail, the one a multi-block body produces by construction.
>
> ⚠ **Do not re-close this bead on a green suite.** Both misses so far were one token from a witness
> the suite was green on.
>
> **THE OWED MEASUREMENT IS IN, AND IT IS A REGRESSION.** The pre-group tree `74eabd2c` was
> rebuilt in a scratch dir and reproduces the 2026-09-14 oracle exactly
> (`0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`). On it
> `t5j_twoblock_noexit_rot.c` **DECLINES** (`cq loop lowering: rolled body leaks a rail entangled
> with a register rotated after the loop`, that release's pre-`c767` spelling). On the session
> ORACLE `9bd01598` it ACCEPTS at exit 0 with 4 `cq_template_ashr_i32_hl` mints, ZERO `_unc`, ZERO
> `cqrt_free`. So the review's *reasoned expectation* was right and is now a fact.
>
> **MECHANISM, READ IN SOURCE.** At `74eabd2c` `markIfRailLocal` had exactly TWO call sites, both
> inside `collapseFlattenedLoopRails`, which returns early unless `taint.InLoopFlattenedPreds` is
> non-empty — and the witness has NO tainted control flow, so nothing marked it. bd `tu9q`'s
> round-1 root-mint escape added the THIRD call site (`LoopLowering.cpp:5471-5474`), which marks a
> body with no region in it; conjunct (1) then suppressed the fence on a body the spine had never
> discharged.
>
> ⚠ **THE REVIEW'S ROOT-CAUSE LINE NAMED A DIFFERENT PARTITION.** It named `computeFreePoint`'s
> `IterationLocalBlocks` MEMBERSHIP guard. True of the dead-terminal driver; the customer here is
> the **M-B interior** partition, which never calls `computeFreePoint`, and the rail is dropped in
> `planInteriorComponent`'s **convergence loop** by the `DT.dominates(U, At)` conjunct inside
> `provablyBeforePerActivation`. Same defect, different mechanism.
>
> **FIXED BY A PLACEMENT, NOT A DECLINE (Rule 17).** `useCompleteBeforeDischarge` asks the
> obligation the scan owes — *no use runs between the discharge and the NEXT execution of the mint*
> — instead of the strictly stronger dominance, SCOPED to a use, a discharge and a mint that all
> key to ONE marked body. Every gate whose ADJOINT is emitted is still re-proved under the full
> `DT.dominates(G, At)` in §4, so only a READER the reversal never touches is relaxed.
> Witness after the fix: 26 trace lines, 4 mints / 4 `_unc` / 4 `cqrt_free`, `0 left dirty`.
>
> **PLUS THE FENCE HALF (F-1's second option) AND F-2.** `declineDephasingUnmarkedLoopRails`
> conjunct (1) gains `markedBodyRailsHaveInBodyDischargePoint`; conjunct (1)'s argued header and
> `bodyBlocksMarked`'s retirement triggers are corrected AT THE SITE in the same change
> (L7-with-a-twist), including the trigger that header did not carry — *what the marking proves*.
>
> **RED-GREEN**, by BINARY MUTATION over both binaries: `loop_pairing_accept_twoblock_body_straddle.ll`
> FAILS on the ORACLE (both prefixes) and passes on the subject;
> `loop_pairing_accept_oneblock_body_control.ll` (ONE body block) and
> `loop_leak_dephase_reject_twoblock_unmarked_control.ll` (marking refused) are UNMOVED on both.
>
> ⚠ **NOT CLAIMED**: the fence half is a SUFFICIENT condition, not an oracle — it models the
> post-dominator sub-case, and a marked body whose rail is refused by clause (d) or by
> `preservesBasisUnderRecord` still leaks with the marking granted. And no module was constructed
> on which it answers `false`; it is validated by MUTATION (17 shipped fixtures depend on its
> `true`). The total answer is the postcondition pattern, built on `tu9q-p0-p3-wip` and not landed.
> Cross-reference bd `s82e` (the UNMARKED spelling of the same hazard) and bd `tu9q.1`.

---

## bd `test_C_libtooling-1m5p` — **CLOSE**

> **CLOSED 2026-09-18**, commit `bfb809be`. `Uncomputation::anchorForConsumer` anchors a rail
> minted OUTSIDE the cycle its consumer runs in at that cycle's unique EXIT, walking OUTWARD to
> the OUTERMOST such loop.
>
> MEASURED on `m_none_oder_none_none_none` (the class-A cell): rolled **27** == hand-unrolled twin
> **27**, `cq_template_sqrt_f64_unc` present in BOTH, trace **MULTISET IDENTICAL** with handle
> numbers normalised, ORDER-divergent. Was 25 vs 27 with `sqrt_f64_unc` 0 vs 1.
>
> **The LIFO inversion this bead records is gone**: the whole hoisted chain
> (`sitofp → fadd → sqrt`) is adjointed LIFO at the loop exit instead of the lower members being
> freed in the preheader while the top one was still live.
>
> ⚠ The six class-A `oder` cells **stay QUARANTINED with new arguments** — rolled and unrolled are
> multiset-identical and ORDER-divergent, so a `compare_files` twin gate would still be red. The
> merge-and-gate agent re-measures all **twelve** `oder` rows (the `add_*` six are class B, bd
> `a3z7`, and their digests may move underneath); see `trackT2/QUARANTINE_HANDOFF.md`.

---

## bd `test_C_libtooling-s82e` — **APPEND, do not close**

> **The `a1_apost` half is CLOSED by commit `bfb809be` (2026-09-18); the bead is NOT.**
>
> `probes/a1_apost.c` — this bead's own hoisted-rail class, built by the 2026-09-18 scoping because
> nobody had — compiled at `opt` exit **0** on the ORACLE with the LICM-hoisted
> `sqrt((double)a + 3.0)` rail left allocated and entangled, a non-diagonal `cqrt_ry_i32(h, 0.7)` on
> the register it copies, and then a measurement of that register. Rolled and flat were DIFFERENT
> unitaries. After P2: rolled **28** == twin **28**, MULTISET IDENTICAL, and **`opt` stderr is 0
> bytes** where the ORACLE emitted `cq rotation lowering: non-diagonal gate over a live derived
> record` — the warning goes silent because the record is DISCHARGED, which is the test SCOPE_T2 §6
> round-1 lens 7 asks for.
>
> ⚠ **NEW FINDING TO CARRY ON THIS BEAD**: `declineDephasingUnmarkedLoopRails`' conjunct (3)
> quantifies over `L`'s **OWN blocks**, so a rail LICM-hoisted into the **PREHEADER** is in none of
> them and **the fence built for this hazard class is structurally blind to the hoisted instance of
> it**. That is why `a1_apost` compiled silently. P2 removes the customer; the blind spot is
> unchanged and is still this bead's.

---

## bd `test_C_libtooling-tu9q` — **APPEND, do not close**

> **P1 and P2 LANDED 2026-09-18** (`f6713c0e`, `bfb809be`, branch `tu9q-hoisted-template`).
> **P0 and P3 are BUILT AND MEASURED BUT NOT LANDED** — branch `tu9q-p0-p3-wip` `30b80d7f`.
>
> P1 is the real multiplicity test `Uncomputation.cpp` §4's own comment has been asking for since
> bd `8h7d.5` round 5 (*"the obligation is a real multiplicity test … not a re-reading of these
> two"*) — `markedHeaderOf` / `multiplicityAgrees`, asked at §4, at §2.9 on the final `At`, and
> mirrored in `reverseTerminalGroup`. P2 is the loop-exit anchor; `loopExitDischargePoint` is
> exported from `LoopPlan.h` as the ONE spelling, with its GRANTING direction stated at the
> declaration BEFORE its second caller exists.
>
> **P0+P3 works for its customers** — `s2`, `hoisted_template` and `short_sext` all lower with
> `mint == _unc` on every rail, and `hoisted_template` measures rolled **40** == twin **40**,
> multiset identical — **and it moves 8 shipped fixtures, two of which are other owners' Rule-13
> fences losing their subject.** Full ledger in `trackT2/IMPL_T3.md` §5. The two that are not
> mechanical:
>   * `loop_pairing_reject_round2_falsified` goes **DECLINE → exit 0**, because **P1 retires the
>     premise that fixture's own header gives for its decline** (*"K adjoints against ONE forward
>     gate"*). Measured on the WIP binary: the preheader `mul` is minted once and adjointed once at
>     the loop exit. Retiring another owner's Rule-13 fence is not an implementer's call.
>   * `control_inplace_ry_reject_rail_inloop_carried_invariant_read` string-moves to the (ii-d)
>     postcondition. Still a decline — and **with the postcondition removed that module COMPILES**,
>     so the postcondition is holding a verdict, not decorating a message.
>
> Two narrowings of clause (ii-d) were tried; the KEPT one ("every user inside `L`") took the mover
> count 14 → 8 and restored both controls SCOPE_T2 §4 names; the REJECTED one ("no carried rail")
> is recorded at the clause so it is not re-derived as an improvement.
>
> ⚠ **SCOPE_T2 §3.4's source reading is falsified**: `mintsOutOfPlaceTemplateRail` does **not**
> return false for `control_phase_kickback_mixed_preheader_volatile_imm…`'s in-place `add` at the
> stage clause (ii-d) asks it — the (1a) fence has refused the COMMIT, so the forecast says
> "out of place" and M-C then lowers it IN PLACE anyway. The postcondition must therefore ask its
> question in the POST-LOWERING vocabulary; that conjunct is on the WIP branch with its own
> direction note and trigger.

---

## bd `test_C_libtooling-0kjo` — **APPEND**

> **The landed prefix (P1+P2) adds NO customers to this L1 window.** It introduces no taint-growth
> event and no new marking: `markedHeaderOf` READS `taint.IterationLocalBlocks` and never writes
> it, and conjunct (1)'s suppression is strictly NARROWER than before. The window
> SCOPE_T2 §2.5(2) names — `collapseFlattenedLoopRails`' marking at `LoopLowering.cpp:3891-3907`
> runs at `CQLoweringPass.cpp:600`, before `repropagateControlMerges` at `:616`, and calls **no**
> `recordRound1RailGrant` — is widened by **P3**, which did not land. The pre-existing population
> stays on this bead and gains none.

---

## NEW BEADS TO FILE

1. **P3 (over-decline / capability, P2)** — *the acyclic diamond-use residual of
   `useCompleteBeforeDischarge`*. An interior rail minted in `entry` and read in BOTH arms of a
   classical `if` is still dropped by the convergence loop and leaks, because the 2026-09-18
   relaxation is SCOPED to one marked body. The identical argument admits it; the scoping exists
   only so the change is byte-inert for every acyclic module in the tree. Mechanism known, no
   measured customer, and it needs its own Rule-13 round because it moves modules with no loop.

2. **P3 (over-decline, `RotationLowering.cpp`)** — *`recordIsExemptAt` clause 4 cannot exempt a
   CONDITIONALLY-executed measure*. Measured on `t5j_twoblock_noexit_rot.c` after bd `6n1s`: every
   `ashr` rail is discharged and every `and` rail is measured, yet `warnLiveRecordRotations` still
   fires, because the `and(%h_op, 2)` rail's own `cqrt_measure` sits in a guarded block and does
   not DOMINATE the post-loop rotation, so `provablyBeforePerActivation`'s dominance conjunct
   fails. Same dominance-vs-conditional-execution shape bd `6n1s` fixed in `Uncomputation`, in a
   guard `RotationLowering.cpp` owns. **Deliberately not fixed there** — a second spelling of
   another owner's predicate is the drbq Inc-3 (b′) defect (Rule 14).

3. **P3 (test debt)** — *ONE e2e slice pair landed where SCOPE_T2 §5 asks for TWO*.
   `e2e-slice-loop-hoisted-chain-exit-discharge{,-unrolled}` is the Rule-16 witness for P2 and for
   the `a1_apost` closure (rolled 28 == unrolled 28, goldens byte-divergent and MULTISET-identical).
   The scope's second pair is P3's and is not here because **P3 is not here**. ⚠ The rolled half
   runs with `--allow-unproven` for a STRUCTURAL reason written at its registration:
   `free_pairing_check.py` analyses per straight-line STREAM, so a loop-exit discharge is
   `U3-extern-rail` UNPROVEN **by construction** (measured: rolled `1 verified, 3 unproven`, twin
   `5 verified, 0 unproven`).

4. **P3 (instrument)** — *`free_pairing_check.py`'s stream model cannot witness a per-trip or
   loop-exit discharge*. Not a defect in the circuit and not a new one, but it is now load-bearing:
   every rail this increment discharges is TEMPLATE-minted, so stage 2b is blind in one direction
   and UNPROVEN in the other, and `e2e-loop-twin-matrix` is the only instrument left that can see
   the class.

5. **P3 (test debt)** — *`inject_T.py` reports `N/A` for `inject_unc_free` on
   `loop_pairing_accept_hoisted_chain_exit_discharge.ll`*. An `n/a` is a HOLE, not a pass
   (PROTOCOL S3). The batch is otherwise `47 mutations, MISSED 0`.

6. **P2 (pre-existing, population widened)** — *`taint.IterationLocalBlocks` is a raw
   `BasicBlock *` set that nothing scrubs*, and bd `6n1s` gives it a NEW KIND of consumer:
   `markedHeaderOf` makes the set decide a MULTIPLICITY question rather than only a suppression.
   The asymmetry that keeps it safe is written at the definition — a stale-true gives a block a
   NON-null key, and a non-null key can only make `multiplicityAgrees` return **false** where the
   other endpoint keys null, so the added population's failure mode at the new site is a REFUSAL
   (a leak), not a grant. The scrub itself is cross-TU and out of scope here.

---

## NEW BEAD — **P1**: *two shipped goldens pinned a Rule-8 wrong unitary under a green `twin-identical` gate, and only the ROLLED half is now fenced*

> **P1 OVER-ACCEPT, straight-line (NO loop, NO tainted control flow needed on the surviving
> half).** Found 2026-09-18 by the merge gate's blast-radius sweep of the bd `6n1s` F-1 fix, and
> MEASURED by Group 1 on the fixed binary `df2445fcaf82cf00` rather than assumed.
>
> **WHAT SHIPPED.** `tests/e2e/slice_control_inplace_ry_loop_leak.c` and
> `…_unrolled.c` were REGISTERED e2e slices with committed goldens and a GREEN
> `e2e-inplace-ry-loop-leak-twin-identical` gate. Both goldens contain, per trip / per copy:
>
> ```
> cq_template_mul_i32_hl(h2, 7) -> h3      <- a COHERENT copy of h2's basis label
> cqrt_tape_write_i32(t0, h3) -> h4        <- a COPY into the output tape; h3 is NOT
>                                             collapsed and stays entangled with h2
> cqrt_ry_i32_controlled(h5, h2, 0.9)      <- NON-DIAGONAL, on h2
> cqrt_measure_i32(h2)                     <- h2 IS the observable
> ```
>
> `h3`/`h6` are never `_unc`'d and never freed. **That is `CLAUDE.md` Rule 8 verbatim and §5's
> Q-R1-1 correction in its own words**, and BOTH slice headers asserted *"IT IS RULE-6 CORRECT"* —
> the exact sentence that correction ruled FALSE for three sibling fixtures. ⚠ Only the tape-write
> RESULT (`h4`, `h7`) is an `OutputRails` member; its OPERAND `h3` is an ordinary interior template
> rail, so *"it is the program's own output"* does **not** excuse it.
>
> ⚠ **WHY NO GATE SAW IT, and this is the transferable half.** The twin-identical gate compares the
> two goldens with `compare_files`. The unrolled twin leaks the SAME rail in the SAME place, so the
> comparison PASSED. `CLAUDE.md` L10 already states the general form — *"a cell whose two halves
> agreed because BOTH were wrong is precisely what ACCEPT-IDENTICAL cannot see; only a fence can"* —
> and this is a second measured instance of it, on a REGISTERED e2e pair rather than a matrix cell.
> Stage 2b could not see it either: every leaked rail here is TEMPLATE-minted, and the checker has
> no `cqrt_alloc` to count.
>
> **WHAT IS CLOSED AND WHAT IS NOT — say this halves-first, because the asymmetry IS the bead.**
> The bd `6n1s` F-1 fix (`declineUndischargedMarkedBodyRails`) refuses the **ROLLED** half: measured
> `opt` exit 1, `cq loop lowering: rolled body leaks a rail entangled with a rotated register`. That
> fence is **LOOP-SCOPED by construction** — it verifies a promise conjunct (1) makes about a MARKED
> LOOP BODY — so it **structurally cannot reach the UNROLLED twin**, which was re-measured on the
> fixed binary as **byte-identical to its old golden, exit 0, unchanged**. **The straight-line
> spelling of this hazard still compiles today and nothing refuses it.**
>
> **DISPOSITION TAKEN 2026-09-18** (coordinator option (ii), the 2026-09-14 stale-reader precedent):
> both goldens DELETED rather than regenerated; all THREE ctest entries unregistered
> (`e2e-slice-control-inplace-ry-loop-leak`, `…-unrolled`, `e2e-inplace-ry-loop-leak-twin-identical`
> — 449 → 446 `add_test`, 0 duplicates, sweep still last); both `.c` files KEPT with conversion
> headers and L8 triggers (a deleted fixture can be resurrected by a merge — L8, bd `gahu`). The
> ROLLED decline is pinned by `ir-pass/test/loop_leak_dephase_reject_inplace_ry_loop_leak_slice.ll`,
> the slice's verbatim stage-1 module, **validated NON-VACUOUS by BINARY MUTATION** (on the ORACLE
> `9bd01598` it reports `EXPECTED-DECLINE but opt exit 0 -> FAIL`; on `df2445fcaf82cf00` it passes).
> **Net coverage for the rolled half: zero. For the unrolled half: this bead.**
>
> **WHAT THIS BEAD OWES**, in the order a fix should take them:
> 1. a fence (or a placement) that reaches the **straight-line** which-path leak — the class bd
>    `s82e` owns; this is a new REGISTERED-GOLDEN customer for it, not a new class;
> 2. RED = `tests/e2e/slice_control_inplace_ry_loop_leak_unrolled.c` (kept unregistered for exactly
>    this), GREEN = the same program with the trailing `cq_measure(r)` removed so nothing observes
>    the rotated register, isolating control = the same program with `s = r * 7` deleted;
> 3. when it lands, BOTH `.c` files become ACCEPTs and the twin-identical gate can be restored —
>    re-derive both streams against the hand-unrolled twin's MULTISET (owner ruling S3, 2026-09-17),
>    and do **not** restore the deleted goldens, which pin the leaking stream.
>
> ⚠ **DO NOT READ THIS AS "the F-1 fix caused a regression".** The hazard is PRE-EXISTING and
> shipped; the fix removed one half of it and made the other half visible. *"'pre-existing' is true
> of the defect and FALSE of its population"* cuts the other way here for once: the population
> SHRANK by one spelling and the residue is now named.
>
> Cross-reference bd `s82e` (the class), bd `6n1s` (the fence that took the rolled half), bd `bbu0`
> (whose twin pair these were), bd `1yeu` (the instrument-gap family this joins).
