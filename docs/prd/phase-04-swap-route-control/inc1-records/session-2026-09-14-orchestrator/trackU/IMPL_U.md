# Track U — IMPLEMENTATION record: bd `z9t1`, the undef seed is a zero at the allocation

Worktree `/Users/sorenwilkening/Desktop/CQ_undef`, branch `undef-seed-zero` (off `main` 607b6fe4).
Binaries and every gate line: `GATES.md` (hash-keyed). Probes and instruments: `probes/`.

**Headline.** Both ruled spellings compile, silently, exit 0. `bool b; b = cq_theta(b,.5);` keeps
compiling but its rail is now deterministically |0⟩ instead of whatever the `-O0` stage 3
materialised (the oracle's own trace opened `cqrt_alloc_i1(1) -> h0`, a value the program never
wrote). `bool b; if (c) b = cq_theta(b,.5);` compiled **not at all** before — it was a loud F1
decline — and now emits the same controlled state prep the initialized program gets. The strongest
single measurement in this record: the owner's 2026-09-13 cascade with **one token deleted**
(`_Bool b1 = 0;` → `_Bool b1;`) produces a trace **byte-identical** to the shipped
`slice_control_cascade_two_bools.expected.log`, 29 = 29, now pinned as a ctest twin gate.

---

## 1. The site, and why it is that site

**`normalizeUndefRotationSeed`** is defined in `ir-pass/src/RotationLowering.cpp` (declared in
`RotationLowering.h`) and has **exactly one call site**: `collectAndSeed`'s `IsTheta` arm in
`ir-pass/src/TaintPropagation.cpp`, i.e. **inside `propagate`**.

*Concern ownership* (Rule 14): the rule attaches to the QUBIT ALLOCATION, and `RotationLowering` is
the module that owns what a `cq_theta` arg-0 means (`Chained` vs source, the `cqrt_alloc_<W>` mint,
the width). `TaintPropagation` contributes only the funnel.

*Why the funnel* — the ruling's clause 2 forces it and the L1 obligation is discharged by it:

