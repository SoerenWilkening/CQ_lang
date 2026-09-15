# Owner decisions — session 2026-09-15

Asked by the orchestrator at session open, as the ONE EARLY BATCH the brief's §5 requires, from the
four items carried as "OPEN WITH THE OWNER" since 2026-09-14. Answers are the owner's selections,
verbatim option labels; the rationale below each is the orchestrator's record of what was put to the
owner, **not a rule** (Rule 0 / L7 — a rule lives in `CLAUDE.md`, `ROADMAP.md` or a PRD, never in a
record).

⚠ Two of these four create work that was **not in the session brief**. That is recorded here rather
than absorbed silently, because the brief's track list is now incomplete by exactly those two items.

---

## E1 — bd `dnqo`, an `undef`/`poison` ROTATION ANGLE: **KEEP IT ACCEPTING**

Put to the owner with last session's four F-U1-1 measurements, all pointing away from a decline: the
genuine literal-pairing hazard (`declineUnpairedUndefLiterals`) still fires; the survivor occupies
exactly one emitted gate slot; the blessed precedent
(`lowering_accept_undef_literal_single_slot.ll`) is an ALLOC operand; and a materialized undef is
already committed in a shipped golden (bd `u7z9`).

**RULED: ship as-is. No conjunct is added.** A single-slot `undef` rotation angle stays blessed;
`cqrt_ry_<W>(h, undef)` links, runs and prints a garbage angle.

⚠ **The honest statement, which must be the one written down:** CQ does not model an uninitialized
rotation angle. This is not "undef angles are safe" — it is a scope boundary, in the same family as
the `fenv` ruling of 2026-08-10, and it should be recorded the way that one is (a named scope
exclusion) rather than as a property of the lowering. **bd `dnqo` closes as `wontfix`/`by-design`
with that wording**, not as "measured safe".

## E2 — bd `fve8`, the φ clause disarming ruling clause 4 upstream of the sink: **MAKE BOTH ACCEPT**

The measured asymmetry: `cq_measure` of an `undef` **declines** by the 2026-09-14 ruling's clause 4
when spelled directly, but bd `z9t1`'s φ clause deletes the `undef` **before** `MeasureLowering` ever
sees it, so the φ-routed spelling compiles — 4 of 710 rows going oracle-exit-1 → subject-exit-0 with
**0 bytes of stderr**, every one byte-identical to its written-zero twin.

**RULED: retire clause 4 for `undef` at the sink entirely.** `cq_measure` of an `undef`/`poison`
operand measures the type's concrete zero, in **every** spelling — the direct one included. The
asymmetry is closed in the ACCEPT direction.

⚠ **This RETIRES PART OF THE OWNER'S OWN 2026-09-14 RULING** (bd `z9t1` clause 4) and is therefore a
code change with a red-green obligation, not a documentation change: the shipped decline fixture for
the direct spelling **inverts** to an accept, and the decline string
`cq_measure_<sfx> operand is an undef/poison literal` loses its last customer. Whoever lands it owes
(a) the inverted fixture pair, (b) a check that no OTHER customer of that string exists, and (c) the
same **refinement** argument `z9t1` shipped — the emitted stream must be byte-identical to the
written-zero twin, **measured**, not asserted. **Track M.**

## E3 — bd `yiid` (P1), how wide to model `cq_measure` as a wire event: **(b) BROAD**

The capability was already ruled IN by the owner on 2026-09-14 — *"so using `cq_theta` after
measurement is completely fine, it just requires a `c_alloc` again"*. What was open is the width.
Today `cq_measure` is a taint SINK **and nothing else**: not a non-diagonal gate to `WireWalk`, never
returned by `findNonDiagonalWireGate`, never in a barrier set — so a post-measure re-rotation
silently CHAINS on the measured rail, which is the wrong circuit, and reading a name after measuring
it compiles in every spelling.

