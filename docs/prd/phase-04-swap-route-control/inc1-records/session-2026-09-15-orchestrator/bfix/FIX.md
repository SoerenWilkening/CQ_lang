# BFIX — closing the rail bank's P1 over-accept, and the six items

Fix agent, session 2026-09-15. Branch `railbank-fix`, worktree
`/Users/sorenwilkening/Desktop/CQ_BFIX`, based on Track B `railbank-accept`
`3b982459`. Subject of the review: `review_r13_railbank/REVIEW.md`.

Every number below is a run, with the command in `GATES.md` and the binary hash
beside it. Nothing here is estimated (Rule 19).

> ⚠ **The "before" binary is not a lookalike.** This worktree built from
> `3b982459` with no edits produced `cq-opt` `784c14fa05c16c50…` and
> `libCQPass.so` `a4e4f6781524c569…` — **bit-identical** to the binary the
> reviewer measured. Every BEFORE line is therefore a fact about the reviewed
> compiler.

---

## 1. The P1 — measured before and after

`bfix/probes/f01_bank_stale_reader.c`: a loop-invariant rail's NAME parked in
every cell of a bank, the rail then relabelled by a non-diagonal `cq_theta`, the
cells measured afterwards.

| | `cq-opt` | verdict |
|---|---|---|
| **BEFORE** (SUBJ_B `784c14fa`) | exit **0**, stderr **empty** | 7 trace lines, STRICT 2b `2 rail mint(s) of which 2 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven` |
| **AFTER** (BFIX `fd310f80`) | exit **1** | `cq opcode lowering: rotation/measure operand predates a non-diagonal gate` at `f01…:10:36`, the bank measure's own `!dbg` |

The circuit the BEFORE emitted, verbatim:

```
cqrt_alloc_i32(1) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cqrt_ry_i32(h0, 0x1.6666666666666p-1)   <-- the 0.7 rotation, BEFORE every measure
cqrt_measure_i32(h0) -> 0   x4
```

— three bank measures observing `h0` **after** a rotation the source places
after them. The register spelling of the same program (`f02`) declines on the
ORACLE, on the BASE and on SUBJ_B itself, with the identical string. The
non-`main` spelling (`i02`) moved the same way.

**Also closed, and NOT named by the review**: `p05_stale_before_park` — the rail
relabelled *before* it is parked, so the name written into every cell is already
stale at the store. Found by the new gate, not by a probe (see §6).

---

## 2. Which fix, and what the alternative does not cover

**The REAL fix was taken, not the stopgap.**

### The real fix — a SEED, not a policy

`recordStaleQuantumReaders` (bd `3d8q`) asks *"does this `cq_measure` operand —
or `cq_theta` arg-0 — read a rail name that a non-diagonal gate has since
relabelled?"* through `WireWalk`'s SSA walks. **Those walks have no memory hop**,
so a bank cell load is a value with no wire and the reader was never adjudicated.

Three edits, and the third is the whole of it:

1. `RailBankPromote.{h,cpp}` — **`bankStoreRailValue(SI, CellT)`**: the rail NAME
   a bank store parks, i.e. the store's value operand with the storage cast
   stripped. **One spelling, two callers**: `markRailBankAllocas` takes its
   WIDTH (the `!cq.railbank` payload) and the fence takes the VALUE. The width
   capture was refactored to call it, so a width that disagreed with the seed is
   now unspellable (Rule 14; the review's own I-4 is this file's cautionary
   instance of the alternative).
2. `RailBankPromote.{h,cpp}` — **`railBankParkedRails(V, Out)`**: the memory hop.
   `V` is a cell load or the storage `trunc` in front of one (D5 entry (2));
   `Out` gets the cast-stripped value of **every** store into that bank.
3. `OpcodeLowering.cpp` — `recordStaleQuantumReaders` seeds the **same walker**
   with `Seeds` instead of `Rec`. Same `EmitPoint` (the reader), same
   `RequireEmitDominance=false` policy bit, same `Covered` machinery.

**The invariant that makes it right, and that makes the fix small**: a bank cell
read is adjudicated **exactly as if the source had named the parked rail
directly** — which is precisely what the source says it is. So the verdict a
bank program gets is, by construction, the verdict its register spelling gets;
that is both the correctness argument and the property the new gate measures.