* **Clause 2 requires EARLY.** Normalizing at the emission site (`lowerRotations`) is measurably
  wrong: the in-region spelling dies ~500 lines earlier at F1's `state prep seed does not match the
  merge incoming`. `collectAndSeed` runs before every classifier, every peel and every detector.
* **L1 (control detect+lower runs TWICE) is discharged STRUCTURALLY, not by a record.** `propagate`
  is the one funnel that BOTH entry points and every re-propagate fixpoint round come through — 9
  call sites in `run`, 8 in `runOnFunction` — and every stage that DUPLICATES a theta
  (`LoopUnrollPrepass`, the PredMux / fp80-union / ctlz fixpoints) is followed by a full
  `taint = propagate(M, wd)` in its own loop. There is no second call site to forget: the failure
  mode L1's cure exists to prevent (`markBranchPhaseGate`'s "a seventh emitter forgets it") cannot
  arise with one site inside the funnel.

  > ⚠ **AMENDED — that discharge is the SEED half's, and the PHI half is ONE-SHOT (review round 3,
  > F-U3-4).** The function early-returns once the seed is concrete (`valueCarriesUndef(i32 0)` is
  > false), so **from the second propagate round onward the phi loop is UNREACHABLE**. The function
  > is therefore *idempotent*, and "re-asked at every fixpoint round" means, for the phi half,
  > "re-asked and the answer is *nothing to do*". An undef phi incoming that **appeared or was
  > exposed between rounds** would be left alone, F1 would compare `i32 0` against `undef`, and the
  > module would **decline** — the over-decline direction, and an L1-species asymmetry the record did
  > not name.
  >
  > **It is unreachable today for three MEASURED reasons, and this fix round re-ran every grep itself
  > rather than inheriting them (Rule 11) — finding two write-spellings round 3's greps did not
  > cover:**
  >
  > | limb | measured, `ir-pass/{src,include,tools}` | verdict |
  > |---|---|---|
  > | **(a)** nothing rewrites a phi incoming but this clause | `setIncomingValue` — **1 site**, `RotationLowering.cpp:274`, the loop itself. ⚠ **the write-spelling FAMILY is wider than that one name** (lesson L2): `addIncoming` **3 sites** (`Specialization.cpp:487` a clone `ret` value; `BreakReversePlay.cpp:834`/`:837` two `sub` Instructions), `removeIncomingValue` **2** (`CtlzIdiomPrepass.cpp:433-434`, which only REMOVES) | none can put an `undef` on a theta-carrying phi |
  > | **(b)** the pass mints no undef at all | `UndefValue::get` / `PoisonValue::get` — **0 call sites**; the single textual hit is the comment at `LiteralIntegrity.h:136` recording that this grep is clean | holds |
  > | **(c)** both phi minters are structurally excluded | `PHINode::Create`/`CreatePHI` — **2 sites**. `cqq.ret` (`Specialization.cpp:484`) merges CLONE RETURN VALUES and `SpecializeReject::scanBody` rejects any body containing a call in `Sets.Rotations` (`SpecializeReject.cpp:636`, seeded from `taint.ThetaCalls` at `:53` — its own "load-bearing precondition R2"), so no theta result can be returned and that phi can never be a theta user. `cq.brk.ip` (`BreakReversePlay.cpp:831`) takes exactly `NMinus1` and `IDec`, both `sub` Instructions | holds |
  >
  > **(d) NOT enumerated, stated rather than implied:** a RAUW whose replacement value is an `undef`
  > **already present in the input module** could in principle land on a phi incoming. Limb (b)
  > bounds it — the pass creates no new undef — but the RAUW targets were not enumerated. ⚠ And limb
  > (c)'s R2 carries the qualifier F-U1-3 already put on it: `Sets.Rotations` is **exact-pointer**
  > over `taint.ThetaCalls`, so a theta clone minted after the last full `propagate` is invisible to
  > `scanBody`.
  >
  > ⚠ **RETIREMENT TRIGGERS, one per limb:** (a) a **second writer in the phi-incoming write family**
  > appears; (b) any `UndefValue::get` / `PoisonValue::get` call site appears; (c) a **third**
  > phi-creation site appears, or either existing one stops being excluded (R2 stops rejecting
  > `Sets.Rotations`, or `cq.brk.ip` gains a non-`sub` incoming). On **any** of them the phi half must
  > be **re-asked after the round-2 fixpoint**.
  >
  > ⚠ **AND THE FIX IS A SECOND ENTRY POINT, NEVER A RELAXED GUARD — correcting round 3's own stated
  > reason.** F-U3-4 says moving the seed guard "would make the rewrite non-idempotent". **Re-checked
  > here and that is not the hazard:** the phi loop *is* idempotent (`isa<UndefValue>` is false after
  > the first rewrite) and the one call site **discards the return value**
  > (`normalizeUndefRotationSeed(CI);`, `TaintPropagation.cpp:171`), so no fixpoint is driven by it.
  > The real hazard is the **seed operand**: the same guard is the ACTION guard for `setArgOperand`,
  > and relaxing it to reach the phi loop would let the rewrite fire on a seed that is not a
  > whole-value `undef` — the silent VALUE CHANGE the `isa<UndefValue>` conjunct exists to prevent.
* **THE INVARIANT HOLDS FROM BEFORE THE FIRST STAGE, AND IS TAINT-INDEPENDENT — lead with this.**
  *(Rewritten per review round 1, finding F-U1-3: the original led with the `specialize` walk, which
  is the weaker of two grounds and whose load-bearing clause needed a qualifier. All three limbs below
  re-verified from source in `FIX_U_R1.md` §4.)*
  1. `propagate` is the **first module-touching statement** of BOTH entry points — `run`
     (`CQLoweringPass.cpp:113-115`) and `runOnFunction` (`:747-755`). ⚠ Say "first module-touching",
     not "first statement": it follows the `WidthDispatch` construction (and, in `runOnFunction`, the
     `getParent()`), neither of which mutates the module. (`runOnFunction` is in-tree documented as a
     **DEAD SHIM** with zero callers.)
  2. `collectAndSeed` runs on **every non-declaration function** (`for (Function &F : M)`,
     `TaintPropagation.cpp:480-484`) and calls `normalizeUndefRotationSeed(CI)` on **every** theta
     **unconditionally** — not taint-gated, not region-gated. `resolveSources` (`:464`) precedes it,
     so arity 2 and `paramType(0) == returnType` are already proven.
  3. It can be broken only by MINTING an undef — `ir-pass/src` contains **ZERO** `UndefValue::get` /
     `PoisonValue::get` (measured; the one textual hit is a COMMENT at
     `ir-pass/include/LiteralIntegrity.h:136` noting that this grep is clean) — or by WRITING one into
     arg-0, and the four `setArgOperand(0, …)` sites (`AngleSelectEmit` ×1, `SwapRouteEmit` ×3) each
     write an SSA value.
  ⇒ *"No `@cq_theta_<sfx>` collected by `propagate` has a whole-value `undef` arg-0"* holds before any
  stage runs, in both entry points, independent of taint.
* **The `specialize` walk is then a COROLLARY, not the ground** — `repropagateControlMerges` re-seeds
  via `propagateFromSeeds`, NOT a full `propagate`, so that gap is where an L1 finding would live, and
  it was checked three ways: (1) `SpecializeReject::scanBody` REJECTS every body containing a
  `cq_theta`/`cq_phi` — ⚠ **stated precisely (F-U1-3): a theta THAT `propagate` COLLECTED.**
  `SpecializeReject.cpp:50-54` builds `Sets.Rotations` from `taint.ThetaCalls` by **EXACT POINTER**
  ("NEVER name-prefix — C7"), so a theta clone minted after the last full `propagate` is invisible to
  `scanBody`. Harmless for z9t1 (a clone of a normalized call is normalized, and it lands in the
  function being lowered, not in a callee candidate), but the unqualified sentence would be quoted
  against a different change later; (2) duplication is MONOTONE, a clone copies operands
  (`SwapRouteEmit`'s negated-arm `T->clone()` is the live instance); (3) the `setArgOperand(0, …)`
  audit above.
  ⚠ My first draft of this argument named `SpecializeClone`'s argument substitution as the hazard and
  leaned on a re-propagate that does not exist at that point; the correct answer is that the stage
  cannot host a theta at all. Recorded because the wrong version reads just as convincing.
* **Passthrough is untouched**: a module with no theta call has nothing to normalize.

## 2. What the rule does — and the two places it deliberately stops

```
if (!valueCarriesUndef(Seed)) return false;   // the ONE shared spelling (Rule 14)
if (!isa<UndefValue>(Seed))   return false;   // ... but only a WHOLE-VALUE undef is rewritable
Theta->setArgOperand(0, Constant::getNullValue(Seed->getType()));
for each PHI user of the theta: every UndefValue incoming of that phi := the same zero
```

**(a) The predicate and the ACTION are two different questions, and the safety polarity FLIPS.**
`valueCarriesUndef` is the shared owner and is called as the gate. But its answer is TRUE for a
`ConstantExpr` that merely *contains* an undef leaf, and there the action would be unsound:
replacing a whole-value `undef` with zero is a **refinement** (LangRef lets any value of the type
stand in), while replacing `ptrtoint (gep @g, undef, 1)` with zero is **not** — that expression
denotes an address and no choice of the leaf makes it 0. Everywhere else in the pass this predicate
gates a DECLINE, where over-firing is safe; here it gates a REWRITE, where over-firing is a silent
value change. Hence the second conjunct, and hence its own negative fixture. The ruling's own
justification does not reach the ConstantExpr case anyway: such a constant is UNIQUED into one
link-time relocation (bd `bu96`), so it has no multi-materialisation hazard to remove.

**(b) THE PHI INCOMINGS MOVE TOO — and the scope below is NOT "one object, read twice".**

> ⚠ **CORRECTED by review round 1, finding F-U1-2 (see `FIX_U_R1.md` §3).** This paragraph
> originally stated the rule as being about *one uninitialized object read twice*, and scoped it as
> "only where the object was undefined on BOTH edges". **The code checks no such thing**, and after
> `-O1` nothing could: probe `r08_two_objects_q.c` takes the seed from a *different* uninitialized
> object than the merge's straight-through incoming and lowers to a gate stream **identical** to the
> one-object spelling. The actual predicate is *a whole-value `undef` seed, plus **every** same-typed
> `UndefValue` incoming of **every** phi that has this theta as an operand.* The C-level story is a
> motivation, not a precondition, and an agent-authored precondition that hardens by repetition is
> exactly lesson L7. **The soundness ground is the per-`undef` refinement, stated below.**

For `bool b1; if (c) b1 = cq_theta(b1,.5);`, `clang -O1` writes the same uninitialized object twice:

```llvm
%3 = call i1 @cq_theta_i1(i1 undef, double 5.0e-01)   ; the SEED
%6 = phi i1 [ %3, %2 ], [ undef, %0 ]                 ; the MERGE INCOMING
```

Normalize the seed alone and F1's **second** sub-clause (the Pred incoming must be pointer-identical
to the seed) compares `i1 false` against `undef` — **the module still declines with the same
string**. I measured that before widening. So the rule is stated over the OBJECT: one uninitialized
object read twice becomes the same concrete zero at both reads; each rewrite is independently a
refinement, so the pair is sound for the same reason the single one is.

### The scope, corrected and MEASURED — F-U2-2 (round 2) and F-U3-2 (round 3), folded

> ⚠ **THIS LANDED IN THE RECORD IN ROUND 1 AND NOT IN THE SOURCE. It is the same finding three
> times.** Round 1 (F-U1-2) corrected the paragraph above; round 2 (F-U2-2) found the false "i.e."
> still in `RotationLowering.cpp` and specified the fix; **that fix never landed at tip `4044e49e`**;
> round 3 (F-U3-2) found it again and measured it *wronger than round 2 had*. It is corrected in the
> source now — `RotationLowering.cpp`'s scope paragraph, `RotationLowering.h`'s declaration comment,
> the phi-loop body comment, and `control_accept_undef_theta_seed_stateprep.ll`'s header.

The sentence that was false, in full, so it is recognisable if it is ever quoted again:

> *"A phi incoming is normalized ONLY when that phi carries THIS theta's result as another incoming —
> i.e. only where the object was undefined on BOTH edges."*

**The clause before the dash is what the code asks. The "i.e." is false, and the gap is not
marginal: the "i.e." describes a rule whose population is about FOUR modules; the shipped clause's is
164.** The code asks the first half alone — `for (User *U : Theta->users())`, then **every**
`UndefValue` incoming of every phi user — which is wider than "one object read twice" in **three
independent directions**, each measured over the **711** corpus modules containing a phi that carries
a `@cq_theta_*` result (round 3's `review_r3_probes/census_main.json`; **re-derived independently by
this fix round** from the committed artefact, all six figures reproduced):

1. **Several phis per theta.** The walk is over every phi USER, not the region's merge phi.
   **164 of the 972 carried thetas are carried by more than one phi**, and every undef incoming of
   every one of them is rewritten. Probe `pL_second_unrelated_phi`.
2. **Several incomings per phi.** The inner loop rewrites *every* undef incoming, not the Pred edge.
   **37 phis in that corpus have ≥2 non-theta incomings**, so **one visit can equate several distinct
   C objects**. Probe `pA_three_edges`.
3. **A different object entirely.** The seed's object and the straight-through incoming's object need
   not be the same one; nothing in the source equates them and the rule equates them anyway. Probe
   `pD_two_objects`, which moves `D→A` on that ground alone — and which is why the disclosure
   paragraph below exists.

**Measured population of the phi half**, isolated against a seed-only oracle
(`SUBJECT(undef seed + undef phi)` vs `ORACLE(zero seed + undef phi)`, 710 measurable modules):
**164 modules move** — 124 decline→accept, 39 decline-string changes, 1 IR-only. All 164 land
**byte-identically on the zero twin** (0 divergences, 0 `A→D`), which is why this is a scope
correction and **not** a correctness defect.

> ⚠ **TWO DIFFERENT 164s, EQUAL BY COINCIDENCE.** *"164 of 972 carried thetas"* (direction 1) is a
> **count of thetas**, from the census; *"164 modules"* is the phi half's **module population**, from
> the isolation sweep. Different instruments, different denominators. **Do not cite one as evidence
> for the other** — this warning is carried at every site either number appears
> (`RotationLowering.cpp` ×2, the fixture header, `FIX_U_R3.md`).

**The soundness ground is not the scope — it is the per-rewrite refinement.** Every rewrite is
`isa<UndefValue>(In)` → `Constant::getNullValue(T)`, and LangRef lets any value of the type stand at
an `undef`, so each one independently yields a circuit the source already licensed. The clause cannot
turn a *defined* value into a different one: the `isa<UndefValue>` test is literal and the
`ConstantExpr` residual is excluded by its own conjunct. **That argument never needed the "i.e.",
which is why removing it costs nothing.**

**Why the shipped decline fixtures stay green — the true reasons, because the false "i.e." was
carrying this weight and could not:**

* `control_inplace_ry_reject_stateprep_undef_incoming.ll`: its **seed is `i32 0`**, so
  `normalizeUndefRotationSeed` returns at the `valueCarriesUndef` gate and the phi loop never runs
  (round-1 F-U1-2's re-grounding, measured on both binaries, full-stderr sha `0af03bddc2cc` each).
* `control_peel_reject_{undef,poison}_incoming.ll` (`MergePhiPeel` P3b): the undef-bearing phi there
  is `%6 = phi i32 [ 5, %3 ], [ undef, %0 ]`, which **does not carry a theta** — and the
  theta-carrying phi in the same module (`%7`) has no undef incoming. **Nothing narrows; the two
  shapes miss each other.** Both headers now carry that as a RETIREMENT TRIGGER (L8), including what
  to check first if either ever goes red.

**The P3b interaction, real and previously unrecorded** (F-U2-2's second fix item, also landed only
now). Make that phi *carry* the theta and P3b stops firing: the incoming is a concrete `i32 0` by the
time the peel looks, so the peel proceeds and the module reaches F2 instead (probes
`pC_p3b_carrier` / `pC_peel_p3b_carrier.ll`, both binaries, zero twin identical). **That is sound on
P3b's own ground** — P3b's hazard is a literal read as two *different* values at the `-O0` stage-3
link, and a uniqued `i32 0` is single-valued, which is the same reason `MergePhiPeel.cpp` gives for
peeling a `freeze`. So the disarm and the removal of the hazard are the **same event**, and that is
the test to apply to every other undef-keyed gate this clause reaches. ⚠ **`GUARD 1`
(`declineUnpairedUndefLiterals`) is the one gate that fails that test** — a *counting* gate over a
population this clause only partially empties — and it is F-U1-1, open with the owner.

**AND THE PROPERTY WORTH CLAIMING, which rules out the F2 α reading** (derived by the round-1
reviewer, re-verified here): an `undef` seed is a **`Constant`**, and `valueCarriesUndef` returns
false for every non-`Constant` (`LiteralIntegrity.cpp`: `dyn_cast<Constant>(V); if (!C) return
false;`). A variable that was never written cannot be the condition's own live register — that would
be an `Instruction`. **So this rule can only ever produce a FRESH prep.**

> ⚠ **RE-GROUNDED (F-U1-2).** This paragraph used to keep
> `control_inplace_ry_reject_stateprep_undef_incoming.ll` declining by citing a "both edges" scope.
> That is the wrong ground and the reviewer measured the right one on both binaries (full-stderr sha
> `0af03bddc2cc` on each): **its seed is `i32 0`**, so `normalizeUndefRotationSeed` returns at the
> `valueCarriesUndef` gate and the phi loop is never reached at all.

**(b′) ⚠ THE DISCLOSURE — what this rule silently absorbs (review round 3, F-U3-3).**

> **This is the paragraph CLAUDE.md §4 requires and it did not exist.** The widening below is the
> same class as the F2 α/β narrowing: a loud refusal becomes a silent compile, no predicate can
> separate the readings after `-O1`, and the mitigation is therefore **disclosure, not a fence**.
> **The text below is the normative copy; the orchestrator carries it to `CLAUDE.md`, and the same
> text is at the mechanism in `RotationLowering.cpp`.**

**136 modules that the ORACLE loudly REFUSED now compile SILENTLY, and 116 of them move through one
mechanism: F1's pointer-identity proof is MANUFACTURED, not found.** F1's second sub-clause is a
literal `Value*` comparison — `MergePhi->getIncomingValue(PredIdx) != RotBase`
(`ArmClassify.cpp:3905-3908`, read in source by this fix round, not inherited) — and
`Constant::getNullValue` is **uniqued**, so rewriting a seed `undef` and a straight-through `undef`
to "the type's zero" makes them **the same `Value*`**, for two operands the source never equated.
The other 20 rows: 14 `control flow` (the `MergePhiPeel` P3b route above), **4
`cq_measure_<sfx> operand is an undef/poison literal`** — the ruled clause-4 decline reached
*upstream* of the sink, which is **F-U3-1, open with the owner, and NOT covered by this
paragraph** — 1 `condition predates a non-diagonal gate`, 1 `nested control flow`.

**The rival reading, stated as a program and not as an IR shape:** the seed and the merge's
straight-through incoming were **two different uninitialized C objects**, and the source never said
they were equal. `pD_two_objects` is the minimal witness — the prep seeds from object *X*, the
straight-through edge carries object *Y*, and it moves `D→A`. The compiler now treats them as **one
value** at the state-prep proof.

**Why the rival has no lowering to be robbed of — two halves, because either alone would be an
assertion.** (1) On the oracle the two-object module is a **loud decline**, so there was no circuit
for the other reading and nothing is displaced. (2) The accept it now receives is a **refinement**,
not a choice between two circuits: LangRef lets an `undef` stand for any value of its type, so `0` at
each read is a value the source **already licensed**, and the emitted stream is **byte-identical** to
what a written `= 0` on both objects produces — measured on all **164** modules of the phi half's
population, 0 divergences, 0 `A→D`. On the ¬flag component the fresh rail holds |0⟩, which is a value
object *Y* was permitted to have. **No fence is deceived about a value the program actually wrote.**

**Why disclosure and not a predicate.** After `-O1` there is nothing left to discriminate: *"one
object read twice"* and *"two objects that were both uninitialized"* are **the same module** —
`undef` is uniqued per type, so the IR carries no record of how many C objects there were. A fence
that refused the two-object reading would have to refuse the one-object reading this rule was **ruled
to compile**. And a warning was **deliberately not added**, for the same reason CLAUDE.md §4 gives for
the F2 one: it would fire on the owner's own ruled spelling — *"both codes are supposed to compie!!
also no warnings."*

⚠ **RETIREMENT TRIGGERS, three, each naming what would make this paragraph wrong rather than merely
out of date:** **(i)** F1's second sub-clause stops being a `Value*` **identity** test — a
value-equality or provenance test would make the manufacture *visible*, and that is the only place a
real predicate could live; re-derive from scratch. **(ii)** the clause rewrites anything that is not
`isa<UndefValue>`, or `undef` stops being uniqued per type — those are the refinement's only two
load-bearing facts, and either one gone makes this an **over-accept**. **(iii)** the 4 `cq_measure`
rows are **not** covered here: they are a ruled clause reached by a new route, and they are with the
owner.

**One positive from the same surface, recorded so the disclosure is not read as all-cost.**
`lowering_unroll_const_trip` is round 3's single `IR-only` row: at HEAD with an undef phi incoming,
LLVM constant-folds the `fma` to NaN and **the user's `cq_measure` disappears from the emitted module
entirely**; the subject restores it. bd `z9t1` *removes* a vanished user measurement here — it does
not create one.

**(c) SOURCE only, by construction.** A chained theta's arg-0 is an `Instruction`;
`valueCarriesUndef` is false for every non-`Constant`. So the rule can never disagree with
`lowerRotations`' own `Chained = taint.Tainted.count(arg0)` — there is no second spelling of that
relation to drift (the bd `9pum` L1 PREDICATE species). Pinned by
`lowering_accept_undef_theta_seed_chained.ll`.

**(d) Widths.** The zero is minted from the OPERAND's own type, which `declMatchesPrototype` has
already proven equals the suffix's `T`. All nine reachable types are covered with no width table:
`i1 i8 i16 i32 i64 half float double x86_fp80`. Three are pinned (`i32`, `double`, `x86_fp80` —
including `x86_fp80 0xK00000000000000000000`, the one spelling that is not obvious).

**(e) `cq_measure` is untouched and KEEPS DECLINING (clause 4), and the asymmetry is principled.**
There is no allocation, no register and nothing quantum at a classical measure of an indeterminate
object — a zero there would be an invented ANSWER rather than a chosen starting basis state. That
sentence is in the source at the call site, as the brief required. Measured unchanged: u1, u4,
`lowering_reject_measure_undef_operand.ll`, and the whole `slice_measure_classical_*` family.

**(f) ARG-1, the ANGLE, is never touched (Rule 3), and I measured what it does today rather than
changing it.** A poison ANGLE on a `cq_theta` still reaches `classifyConeNode`'s `Call->args()` scan
and declines `control flow under quantum control` — identically on the oracle and on this build (193
stderr bytes each). The paired-slot angle case (`cq_phi`, forward + negated adjoint) still declines
through `lowering_reject_undef_literal_paired_rz_angle.ll`, green.

> ⚠ **"Out of scope, unchanged, pinned" was the original last sentence here and IT IS FALSE FOR ONE
> COMPOSITION — review round 1, finding F-U1-1** (full measurements: `FIX_U_R1.md` §1–§2). Arg-1 is
> untouched **in isolation**. It is NOT untouched when the SEED is also an undef: the rule then
> deletes the seed's emitted slot, `declineUnpairedUndefLiterals` (GUARD 1) drops below its threshold
> of **2**, and a module the ORACLE declined compiles **silently** emitting
> `call void @cqrt_ry_f64(i32 %h, double undef)`.
>
> | probe | ORACLE `f7b65d8c` | this build `a5773be1` |
> |---|---|---|
> | `r14` `double d; d = cq_theta(d,d);` | exit 1, 246 B, `cq literal integrity: undef/poison literal reaches two emitted gate operands` | **exit 0, 0 B** |
> | `r15` two distinct uninitialized doubles | exit 1, 244 B | **exit 0, 0 B** |
> | `r21` `_Bool b; double th;` — seed and angle at DIFFERENT widths | exit 1, 248 B | **exit 0, 0 B** |
> | `r22` the surviving slot on a DIFFERENT theta | exit 1, 248 B | **exit 0, 0 B** |
>
> **So this increment moves modules through a THIRD diagnostic, which §6's mover taxonomy did not
> name.** It is a population widening of the deliberately blessed one-slot accept, not a new wrong
> unitary — and whether the ORACLE's decline was protecting anything is **an OPEN OWNER QUESTION**,
> because GUARD 1 is the *pairing* break and r14's two slots are two **independent** source operands
> that coincide only because `undef` is uniqued per type. **No conjunct was added** (coordinator hold,
> 2026-09-14). The four measurements the ruling needs — the genuine pairing hazard still fires; the
> survivor is exactly one slot; the blessed precedent is an ALLOC operand, not an angle; and the trace
> is reproducible across relinks and already committed at line 368 of
> `slice_libm_ld80_nexttoward.expected.log` — are in `FIX_U_R1.md` §2.

## 3. Diff summary

| file | ± | what |
|---|---|---|
| `ir-pass/src/RotationLowering.cpp` | +152 | `normalizeUndefRotationSeed` + the ruling, the refinement ground, the polarity-flip argument, the phi scope and the placement/L1 argument as a source comment |
| `ir-pass/include/RotationLowering.h` | +14 | its declaration + where it is called from and why |
| `ir-pass/src/TaintPropagation.cpp` | +34 | the ONE call site in `collectAndSeed`'s `IsTheta` arm + the placement/L1/`cq_measure`-asymmetry comment; one `#include` |
| `ir-pass/test/*.ll` | +5 new, 4 rewritten | see §4 |
| `tests/e2e/` | +3 slices, +3 goldens, +4 `add_test` | see §4 |

