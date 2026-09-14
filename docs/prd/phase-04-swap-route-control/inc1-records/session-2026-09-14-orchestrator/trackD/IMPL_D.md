# Track D — IMPLEMENTATION record: the STALE-READER fence (bd `3d8q`, P1)

Worktree `/Users/sorenwilkening/Desktop/CQ_3d8q`, branch `stale-reader-fence`, off `main` `607b6fe4`.
Gate lines and binary hashes: `GATES.md` (same directory). Probes: `probes/`.

---

## 1. What shipped, in one paragraph

`docs/frontend.md` §3.2 states the LINEAR RULE — *"a rotation consumes the old name … a read of the
pre-gate value that the compiler cannot prove executes before the gate is refused — loudly, lowering
nothing"* — and, since 2026-09-05, states this exact hole in the same breath: *"the enforcement is
per-site and is not yet complete … replacing the arithmetic with a MEASUREMENT of the same stale name
… is accepted … `declineStaleRecordOps` covers tainted PURE OPS only … Do not rely on the compiler to
catch this spelling."* That paragraph is the specification of this increment. The fence now asks the
same rule, of the same walker, for the two reader families `inLowerOpsScope` never covered — a
`@cq_theta_<sfx>` (**arg-0 only**, Rule 3) and a `@cq_measure_<sfx>` call.

**Two halves, two slots, and the split is the whole design** (see §4 — it was not the first design, it
was the fourth, and each move was forced by a measurement):

| half | function | slot | why exactly there |
|---|---|---|---|
| ANALYSIS (pure, no diagnostic) | `recordStaleQuantumReaders` | beside `declineStaleRecordOps`, **before** `lowerLoops` / `MergePhiPeel` / control detection | the fence's premise is that an SSA NAME denotes a basis RECORD — true only of names the USER wrote. Three later stages rewrite a wire-TRACKING name into a wire-BASE name. |
| ANALYSIS, delta-scoped | `recordStaleQuantumReaders(M, taint, &live)` | inside `adjudicateTaintDelta` | every taint-GROWTH event owes the L1 question; scoping it to the values that JUST became tainted pays it without re-asking on rewritten IR. |
| DIAGNOSTIC | `declineRecordedStaleQuantumReaders` | the last slot before `lowerRotations` | this is a BACKSTOP, never a preemptor. `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`), so "last" is literally "every other owner goes first". |

New loud string, mirrored character-for-character by 7 negative fixtures:

```
cq opcode lowering: rotation/measure operand predates a non-diagonal gate
```

It keeps the `cq opcode lowering:` stage prefix (the decision is `OpcodeLowering`'s, one operand policy
wider — the project's convention, spelled out at `diagnosePreLoopCommitStale`) and adds
`rotation/measure` so the group corpus sweep can attribute movers BY STRING (PROTOCOL S1) and so a
negative fixture can pin the NEW predicate rather than somebody else's. It deliberately does not begin
with `cq_measure_`, which the shared `corpus.sh` tag regex renders as an empty `D:` (PROTOCOL S3).

## 2. Files touched

| file | change |
|---|---|
| `ir-pass/src/OpcodeLowering.cpp` | `diagnoseStaleQuantumReader`, `staleReaderRecordOperand`, `recordStaleQuantumReaders`, `declineRecordedStaleQuantumReaders`. ⚠ `inLowerOpsScope`, `checkStaleOp` and `declineStaleRecordOps` are **byte-unchanged in behaviour** — the reader policy is a separate stage, not a widening of theirs. |
| `ir-pass/include/OpcodeLowering.h` | the two declarations + the slot contract |
| `ir-pass/src/WireWalk.cpp`, `ir-pass/include/WireWalk.h` | `RequireEmitDominance` (default `true`) threaded through `gateIsHarmless` → `walkNonDiagonalWireGates` → both public faces. **Every pre-existing caller passes `true` and is byte-unchanged.** |
| `ir-pass/include/TaintPropagation.h` | `TaintSet::StaleQuantumReaders` (`WeakTrackingVH`) + the measured argument for the early/late split |
| `ir-pass/src/TaintPropagation.cpp` | the delta-scoped call in `adjudicateTaintDelta` |
| `ir-pass/src/CQLoweringPass.cpp` | the two call sites, in BOTH entry points |
| 9 new fixtures, 5 edited (§8) | |

## 3. The two mechanisms, and how each fails silently if removed

**(i) The reader is its own gate — `Covered`.** `c = cq_theta(a, .9)` is an in-place Ry on the very
rail it reads, so a walk seeded at `a` finds `c` among `a`'s users. Without the exemption EVERY
well-formed chained rotation in the tree declines against itself. It is spelled with the shipped
`Covered` parameter, which skips the gate AS EVIDENCE while still walking THROUGH it — the per-entry
exemption bit of **L4**, never a boolean short-circuit, so nothing BEHIND the reader rides on the
exemption. Passed only for a `cq_theta_` reader: a measure is not a gate the walk can return, and
claiming it is "already ruled on" would be an untrue statement in the code.

**(ii) `RequireEmitDominance=false` — the policy bit.** The shipped position-aware proof refuses
outright unless `EmitPoint` DOMINATES the candidate gate. That precondition is **not** what carries the
soundness — leg 1 (`!isPotentiallyReachable(T, EmitPoint)`) and leg 2 (the record-barrier walk) each
prove "no instance of `T` runs between the record's last establishment and this execution of
`EmitPoint`" on their own, and leg 2's written proof never cites dominance. It is a conservative gate,
and it is cheap for the pure-op policy. It is **structurally wrong for the reader family**, which
routinely cannot satisfy it while being perfectly well formed:

* a rotation reader that IS a branch arm — `%rt` in `armt` and `%rf` in `armf` are siblings on one
  rail that **never both run**; neither can stale the other and neither dominates the other. **14
  shipped Rule-13-cleared fixtures flip without leg 1** (the whole drbq in-place controlled-Ry
  if/else family). Pinned: `lowering_stale_reader_exclusive_arms_accept.ll`.
* a measurement AFTER a loop whose body holds the gate — the merge φ re-establishes the record every
  trip, so the exit read is fresh, but the exit block dominates nothing in the body. **12 shipped
  in-loop fixtures flip without leg 2.** Pinned: `lowering_stale_reader_postloop_measure_accept.ll`.

⚠ **The pure-op policy keeps the precondition, deliberately.** Dropping it there is a strict
ACCEPT-direction widening of a fence that has shipped and been cleared since Phase 5 — the one
direction this project never takes casually — and `lowering_reject_stale_record_exclusive_arms.ll` is a
pinned, deliberate over-decline of exactly that shape whose header asked for "a future refinement …
with a path-exclusivity argument". That file now carries a cross-reference and a RETIREMENT TRIGGER; it
is **not** flipped here. **L3 answered in the narrow direction: the other predicate names the same
instruction, and the answer is "leave it".**

## 4. The design is the measurement — 116 → 0 was FIVE findings, not tuning

Every step below was a `lit ir-pass/test` run on its own binary (`GATES.md` has the hashes).

| binary | FAIL | what the failures said |
|---|---|---|
| `aeac6894` reader policy folded into the early sweep | **116** (25 ACCEPT→DECLINE, 91 reject-string) | — |
| `979f93eb` + a local mutual-exclusion filter | 102 | **F-1**: mutually-exclusive ARM siblings are not stale. A local filter is a second spelling of one relation (Rule 14). |
| `08ca9cc0` + `RequireEmitDominance` in the ONE walker | 74 | **F-2**: the in-loop post-loop measure needs leg 2, which the dominance precondition hides. One relation, one policy bit. |
| `99c947d7` + readers scoped out of the post-lift re-sweep | 72 | **F-3**: `liftOneRegisterMergePhi` RAUWs a wire-TRACKING φ to a wire BASE; a reader adjudicated against the base reads as stale for a fact about the REWRITE. |
| `82d76e6f` reader half moved to its own LATE stage | 16 | **F-4a**: at the early slot the fence PREEMPTED 68 shipped negative fixtures — the condition-wire dispositions, `ArmClassify` R6, `staleRailRecordRead`. 68 fences pinned by nothing (Rule 12 fixture-hygiene defect (c)). |
| `08bd9401` analysis EARLY, diagnostic DEFERRED | 6 | **F-4b**: at the late slot the LOOP-RAIL COLLAPSE has already replaced the per-trip barrier φ with the loop-invariant preheader mint, and 9 in-loop ACCEPTS flip. Neither slot works for both halves; the analysis and the diagnostic must be split. |
| `8e508cac` emit moved to the last pre-`lowerRotations` slot | 4 | 2 more owners (`declineClassicalMuxes`, `declineLiftedStaleRecordOps`) claim first. |
| **`7fe2bcbf`** + the delta-scoped round-2 re-ask, 5 fixtures adjudicated | **0** (1935 pass, 1 XFAIL) | **F-5**: round-1 taint cannot see a peeled mux out-rail or a 6.5/4.5 `%out`; `S03_stale_mux_sibling.c` — a NAMED §2 customer — still accepted, and `control_swap_select_cmp_round2_window_accept.ll` turned out to be a genuine member. |

**The standing lesson, offered for the reviewer to attack:** *a fence whose premise is "this SSA name
denotes a record" must be ASKED on the IR the user wrote and ANSWERED where every other owner has
already spoken.* Three separate compiler rewrites (the rail-φ collapse, the merge peel, the
one-register lift) each turn a wire-TRACKING name into a wire-BASE name; asked after any of them the
fence declines well-formed programs. That is the same shape as **L1** but it is not L1 — L1 is about
taint GROWING under a stage; this is about NAMES being REWRITTEN under a stage.

## 5. The L-question answers the brief asks for

**L1 (a stage that runs ONCE has a round-2-FALSE premise).** The analysis runs at the early slot with
ROUND-1 taint, and re-runs DELTA-SCOPED inside `adjudicateTaintDelta` — which is called after both
`MergePhiPeel` sites and on `repropagateControlMerges`' `reseed`, i.e. at every taint-GROWTH event and
at the round-2 fixpoint. The diagnostic is emitted after the fixpoint. A value that becomes tainted
only in round 2 (a 6.5/4.5 merge `%out`, a peeled mux rail) IS adjudicated — measured on
`S03_stale_mux_sibling.c` and on `control_swap_select_cmp_round2_window_accept.ll`, both of which
accepted until the delta re-ask existed. ⚠ A FULL re-sweep at that slot is **not** the fix: `lowerLoops`
has already run there, so it reopens F-4b. The delta scope is what makes the L1 payment safe — the
values in the delta are ones the pass MANUFACTURED or freshly re-seeded, never a name an earlier
rewrite collapsed.

**L2 (when you WIDEN a set, ask what OTHER set was computed over the same closure).** The set widened
is the SWEPT-INSTRUCTION set, not a gate set — the walker's closure, exemptions and harmlessness proof
are untouched. The other sets computed over the same closure are `declineStaleRecordOps`'
(pure ops — unchanged, same closure, same `Exempt`, same `gateIsHarmless` with the precondition ON) and
the condition-wire fences' (`ArmClassify`, `SelectClassify`, `SwitchClassify`, `SwitchArmProve`,
`RegionTreeDetect` — all still pass `RequireEmitDominance=true`, byte-unchanged). The one shared thing
that DID change is `gateIsHarmless`' signature, and its default keeps every existing caller identical.

**L3 (when a set is NARROWED, ask what OTHER predicate names the same instruction — and the answer is
not always "narrow it too").** Three predicates name the instructions this fence now sweeps:
* `LoopLowering::staleRailRecordRead` asks the SAME question over the loop-collapsed RAIL CHAIN rather
  than over the wire. **Not narrowed, not touched** — it sees in-loop reads this walk cannot prove, and
  it runs earlier, so it keeps its (more precise) message;
* `ArmClassify` R6 asks it of an in-place rotation arm under quantum control. **Not touched**, and it
  is deliberately STRICTER than the pass-wide guard;
