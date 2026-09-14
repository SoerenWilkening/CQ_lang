# Track I — the INSTRUMENTS: bd `21re` closed, and the L-1a witness designed

Worktree `/Users/sorenwilkening/Desktop/CQ_inst`, branch `railbank-instruments`, off `main`
`c8007c37`. Files touched: `tools/free_pairing_check.py`, `tools/free_pairing_check_test.py`, and
records + probes under `$SES/trackI/`. **No file under `ir-pass/`, `include/` or `runtime/` was
opened for writing.** No build was made: both jobs are pure python over lowered IR, and every lowered
module below came from the **frozen ORACLE** `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
sha256 `5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8` (verified before use; the
primary `build/` was read, never written).

---

## 0. The one-paragraph summary

bd `21re` is **CLOSED by construction and kill-tested**: `free_pairing_check.py`'s
`provably_not_a_rail` rested on a docstring premise — *"a tainted `store` is a loud decline at
`declineTaintEscapes` long before lowering — so a load result is not a rail"* — that bd `xdu2` exists
to falsify, and the premise is now a **CHECK** (`adjudicate_memory`) rather than an assumption. Two
distinct wrong-discharges were **reproduced on the shipped tool at exit 0** before the fix and are
committed as subjects. The witness design for L-1a is in §4: the primary witness is the **golden
trace**, the rolled-vs-unrolled byte-identity gate **does not exist for the owner's cascade** (I
re-measured why, and got a sharper reason than the line-count one on record), it **does** exist for the
identical-trip sub-program (measured: it accepts on the oracle today), and everything else is labelled
INTERNAL-CONSISTENCY in the required style.

⚠ **Two corrections to documents this session is working from are in §6. One of them is a stale
measurement in `SCOPE_L1a.md` §7 that would have mis-scoped the twin.**

---

## 1. Job (a) — bd `21re`: what was wrong, shown before it was fixed

### 1.1 The premise, and why it is load-bearing

`tools/free_pairing_check.py` `provably_not_a_rail` answers **True** ("this operand is provably not a
rail handle") for any `%`-prefixed SSA value that is not a known stream rail, not a formal parameter
and not a rail-minting call result in the function. A non-call instruction result therefore answers
True **by absence of evidence**, and the docstring converted that absence into *positive* evidence for
the `load` class with the sentence quoted above. Rule (A1) — *"every write to this rail is a classical
immediate, so it still holds a known classical basis state"* — consumes that answer directly, and
(A1) is what discharges a `cqrt_free`.

bd `xdu2` (L-1a) carves `bool b[N]` into an `[N x i32]` bank of rail **HANDLES** marked
`!cq.railbank`, so a load from a bank cell **is** a rail. The premise is then false and (A1) becomes
the bd `az1h` defect again, through a door nobody was watching.

### 1.2 The subjects, measured on the SHIPPED tool at `c8007c37` (pre-fix)

All six committed at `$SES/trackI/probes/p*.ll`. They are **hand-built by construction and had to be**:
Track A ships the classifier this session while the taint rule and the type rewrite are deliberately
deferred (`BRIEF_A.md` §0), so no compiler in the tree can emit a `!cq.railbank` load today.

| probe | construct | PRE-FIX verdict (`python3 tools/free_pairing_check.py --explain`) |
|---|---|---|
| `p1_bank_imm_slot.ll` | a bank load in `cqrt_xorc_i32`'s classical-immediate slot, then `cqrt_free` of the entangled rail | **`OK @slice line 29 [%r] via A1-classical-immediate`, exit 0** |
| `p2_bank_control_slot.ll` | a bank load as the CONTROL of two `cqrt_copy_i32_controlled`, with the rail flipped through its MINT name in between | **`OK @slice line 32 [%o] via A2-reduces-to-identity`, exit 0** |
| `p3_target_measure_only.ll` | the L-1a design target: bank load, measured and nothing else | 1 verified, exit 0 (this one is CORRECT and must stay so) |
| `p4_classical_global_load.ll` | the shipped `XORC_SSA` shape — `load volatile i32, ptr @msk` in the immediate slot, **no bank** | 1 verified, exit 0 (correct; the premise holds here) |
| `p5_unmarked_rail_store.ll` | a rail stored to an **unmarked** local slot | 1 verified, exit 0 |
| `p6_undecidable_load_base.ll` | a bank in scope, a load through a formal-parameter pointer | 1 verified, exit 0 |

⚠ **And the over-decline control, which is the row that would have blocked the increment.** The L-1a
design targets `$SESP/trackL/probes/TARGET_rolled_stage2.ll` and `…_mloop.ll` — hand-written to the
design, with a `!cq.railbank` alloca, a variable-index `getelementptr`, a rail store and three bank
loads feeding `cqrt_measure_i1` — report
`4 rail mint(s) of which 3 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`,
exit 0, **byte-identically before and after the fix**. A checker that refuses the increment's own
emitted shape is an over-decline, not a safety margin (owner ruling 2026-09-11).

`p2` is worth reading twice: it **never reaches `provably_not_a_rail` at all**. The write history is
keyed on the literal SSA operand string, so the bank load `%v` has an EMPTY history, `unchanged_over`
answers "unchanged", and a pair that does not cancel physically cancels in the model. **A one-line
edit to the predicate the bead names would have left this one open**, which is why the fix is a rule
set rather than a patch.

### 1.3 The fix

`adjudicate_memory` (new, `tools/free_pairing_check.py`), called from `check_module` **after** the
mint scan (it needs to know which values are rails) and **before** anything consults `rail_defs`. It
raises the new `Undecidable` exception — the `Unclassified` discipline one layer down — for a
construct whose rail-ness the model cannot decide, and returns the bank-load results, which
`check_module` folds into `rail_defs` so `provably_not_a_rail` answers **False** for them.

| rule | fires on | why a REFUSAL and not a finding |
|---|---|---|
| **L1** `rail-stored-to-unmarked-memory` | a `store` whose value is a known rail of this function and whose object is not a `!cq.railbank` bank (or is unresolvable). **Unconditional** — this is the premise itself, turned into a check | either the promoter forgot the marker or a second escape mechanism exists; every load classification below it would be a guess |
| **L2** `undecidable-load-provenance` | with a bank in scope, a `load` whose underlying object cannot be resolved (`select`/`phi`/`inttoptr`/a parameter) | with a bank present the answer decides classical-immediate vs rail |
| **L3** `bank-rail-in-a-modelled-rail-slot` | a bank-load result in a slot `classify()` models as a RAIL slot (a read or write index, **not** a `classical_imm` slot) at any symbol other than `cqrt_measure_<W>` | `Rail.writes` is keyed on the SSA name, so that name and the mint's name are two rails to the model; no verdict about either is sound |
| **the positive arm** | a bank-load result in a `classical_imm` slot | not a refusal: `provably_not_a_rail` now answers False and rule (A1) correctly declines to discharge, reporting `A1-imm-not-classical` |

An UNPROVEN finding can be waived with `--allow-unproven`; a **waivable model-unsoundness is the
hole, not the report of it**, so L1/L2/L3 raise. They are reported by `main()` as
`UNDECIDABLE MEMORY CONSTRUCT [<code>]`, counted in the summary line, and exit non-zero.

`cqrt_measure_<W>` is the **one** exemption in L3, and it is not a convenience: it is the only use of
a bank load that SCOPE_L1a's D5 allow-list sanctions, and it is the L-1a emitted shape (`p3`). **If
the pass's D5 allow-list ever widens past `cq_measure`, this exemption must widen in the same change
or stage 2b will refuse the increment's own output** — that is written at the mechanism.

### 1.4 POST-FIX verdicts (same command, same probes)

| probe | verdict | code |
|---|---|---|
| `p1` | **exit 1**, `0 verified, 1 unproven` | `A1-imm-not-classical` |
| `p2` | **exit 1**, refused | `L3-bank-rail-in-a-modelled-rail-slot` |
| `p3` | exit 0, 1 verified | — (unchanged, as required) |
| `p4` | exit 0, 1 verified | — (unchanged, as required) |
| `p5` | **exit 1**, refused | `L1-rail-stored-to-unmarked-memory` |
| `p6` | **exit 1**, refused | `L2-undecidable-load-provenance` |

### 1.5 The docstring was fixed AT THE SOURCE, not only in the record

`CLAUDE.md` L7-with-a-twist (bd `z9t1`, three rounds on one sentence): *a record correction that is
not applied to the source is not a correction*. The false clause has been **removed from
`provably_not_a_rail`'s own docstring** and replaced by the measured residue — the 4
`load volatile i32, ptr @off` corpus sites still answer True, *because `@off` is not a bank and no
rail is stored into it*, which is the narrow consequence the old sentence over-generalised.

### 1.6 What the fix deliberately does NOT do — bd `21re`'s sibling risks, documented so the next increment does not rediscover them

1. **A bank load is NOT entered into the stream write history (`self.rails`).** Doing so would
   MANUFACTURE a second rail identity for one physical rail, which is the defect and not the fix. L3
   is what makes that absence safe: no modelled rail slot may hold one. **The day L-1a's D5 allow-list
   admits a second use, this is the decision to re-open**, and it is a memory model, not a patch.
2. **L1 keys on values this file can SHOW are rails** — a rail-minting call result in this function.
   A **formal parameter** is "cannot vouch either way" (`provably_not_a_rail` refuses it too), and
   refusing every parameter store would fire on classical spills. A promoter that banks a *parameter*
   rail is out of reach. It is also not a shape L-1a emits (a bank is a local alloca).
3. **Intra-procedural, like the rest of the file** (bd `1yeu`).
3b. **A bank load LAUNDERED through classical arithmetic and only then handed to a gate is not matched
   by L3** — it matches the load's own SSA name. That is the header's existing
   *"ALIASING THAT IS NOT SSA-IDENTITY"* / *"NON-CALL instructions"* blind spot reached through the
   bank instead of through a `select`, and what stands in front of it is the PASS, exactly as it does
   there: SCOPE_L1a's D5 allow-list makes *"a bank load feeding arithmetic"* a loud decline. **Filed,
   not left implicit; it is the first thing to build if D5 widens.**
4. **`free_pairing_check.py` counts `cqrt_alloc` SITES, not executions**, and bd `21re` does not
   change that. Two measurements, both on the frozen oracle, so the next increment argues with numbers
   rather than with the sentence:
   * the L-1a design target `$SESP/trackL/probes/TARGET_rolled_stage2.ll` at K=3 reports
     `4 rail mint(s) of which 3 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`
     — for a circuit that executes **10** allocations and leaves **7** allocated.
   * ⚠ and it is **not a loop property**. `$SES/trackI/probes/w1_flat_prep_only.c` has no loop at all:
     `-O1` inlines `slice` into `main` and keeps both, so the module holds **6** `cqrt_alloc_i1` call
     sites, 2b reports `6 rail mint(s) of which 6 left allocated`, and the trace shows **3**
     allocations. Any reading of that census as a count of RAILS is wrong today, in a shipped shape,
     with no bank and no loop involved.
   Fixing it is a bigger question (it needs execution counts, i.e. trip counts, i.e. the thing the
   checker deliberately does not model) and is **not** in this increment.

---

## 2. Job (a) — the mutant validation, and the instrument made to fail on purpose

### 2.1 `tools/free_pairing_check_test.py`, extended

| layer | before (`c8007c37`) | after |
|---|---|---|
| positive fixtures | 26 | **30** (+`bank-load-measured-only`, `bank-plus-unmarked-classical-load`, `bank-global-constexpr-gep`, `bank-variable-index-in-loop`) |
| free-order pairs | 2 | 2 |
| cost bounds | 1 | 1 |
| named mutants | 69 | 69 |
| **memory mutants / refusals** | — | **10** (1 finding-mutant + 9 refusal-mutants) |
| Case-A negatives | 5 | 5 |
| proof-targeted sweep | 313 (2 exempt) | **315 (4 exempt)** |
| failures | 0 | **0** |

**MISSED = 0** in the layer's own terms: every one of the 10 memory rows produces its named code.
That number alone is worth little — a table of mutants written against the implementation always
passes — which is why §2.2 exists.

Two tables, not one, and the split is semantic: a defect the model can still render a verdict about is
a **FINDING**; a construct it cannot decide is a **REFUSAL**. The harness asserts the `kind` as well
as the code, so a future change that downgraded a refusal to a waivable UNPROVEN is a failure here.

`BANK_VARIABLE_INDEX` is the fourth positive and it exists because none of the other three uses
`getelementptr ... i64 %i`: a `first_ptr_operand` that only handled CONSTANT indices would have passed
every one of them, and the variable index is the shape the L-1a design target actually emits.

`BANK_PLUS_CLASSICAL_LOAD` is the **discrimination control** and it earns its place: a bank IS in
scope, a second load from an unmarked global still lands in a classical-immediate slot, and it must
still discharge (A1). Without it, *"refuse every load whenever a bank is in the module"* would pass
every other row and would over-decline the 4 real corpus sites the docstring names.

### 2.2 `armkill.py` — the demonstration that the new instrument FAILS when it should

`$SES/trackI/probes/armkill.py`, committed and runnable from the repo root. It deletes each arm of the
bd `21re` rule in a COPY of `free_pairing_check.py`, re-runs the FULL selftest against that copy, and
reports which fixtures go red. **An arm whose deletion leaves the suite green has no coverage and the
row is a lie.**

```
CONTROL (unmutated): exit=0  free_pairing_check_test: 30 positive fixture(s), 2 free-order pair(s),
  1 cost bound(s), 69 named mutant(s), 10 memory mutant(s)/refusal(s), 5 Case-A negative(s),
  315 proof-targeted mutant(s) (4 exempt by rule), 0 failure(s)
  kill-L1-rail-store-refusal                                  caught by 3 fixture(s)
  kill-L2-unresolvable-load-refusal                           caught by 2 fixture(s)
  kill-L3-rail-slot-refusal                                   caught by 4 fixture(s)
  kill-rail_defs-fold (the provably_not_a_rail arm)           caught by 1 fixture(s)
  kill-the-!cq.railbank-marker-read                           caught by 10 fixture(s)
  kill-the-global-bank-marker-read                            caught by 1 fixture(s)
  kill-resolve_object-refusal (everything forwards)           caught by 1 fixture(s)
  kill-the-store-pointer-operand-fix (first ptr of the line)  unobservable by construction (exempt)
  over-fire: refuse EVERY load while a bank is in scope       caught by 1 fixture(s)
  over-fire: drop the cqrt_measure exemption from L3          caught by 4 fixture(s)
