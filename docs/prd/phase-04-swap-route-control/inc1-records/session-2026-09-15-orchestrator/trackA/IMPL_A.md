# Track A — IMPLEMENTATION record: the two P1 blockers (bd `de8n`, bd `n74d`) + F-2 + F-4

Worktree `/Users/sorenwilkening/Desktop/CQ_A`, branch `railbank-blockers`, off `main` `74eabd2c`.
Every number below was MEASURED with the command shown (Rule 19). Gate lines: `GATES.md`.

**ORACLE** (frozen, read-only), verified before the first probe and after the last, UNCHANGED:
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
`0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`, `libCQPass.so`
`94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b`.

⚠ **A clean build of this worktree at `74eabd2c` produced a `cq-opt` BIT-IDENTICAL to the ORACLE**
(`0e280fc6…`), so the RED half of every red-green below is the same binary the whole session is
measured against.

**SUBJECT:** `cq-opt` `b65549356168354626a7f09c748e35e43f9fba186ae7ede8dab6a31fd3aae2bf`,
`libCQPass.so` `1c7df31bf95268089ffb10775240339764f91bf4d5a53c6186c1178e06e6093a`.

---

## 0. What shipped

| # | item | files |
|---|---|---|
| 1 | bd `de8n` — carve clause **C7**, splitting the accept-shaped verdict into `Bank` / `BankRaw` | `QramLowering.{h,cpp}`, `TaintPropagation.cpp`, `RailBankPromote.{h,cpp}` |
| 2 | bd `n74d` — promoter clause **B4′** now tests the LOADS of a `Read` gep, not the gep's block | `RailBankPromote.{h,cpp}` |
| 3 | F-2 — promoter clause **B9** (one write per activation) + the several-stores `SSAUpdater` merge DELETED | `RailBankPromote.{h,cpp}` |
| 4 | F-4 — the three-part tripwire claim corrected at its own recipe site (two thirds were INERT) | `RailBankPromote.cpp` |
| 5 | R4 — `SCOPE_L1a.md` §5/§7's stale premise, re-derived by measurement and **applied in the source** | `trackL/SCOPE_L1a.md` |
| 6 | two false claims corrected in place (L7-with-a-twist) — C6's *"written exactly once"*, and `QramLowering.h`'s *"Both classify `Bank`"* | `QramLowering.{h,cpp}` |

Five new fixtures; `ir-pass/test/*.ll` 2039 → 2044. **+338 / −48** over six files
(`git diff --stat`), of which the pass source is `QramLowering.h` +61, `QramLowering.cpp` +86,
`RailBankPromote.h` +54, `RailBankPromote.cpp` +125/−48, `TaintPropagation.cpp` +28.

---

## 1. bd `de8n` — `Bank` did not imply what its own retirement trigger promised

### 1.1 The defect, reproduced on the ORACLE before any edit

`declineTaintEscapes` consults only `railBankCarveVerdict`, and the L8 trigger at
`TaintPropagation.cpp` says the `Bank` arm *"stops breaking and becomes a `continue`"* when the
deferred half lands — i.e. **`Bank` IS the accept predicate of record**. `planBank` adds nine
structural clauses after its B6 carve call and nothing recorded that an unpromoted `Bank` is unsound.

Measured on the ORACLE, `probes/rb.sh` (ORACLE + SUBJECT + both env anchors on one stage-1 file):

```
r2_nopreheader.ll    O:1 kMsgStore  carve=[Bank] cells=3  promo=0     <-- Bank AND NOT promoted
r3_withpreheader.ll  O:1 kMsgStore  carve=[Bank] cells=3  promo=1
d1_rezero_inloop.c   O:1 kMsgStore  carve=[Bank] cells=3  promo=0
d2_lifetime_inloop.c O:1 kMsgStore  carve=[Bank] cells=3  promo=0
d3_rezero_arm.c      O:1 kMsgStore  carve=[Bank] cells=3  promo=0
```

