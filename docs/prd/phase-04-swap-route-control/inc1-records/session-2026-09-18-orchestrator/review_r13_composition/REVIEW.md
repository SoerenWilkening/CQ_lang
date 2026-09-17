# Rule-13 INDEPENDENT REVIEW — **the COMPOSITION** of session 2026-09-18's landings on ONE binary

# VERDICT: **CLEAR-WITH-ITEMS**

Four findings: **one P1 against an INSTRUMENT** (Track C's new (T4) rule can be made to VERIFY the
exact K:1 stream it was written to refuse, through a `switch` back edge — F-1), **one P3 instrument
conservatism that is composition-visible** (F-2), **one P3 record-scoping correction to the gate's own
G-2** (F-3), and **one P2 over-decline candidate the composition does not reach** (F-4).

**The composed LOWERING held against every construction I aimed at it.** Of 19 constructed probes,
every accept on the COMBINED binary emitted a stream I could read as correct by analytic/trace
reasoning, every decline was in the safe direction for a reason I could name in source, and I found
**no module the composition makes worse than either part alone**. The P1 is against
`tools/free_pairing_check.py`, the gate that the composition's own evidence now leans on hardest
(G-4: `--allow-unproven` 5 → 4 *because* (T4) proves P2's placement).

Independent reviewer. I **built nothing, ran no suite, no corpus sweep, no matrix, no equivalence
run**, edited no source, fixture or test, and wrote only under `$SES/review_r13_composition/`.
Everything below is `$SES/PROTOCOL.md`'s per-probe pipeline plus analytic/trace reasoning (no
simulation — owner 2026-06-10). Gate lines in `GATES.md`.

---

## Binaries — verified on disk before any measurement

| role | path | sha256 (first 16) | verified |
|---|---|---|---|
| ORACLE | `$REPO/build/ir-pass/cq-opt` | `9bd01598d574b344` | matches the brief and `PROTOCOL.md` character-for-character |
| **COMBINED** (subject) | `.claude/worktrees/agent-ac2acfdde3461becc/build/ir-pass/cq-opt` | `07d937842bfb5135` | matches the brief |
| Group 1 alone | `.claude/worktrees/agent-ad443b9a480ffb751/build/ir-pass/cq-opt` | `df2445fcaf82cf00` | matches the brief |
| Track D alone | `.claude/worktrees/agent-ad7349188dd3b67bd/build/ir-pass/cq-opt` | `5ee9d14420c3533a` | matches the brief |
| P0+P3 (not landed) | `.claude/worktrees/p0p3/build/ir-pass/cq-opt` | `e951d5d1bc072902` | matches the brief; **not used** — see "what I did NOT attack" |

⚠ The Group-1-alone binary at `df2445fc` is **post-F-1-fix** (`22a0ab11`), not the `7c1163ad` prefix
`review_r13_group1` measured. Stated because it changes how its rows read: `g8` DECLINES on it.

Stage 2b throughout is the **GATE worktree's** `tools/free_pairing_check.py` (Track C's (T4)), per the
brief; the main checkout's copy has no (T4) and would report `U3-extern-rail` on every row.

## What I read

`$REPO/CLAUDE.md` — Prime Directive; Rules 2, 6, 8, 13, 14, 19; CORRECTNESS RISK §1 the loop rows,
§2 "Condition-wire disposition" and "Loop scope", §3 **L1–L5 and L10**, §4c's composition paragraphs
(F×P, F′×P′ `c1`/`c2`, R-1/R-2) and §5's open list (bd `s82e`, `1m5p`, `7845`, `lyyf`, `1yeu`).
`$SES/PROTOCOL.md` whole incl. §6.1. The three prior rounds whole —
`review_r13_group1/REVIEW.md` (F-1…F-6, §C, and its closing "did NOT attack"),
`review_r13_trackD/REVIEW.md` (F-1…F-5, §5, §6), `review_r13_loopconv/REVIEW.md` (scanned for its
single-block-coincidence claim). The gate's `gate/COMPOSITION.md` and `gate/FILINGS.md` whole
(G-1…G-10 plus the pass-2 dispositions). `trackC/IMPL_C.md` §(T4) and the arm-kill matrix as carried
in the source docstring.

**Source, read on disk at the gate branch and not remembered** (`git diff main -- ir-pass/src
ir-pass/include tools/free_pairing_check.py`, hunk by hunk): `Uncomputation.cpp`'s `markedHeaderOf`,
`multiplicityAgrees`, `useCompleteBeforeDischarge`, `anchorForConsumer`, the three
`multiplicityAgrees` call sites and the `planInteriorComponent` signature change;
`LoopLowering.cpp`'s `bodyBlocksMarked`, `markedBodyRailsHaveInBodyDischargePoint`, the obligation
ledger, `declineUndischargedMarkedBodyRails`, `loopExitDischargePoint` and
`declineDephasingUnmarkedLoopRails` conjuncts (1)/(2)/(3) **in full**; `ArmClassify.cpp`'s
`anyInstructionInGap`, `isChainedThetaCall`, `condRailMembers`, `railRelabellingGateOn`,
`crossBlockCompareMintable`, the `condWireDisposition` P4/P5 edit and both `classifyPhaseKickback`
edits; `CQLoweringPass.cpp`'s stage order in **both** entry points; `RotationLowering.cpp`'s
`warnLiveRecordRotations` and `recordIsExemptAt`; and `tools/free_pairing_check.py`'s
`CrossStreamIndex`, `cyclic_blocks`, `stream_runs_at_most_once`, `loop_exit_discharge`,
`build_streams` and the block/terminator parser.