Consequences, all measured:

* a gate between the STORE and the READ is not provably after the read ⇒
  returned ⇒ DECLINE (`f01`, `i02`, pairs `p01`/`p05`/`p08`);
* a gate AFTER the read is harmless by `gateIsHarmless`' leg 1 ⇒ ACCEPT, with a
  stream byte-identical to the register twin's (`f06` vs `f07`, `cmp` empty);
* the CAPABILITY — a distinct theta per cell, minted inside the walk loop —
  seeds at a **source** theta whose backward closure stops at its classical init
  and whose only forward user is the store, so **no gate is found and nothing
  changes** (o01/o02/o04/o05, pairs p03/p04/p07, all 6 shipped `railbank_accept_*`
  fixtures, all 8 e2e railbank entries).

Two supporting conjuncts, each stated at its site:

* **a `Constant` is never a seed.** Constants are uniqued module-wide, so
  seeding `i8 0` (the whole-object zero initializer C1 admits, or a `false` arm
  incoming PASS G builds) would walk every unrelated use of that literal and
  could return a theta on a wire the bank never touched — an **over-decline
  manufactured by the seed**. A constant also parks no rail.
* **the Delta is tested against the SEEDS, not only `Rec`.** A bank load is
  tainted from round 1 by piece 1, so keying the round-2 re-ask on `Rec` alone
  would skip a bank whose *parked rail* is what just became tainted — L1's
  PREDICATE species, one indirection out. Justified by DIRECTION (I-6's
  discipline), not by a claim of unreachability.

### The stopgap — NOT taken, and exactly what it does not cover

The review offered: *refuse a `Bank` whose stored value is not defined inside
`L`*, measured to flip **zero** registered accepts and to close f01, f06, d03 and
d5e together.

**What it does not cover — and the phrase "and d5e together" is the problem, not
the selling point.** It closes f01 by refusing the SHAPE, so it also refuses:

* **`f06`** — the same program with the measure loop one line higher. That
  program ACCEPTS on the fix, and its emitted stream is byte-identical to its
  array-free register twin `f07`, which the ORACLE accepts. Refusing it is an
  over-decline of a valid circuit — a defect under the owner's 2026-09-11 ruling,
  not a margin.
* **`d03`** and **`d5e`** — the same, and `d5e` is a **shipped D→A accept** of
  the increment under review.
* every future *"record this qubit N times, then read it"* program, which is the
  natural spelling of a legitimate thing.

It is also silent about the direction that matters: it says nothing about WHEN,
so a bank parking an in-`L` rail that a later gate relabels would still pass it.
The pipeline has no such shape today (D5 admits only a measurement as a cell
reader), but the stopgap's argument does not exclude one — it excludes a
*syntax*, and CLAUDE.md L5 is about exactly that trade.

**Shipped accepts flipped by the real fix: ZERO.** The reviewer's target was
zero. Measured **five** ways, the last of which is the strongest:

1. lit **2057 passed / 1 XFAIL of 2058** (Track B: 2054/1 of 2055; the delta is
   the 3 fixtures added here) and **8/8** `^e2e-(slice-)?railbank` entries;
2. **36 of 38** reviewer+owner probes identical in verdict AND diagnostic string;
3. **17** probes accepting on both binaries, **0 trace divergences** (`cmp`);
4. **all 40** pre-existing `railbank_*.ll` + `lowering_railbank_*.ll` fixtures:
   **0 movers** — identical exit code and **byte-identical lowered IR** (accepts)
   or **byte-identical stderr** (declines) between `784c14fa` and `fd310f80`;
5. the legitimate orderings, on the FIXED compiler, emit streams **byte-identical
   to what the ORACLE emits for their array-free twins** — `f06`(BFIX) == `f07`
   (ORACLE), equal sha256 `b60ae0ac5df0b30b6192…`, and `d03`(BFIX) ==
   `d04`(ORACLE). That is the property a shape-based fix cannot have.

### A vacuous negative in my OWN fixtures, self-caught

