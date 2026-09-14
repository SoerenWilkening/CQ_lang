# Track U — ADVERSARIAL REVIEW round 3 (Rule 13), bd `z9t1` — THE φ CLAUSE ONLY

**Reviewer:** independent; did not write the code, did not perform round 1 or round 2.
**Subject:** `/Users/sorenwilkening/Desktop/CQ_undef`, branch `undef-seed-zero`, tip `4044e49e`.
**Probes:** `$SES/trackU/review_r3_probes/` — 4 scripts, 11 hand probes, and a
**three-corpus φ-incoming injection sweep over 711 modules, 710 of them measurable** (2844 `cq-opt`
invocations).
**Scope:** the φ half of the rule and nothing else. The seed half is round 2's closure and is not re-asked;
F-U1-1 is not re-litigated (the owner holds it).

## 0. Hash gate — PASS (my first act)

```
$ shasum -a 256 <both>/build/ir-pass/cq-opt /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/libCQPass.so
a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff  CQ_undef/build/ir-pass/cq-opt      ← brief
f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  CQ_lang/build/ir-pass/cq-opt       ← brief
f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d  CQ_lang/build/ir-pass/libCQPass.so ← brief
$ git -C CQ_undef rev-parse HEAD → 4044e49ea239bd4ce1a70457dbf5d17718714886                          ← brief
```
All three match character-for-character; the subject tip matches. Proceeded. (`CQ_undef/.../libCQPass.so`
= `957d2e14…` is not pinned by the brief and is used by no measurement — every invocation below runs the
pass built into `cq-opt` itself.)

---

## VERDICT: **CLEAR-WITH-ITEMS**

**No over-accept and no silent miscompile in the φ clause.** On the φ clause's own eligible population —
**711 modules, 101× round 2's seven** — `SUBJECT(undef seed + undef φ incoming)` is indistinguishable from
`ORACLE(the same two operands written as concrete zeros)`: **710 of 710 measurable modules are exactly
equal, 0 divergences**. (The 711th never ran the pass at all: my own mutator emitted it unparseable. It is
excluded from every figure below rather than scored as an equality — see §1.) Zero `A→D`. Zero undef in any
emitted gate operand. Zero crashes in 2844 invocations.

Four items, **none a correctness defect in the rule**. Three are record/disclosure; the fourth is an
owner-disposition question that round 2's clause-4 check structurally could not reach.