## My instrument, and the two times it lied to me

`$SCRATCH/r13comp/cp.sh`, private to this review (group1 F-4: the session scratchpad root is a shared
writable path with no diagnostic; mine is under my own session scratchpad). It **self-attacks before
use** — a 0-byte `.c` returns `VACUOUS-EMPTY` rc=2 and a quantum-free `.c` returns `VACUOUS-NOQUANTUM`
rc=2, both run and recorded in `GATES.md` — and it stamps the binary's sha256 on every row.

It still misreported twice, both caught by reading the output rather than the summary (`CLAUDE.md`
L10): (1) the link step was `clang … && ./a && echo trace` so a probe whose **program** exited
non-zero (`return 7`) printed `LINK/RUN FAILED` — fixed to capture the program's exit separately;
(2) a mover sweep printed `exit=$?` **after** a `$(basename …)` command substitution had reset `$?`,
so ten rows reported `exit=0` for declining runs — re-run in full. Every number below is from the
corrected harness.

---

## ATTACK 1 — Track D's admission × Group 1's placement

`dD1` is the cleared instance; these are its neighbours. Every row `-O1 -g`, `cq-opt`, STRICT 2b with
(T4), link+run where the stream argument needs the trace.

| # | probe | delta from `dD1` | ORACLE `9bd01598` | G1 `df2445fc` | D `5ee9d144` | **COMBINED `07d93784`** | right? | why |
|---|---|---|---|---|---|---|---|---|
| 1.0 | `dD1` (re-measured) | — | D `condition predates…` | D same | A, **1 dirty**, warns | **A, 0 dirty, 2 free, 2 verified 0 unproven, stderr 0 B** | ✅ | reproduces `COMPOSITION.md` §1 at the PASS-2 hash. Rolled confirmed in IR (`!llvm.loop`, loop `%3`); `and_i32_hl_unc(h2,h0,1)`+`free(h2)` are at the TOP of the exit block, strictly before `cqrt_ry_i32(h0,.9)` |
| 1.0b | `dD4` twin (re-measured) | hand-unrolled | D | — | — | **A, 22 lines, MULTISET IDENTICAL to `dD1`** | ✅ | sole divergence one `cqrt_free(h4)` position on a **disjoint** rail; re-measured at `07d93784`, the gate measured it at `96d74fe6` |
| 1.1 | `x1_multiexit_hoisted_cond_then_ry` | + a second exit (`return 7`) | D `condition predates…` | — | — | **A, 0 dirty, 1 UNPROVEN, rc=1** | ✅ | ⚠ `-O1` **MERGED** the two exits into one block `%9` with a phi — the **5th** neutralised multi-exit attempt (group1 F-5 counted four). The rail is discharged once on BOTH paths. The `1 unproven` is F-2 |
| 1.2 | `x2_twoexit_goto` | two exits with different content | D | — | — | **A, 0 dirty, 1 UNPROVEN, rc=1** | ✅ | merged again — the **6th** attempt. `getUniqueExitBlock()` is still a PREDICTION, not a test |
| 1.3 | `x3_cond_rail_parent_rotated_inbody` | `q = cq_theta(q,.1)` **in the body** | D | **D** | **D** | **D `condition predates a non-diagonal gate`** | ✅ | the hazard the exit-discharge would otherwise realise — `and_unc(h2,h0,1)` recomputed from a ROTATED `h0` would not invert its forward, so the free would be **dirty** (Rule 6, a hidden measurement). `condWireDisposition`'s position-aware wire walk (which `crossBlockCompareMintable` does **not** relax) refuses it on all four binaries, and (T4g) independently refuses the same operand movement |
| 1.3c | `x3c_parent_rotated_after_loop_control` | the same rotation AFTER the loop | D | **D** | A, **1 dirty**, warns | **A, 0 dirty, 2 verified** | ✅ | the isolating control: a **composition cell** — neither track alone |
| 1.4 | `x6_rolled_postloop_reader_after_rotation` | + `u = t*3` AFTER the trailing rotation | D | **D** | **A, 1 dirty, no warning** | **A, 1 dirty, no warning — md5 IDENTICAL to D** | ⚠ **F-3** | the anchor set gains a post-rotation consumer, `dagInsertPoint` takes the LATEST anchor in the exit block, and clause (d)'s borrowed-parent scan then abandons the component → **LEAK, the safe direction**. `recordIsExemptAt` clause 3 exempts the record because the user **observes it after the gate** — the bd `lyyf` user's-circuit class. Correct circuit; **wrong sentence in G-2** |
| 1.5 | `x7_rolled_postloop_reader_before_rotation` | the same line BEFORE the rotation | D | **D** | A, 0 dirty | A, 0 dirty, md5 identical to D | ✅ | one line apart from 1.4 and it discharges. Isolates the discriminant as *"is the rail's last use before or after the gate"*, not the composition |
| 1.6 | `x13_two_hoisted_compares_one_rail` | TWO hoisted compares over ONE rail | D | — | — | **A, 0 dirty, 3 free, 3 verified** | ✅ | trace: 2 trips × 2 regions, each flag minted/gated/stripped/freed in-body; then **ONE** `and_unc(h3,h0,3)`+`free(h3)`, then `ry(h0,.9)`. One adjoint against one forward gate |
| 1.7 | `x14_nested_loop_rail_hoisted_past_both` | the loop is a **nest** | D | — | — | **D `condition predates a non-diagonal gate`** | ⚠ **F-4** | the nested spelling of a program whose single-loop form accepts. Unmoved from the ORACLE, so pre-existing; but it means **P2's OUTERMOST anchor walk gains no nest customer through D's door** |
| 1.8 | *(order at the exit block)* | — | — | — | — | **no such shape exists** | ✅ | structural, and measured four ways (1.0, 1.6, `x9`, `x15`): D's flag is minted at `BI` **inside the body** and stripped+freed there on every trip, so the exit-block discharge cannot precede it. `ShareCondFlag` — the one path that mints at `Cond->getNextNode()` — is kept on the unconditional decline by `crossBlockCompareMintable`'s conjunct (4), read in source at `ArmClassify.cpp` |

