# Track E2 — the Rule-13 FIX round (bd `test_C_libtooling-fve8`)

Session 2026-09-15, fix track, branch **`fve8-fix`**, worktree
`/Users/sorenwilkening/Desktop/CQ_E2FIX`, based on Track E2's `fve8-undef-measure` `8eed7a2d`.

**Input**: `../review_r13_e2/REVIEW.md` — verdict **FINDING**, 1 × P1 (`F-E2-1`) + 2 × P2
(`F-E2-2`, `F-E2-3`), plus an opinion on the track's open item 3 and four housekeeping notes.
**The owner has ruled on the P1** (`../DECISIONS.md` **E9**: *ACCEPT, AND DISCLOSE THE QUANTUM
RIVAL* — no fence, **no warning**).

```
ORACLE   0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d  cq-opt   (verified here)
         94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b  libCQPass.so
SUBJECT  57e7420c50ddf8027d9c686672a1db282ed03d8bd94e5d9c366a8d2bfdc15439  cq-opt   (Track E2's gated binary)
         35fb4c26c1519cb185a5a1b683a93d0be4a95928f7035fc86c4619bd90ccf7ee  libCQPass.so
FIX      57e7420c50ddf8027d9c686672a1db282ed03d8bd94e5d9c366a8d2bfdc15439  cq-opt   ← BIT-IDENTICAL
         35fb4c26c1519cb185a5a1b683a93d0be4a95928f7035fc86c4619bd90ccf7ee  libCQPass.so ← BIT-IDENTICAL
```

## 0. ⚠ THE BINARY IS BIT-IDENTICAL TO THE GATED SUBJECT — and that is a measurement, not a hope

Every production line of `lowerMeasures` is **untouched**. This round changed **comments, fixtures
and records only**, and the claim is checked rather than assumed: `ir-pass/src/MeasureLowering.cpp`
and `ir-pass/include/MeasureLowering.h` were edited, then
`cmake --build build -j2 --target CQPass cq-opt` **recompiled** `MeasureLowering.cpp.o` **and**
`CQLoweringPass.cpp.o` (which includes the header) and relinked `libCQPass.so` — the build log shows
exactly those two `Building CXX` lines — and both binaries hash to the SUBJECT's values.

**Consequence, under `PROTOCOL.md`'s non-redundancy rule (*a gate result is a fact about a BINARY*):
every gate line in `../trackE2/GATES.md` STANDS, cited rather than re-run** — the corpus sweep (4986
rows, 24 movers, all `D→A`), the refinement measurement (12/12 byte-identical), the injection matrix
(42 mutations, 0 MISSED) and `ctest -R ir-pass-lit`. `ctest -R ir-pass-lit` was **not** re-run here,
per the brief, because the binary did not move; the two NEW fixtures were run under `lit --filter`
(§4) and are additive.

---

## 1. `F-E2-1` (P1) — **ACCEPT, AND DISCLOSE THE QUANTUM RIVAL.** No decline was added

**The owner's ruling is `DECISIONS.md` E9 and it is landed as written**: the clause ships as built,
and the disclosure — which named **one** rival, the purely classical `int u; return cq_measure(u);`
— now names **two**. The text below is the normative extension; **the fullest copy is at the
mechanism** in `ir-pass/src/MeasureLowering.cpp` (clause (1a)), and `../trackE2/IMPL_E2.md` §6
carries the same text with a banner recording that it was corrected and extended.

### 1.1 The disclosure that was landed (rival 2), in the form CLAUDE.md §4c requires