**RULED: (b) BROAD — taint STOPS at `cq_measure`, POSITION-AWARE.** Every use of the name positioned
after the measurement is treated as fresh/classical rather than as the same rail. (b) subsumes the
narrow reading (a) (a fresh rail on re-rotation only), and was the round-2 reviewer's recommendation
on four grounds recorded in `…/session-2026-09-14-orchestrator/trackD/IMPL_D.md` §14.

Costed there at **2 goldens, 0 shipped accepts, no ABI change, no new symbol**.

⚠ **This is a P1 capability build in the TAINT CORE, so it is Rule-13 core by definition** and it
composes with the headline's own taint-rule change (both touch `TaintPropagation.cpp` and
`MeasureLowering.cpp`). It is therefore **sequenced after** the headline rather than composed with it
blind — `MERGE_FILINGS` F-1's lesson, applied before the fact instead of after. **Track M.**

⚠ **`IMPL_D.md` §14's own warning is carried verbatim:** *"Do not read this as a capability. Nothing
in the pass implements it."* That is still true at the start of this session.

## E4 — bd `zwtm`, the owner's canonical customer program is not in the repository: **KEEP `example/` EXCLUDED; THE e2e SLICE IS THE RECORD**

`example/` is in `.git/info/exclude`, so `example/grover/grover_oracle_uncompute.c` is local-only and
"the owner's file compiles" is not a claim any gate can check.

**RULED: `example/` stays excluded.** The program is committed instead as a `tests/e2e/slice_*.c` +
golden by the track that lands the accept, which makes the claim **gated** rather than merely
measured.

⚠ **The stated cost is DRIFT — two copies of one program.** The mitigation is an obligation on the
landing track, not a hope: the slice must be **byte-identical in its code body** to
`example/grover/grover_oracle_uncompute.c`, and the slice's header must say so and name the source
file. **bd `zwtm` closes when that slice lands**, with the drift risk recorded rather than resolved.

⚠ **CORRECTION, orchestrator, 2026-09-15 — and it matters because this ruling's whole mitigation is a
byte-identity obligation.** When this ruling was recorded the orchestrator wrote that the live file's
code body *"matches the session brief's reproduction exactly"*. **That is false.** Track B-scoping
measured the two against each other and they differ in whitespace — a **trailing space** and a
**double space** — and the owner's code body is **not contiguous** in the file (it is interleaved with
commented-out history). The brief's reproduction is a faithful *transcription*, not a *copy*.
`trackB/probes/b01_owner_verbatim.c` carries the exact `sed` recipe that extracts the real body.
**The landing track must take its slice from the FILE by that recipe, never from the brief's code
block.** The orchestrator's original claim was an eyeball comparison reported as a measurement, which
is the error this project files against its own instruments (L10).

---

## Carried from previous sessions, still open with the owner, NOT asked this session

* **bd `bbu0`** — should the dephasing class be declined at `warnLiveRecordRotations` (strictly more
  complete, a WARNING by owner ruling bd `lyyf`, fires on 5 of 366 accepting slices) instead of at the
  second, narrower `declineDephasingUnmarkedLoopRails`? Track S' carries it **as a question, not a
  fix**, and brings it back here rather than ruling it (L7).
* **bd `wt3l`** (P1) — a USER `Rz` on a rail the spine later uncomputes: three inconsistent treatments
  today (cancel / leak / keep), and the textbook phase-kickback oracle is silently lost in two of them.
  Not scheduled this session.

---

## E5 — the HEADLINE is NOT reachable this session: **(A) LAND W1 ONLY; THE HEADLINE WAITS**

Asked mid-session, not at open, because the question did not exist until Track B measured it. The
session brief's premise — that the owner's rolled loop script is blocked by bd `de8n` + bd `n74d` plus
the three deferred W1 pieces — is **measured FALSE**.

Track B hand-emulated all three deferred pieces on the promoter's own output and found **four** walls
(`trackB/SCOPE_B.md` §1, probes `derived/B2,B3,B6`):