Recorded rather than quietly fixed, because this session measured nine instrument
self-failures and the discipline is that the person who owns the instrument finds
them. Both new green fixtures first shipped `NOTS-NOT: 3 x i8`, copied from the
`_Bool`-bank fixtures where it pins the type rewrite. **These are `int`-cell
banks**: `3 x i8` occurs **0×** in the IR body and **0×** in the lowered output,
so the check could never have fired — Rule 12 hygiene defect (c) exactly.
Replaced with `cq_theta_` / `cq_measure_`, which occur on **10** and **7** body
lines of the INPUT and on **zero** lines of the output, and so pin the pass's
postcondition (`declineSurvivingIntrinsicCalls`) on the very module where a
failure to lower the bank read is how that postcondition would break. Both
fixtures re-run: 2/2 PASS.

---

## 3. The owner constraint — the capability, measured before and after

Relayed mid-task: the P1 probe's shape (one loop-invariant rail's name in N
cells) is **not** what the rail bank exists for; the capability is a **DISTINCT
THETA PER CELL**, minted inside the loop, per trip — the inner loop of
`example/grover/grover_oracle_uncompute.c`.

| probe | shape | BEFORE (`784c14fa`) | AFTER (`fd310f80`) |
|---|---|---|---|
| `o01_percell_theta_int` | per-cell theta, `int` cells | ACCEPT, 9 lines, 2b `0 violation(s)` | **ACCEPT, 9 lines, identical trace** |
| `o02_percell_theta_bool` | per-cell theta, `_Bool` cells (the owner's own spelling) | ACCEPT, 9 lines | **ACCEPT, 9 lines, identical trace** |
| `o05_percell_theta_constidx` | per-cell theta, constant-index measures | ACCEPT, 9 lines | **ACCEPT, 9 lines, identical trace** |
| `o04_percell_theta_other_reg_rotated` | per-cell theta **plus a genuine non-diagonal gate between the loops on another register** | ACCEPT, 13 lines | **ACCEPT, 13 lines, identical trace** |
| `o03_owner_inner_loop` | the owner's inner loop VERBATIM | DECLINE `control flow inside a loop body under quantum control` @:15:15 | **DECLINE, same string, same anchor** |

`o03` declines at DECISIONS.md **E5 wall 3**, which is `iterationLocalRollable`'s
conjunct (c3), is **BANK-INDEPENDENT** (the orchestrator verified it on a scalar
`bool` with no array at all) and is deferred with a named path. **This fix does
not touch it** — verified by string and anchor, not by verdict alone.

`o04` is the load-bearing row and is now a committed fixture
(`railbank_accept_percell_theta_sibling_register_rotated.ll`): a fence seeded
with the wrong thing — the function's rails, the bank OBJECT, or "any theta
between the loops" — declines it. The shipped fence seeds at the cell's own
parked rail, which that register's wire never touches.

**The discriminator, confirmed by measurement rather than taken on trust.** The
reviewer's *"whether the stored value is minted INSIDE the walk loop"* is the
right separator, and the MECHANISM is why: a per-trip mint is a **SOURCE** theta
after `applyBank` (PASS A registers `Constant::getNullValue` as the cell's
available value, so the in-loop `cq_theta`'s arg-0 is a classical constant). The
walker's backward closure stops at a source theta's classical init, and the only
forward user of the result is the store. **There is nothing on that wire to
find.** A loop-invariant park, by contrast, seeds at a rail whose wire lives on
past the loop and can gain gates. The separation is a property of the WIRE, not
of a syntactic test on the store — which is why it also holds for `o04`, where a
non-diagonal gate *is* present between the loops.

### Which ground the refusal was put on — **ORDERING, not aliasing**

The relayed note is right that the aliasing probe is independently suspect on
Rule 8 / no-cloning grounds, and the two grounds have different homes. **The
refusal is on the bd `3d8q` ORDERING question**, in `recordStaleQuantumReaders`,
seeded through `railBankParkedRails`. Reasons, in order of weight:

1. **Aliasing alone is not wrong here, and that is measurable, not arguable.**
   `f06` parks one rail's name in three cells and measures all three — maximally
   "aliased" — and its emitted stream is **byte-identical** to its array-free
   register twin `f07`, a program the ORACLE `0e280fc6` **accepts**. A fence on
   aliasing declines a valid circuit. Likewise `d03`, and likewise `d5e`, a
   shipped accept.
2. **The two programs that differ are one statement apart and differ only in
   ORDER.** `f01` and `f06` have the same cells, the same rail, the same number
   of measurements. What separates them is whether a rail-relabelling gate is
   scheduled between the park and the read. A fence that cannot see order cannot
   separate them.
3. **"Measure one qubit N times" already has an owner, and it is not this
   fence.** That is bd `yiid` (`cq_measure` is not modelled as a wire event), it
   is UNRULED, and it reproduces with **no array anywhere** (`d04`, `d5f`). A
   fence here would be this increment annexing an open boundary question — and
   would decline the register spelling's behaviour asymmetrically, since the
   register spelling would keep accepting.
4. **The aliasing question also has a natural home if it is ever ruled**, and it
   is not here either: C2′ / the carve, where "each cell is written once" already
   lives. Putting an ordering fence there, or an aliasing fence in
   `OpcodeLowering`, is how a fence ends up in the wrong file.

`p06_double_measure` is kept in the gate's corpus **as a known both-accept row**
precisely so that if bd `yiid` is ever ruled the other way, the change shows up
as a row rather than as silence.

---

## 4. The six items

| item | direction | disposition |
|---|---|---|
| **I-1** | correction | **LANDED IN THE SOURCE**, at `ArithLowering.cpp`'s explicit-image list. The *"measured unreachable for a bank rail"* claim is corrected: three of the four families refuse a bank rail (explicitly / structurally / incidentally) and **this one refuses it by nothing**. `railStoredToRailBank` was **deliberately NOT added**, and the ground is the review's own measurement: the conversion fires (`cqrt_addc_i32(h0, 7)`) and is **byte-identical to the register twin the ORACLE accepts** (`h01`/`h04`), while `provablyBefore` refuses it wherever a later reader exists (`h02`/`h05` vs `h03`/`h06`). Adding the conjunct would remove an accept whose circuit is right. A **retirement trigger** is written at the site naming the composition that would make the absence unsafe: the in-place conversion relabels the parked rail, and the memory hop walks for `cq_theta_` and not for a dtzb `add`/`xor` (the `WireWalk.h` vocabulary gap, bd `a3z7`) — so the day a bank rail's in-place reassignment can sit between the store and a later cell read, **both** must be re-derived together. |
| **I-2** | correction | **LANDED**, at PASS G. The *"cannot move an accept"* claim no longer rests on the `phi` test; the load-bearing premise is named (both condition classes decline today) with both measured strings, and a **RETIREMENT TRIGGER** is written: *the day a conditional bank store accepts, re-derive this claim from scratch.* |
| **I-3** | latent P1, gated by I-2 | **FENCED BY DOCUMENTATION AND GATED BY NAME**, at the same site. PASS G's `addIncoming(Constant::getNullValue(RailTy))` parks **handle `0`** in a cell — the live rail PASS 3 deletes the memset to avoid — and the two sites now carry each other's name. The obligation the unblocking landing owes is stated: the ¬arm needs a **real `|0⟩` rail (a fresh `cqrt_alloc`)**, not the literal 0. It is not fenced in code because it has **no reachable subject** and an unpinned decline clause is Rule 12 hygiene defect (c); it is gated on the *same* trigger as I-2, which is the only thing that can make it reachable. |
| **I-4** | documentation | **LANDED**. The false *"THE SAME PREDICATE THE CARVE'S C1 USER SCAN ASKS (Rule 14)"* is replaced by what is true: two spellings (`wholeArrayConstantZero` uses `getTypeStoreSize(ArrTy)`, `isWholeObjectZeroStore` uses pointer identity ∧ `isSimple()` ∧ `getTypeAllocSize`), agreeing on every reachable module, so **"a strictly stronger predicate that agrees with C1 on the reachable population"**. Retirement trigger: non-integer cells can part the two size questions. |
| **I-5** | hygiene | **LANDED**, the honest statement rather than a `Fail` arm with no subject: `llvm.lifetime.*`'s size is `immarg`, so a non-constant size fails `opt -passes=verify` and **the verifier owns the case**. The stage's "NEVER a silent `continue`" contract is about shapes this stage could meet and chose not to handle. |
| **I-6** | documentation | **LANDED**, at the M2 conjunct in `TaintPropagation.cpp`. The unreachability claim is removed and replaced by the direction argument, with the stage list written out **as the reason the claim could not be made** (PredMux exists to turn conditional control flow into straight-line code). The conjunct stays; M2 stays a deliberate MISSED. |

---

## 5. The A×B composition — the C6 seam

**Landed as a comment at `markRailBankAllocas`**, which is the site that answers
it. The structural answer is stronger than 2026-09-14c's F-1 feared: the full
carve runs **again**, on the module **after** the promoter's fixpoint, and mints
only on `Bank` — so **C2′ and C4 are independently re-proven on `applyBank`'s
OUTPUT**, and `applyBank` adding a store makes the input's C4 and the output's C4
two different facts about two different modules, both checked in that order.

**C6 is the seam and it is now written down where it bites.** Its *counting* half
(`Trips == N`) re-proves, and that is the half PASS 3 leans on when it deletes
the initializer. Its **in-loop-read half is VACUOUS on this module**, because
PASS B has already erased every in-`L` load: the forwarding PASS B performed is
licensed by the INPUT carve alone and **the evidence was consumed**. Retirement
trigger at the site: any widening of the promoter's read handling must
re-establish that half **at its own site**, because nothing downstream of
`applyBank` can.

---

## 6. The new instrument — and what it caught

`tools/railbank_register_twin_gate.py`, corpus `tools/railbank_twin_pairs/`
(8 pairs + `PAIRS.md`), selftest `tools/railbank_register_twin_gate_test.py`,
both registered in `tests/e2e/CMakeLists.txt`
(`e2e-railbank-register-twin-decline`, `e2e-railbank-register-twin-selftest`).

**Why this class needed a new instrument, in the review's words**: the corpus
sweep's headline safety property is `0 A→D`, and F-1 is a **D→A** — *a sweep over
a corpus written before a capability cannot sample that capability's new accept
surface.* `ir-pass-lit`, the 8 e2e railbank entries, STRICT stage 2b and every
twin-IDENTITY gate were green on `f01`.

It extends the shipped discipline from *"the bank MATCHES the register spelling
when both accept"* to:

* **P1 — the bank DECLINES whenever the register spelling DECLINES.** A breach is
  a VIOLATION and fails.
* **P2 — when both accept, the traces are BYTE-IDENTICAL.** A breach fails.
* the converse (bank declines, register accepts) is an **over-decline**: counted
  and printed, never failed on.

**What it caught besides the P1.** Run on the reviewed binary it reported **3
VIOLATIONS**, and only two of them are the review's finding:

* `p01_stale_invariant_park` — F-1 itself;
* `p08_nonmain_stale` — F-1 outside `main` (the review's `i02`);
* **`p05_stale_before_park` — NOT NAMED BY THE REVIEW.** The rail is relabelled
  **before** it is parked, so the name written into every cell is already stale
  at the store. A second instance of the class, found by the instrument on its
  first run. It is closed by the same fix.

It also produced a **negative** result worth recording: **0 over-declines** across
the corpus, which is the mechanical form of "the reviewer's target of zero
flipped accepts was met".

**Mutant-validated, as required.** 20 mutants, **0 not caught**, in two layers,
because each catches what the other cannot:

* **layer A** drives the pure verdict function with synthetic rows — all 12 cells
  of the table, including that a non-`1` non-zero exit (a crash, a kill) counts
  as a DECLINE and not as an accept, and that the FAIL set contains VIOLATION and
  TRACE-MISMATCH but **not** OVER-DECLINE;
* **layer B** runs the WHOLE DRIVER on deliberately broken corpora and asserts its
  **exit code** — an empty corpus, a fabricated bank-accept/register-decline pair,
  a fabricated trace mismatch, a **vacuous half** (a `.c` with no `cq_*` call,
  which ACCEPTS through the passthrough early-out — bd memory
  `empty-module-accepts-vacuity-trap`), and a missing twin. *A checker whose
  verdict function is right and whose exit code is not is a checker that reports
  a pass* — this session measured a harness reading `$?` after an assignment and
  reporting 7/7 green including its mutants.

The driver itself refuses to report success on 0 pairs, on a missing half, on a
vacuous stage-1 module, or on a compile failure, and a link failure on an
accepted module is surfaced as a distinguishable marker rather than scored as an
empty trace.

---

## 7. What I re-attacked (Rule 13 — a fix introduces new holes)

CLAUDE.md's measured precedent is *"8 instances over 6 rounds on one function —
**two of them introduced by a fix**"*. Six new probes, all four-way:

| probe | the attack | result |
|---|---|---|
| `f10_bool_bank_chained_invariant` | a `_Bool` bank whose per-cell theta is **CHAINED on a loop-invariant rail**: every trip is an in-place Ry on ONE wire, so all three cells park the same handle after three rotations. The staling gate is the reader's own previous dynamic instance — the shape the memory hop **cannot** see. | **Already caught**, by the PRE-EXISTING in-loop-invariant leg of bd `3d8q` (`readerStalesItself` withholds the self-exemption for a loop-invariant seed). Identical on SUBJ_B. Not a new hole, and not one the fix closes or opens. |
| `f11_int_bank_chained_invariant` | the same at `int` cells (no storage cast anywhere) | same |
| `f12_register_twin_of_f11` | the array-free twin | DECLINES on all four binaries — the two spellings agree |
| `f13_two_banks_one_stale` | TWO banks, one stale and one clean, in one function: the hop is per-bank, so neither may contaminate the other | unchanged from SUBJ_B (both declines land earlier, at the promoter's one-bank clause) |
| `f14_two_banks_both_clean` | the control | unchanged from SUBJ_B |
| `f15_split_reads_one_stale` | the gate BETWEEN two reads of the SAME bank — one legitimate, one stale; a per-BANK rather than per-READ answer would over-decline the first or miss the second | unchanged from SUBJ_B (declines earlier, at `array mixes a rail cell access with an unrecognized one`) |

Also attacked and recorded:

* `f08`/`f09` — a genuine `_Bool`-cell invariant park (the review's `f03` never
  reached the fence: its `cq_theta(seed,…)` took an `int`). **Not constructible
  at the `-O1` floor**: `clang` turns an invariant `_Bool` park into an
  `llvm.memset` and the module dies at `tainted value consumed by an unknown
  callee` on all four binaries. Consequence, filed rather than hidden: **the
  `TruncInst` arm of `railBankParkedRails` has no *stale* subject today**. It is
  exercised by the accepting `_Bool` banks (o02/o05/p03) but they cannot
  distinguish its presence, so it is a DECLINE-direction clause pinned only by a
  mutant, not by a fixture. Kept, for the same reason the review's F-3 opinion
  keeps a structurally-shadowed clause, and named here so the next round does not
  re-derive it.
* the seed's **constant filter** and the **Delta-vs-Seeds** conjunct are both
  DECLINE-direction and both have their justification written at the site in
  I-6's form (direction, not unreachability).

---

## 7b. The corpus, and the mutants

**The three-way sweep** (`bfix/probes/corpus3.sh`, ORACLE | BASE | BFIX, 5635
inputs, `DONE inputs=5635 rows=5606`, exit 0): **0 A→D**, 0 A→A md5 divergence.

But that is BASE→BFIX, i.e. Track B's increment *plus* this fix. **This fix's own
delta was isolated** by joining against Track B's `corpus_784c14fa05c16c50.txt`
on the 5557 common rows — the ORACLE column agrees on **0 of 5557** disagreements,
which is what makes the join sound — and the answer is **ZERO movers**. The fix's
entire corpus delta is the **49 rows that did not exist** when Track B swept.

**PROTOCOL S3's known blind spot was closed rather than inherited.** The shared
tag regex renders some declines as an empty `D:`, so a decline→decline string
move inside one is invisible to that join. All **136** empty-tag rows were re-run
through BOTH binaries on the SAME stage-1 module and compared on **exit code +
FULL stderr bytes**: **0 real movers**. The one row flagged, Track B's
`derived/B10_classcond_deadphi_crash.ll`, **ABORTS (exit 134) on BOTH** with a
byte-identical message — the only differing bytes are the binary's own path
inside LLVM's `Program arguments:` line. Pre-existing, and already attributed by
Track B's own sweep row (*"1 pre-existing hand-derived ABORT on BOTH binaries"*).

**The injection matrix** (7 mutants: Track B's M1/M2/M10 plus M11–M14 for this
fix, with the **new twin gate added to `gates()`** so the matrix measures the
instrument that sees this class): **7 mutations, MISSED 4**.

| mutant | verdict | note |
|---|---|---|
| **M11** the memory hop removed — **the P1** | **CAUGHT** | by the new RED fixture *and* by the twin gate (3 VIOLATIONS) |
| **M14** the store-side storage-cast strip dropped | **CAUGHT** | by 12 lit fixtures — the Rule-14 coupling made observable, since `bankStoreRailValue` also carries the `!cq.railbank` width |
| **M1** piece 1 removed (Track B's core miscompile) | **CAUGHT** | and **both new green fixtures are among its catchers**, so they add coverage Track B did not have |
| **M2**, **M10** | MISSED | Track B's two, unchanged; M2's *justification* corrected by item I-6 |
| **M12** the constant-seed filter | MISSED | **this fix's.** Safe direction (its removal manufactures an over-decline, never an accept). MISSED is the measurement of how load-bearing it is today: only a whole-object zero `store iN 0` reaches it, an `llvm.memset` initializer does not reach it at all (a `CallInst`, and the walk takes only `StoreInst`), and no corpus module pairs one with a same-typed `cq_theta` |
| **M13** the storage-`trunc` arm of the hop | MISSED | **this fix's**, and expected — §7's measurement: a `_Bool`-cell STALE bank is not constructible at `-O1` |

⚠ **Anchor and restore integrity were checked before the matrix was believed**:
every mutant anchor occurs **exactly once** in its file (0 `EDIT-FAILED` holes),
0 `BUILD-FAILED`, and the restore build reproduced `cq-opt` `fd310f80…` and
`libCQPass.so` `53d8d055…` **bit-identically** with `git status` showing no
residue. A matrix that reports `n/a`, or that leaves a mutated tree behind, is a
hole rather than a pass.

⚠ **The two comment corrections made after the gated build also reproduce
bit-identically** (Release, `-DNDEBUG`, no `assert(` in either file), so the
source on disk is exactly what every gate line was measured on.

## 8. Open, and owed

* **`cq-opt-equivalence-full` is OWED at the Group-1 gate**, and this increment
  **adds** to Track B's existing debt: Track B added two decline strings and
  stopped one arm declining; this fix **moves the population of a third**
  (`rotation/measure operand predates a non-diagonal gate` now reaches
  memory-resident readers). Not the fix agent's to run (PROTOCOL S1).
* **The full `ctest -j6` is the merge-and-gate agent's**, once per landing.
  Two new ctest entries are registered; post-union checks are clean (0 duplicate
  `add_test` names, 442 entries, sweep still LAST).
* **TWO NEW MISSED MUTANTS, both this fix's, both DECLINE-direction** — M12 (the
  constant-seed filter) and M13 (the storage-`trunc` arm of the hop). Neither can
  become an over-accept if it is wrong: M12's removal manufactures an
  over-decline, M13's removal loses a decline in a shape that is not constructible
  at the `-O1` floor. Both are pinned by their mutant and by nothing else, and
  both are named in `GATES.md` §"The FOUR MISSED mutants" rather than absorbed
  into a count. The measurement that would close M13 is a `_Bool`-cell stale bank
  the floor does not currently produce; the one that would close M12 is a module
  pairing a whole-object zero `store iN 0` with a same-typed `cq_theta`.
* **The conditional bank store** carries THREE obligations now, all written at
  PASS G and gated on the same trigger: I-2's re-derivation, I-3's real `|0⟩`
  rail, and the memory hop's backward closure through the `phi`'s incomings plus
  leg 2's barrier becoming the STORE rather than the seed's def.
* **bd `a3z7`'s dtzb vocabulary gap composes with I-1's deliberate absence** —
  written as a joint retirement trigger at `ArithLowering.cpp`.
* **The owner's inner loop (`o03`) still declines** at E5 wall 3, unchanged.
  The honest closing claim is Track B's, unmoved: *the bank compiles; the owner's
  cascade needs (c3) + W3.*