> **RIVAL 2 (QUANTUM), AS A PROGRAM AND NOT AS AN IR SHAPE:**
>
> ```c
> int u;  int q = cq_theta(0, 0.3);  return cq_measure(q + u);
> ```
>
> The author wrote **a measurement of a quantum register**. `clang -O1` folds
> `add nsw i32 %q, undef` → `undef`, and **that fold deletes the data-flow edge to the theta**, so
> the operand clause (1a) sees has no quantum lineage anywhere in the module: `taint.Tainted` is
> correct and irrelevant, branch (1) is entered legitimately, and (1a) reports the type's zero.
>
> **Measured** on the two frozen binaries: ORACLE **exit 1**, the loud decline; SUBJECT **exit 0, 0
> bytes of stderr**, a 2-line stream (`cqrt_alloc_i32` + `cqrt_ry_i32`) and **no `cqrt_measure` in
> the emitted module at all** — not even a declaration — while the C-level written-zero twin
> (`int u = 0;`) emits **3 lines with the measurement**. **A USER-WRITTEN MEASUREMENT DISAPPEARS AND
> NOTHING IS PRINTED.** The prepared rail is left allocated. Rule 5's hard invariant — never
> *insert* a measurement — is intact; **its mirror is not**, and CQ does not diagnose that.
>
> **WHY RIVAL 2 HAS NO LOWERING TO BE ROBBED OF — and here the second half is PRE-EXISTENCE, not
> refinement, because the refinement argument does not reach this rival.**
> (1) On the ORACLE the module is a **loud decline**, so no circuit for the rival reading is
> displaced. (2) **The class already ships at HEAD**, on spellings this clause never touches:
> `cq_measure(q * u)` and `cq_measure(q & u)` fold to a **concrete `0`** at stage 1 — not to `undef`
> — so they enter branch (1) with a defined operand and **accept on the ORACLE**, emitting the
> identical 2-gate stream. ⇒ **this clause emits no stream HEAD could not already emit**; what it
> adds is the `undef`-folding spellings and **the silence**. A decline here would be a **new**
> refusal that leaves `q * u` and `q & u` untouched — it would not close the class, only the half
> this clause can see.
>
> **WHY DISCLOSURE AND NOT A PREDICATE, FOR RIVAL 2.** The discriminator would have to be *"this
> operand once carried taint"*, and `-O1` has already erased the edge that fact lived on — which is
> precisely why branch (1) takes it (CLAUDE.md **L5**: a syntactic answer to a semantic question
> loses). The only decidable alternative is a Rule-5-**mirror postcondition** — *"the module lowered
> a theta whose handle is never measured"* — and it fires on every legitimately unmeasured register,
> which is most of the tree. **No warning here either** (the owner has ruled against a warning on
> this family twice; `DECISIONS.md` E9 restates it).
>
> ⚠⚠ **THE INSTRUMENT AGREES WITH THIS ONE — read it before citing the refinement number.**
> `../trackE2/probes/refinement_check.py`, the gate the rival-1 argument rests on, reports the
> rival-2 module **BYTE-IDENTICAL**, because its one-token twin rewrites the measure operand of
> **the module the pass sees** and therefore **inherits the very fold that erased the taint**. The
> only comparison that can see rival 2 is the **C-level** twin (the `undef` source on the subject
> against the `= 0` source on the oracle), a different and weaker instrument the track ran exactly
> once, on a program where the two coincide. CLAUDE.md **L10** on a checker this repo ships — *an
> instrument's failure mode is to report a PASS*. **Do not read "0 divergences" as covering rival 2.**

Landed at: `MeasureLowering.cpp` clause (1a) (the "RIVAL 2 (QUANTUM)" block), `MeasureLowering.h`
(the one-sentence version that belongs at every site), `../trackE2/IMPL_E2.md` §6, and the two
fixtures of §1.3.

### 1.2 ⚠ The pre-existence ground was RE-MEASURED here, not inherited (Rule 11)

The ruling rests on it, and it is now in shipped source, so this round measured it independently —
stage 1 (`clang -Iinclude -include CQ.h -O1 -g`) on the review's committed probe sources, stage 2 on
**both** binaries:

| probe | ORACLE | FIX binary |
|---|---|---|
| `y1_quantum_measure_folded_to_undef.c` (`q + u`) | **exit 1**, 290 B stderr, the undef-operand decline | exit 0, **0 B stderr**, `alloc_i32; ry_i32` — **no measure** |
| `y2_quantum_measure_mul_undef.c` (`q * u`) | **exit 0**, 0 B stderr, `alloc_i32; ry_i32` — **no measure** | identical |
| `y3_quantum_measure_and_undef.c` (`q & u`) | **exit 0**, 0 B stderr, `alloc_i32; ry_i32` — **no measure** | identical |
| `y1b_written_zero.c` (`int u = 0`) | exit 0, `alloc_i32; ry_i32; measure_i32` | identical |