Reproduces review R1A's F-α1 exactly. On such a bank the per-trip cell is still read inside the loop
and that read is PARTIALLY AVAILABLE (`SCOPE_L1a.md` §0 H3), so the deferred `[N x cell]` →
`[N x i32]` rewrite makes it read the initializer `0` AS A HANDLE — and `h0` is a LIVE RAIL
(`cqrt_alloc_i1(0) -> h0`).

### 1.2 A SECOND hazard the bead does not name, found by asking what `Bank` actually promises

F-α1 attaches the observation that C6's argument text (*"cells 0…N-1 are each written exactly
once"*) is true of the promoted shape and false of the raw one. I took that as a **separate**
property rather than as a restatement of the first, and it is: a bank can have **no in-loop read at
all** and still fail totality, because the store sits in a conditional arm.

`probes/p1_cond_store_no_read.c` — `for (i<3) { if (n > 0) b[i] = cq_theta(z, 0.5); }` then a measure
loop over every cell. `clang -O1` keeps the arm (it does not unswitch). Measured:

```
p1_cond_store_no_read   ORACLE carve=[Bank] promo=0   SUBJECT carve=[BankRaw] promo=0
p2_uncond_store_no_read ORACLE carve=[Bank] promo=0   SUBJECT carve=[Bank]    promo=0   (control)
```

`p1` has no in-loop read, so **the promoter's B8 leaves it byte-untouched** — nothing else in the
tree refuses it. A hazard nothing else refuses is the Prime Directive's own case.

### 1.3 A THIRD, found by the injection matrix rather than by reading

Mutant M3 ("drop C7(b)'s `getExitingBlock() == Latch` conjunct") was **MISSED by all 44 railbank
fixtures**. Closing it produced the sharpest witness of the three — `probes/p5_toptest_exit_not_latch.ll`,
a TOP-TESTED loop over `[4 x i8]`:

* header executions (SCEV's `Trips` = BTC+1) = **4**, body executions = **3**, `N` = **4**;
* so C6's `Trips != N` test **passes** and **cell 3 is never written** — and the module measures it.

`Trips` counts HEADER executions; header and body executions coincide only when the single exiting
block IS the latch. Measured: ORACLE `carve=[Bank] cells=4 promo=0` → SUBJECT `carve=[BankRaw]`.
**The lesson is L2's, taken twice by this clause family:** C2′ already asks `getExitingBlock()` to be
non-null and stops there — that proves there is only ONE way out and says nothing about WHERE it is.

### 1.4 The fix — C7, stated as the properties the type rewrite needs

Not as a structural echo of the promoter's B-clauses (which live in another file and were cleared for
another purpose — `MERGE_FILINGS.md` F-1's lesson), and **not** as a call to the promoter (which would
be circular: `planBank` B6 calls the carve).

```cpp
  BasicBlock *Latch = L->getLoopLatch();
  const bool WriteIsTotalPerTrip =
      Latch && L->getExitingBlock() == Latch &&
      DT.dominates(SI->getParent(), Latch);
  if (AnyReadInsideL || !WriteIsTotalPerTrip)
    return RailBankCarve::BankRaw;
  return RailBankCarve::Bank;
```

The dominance proof (why `B` dom latch ⇒ `B` runs every trip, for a NATURAL loop) is written out at
the site and in `SIGNATURE.md` §2.

**Why not `ICFLoopSafetyInfo::isGuaranteedToExecute`** (the Rule-14 "ask LLVM's own machinery"
move): `SimpleLoopSafetyInfo`'s spelling proves *"executed on **some** iteration"*, not *"on every
iteration"*, and `allLoopPathsLeadToBlock`'s own comment hedges to *"at least on the first
iteration"*. I could not verify from LLVM 19's own text that either answers the question C7(b) asks,
and a fence resting on a helper whose doc comment hedges is L5 in its usual shape. The two-conjunct
form is a three-line theorem I can state. **RETIREMENT TRIGGER:** if a later increment wants the
precision (a store guarded by a `mayThrow` call, say), take `ICFLoopSafetyInfo` and re-derive this
proof against it — do not assume the two agree.