**The unitary argument for the accepts, once, because it is the same one.** The hoisted rail `h_t` is
written exactly twice — by its forward `cq_template_<op>_hl(h_q, k)` in the preheader and by its own
adjoint at the loop exit — with `h_q` unwritten between them (1.3 is the module where that premise
fails, and it declines). Every in-loop use reads `h_t` as a control into its own fresh flag rail,
which the emitter mints, brackets, gates, strips with its own inverse and frees **within the trip**.
So `h_t = |0⟩` at its `cqrt_free`, the free collapses nothing (Rule 6), and the trailing non-diagonal
gate on `h_q` runs with no coherent record of `h_q` alive (Rule 8). Multiplicity is **1 : 1** — the
forward gate is in the preheader (once), the adjoint in the unique exit block (once) — which is
exactly what `multiplicityAgrees` re-asks at §4 and again on the final `At`.

---

## ATTACK 2 — Group 1's backstop × Track D's accepts

**All 14 of Track D's movers, on the COMBINED binary, STRICT 2b with (T4).** Nine shipped fixtures
run from the gate worktree's own `ir-pass/test/`; five probe-corpus modules run from the main
checkout. Every row: `opt` exit 0, **zero** warning lines, 2b **rc=0**, `0 template rails left dirty`,
**0 unproven, 0 violations**.

| mover | exit | warn | 2b rc | census |
|---|---|---|---|---|
| `control_inplace_ry_crossblock_cond_inplace_add_after_loop.ll` | 0 | 0 | 0 | 1 template rail, 0 dirty, 1 free: 1 verified |
| `control_inplace_ry_crossblock_cond_outofplace_add_in_gap.ll` | 0 | 0 | 0 | 3, 0 dirty, 2 free: 2 verified |
| `control_inplace_ry_crossblock_cond_wire_gate_after_loop.ll` | 0 | 0 | 0 | 1, 0 dirty, 1 free: 1 verified |
| `control_inplace_ry_crossblock_cse_cond.ll` | 0 | 0 | 0 | 2, 0 dirty, 2 free: 2 verified |
| `control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll` | 0 | 0 | 0 | 1, 0 dirty, 1 free: 1 verified |
| `control_phase_kickback_inloop_hoisted_tree_leaf.ll` | 0 | 0 | 0 | 2, 0 dirty, 3 free: 3 verified |
| `control_phase_kickback_reject_inloop_invariant_cond_hoisted.ll` | 0 | 0 | 0 | 1, 0 dirty, 1 free: 1 verified |
| `control_phase_kickback_reject_tree_cross_block_leaf.ll` | 0 | 0 | 0 | 2, 0 dirty, 3 free: 3 verified |
| `control_swap_reject_seq_shared_cond.ll` | 0 | 0 | 0 | 2, 0 dirty, 2 free: 2 verified |
| `…/session-b6ap/…/u04_newbranch.s1.ll` | 0 (D on ORACLE) | 0 | 0 | 2, 0 dirty, 2 free: 2 verified |
| `…/trackW/fix_r2_probes/w2i3_h1_cmpcond.fxora.s1.ll` | 0 (D on ORACLE) | 0 | 0 | 3, 0 dirty, 3 free: 3 verified |
| `…/w2i2_h1_round2.fxora.s1.ll` | 0 (D on ORACLE) | 0 | 0 | 2, 0 dirty, 2 free: 2 verified |
| `…/w2i2_h1_round2.fxsub.s1.ll` | 0 (D on ORACLE) | 0 | 0 | 2, 0 dirty, 2 free: 2 verified |
| `…/w2i3_h1_cmpcond.fxsub.s1.ll` | 0 (D on ORACLE) | 0 | 0 | 3, 0 dirty, 3 free: 3 verified |

**Does any of them contain the g8 door — a marked multi-block body with an ARM-minted interior rail?
No, and the reason is STRUCTURAL rather than lucky, measured:**