**`q * u` and `q & u` already emit, on the ORACLE, exactly the stream `q + u` now gets** — the
class pre-exists, measured on this box by this agent. And `y1b` shows what the class costs: the
measurement is in the twin's stream and in neither of the other three.

### 1.3 The red-green pair the review specified — both fixtures written, both validated by mutation

| fixture | direction | measured |
|---|---|---|
| `ir-pass/test/lowering_measure_undef_operand_after_taint_fold.ll` | **ACCEPT** on the subject; **RED on the ORACLE** | ORACLE: `exit=1`, **0 bytes of stdout**, `cq_measure_<sfx> operand is an undef/poison literal…`. FIX binary: `exit=0`, 0 bytes stderr, and its whole-file `NOMEASURE` prefix pins that **`cqrt_measure` does not occur in the emitted module** |
| `ir-pass/test/lowering_measure_taint_fold_control.ll` | ACCEPT on **both** binaries | the one-token control (`undef` → `%1`); emits `cqrt_measure_i32`; its lowered module is **byte-identical under both binaries** (`cmp` clean), which is the strongest available statement that E2 did not move the control |

**Mutation validation** (`probes/mutation_pair_check.sh`, committed): the two modules differ in
exactly one token, so **each is the other's mutant**. Running each fixture's own prefixes with the
FileCheck command line lit uses:

```
lower: A exit=0 (366B)  B exit=0 (421B)
-- BOUNDARY CONTROL: each fixture against its OWN module (expect all 0)      → 7/7 green
-- MUTANT of A (operand undef -> %1): A/CHECK 1, A/COUNT 0, A/NOMEASURE 1, A/NOINTR 0
-- MUTANT of B (operand %1 -> undef): B/CHECK 1, B/COUNT 1, B/NOINTR 0
mutation pair check: 2 mutants, both CAUGHT, 0 MISSED; boundary controls green
```

The discriminating prefixes are named rather than summarised: `CHECK` and `NOMEASURE` for A,
`CHECK` and `COUNT` for B. `COUNT`/`NOINTR` do **not** flip in the A direction and that is correct —
both modules have one rail, one rotation and no surviving intrinsic.

⚠ **TWO L10 INSTANCES FROM THIS ROUND'S OWN THROWAWAY TOOLING, RECORDED BECAUSE THE RULE IS THAT WE
RECORD THEM — both reported a PASS, neither was caught by reading the output.**

1. The first spelling of the mutation harness reported **7 of 7 green including the mutants**: it
   read `$?` after an `if …; then CMD >log; lbl=CHECK; fi`, i.e. the exit status of the
   **assignment**, which is always 0. The committed script reads `$?` immediately after the command,
   runs a **boundary control** on every invocation, and **exits 2 with no argument** (measured:
   `ERROR: no build dir given (a vacuous run is a HOLE, not a pass)`).
2. The duplicate-body verdict scan (§5, L8) ran under **zsh**, where an unquoted `$files` does
   **not** word-split — so its inner loop ran once per group with a multi-line string as the
   filename, every `grep` missed its file, and it printed `verdicts=A` for **all nine** groups,
   including five that are in fact `DD`. Re-run under `bash` with `while read -r`: **9 groups,
   `mixed=0`.** ⚠ A harness that silently classifies everything into one bucket looks exactly like a
   clean result.

### 1.4 What was NOT done, deliberately

* **No fence, and none was invented** — the review explicitly declined to propose one and the owner
  explicitly rejected *decline-when-ever-tainted* (it needs a taint-history test surviving a fold
  that already erased the taint) and *reverse E2*.