### 1.5 The consumers, updated in the same change (L7-with-a-twist)

* `TaintPropagation.cpp` gains a `BankRaw` arm that prints `railbank [BankRaw] …` and `break`s to
  `kMsgStore`, with the L8 trigger rewritten to say **`Bank` may one day `continue`; `BankRaw` must
  keep breaking, forever**.
* `RailBankPromote.cpp` B6 now requires **`BankRaw`** — the contract *input `BankRaw`, output `Bank`*.
* C6's *"cells 0…N-1 are each written exactly once"* → *"the index VISITS cells 0…N-1 exactly once"*,
  with the correction and its reason at the site.
* `QramLowering.h`'s *"The promoter sees the RAW shape … the carve sees the PROMOTED one. **Both
  classify `Bank`**"* → they now classify DIFFERENTLY, deliberately. ⚠ Measured while correcting it:
  `lowering_railbank_bank_anchor_n3.ll` carries the RAW text but its `[Bank]` line names
  `store i8 %cq.bank, ptr %cq.bank.addr` — **the promoter's output**, because the promoter runs
  first. That fixture's `Bank` verdict has ALWAYS been about the promoted module.

---

## 2. bd `n74d` — the store-move clause tested the GEP's block, not the LOAD's

### 2.1 The `-O1` spelling, read off the compiler and not assumed

`clang -Iinclude -include CQ.h -O1 -emit-llvm -S probes/c1_readcell1_inloop.c`:

```llvm
  %2 = getelementptr inbounds i8, ptr %1, i64 1     ; ENTRY block   -> NonRewritable
  br label %6
6:                                                  ; the loop
  store i8 %13, ptr %9, align 1
  %14 = load i8, ptr %2, align 1                    ; IN L, and never examined
```

LICM hoists the loop-invariant cell address to the preheader and leaves the load in the loop. The
clause iterated `NonRewritable`, which receives the **GEP** for a `Read`-classified access, so the
observation point was invisible to it. The predecessor fixture
`railbank_promote_reject_inloop_other_read.ll` pins the DIRECT spelling (`%r0 = load i8, ptr %b`) —
the one shape the clause did catch — so the `-O1` spelling had **never been tested**.

### 2.2 The fix

`planBank` now pushes a `Read` gep's LOAD USERS into `NonRewritable` beside the gep. A gep observes
nothing; its loads do. Promoted to a numbered clause **B4′** in `RailBankPromote.h`, with the
retirement trigger for a non-load `Read` user (T4).

### 2.3 THE M12-STYLE MUTANT — the red-green of record, because no fixture can be one

On the shipped binary the carve's C6 refuses this module first
(`cq rail bank: array has cells no iteration writes`), so `planBank` never reaches B4′ and the
promoter would not fire even with the defect present. bd `n74d` says so and asks a fix agent to take
the mutant. Taken, `probes/n74d_mutant.sh`, on
`ir-pass/test/railbank_promote_reject_inloop_hoisted_read.ll`:

| binary | mutations | `promo` | emitted loop body |
|---|---|---|---|
| `4516c7617f409ca4` | C6 in-loop-read conjunct deleted **+ the B4′ fix REVERTED** | **2** | `%11 = load i8, ptr %2` … **then** `store i8 %10, ptr %cq.bank.addr` |
| `95fda6f10d3fa874` | C6 in-loop-read conjunct deleted **only** | **0** | module byte-untouched; `store i8 %13, ptr %9` … **then** `%14 = load i8, ptr %2` |

The source order is store-then-load. **The unfixed promoter inverts it** — the classical store-move
miscompile, verify-clean, on a value that is not even quantum. The fixed one refuses.