* `RotationLowering`'s `Chained` decision names the same `cq_theta` calls but asks "is this in place?",
  a different question; a `DS_Error` exits `opt` before it runs anyway.
And the fourth, the one this increment could have widened and did not:
`gateIsHarmless`' dominance precondition for the PURE-op policy (see §3).

**L4 (a wire question must be a gate SET, not a BOOLEAN over a return-first walker).** The exemption is
carried as a per-entry bit (`Covered`), which the walker skips as evidence while continuing THROUGH it.
An earlier draft of this increment used a local post-filter over the enumerating face; it was retired
in favour of the shipped mechanism precisely so there is one relation with one spelling.

## 6. Reproducer table — ORACLE vs SUBJECT, every probe the brief §2 names

ORACLE = `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
`f7b65d8ccd7bc472…` (verified by `shasum -a 256` before use). SUBJECT = `7fe2bcbf…`.
Command: `probes/measure.sh <tag> <build-dir> probes/src/*.c` (PROTOCOL's per-probe pipeline; stage 1
generated ONCE and fed to both binaries). `D` = the new stale-reader string unless noted.

### 6a — the population (§2 of the brief): every row must move ACCEPT → DECLINE

| probe | ORACLE | SUBJECT | note |
|---|---|---|---|
| `f1_two_siblings_nocontrol.c` | **A**, 6 trace lines | **D** | THE reproducer. |
| `f1w_chain.c` | **A**, 6 | **D** | a chain whose MIDDLE name is measured. |
| `g1_chain_measure_both.c` | **A**, 6 | **D** | CLAUDE.md's own 8h7d.5 F-3 shape, out of loop. |
| `g2_measure_parent.c` | **A**, 5 | **D** | ⚠ the brief §3 lists this as a MUST-NOT-MOVE. It is **not** — see §6c. |
| `f2_two_siblings_template_nocontrol.c` | **A**, 7 | **D** | siblings on a TEMPLATE parent (needs the F-1b-1 ancestry crossing). |
| `e6_sibling_after_branch.c` | **A**, 10 | **D** | `cq_theta` reader; listed by `review_1b_r2.md` §F-1b2-1's boundary table as a defect ACCEPT. |
| `l1_inloop_sibling_invariant.c` | **A**, 24 | **D** | the IN-LOOP member (brief §4). |
| `l1u_unrolled.c` | D `condition predates…` | D `condition predates…` | its hand-unrolled twin — **unchanged**, still owned by the condition-wire fence. See §6d. |
| `S04_sibling_plain_oracle.c` (bd `b6ap` F-B6R2-2) | **A**, 8 | **D** | the NO-PEEL control. |
| `S03_stale_mux_sibling.c` (bd `b6ap` F-B6R2-2) | **A**, 35 | **D** | the PEELED mux out-rail. ⚠ needed the round-2 delta re-ask; it still accepted at `8e508cac`. |
| `G8_sibling_after.c` (integration I-3) | **A**, 22 | **D** | |
| `p3d8q_sibling.c` (Track M) | **A**, 31 | **D** | the φ spelling. |
| `r15_p3d8q_sibling.c` (Track M r1) | **A**, 31 | **D** | |
| `p3d8q_sibling_rail.c` (Track M) | **A**, 30 | **D** | the rail spelling — accepted on the PRE-session oracle, i.e. pre-existing. |

**14 of 14 moved.** Every DECLINE carries the new string.

### 6b — the must-not-move table (§3 of the brief)

| probe | ORACLE | SUBJECT | |
|---|---|---|---|
| `f1w2_chain_measure_twice.c` — the well-formed chain, tip measured twice | A, 6 | **A, 6** | the discriminating accept |
| `a10_grandparent_inplace.c` | A, 10 | **A, 10** | |
| `oc1_two_templates.c` | A, 11 | **A, 11** | two distinct template rails |
| `oc3_template_parent_post_chain.c` | A, 10 | **A, 10** | a proper chain on a template parent |
| `m3_measure_after_straightline.c` | A, 4 | **A, 4** | |
| `l2_grover_loop.c` | A, 18 | **A, 18** | the rolled chain |
| `l3_perbit_loop.c` | A, 39 | **A, 39** | |
| `trackM_s04.c` — the shipped S† rail-leaf accept | A, 16 | **A, 16** | |
| `p07_chained_after.c` / `control_phase_kickback_rail_post_ry.ll` (`ProvenPostRegion`) | A | **A** | named explicitly by bd `3d8q`; the `.ll` is green in `ir-pass-lit`, the `.c` is an ACCEPT row in the corpus sweep |
| `g3_pureop_after_theta.c` | D `operand predates…` | D, **same string** | the pure-op owner is untouched |
| `g4_sibling_measure_only_c.c` | D `operand predates…` | D, **same string** | ditto |
| `l1w_wellformed_chain.c` | D `taint escape` | D, same string | |
| `m4_measure_before_uncond.c` | D `condition measured before…` | D, same string | |
| `a02_cmp_parent.c` | D `condition predates…` | D, **same string** | ⚠ at the EARLY-emit design this moved to my string; the deferral is what keeps the condition-wire fence's message. |

**Every accept's trace-line count is identical**, not merely "still accepts".

### 6c — ⚠ ONE DEVIATION FROM THE BRIEF, stated loudly

Brief §3 lists **`g2_measure_parent` as a must-not-move ACCEPT** ("`cq_measure(b)` on a well-formed
chain stays ACCEPT"). **I moved it to DECLINE, deliberately.** The brief's attribution is a
transcription slip from bd `3d8q`'s wording: `review_1b_r2.md` §F-1b2-1's own boundary table lists
`g2_measure_parent.c` in the **DEFECT** row — *"`f1`, `g1`, `g2_measure_parent.c` | a `cq_measure`
sink | **ACCEPT**"* — i.e. among the accepts that are wrong. The program is
`q=cq_theta(0,.3); a=cq_theta(q,.5); return cq_measure(q)+a;`: `a` consumed the name `q`, so
`cq_measure(q)` is a read of the pre-gate value, and the PURE-op spelling of the identical program
(`int d=q+1;`) has declined since Phase 5. What the bd text means by "stays ACCEPT (ancestry exempt)"
is measuring the chain's **TIP** — which is `f1w2_chain_measure_twice.c`, and it does stay ACCEPT.
If the orchestrator or owner disagrees, this is a one-line revert of the reader family's `cq_measure_`
half; say so and I will.

### 6d — the l1 / l1u rolled≠unrolled split (brief §4) is CLOSED, in the direction the reviewer predicted

bd `3d8q` F-1b2-2 recorded: rolled `l1` ACCEPTS while the hand-unrolled `l1u` DECLINES, and *"fixing
F-1b2-1 closes both spellings"*. Measured: `l1` now **DECLINES** (the new string) and `l1u` still
DECLINES (`condition predates a non-diagonal gate`, unchanged). **Both spellings decline; the
disposition split is gone.** They decline with DIFFERENT strings, which is correct and is the
reviewer's own analysis: in `l1u` the CONDITION is stale (copies 2 and 3 read a `t` that copy 1's `c`
already moved) and the condition-wire fence owns it; in `l1` the condition is genuinely fresh per trip
and what is wrong is `c = cq_theta(t,0.9)` reading the stale `t` — which is this fence.

## 7. Instrument notes

* `vacuity.py` over the 5 accept fixtures reports **0 named negatives checked**. Per PROTOCOL S3 a
  harness that reports nothing is a HOLE, not a pass — its pattern is `<PREFIX>-NOT: … (i32 %handle)`
  and none of these fixtures' negatives name a handle (they name SYMBOLS). The property it would have
  checked is instead covered by the injection matrix, which is a stronger instrument here; recorded so
  nobody reads "0 VACUOUS" as clearance.
* One fixture-hygiene defect was hit and is worth the warning: a **prose sentence containing the
  directive token** made the converted fixture fail (FileCheck reads comments — bd `qta2`'s family).
  The preserved old directive blocks are neutered to `[check]` / `[ord]` forms for the same reason.

## 8. Fixture table

### New (9)

| file | verdict | what it pins |
|---|---|---|
| `lowering_reject_stale_reader_sibling_theta.ll` | DECLINE | THE reproducer: two sibling Ry on one rail, both measured. Byte-identical stream to the accept twin on the pre-fix compiler. |
| `lowering_reject_stale_reader_measure_parent.ll` | DECLINE | the `cq_measure` half, and the PARITY with `lowering_reject_stale_record_add.ll` (the pure-op spelling of the identical program). |
| `lowering_reject_stale_reader_chain_measure_mid.ll` | DECLINE | CLAUDE.md's own 8h7d.5 F-3 shape OUT of loop. |
| `lowering_reject_stale_reader_template_parent.ll` | DECLINE | the sibling pair on a TEMPLATE parent — also pins that the reader policy passes `&taint` (the F-1b-1 ancestry crossing). |
| `lowering_reject_stale_reader_mux_out_rail.ll` | DECLINE | the `MergePhiPeel` / mux out-rail customer (`S04`/`S03`, bd `b6ap` F-B6R2-2). |
| `lowering_reject_stale_reader_merge_phi_prep.ll` | DECLINE | the Track-M customer (`p3d8q_sibling.c`, `r15_*`): the seed is a state-prep's merge φ. |
| `lowering_stale_reader_chain_accept.ll` | ACCEPT | the DISCRIMINATING accept — the well-formed chain with the tip measured twice; byte-identical to what the reproducer used to emit. |
| `lowering_stale_reader_exclusive_arms_accept.ll` | ACCEPT | leg 1 / `RequireEmitDominance=false`. |
| `lowering_stale_reader_postloop_measure_accept.ll` | ACCEPT | leg 2 / the record barrier. |

⚠ **RED-GREEN, measured rather than asserted (Rule 12).** All **6** new negative fixtures are rows in
the ORACLE-vs-SUBJECT corpus sweep with `A:<md5>` on the ORACLE and the new decline string on the
SUBJECT — i.e. each one demonstrably ACCEPTED on the pre-fix compiler and demonstrably declines now.
That is the "watch it fail first" step, taken on a frozen binary instead of on a reverted build.

### Edited (5) — each decided in writing, in the file

| file | was | now | why |
|---|---|---|---|
| `control_inplace_ry_stateprep_fcmp_oeq_twin.ll` | ACCEPT | ACCEPT | ONE OPERAND: `cq_measure(%t)` → `cq_measure(%rt)`. `%rt` consumed `%t`. **Emitted stream byte-identical**, every directive unchanged; the fp-anchor identity witness is untouched. |
| `control_phase_kickback_mixed_onward_deadgate_leak_control.ll` | ACCEPT | ACCEPT | ONE OPERAND: `cq_measure(%3)` → `cq_measure(%20)` (the last trip's own result). The gate's arg-0 is still the loop-invariant name, so there is still no header φ, the rail is still unclaimed, **stream byte-identical**, all 5 prefixes unchanged. |
| `lowering_bitcast_measure_after_rerotate.ll` | ACCEPT | **DECLINE** | its header WAS the specification of the bug (*"never a measure"*) and is `docs/frontend.md` §3.2's own `mark` example. The bitcast-fold subject survives in `lowering_bitcast_i32_identity.ll` + `lowering_bitcast_chained_theta_before.ll` (checked, both green). Retirement trigger written. |
| `control_phase_kickback_reject_preloop_commit_stale.ll` | DECLINE | **DECLINE, new owner** | module, verdict and anti-miscompile `-NOT`s unchanged; only the message moved to the earlier and more accurate owner. ⚠ It was the SOLE positive pin of `diagnosePreLoopCommitStale`; that tripwire is untouched and now defence-in-depth. Recorded, with a plausibility argument explicitly labelled as NOT a measurement. |
| `control_swap_select_cmp_round2_window_accept.ll` | ACCEPT | **DECLINE** | genuine P1 member (`b3 = cq_theta(x,.9)` names `Ry(.9)\|x>` while the register holds `Ry(.9)Ry(.25)\|x>`). Old header + old directive blocks preserved verbatim. ⚠ Loses ONE Track-A.1 cell (compare path, sibling present AND accepted); measured that the chained rewrite does not restore it. |

## 7b. The `!dbg` ANCHOR — checked by measurement, because a deferred diagnostic is exactly where it can be lost

Raised by the orchestrator from **Track P's lesson**: a diagnostic that loses its `!dbg` and reports
`<unknown>:0:0` is INVISIBLE to every gate this project runs except a full-stderr hash — it shipped
past a green 1946-fixture `ir-pass-lit`, a 0-MISSED injection matrix and a byte-identical 288-cell
family, because a lit fixture pins the STRING, not the line:col.

⚠ **This fence is the shape most exposed to that defect in the whole tree**, and the reason is its own
design: the diagnostic is DEFERRED. `recordStaleQuantumReaders` runs early and
`declineRecordedStaleQuantumReaders` emits hundreds of lines later, so the anchor has to survive the
gap. If the record had kept a BLOCK, a region, or anything the emitters rewrite, the location would
have silently degraded to `<unknown>:0:0` and nothing here would have failed.

**The anchor is the READER INSTRUCTION ITSELF** — `diagnoseStaleQuantumReader(I)` passes
`I->getDebugLoc()`, the same anchor the shipped `diagnoseStaleRecord` uses — and the record is a
`WeakTrackingVH` **to that instruction**, so what is emitted late is the very `Instruction *` whose
`!dbg` was read.

**MEASURED on `-g`-compiled plain C** (the probe pipeline compiles with `-O1 -g`; `probes/SUBJECT/*.err`):

| probe | reported location | what that column is |
|---|---|---|
| `f1_two_siblings_nocontrol.c` | `:2:69` | `cq_theta(q,0.9)` — the sibling reader `%c` |
| `g2_measure_parent.c` | `:2:70` | `cq_measure(q)` |
| `g1_chain_measure_both.c` | `:2:96` | `cq_measure(a)` — the MID-chain read, not the tip |
| `l1_inloop_sibling_invariant.c` | `:3:31` | `cq_theta(t,0.5)` in the loop BODY (`b`, which is the stale one at trip 2) |
| `S03_stale_mux_sibling.c` | `:11:12` | `cq_theta(m,0.6)` — the second sibling on the mux rail |
| `p3d8q_sibling.c` | `:14:29` | `cq_measure(b1)` — the stale measure, after `c` consumed `b1` |
| `G8_sibling_after.c` | `:8:15` | `cq_theta(t,0.9)` — the sibling |

Not one `<unknown>:0:0`, and every column lands on the offending READER rather than on the staling
gate or the enclosing statement — including through the DEFERRAL, through the round-2 delta path
(`S03`), and inside a loop body (`l1`). For comparison on the same corpus, the shipped pure-op twin
reports `g3_pureop_after_theta.c:2:70` and the condition-wire fence `a02_cmp_parent.c:2:61`, so the new
string is no worse located than its neighbours.

⚠ **The `<unknown>:0:0` you will see on the `.ll` FIXTURES is not this defect** — those modules carry
no `!dbg` at all, and every other diagnostic reports the same on them. Do not "fix" a fixture by
chasing it; check a `-g` `.c` probe, which is what this table is.

## 8b. Corpus sweep — ORACLE vs SUBJECT

`probes/corpus_d.sh` → `probes/corpus_7fe2bcbfb6c97126.txt`. Derived from the shared
`review_integration_probes/corpus.sh` with two deliberate changes:
* every DECLINE row also carries an **md5 of the FULL stderr**, because PROTOCOL S3 records that the
  shared tag regex renders a whole diagnostic family as an empty `D:` and hides a decline→decline
  string change;
* the corpus **adds `tests/e2e/*.c`**. This increment widens a DECLINE, and the e2e slice sources are
  exactly the population a lit-only sweep cannot see. An implementer may not run `^e2e-`; reading the
  same `.c` files through the per-probe pipeline is not that gate and does not replace it — but it is
  the layer where a golden-breaking decline would first appear, and an `A:<md5>|A:<md5>` row is
  byte-identical LOWERED IR on both binaries, hence an identical trace.

Corpus: every `ir-pass/test/*.ll`, every `tests/e2e/*.c`, and the PROTOCOL-named session probe dirs
plus this track's. **Attribution: every mover's SUBJECT string is this track's own**
`rotation/measure operand predates a non-diagonal gate` — there is no unattributable mover, and no
mover outside the shapes the brief §7 names (sibling-theta / sibling-measure / mux-out-rail / prep-φ).
**Zero `e2e/` movers.** The detailed list is §8c.

## 8c. Corpus movers — all 43, all attributable, ZERO in `e2e/`

`probes/corpus_7fe2bcbfb6c97126.txt`: **3093 rows** (1937 `lit/` + 369 `e2e/` + 787 probe files;
1 `CLANGERR`, `review_integration_probes/U0_uncommented.c`, which does not compile under the plain
recipe on EITHER binary). SUBJECT: 1749 accept / 1343 decline.

**43 movers. Every one is ACCEPT → DECLINE with THIS TRACK'S string** (`rotation/measure operand
predates a non-diagonal gate`), except one DECLINE → DECLINE ownership move
(`control_phase_kickback_reject_preloop_commit_stale.ll`, §8). There is no unattributable mover and
none outside the shapes the brief §7 names.

| group | count | what |
|---|---|---|
| new negative fixtures | 6 | RED-GREEN: each ACCEPTED on the ORACLE, declines now |
| shipped fixtures converted in §8 | 3 | decided in writing, in the file |
| `review_1b_r2_probes/` (bd `3d8q`'s own) | 7 | f1, f1w, f2, g1, g2, e6, l1 |
| `review_b6ap_r2_probes/` + `session-3qlq4/probes/` | 9 | S03 (+ its hand-peel twin and `.s1.ll` forms), S04 |
| `review_integration_probes/` | 2 | G8, and `a4_sel_cmp_round2_window_caller.c` — the two-TU plain-C source behind the converted window fixture, same shape |
| `trackM/probes/impl/` | 2 | p3d8q_sibling, p3d8q_sibling_rail |
| this track's `probes/src/` copies | 14 | the same programs again, as copied into `trackD/probes/src` |
| **`e2e/`** | **0** | **no e2e slice source changes disposition, and every accepting row is `A:<md5>|A:<md5>` — byte-identical LOWERED IR on both binaries, hence an identical trace** |

⚠ **The zero is the load-bearing number here.** This increment widens a DECLINE, and the failure
mode it could have had is a shipped slice quietly refusing to compile. Read it for exactly what it is:
the same `.c` files through the per-probe pipeline, NOT the `^e2e-` gate (which is the merge-and-gate
agent's and still owed).

## 8d. Twin-matrix disposition (brief §4)

`ctest -R '^e2e-loop-twin-matrix$'` on `7fe2bcbf`. TWIN_DISPOSITION

**The prediction, made before the run and recorded here so it can be wrong in public:** NO cell should
move. Every program the generator emits writes its rotations in the SELF-ASSIGNED spelling
(`a = cq_theta(a, …)`, `r = cq_theta(r, …)` — `tools/loop_twin_matrix.py` `RY`/`RGATE`/`RY_REGION`),
which is the chain, not the sibling; the two axes that could have tripped the fence are
`rifelse` (`if (a==5) { r = cq_theta(r,.9); } else { r = cq_theta(r,.3); }` — MUTUALLY EXCLUSIVE arm
siblings on one rail, which is leg 1) and `RECORD_R`'s post-loop `+ cq_measure(r)` (leg 2), and both
are exactly the shapes `RequireEmitDominance=false` exists to keep accepting. The reduced forms are
pinned as `lowering_stale_reader_exclusive_arms_accept.ll` and
`lowering_stale_reader_postloop_measure_accept.ll`.

⚠ The `expected.txt` / `quarantine.txt` baselines were **NOT touched**, and `--regenerate` was **not
run**. If a cell had moved, the disposition would be written here with its direction and its reason.

## 9. Attack surface for the adversarial reviewer

Every predicate touched, every set widened, and the three programs most likely to be the next hole.

**Predicates touched:** `staleReaderRecordOperand` (the reader family + the arg-0-only Rule-3
exclusion); `gateIsHarmless`' dominance precondition (now a parameter); the `Covered` exemption as used
by the reader policy; the `Delta` scope of the round-2 re-ask; the WeakTrackingVH drain.

**Sets widened:** the SWEPT set (from `inLowerOpsScope` to `inLowerOpsScope ∪ readers`), and — for the
reader policy only — the ACCEPTED set (legs 1/2 without the precondition).

**Where I would attack it, in order:**
1. **The `Delta` scope** — the newest thing here, and I attacked it myself; read this before
   re-deriving it. The hole would be: a reader whose operand is tainted at ROUND 1 (so it is not in the
   delta and the re-ask skips it) whose STALING GATE is reachable only through the TAINT-GATED hop —
   the walker's backward closure crosses a chained theta's arg-0 edge only when that parent is tainted
   (`Taint->Tainted.count(Arg0)`), so a gate hanging off a round-2-tainted parent is invisible at
   round 1.
   **Structural argument that it closes, offered to be attacked, NOT a measurement:** a gate that
   becomes visible only through that hop is BY CONSTRUCTION a direct reader of the newly-tainted
   parent — it is a `cq_theta` whose arg-0 IS that parent — so it is itself in the delta and is itself
   adjudicated. The forward direction needs no taint at all (the walk finds `cq_theta_` users by name),
   so a staler reachable forward is already caught at round 1.
   **Measured, and the measurement is inconclusive rather than confirming:** two probes built for this,
   `probes/attack/d1_round2_midchain.ll` (reader operand round-1 tainted, staler a chained FORWARD
   user) and `probes/attack/d2_round2_sibling_first.ll` (the staler runs FIRST so its own read is
   harmless, the second reader is the stale one), both DECLINE on BOTH binaries — and at the
   CONDITION-WIRE fence (`cq controlled lowering: condition predates a non-diagonal gate`), not at
   mine. So the shape is claimed by an earlier owner before my fence is reached, and I could not
   isolate it. A reviewer with a shape that dodges the condition-wire fence (no compare on the rail at
   all — measures only) would have the clean probe I could not build.
2. **The `WeakTrackingVH` drain.** A control emitter that ERASES a recorded reader nulls the handle and
   the decline vanishes. That is intended when the emitter PROVED the shape — but is it always? Find an
   emitter that erases a `cq_theta` without adjudicating its record (the in-place-Ry arm hoists and
   replaces; a peel or flatten that RAUWs rather than erases keeps the handle). A RAUW of the reader's
   own result does not null the handle, but a RAUW of the reader *value* to a non-Instruction would.
3. **Leg 2 with a non-φ seed in a loop.** `gateIsHarmless` grants `Barriers = {SeedDef}` for any
   Instruction seed. With `RequireEmitDominance=false` a gate that does NOT dominate the read now
   reaches leg 2 for the first time. Construct a loop where `SeedDef` is a loop-INVARIANT instruction
   (not a φ) and the gate is in the body: `reachesWithoutBarrier` should say TRUE (decline) — but check
   the case where the seed's block is re-entered, since `reachesWithoutBarrier` deliberately does not
   pre-mark `From`'s own block.

**Also worth an adversarial eye:** whether the arg-0-only restriction can be evaded (a `cq_theta` whose
ANGLE is a tainted-derived value is a separate decline — confirm it still fires first); whether a
`cq_measure` of a QRAM/tape-derived value has a wire this walk misreads; and the two disposition calls
in §8 that inverted a shipped ACCEPT.

## 10. Rule-13 round budget — stated up front

**≥2 rounds, and I expect the first to find something.** The measured hit rate in this codebase says so
(7.4 break: 13 holes over three rounds, three AFTER the epic was closed as cleared; 3qlq Inc 1's C-1
family: 8 instances over 6 rounds on one function, two introduced by a fix). This increment moved a
core fence's slot FOUR times before the fixture suite stopped objecting, which is itself evidence that
the shape is not yet fully understood — and §9 item 1 is a hole I am handing over UNFIXED and BELIEVED
REAL rather than claiming clearance for.

## 11. Follow-ons to file

1. **The `Delta`-scope hole** (§9 item 1) — a reader tainted at round 1 whose staler appears at round 2.
2. **The pure-op path-exclusivity over-decline** — `lowering_reject_stale_record_exclusive_arms.ll`;
   flip `RequireEmitDominance` for `declineStaleRecordOps` under its own Rule-13 round.
3. **`diagnosePreLoopCommitStale` has no positive pin** (§8) — either find a program that reaches it
   with no stale reader, or record it as subsumed.
4. **The Track-A.1 compare-path cell** — `cq_theta(b,0.9)` chained declines at
   `cq controlled lowering: condition predates a non-diagonal gate under quantum control`; decide
   whether that is a true property or a separate over-decline.
5. **The post-lift residual** — a reader whose staler is exposed only by `liftOneRegisterMergePhi`'s
   RAUW is missed; the exact fix needs `WireChain::Gates` propagated transitively to downstream readers.

---

## 12. ROUND-1 FIX ROUND (2026-09-14) — what changed, and what is HELD

Full record: **`FIX_D_R1.md`**. Owner-ruling input for the held item: **`RULING_INPUT_D_R1.md`**.
The branch tip is now **B11 `abe3e0ecfdad3961`**; ⚠ **every measurement in §§6–8d above is a fact about
B8 `7fe2bcbf` and is VOID for B11** unless it is re-stated in `FIX_D_R1.md`.

| finding | disposition |
|---|---|
| **F-D1-1** over-ACCEPT (the in-loop invariant seed) | **HELD, not landed** (coordinator, mid-round: the owner is questioning whether the program should decline at all). Implemented and measured as B10; `HELD_F-D1-1.patch` + `held_f_d1_1/` carry it, including the DECLINE fixture, which cannot land before the ruling. |
| **F-D1-2** the `WeakTrackingVH` drain | **FIXED** — the record is a `WeakVH` (non-tracking), the drain enumerates three outcomes and the third is `report_fatal_error`, never a `continue`. |
| **F-D1-3** header contradicts the code | **FIXED** — the false residual paragraph is replaced by the delta-scoped design. |
| **F-D1-4** `diagnosePreLoopCommitStale` vacuity | **NARROWED, not pinned.** Failure mode (a) is now an EXHAUSTIVE enumeration over the LLVM user kinds of a tainted value; modes (b) taint-growth and (c) CFG rewrite are recorded as NOT subsumed. Follow-on #3 below is rewritten. |
| **F-D1-5** the Delta scope's routing sub-case | **RECORDED** in `TaintSet::StaleQuantumReaders` and at the `Delta` filter, with the `declineClassicalMuxes` coupling as an L3 retirement trigger. |
| minor: column-0 `!dbg` | **MEASURED, not ours** — `clang -O1` emits `!DILocation(line: 4, scope: !10)` with no column for the folded angle select, in the STAGE-1 module. |
| the `g2_measure_parent` deviation | **STANDS** (adjudicated in the implementer's favour by the reviewer and by the coordinator). |

⚠ **§9 item 3 was right, and the reviewer's fix for it was wrong.** The predicted hole ("leg 2 with a
non-φ loop-invariant seed … reachable for the first time") is exactly F-D1-1. The reviewer's traced
minimal fix — `gateIsHarmless(I, I, …)` as the exemption condition — was built as **B9** and declines
**12 shipped Rule-13-cleared ACCEPT fixtures**, because `isPotentiallyReachable(A, A)` is TRUE **by
identity** in LLVM 19 so leg 1 never short-circuits for a self-gate. The corrected spelling is
`WireWalk::readerStalesItself` (leg 1 asked non-degenerately from `std::next(R)`, then leg 2 verbatim
via the split-out `recordBarrierCutsPath`); it leaves 4 lit failures, **all four of them programs that
contain the r5 shape itself**, two of which already decline on the ORACLE at the uncompute fence.

## 11b. Follow-ons — REVISED after round 1

3. ~~`diagnosePreLoopCommitStale` has no positive pin — either find a program that reaches it with no
   stale reader, or record it as subsumed.~~ **Revised**: it is subsumed for failure mode (a) ONLY,
   by an exhaustive enumeration; modes (b) (the in-place op's immediate becomes tainted at the round-2
   fixpoint) and (c) (`RegionFlatten` rewrites the CFG a G5/G6/G7 clause was proven over) are
   structurally reachable between `lowerLoops` (`CQLoweringPass.cpp:393`) and `lowerOps`, and neither
   has a stale reader. **A program built on (b) or (c) is the missing positive pin.**
6. **NEW — the measurement sink is not a wire event.** `cq_measure` is not a non-diagonal gate to the
   wire walk, so `for (…) s += cq_measure(q);` and `int m = cq_measure(q); int a = cq_theta(q,.5);`
   both compile, though a measurement COLLAPSES the register. Whether `docs/frontend.md` §3.2's linear
   rule consumes a measured name is unexamined in both directions, and it is the same boundary the
   F-D1-1 ruling sits on.
7. **NEW — two shipped ACCEPT fixtures contain the r5 shape**
   (`control_phase_kickback_mixed_onward_deadgate_leak_control.ll`,
   `control_phase_kickback_mixed_claim_across_loops_leak_control.ll`). They need a written
   adjudication under either ruling.

---

## 13. OWNER RULING 2026-09-14 — the in-loop invariant re-read DECLINES; F-D1-1 is LANDED

**The ruling.** `int b = cq_theta(q, 0.1);` inside a loop that re-reads a loop-INVARIANT `q` every
trip **must decline**. Made on Track D's measurements, and it reversed the analysis that had been put
to the owner: the "fresh from `q` each trip" reading was believed to require CLONING and therefore to
be unrealizable, which would have made the emitted chain the only possible circuit. It does not —
re-preparing a KNOWN state is not copying an unknown one, and `r5f_inbody_fresh_mint.c` **already
compiles to three independent rails**. Two realizable circuits, the source names neither, so it is
ambiguous and it declines. The conditional-probability measurement settled it: intended
`P(1) = sin²(0.2) ≈ 0.0395` i.i.d. per trip versus emitted `P(1|prev=0) ≈ 0.0025` /
`P(1|prev=1) ≈ 0.9975`, locked onto the first outcome.

The (b) finding stands with it: the immediacy distinction between the loop case and the straight-line
case is about **VISIBILITY, not validity** — which is why the loop case belongs WITH the straight-line
one rather than apart from it. Full measurement set: `RULING_INPUT_D_R1.md`.

**Landed:** `WireWalk::readerStalesItself`. ⚠ **NOT** the reviewer's `gateIsHarmless(I, I, …)`
spelling — measured, it declines 12 shipped Rule-13-cleared ACCEPT fixtures, because LLVM 19's
`isPotentiallyReachable(A, B)` opens `if (A == B || A->comesBefore(B)) return true;` and is therefore
true **by identity**. That LLVM fact is now recorded at `gateIsHarmless`' leg 1 itself, where the next
person would otherwise "simplify" it back, as well as at the new predicate and in `WireWalk.h`.

**Four fixtures converted deliberately, each in writing, each with an L8 retirement trigger naming the
ruling by date** — see `FIX_D_R1.md` §"The ruling, landed".

---

## 14.0 ⚠ THE ROUND-2 ATTACK PROMPT (kept verbatim) — `cq_measure` IS NOT MODELLED AS A WIRE EVENT AT ALL

Stated here prominently because it is **the same boundary the 2026-09-14 ruling sits on, and it is
unexamined in BOTH directions.**

A `cq_measure` is a taint SINK. It is **not** a non-diagonal gate to the wire walk, is never returned
by `findNonDiagonalWireGate`, and never enters a barrier set. So reading a name *after* measuring it
compiles in every spelling — measured on the ruled binary:

| program | verdict |
|---|---|
| `int q=cq_theta(0,.3); int m=cq_measure(q); int a=cq_theta(q,.5);` (`r1`) | **A**, 5 lines |
| `int q=…; for (…) s += cq_measure(q);` (`r5g`) | **A**, 5 lines |
| `int q=…; int a=cq_theta(q,.5); int m=cq_measure(q);` (`r9`/`g2_measure_parent`) | **D** — but only because of the *rotation*, never the measurement |

Physically a measurement **COLLAPSES** the register, so every later name for it denotes a state it no
longer holds in superposition — which is the same "the name and the register have diverged" claim the
whole 3d8q fence is built on. If `docs/frontend.md` §3.2's linear rule consumes a MEASURED name, `r1`
and `r5g` are members of the class and nothing asks about them; if it does not, that should be written
down as a ruling rather than left as an absence of one (L7: *an agent-authored justification hardens
into a ruling if nobody rules*). **Neither direction has been argued, measured or ruled.** This is
where round 2 should start attacking.


---

## 14. `cq_measure` AS A WIRE EVENT — THE DESIGN, after the owner's ruling of 2026-09-14

**Status: DESIGNED, MEASURED, NOT BUILT.** §14.0 above is the question as it was posed to round 2;
this section is the answer, written as an implementable design because the owner has RULED the
capability in — *"so using `cq_theta` after measurement is completely fine, it just requires a
`c_alloc` again"*. Every number below was measured by the round-2 reviewer on the ORACLE
(`f7b65d8ccd7bc472`) and on the reviewed subject (`0f3d512529c5d106`), and re-confirmed on this
round's binary (`4394b3495c1c539f`) where it is cited; the probes are
`trackD/review_r2_probes/src/m14*.c`, `post_measure_scan.py` and `trackD/fix_r2_probes/`.

**Do not read this as a capability.** Nothing in the pass implements it; at the tip a post-measure
re-rotation still CHAINS, and three programs the ruling makes legal still DECLINE. CLAUDE.md's own
standing warning about the Rule-18 narrowing applies verbatim to this section.

### 14.1 What the compiler does today, in one stream

`m14a_measure_then_theta.c` = `int q=cq_theta(0,.3); int m=cq_measure(q); int a=cq_theta(q,.5);`

```
cqrt_alloc_i32(0) -> h0 / cqrt_ry_i32(h0,.3) / cqrt_measure_i32(h0) -> 0
cqrt_ry_i32(h0,.5)                       <-- THE SAME HANDLE. No second alloc.
cqrt_measure_i32(h0) -> 0
```

It **chains on the measured rail**, identically on the ORACLE and on this tip. That is the delta the
ruling has to close. The reason is structural and is the whole finding: **`cq_measure` is a taint
SINK and NOTHING ELSE.** It is not a non-diagonal gate to `WireWalk`, is never returned by
`findNonDiagonalWireGate`, never enters a barrier set, and does not end a name's taint. So the wire
walk cannot see it, and neither can this increment's fence.

### 14.2 The physics, and where the two readings actually differ

A projective computational-basis measurement of the whole register leaves it in `|m⟩`, **unentangled**
(the correlation is transferred to whatever it was entangled with, as that partner's conditional
state). So `Ry(θ)` on the measured rail gives `Ry(θ)|m⟩`, and `alloc(m)` + `Ry(θ)` gives `Ry(θ)|m⟩` on
a NEW rail. **Chain and fresh-alloc are the SAME STATE**, differing only by a **spectator qubit in a
known basis state** — the old rail, still holding `|m⟩`, which Rule 6 will leave ALLOCATED because `m`
is a runtime value and the rail is therefore not provably `|0⟩`.

Two consequences, and neither is the intuitive one:

* **Where the measured name is read ONCE, the literal reading costs a LEAKED QUBIT PER RE-USE and buys
  no state change.** `m14g_entangled_then_measure_reuse.c` (a `cq_theta` under quantum control of `q`,
  then measure and re-use `q`) accepts unchanged at 12 lines on both binaries, and the argument above
  is why: the measurement is exactly the event that disentangles `q`.
* **They differ on a LATER READ of the measured name, and there the chain is WRONG:**
  * `m14b` `m=cq_measure(q); a=cq_theta(q,.5); m2=cq_measure(q);` — chained, `m2` samples the
    ROTATED distribution; under the ruling `q` still denotes `|m⟩` and `m2` returns `m`
    deterministically.
  * `m14d` two siblings off a measured name — chained, `ry(.5); ry(.9)` on one rail (the 3d8q defect);
    under the ruling, two independent rails each seeded `|m⟩`.
  * `m14c` the in-loop re-use — chained, an N-deep chain; under the ruling, N i.i.d. rails. This is
    the exact conditional-probability argument the 2026-09-14 stale-reader ruling was made on.

  All three DECLINE today, and all three declines are **SAFE** — each refuses a chain circuit that is
  genuinely wrong for that program. **This is a capability gap, not a miscompile.**

### 14.3 The two readings, and the recommendation

* **(a) NARROW** — a re-rotation of a measured name allocates a fresh rail seeded from the outcome.
  Every existing single-read accept (`m14a`, and every in-loop measure-and-continue) then gains a
  leaked qubit for no state change.
* **(b) BROAD — TAINT STOPS AT `cq_measure`, POSITION-AWARE.** Every use of the name positioned after
  the measurement is CLASSICAL, so a later `cq_theta` on it is an ordinary SOURCE theta and a later
  pure op is classical arithmetic.

**(b) is the recommendation**, and it is the round-2 reviewer's, on four grounds: it SUBSUMES (a); it
is the natural completion of bd `21mg` (*a `cq_measure` of a never-quantum value lowers to the
classical value*) — same sink, same split, one more axis; it needs no ABI and no new symbol (§14.4);
and it **retires bd `3d8q`'s whole class for measured names BY CONSTRUCTION** rather than by a new
fence — no taint, no reader, no stale record, nothing for this increment's predicate to ask.

### 14.4 The seed — the ABI already takes it, with NO new symbol

`runtime/cq_runtime.h:94-103` declares the seven allocators as taking **a value**
(`int32_t cqrt_alloc_i32(int32_t value)`), not a literal, and the pass **already emits one with a
runtime operand** — measured, `m14h_runtime_seed_alloc.c`:

```llvm
%h = call i32 @cqrt_alloc_i32(i32 %0)        ; %0 is `argc`
```

So `cqrt_alloc_<W>(<the cq_measure result>)` needs **no ABI change, no new frozen symbol, no
`gen_templates.py` regeneration** (Rule 15 untouched, so the drift check never enters this change).

**Width rule.** `cq_measure_<sfx>` returns the register's own type, so for the same-variable re-use the
measured width and the rotated width match BY CONSTRUCTION and the seed goes straight in. A
cross-width re-use is an ordinary **classical** cast on the seed, which `CastLowering` already owns —
the seed is classical by the ruling's own argument, so this never becomes a quantum cast.

### 14.5 The implementation, and the one real cost

`q` before the measurement and `q` after it are **the same SSA value**. Reading (b) is therefore a
**position-aware taint kill** — *"uses of `%q` that are provably after `%m = cq_measure(%q)` are
classical"* — and NOT a set removal from `taint.Tainted`. That is the whole difficulty, and it is not
in the ABI.

**The machinery already exists and is this very fence's.** `WireWalk`'s `provablyBefore` /
`provablyBeforePerActivation` / `reachesWithoutBarrier` answer exactly *"if `B` executes, `A` has
already executed, and `A` never runs again after it"*, with the `cq_measure` call as the barrier. It
is the same walk `readerStalesItself` runs. Sketch, in the shape this track has already cleared once:

1. **Record, do not decide, at the early slot.** Beside `recordStaleQuantumReaders`, for every
   `@cq_measure_<sfx>` call `M` on a tainted `%q`, enumerate the uses of `%q` for which
   `provablyBefore(M, U)` holds. Anything not PROVABLY after stays quantum — the conservative
   direction is "still tainted", which is today's behaviour exactly.
2. **Kill positionally at the consumer, never globally.** A `@cq_theta_*` whose arg-0 is such a use
   becomes a SOURCE theta (`lowerRotations`' existing `Chained == false` path — no new emitter); a
   pure op becomes classical and `lowerOps` simply does not collect it.
3. **⚠ PAY THE L1 OBLIGATION IN BOTH ENTRY POINTS.** `Chained` is decided at FINAL taint
   (`RotationLowering.cpp`), while any predicate that reads the kill set early is at ROUND-1 taint —
   that asymmetry IS L1's PREDICATE species and it has already produced one silent miscompile in this
   file's history (bd `9pum`). The kill must be RE-ASKED after the round-2 fixpoint, like
   `taint.RailCondReads` and `taint.InPlaceRailOps`, and recorded at EVERY site that asks it.
4. **Order it after `repropagateControlMerges`, like bd `21mg` did.** That bead's own RETIREMENT
   TRIGGER says moving `lowerMeasures` earlier passes an `i32` HANDLE through as data; the same
   hazard applies to any stage that reasons about a measured name's disposition.

### 14.6 The population — the cost of building it, measured

* **Shapes the ruling would newly ACCEPT: 0 shipped.** No fixture, slice or golden contains one.
  `ir-pass-lit` is green at this tip (1942 pass / 1 XFAIL of 1943, §15.5), the round-2 e2e sweep was
  **0 movers of 373 measurable**, and `scan_r5.py` found no ACCEPT fixture holding the shape. Closing
  F-D2-3 is therefore **pure capability gain with no regression surface**.
* **Existing accepts whose STREAM would change: 2 of 367 goldens.** `post_measure_scan.py` parses
  every committed `tests/e2e/*.expected.log` and reports a handle acted on again after its
  `cqrt_measure` (a re-measure excluded — idempotent; a `cqrt_free` excluded — not a re-use):

```
slice_control_select_bool_round2_window.expected.log | 1 handle, 1 post-measure op | h2 -> cq_template_icmp_ne_i32_hl
slice_control_select_cmp_round2_window.expected.log  | 1 handle, 2 post-measure ops | h2 -> cq_template_icmp_ne_i32_hl
```

  Both are `int keep = cq_measure(y); int x = (y != 0);` — a pure op on a measured rail, lowered today
  as a quantum `cq_template_icmp_ne_i32_hl` with an `_unc` strip and a `cqrt_free`. Under (b) that
  whole block becomes classical and disappears. **(b)'s shipped cost is exactly two goldens, and both
  get SHORTER.**
  ⚠ The reviewer's first version of that scanner was **VACUOUS** and they caught it by self-test, not
  by re-reading it (the measure line's return is `-> 0`, not `-> hN`, so the anchored regex never
  matched and it reported `0 of 367` for the wrong reason). Re-run against 37 probe traces with known
  positives it reports 12 hits. Rule 12(c), on an instrument. **Re-self-test it before citing it
  again.**

### 14.7 Which of THIS increment's declines reading (b) retires — asked, and answered

The brief asks which of the fence's own declines the design removes. Measured on this round's binary
(`4394b3495c1c539f`), unchanged from the reviewed one:

| program | ORACLE | tip | legal under the ruling? | retired by (b)? |
|---|---|---|---|---|
| `m14a` measure → rotate (read once) | A 5 | **A 5** | yes | not a decline — but its STREAM changes (fresh alloc + one leaked spectator) |
| `m14b` measure → rotate → **re-measure the name** | A 6 | **D** | **yes — OVER-DECLINE** | **YES** |
| `m14c` measure → **in-loop** re-use | A 9 | **D** | **yes — OVER-DECLINE** | **YES** |
| `m14d` measure → **two siblings** | A 7 | **D** | **yes — OVER-DECLINE** | **YES** |
| `m14e` the same two siblings with **no** measurement | A 6 | **D** | **no** | **NO — and it must not.** The control. |
| `m14f` measure → rotate → **pure op** on the name | D | D | yes | **YES**, and it is a PRE-EXISTING decline (`declineStaleRecordOps`, on the ORACLE too) |

**`m14d` and `m14e` differ by exactly one line (`int m=cq_measure(q);`) and get the SAME diagnostic.**
That is the honest shape of the interaction and the sharpest argument for (b): the fence has no
vocabulary for measurement at all, so it cannot separate the legal re-use from the illegal one, and it
refuses both. Reading (b) separates them **by construction** — after the measurement there is no taint
to be stale about — which is why it is a better answer than any predicate this fence could grow.

**Owner question still open (carried from bd `21mg` Q-1):** if the 7.6 output tape wants every
user-written measurement to appear, reading (b) makes a *post-measure classical* `cq_measure` of the
same name lower to the classical value with **no trace line** (that is 21mg's shipped behaviour for a
never-quantum value). Decide that with 7.6, not here.


---

# 15. ROUND-2 FIX ROUND (2026-09-14) — what changed, what is DISCLOSED, what is FILED

Round 2 returned **NOT CLEAR** on five findings (`REVIEW_D_R2.md`, 78 probes). The disposition is
deliberately NARROWER than the review, on the coordinator's instruction: **fix what THIS increment
caused; file what it did not.**

| # | severity | disposition here |
|---|---|---|
| **F-D2-1** | over-ACCEPT / silent miscompile | **NOT FIXED — WRITTEN UP FOR FILING (§15.4).** Reproduces byte-for-byte on the ORACLE; pre-existing, and its minimal fix moves an ACCEPT-direction predicate with three granting callers, which is a Rule-13 round of its own. |
| **F-D2-2** | over-DECLINE, created by this increment | **FIXED (§15.1)** — `readerStalesItself` leg 1b, + 2 accept fixtures + 1 decline fixture + the reworded retirement trigger. |
| **F-D2-3** | over-DECLINE under the §14 ruling | **DESIGNED, NOT BUILT (§14)** — owner's call between readings (a) and (b); reading (b) recommended and costed. |
| **F-D2-4** | fixture hygiene | **DISCLOSED (§15.3)**, verified independently by the reviewer; what would restore the lost pin is stated. |
| **F-D2-5** | record accuracy | **CORRECTED (§15.2)**, at both occurrences, and the reviewer's own count corrected with it. |

Binary for every row below: **B13 `4394b3495c1c539f`**, `libCQPass.so` `7f7ff051d12b5112`
(`GATES.md`). ⚠ **Every line measured against `0f3d5125…` is VOID for this binary** and was re-run.

---

## 15.1 F-D2-2, FIXED — `readerStalesItself` gets leg 1b, the SEMANTIC reading of leg 1

### The defect, in one sentence

Leg 1 asks `reachesWithoutBarrier(R, R, {})` — a **CFG** question — and *"there is a cycle through the
reader's block"* is **not** *"the reader executes twice"*. Two well-formed programs the ORACLE
compiled to the **correct one-rotation circuit** were declined:

```c
/* ob1  */ int q=cq_theta(0,.3); for(i<3){ if(i==0){ int b=cq_theta(q,.1); s+=cq_measure(b);} else s+=1; }
/* ob1b */ int q=cq_theta(0,.3); int first=1;
           for(i<3){ if(first){ int b=cq_theta(q,.1); s+=cq_measure(b); first=0;} else s+=1; }
