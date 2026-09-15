# MUTANTS — Track J. Every fix here was made to FAIL ON PURPOSE.

> *An instrument's failure mode is to report a PASS, so the only instrument worth citing is
> one that has been made to fail on purpose.* — CLAUDE.md L10, this track's brief.

Two directions, and both are needed. **(A) MUTATE THE SUBJECT**: plant the defect, require
the instrument to name it. **(B) MUTATE THE INSTRUMENT** (a kill test): delete the rule,
require the instrument's own selftest to go RED. (B) is the one that catches a rule nothing
pins — and it caught **three** here, one of them in my own first draft of (A).

Binary for every run: ORACLE `cq-opt 0e280fc62a91cec2`. The kill-test driver is committed at
`probes/killtest_free_pairing.py`; it copies the checker + its selftest to a temp dir, applies
one textual mutation, and runs the selftest, so **the shipped tree is never mutated in place**.

---

## 1. `free_pairing_check.py` — direction (A), planted defects

`tools/free_pairing_check_test.py`, layers 2d (undef) / 2e (census object) / 2f (census line).

```
$ python3 tools/free_pairing_check_test.py
free_pairing_check_test: 30 positive fixture(s), 2 free-order pair(s), 1 cost bound(s),
  77 named mutant(s), 10 memory mutant(s)/refusal(s), 5 Case-A negative(s),
  19 census case(s), 315 proof-targeted mutant(s) (4 exempt by rule), 0 failure(s)
```
(was `69 named mutant(s) … 0 census case(s)` before this track.)

**bd `1739` hole 2 — 5 mutants, 3 controls.** `undef-t1a-unc-pair`, `poison-t1a-unc-pair`,
`undef-t1b-inv-pair`, `undef-constexpr-operand` (an `i32 add (i32 undef, i32 1)` — the
`norm_arg` constexpr arm keeps the whole text, so the textual match succeeds for exactly the
same wrong reason) → `T1-undef-literal-pairing`; `undef-a2-xorc-bracket` →
`A-undef-literal-pairing`. Controls: the same two shapes with a REAL literal, plus
**`undef-control-alloc-seed-slot`**, which pins the one slot this fix must NOT refuse.

⚠ **Why layer 3 could never have caught hole 2**, and it is the general lesson: layer 3
mutates what the checker MODELS — it blanks a line a proof consumed. Hole 2 is not a missing
line. It is an **OPERAND AXIS outside the model**: every witness line is present, the
structure is perfect, and only the run-time values differ. Hole 1 is the same shape one step
over — a MINT KIND outside the model. Neither is reachable by perturbing the model.

**bd `rixk` / `19vy` / `1739` h1 — 19 census cases.** The census is not a finding, so **no
layer above can see it**: a census reporting twice the truth scored as a pass everywhere.
Layer 2e checks the census OBJECT (`rixk-inlined-dead-body`, `-control-callee-called`,
`-inlined-AND-called`, `-address-taken-is-live`, `-indirect-counts-all`,
`-no-main-both-entries`, `-cycle-with-no-entry`, `-no-main-cycle-counted`;
`1739h1-template-{left-dirty,measured,reversed,freed,freed-only,escaped,returned}`,
`-tape-kept-by-design`). Layer 2f checks the census **LINE** — see K10.

---

## 2. `free_pairing_check.py` — direction (B), kill tests

`python3 probes/killtest_free_pairing.py`. **14 mutations, 14 RED, 0 survivors.**

| # | rule deleted | selftest says |
|---|---|---|
| K1 | the T1a/T1b undef refusal | `UNDEF MUTANT undef-t1a-unc-pair: expected T1-undef-literal-pairing, got NOTHING (survived)` |
| K2 | the `adjoint_matches` undef refusal | `undef-a2-xorc-bracket … NOTHING (survived)` |
| K3 | census counts every function (pre-`rixk`) | `CENSUS rixk-inlined-dead-body: expected (3,3,0,0,False), got (6,6,0,0,False)` |
| K4 | census counts only `cqrt_alloc` (pre-`19vy`) | `1739h1-template-left-dirty: expected (1,1,1,1,…), got (1,1,0,0,…)` |
| K5 | the tape-kept-by-design exclusion | `1739h1-tape-kept-by-design: … got (1,1,1,1,…)` |
| K6a–e | drop `measured` / `uncd` / `returned` / `freed` / `escaped` from the discharge set | each names its own case |
| K7 | the indirect-call fallback | `rixk-indirect-counts-all: expected (6,6,0,0,True), got (3,3,0,0,False)` |
| K8 | address-taken roots | `rixk-address-taken-is-live: … got (3,3,0,0,False)` |
| K9 | the no-`main` early-out | `rixk-no-main-both-entries: expected (2,2,…), got (0,0,…)` |
| K10 | the census LINE reports the alloc half only | `CENSUS LINE line-template-left-dirty: printed line is missing '1 template rail mint(s) of which 1 left dirty'` |

### ⚠ THE THREE KILL TESTS THAT CAME BACK GREEN FIRST — the point of doing this at all