### 2.4 The fixture, and what it does and does not pin

`railbank_promote_reject_inloop_hoisted_read.ll` (new) carries the `clang -O1` module verbatim and
pins the `-O1` SHAPE plus the promoter's non-firing (`DBG` proves the stage ran; `NOTS` proves it did
not promote). Its header says **in capitals** that it does NOT isolate B4′ today, names the mutant as
the red-green of record, and carries the retirement trigger: the day C6's in-loop-read test is
widened (`if (b[i-1]) …`), B4′ becomes the sole defence and this file becomes an isolating negative.
The old `…_other_read.ll` is kept unchanged — it pins the direct spelling, which is a different
shape.

---

## 3. F-2 — the multi-store `SSAUpdater` path: DELETED, with the widening's obligation written down

**Decision: delete, and give the promoter its own clause.** Reasoning:

* The path was **unreachable**, not merely untested: carve C4's second half refuses a bank with more
  than one store site, and B6 runs before every other B-clause. So nothing could enter it.
* Leaving it is the thing F-2 asks not to leave — an untested `SSAUpdater` merge that becomes live
  the day C4 is widened, with no test behind it.
* But deleting it while the only proof lives in **another file** would repeat `MERGE_FILINGS.md`
  F-1's defect. So the promoter acquires **B9 — `Plan.Stores.size() != 1` → refuse**, its own
  clause, and `applyBank` is then simple by construction.

What was deleted: PASS A's walk over `L->blocks()` with `lastCellStoreIn` (now two
`AddAvailableValue` calls — the store's block, and the header with the seed when the store is not
there), and the `CanonStore` dominance-selection loop (now `Plan.Stores.front()`). `SSAUpdater`
itself STAYS — it is what builds the merge φ for the single CONDITIONAL store, which is the
customer.

**What would make it live, and what test is then owed** (T6, written at both the clause and the
header): the day C4 or B9 admits a two-writer bank, PASS A needs the several-stores merge back —
register the last cell store of every block, take the canonical store by dominance among them — and
it lands WITH a red-green pair whose accept has two stores in one activation and whose adversarial
probe puts them in sibling arms. The deleted spelling is in this commit's `git` history.

**Measured cost: none.** The promoter's output module is byte-identical on all 10 firing fixtures
(§5.2).

---

## 4. F-4 — a tripwire counted three times, of which two thirds are inert

