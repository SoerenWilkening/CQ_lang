# Track D — FIX record for adversarial review round 1 (bd `3d8q`)

Round-1 verdict was **NOT CLEAR** (`$SES/trackD/REVIEW_D_R1.md`, 5 findings). This file records the
disposition of each, the measurements behind it, and the attack surface round 2 should start from.

**⚠ F-D1-1 was HELD mid-round and is now LANDED — OWNER RULING 2026-09-14: DECLINE.** The ruling was
made on this track's measurements and it reversed the analysis put to the owner (the re-preparation
reading was believed to need CLONING and therefore to be unrealizable; `r5f_inbody_fresh_mint.c`
refuted that, and the conditional-probability figures settled it). The measurement set is
`trackD/RULING_INPUT_D_R1.md`; `HELD_F-D1-1.patch` and `held_f_d1_1/` are kept as the record of what
was held and what was applied. See §"The ruling, landed" at the end of this file.

## Binaries

| tag | `cq-opt` sha256 | what |
|---|---|---|
| **O** ORACLE | `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc` | frozen session oracle, pre-increment (main checkout, READ ONLY) |
| **P** B8 | `7fe2bcbfb6c9712613952e6db33ab36dc3525275af99109cf0edfe4ea112fb23` | branch tip `e7d6efe2` as reviewed; **every gate line recorded against it is VOID for the tip below** |
| B9 | `33af613009b823e80ac1588a380fc12c32a230bf9395d50ea6de10cc8b94c758` | P + the reviewer's TRACED minimal F-D1-1 fix — **rejected, see §1** |
| B10 | `0f3d512529c5d1066fc82b38f21444efbe17088fe344a4c83f67cd2eee93c672` | P + the CORRECTED F-D1-1 fix — **this is what `HELD_F-D1-1.patch` contains** |
| **B11** | `abe3e0ecfdad39612e39940ce12195b3f1d2157b9b274d792a4a358efc8fc123` | **the new branch tip** — P + F-D1-2/3/4/5 + the accept fixture, F-D1-1 reverted |

`libCQPass.so` for B11: `00aa785c956db86d0cc2245a5fb4ed848449c4b19afdae40253b46681eb212cc`.

---

## F-D1-1 — the disqualifying over-ACCEPT. HELD, with a finding of its own

### The fix works, and the reviewer's spelling of it does not