**K6d (`res in freed`) survived.** The first draft's "freed" census case was derived from the
`_unc`'d one, so it was BOTH reversed and freed, and deleting the `freed` clause changed
nothing. Fixed by adding `1739h1-template-freed-only`. **A clause nobody has deleted is a
clause nobody has validated**, and a case that happens to satisfy two clauses validates
neither.

**K9 survived.** The first draft's no-`main` rule was `roots = defined - called`, and every
case I had written was rescued by an `if not roots` fallback. The rule was **replaced**
rather than re-pinned: a module with no `main` is a TRANSLATION UNIT whose external functions
may be entered from outside, so it is counted whole — which is also strictly safer, and makes
the `rixk` narrowing apply only where the defect can exist (the shape REQUIRES a `main`).
`rixk-no-main-cycle-counted` pins it.

**K10 survived, and it is the one that matters.** Every census case checked the census
**OBJECT** returned by `check_module`. A regression that computed all four numbers correctly
and then dropped the template clause from `main()`'s printed line scored GREEN across the
whole of layer 2e. **The instrument's own failure mode, one level down: I had pinned the
value and not the report.** Layer 2f now runs `main()` and reads the line a human — or a
record — actually sees.

---

## 3. `negative_vacuity_check.py` — direction (A)

```
$ python3 tools/negative_vacuity_check_test.py
negative_vacuity_check_test: 6 hole case(s), 4 positive(s), 10 mutant(s)/control(s), 0 failure(s)
```
ctest: `e2e-negative-vacuity-selftest` — **Passed, 5.01 s**.

**The largest layer is HOLE, not MUTANT, because bd `jdec` is a defect of SILENCE.** Six
cases must EXIT 2 and never 0: no arguments · a nonexistent fixture · a batch matching no
directive · a `--universe` that lowered to nothing · a missing compiler · **a generator
fixture whose compiler input is not `%s`**.

Mutants: `V2-HANDLE-UNDEFINED`, `V1-MATCHES-HEADER`, `V4-PREFIX-NEVER-RUN`,
`V0-EMPTY-MODULE`, `V3-UNREACHABLE-SYMBOL` (under `--strict-unreachable`).
Controls: a live symbol negative · the three V2 shapes the inherited regex got wrong (formal
PARAMETER, BASIC-BLOCK LABEL, quoted name) · a scoped-out header collision · an emittable
symbol · a front-end intrinsic · **`v3-is-a-note-by-default`** · **`one-fixture-universe-
undecidable`** (a single-fixture run must NOT claim a vacuity it cannot decide) · and the
verdict line must carry the compiler's sha256.

### ⚠ THE SELFTEST CAUGHT A DEFECT IN ITS OWN FIXTURE, WHICH IS THE BEST THING THAT HAPPENED HERE

The V3 control failed. The cause was **not** the rule: my `ACCEPT_BODY` declared
`@cq_theta_i32`, and the intrinsic is spelled **`cq_theta_si32`** — the suffix is the
`_Generic` tag, not the LLVM type. **A module with the wrong spelling lowers to ITSELF through
the passthrough early-out, exit 0**, so my "universe" was a module with no `cqrt_*` in it at
all, and *every* negative over it would have been vacuous. That is the
`empty-module-accepts-vacuity-trap` wearing a different hat, planted by the author of the
anti-vacuity tool, in the anti-vacuity tool's own fixture. It is now a comment in the file.

---

## 4. The four fabricated-finding classes the corpus run killed before they shipped

Direction (A) and (B) both pass on a rule that is simply WRONG about the tree. Running the
tool over all 2039 fixtures is the third direction, and it removed four rules that would each
have shipped as a defect report. **Full table in `IMPL_J.md` § bd `jdec`.** In one line each:
a permissive prefix regex "found" **719** orphan prefixes (all comment prose); an unscoped V1
"found" 24 header collisions (FileCheck scopes a `-NOT` between positive directives); V2
asked about the lowered module only and "found" 5 (3 were ELIMINATION negatives — the
absence IS the assertion — and 1 was an LLVM TYPE name); and **V3 as a verdict "found" 1116,
every one examined a WORKING negative**, so it is demoted to a NOTE.

⚠ **Track W's checker carries V3's rule unchanged and reported `0 VACUOUS` — because its
universe was six modules.** A rule that is wrong at scale can look right on a small batch,
and that is an argument for running an instrument over the whole corpus before trusting any
verdict it gives on a batch.

---

## 5. What is NOT mutant-validated, said plainly

* The **749 V3 notes**, **33 latent V1 collisions**, **18 V5 decline-stdout notes** and
  **155 unmodelled-stream directives** are POPULATIONS, not verdicts. Nothing validates that
  they are the right populations; they are printed so they cannot become silent.
* The **`census_of` totals** are cross-checked against `census_03_orphan_rails.py`'s
  independent trace-layer sweep (5048/154 vs 5046/155 — `IMPL_J.md`) but that is an
  AGREEMENT BETWEEN TWO INSTRUMENTS, not a proof either is right about the circuit.
* The **blast-radius sweep** (0 exit-code movers over 368 lowered slices) is a comparison of
  two checker versions, not evidence that either verdict is correct.