`RailBankCarve.h` no longer exists (it was Track B's stand-in, deleted at the 2026-09-14c merge), so
the claim's surviving site in code is the `#include "QramLowering.h"` comment in
`RailBankPromote.cpp`. Corrected there, at the recipe's own site, in the form a future stand-in needs:

> the recipe was defended as a THREE-part argument — a duplicate-symbol LINK error, a REDEFINITION
> compile error *"in any TU that sees both headers"*, and a hard error on the duplicated default
> argument — and **the last two are INERT**: measured at the gate, neither fired, because **no TU
> includes both headers**, which is precisely the arrangement a stand-in header is built to have.
> **If you build a shim, the tripwire must be a DEFINITION collision at LINK time; a declaration
> collision proves nothing about headers nobody includes together.**

Verified by measurement that no other source or header in `ir-pass/` carries the claim
(`grep -rn REDEFINITION ir-pass` → 0 hits).

---

## 5. THE MEASUREMENTS

### 5.1 Corpus sweep — ORACLE vs SUBJECT, **5582 modules, 0 movers**

`probes/corpus_row.sh` + `probes/corpus_b6554935.txt`. Corpus: `ir-pass/test/*.ll` (2044) + every
`inc1-records` session dir's `track*/probes`, `review_*_probes`, `merge_gate_probes` and
`*_reproducers` (3538). Row: `<path>|<O verdict>|<S verdict>|<O stderr sha16>|<S stderr sha16>`,
where a verdict is `A:<md5 of lowered IR>` or `D:<first cq diagnostic>`.

```
rows=5582   accepts(ORACLE)=3058   declines=2522   clangerr=2 (both binaries, pre-existing)
verdict-movers=0   stderr-byte-movers=0
```

⚠ **The stderr sha closes PROTOCOL S3's named hole** — the shared recipe's tag regex renders the
whole `cq_measure_<sfx>` family as an empty `D:`, so a decline→decline string change inside it is
invisible to the tag. Compared here byte-for-byte instead. **0 movers on both columns** is the
expected result and the one the design predicts: `BankRaw` sets no `outMsg` and breaks to the same
`kMsgStore`, so the ONLY observable in the whole change is the env-gated `CQ_CTRL_DBG` anchor.

### 5.2 Promoter-output differential — **2043 fixtures, 10 fires, 0 movers**

`probes/promo_row.sh`, self-tested in both directions on both binaries (a must-fire control and a
must-not-fire control) before reporting:

```
rows=2043   promoter-fires ORACLE=10  SUBJECT=10   movers=0
```

and on all 10 the sha256 of the promoter's **output module dump** is EQUAL between the binaries. So
B6's `BankRaw` requirement, B9, the `applyBank` simplification and the B4′ fix change the promoter's
behaviour on **nothing** in the fixture corpus. The 10 are this increment's own
(`railbank_promote_*` ×7, `lowering_railbank_bank_anchor_*` ×3), matching review R1A's count.

### 5.3 The injection (mutation) matrix — **12 mutants, 3 MISSED, every one with a reason**

`probes/inject.sh` / `probes/inject_one.sh`. Each mutant: apply (pattern must occur EXACTLY once, or
the row is `MUTATION-HOLE`), rebuild BOTH targets, run `lit ir-pass/test --filter railbank` — the
same command the suite runs, never a hand-rolled FileCheck with the RUN line's flags dropped — record
CAUGHT/MISSED, revert. A BUILDFAIL is reported as itself and never as a CAUGHT.

| mutant | result |
|---|---|
| M1  C7(a) deleted | CAUGHT(3) `…uncond_prep` `…unrolled_reads` `…bankraw_inloop_read` |
| M2  C7(b) deleted | CAUGHT(1) `…bankraw_cond_store` |
| M3  C7(b): drop `getExitingBlock() == Latch` | **MISSED** → **CAUGHT(1)** `…bankraw_toptest_exit` after the fixture the matrix demanded |
| M4  C7(b): drop `dominates(store block, latch)` | CAUGHT(1) `…bankraw_cond_store` |
| M5  C7 deleted entirely (the pre-fix binary) | CAUGHT(9) |
| M6  C7(a) flag never set | CAUGHT(3) |
| M7  B6 requires `Bank` instead of `BankRaw` | CAUGHT(10) |
| M8  B6 accepts BOTH | **MISSED** |
| M9  B9 weakened to ≥1 store | **MISSED** |
| M10 B4′ reverted (bd `n74d`) | **MISSED** |
| M11 CONTROL: carve C6's in-loop-read conjunct deleted | CAUGHT(2) `…reject_two_cells` `…reject_inloop_hoisted_read` |
| M12 C7(a) INVERTED | CAUGHT(8), incl. `…bank_anchor_unpromoted` |

**MISSED = 3 of 12, and each is a stated property of the change rather than a hole in the fixtures:**

* **M8** — B6 accepting `Bank` as well as `BankRaw` is behaviourally equivalent, because a `Bank` bank
  has no in-`L` load (C7(a)) and B8 refuses it one clause later. The MISSED **is the measurement**
  that the tightening cost nothing; it is recorded, not fixed.
* **M9** — B9 is unreachable behind carve C4 by design (F-2 §3). Its value is that `applyBank` no
  longer carries a merge for a case nothing proves locally. A fixture would have to defeat C4 first.
* **M10** — B4′ is defence-in-depth behind carve C6, exactly as bd `n74d` says. Its red-green is the
  §2.3 mutant, which is the form the bead asks for.

**M3's MISSED is the matrix earning its keep**: it produced a fixture, and that fixture's subject is
a genuinely unwritten cell that C6's own counting passes.

### 5.4 Lit

`ctest --test-dir build -R ir-pass-lit --output-on-failure` → **1/1 Passed, 64.43 s**, over **2044**
fixtures (2039 + 5 new). `lit ir-pass/test --filter railbank` → **46 Passed** (41 shipped + 5 new).

### 5.5 Non-vacuity of the five new fixtures

`vacuity.py` (PROTOCOL S3) **could not be run**: it hardcodes `/Users/sorenwilkening/Desktop/CQ_mphi`
as its build tree and dies `FileNotFoundError` in any other worktree. That is a **second** defect on
that instrument beside bd `jdec` (which records it printing `checked 0`), and it is reported to the
orchestrator rather than worked around silently.

The stronger check was taken instead — each fixture's exact RUN-line FileCheck command, with its
`--implicit-check-not` flags, against the **ORACLE** binary:

```
lowering_railbank_bankraw_cond_store       FileCheck-on-ORACLE exit=1   (RED: oracle prints [Bank])
lowering_railbank_bankraw_inloop_read      FileCheck-on-ORACLE exit=1
lowering_railbank_bankraw_toptest_exit     FileCheck-on-ORACLE exit=1
lowering_railbank_bank_anchor_unpromoted   FileCheck-on-ORACLE exit=0   (green by design; mutant M12 validates it)
railbank_promote_reject_inloop_hoisted_read  both binaries decline       (mutant M11 validates it)
```

---

## 6. R4 — `SCOPE_L1a.md` §5/§7, re-derived rather than quoted, and APPLIED IN THE SOURCE

Measured on the ORACLE at `74eabd2c`:

```
a_flat_n2.c                   exit 0, 115 lowered lines
a_flat_n3.c                   exit 0, 147 lowered lines          <-- ACCEPTS
L13_flat_n2_opaque_noinline.c exit 1, cq controlled lowering: control flow under quantum control
```

* §7's *"The dependency is UNMET at N=3"* and *"at the end of this session the N=3 unrolled twin
  still does not exist"* are **HISTORY** — bd `om35` landed (`30317792`) after the document was
  written. The N=3 twin exists.
* **§5's conclusion still holds, for a DIFFERENT reason, which is exactly how a stale premise
  survives a correction.** The byte-identity gate is still not available for the owner's literal
  program because (i) with `a = 5` constant, `-O1` folds trip 0's condition in the UNROLLED spelling
  and cannot in the rolled one (H2), and (ii) the opaque-`a` alternative still declines (L13,
  re-measured above). Neither reason is `om35`'s.

Both corrections are written **into `SCOPE_L1a.md` itself** — a dated erratum under the §7 bullet and
an annotation in the §5 row — because the 2026-09-14c record correction was recorded in `DECISIONS.md`
and never applied to the document. `CLAUDE.md` L7-with-a-twist, verbatim: *a record correction that is
not applied to the source is not a correction.*

---

## 7. THE OWNER'S PROGRAM — my change alone does NOT move it, and that is the intended answer

`example/grover/grover_oracle_uncompute.c`, copied to scratch (local-only per owner ruling E4; **not**
committed), ORACLE vs SUBJECT on the same stage-1 file:

```
owner   O:1 cq taint escape: tainted value stored to memory  carve=[Bank] cells=3 promo=1
        S:1 cq taint escape: tainted value stored to memory  carve=[Bank] cells=3 promo=1
```

Identical. Expected: this track fixes two soundness blockers so W1's second half can land; the
deferred pieces are Track B's, and owner ruling **E5** records four measured walls in front of the
headline, of which only two are W1's.

⚠ **The load-bearing half of that measurement is the `carve=[Bank]`.** The owner's program is on the
**accepting** side of the new split — the promoter normalises it (`promo=1`) and the carve then calls
the result `Bank` — so C7 does not block the headline. Had it come back `BankRaw`, this fix would
have been an over-decline of the very program the increment exists for (Rule 17), and the right
action would have been to stop and report.

---

## 8. INSTRUMENT LESSONS FROM THIS TRACK — three, all measured, all mine

**(a) A SWEEP THAT OUTLIVES THE BINARY IT STARTED ON MEASURES NOTHING, AND IT REPORTS A PASS-SHAPED
RESULT.** My first promoter sweep ran ~40 minutes across a fixture batch and two mutant builds. It
finished and reported **2 MOVERS** (`railbank_promote_reject_two_cells.ll`,
`spec_accept_intrinsic_involution.ll`). Both re-measured **identical** on the stable binary:

```
railbank_promote_reject_two_cells.ll|0|0
spec_accept_intrinsic_involution.ll|A:8f3ec6e8|A:8f3ec6e8|e3b0c442…|e3b0c442…
```

They were artifacts of sampling two different binaries within one sweep. `CLAUDE.md`'s *"never relink
a binary under a running measurement"* is usually quoted about a gate that FAILS; here it produced two
FINDINGS out of nothing. The rule the sweep now follows: **a sweep runs in foreground chunks that
cannot outlive the binary**, and the reported rows are from `promo_a`/`promo_b`, both taken between
the subject build and the first mutation.

**(b) TWO MEASUREMENT JOBS IN ONE BUILD DIR CORRUPTED THE SOURCE, NOT ONLY A RESULT.** A background
injection matrix was still alive when I started a second mutant run. The second run saved "the
original" **while the first had a mutation applied**, and its `trap … EXIT` restore then wrote that
mutation back into `QramLowering.cpp`. Caught by a pattern-count integrity check
(`grep -c -F` over five conjunct strings, one of which came back `0`), not by the build and not by
lit — the mutated tree COMPILES and 46 fixtures still pass. The contaminated M3 row named M11's
fixtures, which is how it was noticed. **Never run two mutation harnesses against one worktree**, and
verify the source by pattern count before trusting any post-mutation measurement.

**(c) A HARDCODED PATH TURNS AN INSTRUMENT INTO A NO-OP IN EVERY OTHER WORKTREE.**
`trackM/probes/impl/vacuity.py` dies `FileNotFoundError: /Users/sorenwilkening/Desktop/CQ_mphi/build/ir-pass/cq-opt`.
bd `jdec` records that it reports `checked 0` instead of failing; this is a second, independent way it
reports nothing. Both belong on that bead.

---

## 9. WHAT I DID NOT DO

* **No full `ctest`, no `^e2e-`, no equivalence sweep** — the merge-and-gate agent owns those
  (PROTOCOL's matrix). A decline-string set did not change (0 stderr-byte movers over 5582 rows), so
  `cq-opt-equivalence-full` is arguably not owed; that call is the merge agent's, and the measurement
  it needs is §5.1.
* **No e2e slice.** `BankRaw` emits nothing and every module on this path still declines, so there is
  no golden to add. The e2e layer has no decline shape.
* **F-α4, F-α5 and F-α3 are NOT fixed** — they were not mine. ⚠ But note the composition: F-α5's two
  exploit routes (`d1`/`d3` in-loop re-zero, `d2` in-loop lifetime markers) are `[Bank] promo=0` on
  the ORACLE and **`[BankRaw]` on the subject**, so C7 closes their reachability into the deferred
  half. The underlying carve holes (C1's `DT.dominates(Init, SI)` answering a syntactic question, and
  the location-free `continue` on a lifetime marker) are **untouched** and stay filed.
* **`isRailBankAlloca` / `railStoredToRailBank` / the `!cq.railbank` mint** are still not shipped
  (2026-09-14c deviation (2), unchanged).