* **No warning** (`DECISIONS.md` E9, and the owner's words twice on this family).
* **No e2e slice.** E2's §7.1 reasons are unchanged by this round, and the review measured the e2e
  layer immobile 409/409.

---

## 2. `F-E2-2` (P2) — the FALSE sentence is out of shipped source

**Was** (`MeasureLowering.cpp` clause (1a), and `IMPL_E2.md` §6 verbatim):

> *"the emitted stream is BYTE-IDENTICAL to what a written `= 0` produces — measured over the
> decline's whole censused population, 0 divergences, 0 `A→D`"*

**Is now**, in both places:

> *"the emitted stream is BYTE-IDENTICAL **to the same module with that one operand token written as
> the type's zero** — 12 of 12 measured by the track, extended to **32 of 32** by the review, 0
> divergences, 0 `A→D`. It is **NOT** 'byte-identical to what a written `= 0` produces': that
> sentence stood here, in shipped source, until 2026-09-15, and it is FALSE for an operand with more
> than one use — this clause rewrites the MEASUREMENT'S RESULT and never the operand's other reads,
> so `int u; int m = cq_measure(u); return m + u;` keeps `undef` at the second read where the
> written-`= 0` source has `0`. The SOUNDNESS ground is LangRef and is UNAFFECTED — each read of an
> `undef` may independently be any value of its type — so what was wrong is the CLAIM, by exactly
> the multi-use case."*

**Where**: `ir-pass/src/MeasureLowering.cpp` (the "RIVAL 1 … CORROBORATION" block, adjacent to the
pre-existing *"the operand's OTHER uses are not rewritten"* note, which is the limitation §8 of the
record already stated correctly) and `../trackE2/IMPL_E2.md` §6 half (2). §3.1 was **not** weakened —
it was already precise about the one-token twin — and §8's bullet now says in one line that it is
the sentence §6 contradicted, so a future reader sees the contradiction was between two sections of
one record and not a change of fact.

This is **L7-with-a-twist** landed the way that lesson demands: the correction is applied **to the
source in the same change as the record**, not filed.

---

## 3. `F-E2-3` (P2) — the trigger set no longer presents itself as exhaustive

**The claim that was wrong**: E2 declared itself a *"SECOND CUSTOMER"* of bd `z9t1`'s trigger (ii)
**as a pair** (`isa<UndefValue>` **and** `undef` uniquing).

**What landed** (`MeasureLowering.cpp`, trigger block; same in `IMPL_E2.md` §6):

* **(ii) is split.** The `isa<UndefValue>` half **transfers** — same predicate, same direction (it
  gates a DECLINE everywhere else and a REWRITE here), same consequence if widened. The **uniquing
  half does NOT**: uniquing is load-bearing for `z9t1` because F1's second sub-clause is a literal
  `Value*` **identity** test (`ArmClassify.cpp`, `MergePhi->getIncomingValue(PredIdx) != RotBase`),
  so manufacturing a uniqued zero makes two operands *the same pointer* — **and this clause performs
  no identity test anywhere**: it asks a type question and RAUWs the measurement's **result**. The
  source now says **HALF customer**, and names CLAUDE.md's **mirror of L3** as the class of the
  mistake.
* **A new trigger (v) carries the argument the borrowed half was standing in for**, and it was
  stated nowhere before: **`lowerMeasures` runs AFTER every `Value*`-identity fence in the pass** —
  called in both entry points after `repropagateControlMerges`, hence after every
  `detectControlRegions` / `classifyArms` / F1 / F2 — so a zero manufactured here **cannot reach a
  pointer-identity test at all**. It is **cross-referenced to bd `21mg`'s ordering trigger** in this
  same file (which forbids the same reordering for a different reason: a round-2 rail measure
  degrading into a classical passthrough of an `i32` handle). **One ordering fact, two triggers,
  read together.**
* **A new trigger (vi)** carries the owner's E9 retirement condition for rival 2 (a taint-history
  record surviving `-O1`, or `q * u` / `q & u` ceasing to ship this circuit on `main`).
* ⚠ **The numbering (i)–(iv) is unchanged on purpose**: `IMPL_E2.md` §6 and `REVIEW.md` cite those
  numbers, so (ii) was split **in place** and (v)/(vi) appended. The source says so, so the next
  editor does not "tidy" it.

⚠ **No edit is owed to `RotationLowering.cpp`**: its own trigger (ii) names **no customer**, so it
carries no claim about E2 to correct. Measured: `grep -n "SECOND customer" ir-pass/src include` has
exactly one hit, and it was the `MeasureLowering.cpp` line this round rewrote.

---

## 4. The track's open item 3 — re-grounded, not swapped