| wall | decline | owner |
|---|---|---|
| 1 | `cq taint escape: tainted value stored to memory` | W1 piece 3 |
| 2 | `value-arm swap-route` @ `%27 = zext i1 %26 to i8` | W1 piece 2 |
| 3 | `control flow inside a loop body under quantum control` | **`iterationLocalRollable` (c3)** — not W1 |
| 4 | `loop-carried tainted value crosses iterations` | **X1 / bd `ej5w` / W3** — not W1 |

⚠ **Wall 3 is BANK-INDEPENDENT, and the orchestrator verified it on the ORACLE before escalating**:
`b02_scalar_measure_a_outside.c` is the same loop with a **scalar `bool` and no array at all** and
declines identically (exit 1, `control flow inside a loop body under quantum control`);
`b05_scalar_classical_acc.c`, identical but with the arm not feeding `a`, **accepts** (exit 0). The
trigger is **the arm writing a value measured after the loop**, not the bank. Piece 1 taints loads
defined *outside* `L`; (c3) quantifies over values defined *in* `L`. The rail bank cannot move it.

⚠ **The four-wall table is NOT EXHAUSTIVE, and Track B said so unprompted when asked.** Its words:
*"the first four I could reach"* — every row is *"the first decline once the row above is gone"*,
because `LLVMContext::diagnose` EXITS on the first `DS_Error`, so rows 3 and 4 are **the first two
declines of an unknown-length tail**. There may be a wall 5; there is no evidence either way, and
nothing short of a binary with W1 + (c3) + W3 present will settle it.

**RULED: (A).** Land W1's second half; the headline waits. The honest closing claim is
***"the bank compiles; the owner's cascade needs (c3) + W3"*** — and it must be stated in those words,
not as "the decline moved".

**Rationale as put to the owner** (three costed options in `trackB/SCOPE_B.md` §1.4, corrected by the
follow-up in §E5.1 below): the full attempt is **~800–1250 pass lines and ~9 Rule-13 rounds across
THREE Rule-13-core capabilities**, it merges the rail-bank group with the two tracks already live in
`LoopLowering.cpp` at two named semantic seams, **and it may still not compile.** Against that, W1's
own accept shapes are real, gated and byte-identity-witnessed, and **W1 closes a measured silent
miscompile** Track B reproduced with a trace: piece 3 without piece 1 gives `opt` exit 0, STRICT 2b
`0 violation(s)`, a 6-line trace, and **three written `cq_measure` calls emitting nothing**.

⚠ **Rule 17 check, stated so it is not mistaken for a punt.** This is **not** a decline substituted
for a lowering we set out to build, and it is **not** an over-decline of a valid circuit. It is a
**scope** decision: the capability the headline needs was never in this session's scope, was not
costed in its brief, and is now filed with a measured cost. The headline is **deferred with a named
path**, not abandoned — and per the owner's 2026-09-11 ruling the walls 3 and 4 declines remain
**defects to remove**, tracked as such.

### E5.1 — two corrections Track B landed on its own §1.4 when the orchestrator pressed it

* **Option (B)'s cost did NOT include (c3).** The `~200–300` / 3-rounds figure was SCOPE_L1a §6.6's W3
  row copied forward, which is about X1 and nothing else. **(c3) is separate: ~150–250 pass lines and
  ≥2 Rule-13 rounds** (derived, calibrated against `94c085e`: one conjunct added to one F2 test,
  +231/−107). The body is one 16-line function, `iterationLocalTaintEscape`
  (`LoopLowering.cpp:4143-4158`), deliberately **one body with two callers** (`ArmClassify.cpp:3903`
  at round-1 taint, `LoopLowering.cpp:4489` at final taint) — so widening the body moves both, and
  *that* half is cheap. The expensive half is the **argument**: a bare ACCEPT-direction relaxation of a
  Rule-13-core predicate whose own source comment (`:4432-4463`) records that its previously-shipped
  rationale was **measurably FALSE** (F-W2-2) and **warns a future widening off leaning on it by name**.
