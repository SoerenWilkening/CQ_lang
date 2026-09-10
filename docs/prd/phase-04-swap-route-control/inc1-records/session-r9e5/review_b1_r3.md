# Rule-13 adversarial review, ROUND 3 — bd `test_C_libtooling-r9e5` sub-increment 1b-B.1
## (the round-2 BLOCK fix: `RailCondReads` + `reverifyRailCondReads`)

Independent reviewer, 2026-09-11. Tree under review: branch
`3qlq-inc1b-b-rail-select`, checkpoint **a1e6d62** (= f8d29e8 + the F-B1R2-1 fix),
built in `build/`. I did not write this code and did not rebuild or edit anything
under `ir-pass/`, `tests/`, `tools/` or `build/`.

# VERDICT — **CLEAR-WITH-ITEMS**

**No new silent miscompile, no over-accept, and the BLOCK is closed.** I built
**54 fresh adversarial programs** (40 hand-IR, 4 plain-C single-TU, 10 two-TU) and
found **eleven fresh programs that are CONFIRMED silent miscompiles on the pre-fix
checkpoint f8d29e8 and DECLINE on this tree** — reaching all four recording sites
and all four consumers, including the two the fix report explicitly said it had no
program for (the Rz-stem **angle select**, and the **kickback** in plain C). Every
one of their controls (the same program minus the sibling) accepts on both binaries
with a **byte-identical** lowered module. The fix is **decline-monotone over the
whole corpus**: `corpusdiff.sh PRE` = **`SCANNED=1773 MOVERS=5`**, all five the
fix's own new decline fixtures, all `0 → 1`; the other **1768 fixtures are 0 RCDIFF
· 0 DIAGDIFF · 0 OUTDIFF**. I reproduced round 2's 73-probe corpus and round 1's
108-program corpus on this binary and both are **identical, line for line**, to the
fix agent's own records.

Three items, all DOC, none blocking:

| id | grade | one line |
|---|---|---|
| **F-B1R3-1** | DOC | the stage's placement argument ("after the round-2 fixpoint") is **not** what makes it sound: FOUR `taint.Tainted` mutations run AFTER it, two of them RAUW a previously-classical `load` onto a tainted value (the exact `Chained` input). Measured: neither opens the window — but for reasons that live in **two other files**, the F-B1R2-3 species again, and no retirement trigger is written |
| **F-B1R3-2** | DOC | `reverifyRailCondReads`' return value is discarded at both call sites and everything after the FIRST `diagnoseUnderControl` — the `Diagnosed` per-rail set, the loop continuation, the `bool` — is **vacuous**: the default LLVMContext handler `exit(1)`s inside `diagnose`. Measured (`r11`, two failing rails): exactly ONE diagnostic. The header's "LOUD AND FINAL … the emitted stream is discarded WITH the module" is a property of the HOST TOOL, not of the stage |
| **F-B1R3-3** | DOC | the re-ask seeds `{Rail}`; the classifiers seed a `condProvenance` **union**. For a rail leaf the two coincide exactly (`condProvenance` `continue`s at a theta call), so this is invisible today — but for a MIXED tree the compare leaf's wire is asked at round 1 and **not** re-asked, which is the `9pum` half arriving through a rail-bearing tree. I found **0 reachable programs** (`r38` declines `control flow` on both binaries); recorded as a sentence owed, not a hole |

One over-decline is INTRODUCED and it is **intended** (§5, `r29`): its ROUND-1 twin
`r30` declines on all three binaries, so the fix makes the round-2 window agree with
the shipped round-1 disposition rather than inventing a refusal.

---

## 0. What I ran, and only that (Rule 19)

