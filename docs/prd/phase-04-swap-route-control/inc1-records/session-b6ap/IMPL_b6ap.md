# IMPL — bd `test_C_libtooling-b6ap`: THE MULTI-PHI MERGE PEEL

Implementation record, session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-11. Worktree
`/Users/sorenwilkening/Desktop/CQ_b6ap`, branch `merge-phi-peel`, from `main`
`0c7380c`. **NOT COMMITTED, NOT PUSHED.** Every A/B figure below is measured
against the frozen ORACLE `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass`
(`main` `0c7380c`, never rebuilt or written to).

Read `BRIEF_b6ap.md` and `SCOPE_b6ap.md` first; this file records what was
BUILT, what was MEASURED, and where the shipped predicate differs from SCOPE §3.

> ⚠ **THIS FILE RECORDS THE HAND-BACK TREE. The Rule-13 round-1 review
> (`review_b6ap_r1.md`) returned BLOCK on it and the fixes are in
> `FIX_b6ap_R1.md` — read that alongside this one.** Two things here are
> SUPERSEDED and are corrected in place below rather than deleted: **D1's stated
> reason** (§2 and §7 Q1 — the f64/angle framing is withdrawn; see the dated ⚠
> block) and the **containment argument's guarded-store bullet** (§3's "every site
> declines today" — true, and insufficient: `classifyGuardedStoreArm`'s decline keys
> on the very φ the peel deletes, so a new clause **P10** now refuses any site whose
> ARM writes memory). And one thing here was INCOMPLETE rather than wrong: the peel
> GROWS TAINT, and the stages that adjudicate consumers of tainted values had already
> run — five plain-C consumer classes escaped at `opt` exit 0 (finding F-B6-1). The
> peel now reports its delta and the caller hands it to `adjudicateTaintDelta`. The
> fixture family is **38**, not the 25 counted in §3.
>
> ⚠ **AND THE ROUND-2 REVIEW (`review_b6ap_r2.md`, CLEAR-WITH-ITEMS) THEN FOUND THAT
> THE ROUND-1 FIX'S OWN ENUMERATION WAS ONE SHORT** — `foldIdentityBitcasts` is a
> FIFTH taint-delta consumer (F-B6R2-1, an OVER-decline, hand-IR only), and
> `declineStaleRecordOps` over the delta — recorded at round 1 as having no
> constructible customer — HAS one from plain C (M-D). Both are answered in
> `FIX_b6ap_R2.md`; the new material in THIS file is **§2c** (the 15-row pre-peel
> stage table, zero HOLE rows), **§2d** (the φ-consumer audit for the round-3
> question) and **§2e** (M-D's customer + the five-mutant table). Read
> "`adjudicateTaintDelta` is four calls" anywhere below as **five**.

---

## §0 — measured BEFORE writing any code

Three facts were re-measured on the oracle before touching the tree, because the
whole design rests on them:

1. **The flagship declines for a bookkeeping reason.** `p09_owner_int` (the
   owner's file with `int b0`/`int b1`) at `-O1` hands the pass one diamond whose
   merge holds two phis; `CQ_CTRL_DBG=1` anchors the decline at
   `br i1 %2, label %5, label %3` with `control flow`. Confirmed by reading
   `ControlDetect.cpp:240` (`soleMergePhi`'s `if (Found) return nullptr`) and
   `:352` / `:583`.
2. **Every accepting hand peel in `probes/` still accepts on the oracle**
   (`h09c`, `h09d`, `h30`, `h31`, `h60`, `h61`, `h71`, `h80`, `h87c`, `h87d`,
   `h87f`) and every declining one still declines with the string the README
   records. So the probe family is a valid baseline for this tree.
3. **No classifier can claim a `>= 2`-phi merge today**, read out of the source:
   all three `recoverRegion` recognizers go through `soleMergePhi`;
   `classifyPhaseKickback` admits merge phis in `{none, ONE angle tail}` and
   `phaseAngleTail` (`ArmClassify.cpp:3766`) itself returns false on a second phi;
   `classifyGuardedStoreArm` LOUD-declines on any merge phi
   (`GuardedStoreArmEmit.cpp`, `"guarded store with a merge value"`);
   `classifyAbortPark` needs an `unreachable`-terminated arm, so
   `uncondSucc(arm)` is null; `lowerControlledIOSinks` demands
   `NumPhis == 0 || ValuePhi` (`IOSinkLowering.cpp:609`) **and** runs before this
   stage. That is the containment argument, and it is why the shipped predicate
   has a `>= 2`-phi entry gate (§2, deviation D1).

---

## §1 — THE STAGE, and all three call sites

New file `ir-pass/src/MergePhiPeel.cpp` (+ `ir-pass/include/MergePhiPeel.h`),
added to `ir-pass/CMakeLists.txt`'s `CQPass` source list (`cq-opt` inherits the
list via `get_target_property`, so both targets get it).

```
bool cq::peelIndependentMergePhis(llvm::Module &M, TaintSet &taint);
```

Accept-only: it never calls `diagnoseUnderControl`. A shape failing any clause is
left byte-untouched for its existing loud owner.

**THE RULE, and it is grep-checkable: the peel is called immediately before EVERY
`detectControlRegions` call in the tree.** There are exactly three, and there are
exactly three calls:

| # | call site | round |
|---|---|---|
| 1 | `ir-pass/src/CQLoweringPass.cpp:451` (in `run`, immediately before `:455`) | 1 |
| 2 | `ir-pass/src/CQLoweringPass.cpp:929` (second entry point, before `:933`) | 1 |
| 3 | `ir-pass/src/TaintPropagation.cpp:1430` — **INSIDE** `detectAndLowerOnwardControl`'s `while (true)` fixpoint, before `:1431` | 2, 3, … |

```
$ grep -rn "detectControlRegions(M, wd, taint)" ir-pass/src/   # 3 hits: 455, 933, 1431
$ grep -rn "peelIndependentMergePhis(" ir-pass/src/            # 3 call sites + 1 definition
```

> ⚠ **LINE NUMBERS IN THIS FILE MOVE.** The three above are this tree's AFTER the
> round-2 fix; the hand-back tree read 416 / 887 / 1409 and the round-1 fix tree
> 441 / 919 / 1421. The COMMENTS that carry the rationale moved them, not the
> code. Re-grep rather than trusting a number here; the invariant is the RULE
> (peel immediately before every `detectControlRegions`), which is grep-checkable
> by shape and not by line. The round-2 fix also changed the grep string: the
> call now passes a `Delta` argument, so `"peelIndependentMergePhis(M, taint)"` —
> the string the hand-back recorded — matches NOTHING.

**Site 3 is INSIDE the loop, not before it**, which is a deliberate deviation
from SCOPE §8's spelling (i): `detectAndLowerOnwardControl` is a FIXPOINT — a
control emit can expose a further onward control — so a call placed before the
loop would cover only its first iteration. Placing it at the top of the loop
gives the uniform, statable rule above; SCOPE §8 itself asks for "whichever
spelling makes the peel impossible to skip".

**Slot rationale (written at call site 1):** after the PredMux fixpoint, before
`detectControlRegions`. NOT before PredMux — both of PredMux's own W5 and W7
witnesses require `NumMergePhis == 1` (`PredMuxFlatten.cpp:2317` / `:2468` IN
THIS TREE; SCOPE §2 cites `:2286` / `:2312`, which are the `main` 0c7380c
numbers — the `isMuxableType` de-anonymization below shifted them), so an
earlier peel could silently MOVE a PredMux accept.
Running after the fixpoint means every region PredMux can claim is already gone.
The local witness is `control_peel_predmux_unchanged_control.ll`; the global one
is §5's corpus diff.

**NOTES §2's stage-table row** (written at call site 1): the peel's P3 dominance
and P7 clonability proofs ARE computed before detection and consumed by it, but
both are STRUCTURAL (dominance, block shape, `isa<>`) and the peel changes no CFG
edge, so round 2 cannot falsify them for a region round 1 already saw. What
round 2 changes is WHICH branches are tainted — which is exactly what site 3 is
for, and `control_peel_round2_out_cond.ll` is its fixture.

**One shared-header change and one shared-function addition, both Rule 14:**

* `isMuxableType` was DE-ANONYMIZED in `PredMuxFlatten.cpp` (linkage only,
  definition byte-unchanged) and declared in `PredMuxFlatten.h`, so P5 asks the
  same predicate PredMux's own witnesses ask rather than growing a second
  spelling of "a type the 4.4/kjd1 merge can copy".
* `cq::propagateFromSeeds(TaintSet &, ArrayRef<Value *>)` was ADDED to
  `TaintPropagation.{h,cpp}` — a seeded forward walk over the SHIPPED
  `propagateWorklist` rule (the same one `repropagateControlMerges` re-runs for
  the 6.5/4.5 `%out` rails, `skipRuntimeCalls=true`). See §3's finding for why it
  is a correctness requirement rather than hygiene.

The peel deliberately does **not** re-run `propagate(M, wd)` the way the PredMux
fixpoint does: by this slot `lowerControlledIOSinks` and `lowerLoops` have
written bookkeeping into the `TaintSet` (`InPlaceRailOps`, `ClaimedRailRoots`,
`InLoopFlattenedPreds`, `PreLoopCommittedInPlaceOps`), and rebuilding the set
would silently discard it. Its taint delta is exactly three edits per peeled phi
(insert the clone, insert the select, erase the phi) plus the seeded forward walk;
every other `TaintSet` field is structurally incapable of naming a SOURCE phi at
this program point (argued at the erase site).

**Files touched:** `ir-pass/src/MergePhiPeel.cpp` (new),
`ir-pass/include/MergePhiPeel.h` (new), `ir-pass/CMakeLists.txt`,
`ir-pass/src/CQLoweringPass.cpp`, `ir-pass/src/TaintPropagation.cpp`,
`ir-pass/include/TaintPropagation.h`, `ir-pass/src/PredMuxFlatten.cpp`,
`ir-pass/include/PredMuxFlatten.h`, 25 `ir-pass/test/control_peel_*.ll`, 2
`tests/e2e/slice_control_fused_regions_*.{c,expected.log}`,
`tests/e2e/CMakeLists.txt`, **`tools/loop_twin_matrix.expected.txt`** (5 rows +
a dated header block — §4b), this record + `probes/`.
**NO** `runtime/`, **NO** `tools/opcode_table.yaml`, **NO** `include/CQ.h`, **NO**
new frozen symbol, **NO** new diagnostic string.

---

## §2 — THE PREDICATE AS SHIPPED vs SCOPE §3

P1–P8 are shipped verbatim in substance. Three deviations, each named, each in
the DECLINE-keeping direction.

| clause | shipped | vs SCOPE §3 |
|---|---|---|
| **P1** shape | diamond A / diamond B / if-else, transcribed clause-for-clause from `recoverRegion`, **plus `MergeBB->hasNPredecessors(2)`** and `S0 != S1` | as specified. The 2-pred demand also discharges SCOPE's *"`BI` is not `Claimed` by a nest"* STRUCTURALLY (a nest's shared merge has three preds), so no `Claimed`-set bookkeeping exists in this stage |
| **P2** | 2 incoming values **and** both `TruePred`/`FalsePred` named | as specified |
| **P3** | every incoming a `Constant`, an `Argument`, or an `Instruction` that `DT.dominates(I, BI)` | as specified |
| **P3b** | **`isa<UndefValue>` incoming → NOT PEELED** | **DEVIATION D3** — SCOPE H-9 offered "either exclude in P3 or confirm `LiteralIntegrity` covers it"; excluded. `PoisonValue` derives from `UndefValue`, so one test covers both. Pinned by `control_peel_reject_undef_incoming.ll` and (round-1 review DOC item) `control_peel_reject_poison_incoming.ll`. ⚠ **A `freeze` IS PEELED and that is CORRECT**: `freeze i32 poison` is an `Instruction`, not an `UndefValue`, so it falls to P3's dominance clause — and the argument is the PROPERTY, not the type test. `freeze` is SINGLE-VALUED BY DEFINITION, which is exactly what `LiteralIntegrity` guard 1 counts, so it cannot exhibit the two-slots-two-values hazard and refusing it would be an unargued over-decline. ACCEPT fixture `control_peel_freeze_incoming.ll`, one token from the poison decline (probes `x03`/`x02`) |
| **P4** | peel EVERY passing phi while **at most one** fails; entry gate **`NumPhis >= 2`** | **DEVIATION D1**, below |
| **P5** | `isMuxableType` (PredMux's own, now shared) | as specified |
| **P6** | the two incomings are distinct | as specified |
| **P7** | (a) a `CmpInst` in `Pred` all of whose operands dominate `MergeBB` → CLONE; or (b) `isCondRailLeaf` → the rail itself, no clone | as specified. A rail condition is asked `DT.dominates(CondI, MergeBB)` explicitly rather than argued |
| **P8** | `!Phi->use_empty()` | as specified |
| **P9** | **`regionEntryInLoop(BI)` → NOT PEELED** | **DEVIATION D2**, below |
| **P10** | **an ARM containing a `StoreInst` / atomic → NOT PEELED** | **ADDED BY THE ROUND-1 REVIEW** (finding F-B6-2): `classifyGuardedStoreArm`'s `guarded store with a merge value` decline keys on the merge φ the peel DELETES, so peeling flipped the 7.5 guarded Shadow store to an ACCEPT with the whole reversal spine gone (probe `g01`: exit 0, 35 lines, 10 mints / 10 left allocated, stage 2b `0 violation(s)` — blind to it). Pinned by `control_peel_reject_guarded_store.ll` + the discriminating control `control_peel_guarded_store_ctrl_unchanged.ll`. See `FIX_b6ap_R1.md` |

### D1 — the `>= 2`-phi entry gate (SCOPE OQ-5, and it is LOAD-BEARING)

SCOPE §3's P4 never states an entry gate, and SCOPE §0.3/§13 list `p60`/`h60` and
`V4`/`h61` (a data mux beside a VOID phase arm — a **one**-phi merge) as accepts.
**The shipped peel refuses them**, and SCOPE §17 OQ-5 is where that is already
written down: *"a second accept class … should be its own increment row"*.

What the implementation round adds is that the gate is **not merely
conservative — it is what stops peeling the region's OWN phi**. MEASURED:
`control_peel_angle_tail_unchanged_control.ll` is the module of the SHIPPED
accept `control_phase_kickback_negated_tail_phi.ll`, whose sole merge phi is
`classifyPhaseKickback`'s ANGLE TAIL. Its two incomings are distinct `double`
CONSTANTS, `double` is muxable, it has a use — it passes P2/P3/P5/P6/P8 and would
be PEELED by any predicate relaxed to `>= 1`, replacing a Rule-13-cleared kickback
lowering with a select on a fixture nothing would have flagged.

> ⚠ **CORRECTED 2026-09-11 by the Rule-13 round-1 review (DOC item).** This
> paragraph used to call that "CLAUDE.md's named f64/angle wire-crossing (*a
> floating-point merge phi is an ANGLE, not data*)". **That framing is not what the
> measurement shows, and it is withdrawn.** The reviewer ran the one-phi module
> (`d01_tail_onephi.c`) against its two-phi sibling (`d02_tail_twophi.c`, where the
> SAME angle phi sits beside a data mux so the peel DOES fire) and the two emit the
> **same unitary** — relative phase `c=1 -> 1.5+0.7 = 2.2`, `c=0 -> 0.1` in both,
> with **no `cqrt_alloc_f64` anywhere in either**: a peeled angle select is claimed
> by `classifyAngleSelect`, which is an ANGLE consumer, so no wire is crossed.
> Peeling an angle-tail phi is not itself a hazard. **The sound reason — the one
> that survives measurement — is the next paragraph's: on a ONE-phi merge the stage
> cannot tell the angle tail from the region's own value phi.** Applied to the
> source comment in `MergePhiPeel.cpp` and to the fixture header.

Relaxing the gate therefore means DECIDING WHICH PHI IS THE REGION'S, on a merge
where the region defines no value at all. That is a real design question and it
is OQ-5's, not this increment's.

**Consequence for the brief:** BRIEF §3's second e2e slice was specified as "bool
rail condition + phase arm + the `a` mux (16 lines)" — the `h61` shape, a
one-phi merge. It is **not deliverable under D1**. What shipped instead is the
same shape with **TWO** muxes (`slice_control_fused_regions_phase_bool.c`, 28
lines): bare rail condition, register-free phase arm, both muxes peeled, merge
ends empty, kickback on the rail. The slice header says so.

### D2 — P9, the in-loop refusal

An in-loop 2-phi merge declines `control flow` today. Peeling it would hand the
flattener a region that `flatRegionRollableInLoop` (bd `8h7d.5`) may ROLL IN
PLACE with a peeled `select` and a freshly cloned tainted compare in the loop
BODY — a combination nothing in the tree has measured, in the one neighbourhood
where CLAUDE.md's record is eight findings over six adversarial rounds on one
function, and where stage 2b is structurally blind to the failure mode (a leaked
TEMPLATE-minted rail has no `cqrt_alloc` to count). The 4.4 select is itself
loop-legal (bd `9ymx`), so this is **not** a claim that the shape is unsound; it
is a refusal to widen two axes at once. `regionEntryInLoop` is used rather than
`LoopInfo` because an irreducible cycle has no `LoopInfo` loop (the bd `drbq`
Inc-2b S7 lesson). Pinned by `control_peel_reject_inloop.ll`. Widening is a
follow-on row with its own rounds.

### Polarity, placement, the clone — as SCOPE specifies

* **Polarity (Rule 9):** `TruePred`/`FalsePred` are the merge predecessors
  reached when the condition is 1/0, read off the branch in `recoverPeelShape`
  and never assumed. Diamond A (arm = S0): `TruePred = Arm`, `FalsePred = Pred`.
  Diamond B (arm = S1, the `clang -O1` canonical form and the owner's file):
  `TruePred = Pred`, `FalsePred = Arm`. If/else: `TruePred = S0`,
  `FalsePred = S1`. Pinned by `control_peel_ifelse_constmux.ll`.
* **Placement:** clone + select inserted BEFORE `MergeBB->getFirstNonPHI()`,
  captured ONCE before any erase, so they land in phi order immediately after the
  surviving phi. SCOPE §7's choice; `h09c` vs `h09d` measured that pred placement
  also accepts at 22 lines with a DIFFERENT trace, which is the measurement that
  settles it.
* **The clone, not a share:** SCOPE §6 option A. `condDataUseDisposition` is
  untouched (OQ-1 not taken).
* **No `BirthOrder` entry** for the peeled select, deliberately: the stage runs
  before `lowerRotations`, so its select must be indistinguishable from one the
  SOURCE wrote, and a source select has none. This is what keeps the fused and
  hand-peeled modules byte-identical (§3).

---

## §2c — THE PRE-PEEL STAGE TABLE (Rule-13 ROUND-2, F-B6R2-1) — 15 rows, ZERO HOLES

⚠ **This table exists because the round-1 fix enumerated the stages that
adjudicate CONSUMERS of tainted values and got the SET wrong.** It named three
(`detectSpecializations`, `declineTaintEscapes`, `declineStaleRecordOps`, plus
`replanReseedSpecialization` riding with the first) and the round-2 review found a
FOURTH kind one row up: `foldIdentityBitcasts`, which folds ONLY an
already-tainted bitcast and is the SOLE handler for the opcode — so a bitcast the
peel taints later is left standing and dies at `no template for opcode 'bitcast
i32' in tainted context` while the hand-peeled twin of the same module lowers at
exit 0 on BOTH binaries (probe `BC1`). That is the finding; the fix is a fifth
call, and this table is the obligation the finding leaves behind: **re-walk every
stage between the first `propagate` and the peel, and let no row read "not asked".**

The question, per the NOTES §2 method, is asked of each stage in `CQLoweringPass::
run`: *does this stage read `taint.Tainted` to make a decision about a VALUE OR A
CONSUMER, and is that decision falsified when the peel grows taint at `:451`?*

The 15 rows are the complete statement-level enumeration of that window (MEASURED,
not eyeballed: `awk 'NR>=110 && NR<=452' ir-pass/src/CQLoweringPass.cpp | grep -v
'^\s*//' | grep -E '[A-Za-z_][A-Za-z0-9_]*\(' | sort -u` — 15 stages plus two
`CQ_*_DBG` dumps that print and change nothing). The SECOND entry point
(`:760`–`:929`) runs a strict SUBSET of the same stages in the same order
(`lowerByRefInline`, `unrollConstTripLoops` and `recognizeCtlzIdiomLoops` are
absent there), so no row can be worse in it.

| # | line | stage | taint-dependent decision? | disposition after the fix |
|---|---|---|---|---|
| 1 | 145 | `lowerByRefInline` fixpoint (+ full re-propagate) | YES — the gate is "out-POINTER classical AND ≥1 tainted value arg" (`ByRefInline.cpp:317/334`) | **DECLINE-ONLY.** A call the peel taints later was NOT inlined, so its `store` / opaque call survives to the RE-ASKED escape net (`kMsgStore` / `kMsgUnknownCallee`). The opposite direction needs the peel to make the out-POINTER tainted; the peel taints only `isMuxableType` SCALARS and their users, and a tainted `gep` is itself owned by the re-asked escape net (measured `K04`/`K05`) |
| 2 | **167** | **`foldIdentityBitcasts`** | **YES — folds only `taint.Tainted.count(BC)` same-width int↔int bitcasts, and is the SOLE handler for the opcode** | **WAS THE HOLE (F-B6R2-1). NOW RE-ASKED** as call 1 of `adjudicateTaintDelta`, ahead of the other four. Accept `control_peel_identity_bitcast.ll`; boundary partner `control_peel_reject_vector_bitcast.ll` |
| 3 | 178 | `foldVolatileConstGlobalLoads(M)` | no — it takes no `TaintSet` at all | **n/a.** Nothing to falsify |
| 4 | 187 | `foldVolatileConstAllocaLoads` | gate is the ALLOCA shape (single constant store, dominated exact-type loads); taint is carried for scrubbing | **DECLINE-ONLY + SHAPE-INVARIANT.** The peel changes no alloca and no load; an unfolded load leaves the value in MEMORY, where the re-asked escape net owns it |
| 5 | 202 | `eraseDeadVolatileScalarStores` | gate is the alloca shape + "zero loads"; taint appears once, as a belt-and-braces SKIP (`QramLowering.cpp:1447`) | **MONOTONE IN THE SAFE DIRECTION.** The fenv ruling licenses erasing a never-read volatile store on a non-escaping local — an observability fact, independent of the stored value's taint — and the taint clause can only ever make the stage do LESS |
| 6 | 217 | `promoteVolatileScalarLocals` fixpoint (+ re-propagate) | gate is the scalar-local shape | **DECLINE-ONLY.** An unpromoted accumulator stays in memory ⇒ re-asked escape net (`kMsgStore`) |
| 7 | 235 | `promoteFp80Union` fixpoint (+ re-propagate) | gate is the union bit-pattern SHAPE | **DECLINE-ONLY**, same argument |
| 8 | 259 | `flattenPredMuxRegions` fixpoint | YES (the E-gates read taint; the W-witness is literally `NumMergePhis >= 2`) | **ACCEPT-ONLY, and this omission is the SHIPPED round-2 sequence's own.** A region PredMux never saw (its branch tainted only via the peel) falls to `detectControlRegions` — the Rule-13-cleared 4.4 / Phase-4 substrate — or to a loud decline. `repropagateControlMerges` likewise does NOT re-run PredMux for its `%out` delta, and for the same reason. No measured customer |
| 9 | 281 | `unrollConstTripLoops` fixpoint | YES (the U-gates) — but the TRIP COUNT gate reads a `ConstantInt` | **ACCEPT-ONLY + MONOTONE.** A `Constant` can never become tainted (the same argument the eqpx (1a) fence rests on), so the peel cannot falsify the trip count; a loop it declined to unroll reaches `lowerLoops` and then `detectControlRegions`. MEASURED `L01` (the mux AS the trip count): loud `nested control flow` on the SUBJECT |
| 10 | 310 | `recognizeCtlzIdiomLoops` | YES — Z8 needs a TAINTED entry value, and it COMPETES with `lowerLoops`' Q1 | **ACCEPT-ONLY**, MEASURED `L06`: the idiom over a peel-tainted entry is not recognised, Q1 has already run, and the residual is loud `nested control flow` on BOTH binaries |
| 11 | 328 | `detectSpecializations` | YES | **RE-ASKED — call 3** (`detectSpecializations(&live)`). Mutant M-B; 7 measured members (`r20`,`k01`,`R01`,`R05`,`W13`,`W22`,`Z02`), all twin-identical |
| 12 | 338 | `declineTaintEscapes` | YES | **RE-ASKED — call 4.** Mutant M-C; 9 measured members; 4 decline fixtures |
| 13 | 345 | `declineStaleRecordOps` | YES | **RE-ASKED — call 5.** Mutant M-D, and it NOW HAS A FIXTURE: `control_peel_reject_stale_mux_record.ll` (`S02`), §2e |
| 14 | 357 | `lowerControlledIOSinks` | YES | **CLOSED BY ITS OWN LOUD DECLINE**, verified in source and measured (`I01`): `MergeOk = C.Merge->hasNPredecessors(2) && (NumPhis == 0 \|\| ValuePhi)` (`IOSinkLowering.cpp:609`) and `ValuePhi` is set ONLY when `NumPhis == 1` (`:594`), so EVERY ≥2-φ merge with an I/O-sink arm fires `kMsgIOControl` before the peel runs. The peel never sees such a site un-adjudicated |
| 15 | 373 | `lowerLoops` | YES (Q1 trip count, X1 cross-iteration, the `InPlaceRailOps` markings) | **CLOSED BY A LATER RE-VERIFICATION, not by an argument.** The in-place-immediate half — the bd `eqpx` class reached through the peel instead of through round-2 taint — is re-asked under FINAL taint one stage later by `lowerOps`' own G2 tripwire (`cq loop lowering: in-place rail op no longer provable at lowering`, `OpcodeLowering.cpp:102`) and, for a pre-loop commitment, by the (1b) sibling (`:86`) over the MONOTONE `isa<Constant>(Imm)` fence. Q1/X1 are ACCEPT-ONLY in the same sense as rows 8–10 and measured loud at `L01`/`L04`/`L05`/`L06`. `lowerLoops` emits only three CONSTANT-argument `cqrt_alloc_*` (`LoopLowering.cpp:1746/1748/1750`), so it cannot leave an emitted runtime call holding a peeled select |

**ZERO rows read "not asked".** Rows 11-13 are re-asked because they adjudicate
consumers; row 2 joins them as of this fix; rows 14 and 15 are closed by a decline
or a re-verification that ALREADY exists and that this round read rather than
assumed; rows 1, 3-10 are decline-only or shape-invariant, with the two
loop-recogniser rows measured loud rather than argued.

⚠ **The row that matters for the NEXT round is row 8.** It is the only one whose
safety rests on "the fallback owner is sound", and its fallback is the whole
Phase-4 control substrate. It is the shipped round-2 sequence's own posture, so a
defect there is not the peel's — but it is the row to attack first if a third
round wants a fifth thing.

## §2d — THE φ-CONSUMER TABLE (the round-3 question, asked and MEASURED)

The round-2 review's item 7 named the successor question and said outright that it
had checked it **by reading, not by a probe family**: *the peel does not only GROW
TAINT — it DELETES a `phi` and INSERTS two instructions.* A deleted `Value *` that
some structure still names is the bd `drbq` Inc-1 defect verbatim (a set keyed at
one stage, read stages later, after the key was freed).

**METHOD — measured, not read.** A temporary audit build asked, AT THE ERASE LINE
and for every φ the peel deletes, whether that φ is a member of every container in
`ir-pass/include` that can hold a `Value *` / `Instruction *` / `PHINode *` (found
by grepping the headers for `SmallPtrSet<`, `DenseMap<`, `DenseSet<`, `std::set<`,
`WeakTrackingVH` and `SmallVector<…Value`), plus `Phi->user_empty()`. Run over
**all 1814 fixtures** and **all 501 probe modules** under `inc1-records/**`
(every committed probe corpus plus the round-2 reviewer's own, which the
orchestrator commits with this round):

```
fixtures : 31 erasures in 16 files   | HITs: Tainted 3 | users=0 : 31/31
probes   : 163 erasures in 85 files  | HITs: Tainted 3 | users=0 : 163/163
```

**194 erasures; the ONLY container ever holding a deleted φ is `Tainted` (6
hits, all genuinely tainted muxes — `control_peel_{fp_datamux_phase,qq_datamux,
reject_fp_stateprep}.ll`, `p90_qq_mux`, `n01_alias_rail_mux`,
`s01_stale_record_mux`), and it is erased on the line before the deletion.**
`user_empty()` held at every one of the 194, because the `replaceAllUsesWith` runs
first — so no LLVM `Use` dangles either. The instrumentation was removed and the
binary rebuilt (`grep -c PEELAUDIT ir-pass/src/MergePhiPeel.cpp` → 0).

The rows, with the REASON each one cannot hold the φ — the measurement says *this
corpus*, the reason says *any corpus*:

| container | can it name the deleted φ? | why |
|---|---|---|
| `TaintSet::Tainted` | **YES** | **ERASED** at the deletion site (`MergePhiPeel.cpp`), one line before `eraseFromParent`. Measured 6/6 |
| `BirthOrder`, `HandleWidth` | no | `Value *` keys, but every writer is `lowerRotations` / `lowerOps` / a control emitter — all AFTER the round-1 peel. At the ROUND-2 peel they hold emitter-minted `CallInst` handles, never a source φ. Measured 0 |
| `SharedCondFlags` (key/val), `ControlledRotations` (val) | no | written by `emitRegion` / `AngleSelectEmit` with the region's COMPARE and the minted FLAG; both are `CmpInst`/`CallInst`. Measured 0 |
| `StaleDeclined` | no | `Instruction *`, so type-possible — but its ONLY writer is `checkStaleOp`, and its subject set is `inLowerOpsScope`, which admits `BinaryOperator`/`UnaryOperator`/`CastInst`/data-`CmpInst`/curated `CallInst` and **no `PHINode`** (`OpcodeLowering.cpp`). Measured 0 |
| `LiftedConsumers` | no — BY STAGE ORDER ONLY | `Instruction *`, and its writer `liftOneRegisterMergePhi` inserts the lifted φ's USERS, which CAN be a φ. It is empty at both peel sites: `declineClassicalMuxes` runs at `CQLoweringPass.cpp:613` / `:967`, AFTER both. ⚠ RETIREMENT TRIGGER: if `declineClassicalMuxes` ever moves above the peel, the peel must scrub this set |
| `ControlOwnedRails`, `OutputRails`, `GraveyardRails`, `UntaintedMergeRails` | no | every `insert()` site (`SelectMergeEmit:250`, `SwitchDataMuxEmit:145/151`, `SwitchValueEmit:294`, `ClassicalCallArmEmit:210/219`, `IOSinkLowering:414/740/776`, `AbortParkEmit:421/423/425`, `LoopLowering:1764`, `BreakReversePlay:780/782`, `BennettWrap:109/115`) passes a value the EMITTER JUST CREATED — a `cqrt_*` / `cq_template_*` call. Never a source φ. Measured 0 |
| `InPlaceRailOps`, `InPlaceRailIdx`, `PreLoopCommittedInPlaceOps` | no | `Instruction *` keys written only through `markInPlaceRailOp` / the pre-loop commit, whose subject is a proven in-place `add`/`xor` `BinaryOperator`. Measured 0 |
| `ClaimedRailRoots` | no | `(root, header)` pairs whose root is `railPhiRootMint`'s ROOT MINT — a `@cq_theta` call. Measured 0 |
| `RailCondReads` | no — and it CANNOT dangle either | holds (rail, first read) as **`WeakTrackingVH`**, which nulls on deletion; and the rail is a `cq_theta_i1` call. Measured 0 |
| `IOTapeForFn`, `GuardedStores` | no | keys are `Function *` / `StoreInst *`; values are the tape rail / the guarded value, both emitter-created. Measured 0 |
| `IntrinsicInvokes`, `DischargedFlagGates`, `SpineOps`, `UserSourceRotations`, `UserChainedRotations`, `UserPhaseRotations`, `ThetaCalls`/`PhiCalls`/`MeasureCalls`/`PhaseCalls` | no — BY C++ TYPE | every one is a `CallInst *` / `CallBase *` container. A `PHINode` is not of that type; this is a compiler-enforced impossibility, not a convention |
| `IterationLocalBlocks`, `InLoopFlattenedPreds` | no — BY C++ TYPE | `BasicBlock *`. (And the peel deletes no block and moves no CFG edge) |
| `SpecPlan::Pending` / `Diagnosed` / `Cache` | no — BY C++ TYPE | `SpecCandidate` holds a `CallInst *Site`; `Diagnosed` is `const CallInst *`; `Cache` is keyed by `(Function *, mask)` |
| `ControlPlan` (`ControlRegion::Merge` is a `PHINode *`) | no — BY LIFETIME | at the round-1 peel no `ControlPlan` exists yet (`plan` is constructed on the NEXT line); at the round-2 peel `plan2` is constructed, consumed by `lowerControlRegions` and destroyed INSIDE the same fixpoint iteration (`TaintPropagation.cpp`), so no plan is ever live ACROSS a peel |
| **`TaintSet::BreakRegions`** | **no — BY CLAUSE (P9 + P1), and this is the one to watch** | `LoopBreakRegion` holds RAW `llvm::PHINode *` (`EscapePhi`, `CounterPhi`), it is written by `lowerLoops` **BEFORE** the peel and read by `lowerBreakReversePlay` **AFTER** it. `CounterPhi` is the loop HEADER φ (in-loop ⇒ P9); `EscapePhi` is in the exit merge, whose predecessor's terminator is the in-loop exiting branch (in-loop ⇒ P9, and its arm does not unconditionally reach the merge ⇒ P1). MEASURED: 17 fixtures and the 4 `slice_loop_break*` e2e slices reach the peel with `BreakRegions` non-empty (`n=1`) and **not one of them peels a φ** — zero files in either corpus have both a non-empty `BreakRegions` and an erasure. ⚠ RETIREMENT TRIGGER, written at P9 in the source: **if P9 is ever narrowed to admit an in-loop site (§7 Q2), the peel must first scrub or re-derive these φ pointers** |

**No dangling key found.** Two rows are safe only by a decision that a follow-on
wants to change (`LiftedConsumers` by stage order, `BreakRegions` by P9), and both
now carry a retirement trigger — in the source, not only here.

⚠ **One more number the audit produced, and it is the containment claim restated as
a measurement: the peel FIRES on exactly 23 of the 1814 fixtures, and all 23 are
`control_peel_*` — its own family.** Every other fixture leaves `Delta` empty, so
`adjudicateTaintDelta` returns at its first line and none of the five calls runs.
That is why §5's ORACLE-vs-SUBJECT corpus diff is `0/0/0` over the 1776
pre-existing fixtures BY CONSTRUCTION rather than by luck, and it is also the
complete list of fixtures a change to any of the five calls can move.

**THE INSERTION HALF**, for completeness: the peel also inserts a compare CLONE
and a `select`. The round-2 review checked `condDataUseDisposition`,
`f2SeedPinnedByLiveRegister` and `reverifyRailCondReads` by reading and found
nothing; this round adds no measurement there, and says so rather than implying
the audit covered it. The audit above answers the DELETION question only.

## §2e — M-D's CUSTOMER: `declineStaleRecordOps` over the delta is NOT dead

The round-1 fix recorded, as its open question 1, that mutant **M-D** (drop call 5,
`declineStaleRecordOps`, from `adjudicateTaintDelta`) moved **nothing**, and gave a
structural argument for why it might be unreachable. **The argument was wrong**, and
the round-2 review produced the customer from plain C at `-O1` (probe `S02`):

```c
int m = 5, n = 1;
if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
int r = cq_theta(m, 0.2);   // SOURCE prep at :345 (m is a classical phi);
                            // CHAINED at lowerRotations (m is the mux rail)
int s = m + 1;              // reads the PRE-Ry record of that same rail
```

The staleness is **created by the peel**: at `declineStaleRecordOps`' own slot `%m`
is a CLASSICAL `phi`, so `s = m + 1` is a classical `add` that is not even in
`inLowerOpsScope` — the once-only sweep structurally cannot see it. The peel makes
`%m` a tainted `select`, which flips the `cq_theta` from a SOURCE mint to a CHAINED
in-place `Ry` on the mux rail, and the `add` becomes a read of that rail's
pre-rotation record. The SUBJECT declines **`cq opcode lowering: operand predates a
non-diagonal gate`**; the ORACLE gives the HAND-PEELED twin the same string.

Shipped as the decline fixture `control_peel_reject_stale_mux_record.ll`. **Mutant
M-D re-measured on this tree: the fixture goes to `opt` exit 0 (a silent accept —
only the pre-existing `non-diagonal gate over a live derived record` WARNING is
printed) and it is the ONLY fixture of 1814 that moves.** All four consumer-
adjudicating calls now have a pinning fixture, and so does the fifth:

| mutant | what breaks | pinned by |
|---|---|---|
| **M-A** drop `replanReseedSpecialization` | `k01` emits `add_i32_hl(h1, 4)` at exit 0 | `control_peel_clone_stale_mask.ll` |
| **M-B** drop `detectSpecializations(&delta)` | `r20` OVER-declines `unknown callee` | `control_peel_clone_measured.ll` |
| **M-C** drop `declineTaintEscapes` | `r04`/`r11`/`r02`/`r07` return to exit 0 | the four `..._reject_escape_*.ll` |
| **M-D** drop `declineStaleRecordOps` | `S02` returns to exit 0 | **`control_peel_reject_stale_mux_record.ll`** (NEW) |
| **M-E** drop `foldIdentityBitcasts` | `BC1` returns to exit 1, `no template for opcode 'bitcast i32'` | **`control_peel_identity_bitcast.ll`** (NEW) |

Each mutant was built, run over the FULL lit corpus, and restored; M-D and M-E each
reddened **exactly one** fixture and nothing else (`Passed: 1812, Expectedly Failed:
1, Failed: 1` both times).

## §3 — RED-GREEN LOG

### ⚠ THE FINDING THIS ROUND FOUND IN ITS OWN FIRST SPELLING

The peel's first version copied the **phi's** taint onto the select it built
("taint follows the φ EXACTLY"). **That is a wrong unitary, and it was
verify-clean, stage-2b-clean and `opt` exit 0.**

`propagateWorklist` (`TaintPropagation.cpp:374`) taints **every user** of a
tainted value (bar a measure sink and an angle-only edge). A `phi` is not a user
of the branch condition, so a constant-armed merge phi is UNTAINTED; a `select`
**is** one, so the identical mux written in the source is TAINTED. With the
select left classical, its downstream users stayed classical too:

```
  %s = add nsw i32 %m, %out                     <- FIRST SPELLING (z08/z18/z19)
  call void @cqrt_addc_i32(i32 %out, i32 %m)    <- ORACLE on the hand-peeled twin z12
```

`%out` is the 4.4 merge OUT-RAIL: the emitted program added the runtime **handle
tag** instead of the superposed value — the bd `afmv` class. It surfaced only
because the peel's contract is *"produce the module the hand peel already is"* and
the hand-peeled twin `z12` lowers it CORRECTLY **on the oracle**; the isolation
ladder is `z11` → `z16` → `z17` → `z12` vs `z08`/`z18`/`z19` (probes README).

**Fix:** taint the select unconditionally, record the clone, and re-run the ONE
shipped forward walk from both (`propagateFromSeeds`). After it, `z08`'s lowered
module is BYTE-IDENTICAL to `z12`'s. The lesson is CLAUDE.md's in a new place: a
normalisation that restores a source spelling must restore **everything the
source spelling implies**, taint included — and the way to know is to diff against
the hand-written twin, not to reason about it.

### The fixture family — 25 files, all `ir-pass/test/control_peel_*.ll`

RED-GREEN measured by running each committed fixture through BOTH binaries.

**9 ACCEPTS, each RED (exit 1) on `main` 0c7380c and GREEN here:**

| fixture | oracle string | what it is |
|---|---|---|
| `control_peel_stateprep_datamux` | `control flow` | THE FLAGSHIP (`p09`/`h09c`): the owner's file with `int b0`/`int b1`. Its last RUN line lowers the ALREADY-PEELED twin and `diff`s the two modules — the byte-identity witness |
| `control_peel_three_phis` | `control flow` | `p31`/`h31` — two muxes peeled, the prep phi left, THREE flag triples |
| `control_peel_qq_datamux` | `control flow` | `p90`/`h90` — SCOPE H-8, a Q+Q mux; the Rule-8 argument is re-derived in the header |
| `control_peel_ifelse_constmux` | `control flow` | the if/else orientation; both phis peel, merge ends empty, phase kickback claims it |
| `control_peel_classical_call_datamux` | `control flow` | `p71`/`h71` — the 6.5 classical-call arm |
| `control_peel_round2_out_cond` | `control flow` | **THE ROUND-2 PIN** (`p80`/`h80`) |
| `control_peel_fp_datamux_phase` | `control flow` | `h87c` — a real `double` DATA mux (kjd1 `cqrt_copy_f64_controlled`) + phase arm |
| `control_peel_angle_tail_datamux` | `control flow` | **NEW THIS ROUND** (`z03`): an ANGLE-TAIL phi BESIDE a data mux |
| `control_peel_seq_chain` | `nested control flow` | **NEW THIS ROUND** (`z04`): SCOPE H-1, the hcrg chain |

**3 CONTROLS, green on BOTH binaries** (the containment witnesses):
`control_peel_stateprep_datamux_peeled_control` (the byte-identity partner),
`control_peel_predmux_unchanged_control` (`p30`/`h30` — PredMux owns it, so the
slot is right), `control_peel_angle_tail_unchanged_control` (the one-phi ANGLE
tail — D1's concrete reason).

**9 DECLINES that keep `control flow` exactly** (the partition survives):
`..._reject_two_arm_defined` (`p88`, the decline that must survive),
`..._reject_arm_defined_speculatable` (`h30b`, **the peel must never hoist**),
`..._reject_nonmuxable_type` (P5), `..._reject_cond_tree` (P7/OQ-4),
`..._reject_three_pred_merge` (P1, `z13`), `..._reject_inloop` (P9, `z05`),
`..._reject_one_phi_void_arm` (`p60`, D1's boundary),
`..._reject_undef_incoming` (P3b, `z09`), `..._reject_identity_phi` (P6, `z10`).

**4 DECLINES whose STRING MOVES** (SCOPE H-2 — the peel fires and a deeper fence
owns the decline; each confirmed to be the RIGHT fence):

| fixture | oracle | subject |
|---|---|---|
| `..._reject_rotated_cond` (`p85`/`h85`) | `control flow` | `condition predates a non-diagonal gate` — `SelectClassify` gate 2c, position-free, so the CLONE cannot launder a stale condition |
| `..._reject_round2_rotated_cond` | `control flow` | the same, at ROUND 2 — pins that site 3 is not a silent accept |
| `..._reject_stateprep_rail` (`p01`) | `control flow` | `bare i1 register condition` — bd `l4x4`; **this fixture flips to an accept when `l4x4` lands** and its header says so |
| `..._reject_fp_stateprep` (`p87`/`h87`) | `control flow` | `state prep seed is proven equal to the condition register` — SCOPE H-3/OQ-2, an OVER-decline, pinned so it cannot move silently |

### Injection matrix — 48 mutations, **0 MISSED / 0 DIRTY**

Over the 12 accept fixtures, on the LOWERED text, checked against every prefix
each fixture declares: **M1** an extra `cqrt_x` on the condition REGISTER, **M2**
an extra `cqrt_free`, **M3** a controlled copy fired on the WRONG FLAG, **M4** a
DROPPED `_unc` strip, **M5** a DROPPED `cqrt_x` bracket half. Each accept carries
an ordered `CHECK` stream plus whole-file exact-count prefixes
(`XCNT`/`FCNT`/`ACNT`/`UCNT`/`CPCNT`/`RYCNT`/`RZCNT`/`CNCNT`) and one
pure-negative `NOROUTE` block — pure-negative on its own prefix, because a
positive line inside one WINDOWS every negative after it (the drbq Inc-4 F-L6-1
lesson).

### The round-2 MUTATION TEST (SCOPE §15.2, run by this round)

Deleted the site-3 call, rebuilt BOTH targets, ran the FULL lit suite:

```
FAIL: control_peel_round2_out_cond.ll
FAIL: control_peel_reject_round2_rotated_cond.ll
Passed: 1798  Expectedly Failed: 1  Failed: 2   (of 1801)
```

**Exactly the two round-2 fixtures redden and nothing else** — which is SCOPE
§15.2's stated acceptance criterion ("if more than the round-2 fixtures move, the
slot is wrong"). Restored and rebuilt; the suite is green again.

---

## §4 — e2e

Two slices, both STRICT stage 2b, registered in `tests/e2e/CMakeLists.txt`
immediately before the `select_bool` group.

| slice | lines | 2b | oracle |
|---|---|---|---|
| `slice_control_fused_regions_int.c` | **22** | `5 rail mint(s), 5 left allocated, 2 free(s): 2 verified, 0 violation(s), 0 unproven` | DECLINE `control flow` |
| `slice_control_fused_regions_phase_bool.c` | **28** | `9 rail mint(s), 7 left allocated, 2 free(s): 2 verified, 0 violation(s), 0 unproven` | DECLINE `control flow` |

`slice_control_fused_regions_int.c` is the owner's `main()` with `bool` → `int`,
and its golden is EXACTLY the `h09c` stream SCOPE §0.2 predicted, line for line.
Read against the analytic stream: register mint → REGION flag mint → `cqrt_x`
bracket → prep rail + `cqrt_ry_i32_controlled` → `cqrt_x` → strip → free →
SELECT's OWN flag mint → `|0>` out rail → source 2 + controlled copy → `cqrt_x` →
source 5 + controlled copy → `cqrt_x` → strip → free → three measures. Two
INDEPENDENT flag triples on one wire, which is the shipped hcrg sequential shape;
two frees, both flags, everything else left allocated (Rules 6/8).

**NO `compare_files` gate**, deliberately (the drbq Inc-4 / r9e5 precedent): no
program in the tree has a golden provably identical to either of these, so such a
gate would assert something false. **The byte-identity witness for this increment
lives in lit, where it is real** — `control_peel_stateprep_datamux.ll` lowers the
already-peeled partner on a RUN line and `diff`s the two modules.

The **owner's file VERBATIM** is not registrable: see §6.

### §4b — ⚠ `e2e-loop-twin-matrix`: FIVE CELLS MOVED, and the table was changed

The e2e gate came back **378/379 with `e2e-loop-twin-matrix` RED on 5 cells**,
`m_rz_{der,eq0,eq,gt,range}_rz`, all `DECLINE-BOTH-DIFFERENT` -> `UNROLLED-ONLY`.
It was investigated before anything was regenerated (Rule 12: *"regenerate
baselines deliberately, never by reflex"*).

**Only the UNROLLED side moved, and it moved DECLINE -> ACCEPT.** The ROLLED
side's `condition predates a non-diagonal gate` is unchanged on both binaries, so
this is a rolled-side OVER-DECLINE, not a new defect; `UNROLLED-ONLY` is an
established verdict class with 63 other cells in it.

**Mechanism, measured.** The cells are `cq_phi` prefix / phase region / `cq_phi`
suffix. In the unrolled spelling `clang -O1` SINKS the second repetition's
`cq_phi` calls into the merge and leaves **TWO `double` ANGLE phis** there:

```llvm
  %5 = phi double [ 1.250000e-01, %arm ], [ -1.250000e-01, %entry ]
  %6 = phi double [ 0x400921FB54442D18, %arm ], [ 1.250000e-01, %entry ]
```

`phaseAngleTail` refuses a second phi, so `classifyPhaseKickback` returned
NotApplicable and the program declined `control flow`. The peel turns both into
selects, the merge ends EMPTY, the region lowers as a flat kickback, and **each
peeled ANGLE select is claimed by `classifyAngleSelect`'s Rz stem — the shipped
KICKBACK PAIR, not the kjd1 fp DATA merge.** There is no `cqrt_alloc_f64` in any
of the five outputs, so the f64/angle wire is NOT crossed: `SelectClassify`'s
gate 3 makes that partition for a peeled select exactly as for a source-written
one. This is the same shape as the hand-IR fixture
`control_peel_angle_tail_datamux.ll`, which this round wrote for precisely this
reason before the matrix ran.

**Unitary, re-derived by hand on `m_rz_eq_rz`** (6 `cqrt_rz_i1` gates, 2b
`0 violation(s), 0 unproven`; the other four are identical in form, each measured
at 2 `double` phis / 6 gates / 2b clean):

```
  a == 5 :  PI + (-0.125) + 0.125 + PI = 2*PI
  a != 5 :        (-0.125) + 0.125     = 0
```

which is the source's 2*PI relative phase (the two UNCONTROLLED `cq_phi(0.125)` /
`cq_phi(-0.125)` are GLOBAL phases, deleted by owner decision D2). **Correct.**

**Disposition:** the five rows were rewritten BY HAND (five lines, verified as
exactly 10 changed lines against a backup — `--regenerate` was NOT used, so no
other cell could move silently), and a dated ~30-line block explaining the move,
the mechanism and the unitary was added to
`tools/loop_twin_matrix.expected.txt`'s header. Row count 259, quarantine
UNCHANGED at 29, total 288 cells. **This is the one judgement call in the
increment that a reviewer should re-take from scratch** — see §7 Q10.

---

## §5 — CORPUS AND PROBE DIFF

### `ir-pass/test/*.ll` — all 1776 pre-existing fixtures, oracle vs subject

```
corpus: 1776 fixtures | 0 RCDIFF   0 DIAGDIFF   0 OUTDIFF
```

Run twice — once on the first spelling and again after the taint fix — both
0/0/0. **Not one pre-existing fixture moves in any direction**, which is the W7
containment precedent SCOPE §13 asks for, and it also says that no shipped
fixture exercises a `>= 2`-phi merge at all: the whole new family is new coverage.

`git status --porcelain tests/` after the e2e run: **clean apart from the two new
slices and their goldens** (no pre-existing golden regenerated).

### Probe corpora — 189 probes across 9 recorded probe directories

```
probe corpora: 189 probes | 16 MOVERS
```

**All 16 movers are in `session-b6ap/probes/` — this increment's own family. ZERO
movers in the other 144 probes** (`session-r9e5/probes` 44,
`session-3qlq4/probes` 39, `session-3qlq4/review_1b_r2_probes` 53,
`session-7bbdb89e/clearance_probes` 8; the `review_b1_r{1,2,3}_probes` and
`review_1b_r1_probes` directories hold no `.c`/`.ll` probe files).

| probe | oracle | subject | note |
|---|---|---|---|
| `p09_owner_int` | `control flow` | **ACCEPT** | the flagship |
| `p22_peel_int_sel_first`, `p23_peel_int_sel_after` | `control flow` | **ACCEPT** | the "manually peeled" C twins — their stage-1 IR is BYTE-IDENTICAL to `p09`'s (SCOPE §0.1), so they had to move with it |
| `p31_three_phi` | `control flow` | **ACCEPT** | three phis |
| `p50_fp_extra_phi` | `control flow` | **ACCEPT** | the README records `-O1` narrowed its mux to `i32`, so it is an `i32` 2-phi merge |
| `p71_call_arm_opaque` | `control flow` | **ACCEPT** | 6.5 arm |
| `p80_round2_out_cond` | `control flow` | **ACCEPT** | round 2 |
| `p90_qq_mux` | `control flow` | **ACCEPT** | Q+Q |
| `p00_owner_bool`, `p01_owner_intb1`, `p20_peel_bool_sel_first`, `p21_peel_bool_sel_after`, `p40_owner_sdagger` | `control flow` | `bare i1 register condition` | the peel fires; the wall moves to bd `l4x4` |
| `p85_v8int` | `control flow` | `condition predates a non-diagonal gate` | gate 2c |
| `p86_two_armdefined`, `p87_fp_mux` | `control flow` | `state prep seed is proven equal to the condition register` | SCOPE H-3 / OQ-2 |

**Every mover is DECLINE → ACCEPT or DECLINE → (a deeper, loud DECLINE). No
accept moved and no decline became silent.** The increment is accept-monotone as
measured, not as argued.

`p86_two_armdefined` is worth one line: SCOPE OQ-6 already records that `-O1`
IPSCCP const-folds its arm chain on the equality edge, which makes a phi peelable
that the SOURCE did not write as a mux. It is sound (the constant is what the
program computes on that edge) and it now declines at F2 rather than at the
2-phi wall.

---

## §6 — THE OWNER'S FILE AFTER THIS INCREMENT

`example/grover/grover_oracle_uncompute.c` as it stands (snapshot
`probes/p00_owner_bool.c`), `bool b0` / `bool b1`:

```
main 0c7380c :  CQ_CTRL_DBG: decline [control flow] at:   br i1 %1, label %4, label %2
                error: ... cq controlled lowering: control flow under quantum control

this tree   :  CQ_CTRL_DBG: decline [bare i1 register condition] at:
                  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
                error: ... cq controlled lowering: bare i1 register condition under quantum control
```

**The verbatim string it stops on after this increment is
`bare i1 register condition`, and the anchor has moved from the `br` to the
`cq_theta_i1` that produces `b0`.** That is bd **`l4x4`** (Inc 1b-C, the state
prep / in-place Ry arm on a bare rail) — the SECOND of the file's three walls, and
the one this increment deliberately does not build. The peel itself handles the
`bool` spelling perfectly well (P7 clause (b) admits a rail leaf and the data mux
peels); what is left is the ARM.

With `bool b0` → `int b0` **and** `bool b1` → `int b1` the file COMPILES on this
tree: 22 trace lines, STRICT stage 2b `0 violation(s), 0 unproven`, shipped as
`tests/e2e/slice_control_fused_regions_int.c`. Changing only `b1` is NOT enough —
`b0` is the condition register, so the arm is still on a bare rail
(`p01_owner_intb1`, which declines with the same string).

So SCOPE §16's table is confirmed, measured on this build:

| owner spelling | after this increment |
|---|---|
| `int b0`, `int b1` | **COMPILES**, 22 lines, 2b clean |
| `bool b0`, `int b1` | needs bd `l4x4` — `bare i1 register condition` |
| `bool b0`, `bool b1` (the file as written) | needs `l4x4`, and then the `i1` state-prep seed ruling (bd `drbq.14`) |

It is not registered as an e2e slice because it does not compile; it is committed
under `probes/p00_owner_bool.c` with both verdicts.

---

## §6b — COUNTS (measured by command, in this worktree)

| | before (`main` 0c7380c) | after | command |
|---|---|---|---|
| `ir-pass/test/*.ll` | 1776 | **1814** (+38) | `ls ir-pass/test/*.ll \| wc -l` |
| e2e goldens | 341 | **343** (+2) | `ls tests/e2e/*.expected.log \| wc -l` |
| ctest entries | 387 | **389** (+2) | `ctest --test-dir build -N \| tail -1` |
| `^e2e-` | 377 | **379** | `ctest --test-dir build -N -R '^e2e-'` |
| `^e2e-slice-` | 339 | **341** | `ctest --test-dir build -N -R '^e2e-slice-'` |
| `twin-identical` | 28 | **28** (unchanged — no `compare_files` gate added, §4) | `ctest --test-dir build -N -R 'twin-identical'` |

`runtime/`, `tools/opcode_table.yaml` and `include/` are UNTOUCHED. No new frozen
symbol and no new diagnostic string.

⚠ **The fixture figure is the ONLY count this increment has moved since hand-back,
and it moved twice**: 1776 → 1801 (+25, hand-back) → 1811 (+10, the round-1 fix)
→ **1814 (+3, the round-2 fix)**. The three are `control_peel_identity_bitcast.ll`
(ACCEPT, F-B6R2-1 / mutant M-E), `control_peel_reject_vector_bitcast.ll` (DECLINE,
its one-token boundary partner) and `control_peel_reject_stale_mux_record.ll`
(DECLINE, M-D's customer). **The e2e / ctest / golden / twin counts are UNCHANGED
by the round-2 fix — it adds no slice and no golden**, which is itself part of the
gate: `git status --porcelain tests/` must show only the round-1 registration.

---

## §6c — GATES (Rule 19), in the brief's order

⚠ EVERY WALL-CLOCK FIGURE HERE IS A **LOADED** ONE and is not comparable to
CLAUDE.md's quiet-box band: a sibling worktree (`CQ_trackA`) was running its own
full suite concurrently — both `loop_twin_matrix.py` processes were visible in
`ps` at once and the 1-minute load average was 17.7 (15-minute 98.5).

| gate | result |
|---|---|
| 1. `lit ir-pass/test --filter 'control_peel'` while iterating | 25/25 |
| 1b. `lit ir-pass/test` (full, direct) | **1801 discovered · 1800 Passed · 1 Expectedly Failed · 0 unexpected** |
| 2. `ctest -R ir-pass-lit --output-on-failure` | **Passed, 108.00 s — 1/1** |
| 3. `ctest -j6 -R '^e2e-' --output-on-failure` | **378/379, 2780.06 s** — the one red was `e2e-loop-twin-matrix` on the 5 cells of §4b; green after the table edit (re-run in gate 4) |
| 3b. `git status --porcelain tests/` | only the 2 new slices + their 2 goldens + the `CMakeLists.txt` registration — **no pre-existing golden regenerated** |
| 4. full `ctest -j6 --output-on-failure` | recorded at the bottom of this section |
| 5. `cq-opt-equivalence` | the sampled entry runs inside gate 4 |

**FULL SUITE (gate 4), after the table edit:**

```
100% tests passed, 0 tests failed out of 389
Total Test time (real) = 2088.06 sec
389/389 Test #318: e2e-loop-twin-matrix ...........  Passed  1026.88 sec
388/389 Test   #9: cq-opt-equivalence .............  Passed    31.67 sec
```

`cq-opt-equivalence` (the sampled entry) is green, so `cq-opt` and
`opt -load-pass-plugin libCQPass.so` still agree on stdout, stderr and exit code
with the new source file linked into both targets. **The FULL equivalence sweep
(`cmake --build build --target cq-opt-equivalence-full`) was NOT run**: this
increment adds no diagnostic string and moves none in the source — the four
moved strings in §3 are different FENCES firing, not edited text — and the full
sweep costs ~658 s of CPU on a box already carrying a sibling worktree's suite.
If the reviewer wants it, it is one command.

---

## §7 — OPEN QUESTIONS FOR THE REVIEWER

**Q1 — D1, the `>= 2`-phi entry gate (SCOPE OQ-5).** The peel refuses a one-phi
merge even when that phi is provably not the region's (a data mux beside a VOID
arm — `p60`/`h60`, `V4`/`h61`, both measured ACCEPTS as hand peels). The gate is
what makes accept-monotonicity structural, and
`control_peel_angle_tail_unchanged_control.ll` shows it is also what stops a
SHIPPED Rule-13-cleared kickback lowering being replaced by a select. (⚠ the
earlier wording here said "stops the f64/angle wire-crossing"; the round-1 review
MEASURED that peeling an angle-tail phi crosses no wire — same unitary, no
`cqrt_alloc_f64` — see §2 D1's corrected note. The reason is "which phi is the
region's", not the phi's type.) **It costs the `h61` shape, which
BRIEF §3 named as an e2e slice; the shipped bool slice carries TWO muxes
instead.** Widening needs a rule for "which phi is the region's" on a merge where
the region defines nothing — own increment row.

**Q2 — D2, P9's in-loop refusal.** Conservative, not proven necessary. The 4.4
select is loop-legal (bd `9ymx`) and every in-loop 2-phi merge declines today, so
this only keeps an existing decline. Whether an in-loop peel composes with the
`8h7d.5` rolled-region machinery is unmeasured and should not be guessed at.

**Q3 — SCOPE H-3 / OQ-2, unchanged and NOT fixed here.** `fp mux + state-prep
arm` over-declines at F2 (`f2SeedPinnedByLiveRegister`) because the peeled
select's condition is exactly pinned on both edges and an fp select result cannot
be bounded. The brief instructs not to touch F2, and this round did not. Pinned by
`control_peel_reject_fp_stateprep.ll`.

**Q4 — SCOPE OQ-1, `condDataUseDisposition` untouched.** Each peeled phi costs a
flag rail (mint + strip + free). Three peeled phis means three extra triples
(`control_peel_three_phis.ll`). Teaching the ziov fence to recognize a
`SelectClassify`-claimable select would remove them; it is a Rule-13-core widening
of a fence whose disposition table predates region-claimable selects.

**Q5 — OQ-4, the condition TREE.** P7 admits one `CmpInst` or a rail leaf. An
`and`/`or`/`xor` tree is a legitimate region condition the peel cannot clone
cheaply (`control_peel_reject_cond_tree.ll`). Declined.

**Q6 — OQ-3, the identity phi (P6).** Left in place, so `soleMergePhi` still
refuses and the region still declines
(`control_peel_reject_identity_phi.ll`). Peel it anyway / erase it as a benign
live-range extender / keep declining — not decided.

**Q7 — what this round did NOT probe, stated so the next round does not assume
it was.** SCOPE H-5's FLAT half IS probed and clean — `z20_inplace_xor_bridge`
(an in-place `cqrt_xorc` on the condition wire before the region: the xorc fires
ONCE, before BOTH flag mints, so the clone is a second READ and never a second
mutation) and `z21_inplace_xor_after_merge` (a second in-place xor in the MERGE
after the phis: the clone is inserted at `getFirstNonPHI`, i.e. BEFORE it, so both
flags read the pre-mutation state exactly as the branch did). Both ACCEPT, both
2b-clean, both DECLINE `control flow` on the oracle. **Neither is committed as a
fixture** — they are probes only, and a reviewer who wants the property pinned
should say so. H-5's LOOP half is removed by P9, not discharged. NOT probed: (i)
the `InPlaceRailOps` / `staleRailRecordRead` interaction under a rolled loop,
which P9 puts out of reach rather than answering. SCOPE §15.4's two shapes ARE
probed and clean: `z22_argument_incoming` (an `Argument` incoming — it becomes
`cqrt_alloc_i32(i32 %u)`, the shipped 4.4 mechanism) and `z23_pred_phi_incoming`
(an incoming that dominates `BI` only through a CLASSICAL phi in `Pred`); both
ACCEPT, both 2b-clean, both decline `control flow` on the oracle, neither
committed as a fixture. (ii) NOT probed: the same pair, and a peeled select
generally, INSIDE a Phase-6 specialized clone body. (iv) The interaction with
`classifyGuardedStoreArm`: a store arm beside a `>= 2`-phi merge declines
`guarded store with a merge value` today and, if every phi peels, would become an
ACCEPT — reachable by P1, not probed, accept-monotone but unexpected.

**Q8 — the `sed`/`diff` RUN lines.** `control_peel_stateprep_datamux.ll` is the
first fixture in the tree to (a) run a SIBLING fixture through the pass and (b)
use `sed`/`diff` on a RUN line. `lit.cfg.py` uses `execute_external=True`, so a
real shell runs them and both tools are POSIX; the coupling is deliberate (it is
the byte-identity claim) but it is new, and it means editing the peeled-control
fixture can redden its partner.

**Q10 — THE MATRIX TABLE EDIT, and it is the one judgement call to re-take.**
Five `m_rz_*_rz` cells moved `DECLINE-BOTH-DIFFERENT` -> `UNROLLED-ONLY` and I
rewrote their rows (§4b). The move is accept-monotone and I verified the unitary
by hand, but it means **the peel is now a customer-generator for the ANGLE-select
path**: an fp merge phi whose consumer is a rotation's angle slot gets peeled and
re-adjudicated by `classifyAngleSelect`. The alternative — refuse to peel a phi
whose sole user is an angle slot — is ONE clause in `phiPeelable`, and it would
put the five cells back and keep the f64/angle wire strictly with
`classifyPhaseKickback`'s own tail machinery. I did NOT take it because it would
mean the peel re-implementing a `phaseAngleTail`-shaped question (a second
spelling of a Rule-13 predicate, Rule 14), and because `SelectClassify`'s gate 3
already owns that partition and demonstrably makes it correctly here. But
CLAUDE.md names the f64/angle crossing as a silent-miscompile family, and a
reviewer who wants the conservative side can have it cheaply.

**Q9 — assume a fifth thing.** The r9e5 round-1 reviewer said that and round 2
found F-B1R2-1. This round found one confirmed silent miscompile in its OWN first
spelling (§3), in the one place the design said it was safe — "taint follows the
phi" was a prediction, and the shipped fix replaces it with a re-run of the
authoritative walk. The same question should be asked of every OTHER thing the
peel copies from the phi: it copies the incoming VALUES and the debug location,
and nothing else, and nothing else was checked.

**Q11 — THE PEEL IS A NEW CUSTOMER-GENERATOR FOR bd `3d8q`** (Rule-13 ROUND-2
finding **F-B6R2-2**, ARGUED; DOC-only, no code). `S03` is `S02`'s program with
the `add` replaced by a SECOND chained theta — two SIBLING `cq_theta` on ONE
peeled mux rail, both measured. It accepts at `opt` exit 0, STRICT 2b clean, and
emits `ry(h8,0.2); ry(h8,0.6); measure(h8); measure(h8)`: `r1` is measured as
`Ry(0.6)Ry(0.2)|m⟩` where the source names `Ry(0.2)|m⟩`. Two `non-diagonal gate
over a live derived record` WARNINGS fire and nothing declines.

**It is NOT the peel's defect, and that is MEASURED rather than argued**: `S04` is
the same defect with **no peel anywhere in the program** (`int m = q + 1; r1 =
cq_theta(m,.2); r2 = cq_theta(m,.6);`) and it reproduces on the **ORACLE**, exit 0,
8 lines, one register. This is CLAUDE.md's open P1 bd `test_C_libtooling-3d8q` —
*the pass-wide stale-record guard sweeps PURE ops only, so a `cq_theta` or
`cq_measure` READER of a stale name is never asked*. `S03` is byte-identical to its
hand-peeled twin, so the peel reproduces the hand peel here as everywhere.

**What IS this increment's is the POPULATION.** A 4.4 merge OUT-RAIL is now a
shared parent, so `3d8q`'s customer set grows with the peel — and its fix will have
to cover a rail **nobody wrote in the source**, which none of its own reproducers
has. It belongs in the `3d8q` row rather than here, but it must be written down
before `3d8q` is scoped. The orchestrator has appended it to the issue; the three
probes are committed under `probes/S0{2,3,4}_*` with the README table.