armkill: 10 mutation(s), 0 SURVIVED, 1 exempt with a written reason, 0 malformed
```

Two things about that table are the point rather than the decoration:

* **Two rows mutate in the OVER-firing direction.** A rule that refuses everything passes every kill
  test and over-declines the increment it exists to protect; the owner's 2026-09-11 ruling makes that
  a defect, not a margin. Both are caught by POSITIVE fixtures.
* **The one exempt row is exempt WITH A WRITTEN REASON**, in the `SWEEP_EXEMPT_RULES` style: a rail
  handle is always an `i32` (Rule 15), so a `store` whose value type is `ptr` never carries one and
  the pointer-operand guard cannot be exercised today. It is listed, not hidden, and it is **not
  counted as covered**.

### 2.3 ⚠ THE HARNESS LIED TWICE BEFORE IT TOLD THE TRUTH, and both are recorded at the mechanism

This is the paragraph the brief calls the job description, so it gets the measurements rather than a
gesture at them.

1. **A mutation that is MALFORMED scored as a catch.** The first spelling of the "drop the
   `cqrt_measure` exemption" mutant deleted two lines and left their indentation behind, so the copy
   raised `IndentationError`, the selftest died at import, `returncode != 0`, and the harness recorded
   *"caught"*. **A harness that scores its own syntax errors as coverage is measuring itself.** It now
   distinguishes `MUTATION MALFORMED — not a catch` and exits non-zero on one.
2. **Stale bytecode mis-attributed a catch to the wrong arm.** Every `kill_raise` mutation removes
   exactly `raise ` — the same six bytes — so two consecutive kills produce files of **identical
   size**, and a `.pyc` is invalidated on `(mtime, size)` at **1-second** resolution. MEASURED: the
   L2 kill was attributed to the three **L1** fixtures on one run and correctly on another, from
   nothing but which side of a second boundary the writes landed on. The row still read as coverage.
   Fixed with `-B` + `PYTHONDONTWRITEBYTECODE`, and the argument is written at `run()`.
3. **The selftest itself died instead of reporting.** Layer 3 called `fpc.check_module` directly, so a
   mutation that made a POSITIVE fixture REFUSE crashed the harness with a traceback *after* layer 1
   had already recorded the real failure — losing the counts and every later layer. `proofs_of()` now
   guards it, with the reason written there.

None of the three was found by a green suite. All three were found by pointing the instrument at
itself.

### 2.4 Zero regression on real lowered IR — measured, not asserted

**Population:** every single-file `tests/e2e/*.c` in this worktree, lowered by the frozen ORACLE with
the `PROTOCOL.md` per-probe pipeline (`clang -O1 -emit-llvm -S`, no `-g`, then `cq-opt`):
**368 lowered modules** (21 declines and 20 stage-1 failures are the multi-file/decline slices and are
excluded — they have no stage-2 module). Each module was run through the **HEAD** checker
(`git show HEAD:tools/free_pairing_check.py`) and the **subject** checker with identical flags
(`--allow-unproven`), and the `exit=` code plus the summary line were byte-compared.

> **RESULT, both instruments: `368 rows / 368 rows`, `diff` empty — IDENTICAL, 0 rows moved.**

It was measured **twice, by two independent harnesses**, because a single comparison of the tool's
SUMMARY LINE cannot see a finding whose CODE moved while its counts did not:
`probes/sweep_s2.sh` + a per-file subprocess run (exit code + summary line), and
`probes/fastsweep.py` in process (rail census `mint`/`leak`, free-site counts, violation and unproven
counts, **and the set of finding codes**). Both files are committed at
`probes/corpus368_{before_98b83e81,after_0cf25b28}.txt`.

Cost: no measurable change. On the largest module (`slice_libm_real_lgamma.s2.ll`, 15 420 lines)
`1.68s user` before and `1.68s user` after.

---

## 3. Job (a) — the L8 retirement triggers, verbatim

Written into `adjudicate_memory`'s docstring, into every probe header, and into the selftest's bank
section:

> **L8 RETIREMENT TRIGGER:** when L-1a's taint rule + type rewrite + D5 allow-list land (bd `xdu2`,
> the second half), REAL lowered modules carry `!cq.railbank`, the hand-built subjects stop being the
> only exercise of these three rules, and **(L3)'s measure-only exemption must be re-derived against
> the allow-list the pass actually ships**. Re-derive it then; do **NOT** delete the subjects.

and per-probe:

> **L8 RETIREMENT TRIGGER:** when L-1a's type rewrite lands, a real slice produces this shape;
> re-derive this fixture against it then; do **NOT** delete it.

---

## 4. Job (b) — the L-1a WITNESS design

### 4.1 The measurement that reframes it: the flat twin is not K copies of anything

SCOPE_L1a §0 H2 says byte identity is unavailable because `-O1` folds trip 0's `a >= 3` in the
unrolled spelling and cannot in the rolled one, and quotes 50 vs 44 lines. **I re-measured it on the
session oracle and the reason is stronger than a line count.** `a_flat_n3.c`'s trace has **three
structurally different per-trip blocks**:

```
trip 0   lines  1-13   alloc_i1; ry_i1;                      <value-arm merge>   <- condition FOLDED (a==5)
trip 1   lines 14-26   alloc_i1; ry_i1; ry_i1_controlled(h0, h5, -0.5);
                                                             <value-arm merge>   <- ANTI-CONTROL by Ry additivity
trip 2   lines 27-40   icmp_sgt_hl -> h9; ry_i1_controlled(h9, h10, +0.5);
                                                             <value-arm merge>   <- the GENERIC block
```

Only **trip 2** carries a real `cq_template_icmp_sgt_i32_hl` flag — it is the first trip where `-O1`
could not fold the condition. So the unrolled twin is not "K copies with a fold at the front"; it is
three different circuits concatenated. **A whole-stream byte diff against it is not a weaker gate, it
is a meaningless one.**

⚠ That same measurement turns the *per-trip* argument from self-consistency into something better —
see W-D.

### 4.2 The components, each with its label and its blind spot

| # | component | LABEL | what it CANNOT see |
|---|---|---|---|
| **W-A** | the **golden e2e trace byte-diff** | **ORACLE-BACKED, and the PRIMARY witness for this increment** — the reverse of the usual division of labour | rail identity at a free; the unitary. It is primary because it is the only layer that sees all K per-trip `cqrt_alloc`/`cqrt_ry` lines, their angles, and the control/target order |
| **W-B** | **rolled == flat byte identity**, on an **identical-trip** program | **ORACLE-BACKED where it exists** | it does **not** exist for the owner's cascade (§4.1, measured); nothing about the unitary |
| **W-C** | **K-independence of the lowered IR**, measured **without `-g`** | **INTERNAL-CONSISTENCY** | anything about the unitary — a wrong-but-rolled lowering satisfies it exactly |
| **W-D** | **per-trip BLOCK reference**: every rolled per-trip block equals the flat twin's **generic** block up to handle renaming | **ORACLE-BACKED for the block, INTERNAL-CONSISTENCY for the repetition** | that the *number* of repetitions is right; and it is vacuous if the compiler emits no per-trip block at all, so it must be paired with a positive count |
| **W-E** | **stage 2b** `free_pairing_check.py` STRICT | **rail identity at a free, and nothing else** | ⚠ it counts `cqrt_alloc` **SITES**: measured `4 mints / 3 left` on a target that mints 10 and leaves 7, and `6 mints / 6 left` on a **loop-free** program that mints 3 (§1.6.4). Structurally blind to template-minted rails. **Do not cite it as clearance here** |
| **W-F** | `e2e-loop-twin-matrix` | **ORACLE-BACKED cross-check** | there is no **bank** axis today (it would need one, §6.3 of SCOPE_L1a); bd `1yeu` one-function-per-module |

### 4.3 Component 4 of the brief, answered BY MEASUREMENT: a byte-identity twin CAN be built — for part of the program

The brief asks whether a program exists whose every trip is identical and whose flat twin lowers.
**Yes, and it is the "measure loop alone" slice SCOPE_L1a §6.1 already lists.** Measured on the frozen
oracle:

* `$SES/trackI/probes/w1_flat_prep_only.c` (three scalar `_Bool`s, an unconditional prep each, three
  measurements) **ACCEPTS**, 55 lowered lines, and prints
  ```
  cqrt_alloc_i1(0) -> h0 / cqrt_ry_i1(h0, 0x1p-1)
  cqrt_alloc_i1(0) -> h1 / cqrt_ry_i1(h1, 0x1p-1)
  cqrt_alloc_i1(0) -> h2 / cqrt_ry_i1(h2, 0x1p-1)
  cqrt_measure_i1(h0) -> 0 / cqrt_measure_i1(h1) -> 0 / cqrt_measure_i1(h2) -> 0
  ```
  — **exactly** the stream the rolled bank must reproduce, three identical blocks and three measures.
* `$SES/trackI/probes/w1_bank_prep_only.c` (its rolled half) declines
  `cq taint escape: tainted value stored to memory`, as expected at the wall.
* and its **stage-1 K-independence precondition is already measured**: `w1_bank_prep_only.c` and
  `w1_bank_prep_only_k1000.c` produce **114 stage-1 lines each** (N=3 and N=1000), both carrying
  `llvm.loop.unroll.disable`. So no constant `N` scalarises and W-C has a real subject.

**VERDICT: build W-B on the identical-trip program — it is strictly better than (1)+(2) and it exists
— and use W-C + W-D, explicitly labelled, for the cascade, where W-B provably does not.** That is
SCOPE_L1a §5's own "must therefore be built on … OR replaced" resolved by measurement: **both**, on
different slices.

### 4.4 `golden_multiset_audit.py` — the WRONG TOOL, with the RIGHT PRIMITIVE inside it

Read in full. It is a **golden-REGENERATION** witness: `--epic {2a,3qlq}`, it takes an OLD golden and
a NEW one and checks that the delta between them is exactly the structural rewrite that epic is
allowed to perform (`git_show(rev, path)`; `audit_pair_*`; `expected_delta`). A **new** slice has no
old golden, and L-1a performs no rewrite of an existing one, so **none of its four checks (S/A/A2/B)
has an argument to be given**. Do not reach for it.

**But `normalise(lines)` (`golden_multiset_audit.py:248`) — renumber handles by FIRST APPEARANCE — is
precisely the primitive W-D needs**, and `strip_handles(lines)` (`:530`) is its handle-invariant
multiset variant. Rule 14: W-D must **call** them rather than re-spell them; a second spelling of a
normalisation is the drbq Inc-3 (b′) defect in miniature.

### 4.5 The exact sentences L-1a's slice headers must carry

Verbatim. Every L-1a slice gets 1, 2, 3 and 5. A cascade slice also gets 4. An identical-trip slice
gets 6 instead of 4.

> **(1)** ⚠ **THE GOLDEN TRACE IS THE PRIMARY WITNESS FOR THIS SLICE — the reverse of this project's
> usual division of labour.** It is the only instrument that sees every one of the K per-trip
> `cqrt_alloc` / `cqrt_ry` lines, their angles, and their control/target order. Read it line by line
> before believing any other gate here.

> **(2)** ⚠ **DO NOT CITE STAGE 2b AS CLEARANCE FOR THIS SLICE.** `tools/free_pairing_check.py`
> counts `cqrt_alloc` **SITES**, not executions, so a rolled per-trip allocation reads as **one** rail
> where the circuit mints K. Measured on the L-1a design target at K=3:
> `4 rail mint(s) of which 3 left allocated` against a trace that allocates 10 and leaves 7. 2b
> witnesses rail IDENTITY at a free; it witnesses nothing about how many rails there are.

> **(3)** ⚠ **K-INDEPENDENCE SAYS NOTHING ABOUT THE UNITARY.** The line counts below prove the loop
> was ROLLED, not that it was rolled correctly. They are an **INTERNAL-CONSISTENCY** gate in the sense
> of `tests/e2e/slice_control_cascade_select_in_loop_outside_prep_unrolled_twin.c:11-15`, not an
> oracle-backed one. Measure them **without `-g`**: debug metadata inflates the count and a `-g`
> number is not comparable.

> **(4)** ⚠ **THE ROLLED-vs-UNROLLED BYTE-IDENTITY GATE IS NOT AVAILABLE FOR THIS PROGRAM, and its
> absence is MEASURED rather than assumed.** With `a` a compile-time constant, `-O1` folds trip 0's
> `a >= 3` away in the UNROLLED spelling and cannot in the rolled one; with an opaque `a` the
> unrolled twin DECLINES (`L13_flat_n2_opaque_noinline.c`, re-measured on this oracle:
> `cq controlled lowering: control flow under quantum control`). The flat twin at N=3 is not K copies
> of anything — its three per-trip blocks are structurally DIFFERENT, and only the last carries a real
> `cq_template_icmp_sgt_i32_hl` flag. What replaces the gate is (a) K-independence and (b) a per-trip
> BLOCK comparison against that last, generic block, both labelled above.

> **(5)** ⚠ Every corpus and gate in this tree is effectively **ONE FUNCTION PER MODULE** (bd
> `1yeu`), so a cross-function defect is invisible to all of them, this slice included.

> **(6)** This slice's twin `<name>_unrolled_twin.c` **IS oracle-backed**: every trip of this program
> is identical by construction, its flat spelling accepts on the pre-L-1a compiler, and its committed
> golden is the stream this rolled slice must reproduce **BYTE FOR BYTE**.

---

## 5. What I could NOT do

1. **I could not exercise the bd `21re` fix on a naturally-produced module**, because none exists —
   the taint rule and the type rewrite are deferred by design this session. Every subject is
   hand-built, every one carries an L8 retirement trigger, and §2.2 is the compensating evidence.
2. **I could not run any component of the §4 witness as a GATE**, because the rolled bank does not
   lower yet. §4.3's numbers are the components' *preconditions* measured on the oracle (the flat twin
   accepts; stage-1 K-independence holds at N=3 and N=1000), not a passing gate. The design is a
   design.
3. **I did not fix the site-counting blindness** (§1.6.4). It needs execution counts — trip counts —
   which is exactly what the checker deliberately does not model. It is documented with two
   measurements instead, one of which needs no loop at all.
4. **I did not build the twin-matrix bank axis** (SCOPE_L1a §6.3). It is Track L/the implementer's,
   and it cannot be built against a lowering that does not exist.
5. **No build, no `ctest`, no `lit`, no full suite** — per the brief's gate row. The one ctest entry I
   own (`e2e-free-pairing-selftest`) is `python3 tools/free_pairing_check_test.py` verbatim
   (`tests/e2e/CMakeLists.txt:4122-4123`) and was run directly; see `GATES.md`.

---

## 6. ⚠ Corrections to documents this session is working from

**(a) `SCOPE_L1a.md` §7 and §9 are STALE about `a_flat_n3`.** They record it DECLINING
(`state prep seed is proven equal to the condition register`, the `vd.c` wall, bd `om35`) and conclude
*"the dependency is UNMET at N=3 … at the end of this session the N=3 unrolled twin still does not
exist"*. **Re-measured on the session oracle `5c6f7490`: `a_flat_n3.c` ACCEPTS**, 98 lowered lines, 40+
trace lines. bd `om35`'s φ-descendant exclusion landed in the 2026-09-14 merge, after that scoping was
written. The N=3 flat twin **does** exist. (What does *not* change: §4.1 above shows it is not a
byte-identity twin for a rolled cascade, for a reason that has nothing to do with `om35`.)

**(b) `PROTOCOL.md`'s ORACLE hash is the previous session's.** It names
`f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`; the binary on disk and the one
`BRIEF_I.md` names is `5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8`. The briefs
are right and the copied protocol header is stale — worth one line in the session record so the next
agent does not "STOP and report" a rebuild that did not happen.

---

## 7. Follow-ups, and what to do with bd `21re` itself

**bd `21re` was NOT touched in the tracker by this track**, deliberately: the bead says *"Blocks: land
this with `xdu2`, not separately"*, the fix lives on `railbank-instruments` and not on `main`, and a
`bd` write goes to a DB shared by five concurrent worktrees. **The orchestrator or the merge-and-gate
agent should close it when this branch lands**, citing `GATES.md`'s `armkill` and corpus rows. Until
then it is OPEN and the fix is un-merged; do not report it as closed on `main`.

### Follow-ups to file

* **bd (new) — stage 2b's rail census counts SITES, not executions.** Two measured witnesses, one of
  them loop-free (§1.6.4). Not a miscompile gate defect; a number measuring the wrong program, which
  is the class `CLAUDE.md` says the three pure-python record gates exist for.
* **bd `21re` follow-on — the D5 allow-list parity.** L3's `cqrt_measure_<W>` exemption and the pass's
  D5 allow-list are two spellings of one decision. They must be reconciled when L-1a's second half
  lands, or stage 2b refuses the increment's own output.
* **bd (new) — the twin-matrix BANK axis** (SCOPE_L1a §6.3), which is the only instrument in the tree
  that can see a leaked TEMPLATE-minted rail and currently has no bank cell at all.