The reviewer's traced minimal fix was *"grant the self-exemption only when `gateIsHarmless(I, I, Rec, …,
RequireEmitDominance=false)` holds"*, hand-traced through five families and explicitly labelled
**traced, not measured**. Built as B9 and measured, it closes the r5 family **and declines 12 shipped
Rule-13-cleared ACCEPT fixtures**:

```
ctest --test-dir build -R ir-pass-lit      # B9 33af6130: 1924 pass / 1 XFAIL / 14 FAIL of 1939
```

| verdict of the fixture | files |
|---|---|
| ACCEPT → now declines (**over-decline, 12**) | `control_angle_select_ry_lifted_phi_base`, `control_inplace_ry_inloop_two_exits`, `control_inplace_ry_lifted_phi_base`, `control_inplace_ry_stateprep_seq_then_chained`, `control_inplace_ry_stateprep_then_uncond_theta`, `control_inplace_ry_stateprep_warn_live_record`, `control_phase_kickback_mixed_claim_across_loops_leak_control`, `control_phase_kickback_mixed_onward_deadgate_leak_control`, `control_swap_accept_select_mergephi_rail_sdagger`, `lowering_live_record_mb_router_phi_accept`, `lowering_reject_live_record_anc_router_phi`, `lowering_reject_live_record_router_phi` |
| DECLINE → message moves to this fence (2) | `lowering_uncompute_loop_backedge`, `lowering_uncompute_loop_backedge_irreducible` |

**ROOT CAUSE, and it is one line of LLVM.** `gateIsHarmless`' leg 1 is
`isPotentiallyReachable(T, EmitPoint)`, whose LLVM 19 implementation opens
`if (A == B || A->comesBefore(B)) return true;`. With `T == EmitPoint` it therefore answers **TRUE by
identity**, never short-circuits, and EVERY self-gate falls into leg 2 — which refuses outright when
the seed is not an Instruction or is a non-wire-tracking φ. Ten of those twelve fixtures have a reader
that **cannot execute twice at all** (`control_inplace_ry_inloop_two_exits`' `%21 = cq_theta(%12,.3)`
sits in an exit block; `%12` is an identity-carry φ, so `phiTracksWire` refuses and the fixture
declines for a back edge the reader never crosses). The reviewer's own trace table predicted
*"straight-line chain → `isPotentiallyReachable(I,I)` false → leg 1 → ACCEPT"*, which is the step that
does not hold.

### The corrected fix — `WireWalk::readerStalesItself`, ONE new owner, no new relation

```cpp
bool readerStalesItself(const CallInst *R, Value *Seed, const DominatorTree &DT) {
  SmallPtrSet<const Instruction *, 1> NoBarrier;
  if (!reachesWithoutBarrier(R, R, NoBarrier))
    return false;                        // (1) `R` cannot execute a second time at all
  return !recordBarrierCutsPath(R, R, Seed, ArrayRef<Value *>(Seed), DT);  // (2) leg 2 verbatim
}
```

Leg (1) is the walker's own exact walk, which starts at `std::next(R)` and therefore cannot match by
identity — the non-degenerate form of the question leg 1 was being asked. Leg (2) is
`gateIsHarmless`' leg 2, **split out unchanged** (`recordBarrierCutsPath`) so both callers share one
implementation; `gateIsHarmless` keeps its exact previous behaviour and its call site is
byte-unchanged. Rule 14: no second spelling of either leg, and the question "can this reader stale
itself?" gets the one owner it never had.

> ⚠ **ERRATUM 2026-09-14 (Rule-13 round-2 finding F-D2-5), and it corrects the reviewer's count as
> well as mine.** This sentence originally read *"every one of its **17 call sites** is
> byte-unchanged"*, which conflated two different populations. Re-measured on the tip, with the
> command:
> ```
> grep -rn "gateIsHarmless" ir-pass/src ir-pass/include              # 1 call + 1 definition + prose
> grep -rn "findNonDiagonalWireGate(\|collectNonDiagonalWireGates(" ir-pass/src ir-pass/include \
>   | grep -v WireWalk                                               # 18 lines
> ```
> * **`gateIsHarmless` has exactly ONE call site** — `ir-pass/src/WireWalk.cpp:812`, inside
>   `walkNonDiagonalWireGates`. It is `static`-by-anonymous-namespace and nothing outside this file
>   can reach it. The substance of the claim stands (it is behaviourally byte-unchanged, and the
>   reviewer verified that independently by diffing the extracted pre-split body); only the number was
>   wrong, and a future agent grepping for "17 `gateIsHarmless` call sites" would have found one.
> * **The 17 belongs to the WALKER'S PUBLIC FACES.** `findNonDiagonalWireGate` /
>   `collectNonDiagonalWireGates` occur on **18** lines outside `WireWalk.*`; **one of those 18 is
>   PROSE** (`ArmClassify.cpp:2783`, a comment), so there are **17 code call sites**, and **one of the
>   17 is this increment's own new reader call** (`OpcodeLowering.cpp:518`) — leaving **16
>   pre-existing**. The round-2 review said "18 external call sites"; that count includes the comment
>   line. Both corrections are recorded because the honest number is the one someone can re-derive.
> * Round 2's own non-findings table row *"`gateIsHarmless` and the 17 call sites byte-unchanged —
>   VERIFIED, empty diff"* remains true of the files it diffed
>   (`ArmClassify`/`RegionTreeDetect`/`SelectClassify`/`SwitchArmProve`/`SwitchClassify`/`LoopLowering`);
>   it is the LABEL on the number that moves, never the verification.

Measured, B10 `0f3d5125`:

```
ctest --test-dir build -R ir-pass-lit     # 1934 pass / 1 XFAIL / 4 FAIL of 1939
```

The 12 over-declines are gone. The **4 remaining failures are all the r5 shape itself**, in shipped
fixtures — which is a finding, not a residue:

| file | why it fails | what it contains |
|---|---|---|
| `control_phase_kickback_mixed_onward_deadgate_leak_control.ll` | ACCEPT → D | `%20 = cq_theta(%3,.1)` in the loop body; `%3` is minted in ENTRY. ⚠ This increment's own §8 edit note already said *"the gate's arg-0 is still the loop-invariant name, so there is still no header φ"* |
| `control_phase_kickback_mixed_claim_across_loops_leak_control.ll` | ACCEPT → D | `%27 = cq_theta(%9,.2)` in the SECOND loop; `%9` is defined in the FIRST loop's body |
| `lowering_uncompute_loop_backedge.ll` | D → D, message moves | `%p = cq_theta(%h,.1)` in the body, `%h` in entry — **already declines on the ORACLE**, at `cq uncompute: tainted handle live range crosses a loop backedge` |
| `lowering_uncompute_loop_backedge_irreducible.ll` | D → D, message moves | same shape, irreducible CFG |

**So the r5 shape is present in FOUR shipped fixtures, two of which already decline for another
reason.** That materially changes the "population" input to the ruling and is written up in
`RULING_INPUT_D_R1.md` §(d).

### The r5 family, before and after, on three binaries

`fix_r1_probes/m3.sh` (stage 1 generated once, fed to all three; zero-byte modules refused).

| probe | O | P (B8) | B10 (corrected fix) |
|---|---|---|---|
| `r5_inloop_invariant_seed` | A 8 | A 8 | **D** |
| `r5a_while_runtime_trip` | A 8 | A 8 | **D** |
| `r5b_invariant_template_seed` | A 9 | A 9 | **D** |
| `r5d_invariant_seed_measure_only` | A 6 | A 6 | **D** |
| `r5h_inner_loop_outer_mint` (new) | A 12 | A 12 | **D** |
| `r5c_invariant_two_siblings` | A 15 | D | D |
| `r5e_nested_invariant` | A 10 | D | D |
| `r5f_inbody_fresh_mint` (new — seed minted IN the body) | A 12 | A 12 | **A 12** |
| `r5g_inloop_measure_only` (new — no gate in the loop) | A 5 | A 5 | **A 5** |
| `r5i_outer_mint_inner_chain` (new — inner loop carries the chain) | A 12 | A 12 | **A 12** |
| `r5t_selfassign_twin` | A 8 | A 8 | **A 8** |

The four new probes are the over-decline boundary the fix must not cross, and it does not: the
predicate is exactly *"the reader can re-execute AND its record's definition does not re-execute with
it"* — `CLAUDE.md` CORRECTNESS RISK §2's rail-staleness rule, verbatim.

---

## F-D1-2 — the `WeakTrackingVH` drain: FIXED, three outcomes, none silent

The record is now `SmallVector<WeakVH, 4>` and the **choice of handle is the fix**. LLVM 19's two
nullable handles differ on exactly the reviewer's point (`llvm/IR/ValueHandle.h`): `WeakTrackingVH`
*"tries hard to point to a Value, even across RAUW"*; `WeakVH` *"points to a value, and nulls itself
out if that value is deleted"*. The drain's question is **"is the reader INSTRUCTION still in the
module?"**, never "what is its result now" — a reader whose result was replaced is still an
instruction that still reads a stale name and still lowers to a gate. So:

1. **alive and an instruction in a block** → DECLINE on it (correct anchor whether or not it was
   RAUW'd — this is the case that used to be dropped);
2. **null** → the reader was DESTROYED, i.e. an owner claimed and proved the shape → skip (unchanged,
   and the case the shipped comment described);
3. **alive but not an instruction in a block** → `report_fatal_error`, never a `continue`.

Outcome 3 is unreachable under the documented `WeakVH` semantics, which is exactly why it is fatal
rather than silent. ⚠ **Stated as the reviewer would want it: the handle semantics are read off the
LLVM 19 header, not measured** — I could not construct a reaching RAUW either. The fix is correct
under **both** readings: if `WeakVH` did follow RAUW, outcome 3 becomes reachable and is LOUD instead
of silently dropped. The three comment blocks that claimed "a nulled entry is the only other case"
are rewritten.

## F-D1-3 — the header that contradicted the code: FIXED

`TaintSet::StaleQuantumReaders`' block claimed a round-2 residual the code CLOSES and forbade the
delta re-ask the code SHIPS. Replaced with the delta-scoped design: the true half is kept (*a **FULL**
re-sweep after the fixpoint is not the fix — `lowerLoops` has already collapsed the rail φ, and 9
shipped in-loop ACCEPTS flip*), the false half is gone, and the delta's soundness argument is written
out with its three sub-cases (see F-D1-5).

## F-D1-4 — `diagnosePreLoopCommitStale` vacuity: NARROWED, and the enumeration is now honest

Measured, unchanged by this round: the string is carried by **8 fixtures, all as `-NOT`, 0 positive
`CHECK`**. I did **not** restore a positive pin. What I did instead is split the shipped plausibility
argument into what is proven and what is not, in the fixture header:

* **(a) an extra use of the RAUW'd wire** (the F-C1C-1 mode) — **SUBSUMED, and now by an exhaustive
  enumeration rather than a plausibility argument**: the extra use is an LLVM `User` of a TAINTED
  value, and every kind has an owner that runs before `lowerOps` — reader
  (`declineRecordedStaleQuantumReaders`), pure op (`declineStaleRecordOps`), escape/call argument
  (`declineTaintEscapes`), branch/select CONDITION (the `ArmClassify` condition-wire dispositions), or
  `phi`/`select` data mux (`declineClassicalMuxes`). There is no sixth kind.
* **(b) the classical immediate that stopped being classical** — the reviewer's named gap. **NOT
  subsumed.**
* **(c) the CFG/dominator/loop structure changed** — `RegionFlatten` erases the diamond a G5/G6/G7
  clause was proven over. **NOT subsumed**, and I add it: the reviewer named (b) only.

(b) and (c) are structurally reachable, and the ORDER is the reason:
`commitOutOfLoopInPlaceOps` predicts inside `lowerLoops` (`CQLoweringPass.cpp:393`), which runs
**before** `detectControlRegions` (:475, which rewrites the CFG) and **before**
`repropagateControlMerges` (:509, which grows the taint set); `lowerOps` re-verifies ~300 lines later.
So the tripwire is subsumed **for (a) only** — that is the precise statement of what is unpinned, and
the (b)/(c) construction is what any replacement fixture must be. Filed as a follow-on.

## F-D1-5 — the Delta scope's routing sub-case: RECORDED with the argument

Written into `TaintSet::StaleQuantumReaders` and cross-referenced at the `Delta` filter itself. The
enumeration of what round 2 can add to a reader's closure: (a) a direct reader of the newly-tainted
parent — in the delta, hence analysed; (b) a gate behind another gate — a CHAIN the round-1 FORWARD
walk already reaches with no taint-gated hop; (c) **a gate behind a `phi`/`select` ROUTING node** —
the one residual, whose closure is carried by `declineClassicalMuxes` (heterogeneous tainted mux →
refused) and by the one-register merge-φ lift (homogeneous → same register, same wire). ⚠ That is an
**L3 coupling**: a second predicate now names part of this fence's obligation, so it carries a
RETIREMENT TRIGGER — if `declineClassicalMuxes` is ever widened to admit a heterogeneous tainted mux,
this delta scope must be re-derived.

## Minor — the folded-angle-select `!dbg` reports column 0: MEASURED, not this fence's defect

`r23_angle_select_stale_base.c:4:0`. The reader is `%6 = call @cq_theta_si32(i32 %2, double %5),
!dbg !24`, and in the **stage-1** module `clang -O1` itself emitted
`!24 = !DILocation(line: 4, scope: !10)` — **no column field at all**, because `-O1` folded the two
arms' thetas into one call with a `select` on the angle (the drbq Inc 2b fold) and merged their
locations. `getDebugLoc().getCol()` therefore returns 0 for ANY diagnostic anchored on that
instruction, this fence's included. Nothing to fix in the pass; recorded so it is not re-found.

## Deviation — `g2_measure_parent` stays a DECLINE

Adjudicated in the implementer's favour by the reviewer and confirmed by the coordinator. Kept, not
reverted. Measured on the tip: `r9_g2_measure_parent` D, `r9b_g2_pureop_twin` (the identical wire
question spelled as a pure op) D **on the ORACLE too**, `r8_tip_measure_twice` / `f1w2` A 6 unchanged.

---

## Fixtures

| file | verdict | state |
|---|---|---|
| `lowering_stale_reader_inloop_selfassign_accept.ll` | ACCEPT | **LANDED** — accepts on B8 **and** B10, so it is correct under either ruling. Pins the φ-carried in-loop chain, which no fixture pinned before. |
| `lowering_reject_stale_reader_inloop_invariant_seed.ll` | DECLINE | **HELD** in `held_f_d1_1/` — it is the F-D1-1 disposition and cannot land before the ruling. Green on B9 and B10 (`lit --filter 'stale_reader'` 11/11). |

The two differ by ONE edge (the reader's arg-0 is the header φ vs the loop-invariant preheader mint)
and, on the pre-fix compiler, emit the SAME STREAM. Both dispositions of the shape were unpinned
before this round, which is how F-D1-1 shipped.

---

## Gate lines — `ran:` vs `cited:`

⚠ Every gate line in `GATES.md` recorded against `7fe2bcbf` is **VOID for the new tip**. The table
there now carries B9/B10/B11 explicitly.

**ran: (this agent, this round)**

```
ran: cmake --build build -j8                       | B9  33af6130 | exit 0
ran: cmake --build build -j8                       | B10 0f3d5125 | exit 0
ran: cmake --build build -j8                       | B11 abe3e0ec | exit 0
ran: ctest -R ir-pass-lit                          | B9  33af6130 | 1924 pass / 1 XFAIL / 14 FAIL (of 1939)
ran: ctest -R ir-pass-lit                          | B10 0f3d5125 | 1934 pass / 1 XFAIL /  4 FAIL (of 1939)
ran: ctest -R ir-pass-lit                          | B11 abe3e0ec | see GATES.md
ran: lit --filter 'stale_reader'                   | B10 0f3d5125 | 11/11 PASS
ran: fix_r1_probes/m3.sh, r5 family (11) x3 bins   | O/P/B10      | table above
ran: fix_r1_probes/m1.sh, all 60 probes            | B11          | table in GATES.md
```

Three full `ir-pass-lit` runs are **not** redundant under PROTOCOL: a gate result is a fact about a
BINARY, and these are three different binaries answering three different questions (does the traced
fix hold? does the corrected fix hold? does the landed tip hold?).

**cited: for the OLD binary `7fe2bcbf` only — NOT re-run, and must not be read as facts about B11**

```
cited(B8 only): corpus sweep ORACLE-vs-SUBJECT      | 3093 rows, 43 movers, 0 in e2e/
cited(B8 only): injection matrix, 3 new accepts     | 36 mutations, 0 MISSED
cited(B8 only): injection matrix, 2 edited accepts  | 24 mutations, 8 MISSED (identical on the ORACLE ⇒ pre-existing)
cited(B8 only): duplicate-body fixture scan         | 9 groups, all pre-existing
cited(B8 only): !dbg anchor check, 7 -g probes      | 7/7 real file:line:col
cited(B8 only): ctest -R '^e2e-loop-twin-matrix$'
```

**NOT run, deliberately** (brief): no corpus sweep (one per session, the merge gate's), no full
`ctest`, no `^e2e-`, no `cq-opt-equivalence-full`, no twin matrix. ⚠ The group gate still owes
`cq-opt-equivalence-full` — this track moved an analysis site.

---

## Attack surface for round 2 — FRESH, not a repeat

1. **`readerStalesItself` leg (1) passes an EMPTY barrier set to `reachesWithoutBarrier`**, whose own
   header documents two vacuity traps. Neither applies (both need a barrier), but the walk's *"`From`'s
   own block is entered mid-way, so a back edge that re-enters it from the top is a genuinely
   different traversal"* rule is now load-bearing for a NEW question. Probe: a **single-block loop**
   containing the reader; an **irreducible** cycle (`lowering_uncompute_loop_backedge_irreducible.ll`
   is one and it moves — check it moves for the right reason); a reader in a block reachable from
   itself only through an `indirectbr`.
2. **`readerStalesItself` adds a new CUSTOMER to `phiTracksWire` in the GRANTING direction.**
   `WireWalk.h`'s own retirement trigger says the dtzb vocabulary gap (`phiTracksWire` counts a
   `cq_theta` as a staler and does NOT count the dtzb in-place `add`/`xor` that
   `LoopLowering::collectRailGates` does) becomes live when a new granting caller appears. Probe: a
   φ-carried in-loop chain whose wire moves by an in-place `add` between the incoming and the back
   edge — the φ would be granted a refresh it did not earn, and the self-exemption with it.
3. **The drain's outcome (3).** `WeakVH`'s non-tracking semantics are read off the header, not
   measured. Construct an emitter that RAUWs a recorded reader's result while KEEPING the call (M-β
   RAUWs a merge φ to the theta CALL, which is the near miss); then decide whether
   `report_fatal_error` or a `DiagnosticInfoUnsupported` is the right surface.
4. **F-D1-4 (b) and (c)** — a program that reaches `diagnosePreLoopCommitStale` with NO stale reader,
   via a taint-growth event on the in-place op's immediate, or via a `RegionFlatten` CFG rewrite
   between `lowerLoops` and `lowerOps`. That program is the missing positive pin.
5. **The measurement sink is not modelled as a wire event at all.** `cq_measure` is not a
   non-diagonal gate to the wire walk, so `for (…) s += cq_measure(q);` (`r5g`, A 5) and
   `int m = cq_measure(q); int a = cq_theta(q,.5);` (`r1`, A 5) both compile — yet a measurement
   COLLAPSES the register, so every later name for it denotes a state it no longer has in
   superposition. If `docs/frontend.md` §3.2's linear rule consumes a measured name, those are the
   same defect class as `g2_measure_parent` and nothing asks about them. This is the boundary the
   whole F-D1-1 ruling sits on and it is currently unexamined in BOTH directions.
6. **Two shipped ACCEPT fixtures contain the r5 shape** (§1). Whatever the ruling, they need a
   written adjudication: under DECLINE they must be re-spelled or inverted with a retirement trigger;
   under ACCEPT they are evidence that the shape is load-bearing in the corpus and the `1 → 2`
   discontinuity (one reader compiles, two decline — `r5c`/`r5e` decline on B8 **today**) becomes a
   ruling of its own.


---

## The ruling, landed (2026-09-14)

**OWNER RULING: DECLINE.** The in-loop read of a loop-INVARIANT quantum name is ambiguous between two
realizable circuits and names neither, so it declines. The (b) finding stands with it: the immediacy
distinction is about VISIBILITY, not validity, so the loop case belongs with the straight-line one.

Landed: `WireWalk::readerStalesItself` — leg 1 asked non-degenerately from `std::next(R)` via
`reachesWithoutBarrier`, leg 2 verbatim through the split-out `recordBarrierCutsPath`;
`gateIsHarmless` and its ONE call site byte-unchanged (⚠ this read "all 17 of its call sites" — see
the F-D2-5 ERRATUM above: `gateIsHarmless` has exactly one, `WireWalk.cpp:812`; the 17 is the walker's
public faces). The LLVM fact that kills the reviewer's
spelling (`isPotentiallyReachable(A,B)` opens `if (A == B || A->comesBefore(B)) return true;`, so it is
true BY IDENTITY) is now recorded in THREE places, including at `gateIsHarmless`' leg 1 itself, where
the next person would otherwise simplify it back.

### The four fixtures converted, each deliberately and in writing

| fixture | was | now | what the header records |
|---|---|---|---|
| `control_phase_kickback_mixed_onward_deadgate_leak_control.ll` | ACCEPT+LEAKS | **DECLINE** (this fence) | The subject was *an UNCARRIED in-body gate on an unclaimed rail* — and "uncarried" IS "loop-invariant arg-0", so subject and ruled-out shape are the same thing and the pin cannot be preserved by any edit. ⚠ Its own 2026-09-14 note already said *"the gate's arg-0 is STILL the loop-invariant `%3` so there is still NO loop-carried header φ"* — the shape was known, and unruled, in this very increment. MEASURED: 19 other ACCEPT fixtures still carry a zero-`and_hl_unc` pin, and the one-token CARRIED sibling `control_phase_kickback_mixed_onward_inloop.ll` still ACCEPTS. |
| `control_phase_kickback_mixed_claim_across_loops_leak_control.ll` | ACCEPT+LEAKS | **DECLINE** (this fence) | The subject was F-C1B-2's per-loop `ClaimedRailRoots` key, which needs LOOP B to gate a root LOOP B did not claim — i.e. a loop-invariant re-read. Inseparable from the ruled-out shape. MEASURED: the discriminating ACCEPT half `..._claim_across_loops_accept_control.ll` still ACCEPTS; what is lost is the REFUSAL direction's only positive pin — filed. Its header also records that its HAND-UNROLLED twin declines on every binary in the epic, so the ruling CLOSES a rolled/unrolled disposition split rather than opening one (the `l1`/`l1u` pattern). |
| `lowering_uncompute_loop_backedge.ll` | DECLINE (`cq uncompute: tainted handle live range crosses a loop backedge`) | **DECLINE, message moves to this fence** | `%h` minted in ENTRY, `%p = cq_theta(%h,.1)` in the body: the ruled shape, and it always was. `recordStaleQuantumReaders` is diagnosed far earlier than the uncompute spine and `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`). MEASURED, so the uncompute fence is NOT left unpinned: `lowering_reject_loop_nested_quantum.ll` and `lowering_uncompute_leak_irreducible_dead_spine.ll` still decline at that string with positive `CHECK`s. |
| `lowering_uncompute_loop_backedge_irreducible.ll` | same | **same** | same, irreducible CFG. |

Each carries an **L8 retirement trigger naming the ruling by date**, and each pairs its own inversion
with `lowering_reject_stale_reader_inloop_invariant_seed.ll`'s — "do not move one without the other".
The two ACCEPT→DECLINE files keep their entire original header and every original directive, NEUTERED
(`CHECK` → `[check]`, and every `--check-prefix` name likewise) so FileCheck cannot see them.

### The ruling's own pins — four fixtures, and nothing pinned any of this before

| fixture | verdict | spelling |
|---|---|---|
| `lowering_reject_stale_reader_inloop_invariant_seed.ll` | **DECLINE** | the ambiguous spelling — THE ruling |
| `lowering_stale_reader_inloop_selfassign_accept.ll` | ACCEPT | the ALIAS reading, `q = cq_theta(q,.1)` — one rail, chained |
| `lowering_stale_reader_inloop_fresh_mint_accept.ll` | ACCEPT | the RE-PREPARATION reading, the mint moved into the body — a fresh rail per trip |
| `lowering_stale_reader_postloop_measure_accept.ll` | ACCEPT | the φ-carried post-loop read (pre-existing) |

The first three are a one-edge family: they make the decline a **two-token fix rather than a lost
capability**, which is the half of the ruling that keeps it from being an over-decline.