```

`q` is loop-INVARIANT, so leg 2 correctly refuses — there is no per-trip barrier that re-establishes
the record. But **the reader runs exactly once**, so the chain reading and the re-preparation reading
COINCIDE. The 2026-09-14 owner ruling declined the in-loop invariant re-read because *"the source
admits TWO realizable circuits and names neither"*; **this shape admits exactly ONE**, so the ruling's
own rationale is absent. Under the owner's standing ruling of 2026-09-11 (*"our end-goal is to not
decline any code that will lead to a valid quantum circuit"*) an over-decline is a **defect**, and
this one was created by this increment.

### Before / after, measured

```
$ trackD/fix_r2_probes/m.sh {BEFORE|AFTER} src/ob1*.c src/ob7*.c src/ob9*.c
```

| probe | ORACLE | BEFORE (`0f3d5125`) | AFTER (`4394b349`) | |
|---|---|---|---|---|
| `ob1_reader_runs_once_in_loop` | A 4 | **D** | **A 4** | ⭐ fixed; trace **byte-identical to the ORACLE** |
| `ob1b_first_iteration_flag` | A 4 | **D** | **A 4** | ⭐ fixed; trace **byte-identical to the ORACLE** |
| `ob1d_guarded_runtime_cond` (the CONTROL) | A 4 | D | **D** | correct — `if (i < argc)` can hold on many trips |
| `ob1c_guarded_once_measure_after` | D | D | **D** | unmoved; declines at a DIFFERENT, earlier fence (`cq loop lowering: loop-carried tainted value crosses iterations`) |
| `ob7_reader_in_guarded_exit` | A 4 | A 4 | **A 4** | unmoved |
| `ob9_breaking_loop_single_read` | A 4 | A 4 | **A 4** | unmoved (`-O1` deletes the loop outright) |

The fixed stream, both probes, byte-identical to each other and to the ORACLE:

```
cqrt_alloc_i32(0) -> h0 / cqrt_ry_i32(h0, 0x1.3333333333333p-2)
cqrt_ry_i32(h0, 0x1.999999999999ap-4) / cqrt_measure_i32(h0) -> 0
```

### The mechanism — eight clauses, all REQUIRED, and it is reachable from ONE predicate

`WireWalk.cpp`, file-local `readerRunsAtMostOncePerActivation`, called ONLY from
`readerStalesItself`, which is called ONLY from `OpcodeLowering::recordStaleQuantumReaders`.
**Deliberately not exported**: a second caller cannot acquire the ACCEPT-direction relaxation without
coming through the predicate that owns the question (Rule 14; and L3's mirror — when you add a caller,
ask what its callee's contract says).

Let `L` be the reader's innermost loop, `H`/`PH`/`Lat` its header/preheader/latch, `B` the reader's
block:

* **(C2)** `L` is TOP-LEVEL — in a nest, "once per activation of the inner loop" is once per trip of
  the outer one.
* **(C3)** `PH` and a single `Lat` exist, and `B != H`.
* **(C4)** `H` is entered on **exactly two edges** and they are `PH` and `Lat`. Both the edge COUNT
  (`pred_size`, so a **duplicated latch edge cannot pass as one**) and the edge SET are checked,
  because (C7) reads ONE incoming of a φ.
* **(C5)** `B`'s only predecessor is `H` — no second door into the reader.
* **(C6)** `H`'s terminator is a conditional `br` with DISTINCT successors, exactly one of them `B`;
  `Want` is the polarity that reaches the reader. **Read off the successor, never off the predicate**
  (Rule 9 — `-O1` swaps polarity routinely; pinned by `a6_polarity_swapped.ll`).
* **(C1)** the guard is **CLASSICAL (untainted)**. *"How many times does this block execute"* is a
  classical question and a TAINTED condition has no classical answer to it — the arm runs in
  superposition and `detectControlRegions` / the loop layer owns it; asking ScalarEvolution about a
  quantum handle would be the Rule-3 wire crossing this project keeps hitting. ⚠ **This clause was
  added AFTER the first build of the round** (binary B13a `6480de5f7a82084d`, whose rows are VOID)
  because I found the hole in my own leg, not because a probe caught it — and the probe then measured
  that **it is DEFENCE IN DEPTH, not the deciding fence**: `ob1e_tainted_guard.c` (the `ob1` shape with
  `if (p == 5)` on a tainted `p`) declines with `cq controlled lowering: condition predates a
  non-diagonal gate under quantum control` on **all three** of the ORACLE, B12 and B13 — the
  condition-wire fence gets there first. Say it that way; do not claim (C1) saves a program.
  Its **L1 residual is written at the clause** in `WireWalk.cpp`: this runs at ROUND-1 taint, a
  condition can become tainted only at the round-2 fixpoint, and the `Delta` re-ask is scoped to
  readers whose RECORD grew. That window cannot turn a decline into an accept for a reason independent
  of this leg — a round-2-tainted LOOP-HEADER branch is a tainted branch in a loop, which the loop
  layer refuses on its own — and granting here disarms no other fence. RETIREMENT TRIGGER: the day a
  tainted loop-header branch LOWERS, re-derive that paragraph.
* **(C7)** THE SEMANTIC STEP — the guard provably evaluates to `!Want` on **every** arrival from
  `Lat`, via `guardValueOnLatchEdge`.
* **(C8a)** `PH` is **not reachable from `R`** — the loop is never re-entered after the read. Without
  it the loop could be exited and entered again, and the second entry arrives at `H` from `PH`, where
  (C7) says nothing. `isPotentiallyReachable` is conservative-TRUE and TRUE here means DECLINE.
* **(C8b)** a structural backstop: every CFG cycle through `R` crosses `H`'s terminator. **The proof
  is complete without it** (see below); it is retained because the proof leans on LoopInfo's contracts
  and this clause leans on nothing but the CFG, at the cost of one bounded walk. The conjunction
  declines if the two ever disagree, which is the direction this file is allowed to be wrong in.

**The proof.** An execution of `R` needs an `H`→`B` edge (C5), hence an arrival at `H` with the guard
`== Want`; arrivals come from `PH` or `Lat` (C4); from `Lat` the guard is `!Want` (C7); so only a `PH`
arrival runs `R`, and after one has, `PH` never executes again (C8a). Hence at most one `R`. ∎

**`guardValueOnLatchEdge` — two evaluators, because `-O1` produces two shapes, and `std::nullopt`
(NOT PROVABLE) is always the DECLINE direction:**

* **(i) the one-shot FLAG.** `int first = 1; … first = 0;` survives as an `i1` header φ with CONSTANT
  incomings (`[false, %pre], [true, %latch]`). **ScalarEvolution models no `i1` φ**, so this is read
  off the φ directly. Pinned ALONE by `lowering_stale_reader_inloop_once_flag_accept.ll`.
* **(ii) the COMPARE on the induction variable.** `if (i == 0)` survives as `icmp eq %iv, 0`. Each
  operand is rewritten to the value it takes **on the latch edge** (an `H`-φ becomes its latch
  incoming; a loop-invariant operand already is that value) and the rewritten predicate is put to
  ScalarEvolution — whose answer over an add-recurrence is **UNIVERSAL over the iterations**, which is
  exactly the quantifier this needs ("false on EVERY arrival from the latch", not just on trip 2).
* Anything else — a non-`H` φ, a loop-variant non-φ operand, an `fcmp`, a non-integer operand, an
  `and`/`or`/`select` tree — is `nullopt`. **L5 applies**: this is not an enumeration of folds trying
  to bound a semantic question; the semantic question is handed to LLVM's own machinery and what is
  skipped is named.

### What the leg does NOT prove — measured, not argued (`trackD/fix_r2_probes/adv/`)

Six adversarial probes, each a one-token mutation of the accept fixture, on B13:

| probe | verdict | reading |
|---|---|---|
| `a1_noflags.ll` (`nuw nsw` dropped) | **ACCEPT** | SCEV still decides it from the trip-count-bounded range. ⚠ My first retirement trigger claimed the flags were load-bearing — **wrong, measured wrong**. |
| `a2_runtime_trip.ll` (runtime trip count) | **ACCEPT** | the `nuw` range alone carries it |
| `a3_guard_eq1.ll` (`if (i == 1)`) | **DECLINE** | ⚠ **a residual OVER-DECLINE of my own leg.** The reader runs once there too, but not on the FIRST trip; the leg proves *"false on every latch arrival"*, strictly narrower than *"true on at most one iteration"*. Widening it means a monotonic-add-recurrence argument and **its own Rule-13 round** — it is an ACCEPT-direction relaxation. **FILED, not hidden.** |
| `a4_guard_slt2.ll` (`if (i < 2)`) | **DECLINE** | **correct** — the reader runs on two trips and genuinely stales itself. The control that shows the leg is not "any constant compare accepts". |
| `a5_runtime_start.ll` (IV starts at `%u1`) | **DECLINE** | **correct**: with `%u1 == -1` the guard is true again on trip 2. ⚠ **CORRECTED 2026-09-14 by review round 3 (F-D3-1), because the sentence that stood here stated a FENCE THAT DOES NOT EXIST.** It read *"if this ever accepts, leg 1b has become an over-accept in the unforgivable class"*, which reads as the category *a runtime-start IV must decline* — **false as a rule**. `a5` declines because **SCEV cannot decide** `{%u1+1,+,1} ne 0`, **not** because the start is runtime: probe `review_r3_probes/rc6_runtime_start_guarded.c` — `if (u > 0) for (int i = u; i < u+3; i++) if (i == u) {…}` — is a runtime-start IV that **reaches leg 1b and ACCEPTS, soundly** (measured on `4394b349`; the rewritten latch value is `{%0+1,+,1}<nsw>`, which SCEV proves `ne %0`, so the reader runs on trip 1 only). **The real invariant is that `guardValueOnLatchEdge` returns `std::nullopt` for anything it cannot prove, and `nullopt` is the DECLINE direction** — that is what the code implements, and it is the boundary a future widener must argue with. ⚠ The same false sentence is still carried in the header of `ir-pass/test/lowering_stale_reader_inloop_once_guarded_accept.ll` ("a RUNTIME start value for `%i` … if it ever accepts, leg 1b has become an OVER-ACCEPT in the unforgivable class") and is **owed the same correction** — this docs pass may not edit `ir-pass/`. |
| `a6_polarity_swapped.ll` (`icmp ne`, successors swapped) | **ACCEPT**, byte-identical stream | Rule 9 |
| `src/ob1e_tainted_guard.c` (the guard is a TAINTED compare) | **DECLINE** on ORACLE, B12 **and** B13, same string | clause (C1)'s subject — and the measurement that (C1) is **defence in depth**: the condition-wire fence reaches it first |

### Blast radius, and why it is small by construction

* `readerStalesItself` gained two **pointer** parameters; **NULL for either ⇒ byte-identical to the
  pre-fix behaviour.** The leg is strictly additive and no caller can reach it accidentally.
* `gateIsHarmless`, `recordBarrierCutsPath`, `phiTracksWire`, `walkNonDiagonalWireGates` and all
  **17 code call sites of the walker's two public faces are UNTOUCHED** (§15.2 for the count).
* `recordStaleQuantumReaders` now builds `LoopInfo`/`AssumptionCache`/`TargetLibraryInfo`/
  `ScalarEvolution` at the SAME lazy point it already built the `DominatorTree` — once per function
  that contains a reader. `ScalarEvolution`'s constructor computes nothing until queried. The
  direct-construction idiom is `LoopLowering.cpp:3704-3715` verbatim; **declaration order is the
  destruction contract** (`SE` last, destroyed first).
* **78 probes re-run on B13 against the REAL B12 binary: exactly TWO movers**, both intended, and
  **105 probes in total** once the 27 round-1 reproducers / must-not-move modules are added (`m27.sh`,
  against the B12 binary SAVED ASIDE across the rebuild) — those 27 are **unmoved in both verdict and
  trace-line count**. For the 47 probes that accept on both, the **lowered IR is byte-identical**
  (`ModuleID` stripped); for the declines, **stderr is byte-identical** except the two.
* `ir-pass-lit`: **1942 pass / 1 XFAIL of 1943**, green (§15.5).

### Fixtures — red-green, and the trigger that was lying

| file | verdict | what it pins |
|---|---|---|
| `lowering_stale_reader_inloop_once_guarded_accept.ll` | **NEW, ACCEPT** | evaluator (ii); the exact stream; the six adversarial residuals in its header |
| `lowering_stale_reader_inloop_once_flag_accept.ll` | **NEW, ACCEPT** | evaluator (i) ALONE — ⚠ the only fixture in the tree whose guard is an `i1` φ rather than a compare, so it is the one that fails if the two evaluators are ever folded together |
| `lowering_reject_stale_reader_inloop_repeatable_guard.ll` | **NEW, DECLINE** | the Rule-12 negative: the same module with a RUNTIME guard. ⚠ If it ever accepts, leg 1b is an over-accept. |
| `lowering_reject_stale_reader_inloop_invariant_seed.ll` | unchanged DECLINE | ⚠ **its RETIREMENT TRIGGER was REWRITTEN** — see below |

**The trigger that was lying.** The decline fixture's L8 trigger said *"this becomes an over-decline
the day the pass can prove a **LOOP BODY** executes at most once"*. That day arrived in the same week
and the file is unaffected, because **the unit that matters is the READER'S OWN BLOCK, not the loop
body** — `ob1`'s body runs three times and its reader once. Written as "body", the trigger would not
have fired for its own subject, and a future agent reading it would have concluded the shape was
already covered. It now states: the fixture still declines because `%body` is entered by an
UNCONDITIONAL `br` (leg 1b refuses at **(C6)**, never reaching ScalarEvolution), names the two accept
fixtures that DID retire the guarded spelling, and says what would retire this one.

---

## 15.2 F-D2-5, CORRECTED — `gateIsHarmless` has ONE call site, and the reviewer's 18 is also off by one

`FIX_D_R1.md` said *"every one of its **17 call sites** is byte-unchanged"*. Re-measured on this tip:

```
grep -rn "gateIsHarmless" ir-pass/src ir-pass/include                                   # 1 call + 1 def + prose
grep -rn "findNonDiagonalWireGate(\|collectNonDiagonalWireGates(" ir-pass/src ir-pass/include | grep -v WireWalk
```

* **`gateIsHarmless` has exactly ONE call site** — `ir-pass/src/WireWalk.cpp:812`, inside
  `walkNonDiagonalWireGates`. It is anonymous-namespace-static; nothing outside the file can reach it.
  The **substance** of the original claim stands (behaviourally byte-unchanged, and the reviewer
  verified that independently by diffing the extracted pre-split body); only the number was wrong.
* **The 17 belongs to the WALKER'S PUBLIC FACES.** The two faces occur on **18 lines** outside
  `WireWalk.*`; **one of the 18 is PROSE** (`ArmClassify.cpp:2783`), so there are **17 code call
  sites**, one of which (`OpcodeLowering.cpp:518`) is this increment's own new reader call — **16
  pre-existing**. The round-2 review's "18 external call sites" counts the comment line.

Corrected at **both** occurrences in `FIX_D_R1.md` (§"the two legs" and §13's landing note), with a
dated ERRATUM at the first so the old sentence is still findable. Nothing else in the tree carried
the claim (grepped).

---

## 15.3 F-D2-4, DISCLOSED — the F-C1B-2 REFUSAL direction has no positive stream pin anywhere

**Stated plainly, as a cost of the 2026-09-14 ruling rather than as a footnote.**

`control_phase_kickback_mixed_claim_across_loops_leak_control.ll` carried a **13-directive positive
STREAM pin** (the `and_hl` → `icmp_eq_hl` → `cqrt_x` → `cqrt_rz_i1` → `cqrt_x` → `_unc` → `cqrt_free`
sequence, original lines 105-124). Its subject was **F-C1B-2's per-loop `ClaimedRailRoots` key** —
*"LOOP A's claim must not satisfy clause (0) for LOOP B"*. The ruling converted the file to a DECLINE
and neutered those directives to `[check]`, so:

* **the ACCEPT direction is still pinned** — the discriminating half
  `control_phase_kickback_mixed_claim_across_loops_accept_control.ll` still accepts (re-measured on
  B13) and still carries its own 10-line positive `CHECK` stream;
* **the REFUSAL direction's only positive stream pin is GONE, and cannot be recovered by an edit.**
  The subject needs LOOP B to hold an in-body in-place gate on a root LOOP B did not claim — which
  **IS** a loop-invariant re-read, i.e. exactly the shape the ruling removed from the language. The
  pin and the ruled-out program are inseparable.

**What would restore it** — one of three, in increasing cost:
1. a module that reaches the per-loop key with LOOP B's in-body gate on a root LOOP B *did* claim but
   LOOP A *also* claimed, so clause (0) is asked and refused without the invariant re-read. If such a
   module exists it is the cheapest restoration; **nobody has built one, and it may not exist** — the
   two conditions may be the same condition;
2. an `-mutate`-style injection gate that makes the per-loop key's NARROWED form go red (Rule 12's
   "validate by mutation, not by re-reading the prefixes"). This pins the key without pinning a stream;
3. reversing the ruling, which inverts the file back — its ORIGINAL directives are **preserved
   verbatim in the file** for exactly that, with a written L8 trigger pairing it to
   `lowering_reject_stale_reader_inloop_invariant_seed.ll`. **Do not move one without the other.**

Until one of the three lands, **the per-loop key's refusal direction is protected by prose and by the
accept twin, not by a stream assertion.** That is worse than it was, it is a consequence of a ruling
and not of a bug, and it is written here so nobody discovers it by a regression.

---

## 15.4 F-D2-1 — NOT FIXED. THE FILING, in the strongest terms the measurements support

**Severity: over-ACCEPT / silent miscompile — the unforgivable class. Reproduces on the ORACLE, so it
is PRE-EXISTING and not a regression of this increment. It is filed, not fixed, because its minimal
fix moves an ACCEPT-direction predicate with three granting callers — the exact configuration round
1's rejected fix failed on — and that is a Rule-13 round of its own.**

### The pair: two well-formed C programs, one operand of one φ apart, ONE circuit

```c
/* oa1  */ for (i<3) { int a = cq_theta(q,.1); int d = a+1; s += cq_measure(d); q = a; }
/* oa1t */ for (i<3) { q = cq_theta(q,.1);     q = q+1;     s += cq_measure(q);        }
```

After `clang -O1` the two stage-1 modules differ in **exactly one operand of one φ**:

```
oa1 : %4 = phi i32 [ %1, %0 ], [ %7, %3 ]      ; carries %7 — the THETA result, PRE-add
oa1t: %6 = phi i32 [ %1, %0 ], [ %8, %3 ]      ; carries %8 — the ADD result,  POST-add
```

Measured on **B13** and on the **ORACLE** (`f7b65d8c`), both ACCEPT at 11 trace lines, and

```
$ diff AFTER/oa1_phitracks_inplace_add.trace AFTER/oa1t_alias_twin.trace
*** BYTE-IDENTICAL ***        (and identically byte-identical on the ORACLE)
```

The stream, per trip: `cqrt_ry_i32(h0,.1)` / `cqrt_addc_i32(h0,1)` / `cqrt_measure_i32(h0)`.
`cqrt_addc_<W>` is the **in-place** rail op (`runtime/cq_runtime.h:413`, *"h := (h + imm) mod 2^W"*)
and only ONE handle exists, so trip 2's rotation fires on the **post-add** register — which is
`oa1t`'s circuit. `oa1` says trip 2 rotates the state `a` denotes, the **pre-add** one. **Two
different well-formed programs, one circuit, `opt` exit 0, verify-clean.** That is bd `3d8q`'s own
definition of the defect.

### It is a DEFECT and not a semantics question, because the compiler gets the straight-line twin RIGHT

`oa1s_straightline_analogue.c` has the identical data-flow property (`a` used after the add site),
spelled without a loop:

```
cqrt_ry_i32(h0,.1) / cq_template_add_i32_hl(h0,1) -> h1   ; OUT OF PLACE — a FRESH rail for `d`
cqrt_measure_i32(h1) / cqrt_ry_i32(h0,.2) / cqrt_measure_i32(h0)   ; `a`'s rail untouched. CORRECT.
```

`oa2_phitracks_inplace_xor.c` reproduces it with `xor`.

### The two walls, and why NEITHER reaches the new caller

`ir-pass/include/WireWalk.h` (at the reviewed tip, lines 223-243) documents this gap **verbatim**,
above `phiTracksWire`:

> *"THE VOCABULARY THAT MAKES THAT MATTER: this predicate is spelled over `thetaOnPathTo`, which
> counts a `cq_theta` as a staler and does NOT count the dtzb in-place `add`/`xor` … So in the
> GRANTING direction **a φ whose wire moved only by a dtzb `add` between its incoming and its edge
> would be granted a refresh it did not earn.** MEASURED 2026-09-04 (5 probes, HEAD): **NOT
> EXPLOITABLE** …"*
> *"Any third caller must state which direction it uses before relying on the sentence above."*
> *"RETIREMENT TRIGGER, THREE WAYS: … Any of the three makes this predicate the only wall, and the
> dtzb gap becomes live — **WIDEN THE VOCABULARY (or fence the caller) IN THE SAME CHANGE.**"*

The 2026-09-04 "NOT EXPLOITABLE" verdict rests on **two walls**, named in that same paragraph, and
each stands in front of a PREVIOUS granting caller:

* **WALL 1 — `ArmClassify::recordLivePerActivation`'s R6 PHI-EDGE READ-POSITION rule**
  (`ArmClassify.cpp:748`, the header's *"a frozen carry is its own user, so R6's PHI-EDGE READ
  POSITION rule refuses the mirrored pair before this predicate is consulted"*). **It does not reach
  `readerStalesItself`: `oa1` contains NO tainted control region at all** — the loop body is
  straight-line under a classical IV compare — so `ArmClassify` never classifies an arm here and R6
  never runs. Measured corroboration: every decline in the `oa*` family comes from the LOOP path
  (`cq loop lowering: loop-carried rail has multiple in-place consumers`), never from the control path.
* **WALL 2 — `LoopLowering::collapseRailPhisIn` step (1)'s LOOP-CARRIED guard** (`kMsgCrossIter`,
  *"cq loop lowering: loop-carried tainted value crosses iterations"*), named as the header's THIRD
  retirement-trigger leg. **It does not reach `oa1` either: `oa1` passes it — it ACCEPTS.** The guard
  demonstrably fires elsewhere in the same probe set (`ob1c`, `od6` decline on exactly that string),
  so this is a measured non-reach, not an absence of evidence.

**So the increment added the third granting caller the header names, the gap became live in the same
change, and neither the widening nor the caller-fence the header prescribes was made — nor was the new
caller's reliance on the granting direction stated, which the header explicitly requires of "any third
caller".** This is L3's mirror: *when you add a CALLER, ask what its callee's written trigger says.*

### The grant, traced against the code as landed

* reader `%7 = cq_theta(%4,.1)`, record `%4` (the rail φ).
* `readerStalesItself(%7,%4)`: leg 1 `reachesWithoutBarrier(%7,%7,{})` → **true** (the cycle);
  leg 1b (new) refuses at **(C6)** — the header's terminator is the loop's own conditional exit, not a
  guard routing to a distinct reader block — so the new leg changes NOTHING here, as intended.
* leg 2 `recordBarrierCutsPath(%7,%7,%4,{%4})` opens
  `if (auto *SeedPhi = dyn_cast<PHINode>(SeedDef)) if (!phiTracksWire(SeedPhi)) return false;` —
  **a `false` here is a DECLINE**, so `phiTracksWire == true` is the GRANT.
* `phiTracksWire(%4)`: latch incoming `%7`; `thetaOnPathTo(%7, latch-term)` sees only `%8` (the
  `add`), `%9` (the measure) and the IV arithmetic — **no `cq_theta`** → `false` → **tracks** →
  barrier `{%4}` → the back edge crosses it → `recordBarrierCutsPath` = true →
  `readerStalesItself` = **false** → exemption GRANTED → **ACCEPT**.

### Where the in-place decision is actually made — localised to the missing clause

The reviewer localised this by controls but *"did not read the loop-side in-place marking path to the
point of naming the missing clause"*. **Named here.**

`ArithLowering::classifyInPlaceReassignment` (straight-line M-C) cannot be the owner: its G5 returns
`false` for any site inside a loop (`ArithLowering.cpp:695`). The owner is the LOOP path, whose
fan-out / linear-lineage guard is **`tryCaseA`'s in-place-user tally, `LoopLowering.cpp:2217-2236`**
(and its round-2 twin at `:2663`, both diagnosing `kMsgRailFanout`). That tally enumerates the users
of a rail value and counts them as in-place consumers in exactly two branches:

```cpp
for (User *U : KV.first->users()) {
  if (auto *CI = dyn_cast<CallInst>(U))        { /* in-place gate on arg0  */ }
  else if (auto *BO = dyn_cast<BinaryOperator>(U)) { /* dtzb value self-update */ }
}
```

**A `PHINode` user is counted by NEITHER branch.** In `oa1`, `%7`'s users are `%8` (the `add`,
counted) and `%4` (the header φ whose LATCH incoming is `%7`, **not counted**) — yet that φ is
precisely the forward consumer that carries the **pre-mutation** record across the back edge into the
next trip's rotation. So the tally sees ONE in-place consumer, the collapse proceeds, and the add is
emitted in place.

**The controls confirm the localisation exactly:**

| probe | where the later use of `a` is | verdict |
|---|---|---|
| `oa1u_inbody_later_use` | **in the body** (a second `cq_theta(a,.2)` — a `CallInst` user) | **D** `kMsgRailFanout` — the clause exists and fires |
| `oa1` | **through the back edge** (the φ's latch incoming — a `PHINode` user) | **A**, in place — the same clause is blind |
| `oa1v_noloopcarry` | no loop carry at all | **A**, `cq_template_add_i32_hl` **out of place** (correct) |

### NEITHER DISPOSITION OF THE PAIR IS PINNED TODAY — measured, which is how it shipped

`trackD/fix_r2_probes/oa1_shape_scan.py` (text-level, CFG from terminator labels, reachability by
BFS; **self-tested**: it finds `oa1`, `oa1u` and `oa2` and correctly MISSES `oa1t` — which carries the
POST-add name — and `oa1s`/`oa1v`):

```
scanned 1938 fixtures containing cq_theta_; 1 hold the F-D2-1 shape
  control_swap_reject_inloop_value_arm.ll @example: %p carried into %merge from %loop (back edge) and dtzb-mutated