* **54 fresh programs** in `review_b1_r3_probes/` — `ll/` **40** hand-IR modules,
  `c/` **4** plain-C programs at `clang -O1`, `multi/` **10** two-TU programs
  through the shipped 6.5 recipe (per-TU `-O1` IR → `llvm-link` → ONE
  `cq-lowering`). Runners `run.sh [PRE|PREB1|POST]` and
  `run_multi.sh [PRE|PREB1|POST]`; each probe is (clang) → `cq-opt
  -passes=cq-lowering` → `tools/free_pairing_check.py` (stage 2b, STRICT) → link →
  run. Verdict tables `VERDICTS_{,MULTI_}{POST,PRE_f8d29e8,PREB1}.txt`.
  `POST` = `build/ir-pass/{cq-opt,libCQPass.so}`; `PRE` = the saved **f8d29e8**
  pair (`scratchpad/fix_r2/pre`); `PREB1` = the pre-B.1 pair
  (`scratchpad/impl_b1/pre`).
* **Whole-corpus differential, run by me** (`review_b1_r3_probes/corpusdiff.sh`),
  `cq-opt` on **every** one of the 1773 `ir-pass/test/*.ll` on both binaries,
  comparing return code, stderr and stdout:
  * vs **f8d29e8** (the fix's own footprint): **`SCANNED=1773 MOVERS=5`** — the five
    new decline fixtures, all `RCDIFF(0->1) DIAGDIFF`; **1768 fixtures 0 RCDIFF · 0
    DIAGDIFF · 0 OUTDIFF**.
  * vs **pre-B.1** (the whole increment's footprint): **`SCANNED=1773 MOVERS=29`** —
    16 `RCDIFF(1->0)` (the capability), 3 `RCDIFF(0->1)`, 10 `DIAGDIFF`-only, and
    **all 29 have `rail` in their name** (`grep -cv rail` = 0).
* **Round 2's corpus re-run on this binary** — `review_b1_r2_probes/run.sh POST`
  (73 single-TU) and `run_multi.sh POST` (3 two-TU): **identical, line for line, to
  the fix agent's `verdicts_POST_fix.txt`** (the only `diff` hunk is a path prefix
  inside a shell error message). `multi/e16` — the plain-C two-TU CONFIRMED
  miscompile round 2 blocked on — DECLINES. `multi/e13` (the compare twin) still
  ACCEPTS with `ry(h2,.25); ry(h2,.9)` before its flag mint: **bd `9pum`, untouched
  and out of scope, exactly as declared.**
* **Round 1's corpus re-run** — `review_b1_r1_probes/run_corpus.sh POST`, 108
  programs: **identical** to the fix agent's record, 0 movers.
* I did **not** run the full `ctest` and make no claim about it.

---

## 1. The fix, re-derived

Two halves. `markRailCondRead(taint, Rail, FirstRead)` appends `(Rail, FirstRead)`
to `TaintSet::RailCondReads` at the EMISSION SITE; `reverifyRailCondReads(M, taint)`
runs once, in both entry points, immediately after `repropagateControlMerges`, and
re-asks rung (ii) (`railMeasuredBeforeReadPoint`) and rung (iii)
(`findNonDiagonalWireGate`, position-free then positional at the recorded read)
against the FINAL `TaintSet`, declining loudly with the round-1 strings.

**The three premises, checked one at a time.**

**(a) "The walker is blind to the emitted stream, so re-asking after emission is
sound."** Verified in source: the forward scan tests
`isCallToPrefix(CI, "cq_theta_")` and `isCallToPrefix(CI, "cq_phi_")`
(`WireWalk.cpp:498,531`), and every gate these emitters mint is `cqrt_*` or
`cq_template_*`, neither of which starts with `cq_theta_`; the scan's own guard
`CI->getArgOperand(0) != V → continue` reaches them and drops them. Rung (ii) reads
`taint.MeasureCalls`, which holds `@cq_measure_*` calls only and is untouched until
`lowerMeasures` (pipeline slot 559 ≫ 431). ✓

**(b) "The re-ask is the same two rungs, not a second spelling."** Verified: the same
two functions, the same `CrossValueRouting=true`, the same two-prong shape. The one
structural difference is the SEED — see F-B1R3-3 — and for a bare rail it is
*exactly* the classifier's set, because `condProvenance` stops at a theta call
(`ArmClassify.cpp:245`, `if (isThetaCall(I)) continue;`), so
`condProvenance(rail) == {rail}`. The EmitPoint also differs (`Read` vs `Sel`/`BI`),
and it differs in the **stricter** direction only where the emitter's insertion point
is later than the classifier's anchor — the Rz-stem angle select, where the classifier
asks about `Sel` and the two `cqrt_rz_i1` land at the consuming `cq_phi` `T`. I probed
that gap directly (`r20`: a chained theta between `Sel` and `T`) and it is closed
**by an independent fence** — `rotation angle` on BOTH binaries, the Inc-2b round-1
"gate-2c window half" — so the re-ask's stricter anchor is not load-bearing there and
costs nothing.

**(c) "Monotone toward decline."** Argued and measured. The re-ask can only ADD
declines relative to round 1: at final taint `findNonDiagonalWireGate`'s per-seed
backward closure crosses MORE tainted-parent edges, so it finds MORE forward users;
the `Exempt` (ancestry) set can only grow through **non-call** tainted parents
(`collectWireValues` does not cross a non-call parent — the bd `r903` narrowness), so
no `cq_theta_` call can move INTO `Exempt` and become newly harmless; and
`railWireNamesBackward`'s crossing only enlarges the measured-name set. Measured: 5
movers out of 1773, all `0 → 1`.

---

## 2. What I found the fix CLOSES that the fix report could not show

Eleven fresh programs, each **`opt` exit 0, verify-clean and STRICT-stage-2b
`0 violation(s)` on f8d29e8** — the signature of this project's whole hazard class —
and each declining on this tree. Every one is paired with a control that differs by
exactly one deleted line and accepts **byte-identically** on both binaries
(`diff` on `tail -n +4` of the two `-S` outputs: **14 of 14 accept modules
identical**).

| probe | shape | recording site it exercises | f8d29e8 | this tree |
|---|---|---|---|---|
| `ll/r01` | the rail is the select's CONDITION **and** its TRUE ARM (`g08` in the window) | `CopyRailRoot` cnot | ACCEPT, `ry(h5,.5); ry(h5,.9); cnot(h5,h7)` | DECLINE `predates` |
| `ll/r03` | `or i1 %b, %cmp` — a **NON-ROOT** rail leaf, kickback consumer | `emitCondNode` | ACCEPT 30 lines | DECLINE |
| `ll/r05` | the same as an `xor` tree (the 3c6m.67 node) | `emitCondNode` | ACCEPT 28 | DECLINE |
| `ll/r07` | the 4.3 NEST with the **INNER** level the rail (the fix report probed the OUTER one, `w5`) | `emitCondNode` (conjunction) | ACCEPT 26 | DECLINE |
| `ll/r09` | the **Rz-stem ANGLE SELECT** on a rail | `emitPhaseAngleSelect` | ACCEPT 19 | DECLINE |
| `ll/r17` | `e07`'s shape (sibling AFTER) inside a bounded LOOP — the back edge | `CopyRailRoot` cnot | ACCEPT 54, trip 2's `cnot(h5,h10)` after trip 1's `ry(h5,.9)` | DECLINE |
| `ll/r25` | **rung (ii)** (parent MEASURED) through the KICKBACK | `emitKickbackGroup` | ACCEPT 17 | DECLINE `measured before` |
| `ll/r26` | rung (ii) through the NEST | `emitCondNode` | ACCEPT 25 | DECLINE `measured before` |
| `ll/r27` | rung (ii) through the ANGLE SELECT | `emitPhaseAngleSelect` | ACCEPT 18 | DECLINE `measured before` |
| `ll/r34` | **two rail leaves in ONE node** (`and i1 %b, %d`), sibling on the second | `emitCondNode` (both `N.L` and `N.R`) | ACCEPT 24 | DECLINE |
| `ll/r36` | **one rail read by TWO nodes** (`(b&&p) \|\| (b&&s)`) | `emitCondNode` ×2 | ACCEPT 42 | DECLINE |
| `ll/r32` | the recorded read's block is folded away by a **ROUND-2** region's flatten before the stage runs | `CopyRailRoot` cnot, MOVED | ACCEPT 33 | DECLINE |
| **`multi/m06`** | **PLAIN C, two TUs** — the KICKBACK consumer's window (region rolled in a bounded loop so the rail branch gets its own block) | `emitKickbackGroup` | **ACCEPT 20**, `ry_i1(h5,0x1p-2); ry_i1(h5,0x1.ccc…p-1); rz_i1(h5,·)×3` | DECLINE |
| **`multi/m10`** | **PLAIN C, two TUs** — the ANGLE SELECT's window (`if (b) cq_phi(.9); else cq_phi(.3);`) | `emitPhaseAngleSelect` | **ACCEPT 19**, `ry_i1(h5,.25); ry_i1(h5,.9); rz_i1(h5,−0x1.333…p-2); rz_i1(h5,0x1.ccc…p-1)` | DECLINE |

Two of these matter beyond arithmetic. **`m10` is the plain-C program the fix report
said it looked for and did not find** ("I did not find a program that reaches the
round-2 window through it, and I did not fabricate one") — the Rz-stem angle select
IS reachable, in plain C through the shipped two-TU 6.5 recipe, and the site's
recording is therefore load-bearing rather than defensive. **`m06` does the same for
the kickback consumer**, which the fix report had only in hand IR (`w3`); the trick
is to roll the region inside a classically-bounded loop, which gives the rail branch
its own block and steps around the `w1`/`e09` "branch sits in the previous region's
merge block" `control flow` decline.

And `r32` is the direct answer to the brief's item 2: a `RegionFlatten` that folds
the recorded read's block **moves** the `cqrt_cnot` (LLVM merges blocks by moving
instructions), so the `WeakTrackingVH` still names it and the decline still fires.
The nulled-handle skip is not reachable by any erase I could construct: every
recorded read is a **void** `cqrt_*` call, which is never trivially dead, and the two
stages between emission and the re-verification (`collapseFlattenedLoopRails`,
`repropagateControlMerges`) merge and RAUW but do not erase emitted gates.

---

## 3. F-B1R3-1 — DOC: the placement argument is not the soundness argument

The stage's in-source header and both call-site comments say the slot is sound
because it runs "AFTER the round-2 fixpoint (nothing else makes the answer final)".
**That sentence is false as written, and the fix is sound anyway — for reasons
written in two other files.** Measured, by enumerating every `taint.Tainted` mutation
in `ir-pass/src` and locating each in the pipeline:

| stage | slot | mutation | can it change `Chained` for a rail? |
|---|---|---|---|
| `reverifyRailCondReads` | **431** | — | — |
| `lowerIOSinks` | 500 | `Tainted.insert(Out)` (`IOSinkLowering.cpp:413`) | **no** — `Out` is the tape-write's own result, RAUW'd onto nothing a `cq_theta` can name |
| `lowerQramReads` | 510 | `Tainted.insert(Out)` + `R.Load->replaceAllUsesWith(Out)` (`QramLowering.cpp:1801,1811`); `emitCopyOutIfDirectMeasure` `insert(Ret)` (`:1888`) | **RAUWs a `load` onto a tainted value — the exact `Chained` input** |
| `lowerShadowMemory` | 522 | `insert(Arr)` (`:2031`), `insert(Out)` + `A.MemOp->replaceAllUsesWith(Out)` (`:2106`) | **same** |
| `specialize` | 553 | `Tainted.insert(Site)` (`Specialization.cpp:1148`) **and `scrubForwardCone`** — a taint **SHRINK** | insert: "usually already present"; the shrink is unexamined by the fix's argument |

I attacked the two RAUW rows with programs rather than reading them.

* **QROM.** `ll/x01` is a `[8 x i1]` const-global table read at a tainted index, its
  `load i1` feeding two sibling `cq_theta_i1` and the first one conditioning a 4.4
  select — i.e. F-B1R2-1 with the window opened by `lowerQramReads` instead of by
  `repropagateControlMerges`. It **DECLINES on BOTH binaries**, and that is the
  measurement: the load is ALREADY tainted at round 1, because
  `propagateWorklist` taints **every user instruction** of a tainted value
  (`TaintPropagation.cpp:379-410`), so a tainted index taints the `getelementptr`
  and the `load` above it. `ll/x02` (the same minus the sibling) accepts and lowers
  the theta CHAINED onto `cqrt_qram_load_i1` — byte-identical on both binaries.
* **Shadow.** The only way to get a load of a quantum array that is classical at the
  stage is a **classical** index into an alloca-backed Shadow array. `ll/r12` is
  exactly that, and `QramLowering` refuses it outright:
  `cq QRAM store: alloca array mixes a tainted-index and a classical access`. An
  all-tainted-index Shadow array is pre-tainted by the same user walk as QROM.

So the window is closed — by `propagateWorklist`'s user edge and by `kMsgQramMixed`,
**neither of which the stage's argument mentions and neither of which is in this
file**. That is the same species as round-2's F-B1R2-3 ("the stop rule's ground is
another file's fence"), and it wants the same treatment: a written **retirement
trigger** at `reverifyRailCondReads` — *if `propagate` ever stops taking the
address-operand edge into a `load`, or if the Shadow mixed-access decline is
narrowed, this stage must move below `lowerShadowMemory`.* The `specialize` SHRINK is
worth one clause of its own: a scrub can only turn a theta that the ladder treated as
CHAINED into a SOURCE, i.e. split one assumed wire into two independent rails, which
is the safe direction for both rungs (the ladder's accept was about a wire that no
longer carries the gate) — but it is a taint change after the stage and nothing says
so.

---

## 4. F-B1R3-2 — DOC: everything after the first decline is vacuous

`reverifyRailCondReads` returns `bool`, keeps a `Diagnosed` set "once per rail", and
`continue`s so that other rails are still checked. **None of that runs.** Neither
`opt` nor `ir-pass/tools/cq_opt_main.cpp` installs a diagnostic handler, so
`LLVMContext::diagnose` falls through to the default printer, which `exit(1)`s on
`DS_Error`. Measured: `ll/r11` has TWO independent rails, each with its own round-2
sibling, and stderr carries **exactly one** `condition predates a non-diagonal gate`
line; the return value is discarded at both call sites (`CQLoweringPass.cpp:431,852`).

This is the house style for every decline in the pass and is **not** a defect. What is
worth one sentence is that the header's strongest claim —

> LOUD AND FINAL. `diagnoseUnderControl` is `DS_Error`, so `opt` exits non-zero and
> prints no module: the already-emitted stream is discarded WITH the module.

— is a property of the **host tool's default diagnostic handler**, not of the stage:
the stage itself takes no action to stop the pipeline from continuing to lower a
region whose ladder it just refused. Under any driver that installs a
`handleDiagnostics` returning true, the pass would run to completion over an emitted
region it declined. Say it as an assumption, and either drop the `bool`/`Diagnosed`
machinery or note in place that it is dead under `opt`.

---

## 5. Over-declines: one introduced, and it is the round-1 disposition arriving

`ll/r29` — two 4.4 selects on two SIBLING rails of one round-2 wire, with the second
sibling's Ry between the two control reads — accepted on f8d29e8 with a stream that
is **correct** (select 1's `cnot` fires before the `.9`, and select 2's after it,
which is what `%b` and `%b2` respectively name), and DECLINES here. I isolated which
read point refuses it: `ll/r31` (the same module minus select 2) ACCEPTS on both
binaries, so it is select 2 — its seed `%b2` sees the sibling `%b`'s Ry *before* its
own read, which the ladder refuses.

**It is not a new class.** `ll/r30` is the identical module with `%x = trunc i32 %q`
so the seed is tainted at ROUND 1, and it declines on **all three** binaries
(pre-B.1, f8d29e8, this tree). The fix is making the round-2 window agree with the
shipped round-1 disposition, which is precisely what the increment's own `e04`/`e05`
discriminator pair asks for. Prime-Directive correct; record it as a known
over-decline of the **rail ladder**, not of the stage.

**`ll/e07` re-derived independently — the accept is right.** The brief asked for this
and I did not read the fix agent's derivation until after. `%x` is a real register at
run time: at final taint it is a tainted `trunc`, so `lowerOps` mints
`cq_template_trunc_i32_to_i1(h_out) → h5`, a fresh rail. `%b = cq_theta_i1(%x, .5)`
is CHAINED, so it rotates `h5` **in place** and `%b`/`%x` are two SSA names for one
register in state `Ry(.5)|x⟩`. The select's `cqrt_cnot(h5, bf)` is emitted at the
select's position, i.e. **before** the sibling's `cqrt_ry_i1(h5, .9)` (`lowerRotations`
inserts each Ry at its own theta), so the copies are controlled on the label `%b`
names. `cq_measure(%b3)` then reads `Ry(.9)Ry(.5)|x⟩`, the label `%b3` names.
Source order, gate for gate; declining it would be an over-decline. Two variants
confirm the boundary is where it should be: `ll/r18` is the same shape through the
KICKBACK consumer (ACCEPT on both, byte-identical), and `ll/r17` is the same shape
inside a bounded loop, where the back edge makes "provably after every execution of
the read" false — it was a silent miscompile on f8d29e8 and declines here.

Two more over-decline controls I built and that behave: `ll/r19` (the STOP RULE in
the round-2 window — the rail's GRANDparent is round-2-tainted but its parent is an
out-of-place `xor` template, a different register: **ACCEPT on both, byte-identical**)
and `ll/x02`/`x03` (an opaque QROM seed that stays a genuine second register:
**ACCEPT on both, byte-identical**).

---

## 6. F-B1R3-3 — DOC: the seed narrowing, and the answer to the `9pum` question

`classifyPhaseKickback` builds ONE provenance set —
`condProvenance(each compare leaf) ∪ condProvenance(each rail leaf)`
(`ArmClassify.cpp:4255-4257`) — and hands it to `railCondWireDisposition`;
`classifySelectRegion` splits it into `CmpProv`/`RailProv` and asks the rail question
over `RailProv` (`SelectClassify.cpp:947`). `reverifyRailCondReads` asks over
`{Rail}` alone.

For a **bare rail** the two are equal, and the reason is exact rather than lucky:
`condProvenance` returns immediately at a theta call, so a rail leaf contributes
exactly itself. For a **mixed tree** the kickback's classifier asks the rail's
question over a set that also contains the compare's operand cone, and the re-ask
does not — i.e. a gate on the COMPARE's wire that only FINAL taint makes visible is
not re-verified. That is the `9pum` half; I built `ll/r38` to reach it (a mixed
`b && (y > 2)` whose compare sits on the `%out` wire with a chained theta before it)
and it declines `control flow` on **both** binaries, so I found **0 reachable
programs**. Recorded as a sentence owed at the stage, not as a hole.

**Can the record take compare seeds for `9pum` without a second stage?** The RECORD
generalizes unchanged: `markRailCondRead` is already `Value *`-typed, idempotent per
pair, appends, and a compare's read point (its `cq_template_icmp_*` flag mint) is as
good an anchor as a `cqrt_cnot`. The RE-ASK does not: a compare's two questions are
**different functions** — `condDataUseDisposition`'s `MeasuredEarly` rather than
`railMeasuredBeforeReadPoint`, and a **position-free-only** wire prong with
deliberately no DT half (`SelectClassify`'s prong (a): "the mint point is unrelated
to the compare's own schedule, so no positional accept is possible") — and its seed
is a SET (`condProvenance(Cmp)`), not one value. So `9pum` is a `Kind` field on the
entry plus a two-armed body inside the existing loop: an extension of this stage, not
a second one. **Nothing in this fix makes `9pum` harder**, and one thing makes it
easier: the entry is already a `pair<WeakTrackingVH, WeakTrackingVH>`, so a compare
seed needs no new lifetime story.

---

## 7. Areas probed and found nothing in (including the two round-2 "clean" rows I trusted least)

* **The four recording sites are ALL of them — attacked structurally and by program.**
  `grep -rn 'emitCondNetwork(\|emitCondNode(\|stripCondNetwork(' ir-pass/src` gives
  exactly three `emitCondNetwork` callers (`SelectMergeEmit:209`,
  `SwapRouteEmit:1622` flat, `SwapRouteEmit:1964/1983` nest) plus the nest's direct
  `emitCondNode(Conj, …, &taint)` at `:2020`. Every node emission reads BOTH children
  (`AND` → `toffoli(L,R,G)`; `OR` → `cnot(L,G); cnot(R,G); toffoli(L,R,G)`; `XOR` →
  the OR node minus its toffoli), so no node can read a rail through a gate the
  `record` lambda's `C->hasArgument(Ctl)` test misses. No node's FIRST emission is an
  inverse: `stripCondNetwork` runs after the forward network at all three sites, and
  the nest's `Inverse=true` call sits one line below its forward twin.
* **`stripCondNetwork`'s `cqrt_cnot(RailRoot, RailRootFlag)` (`CondTreeEmit.cpp:268`)
  is a genuine FIFTH read of the rail and is deliberately not recorded.** It is the
  strip of the same contiguous stream, at a later position with no user code between,
  so it answers identically — the fix report's §4 item 4 argument, which I re-derived
  and agree with. It is worth naming in that item, because it is the concrete instance
  of the "one rail, two read points" shape the item speculates about.
* **The `bracket()` `cqrt_x` on a user register.** `emitCondNode`'s `bracket()` is
  outside the `record` lambda, and a `cqrt_x` on a rail would break 1b's stated "NO
  `cqrt_x` ON A USER REGISTER, EVER" invariant and, worse, make
  `Uncomputation::preservesBorrowedParent` fail closed for every chain that borrows
  the register. It cannot fire: a negated rail leaf is not in the grammar. `ll/r14`
  (`and i1 (xor i1 %b, true), %cmp` under a branch), `ll/r15` (the same as a data
  select) and `ll/r16` (a bare `!b` select condition) all decline `control flow` on
  both binaries, and the 4.3 nest declines a negated rail LEVEL explicitly
  (`ArmClassify.cpp:4670`). ✓
* **The in-place `xor` BRIDGE on the SELECT path** — the round-2 §5 row I trusted
  least, one level over. The shipped ACCEPT fixture
  `control_phase_kickback_rail_inplace_xor_bridge.ll` rests on M-C's G6 refusing the
  in-place conversion "because the BRANCH reads `b` later"; the 4.4 select is ERASED
  by its own emitter at slot 377, long before M-C at 558, so by then the later "data
  use" is an emitted `cqrt_cnot`. Measured on all three orderings: `ll/r22` (xor
  before the select) and `ll/r24` (xor before, chained theta after) both emit
  `cq_template_xor_i1_hl` **out of place** with the rail untouched, and `ll/r23` (xor
  after the select) does fire `cqrt_xorc_i1(%h, true)` in place but **after** the
  region's two `cqrt_cnot`, so the read order is right. No `cqrt_xorc` ever precedes a
  control read. ✓
* **Clones** — the other round-2 row I trusted least. `c/p02` puts a bare `_Bool`
  rail and a 4.4 rail select inside a `noinline static` callee reached with a tainted
  argument: `cq specialization: callee contains a quantum primitive (cq_*)`, on both
  binaries. That matters because a rail read emitted inside a clone would be recorded
  into `cloneTaint.RailCondReads` — a DIFFERENT `TaintSet` that
  `reverifyRailCondReads(M, taint)` never reads — and because `specialize` runs at
  553, AFTER the stage. `lowerCloneSelect` `continue`s on any tree with
  `!Tree.RailLeaves.empty()` (`Specialization.cpp:288`) and `mintCondNetwork` iterates
  `Tree.Leaves` only, so there is no rail emission path there today; the decline above
  is what keeps it unreachable. **If a later increment ever admits a rail into a
  clone, the record's `TaintSet` and the stage's slot are both wrong for it** — worth
  a line in `SCOPE_B2.md`.
* **The other consumers.** A tainted-index GUARDED STORE under a bare rail
  (`c/p01`) declines `control flow`; a controlled RETURN / abort park under a bare
  rail (`multi/m03`) declines `bare i1 register condition`; the I/O sink path declines
  before `detectControlRegions` (round 2's `c/h01`, re-confirmed). `GuardedStoreArmEmit`
  and `AbortParkEmit` both `dyn_cast<CmpInst>(BI->getCondition())` before anything
  else (`:190/:226` and `:273/:345`), which is the structural reason.
* **The spine.** `Uncomputation::preservesBorrowedParent` clause (1) admits an
  uncontrolled `cqrt_rz_` on a borrowed parent BY NAME — which since 1b means a gate
  on a USER REGISTER, still sound (diagonal is diagonal) — while `cqrt_cnot` falls
  into the "everything else is a mutation" tail. So a chain borrowing a rail can
  discharge across a KICKBACK and not across a 4.4 SELECT. That is a **leak**, the
  Rule-6-safe direction, and it is round-2's pre-existing F-B1R2-4 family, not a new
  one. Every accepting probe I ran is STRICT stage-2b `0 violation(s), 0 unproven`.
* **Two rails in one module, two functions, a nulled handle.** The stage caches a
  `DominatorTree` per function and skips any entry whose two halves are not
  instructions of ONE live function; `r11` (two rails) and every two-TU probe exercise
  the first, and I could not construct the second (see §2 on `r32`).

---

## 8. What a round 4 should do

1. **Write the three DOC items into the source**, in the same style the increment
   already uses for F-B1R2-2/3: the retirement trigger for §3 at
   `reverifyRailCondReads`' header (naming `propagateWorklist`'s address-operand edge
   and `kMsgQramMixed` as the two facts the placement leans on), the host-handler
   caveat for §4, and the seed sentence for §6.
2. **Consider shipping `m10` and `m06` as fixtures.** They are the plain-C reach of
   the two recording sites the fix report could only argue — the angle select was
   explicitly unproven — and both are `clang -O1` + `llvm-link` reproducible with a
   4-line library TU. `r07` (the nest's INNER rail) and `r34`/`r36` (two rails in one
   node / one rail in two nodes) are the cheapest hand-IR additions; the currently
   shipped nest decline fixture covers the OUTER level only.
3. **`9pum` is now the only known live wrong unitary in this family** (`multi/e13`,
   plain C, two TUs, ACCEPT with `ry(h2,.25); ry(h2,.9)` before its flag mint, and
   byte-identical on every binary in this epic). §6 says what it costs.
4. **Assume a seventh thing.** Round 1: 4 items, 0 miscompiles. Round 2: 1 miscompile,
   from the area round 1 called probed-clean. Round 3: 0 new miscompiles in the tree,
   but **eleven** fresh programs that were miscompiles one commit earlier and that
   nobody had written down — including the site the fix report said it could not
   reach. The pattern to carry is not "the fix is complete", it is: **the same defect
   keeps being reachable through one more consumer than the last count**, and each
   round's list has been an undercount of the population rather than of the mechanism.