| id | claim | severity |
|---|---|---|
| **F-U3-1** | the φ clause silently disarms **ruling clause 4** (`cq_measure` of an undef keeps declining) by deleting the undef *upstream* of the sink. **Measured: 4 of 710.** Round 2's clause-4 verification tested only the direct spelling and cannot see this | owner-disposition / documentation (**not** a miscompile) |
| **F-U3-2** | the recorded scope is still wrong at the tip, and **wronger than round 2 measured**: the clause rewrites *every* undef incoming of *every* φ that uses the theta — up to several **distinct C objects per visit**. Population now measured: **164 of 710** | documentation / record + missing retirement trigger (supersedes F-U2-2's wording) |
| **F-U3-3** | **116 of the 136 `D→A` rows** are F1's pointer-identity proof being *manufactured*, equating two uninitialized objects the source never equated. Sound by refinement — but it is the same class of silent widening CLAUDE.md §4 requires be **disclosed**, and there is no disclosure paragraph | documentation |
| **F-U3-4** | the φ clause is **ONE-SHOT** (gated on the seed still being undef), so the record's "the L1 obligation is discharged STRUCTURALLY" is true of the seed half and true of the φ half only via a fact the record never states | documentation + retirement trigger |

---

## 1. The instrument round 2 could not build — why it could not, and why it can

Round 2: *"synthesizing a well-typed undef incoming on a theta-carrying phi mechanically, across 1922
fixtures, is not something I could do soundly in this round."*

**The obstruction is real and it is precise.** Round 2's whole method is the **zero twin**: mutate arg-0 to
`undef` for `O_u`/`S_u`, mutate arg-0 to the type's zero for `O_z`, and ask `S_u == O_z`. That twin mutates
**one operand**. The φ clause rewrites a **second** operand — so a twin that only zeroes arg-0 leaves the φ
incoming `undef`, and `S_u != O_z` by construction on every row the φ clause touches. Round 2 saw exactly
this: its four `CLASS` rows are *"the phi half of the rule, which the zero-twin control does not emulate"*.
The instrument was not unsound; it was **under-specified**.

**The fix is that the twin must reproduce the clause's own algorithm by hand, not approximate it.** That is
constructible, and it is what `phi_mutate.py` does:

| corpus | seed (arg-0 of every theta a φ carries) | non-theta incomings of every theta-carrying φ |
|---|---|---|
| **U** | `undef` | `undef` |
| **Z** | the type's zero | the type's zero |
| **SZ** (round 3's own addition) | the type's **zero** | left **`undef`** |

`Z` is "the subject's rewrite, applied by hand", so the rule's whole claim on the φ half is `S_u == O_z`.
`SZ` is the **isolation** corpus — "what the pass does when *only* the seed clause exists" — so the φ
clause's own population is exactly `{ rows : SUBJECT(U) != ORACLE(SZ) }`. Without `SZ` a moved row could be
the seed clause round 2 already closed, and the round would have re-measured round 2.

```bash
cd $SES/trackU/review_r3_probes
python3 phi_census.py  $CQ/ir-pass/test census_main.json      # the eligible population
python3 phi_mutate.py  $CQ/ir-pass/test undef /tmp/cqu_r3_u
python3 phi_mutate.py  $CQ/ir-pass/test zero  /tmp/cqu_r3_z
python3 phi_isolate.py $CQ/ir-pass/test       /tmp/cqu_r3_sz
./phi_sweep.sh ; /tmp/cqu_r3_szsweep.sh ; python3 phi_analyze.py
```

**Vacuity fences, because a probe that pins nothing is worse than no probe (Rule 12c).** `;`-comment text is
stripped before any match (round 2's mutator defect #2, kept here as a fence — a FileCheck line can never be
mutated); `declare` prototypes are never touched (defect #1); a φ type with no renderable zero is **skipped
and counted**, never silently emitted; every emitted file is checked non-zero (`find -size 0` → **0**, the
passthrough trap the brief names); every mutant is diffed against its source and a no-op is counted
(U: 1 vacuous — `control_inplace_ry_reject_stateprep_undef_seed.ll`, which already *is* the U shape, correct.
Z: 77 vacuous — fixtures already seeded `0` with concrete incomings, correct).

**The instrument's one defect, found by attacking it rather than by re-reading it.** `llvm-as` over both
corpora — **and over the `SZ` corpus too, which carries the isolation figure** — **exactly 1 of 711
unparseable in each, the same file**: `control_inplace_ry_reject_stateprep_constexpr_seed.ll`, where my
comma-split chopped `ptrtoint (ptr @G to i32)` mid-expression. Neither binary ran the pass on it, so it
measures nothing. It is also the `ConstantExpr` case the implementation deliberately refuses, so it costs
no coverage.

⚠ **It was inside my first draft of the headline figures and I took it out, which is the point of running
the check.** Scored naively it appeared as a `MSG_DIFF` in the `S_u`/`O_z` sweep and as a member of the φ
clause's isolated population — inflating that population from its true **164** to 165 and turning a clean
`710/710` into a `710 of 711` with an asterisk. **Every number below excludes it.** A row where neither
binary reached the pass is not an equality and not a divergence; it is not a measurement.

### Population — the brief's explicit question

| | |
|---|---|
| fixtures scanned | 1928 |
| **fixtures containing a φ that carries a `@cq_theta_*` result** (the clause's *eligible* population) | **711** |
| such φs · injectable non-theta incomings | 895 · 698 |
| fixtures already carrying an undef incoming on such a φ, unmutated | **4** |
| **modules actually swept, three verdicts each** | **711** (2844 invocations); **710 measurable** |
| **the φ clause's OWN population** (`SUBJECT(U) != ORACLE(SZ)`) | **164** |
| hand probes | 11 |

That last row of 4 is why round 1's unmutated sweep could not move here either, and it is the same
structural point as F-U2-3 — restated for the φ operand.

**On the brief's "NO corpus sweep" limit.** I read that as the session-level *regression* sweep the merge
gate owns — "did any shipped verdict move?" — and I did not run it. What is above is a **mutant probe
family over the clause's own eligible population**: a different corpus (injected), a different question
(`S_u == O_z` on the φ operand), and it makes **no claim about any shipped fixture's verdict**. I drew that
line deliberately and state it here so the merge gate can disagree with it explicitly.

### Result — `S_u` vs `O_z`, the 710 measurable modules

| | count | reading |
|---|---|---|
| `EQ_decline` | **519** | byte-identical stderr |
| `EQ_accept` | **191** | byte-identical output IR (headers stripped) |
| **divergence** | **0** | 519 + 191 = **710 = every measurable module** |
| *(excluded)* | 1 | the unparseable `ConstantExpr` row — neither binary ran the pass |

Blast radius `O_u → S_u`: `D→D` 520, `A→A` 55, **`D→A` 136**, **`A→D` 0 — the φ clause introduces no
over-decline.** Exit codes across all 2844 invocations: only `0` and `1` — **no SIGABRT anywhere**, in
contrast to round 2's seed sweep (2 rows of exit 134). `Su` and `Oz` have *identical* verdict distributions
(191 A / 520 D).

**Undef/poison surviving into a SUBJECT-emitted gate operand: 0 of 710.**

---

## F-U3-1 — the φ clause silently disarms **ruling clause 4**, and round 2's check could not see it

**Claim.** Ruling clause 4 is explicit and is quoted in the implementation: *"`cq_measure` of a never-quantum
`undef` KEEPS DECLINING (bd 21mg) … a zero would be an invented ANSWER rather than a chosen starting basis
state."* Round 2 verified it (item 8) with `a2_measure_undef.c` — the **direct** spelling, an undef literal
at the sink. The φ clause does not touch the sink; it deletes the undef **upstream**, so by the time
`MeasureLowering` looks there is nothing left to decline. **Measured: 4 of 710.**

**Probe.** Corpus rows, regenerable with the commands in §1:
`lowering_inplace_rail_n02_select_merge_accept`, `…_n03_value_merge_accept`,
`lowering_loop_phase_accum_const`, `lowering_unroll_leave_identity_carry`.

```bash
$ CQ_lang/build/ir-pass/cq-opt -passes=cq-lowering -S \
    /tmp/cqu_r3_u/lowering_inplace_rail_n02_select_merge_accept.ll -o /dev/null
error: … in function slice i32 (i32): cq_measure_<sfx> operand is an undef/poison literal;
       a classical measurement needs a defined value                                   → exit 1
$ CQ_undef/build/ir-pass/cq-opt … (same file)                                          → exit 0, stderr 0 B
$ CQ_lang/build/ir-pass/cq-opt … /tmp/cqu_r3_z/… (the zero twin)                       → exit 0, IDENTICAL IR
```

**Both verdicts.** `O_u` = exit 1, the clause-4 decline. `S_u` = exit 0, 20 emitted gates. `O_z` = exit 0,
**byte-identical to `S_u`**. The module is a loop-carried φ
`%15 = phi i32 [ %3, %1 ], [ undef, %13 ]` over a theta whose seed my mutation made `undef` — i.e. the
second ruled spelling (`int r; if (…) r = cq_theta(r,θ);`) with a measurement after it.

**Reading, stated so it is neither over- nor under-claimed.**
* It is **not a miscompile**: `S_u == O_z` on all four, so the emitted circuit is exactly what a written `0`
  produces, and the measured values after normalization are genuine quantum handles, not invented classical
  answers.
* Clause 4's **direct** spelling is intact, and I verified that myself rather than inheriting it
  (`pN_clause4_direct`): subject exit 1 on `cq_measure_si32(i32 undef)`, while the zero twin accepts — the
  asymmetry the ruling requires still holds, *and that S_u ≠ O_z is the ruling working, not a divergence*.
* What moved is the clause's **reach**. The owner ruled that an undef at a measurement must not silently
  become a zero. After bd `z9t1` it silently becomes a zero whenever it arrives through a φ that happens to
  carry a normalized theta. **The ruling's boundary changed without a ruling** (standing lesson L7).
* Round 2 cannot be faulted for missing it: its clause-4 probe is the only spelling the seed-only twin can
  express.

**Severity.** Owner-disposition / documentation. Given the owner's *"an over-decline is a defect to remove"*
this may well be **ADMIT** — but it must be decided, not discovered.

**Minimal fix.** No code. (1) Carry it to the owner **with the open F-U1-1 disposition**, as the second
measured case of "this rule moves modules through a diagnostic nobody predicted". (2) If admitted, add the
four rows and the mechanism to the clause-4 paragraph in `TaintPropagation.cpp`, which currently reads as
if the asymmetry were total.

---

## F-U3-2 — the recorded scope is still wrong, and it is wronger than round 2 measured

**Claim.** At tip `4044e49e` the record still says:

> *"A phi incoming is normalized ONLY when that phi carries THIS theta's result as another incoming — i.e.
> only where the object was undefined on BOTH edges."*

F-U2-2's minimal fix has **not landed**. Round 2 gave one counter-example. The code is wider than that in
**three independent directions**, and I measured all three:

1. **Several φs per theta.** The loop is `for (User *U : Theta->users())` — *every* φ user, not the merge φ.
   Corpus census: **164 of 972 carried thetas are carried by more than one φ**, and every one of those φs
   has all its undef incomings rewritten. Probe `pL_second_unrelated_phi` (3-edge merge, two undef edges).
   (⚠ This 164 is a *count of thetas* and is **not** the φ clause's 164-module population below. The two
   quantities are unrelated and coincidentally equal — do not cite one for the other.)
2. **Several incomings per φ.** The inner loop rewrites *every* undef incoming, not the Pred edge.
   **37 φs in the corpus have ≥2 non-theta incomings** — i.e. up to several **distinct C objects** made
   equal in one visit. Probe `pA_three_edges`.
3. **A different object entirely.** Probe `pD_two_objects` — the prep seeds from object *X* and the
   straight-through edge carries object *Y*; nothing in the source equates them. `D→A`.

And it now has a **measured population**, which round 2 did not have:

```
ISOLATION  SUBJECT(undef seed + undef φ)  vs  ORACLE(ZERO seed + undef φ)
   unchanged by the φ clause        : 546
   THE φ CLAUSE'S OWN POPULATION    : 164      (124 decline→accept, 39 message changes, 1 IR-only)
   (excluded: 1 unparseable mutant — neither binary reached the pass)
```

The "i.e." describes a clause with a population of ~4; the shipped clause has one of **164**.

**Severity.** Documentation / record + missing retirement trigger (L8). **Not** a correctness defect —
every one of the 164 lands on the zero twin.

**Minimal fix** (no code): replace the false "i.e." with the three directions above and their measured
counts, and add the two retirement triggers F-U2-2 already specified for
`control_peel_reject_{undef,poison}_incoming.ll`. ⚠ Note for whoever writes those triggers: the shipped P3b
fixtures' undef φ is `%6 = phi i32 [ 5, %3 ], [ undef, %0 ]`, which **does not carry a theta** — that, and
not any scope narrowing, is the whole reason they stay green.

---

## F-U3-3 — the `D→A` disclosure surface: F1's identity proof is *manufactured*, and nothing says so

**Claim.** 136 modules the oracle **loudly refused** now compile **silently**. Categorised by the
diagnostic the oracle gave:

| count | the decline the φ clause removed |
|---|---|
| **116** | `state prep seed does not match the merge incoming` |
| 14 | `control flow` (the `MergePhiPeel` P3b route, below) |
| 4 | `cq_measure_<sfx> operand is an undef/poison literal` (**F-U3-1**) |
| 1 | `condition predates a non-diagonal gate` |
| 1 | `nested control flow` |

The 116 are one mechanism. F1's second sub-clause requires the Pred incoming to be **pointer-identical** to
the seed; `Constant::getNullValue` is uniqued, so after the rewrite it **is**, for two operands the source
never equated. `pD_two_objects` is the minimal witness:

```
oracle (undef)     : cq controlled lowering: state prep seed does not match the merge incoming   exit 1
subject(undef)     : exit 0 — cqrt_alloc_i32(0); cqrt_ry_i32_controlled(%h_cmp,%h1,5.0e-01); …
oracle (zero twin) : exit 0 — BYTE-IDENTICAL IR
```

**This is sound, and I say why rather than asserting it.** LangRef lets an `undef` stand for any value of
the type, so choosing `0` at each read is a **refinement**: the emitted circuit is one the source already
licensed. On the ¬flag component the fresh rail holds |0⟩, which is a value object *Y* was permitted to
have. No fence is being deceived about a value the program actually wrote.

**But it is exactly the class CLAUDE.md §4 says must be DISCLOSED.** The F2 α/β narrowing carries a
paragraph beginning *"What the F2 narrowing silently absorbs, in the words it must be said in"* precisely
because no predicate can separate the readings after `-O1`. This widening has the same shape — a loud
refusal becomes a silent compile, with no diagnostic and no fence available — and it has **no such
paragraph**. The mitigation is disclosure, not a predicate.

**One positive worth recording from the same surface.** `lowering_unroll_const_trip` is the single
`IR-only` row: at HEAD with an undef φ incoming, LLVM constant-folds the `fma` to NaN and **the user's
`cq_measure` disappears from the emitted module entirely** (`ret double 0x7FF8…`, no measurement gate). The
subject restores it (`cq_template_fma_f64_qll` → `cqrt_measure_f64`). bd `z9t1` *removes* a
vanished-user-measurement, it does not create one.

**Severity.** Documentation. **Minimal fix:** a disclosure paragraph in `RotationLowering.cpp` modelled on
CLAUDE.md §4's, carrying the 116/14/4 split and `pD_two_objects` as its witness.

---

## F-U3-4 — the φ clause is ONE-SHOT, so the record's L1 "structural discharge" is half true

**Claim.** The record argues that placing the normalizer inside `propagate` discharges the L1 round-2
obligation *structurally*, "with no second call site to forget". **That is true of the seed half and
materially incomplete for the φ half.** The function early-returns:

```cpp
if (!valueCarriesUndef(Seed)) return false;
if (!isa<UndefValue>(Seed))   return false;      // ← after round 1 the seed is `i32 0`
…                                                //   so the φ loop below is UNREACHABLE
for (User *U : Theta->users()) { … setIncomingValue(I, Zero); }
```

At **every** propagate round after the first, the seed is already concrete, so the φ loop never runs. An
undef φ incoming that appears or is exposed between rounds would be left alone — and F1 would then compare
`i32 0` against `undef` and decline. That is the **over-decline** direction, and it is an L1-species
asymmetry the record does not name.

**It is currently unreachable, and I measured that rather than assuming it** (Rule 11):

```bash
$ grep -rn "setIncomingValue"                  ir-pass/src ir-pass/include
  src/RotationLowering.cpp:274      ← exactly ONE writer in the whole pass: this clause
$ grep -rn "UndefValue::get\|PoisonValue::get" ir-pass/src ir-pass/include
  (one comment line only — NO call site mints an undef anywhere in the pass)
$ grep -rn "PHINode::Create\|CreatePHI"        ir-pass/src ir-pass/include
  src/Specialization.cpp:484   PHINode::Create(RetTy, …, "cqq.ret")
  src/BreakReversePlay.cpp:831 RB.CreatePHI(IdxLog, 2, "cq.brk.ip")
```

Both φ minters are structurally excluded, verified in source, not inherited: `cqq.ret` merges clone return
values and `SpecializeReject::scanBody` refuses every body containing a `cq_theta`/`cq_phi` (its own
"load-bearing precondition R2"), so that φ can never carry a theta; `cq.brk.ip`'s two incomings are both
`sub` **Instructions** (`NMinus1`, `IDec`), never `undef`.

**Severity.** Documentation + retirement trigger. **Minimal fix:** amend the placement paragraph to say the
φ half is one-shot and that its safety rests on the three greps above, with a RETIREMENT TRIGGER: *"if any
stage ever gains a second `setIncomingValue`, mints an `UndefValue`, or creates a φ that can carry a theta
result, the φ half must be re-asked after the round-2 fixpoint — moving the seed guard is the wrong fix,
because it would make the rewrite non-idempotent."*

---

## 3. `MergePhiPeel`'s P3b — verified myself, and the answer to "is any *other* gate disarmed"

**P3b, verified not inherited.** `pC_p3b_carrier.ll` is my own construction of the shipped P3b shape with
the undef-carrying φ *also* carrying the theta:

```
oracle (undef)     : cq controlled lowering: control flow                                  [P3b REFUSED the peel]
subject(undef)     : cq controlled lowering: state prep seed is proven equal to the condition register
oracle (zero twin) : … IDENTICAL
```

Round 2's claim reproduces exactly. And my **one permitted fixture re-run** confirms the shipped negative is
still green *and still has a subject* (L8 non-vacuity):

```bash
$ CQ_undef/build/ir-pass/cq-opt -passes=cq-lowering -S ir-pass/test/control_peel_reject_undef_incoming.ll
  → exit 1, "cq controlled lowering: control flow under quantum control"
$ FileCheck control_peel_reject_undef_incoming.ll < stderr   → PASS
```

**The brief's real question — "any *other* decline-keeping gate disarmed the same way and NOT saved by a
downstream fence?" — answered by enumeration, not by sampling.** Every undef-keyed gate in the pass:

| gate | reachable by the **φ** clause? | disarm co-extensive with the hazard? |
|---|---|---|
| `MergePhiPeel` P3b (`MergePhiPeel.cpp:261`) | **yes** | **yes** — its hazard is "a literal read as two different values"; a uniqued `i32 0` is single-valued, the same ground the file already gives for peeling `freeze` |
| `PredMuxFlatten::classifyConeNode` leaf `Fail` (`:324`) | **yes**, via a φ operand in the cone | **yes** — its question is "is this leaf *defined*"; after the rewrite it genuinely is |
| `PredMuxFlatten` theta-arg `Fail` (`:653`, *"the only protection its seed gets"*) | no — **seed** clause | yes (round 2's closure) |
| `ArmClassify` F1 seed exclusion (`isa<ConstantInt>/ConstantFP`) | no — **seed** clause | yes (round 2's closure) |
| `ArmClassify:3661` negated-rail angle fence · `:6518`/`:6788` angle-select arms | **no** — all read **arg-1 / `ConstantFP` arms**; `valueCarriesUndef` is constant-only so a φ is false for it either way | n/a |
| `MeasureLowering:152` (`valueCarriesUndef(Handle)`) | **not directly** (constant-only ⇒ a φ never trips it) — but **upstream**, which is **F-U3-1** | direct spelling intact; upstream reach is the open item |
| `QramLowering:657` (`convertPhis` mirror) | yes | **yes** — that site *already* freezes undef→zero itself; z9t1 doing it earlier keeps claim and emit mirrored |
| **`declineUnpairedUndefLiterals` (GUARD 1)** | — | **NO** |

**GUARD 1 is the single exception, and it is the one already in front of the owner.** Every other gate asks
*"is this operand an undef?"*, and the rewrite makes the answer genuinely `no` — so the disarm and the
hazard's removal are the same event. GUARD 1 alone is a **counting** gate over a population the rewrite only
**partially** empties: it drops 2 → 1 and goes silent while a *different* undef stays in a gate slot. That
is F-U1-1 / F-U2-1 verbatim, and the brief excludes re-litigating it. **So the answer is: exactly one other
gate, and it is not new.**

---

## 4. What I attacked and found CLEAN — the positive record

The brief's item-2 list, each as a `u`/`z` pair driven by `./pdrive3.sh <stem>` (all three verdicts printed,
emitted stream read per Rule 2). `moved` = the rule changed the outcome, so the row is not padding.

| probe | shape | moved | `S_u == O_z` |
|---|---|---|---|
| `pS0_base` | the subject's own φ-clause accept fixture | **D→A** | ✔ byte-identical IR, 19 gates |
| `pA_three_edges` | 3-incoming φ: theta / undef / a written `7` | — | ✔ identical decline |
| `pB_unreachable_edge` | undef incoming on an **unreachable** edge | — | ✔ identical decline |
| `pC_p3b_carrier` | the P3b carrier (§3) | **D→D′** | ✔ identical decline |
| `pD_two_objects` | prep seeds object *X*, straight-through carries object *Y* | **D→A** | ✔ byte-identical IR, 8 gates |
| `pE_loop_header` | loop-header φ: `[undef, preheader], [%theta, latch]` | — | ✔ identical decline |
| `pG_chained_phi` | **φ of a φ** — the outer φ is not a theta user, so only the inner is rewritten | **D→D′** | ✔ identical decline |
| `pH_rail_cond` | `i1` φ carrying the theta, undef on Pred, used as a **branch condition** | — | ✔ identical decline |
| `pL_second_unrelated_phi` | one theta, two undef edges on one merge | — | ✔ identical decline |
| `pP_two_thetas` | the φ's other incoming is a **different theta on the same rail** | — | ✔ identical decline |
| `pN_clause4_direct` | `cq_measure(i32 undef)` — ruling clause 4, direct | n/a | **deliberately ≠** (the ruling working) |

Four of the eleven do not move the verdict and I say so rather than counting them as clearance; the 711-row
sweep is what carries the population, and **241 of its rows move**.

**Read as streams, not exit codes (Rule 2).** `pS0_base`'s 19-gate stream is the owner's cascade shape and
I checked it against the CLAUDE.md §4b invariants: `h`/`h2` are read only as controls and measured once —
never `cqrt_x`-bracketed, never freed; the two `cqrt_x` sit on the ancilla `bf`, whose `x ⊕ x = 0` return is
what makes its single `cqrt_free` a proven-|0⟩ one; the negated prep
`cqrt_ry_i1_controlled(%h, %h2, −5.0e-01)` is present. `pD_two_objects` emits the textbook controlled prep:
`cqrt_alloc_i32(0)` then `cqrt_ry_i32_controlled(%h_cmp, %h1, 5.0e-01)`, flag minted and stripped by a
paired `icmp`/`_unc`, one `cqrt_free`.

**The refinement argument, stated once so it is not mistaken for hand-waving.** Every rewrite the φ clause
performs is `isa<UndefValue>(In)` → `Constant::getNullValue(T)`. LangRef permits any value of the type at an
`undef`, so `0` is a value the source already licensed at that read; the emitted circuit is therefore one of
the source's own admissible behaviours. What the clause *cannot* do is turn a defined value into a different
one — the `isa<UndefValue>` test is literal and the `ConstantExpr` residual is excluded by its own conjunct.
This is why the 164-row population contains **no** over-accept: everything it accepts, a written `0` accepts
identically, and that is the closure.

---

## 5. What I did NOT examine — stated plainly

* **No build, no suite** (brief). Every number is a two- or three-binary measurement on the prebuilt
  binaries plus **one** `FileCheck`. **Nothing here claims `ctest` is green.**
* **No corpus regression sweep and no twin matrix** (brief). My 711-module sweep is over **injected
  mutants** and makes **no claim about any shipped fixture's verdict**. If the merge gate reads the limit
  more strictly than I did, the finding to keep is F-U3-1 (4 corpus rows) and the probes, which stand alone.
* **The φ clause's population is bounded by what the corpus encodes.** 710 modules is the eligible set of a
  1928-fixture tree, not of all C. In particular I found **no φ shape reachable only from C** that the
  corpus lacks, but I did not compile C to look for one — Track L's `bool b[N]` rail bank, which round 2
  showed the rule does not reach at all (a load from an `alloca`, not a whole-value `undef`), is the known
  gap and it is unchanged.
* **I did not re-attack the seed clause**, did not re-run round 2's sweep, and did not re-litigate F-U1-1.
  F-U3-1 is filed as new because its *route* (upstream of the sink, through a φ) is new.
* **`PredMuxFlatten`'s cone gate is argued, not probed.** I established the disarm is co-extensive by
  reading `classifyConeNode`/`coneDefinedAfterFlagDrop`; I did not construct a libm-shaped PredMux module to
  exercise it, and the corpus sweep's PredMux rows are `S_u == O_z` but I did not isolate them.
* **No simulation, no statevector** (Rule 2, owner decision 2026-06-10). Every correctness claim rests on
  zero-twin equivalence plus stream reading.
* **Track F's parallel φ-descendant F2 conjunct** — measured the Track U binary only, as instructed. Round
  2's interaction note stands and this round **sharpens it**: Track U does not merely give F2 a concrete
  seed, it gives F1 a **manufactured pointer identity** on 116 corpus rows. A φ-descendant conjunct in Track
  F will see a population that does not exist at HEAD. The merge gate must run the F1/F2 family with **both**
  changes present.

---

## 6. Is the φ clause safe at a population larger than seven?

**Yes. The largest population I achieved is 711 modules, 710 of them measurable** — the complete set of
corpus fixtures containing a φ that carries a `@cq_theta_*` result, which is the entire population in which
the clause can fire at all; the 711th is my own mutator's unparseable row and is excluded, not scored. Of
the 710, **164 are the φ clause's own** (isolated against a seed-only oracle), **124 of them `D→A`**. On all
710, `SUBJECT(undef seed + undef φ) == ORACLE(both written as zeros)` — **0 divergences**. Zero `A→D`, zero
undef in any emitted gate operand, zero crashes in 2844 invocations. Plus 11 hand probes over the shapes the
brief named.

**Round 3 found no over-accept and nothing that changes the seed clause's clearance.** Round 2's seed
closure is untouched: my three corpora mutate the seed identically for `S_u`/`O_z`, so nothing here
contradicts it, and F-U3-1's four rows are a *φ*-routed disarm of a ruled clause, not a seed defect.

**Before the merge gate:** F-U3-1 in front of the owner **alongside the open F-U1-1 disposition** (they are
the same question asked twice — "this rule moves modules through a diagnostic nobody predicted"); the record
edits in F-U3-2 and F-U3-4; the disclosure paragraph in F-U3-3. All four are prose. **No code change is
recommended, and none should be made on developer judgement** — the one conjunct that would narrow this
clause is the arg-1 conjunct the implementation explicitly reserves to the owner.

**A fourth round on this surface: NOT WARRANTED.** The φ half now has the same kind of instrument the seed
half had — a closure over its complete eligible population, not a sample — and it returned the same answer.
What remains is a ruling and four paragraphs, neither of which another review round produces.