**No new runtime symbol, no ABI change, no YAML, no new diagnostic string, no `CQ.h` change.**

## 4. Fixtures — every one, with its verdict

### New (5 accepts + 1 decline + 1 substitute decline)

| fixture | verdict | what it pins | oracle |
|---|---|---|---|
| `lowering_accept_undef_theta_seed_zero.ll` | ACCEPT | `i1 undef` seed → `cqrt_alloc_i1(i1 false)`; no literal undef anywhere | RED — the oracle accepts this module too, but emits `cqrt_alloc_i1(i1 undef)`, so the CHECK and NOUNDEF prefixes both fail |
| `lowering_accept_poison_theta_seed_zero.ll` | ACCEPT | the `poison` spelling, one predicate covers both | RED |
| `lowering_accept_undef_theta_seed_widths.ll` | ACCEPT | `i32 0` / `double 0.000000e+00` / `x86_fp80 0xK000…0` | RED |
| `lowering_accept_undef_theta_seed_chained.ll` | ACCEPT | a CHAINED theta on a normalized rail: ONE alloc, two `cqrt_ry` on the same handle | RED |
| `lowering_accept_undef_theta_seed_phi_residual.ll` | ACCEPT | **clause 5's residual, pinned**: an undef through a `phi` is NOT normalized — `cqrt_alloc_i1(i1 %s)`, exactly the oracle's stream | GREEN (it pins today's behaviour on purpose) |
| `control_accept_undef_theta_seed_stateprep.ll` | ACCEPT | the in-region spelling (u2's `-O1` module, verbatim): the additivity prep `ry(h1,.5)` + `ry_controlled(h0,h1,−.5)` and the peeled mux | RED (was the F1 decline) |
| `control_inplace_ry_reject_stateprep_constexpr_undef_seed.ll` | **DECLINE** | F1 clause 1 through the OTHER door (a `ConstantExpr` seed, verified to round-trip with its undef leaf intact) **and** the negative half of the normalizer's red-green pair — point the rule at `valueCarriesUndef` alone and it goes red as an accept | GREEN (arm-kill control) |
| `control_predmux_reject_selectform_rotation_theta_poison_angle.ll` | DECLINE | the bd `u1rp` `Call->args()` scan pin, MOVED onto arg-1; declines identically on **both** binaries | GREEN on both |

### Rewritten (3 shipped declines that are now accepts — all three are §6 movers)

| fixture | before | after | note |
|---|---|---|---|
| `control_inplace_ry_reject_stateprep_undef_seed.ll` | DECLINE F1 clause 1 | ACCEPT: `alloc_i32(0)` + `ry_i32_controlled(flag, h1, .9)`, flag stripped and freed | the `reject` in the NAME is history; the clause-1 pin MOVED to the constexpr fixture (stated in both headers) |
| `control_inplace_ry_reject_stateprep_poison_seed.ll` | DECLINE F1 clause 1 | ACCEPT, **byte-identical lowered module to its `undef` twin** | now pins "one predicate, two spellings, one circuit" |
| `control_predmux_reject_selectform_rotation_theta_poison_seed.ll` | DECLINE `control flow under quantum control` | ACCEPT, the ordinary PredMux stream | **the one mover outside the brief's predicted strings — §6** |

⚠ **The three files are NOT renamed.** A `git mv` can be resurrected by a merge, leaving one module
under two names with contradictory verdicts and invisible to every review that ran before the merge
(lesson L8). Each header says so in its first paragraph; the rename is proposed as its own
rename-only change (§8).

⚠ **`lowering_accept_undef_literal_single_slot.ll` — the committed certificate the brief told me to
stop and report on if it moved — is UNCHANGED and green.** Its `undef` is `clang -O1`'s own
dead-edge `select i1 %c, double undef, double %q` reaching `cqrt_alloc_f64(double undef)` through
`SelectMergeEmit`, **not** a `cq_theta` seed. The rule is scoped to `@cq_theta_<sfx>` arg-0, so the
real slice it protects (`slice_libm_ld80_nexttoward`) is untouched. That scoping is load-bearing:
normalizing at the `cqrt_alloc` MINT — which is how the owner's words ("just before it hits
cq_alloc_*") read literally — would have flipped that certificate and that golden.

### e2e (3 slices, 3 goldens, 4 ctest entries)

| entry | result |
|---|---|
| `e2e-slice-undef-seed-uncontrolled` (C2a) | 15 lines; opens `cqrt_alloc_i1(0) -> h0` where the ORACLE printed `cqrt_alloc_i1(1)`; STRICT 2b `2 verified, 0 violation(s), 0 unproven` |
| `e2e-slice-undef-seed-in-region` (C2b) | 19 lines, was a loud decline on the oracle; STRICT 2b clean |
| `e2e-slice-undef-seed-cascade-twin` | 29 lines; STRICT 2b `4 verified, 0 violation(s), 0 unproven` |
| `e2e-undef-seed-cascade-twin-identical` | `compare_files` vs the shipped `slice_control_cascade_two_bools.expected.log` — **29 = 29** |

The twin is the instrument, not the golden: a golden of its own would only record whatever this
compiler emits, while the twin says the uninitialized spelling gets the circuit the INITIALIZED
program already had — reviewed, Rule-13-cleared and shipped last session. Same argument as
`e2e-measure-classical-bool-twin-identical`.

## 5. Before/after on the DIAG probes (`GATES.md` row 8)

| probe | source | ORACLE | SUBJECT |
|---|---|---|---|
| `u1` | `bool b2;` never prepared, **measured** | DECLINE (21mg) | **DECLINE, unchanged** (clause 4) |
| `u2` | `bool b1;` prepared **in a region** | DECLINE F1 | **ACCEPT, 19 lines**, STRICT 2b clean |
| `u3` | the same **unconditionally** | ACCEPT 15, `cqrt_alloc_i1(i1 undef)`, trace `cqrt_alloc_i1(1)` | **ACCEPT 15**, `cqrt_alloc_i1(i1 false)`, trace `cqrt_alloc_i1(0)` |
| `u3b` | `u3` + a chained second theta | ACCEPT 16, undef seed | **ACCEPT 16**, normalized seed, chain unchanged |
| `u4` | `int a;` uninitialized in a guard, then measured | DECLINE (21mg) | **DECLINE, unchanged** |
| `u4b` | `int a;` in the guard, NOT measured | ACCEPT 3 | **ACCEPT 3, unchanged** (the guard still vanishes at `-O1` — the documented, unfenced residual of clause 1) |
| `u5` | prep in a region + the 4.4 select | DECLINE F1 | **ACCEPT, 29 lines — byte-identical to `slice_control_cascade_two_bools.expected.log`** |

## 6. Corpus movers

ORACLE `f7b65d8c` vs SUBJECT `a5773be1`, both binaries on the SAME stage-1 file, over
`ir-pass/test/*.ll` plus every session probes/ dir PROTOCOL.md lists. Decline rows carry the exit
code **and a sha256 of the FULL stderr**, closing the S3 hole where the shared tag regex renders the
whole `cq_measure_<sfx>` family as an empty `D:`.

**`probes/corpus_a5773be142835fb8.txt` — 2793 rows, 7 movers, 1 CLANGERR.**

| row | ORACLE | SUBJECT | class |
|---|---|---|---|
| `ir-pass/test/control_inplace_ry_reject_stateprep_undef_seed.ll` | `D1: state prep seed does not match the merge incoming` | ACCEPT | **PREDICTED** (the brief's second expected string) |
| `ir-pass/test/control_inplace_ry_reject_stateprep_poison_seed.ll` | `D1: state prep seed does not match the merge incoming` | ACCEPT | **PREDICTED** |
| `ir-pass/test/control_predmux_reject_selectform_rotation_theta_poison_seed.ll` | `D1: control flow under quantum control` | ACCEPT | ⚠ **NOT PREDICTED — FINDING, §7** |
| `…/diag_2026-09-14_probes/u2.c` | `D1: state prep seed …` | ACCEPT | PREDICTED — customer C2b |
| `…/diag_2026-09-14_probes/u5.c` | `D1: state prep seed …` | ACCEPT | PREDICTED |
| `…/diag_2026-09-14_probes/u3.c` | ACCEPT, IR md5 `0a339dfb` | ACCEPT, `4609cda7` | **PREDICTED** — the brief's first expected class (an accept emitting `undef` into an alloc) |
| `…/diag_2026-09-14_probes/u3b.c` | ACCEPT, `0c7370ee` | ACCEPT, `7cd840f2` | PREDICTED |

> ⚠ **A FOURTH MOVER CLASS, AND THE SWEEP ABOVE COULD NOT SEE IT — review round 1, F-U1-1.** The
> taxonomy above names two diagnostics; the increment moves modules through a **THIRD**,
> `cq literal integrity: undef/poison literal reaches two emitted gate operands`
> (`LiteralIntegrity.cpp` GUARD 1, bd `xy9n`) — not by changing that guard, but by **deleting one of
> the two slots it was counting**. It is absent from the sweep because **no fixture in the corpus
> exercises the composition** (re-measured over all 1936: **BOTH-undef population = 0**); it is
> reachable only from ordinary C, which is where the reviewer found it.
>
> | row | ORACLE `f7b65d8c` | SUBJECT `a5773be1` | class |
> |---|---|---|---|
> | `r14` `double d; d = cq_theta(d,d);` | `D1: undef/poison literal reaches two emitted gate operands` | ACCEPT, emitting `cqrt_ry_f64(%h, double undef)` | ⚠ **NOT PREDICTED — the third string** |
> | `r15` two distinct uninitialized doubles | same | ACCEPT | same class |
> | `r21` seed `i1 undef` + angle `double undef` | same | ACCEPT | same class, **different widths** |
> | `r22` survivor on a DIFFERENT theta | same | ACCEPT | same class, **non-local** |
>
> "An increment that moves three fixtures is entitled to say *nothing else moved* only about the
> corpus it swept" — the reviewer's sentence, and it is the lesson. **Disposition is OPEN** (owner
> ruling pending, coordinator hold 2026-09-14); evidence in `FIX_U_R1.md` §1–§2.

Nothing else moved **within the swept corpus**: no decline→decline string change (the full-stderr sha
is identical on every decline row, which is the check the tag regex alone cannot make), no
accept→decline anywhere, and no accept whose IR md5 moved outside those rows. The single `CLANGERR` row
(`session-2026-09-11-orchestrator/review_integration_probes/U0_uncommented.c`) does not compile
standalone and is `CLANGERR` on BOTH binaries.

**⚠ THE SWEEP IS PARTIAL AND I STOPPED IT DELIBERATELY — say so rather than round it up.** It
covered every probe corpus plus `ir-pass/test` fixtures 1–1581 of 1928, and was killed by PID (my own
process; never a pattern kill) because the box was at load 300–440 under four other track agents and
the remaining ~350 fixtures were running at ~6 rows/min. Two measurements close the gap, and neither
is an argument from authority:

* **`probes/corpus_tail_undef_a5773be1.txt` — 98 rows, 0 movers.** The SAME two-binary comparison over
  every fixture in the unswept range that contains an `undef`/`poison` token ANYWHERE — a strict
  superset of the rule's trigger.
* **0 of the 782 fixtures after index 1154 carries a whole-value `undef`/`poison` `cq_theta` seed**
  (measured by parsing every theta call's arg-0, not by grep — `noundef` contains the substring
  `undef` and a naive grep flags every clang-emitted call; that false positive bit me once in this
  session and is why the check parses). `normalizeUndefRotationSeed` returns false and mutates
  nothing unless that trigger is present, and it is the only change to the pass, so those rows cannot
  move.

  > ⚠ **F-U1-4(a): this bullet and `GATES.md` row 34 contradicted each other** — the row called the
  > same measurement "(grep, not a sweep)". Rather than pick a winner, the FIX round re-measured it
  > with a parser over the **WHOLE** corpus and over **BOTH** operands
  > (`fix_r1_probes/theta_operand_census.py`, output `…census.txt`), because the F-U1-1 composition
  > needs the ANGLE and no earlier instrument reported it for the `.ll` corpus at all:
  > **1936 fixtures scanned — SEED-undef only 11, ANGLE-undef only 3, BOTH 0, PARSE-SKIP 2.**
  > The 2 skips are the two `*_constexpr_*_seed.ll` fixtures (the deliberate residual); the
  > instrument reports them rather than counting them clean. `GATES.md` row 34 is corrected.

**The e2e layer, which the PROTOCOL forbids me to run, is covered the same way — by a stage-1
measurement rather than by hope.** A clang-only scan of `tests/e2e/*.c` (no pass, no ctest) parsing
every `@cq_theta_*` call in the `-O1` IR found that the ONLY slices handing a whole-value
`undef`/`poison` to a seed are the **three this change adds**, and that **no slice anywhere** has an
`undef`/`poison` ANGLE. So no shipped golden can move; the ones I did run
(`measure-classical-*` ×8, `control-cascade*` ×9) are byte-identical, as expected.

> ⚠ **F-U1-4(b): two corrections to this paragraph, and the closure HOLDS.** (i) "all 391
> `tests/e2e/*.c`" describes neither the directory nor the scan: the directory holds **394** (391 was
> the pre-change count, before this increment added three slices) and
> `probes/e2e_stage1_undef_seed_scan.sh` carries `case "$b" in *_lib.c) return;; esac`, so it scanned
> **372** = 394 − 22. (ii) The skipped 22 were an unstated hole, and it is now closed by measurement
> rather than left implicit: **18** of them contain the token `cq_theta` (the reviewer said 21 —
> re-measured, it is 18), and **every single occurrence is an `#ifdef cq_theta` compile-time
> tripwire** (17 files) **plus one explanatory comment** in `slice_multi_lib.c:8` whose own `#ifdef`
> is at `:11`. **Zero actual calls; nothing is lost.** The scan's ANGLE finding — 0 slices anywhere —
> is what makes the F-U1-1 composition unable to touch any shipped golden.

## 7. FINDING — the one unpredicted mover, stated rather than explained away

`control_predmux_reject_selectform_rotation_theta_poison_seed.ll` (bd `u1rp`) declined
`control flow under quantum control` because `classifyConeNode` scans a `cq_theta`'s ARGUMENTS for
undef/poison — the cone walk treats a theta as a `Leaf` (its handle does not depend on the seed), so
the walk never recurses into the seed and that explicit scan is the ONLY protection. The z9t1
normalizer rewrites the seed before `flattenPredMuxRegions` runs, so there is no poison left to find
and the region is claimed.

**It is sound, and it is a defect removed rather than a fence relaxed.** The fixture's own header
called the refusal *"a deliberate, cheap over-decline"* whose measured cost was zero; its premise was
that the poison reaches one emitted slot. That premise is gone — the emitted module now carries no
undef/poison slot at all (pinned by its NOUNDEF prefix). Under the owner's 2026-09-11 ruling an
over-decline of a valid circuit is a defect to remove.

**The u1rp pin is moved, not dropped**: `..._rotation_theta_poison_angle.ll` is the same module with
the poison in ARG-1, which Rule 3 keeps permanently outside this rule's scope, and it declines
identically on **both** binaries (same string, same anchor). Delete the `Call->args()` scan and that
file goes red.

## 8. Residuals, and what the orchestrator should file

### 8.0 ⚠ OPEN WITH THE OWNER — two, and they are the same question asked twice

**Neither is touched by any fix round. Both are prose-frozen exactly as the reviews left them.**

| id | the question | why it is a ruling and not a fix |
|---|---|---|
| **F-U1-1** (round 1, round 2's F-U2-1) | when the SEED and the ANGLE both carry an undef, this rule deletes one of the two slots `declineUnpairedUndefLiterals` (GUARD 1) was counting, so a module the ORACLE declined compiles **silently** (probes `r14`/`r15`/`r21`/`r22`) — and on 2 of 1922 round-2 corpus mutants it lands on a **pre-existing SIGABRT** instead | GUARD 1 is the *pairing* break; r14's two slots are two **independent** source operands that coincide only because `undef` is uniqued per type. Whether the oracle's decline was protecting a real hazard or was a uniquing coincidence is the ruling. **No conjunct may be added on developer judgement** — the source says so at the site |
| **F-U3-1** (round 3) | the phi clause **silently disarms ruling clause 4** (`cq_measure` of an undef keeps declining) by deleting the undef **upstream** of the sink. **Measured: 4 of 710.** The direct spelling is intact and verified; what moved is the clause's **reach** | *"The ruling's boundary changed without a ruling"* (L7). Given the owner's *"an over-decline is a defect to remove"* it may well be ADMIT — **but it must be decided, not discovered** |

**Carry them together.** They are one question in two places: *this rule moves modules through a
diagnostic nobody predicted.* If the owner ADMITS, the follow-up for F-U3-1 is to amend the clause-4
paragraph in `TaintPropagation.cpp`, which currently reads as if the asymmetry were total, and to add
the four corpus rows. If the owner RESTORES, none of the five gate lines `FIX_U_R1.md` cites may be
cited for it — the binary would change.


1. **Clause 5's residual stands** (bd `bwsh`): an `undef` reaching arg-0 **through an instruction**
   (a `phi` with an undef incoming) is not normalized — `valueCarriesUndef` is constant-only. Today's
   verdict is an ACCEPT emitting `cqrt_alloc_i1(i1 %s)`, unchanged from the oracle and now PINNED by
   `lowering_accept_undef_theta_seed_phi_residual.ll` with a retirement trigger in its header. bd
   `bwsh` should be re-scoped to this residual alone (its message-split subject is gone: F1 no longer
   sees a whole-value undef seed).
2. **A SECOND residual, not in the brief and now pinned**: a seed that CARRIES an undef without BEING
   one (a `ConstantExpr` with an undef leaf) is deliberately left alone — see §2(a). It keeps F1
   clause 1 reachable, which is why the clause is still pinnable at all.

   > ⚠ **F-U1-4(c):** "it carries the trigger token" is **not literally a closure** — a seed
   > `ConstantExpr` that the PARSER folds to `undef`/`poison` would carry no token and still trigger
   > the rule. The reviewer tried to build one (`c2_no_token_poison.ll`,
   > `i32 add nuw (i32 -1, i32 1)`); LLVM 19 folded it to `i32 0` and both binaries were
   > byte-identical. The FIX agent did not construct one either. Record it as **measured, not
   > proved**: *neither agent could construct one in LLVM 19.*

2b. **A THIRD residual — over-DECLINE, review round 1 finding F-U1-5, for the orchestrator to file.**
   The phi half walks `Theta->users()` and normalizes only a phi that has the theta **directly** as
   an operand. **One** intervening instruction and the incoming stays `undef`, F1's pointer-identity
   sub-clause still fails, and the module declines. Probe `r11_indirect_merge.c` — u2's shape with
   `b1 = !cq_theta(b1, 0.5);` — declines `cq controlled lowering: control flow under quantum control`
   **identically on both binaries** (225 B each), so it is a **residual, not a regression**. Under the
   owner's 2026-09-11 ruling an over-decline of a program that would lower to a valid circuit is a
   defect to file. It belongs beside bd `bwsh` — the same wall as residual 1, reached from the phi
   side rather than the seed side. Widening it means chasing instruction operands, which is the
   `bwsh` conversation and owes its own Rule-13 round.
3. **Rename-only follow-up**: three `*_reject_*` fixtures are now ACCEPTs. Renaming them needs its
   own commit plus the duplicate-body scan the protocol requires after a fixture rename.
4. **`cq-opt-equivalence-full` is owed by the group gate** — no diagnostic string moved, but analysis
   sites did (three shipped declines became accepts), which is the matrix's trigger.
5. **Clause 1's documented, unfenced residual, re-measured**: `u4b` shows `clang -O1` still deletes a
   branch that reads the same uninitialized object before the pass ever runs. CQ makes no claim about
   the variable; that is the ruling, and no fence was added.
6. Clang's own `-Wuninitialized` still fires on both customers under `-Wall` (measured). CQ adds no
   warning and suppresses none; the slice harness compiles without `-Wall`, so the shipped gates are
   silent, which is what "also no warnings" asks of CQ.

## 9. Gate lines — see `GATES.md`

Everything I ran is there with the binary hash it was run against, in `ran:` form. What I did **not**
run, because the PROTOCOL matrix forbids it to an implementer: `ctest -j6 -R '^e2e-'`, the full
`ctest -j6`, `cq-opt-equivalence-full`, the twin matrices.

⚠ One instrument lesson worth carrying (PROTOCOL S3's family): **the first version of the injection
matrix reported 45 MISSED against fixtures that catch every one of those mutations.** It invoked
`FileCheck <fixture> --check-prefix=X` and silently dropped the RUN line's `--implicit-check-not`
flags, so it was measuring a weaker command than lit runs. Verified by hand (exit 1 on the same
mutant with the flags), then fixed in `inject_u.py::prefixes`, which now returns *prefix → the extra
flags its own RUN line carries*. A harness that runs a different command than the gate is not a
measurement of the fixtures; it is a measurement of itself.

Final: **applied 67, MISSED 0, N/A 23** (the N/A are genuine shape-absence: `cnot-pair-unbalanced`
×8 and `two-copies-swapped` ×7 on straight-line modules, `controlled-angle-sign-flipped` ×6 where
there is no controlled rotation, and the two seed mutations ×1 each on the phi-residual fixture,
whose seed is an SSA value by design). The `STREAM` prefix that gets them there is itself measured
rather than assumed: with the FIXED harness, stripping it from two of these fixtures puts **11 of 17
back to MISSED** (injected `cqrt_x`, extra `cqrt_free`, extra `cqrt_ry`, `cqrt_cswap`, swapped copy
pair, extra measurement), which is the number the fixture headers quote.