* **The live X1 site is the ROUND-2 TWIN `:2579`, not `:2136`** — deduced from two measurements, not
  guessed: B3 and B6 differ *only* by the post-loop `cq_measure(a)`, which changes neither operand's
  taint nor the CFG, so `lowerLoops` (`CQLoweringPass.cpp:455`, **before** `detectControlRegions` at
  `:537`) behaves identically on both — and B3 did not die there. Consistent with the orchestrator
  comment at `:541`. ⚠ **That is exactly the site SCOPE_L1a warns about** (*"both X1 sites must move
  together or round 2 re-declines what round 1 accepted"*).

### E5.2 — what the (c3) widening's own seams are, recorded before anyone builds it
Track B named two, and was explicit that it **could not bound them** because it read neither track's
edit — *"I can assert the seams exist and I cannot tell you whether the diffs overlap."*
* **Track T.** `declineUnmarkedRolledIterLocal`'s conjunct 2 reads `taint.IterationLocalBlocks`, and
  its own comment names that set's other consumers as **`FreePoint` and `Uncomputation`** — which
  *"run at `uncompute`, AFTER `lowerBreakReversePlay` creates blocks, and read it in the same relaxing
  direction"* — filing that exposure as pre-existing. A (c3) widening **enlarges the population
  reaching those readers**.
* **Track S′.** A (c3) widening admits exactly the shape that leaves per-trip rails live across the
  loop boundary, i.e. it **grows the dephasing population** S′ is measuring. S′'s *"5 of 366 accepting
  slices"* figure would move under it.
**⇒ If (c3) is ever built, it is a SEMANTIC group with S′ and T**, and the cheap first check is to diff
their touched line ranges against `4143-4158`, `~4380-4560`, `2136` and `2579`.

---

## E6 — bd `bbu0`: **(D) FIRST — REORDER SO THE DECISIVE MEASUREMENT BECOMES POSSIBLE**, then rule A/B/C on the number

Track S′ carried this as a question and **explicitly did not rule it** (`trackS/QUESTION_bbu0.md`), as
its brief required. ⚠ **It also contradicted the bead's own charge, with a measurement behind each
half** — and the correction makes the question **harder**, not easier:

* **The bead's FIRST half survives.** The warning fired on **all three** members the 14c fence missed
  (counts 1, 1, 2 on the ORACLE) — *it saw bd `c767` and bd `7845` before this track did.* On the
  measured set it has never been silent where the fence speaks.
* **The bead's SECOND half — "a SECOND SPELLING … the Rule-14 / drbq Inc-3 (b′) defect" — is the WRONG
  CHARGE.** They are two **different questions** whose populations nest:
  `warnLiveRecordRotations` asks a **PHYSICS** question about **one emitted circuit** (*"does a live
  derived record stand at a non-diagonal gate on this wire?"*), which is exactly why it fires on
  `slice_control_inplace_ry_loop_leak` **and** its `_unrolled` twin — *both circuits carry the hazard,
  so a predicate about circuits must report both; that is the guard working, not over-firing.*
  `declineDephasingUnmarkedLoopRails` asks a **COMPILER-CONSISTENCY** question (*"did ROLLING lose a
  discharge this same compiler performs on the straight-line spelling?"*), a property of a
  **DIFFERENCE between two compilations**, which **no single circuit can answer**.
  ⇒ **divergence ⇒ hazard, hazard ⇏ divergence.** The superset relation the bead measured is the
  **logical shape of the pair**, not evidence of duplication.
* ⚠ **A WEAKER version of the charge IS still true and still worth fixing:** the two stages compute
  **overlapping RECORD SETS by two different walks** (`RecordSet` + `collectAncestorRecords` /
  `collectDescendantRecords` + `recordAbsentAt` / `recordIsExemptAt` on one side;
  `taintedAncestryReaches` + `railIsInterior` on the other). **That** duplication is real — *a
  duplication of the record WALK, not of the VERDICT.*

**THE LOAD-BEARING GAP, and it is why (D) was ruled:** the question *"is the warning ever SILENT where
the fence speaks?"* **cannot be measured on any binary in the tree.** The fence is at
`CQLoweringPass.cpp:772`, the warn stage at `:864`, and `LLVMContext::diagnose` **EXITS on the first
`DS_Error`** (bd `br4a`) — so every module that declines at the fence **never reaches the warning**, and
every "0 warnings" row in S′'s table is **0 BY PREEMPTION, NOT BY SILENCE.** ⚠ S′ **did not construct a
counter-example and explicitly does not claim one exists** — *"round 1β's discipline applies to me too:
did not reproduce, did not claim unreachable."*

**RULED: (D).** Emit the warnings **before** the fence's decline, or have the fence consult the
warning's record set. It **decides nothing semantically** and must not be traded against A/B/C; it is
the only item on the list that turns the gap from an argument into **a number**. A/B/C are then ruled
next session **on that number**.

⚠ **What the measurements already say, carried so the later ruling starts from it, NOT as a ruling:**
they are **consistent with C** and give **NO evidence for B**. B's only measured cost is 5 of 366
accepting e2e slices, one of them a **byte-identical twin PAIR** under a shipped gate — *"not a number
a decision should rest on"*, and **the over-decline charge against B is itself unproven**, since byte
identity cannot certify that pair correct (L10's `m_none_pbitd_none_premark_rypost`, from the other
side). And **C is exactly the change that would HIDE the gap** if the warning ever is silent where the
fence speaks. Hence (D) first.

**Carried, not answered** (S′ §6): bd `lyyf`'s reason was **reporting completeness, not benignity** —
any promotion argument must engage that, and *"emit all warnings, then decline"* preserves it. And the
warning is **silent on all 42 confirmed miscompiles of the drbq Inc-4 F2 class** by its own header: it
is specific to the "live derived record" shape and is **not** a general dephasing detector. **Neither
is the fence. Neither is coverage.**

## E7 — bd `yiid` / E3 question 7.1 (the output-tape contract): **DEFER — RULE IT WITH THE 7.6 INCREMENT**

Under (b) BROAD a second `cq_measure` of the same name lowers classically — **no symbol, no gate, no
trace line** — and on `lowering_io_tape_measure_then_tape` that costs `cqrt_tape_alloc` +
`cqrt_tape_write_i32`, replaced by a plain `printf`. The circuit is **right** (measurement is
idempotent); the **contract** is the question, and the 7.6 output-tape ABI is one of the five items the
**freeze** is gated on.

**RULED: defer.** `IMPL_D.md` §14.7's own closing line — *"decide that with 7.6, not here"* — stands,
now with a **measured customer** in the tree rather than as a forecast.

⚠ **CONSEQUENCE, stated because it is a scheduling fact and not a detail: E3 now sits BEHIND 7.6 in the
queue.** E3 cannot land until this is answered, and it is answered by an increment that has not
started. Record it that way on bd `yiid`; do not let a future session read E3 as "scoped and ready".

## E8 — bd `yiid` / E3 question 7.2 (the regressed shipped accept): **FIX IT — TEACH `AngleSelectEmit` A CLASSICAL BASE**

E3 turns a CHAINED theta into a SOURCE theta, and the folded angle-select's Ry stem **requires a
quantum base** — so `control_angle_select_ry_alias_pre_gate`, a **shipped and Rule-13-CLEARED ACCEPT**,
becomes a DECLINE (`rotation angle under quantum control`). `IMPL_D.md` §14 does not mention this
shape; **Track M found it by measurement**, not from the design.

**RULED: fix it properly.** `AngleSelectEmit`'s Ry stem learns to accept a **classical base value**.
The shipped accept is kept and the regression is removed at the root.

**NOT ruled, and both explicitly rejected:** *fence E3 to exclude the angle-select shape* (a conjunct
added to a taint-core predicate to protect an **emitter's bookkeeping** — CLAUDE.md **L6**: *only a
unitary hazard is a Prime-Directive decline*), and *accept the regression and file it* (it would be the
**first time this project knowingly regressed a Rule-13-cleared accept**, and it is the weakest option
by the owner's own 2026-09-11 over-decline ruling).

⚠ **CONSEQUENCE: E3 grows a SECOND dependency.** Together with E7, the deferred E3 increment now reads:
**7.6's tape ruling → `AngleSelectEmit` classical base → E3 (b) BROAD.** That is a three-increment path,
and it must be written on bd `yiid` as such. It is no longer "one increment of its own".

---

## E9 — bd `fve8` F-E2-1, the vanishing QUANTUM measurement: **ACCEPT, AND DISCLOSE THE QUANTUM RIVAL**

Found by the independent Rule-13 round on Track E2 (`review_r13_e2/REVIEW.md`, verdict **FINDING**, 1 × P1
+ 2 × P2). Put to the owner mid-session with the mitigation measured, not argued.

**The finding.** `int u; int q = cq_theta(0,0.3); return cq_measure(q + u);` — `clang -O1` folds
`add nsw %q, undef` → `undef`, so E2's clause (1a) fires on what the author wrote as a **QUANTUM**
measurement. ORACLE: loud decline. SUBJECT: **exit 0, 0 bytes of stderr, 2 trace lines, and NO
`cqrt_measure` in the emitted module at all** — while the C-level written-zero twin emits 3 lines
**with** the measurement. **A user-written measurement disappears with no diagnostic.**

⚠ **THE INSTRUMENT AGREED WITH THE BUG.** E2's own `refinement_check.py` reports this module
**BYTE-IDENTICAL**, because the one-token IR twin **inherits the very fold that erased the taint** — so
the gate built to catch this class **cannot see it**. That is CLAUDE.md **L10** arriving on a checker
this repo ships, and it must be written into the disclosure rather than left in a review file.

**RULED: accept as built, and EXTEND THE DISCLOSURE to name this rival** — E2 today discloses only the
purely **classical** reading.

**Grounds, as put to the owner:**
* **The class PRE-EXISTS at HEAD.** `q * u` and `q & u` fold to a concrete `0` and **already ship this
  exact circuit on the ORACLE**. A decline here would be a **new** refusal that leaves the pre-existing
  spellings untouched — it would not close the class, only the `undef`-folding half of it.
* **After `-O1` no predicate can separate the readings**, so the mitigation is **disclosure** — the same
  shape as the F2 α/β narrowing and the bd `z9t1` disclosure, both ruled the same way.
* What E2 adds is **the `undef`-folding spellings and the silence**, not the behaviour.

**NOT ruled, and explicitly rejected:** *decline when the folded operand was ever tainted* (it needs a
taint-history test that survives `-O1` having already erased the taint — CLAUDE.md **L5**: *a syntactic
answer to a semantic question loses*); *reverse E2 entirely* (it would reinstate the asymmetry ruled
against this same day, and still not touch `q * u` / `q & u`); *defer to 7.6* (E2 is built and gated).

⚠ **NO WARNING** — the owner has ruled against a warning on this family twice: *"both codes are supposed
to compie!! also no warnings."*

⚠ **This ruling is about a program whose user-written measurement VANISHES SILENTLY. It is recorded in
those words deliberately.** The honest statement is not *"the circuit is right"* — it is *"the class
already ships at HEAD, no fence can separate the readings after `-O1`, and CQ therefore does not
diagnose it."* Whoever quotes this ruling must quote that sentence with it.

**Retirement trigger:** the day a taint-history record survives `-O1` folding — or the day `q * u` /
`q & u` stop shipping this circuit on `main` — the pre-existence ground is gone and this must be
re-derived from scratch.