| # | probe | ORACLE | G1 `df2445fc` | **COMBINED** | reading |
|---|---|---|---|---|---|
| 2.1 | `x8_g8door_inside_d_admitted_region` — the g8 shape (`if (k<3){ e=d+7; measure(e&2); }`) placed inside a body whose region's condition is a HOISTED compare | D `condition predates…` | — | **D `control flow inside a loop body under quantum control`** | **the two are DISJOINT**: a loop body with in-body tainted control flow AND more than one block is refused by `ControlDetect` before the marking or the ledger is reached. Every D accept therefore has a SINGLE-BLOCK body |
| 2.2 | `g8_arm_use_derived_owned_rot` (group1 F-1's own witness) | **A, 2 dirty, 0 free, 2 warnings, 2b rc=0** | **D `rolled body leaks a rail entangled with a rotated register`** | **D, same string** | group1's F-1 is **CLOSED** on the combined binary. ⚠ Note the ORACLE row: stage 2b returns **rc=0** on a module with 2 dirty rails and 0 frees — it COUNTS and does not FAIL (CLAUDE.md's structural blindness, restated) |
| 2.3 | `x16_g8_in_a_second_function` — the same witness in a `noinline` non-`main` function, `main` clean | A, 2 dirty, 1 warning | **D** | **D, and the diagnostic names `leaky`** | the new backstop is **cross-function-sound for this shape** — one slice of bd `1yeu` closed by measurement. Its ledger is module-scoped, filled by a module-scoped writer, cleared at both ends, and `DominatorTree`/`LoopInfo` are rebuilt per offender |

Moreover, conjunct (3) enumerates `L->blocks()` only, so a **preheader**-minted hoisted rail — the
entire subject of Track D's widening — **records no obligation at all** and the backstop is not its
fence. That is not a hole here (the class is covered by `planInteriorComponent`'s own refusals plus
`warnLiveRecordRotations`), but it is the sentence to carry: *the g8 backstop does not stand behind
any rail Track D's door admits.*

---

## ATTACK 3 — the round-2 window across landings

Read in source on the gate branch, `CQLoweringPass.cpp`, **both** entry points (`run` and the
`runOnFunction` shim, which its own comment marks DEAD — `Plugin.cpp` registers the module pass):

```
:500 lowerLoops                :582/:583 detectControlRegions / lowerControlRegions   (ROUND 1)
:600 collapseFlattenedLoopRails
:616 repropagateControlMerges  ......................................................  (ROUND-2 FIXPOINT)
:637 reverifyRailCondReads     :646 reverifyCmpCondReads
:809 declineRecordedStaleQuantumReaders
:817 declineDephasingUnmarkedLoopRails        <- G1 conjunct (1)+(3): the RECORD is taken HERE
:824 declineRound2FalsifiedRailGrants
:826 lowerRotations -> lowerOps -> lowerMeasures -> uncompute   <- G1 P1+P2 run INSIDE uncompute
:936 emitDeferredDephasingDecline
:953 declineUndischargedMarkedBodyRails       <- G1's BACKSTOP
```
(mirrored at `:1296 / :1349 / :1362` in the second entry point — parity present, checked line by line.)

| decision | slot | after the fixpoint? | verdict |
|---|---|---|---|
| (b) **G1's P2 anchor / P1 multiplicity** (`anchorForConsumer`, `multiplicityAgrees`) | inside `uncompute`, at the tail | **YES** | no L1 window. `markedHeaderOf` reads `taint.IterationLocalBlocks` when taint is final |
| (b′) **G1's conjunct-(1) record** and its **backstop** | `:817` and `:953` | **YES, both** | no L1 window, and the backstop is the L1 *cure* pattern (record, re-ask on the FACT) applied to a stage-ordering problem rather than a taint one |
| (a) **D's `crossBlockCompareMintable`** | inside `detectControlRegions`, i.e. ROUND 1 at `:582` | **NO** for a region detected in round 1 | a **documented, pre-existing residual whose population this landing widens**. Its own header says so: the WIRE and MEASURE rungs ARE re-asked (`markCmpCondRead` keyed on the MINT's position, `reverifyCmpCondReads` at `:646` in both entry points); *"the POSITIONAL question is the one nothing re-asks"* |
| (c) **both, on one rail** | — | — | probe 3.1 below |

| # | probe | ORACLE | D | **COMBINED** | right? |
|---|---|---|---|---|---|
| 3.1 | `x15_round2_out_feeds_hoisted_rail_and_p2` — a 4.4 merge `%out` feeds the hoisted rail `a & 1`, which is BOTH D's cross-block condition AND the rail P2 anchors | D `condition predates…` | **A, 1 dirty** | **A, 0 dirty, 3 free, 3 verified, stderr 0 B, 35 lines** | ✅ a **three-way composition cell** (4.4 merge × D's door × P2's anchor). Trace read in full: the select merge builds `h4`; `and(h4,1)→h7` in the preheader; two trips of mint/`x`/`ry_controlled`/strip/free; then ONE `and_unc(h7,h4,1)`+`free(h7)`; then `ry(h0,.9)`; `h4` left allocated and measured. Every rung is the shipped one |

**So the L1 answer is: G1 adds no window; D widens the population of one it inherited and names.**
The residual is the same one `IMPL_D2b` R-7 calls *"probably empty, never closed"*, and I did not
close it either — see "what I did NOT attack".

---

## ATTACK 4 — Track C's (T4) × the compiler  → **F-1**

| # | probe | what it is | (T4) verdict | right? |
|---|---|---|---|---|
| 4.1 | `t4_switch_backedge_k1.ll` | a rail minted ONCE in `entry`, **reversed-and-freed PER TRIP** in a block whose back edge is a `switch` **case** | **`2 verified, 0 violation(s), 0 unproven`, rc=0** | ❌ **F-1** — this is the K:1 shape (T4f) exists to refuse, and the gate PASSES it |
| 4.2 | `t4_br_backedge_k1_control.ll` | byte-identical, back edge spelled `br i1` | `1 verified, 0 violation(s), **1 unproven**`, rc=1, and the message is (T4f)'s own: *"the block carrying the reversal … can execute more than once — a rail minted ONCE and reversed-and-freed PER TRIP is the K:1 shape, and it is a use-after-free from the second trip on"* | ✅ the isolating control: **one terminator spelling** is the whole delta |
| 4.3 | the parse gap on a **real shipped module** | `lowering_classical_mux_phi_onereg_switch_nway.ll`, lowered by the COMBINED binary, parsed with the checker's own `parse_module` | `succ['%entry'] = ['%merge']` (the two case targets missing); `preds['%arm1'] = preds['%arm2'] = []` | ❌ the gap is not hypothetical |
| 4.4 | reachability | every `ir-pass/test/*.ll` lowered by the COMBINED binary and grepped for a `switch` in the OUTPUT | **1 of 1045 accepting fixtures** (the file in 4.3) | latent, not live — see F-1's direction paragraph |
| 4.5 | *"a rail written inside the loop through an alias"* | — | **the compiler cannot emit it**: a handle is an `i32` SSA value, there is no alias; and (T4c) is a function-wide write COUNT, so any second writer refuses | ✅ |
| 4.6 | *"a controlled-copy target"* / *"an `_inv`"* | — | **the compiler cannot emit it**: a `cqrt_copy_<W>_controlled` target is an **alloc** rail, refused by (T4a); an `_inv` mint is `implicit-rail` and (T4b) admits only `_unc` | ✅ |
| 4.7 | *"the free after a second reader"* | — | **not constructed, and I say why**: `planInteriorComponent` pushes an anchor for **every** user of every owned rail and `dagInsertPoint` post-dominates all of them, so no user can lie after `At`. (T4)'s docstring names cross-stream `F2-use-after-free` as an untouched pre-existing gap; I could not reach it from the compiler | — |

---

## ATTACK 5 — the single-block coincidence, again

| # | probe | ORACLE | **COMBINED** | right? |
|---|---|---|---|---|
| 5.1 | `x9_break_with_p2_discharged_rail` — a hoisted P2-discharged rail and a classical `break` **taken** at trip 3 of 4 | D `condition predates…` | **A, 0 dirty, 2 free, 2 verified, 0 unproven, 28 lines** | ✅ |

Read off the IR and the trace: `-O1` latch-folds the break, so the loop is **single-exit** (`%7`) and
`loopExitDischargePoint` returns it. The mint is in `entry` and the discharge in `%7` — **different
blocks**, so the loopconv round's *"protected only because mint and discharge share a block"* is
genuinely retired for this shape rather than re-established by accident. Three trips run, the rail is
discharged **exactly once**, on the break path, before `cqrt_ry_i32(h0,.9)`.

⚠ The multi-exit branch that `anchorForConsumer` guards with `return nullptr` still has **no
constructed customer**: my `x1` and `x2` are the **fifth and sixth** C shapes `-O1` renormalised into
one exit block (group1 F-5 counted four). It remains a prediction, not a test — and it is the one
place where the composition would produce a **silent** leak, because conjunct (3) never sees a
preheader-minted rail so nothing records an obligation and the backstop is blind. Direction: a leak,
not a dirty free; and `warnLiveRecordRotations` would still speak unless `recordIsExemptAt` clause 3
exempts it.

---

## ATTACK 6 — what the gate's blast-radius scan cannot see

The scan keyed on `left dirty > 0` **plus a trailing `cqrt_ry_<W>(h, θ)`**. Three shapes it does not name:

| # | probe | trailing gate / observable | ORACLE | D | **COMBINED** | right? |
|---|---|---|---|---|---|---|
| 6a | `x10_trailing_controlled_ry` | `cqrt_ry_<W>_controlled`, flag also measured | D `rotation arm shares the condition flag` | — | **D, same** | ✅ shape unreachable in that spelling |
| 6a′ | `x10b_trailing_controlled_ry_unmeasured_flag` | `cqrt_ry_i32_controlled(h6, h0, .9)` | D `condition predates…` | **A, 1 dirty + WARNING** | **A, 0 dirty, 3 free, 3 verified, stderr 0 B** | ✅ trace: `and_unc(h3,h0,1)`+`free(h3)` at 20–21, the controlled Ry at 24. **A composition cell** |
| 6b | `x11_trailing_angle_select` (`b ? .9 : .2` inside the call) | — | D `rotation angle under quantum control` | — | **D, same** | ✅ a quantum-derived angle, Rule 3 |
| 6b′ | `x11b_trailing_angle_select_ifelse` | the folded Ry-stem angle select: `ry(h0,.9)` + `ry_controlled(h6,h0,−.7)` | D `condition predates…` | **A, 1 dirty + TWO warnings** | **A, 0 dirty, 3 free, 3 verified, stderr 0 B** | ✅ discharge at 20–21, both angle-select gates at 22 and 24. **A composition cell** |
| 6c | `x12_measure_of_derived_not_register` | observable is `cq_measure(q*5)`, not `q` | D `condition predates…` | — | **A, 0 dirty, 3 free, 2 verified, 0 unproven** | ✅ |

**So the shapes the scan misses are covered by the CAPABILITY, not by the scan** — which is the right
outcome and also the reason the scan's silence must not be quoted as coverage.

---

## ATTACK 7 — the owner's loop program on the COMBINED binary

`example/grover/grover_oracle_uncompute.c` (untracked, read-only; I did not modify it). `clang -O1 -g`
stderr 0 bytes on both binaries.

**WALL 1 — identical on ORACLE `9bd01598` and COMBINED `07d93784`, so this session moved it not at all:**

```
example/grover/grover_oracle_uncompute.c:91:15: in function main i32 ():
cq controlled lowering: control flow inside a loop body under quantum control
```

Line 91 is `if (a >= 3){` — the **state-prep region**, which is quantum-controlled only because
`if (b0[i]) a -= 3;` on line 94 makes `a` tainted and loop-carried. Emitted by
`ControlDetect.cpp:642/:689`.

⚠ **This is NOT the wall Track L's `SCOPE_loop` recorded** (`cq taint escape: tainted value stored to
memory`, the bounded rail ARRAY, bd `xdu2`). The array wall is **gone**: the peel below lowers a rolled
`for (i) b0[i] = cq_theta(b0[i], 0.5);` at `opt` exit 0 with `cqrt_alloc_i1` + `cqrt_ry_i1` **inside a
rolled `!llvm.loop` body** and a 12-byte alloca of `i32` handles — the rail bank, which landed before
this session (`79bd7af9`, lab entry 009). Any brief still quoting taint-escape as the loop form's
first wall is stale.

**WALL 2, by hand-peeling exactly the construct wall 1 names** — `probes/owner_peel1b_uncond_prep.c`
is the owner's file with the `if (a >= 3)` guard removed (prep made unconditional) and everything
else, including `if (b0[i]) a -= 3;`, character-for-character:

```
<unknown>:0:0: in function main i32 ():
cq loop lowering: loop-carried tainted value crosses iterations
```

identical on ORACLE and COMBINED, from `LoopLowering.cpp:78`. ⚠ It carries **no `!dbg`** — a
source-location-less diagnostic on the owner's own program, which is the class Track P's F-P2 found
by sweep and the merge gate counts (`0 lost, 21 gained`). Worth one line to whoever owns bd `zujr`.

**And the control that isolates the attribution**: `probes/owner_peel1_no_inloop_value_arm.c` — the
owner's file with line 94 (`if (b0[i]) a -= 3;`) deleted instead — **ACCEPTS at `opt` exit 0 on both
binaries**. So both walls are the SAME construct seen from two stages: the in-loop **value arm** on a
`_Bool` rail read out of a rail-bank array. Walls 1 and 2 are not two problems; they are one, and it
is bd `ej5w` L-4 / bd `x5fp` L-2 — not bd `xdu2`.

---

## FINDINGS

### F-1 — **P1 (INSTRUMENT): Track C's (T4) VERIFIES the exact K:1 stream (T4f) was written to refuse, when the back edge is a `switch` case**

**Reproducing probes:** `$SES/review_r13_composition/probes/t4_switch_backedge_k1.ll` (RED),
`…/t4_br_backedge_k1_control.ll` (GREEN control, one terminator spelling apart).

**Measured**, gate worktree's `tools/free_pairing_check.py` at `07d937842bfb5135`'s tree:

```
$ python3 tools/free_pairing_check.py probes/t4_switch_backedge_k1.ll
free_pairing_check: 1 file(s), 1 rail mint(s) of which 1 left allocated,
  2 template rail mint(s) of which 0 left dirty,
  2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven      rc=0     <-- PASSES
$ python3 tools/free_pairing_check.py probes/t4_br_backedge_k1_control.ll
UNPROVEN U3-extern-rail @f line 24 [%r]: … (T4) loop-exit discharge refused: the block carrying the
  reversal (line 23) and the free can execute more than once — a rail minted ONCE and
  reversed-and-freed PER TRIP is the K:1 shape, and it is a use-after-free from the second trip on
  … 1 verified, 0 violation(s), 1 unproven                          rc=1     <-- refuses
```

In the RED module `%r = cq_template_and_i32_hl(%h, 1)` is minted **once** in `entry` and
`cq_template_and_i32_hl_unc(%r, %h, 1)` + `cqrt_free(%r)` run **once per trip** in a block whose back
edge is `switch i32 %x, label %out [ i32 0, label %body ]`. That is one forward gate against K
adjoints — a wrong unitary — and a use-after-free from the second trip on.

**Root cause, read in source (`tools/free_pairing_check.py`).** Blocks record their terminator as
`elif TERM_START_RE.match(ln): term = ln.strip()` — the **first line only** — and
`TERM_TARGETS_RE = label\s+%([-\w.$]+)` then finds targets in that one line. An LLVM textual `switch`
puts its case targets on the following lines, so `fn.succ` for a switch block holds **only the default
target**. `CrossStreamIndex.cyclic_blocks()` is a reachability closure over `fn.succ`, so
`stream_runs_at_most_once()` — (T4f), the conjunct whose docstring says it is *"what forbids the K:1
shape … that P2's own anchor walk exists to avoid"* — returns `True` for a block that plainly repeats.

**Direction, stated with its limit and both halves load-bearing.** The gap is **real on shipped code**:
of 1045 `ir-pass/test` fixtures that the COMBINED binary accepts, **1** has a `switch` in its lowered
IR (`lowering_classical_mux_phi_onereg_switch_nway.ll`), and on that exact module the checker's own
parser reports `succ['%entry'] = ['%merge']` and `preds['%arm1'] = preds['%arm2'] = []`. But **no
compiler-emitted module today is both switch-cyclic and a (T4) candidate** (a (T4) candidate needs a
cross-stream template mint freed in another stream), so this is a **latent** P1, not a live
miscompile. It is filed as P1 anyway because `free_pairing_check.py` is a **Rule-6 gate** — it runs
STRICT on every e2e slice and on both sides of all 382 `e2e-loop-twin-matrix` cells, it is the tree's
only witness for rail identity, and its soundness must not be conditioned on what the compiler happens
not to emit yet (Prime Directive). This is the same species as CLAUDE.md L10's *"an instrument's
failure mode is to report a pass"*, and (T4)'s own arm-kill matrix is exactly the discipline that
would have caught it had one arm been killed **by a switch-spelled mutant** rather than a `br`-spelled one.

**Second consequence of the same root cause, NOT demonstrated and stated as such.** `fn.preds` is
incomplete for the same reason, and `build_streams` extends a chain on
`fn.preds.get(nxt, []) == [chain[-1]]`. A block entered by an unconditional `br` from `A` **and** by a
switch case from `S` would therefore be LINEARIZED into `A`'s stream, and every straight-line
reduction in the file ((T1)/(T3)/(A1)/(A2)) would run over a join. I could **not** construct a false
VERIFY through that route — the damaging spellings need a value defined in the skipped path, which SSA
dominance forbids — so I report it as an unmeasured consequence, not as a finding.

**Fix shape (not designed here beyond the two options).** Either accumulate terminator lines to the
closing `]` so `switch` targets are recorded, **or** the conservative one-liner: any function
containing a `switch` answers `True` from `cyclic_blocks()` for every block (a (T4) refusal is
`UNPROVEN`, the safe direction). ⚠ Prefer the first: the second silently re-opens G-4 for any future
module that mixes a switch with a loop-exit discharge.

**RED-GREEN PAIR TO WRITE WITH THE FIX:** RED `t4_switch_backedge_k1.ll`, GREEN
`t4_br_backedge_k1_control.ll`, plus a third positive control (a module with a `switch` that is
**acyclic** and whose loop-exit discharge must still VERIFY) so the fix is not a blanket refusal that
passes the RED by giving up. Both files are in `$SES/review_r13_composition/probes/`.

**bd-fileable text (I filed nothing):**

> **P1 (instrument, latent): `free_pairing_check.py`'s (T4f) cyclicity test is defeated by a `switch`
> back edge, so the rule VERIFIES the K:1 loop-exit discharge it exists to refuse.** Found by the
> independent Rule-13 COMPOSITION round, session 2026-09-18, on the group-gate binary
> `07d937842bfb5135`. ROOT CAUSE: the block parser records `term = ln.strip()` — the FIRST LINE of a
> terminator — and `TERM_TARGETS_RE` matches `label %x` only in that line, so an LLVM textual
> `switch`'s case targets (on the following lines) never enter `fn.succ`/`fn.preds`.
> `CrossStreamIndex.cyclic_blocks()` is a closure over `fn.succ`, so `stream_runs_at_most_once()`
> returns True for a block that repeats. WITNESS `t4_switch_backedge_k1.ll`: a rail minted ONCE in
> `entry` and reversed-and-freed PER TRIP in a switch-latched block scores `2 verified, 0
> violation(s), 0 unproven`, rc=0. CONTROL `t4_br_backedge_k1_control.ll` (same module, back edge
> spelled `br i1`) is correctly refused with (T4f)'s own message, rc=1. REACHABILITY: `switch`
> survives cq-lowering — 1 of 1045 accepting `ir-pass/test` fixtures
> (`lowering_classical_mux_phi_onereg_switch_nway.ll`) has one in its lowered IR, and on that module
> the parser reports `succ['%entry']=['%merge']`, `preds['%arm1']=preds['%arm2']=[]`. No
> compiler-emitted module today is both switch-cyclic and a (T4) candidate, so this is latent; it is
> P1 because the checker is a Rule-6 gate run STRICT on every e2e slice and on both halves of all 382
> twin-matrix cells. SECOND CONSEQUENCE, unmeasured: `fn.preds` is incomplete too, and
> `build_streams` merges on a single-predecessor test, so a block entered by an uncond `br` and by a
> switch case would be linearized — no false VERIFY constructed (SSA dominance blocks the obvious
> spellings). FIX: accumulate terminator lines through the closing `]` (preferred), or make
> `cyclic_blocks()` conservative for any function containing a `switch`. RED `t4_switch_backedge_k1.ll`,
> GREEN `t4_br_backedge_k1_control.ll`, plus an acyclic-switch positive control so the fix is not a
> blanket refusal. Probes in `$SES/review_r13_composition/probes/`. Cross-reference bd `j31l` / Track
> C's (T4), bd `21re`, bd `az1h` (the arm-kill lesson: the matrix killed eight arms with `br`-spelled
> mutants only).

### F-2 — **P3 (instrument conservatism, composition-visible): (T4g)'s "after the reversal" clause is STREAM-LOCAL, so a trailing gate `-O1` puts in a SUCCESSOR block turns a proven discharge into UNPROVEN**

`loop_exit_discharge`'s (T4g) accepts a write to a forward operand only when
`wsid == self.stream_id and wpos > rev_pos` — the **free's own** stream. Measured: `x1` and `x2` both
report `2 template rail mint(s) of which 0 left dirty` **and** `1 verified, 0 violation(s), 1
unproven`, **rc=1**, with the refusal naming `cqrt_ry_i32(%h, 0.9)` as *"neither before the mint in
the mint's own stream nor after the reversal in this one"* — although that gate is in a block that is
a **successor** of the free's block and therefore strictly after the reversal on every path. `dD1`,
the same circuit with the gate in the reversal's own block, reports `0 unproven`, rc=0.

Direction: **safe** (UNPROVEN, never VERIFIED). Cost: an e2e slice of the `x1`/`x2` shape could not be
registered without `--allow-unproven` — the flag G-4 has just finished driving from 5 back to 4 — so
the exception G-4 reports as *"gone, not widened"* is gone for the shipped slice and not for the
shape. One sentence at `loop_exit_discharge`'s "what (T4) does NOT prove" list, naming successor-block
operand writes, is what is owed; widening it to dominated successors is a real increment with its own
Rule-13 obligation.

### F-3 — **P3 (record scoping): the gate's G-2 is true of `dD1` and reads as a statement about its neighbourhood, which is false**

`gate/FILINGS.md` G-2: *"F-1's `dD1` over-accept does not exist on the merged tree."* True, and I
re-measured it. But `x6_rolled_postloop_reader_after_rotation.c` is `dD1` **plus one line** — a
post-loop read of the hoisted rail placed AFTER the trailing `q = cq_theta(q, 0.9)` — and it goes
**DECLINE on ORACLE `9bd01598` and on G1-alone `df2445fc` → ACCEPT with `1 template rail left dirty`
on D-alone `5ee9d144` AND on COMBINED `07d93784`, md5-identical (`8393c3cd…`)**. `x7`, the same
program with that line moved before the rotation, discharges (`0 dirty`). So **the composition does
not close the neighbourhood; it closes `dD1`.**

⚠ **The other half must be quoted with it, and it is why this is P3 and not P1.** `x6` is **not a
miscompile**. `planInteriorComponent` takes the safe direction (clause (d)'s borrowed-parent scan
abandons the component once `dagInsertPoint` lands past the rotation), and
`RotationLowering::recordIsExemptAt` **clause 3** deliberately exempts a record with an OBSERVED use
after the gate: the rail here IS the user's live value (`u = t*3`, measured), so the dephasing is the
**user's own circuit** — the owner's bd `lyyf` ruling class, which is *reported and lowered*, and the
compiler cannot uncompute before a last use. What is owed is one sentence in the record — *"the
composition discharges `dD1`"*, never *"the class is closed"* — beside the existing instruction not to
close bd `s82e`.

### F-4 — **P2 (over-decline candidate, pre-existing, and it costs the composition its only nest customer)**

`x14_nested_loop_rail_hoisted_past_both.c` — `for (i) for (j) if (t == 1) r = cq_theta(r, 0.9);` with
`t = q & 1` hoisted — **declines on ORACLE and on COMBINED alike** at `cq controlled lowering:
condition predates a non-diagonal gate under quantum control`, while the single-loop spelling of the
same circuit (`dD1`) accepts and discharges. Per the owner's 2026-09-11 ruling an over-decline of a
valid circuit is a defect to file, and the pre-existing-ness makes it a candidate rather than a
regression (CLAUDE.md's `d4_noRailRegion.c` precedent).

⚠ **The composition-specific point is what it does to the evidence for P2.** `anchorForConsumer`'s
**OUTERMOST** walk — the choice its own comment calls load-bearing, justified by the depth-3 nest
`b1` — gains **no C-reachable customer through Track D's door**, because the nested spelling of D's
shape declines. So the OUTERMOST choice is today pinned only by group1's `b1`/`b2` probes and by no
shipped fixture through the newly-opened door. Worth one line on bd `tu9q`'s follow-on list.

---

## What HELD, stated positively because a clearance that lists only failures is not a measurement

* **`dD1`/`dD4` multiset identity reproduced at the PASS-2 hash** (the gate measured it at
  `96d74fe6`): 22 == 22, multiset identical, sole divergence one `cqrt_free(h4)` position on a
  disjoint rail.
* **All 14 of Track D's movers are STRICT-clean on the COMBINED binary with (T4)** — 14/14 exit 0,
  0 warning lines, rc=0, 0 dirty, 0 unproven, 0 violations.
* **group1's F-1 (`g8`) is closed** on `df2445fc` and on `07d93784`; its cross-function spelling
  (`x16`) declines too, with the diagnostic naming the right function — one slice of bd `1yeu` closed.
* **Six composition cells that neither track produces alone**: `dD1`, `dD5` (the gate's), plus
  `x3c`, `x10b`, `x11b`, `x15` (mine) — each `1 dirty` + warning on D-alone, `0 dirty` + stderr 0
  bytes on COMBINED, each with a stream I read gate by gate.
* **The dangerous placements refuse.** A rotated parent in the body (`x3`) declines on all four
  binaries; the g8 door and D's admission are structurally disjoint (`x8`); a taken `break` discharges
  exactly once on the break path (`x9`); two regions over one rail discharge it once (`x13`).
* **L1 is clean for Group 1 in both entry points**, read in source: the record at `:817`/`:1296` and
  the backstop at `:953`/`:1362` are both after the `repropagateControlMerges` fixpoint at
  `:616`, and P1/P2 run inside `uncompute` at the tail.

---

## What I did NOT attack

I built nothing and ran **no** suite, corpus sweep, injection matrix, twin matrix, duplicate-body scan,
`negative_vacuity_check.py` or `cq-opt-equivalence-full`, so I have **no tree-wide number** and no
opinion on whether any shipped fixture, slice or golden is a customer of F-1 beyond the 1045-fixture
`switch`-in-lowered-IR count I did run. I did **not** measure the **P0+P3** binary at all — it is not
in the composition and group1 §C already scopes it. I did not attack: irreducible cycles or
multi-latch loops against `markedHeaderOf`'s null key; the 512-block budget's decline path in
`anyInstructionInGap`; `EmitInverse` / `cq_invert`; `reverseTerminalGroup`'s mirrored multiplicity
test (expected never to fire, and I constructed nothing that reaches it — neither did the two prior
rounds); the 4.5 `switch` and depth-2 nest control paths, which keep their unconditional declines;
`-O2`/`-O3`; the 7.5 QRAM and 7.6 tape surfaces. I did **not** close D's round-1-taint POSITIONAL
residual — I built one composed probe for it (`x15`) and it lowered correctly, which is evidence and
not a proof, so `IMPL_D2b` R-7's *"probably empty, never closed"* stands unchanged. I did not construct
a false VERIFY through F-1's `preds` half. And I did not attack the **F × P-style cross-GROUP**
composition — Track V's instrument axis and this group are disjoint in file surface, but *a
composition is not cleared by clearing its parts*, and I cleared this one by construction and
measurement, which is precisely what Rule 2 calls **necessary and not sufficient**.