The reviewer agreed with **not** taking the `valueCarriesUndef` → `slotCarriesUndef` swap and
rejected the stated reason. Landed in **three** places (`MeasureLowering.cpp`'s `kMsgUndefOperand`
block, `ir-pass/test/lowering_reject_measure_undef_global_init.ll`'s header, `IMPL_E2.md` §2.4) and
in the bead note:

* **The ground that holds is SEMANTIC.** `slotCarriesUndef`'s `SkipGlobals=true` exists for
  **emitted gate slots**, and its argument — *"a `GlobalValue`'s operands are its INITIALIZER, while
  the value under test is the global's ADDRESS, which is defined no matter what it is initialised
  to"* — is about **literal integrity at the `-O0` stage-3 link**. A **measurement** asks a
  different question — *what value does this read report?* — and nobody has ruled whether an
  initialiser's `undef` field is reachable from it. The swap would be **adding a caller to a shared
  predicate without asking whether the callee's argument reaches the new caller**: the **L3-mirror**,
  the defect that cost a P1 filing on 2026-09-14 (`WireWalk.h` / `readerStalesItself`), whose
  instruction *widen the vocabulary or fence the caller in the same change* applies verbatim. **It
  therefore needs an OWNER RULING**, not developer discretion.
* **The ground that does NOT hold, recorded as such**: *"it would leave `kMsgUndefOperand` with no
  customer."* **Hygiene is not a ground for keeping an over-decline** (owner, 2026-09-11); the
  correct response to "no customer" is to **delete the string**, which retirement trigger (iv)
  already requires. That sentence is **binding as a consequence** of the swap and was never a reason
  against it.
* **Practical weight: near zero** — a residual member needs a `GlobalValue` in the operand's
  constant chain, i.e. roughly `cq_measure((int)(intptr_t)&g)` with `g` partly uninitialised. A
  reason the question is not urgent; not a reason the answer is obvious.

---

## 5. The review's housekeeping notes — disposition

| note | disposition |
|---|---|
| 1. `DECISIONS.md` E2 ends *"Track M."*, `ROUTING.md` says Track E2 | **Not mine to fix** — both files are on `main`, outside this worktree. Relayed to the orchestrator; the attribution string is unaffected (movers are attributed by **string**, and E2 adds and deletes none). |
| 2. `refinement_check.py`'s docstring is false about its own mechanism (`m.ll` / `twin_m.ll`, not one basename) | **Not fixed here.** It lives on `fve8-undef-measure` and is harmless (`body()` strips `; ModuleID` / `source_filename`), but it is the L10 class on the instrument the rival-1 ruling rests on. **Filed for the orchestrator**; a one-line docstring fix is the whole job. |
| 3. `lowering_reject_measure_undef_operand.ll` is an ACCEPT under a `reject_` name → add to bd `gahu` | **Relayed.** Deliberate (bd `gahu` / L8: a `git mv`'d fixture can be resurrected by a merge); the count there becomes four. ⚠ **This round adds no `reject_`-named accept** — both new fixtures are named `lowering_measure_*`, neither claims a verdict in its name. **Measured** while here: a duplicate-body scan over all **2043** fixtures finds **9** duplicate-body groups and **0** with mixed verdicts, and both new fixtures have unique bodies (`GATES.md`). |
| 4. `ll/w3_vector_undef.ll` accepts on both binaries (unrecognised suffix never enters `MeasureFns`) | **Out of scope, unchanged, pre-dates E2.** Relayed as a reserved-name question. |

---

## 6. What this round did NOT do, and what is still owed

* **`cq-opt-equivalence-full` is still OWED at the group gate.** E2 moved a decline string's
  population; this round moved nothing, so the obligation is **unchanged, not discharged**.
* **`SCOPE_M.md` §1.3(b)'s `ConstantExpr`-residual correction** (E2's open item 2) is still owed —
  that file is on Track M's branch.
* ⚠ **Rule 13 is NOT closed by this fix.** The review's own closing note stands verbatim: *"do not
  close this as Rule-13-cleared on one round"*, and **the composition that has had no review at all
  is `F-E2-1` against the rail-bank headline** — both land in `lowerMeasures`' branch (1), and the
  headline's whole purpose is to keep a *different* class of value out of it. `MERGE_FILINGS` F-1's
  lesson applies: **a composition is not cleared by clearing its parts.**
* **No production line changed**, so no corpus sweep was re-run and no e2e layer was touched. The
  binary is bit-identical; the evidence for that is §0.