```

and that one file is a **DECLINE fixture that declines at an unrelated, earlier fence**
(`cq controlled lowering: control flow inside a loop body under quantum control`, measured on B13).
⚠ Three further fixtures hold a **weaker** form and were excluded once the scan required the dtzb op
to be INSIDE the cycle — `control_swap_inloop_postloop_railop{,_mc}.ll` put the `add` AFTER the loop,
where it runs once and cannot stale the carry. **So no shipped fixture pins either disposition of the
`oa1`/`oa1t` pair.** A crude scan is a LOWER BOUND, never a census (Rule 11).

⚠ **I deliberately did NOT add a fixture pinning today's behaviour.** A green fixture asserting `oa1`'s
current ACCEPT would cement a silent miscompile. **The pair must be pinned AS PART OF THE FIX** — an
`oa1` DECLINE fixture and an `oa1t` ACCEPT fixture, in the same commit — which is the red-green shape
Rule 12 asks for and is listed in the filing below.

### The fix, and why it is a round of its own

Two options, both from the header's own prescription:

1. **WIDEN THE VOCABULARY** — teach `thetaOnPathTo`'s `Stales` lambda (`WireWalk.cpp:166-172`) to
   count a marked dtzb in-place `add`/`xor` on the wire as a relabelling event, which
   `LoopLowering::collectRailGates` and CLAUDE.md CORRECTNESS RISK §2 **already** count. Hand-traced,
   it separates the pair exactly: `oa1`'s φ latch incoming `%7` is followed by the in-place `%8` ⇒
   `phiTracksWire` false ⇒ DECLINE; `oa1t`'s φ carries `%8` with only the measure after it ⇒ true ⇒
   ACCEPT.
2. **FENCE THE CALLER** — have `readerStalesItself` refuse the φ grant when a marked in-place rail op
   lies between the latch incoming and the edge. Narrower, and it cannot move `ArmClassify`.

**Option 1 moves an ACCEPT-direction predicate with THREE granting callers** (`recordLivePerActivation`
at `ArmClassify.cpp:748`; `recordBarrierCutsPath`'s superseding-φ closure at `WireWalk.cpp:371`; and
this increment's reader path through `WireWalk.cpp:355`), so it must be re-measured against the 12
`control_inplace_ry_inloop_*` fixtures, `control_inplace_ry_reject_inloop_frozen_dtzb_carry.ll` (which
carries the whole 2026-09-04 discrimination), `ArmClassify`'s R6 callers, and
`^e2e-loop-twin-matrix` — because it moves an in-loop in-place disposition. **Option 2 needs the
`InPlaceRailOps` marking to EXIST at the time the fence asks**, and `recordStaleQuantumReaders` runs
BEFORE `lowerLoops`; that ordering question is the first thing to measure and it may force option 1.

### bd `a3z7` SHOULD BE RE-RAISED FROM P3 TO P1

`a3z7` records the **same structural fact** — *"the FLAT twin lowers the add OUT of place … rolled
emits `cqrt_addc` in place (**the better circuit**)"* — as a **P3 quarantined divergence** and an
**efficiency judgement**. The `oa1`/`oa1t` pair shows that is the wrong reading: whenever the rail φ
carries the **OPERAND** rather than the RESULT, the rolled form is not "the better circuit" but **a
DIFFERENT PROGRAM'S circuit**. Re-raise `a3z7` to **P1** with this pair attached, or file a new P1 and
cross-reference it. It is also **distinct from bd `0njv`**, which is the straight-line version — and
the straight-line spelling of *this* shape is handled CORRECTLY (`oa1s`, out of place), so this is a
loop-only defect with its own population.

### What the filing must carry

1. the `oa1`/`oa1t`/`oa1s`/`oa1u`/`oa1v`/`oa2` probe set (in `trackD/fix_r2_probes/src/`, traces in
   `BEFORE/`, `AFTER/`, `ORACLE/`) and the byte-identity diff;
2. the two walls and the measured reason neither reaches the new caller;
3. the named missing clause (`LoopLowering.cpp:2217-2236`, the `PHINode`-user hole) and the three
   controls that localise it;
4. **the red-green pair to write WITH the fix**: `oa1` DECLINE + `oa1t` ACCEPT, same commit;
5. the re-measurement list for option 1 (12 `control_inplace_ry_inloop_*`, the frozen-dtzb
   discriminator, R6's callers, `^e2e-loop-twin-matrix`);
6. `a3z7` re-raised to P1; `0njv` cross-referenced as the distinct straight-line sibling;
7. and the durable lesson, for `bd remember`: **when you add a caller to a shared predicate, read the
   callee's retirement trigger and state which direction you use — the trigger named this shape by
   name, and nobody read it.**

---

## 15.5 Gates run this round — `ran:` / `cited:`

```
ran:   cmake --build build -j8 (BOTH targets)      | 4394b3495c1c539f | exit 0
ran:   ctest --test-dir build -R ir-pass-lit       | 4394b3495c1c539f | 1/1 Passed, 49.36 s
ran:   lit ir-pass/test (count)                    | 4394b3495c1c539f | 1942 pass / 1 XFAIL of 1943
ran:   lit ir-pass/test --filter 'stale_reader'    | 4394b3495c1c539f | 15/15
ran:   lit ir-pass/test --filter 'control_inplace_ry' | 4394b3495c1c539f | 246/246
ran:   lit ir-pass/test --filter 'inloop|loop'     | 4394b3495c1c539f | 184/184
ran:   fix_r2_probes/m.sh BEFORE/AFTER, all 78 r2 probes + 5 hand .ll | 2 movers, both intended
ran:   fix_r2_probes/m.sh ORACLE, all 78           | f7b65d8ccd7bc472 | the ORACLE column above
ran:   lowered-IR byte-compare BEFORE vs AFTER over every accepting probe | 47 identical, 0 differing (the 78-probe set + the 27 round-1 probes)
ran:   stderr byte-compare BEFORE vs AFTER over every declining probe     | 2 differing (ob1, ob1b), 0 others
ran:   fix_r2_probes/adv (6 one-token mutants of the accept fixture)      | table in §15.1
ran:   fix_r2_probes/oa1_shape_scan.py over ir-pass/test/*.ll + self-test | 1 hit, decline at another fence
ran:   fix_r2_probes/m27.sh, the 27 ROUND-1 probes (the 14 reproducers + the must-not-move table),
       on a TRUE BEFORE (the B12 binary SAVED ASIDE across the rebuild, hash re-verified) and on B13
                                                   | diff EMPTY — all 27 unmoved, verdict AND trace count
ran:   rebuild reproducibility (stash -> B12 -> pop -> rebuild) | the second B13 build is BIT-IDENTICAL to the first
NOT run (brief): corpus sweep, full ctest, ^e2e-, cq-opt-equivalence, twin matrix.
cited (B8 only, VOID for this tip): the 3093-row corpus sweep, the 43 movers, the injection matrices.
cited (round 2, binary 0f3d5125 / f7b65d8c): the 373-slice e2e sweep (0 movers), scan_r5.py's 11 hits,
       post_measure_scan.py's 2-of-367, the vh_probe WeakVH measurement.
```

⚠ **Every gate line in this file that names `0f3d5125…`, `abe3e0ec…` or `7fe2bcbf…` is a fact about
THOSE binaries and is VOID for `4394b349…`.** The rows above are the ones re-taken.

---

# 16. BEADS TO FILE — for the ORCHESTRATOR. **Not filed by this agent** (the bd store is shared; one writer)

| # | class | title | evidence |
|---|---|---|---|
| 1 | **P1 over-ACCEPT / silent miscompile** | *the rail φ carrying a dtzb-mutated `cq_theta` result in place — `readerStalesItself` is the third GRANTING caller of `phiTracksWire` and the documented dtzb vocabulary gap is live* | §15.4 in full; probes `oa1`/`oa1t`/`oa1s`/`oa1u`/`oa1v`/`oa2`; the named missing clause `LoopLowering.cpp:2217-2236`; the red-green pair to write WITH the fix |
| 2 | **re-raise P3 → P1** | bd **`a3z7`** records the SAME structural fact as an EFFICIENCY divergence (*"the better circuit"*). It is not a better circuit; whenever the φ carries the OPERAND it is a DIFFERENT PROGRAM'S circuit. Attach the `oa1`/`oa1t` pair, or file #1 fresh and cross-reference `a3z7`. | §15.4 |
| 3 | cross-reference | bd **`0njv`** is the STRAIGHT-LINE sibling and is **distinct**: `oa1s` measures the straight-line spelling of this shape as handled CORRECTLY (out of place). #1 is loop-only. | §15.4 |
| 4 | over-DECLINE (residual, SAFE) | `if (i == 1)` — a guarded reader that runs once but not on the FIRST trip. Leg 1b proves *"false on every latch arrival"*, narrower than *"true on at most one iteration"*. Widening needs a monotonic-add-recurrence argument and its own Rule-13 round. | `fix_r2_probes/adv/a3_guard_eq1.ll`; §15.1 |
| 5 | capability (OWNER DECISION) | `cq_measure` as a wire event: reading **(a)** narrow vs **(b)** broad. (b) recommended and costed at **2 goldens, 0 shipped accepts, no ABI, no new symbol**. Retires F-D2-3's three over-declines and part of `3d8q`'s remaining population BY CONSTRUCTION. | §14 |
| 6 | test debt | the **F-C1B-2 REFUSAL direction** has no positive stream pin anywhere; three ways to restore it, none free. | §15.3 |
| 7 | `bd remember` | **when you add a caller to a shared predicate, read the callee's RETIREMENT TRIGGER and state which direction you use.** `WireWalk.h` named this exact shape, called it "NOT EXPLOITABLE", and instructed the next caller to *"WIDEN THE VOCABULARY (or fence the caller) IN THE SAME CHANGE"*. A third granting caller arrived, the argument behind "NOT EXPLOITABLE" did not reach it, and no one read the trigger. This is **L3's mirror** and it belongs beside L3 in CLAUDE.md. | §15.4 |
