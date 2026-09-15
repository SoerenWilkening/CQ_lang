# Rule-13 adversarial review — Track B, the rail-bank W1 SECOND HALF

Independent reviewer, session 2026-09-15. Subject: branch `railbank-accept`, commit `3b982459`,
worktree `/Users/sorenwilkening/Desktop/CQ_B`. Base: Track A's `railbank-blockers` `9e11f524`
(`/Users/sorenwilkening/Desktop/CQ_A`). ORACLE: `main` `74eabd2c` (`/Users/sorenwilkening/Desktop/CQ_lang`).

**No build was run and no suite was run.** Every measurement below is the per-probe PROTOCOL pipeline
(stage 1 `clang -O1 -g`, stage 2 `cq-opt`, stage 2b `free_pairing_check.py`, stage 3 link, stage 4 run)
against binaries that already existed, plus analytic reasoning over the source. Per Rule 2 a green
suite clears nothing here and none is cited as if it did.

---

# VERDICT: **FINDING**

**One P1 over-accept.** The rail bank is a **laundering route for bd `3d8q`** — the project's one known
verify-clean silent miscompile, closed on 2026-09-14 and re-opened here through memory. A program that
the ORACLE, the BASE **and the SUBJECT itself** all decline loudly in its register spelling compiles
silently, exit 0, stderr empty, STRICT stage 2b `0 violation(s), 0 unproven`, with a plausible
seven-line trace — and the trace is the wrong circuit.

Plus **six items** (I-1 … I-6), three of which correct claims the track's own records make.

⚠ **Two of the track's four named Rule-13 rounds produced nothing; the third produced items; the
fourth produced a correction.** The finding came from **Round 1(c)** — the restated D3/R1 question
`SCOPE_B.md` §6 answered with *"less than it looks"*. That answer is wrong, and the way it is wrong is
the standing lesson: **R1's own warning — *"a 'does not reach the fence' answer is true of the binary
and FALSE of the capability"* — was quoted in the scoping and then not applied to the capability the
scoping was authorising.**

---

## 0. Binary verification (briefed as a potential FINDING in its own right)

Re-hashed on disk at the moment of writing, after the restart:

| label | `cq-opt` sha256 | `libCQPass.so` sha256 | matches `trackB/GATES.md`? |
|---|---|---|---|
| ORACLE | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | **yes** |
| BASE (Track A subject) | `b65549356168354626a7f09c748e35e43f9fba186ae7ede8dab6a31fd3aae2bf` | `1c7df31bf95268089ffb10775240339764f91bf4d5a53c6186c1178e06e6093a` | **yes** |
| SUBJ (Track B final) | `784c14fa05c16c501662b3814434dafb8ffb1cc2ed98a8d17986dc12a372b6ff` | `a4e4f6781524c569e7112f5809c2813dd250d8a1b9e02571a4095d2719ba65c6` | **yes** |

Worktree HEADs: `CQ_lang` `74eabd2c`, `CQ_A` `9e11f524`, `CQ_B` `3b982459`. **No hash finding.**
`GATES.md`'s own cited lines are citable; I re-derived only the corpus counts (below), not the suite rows.

Corpus file re-derived by `awk` rather than read off the prose
(`trackB/probes/corpus_784c14fa05c16c50.txt`): **5557 rows, 27 D→A, 0 A→D.** Both match the record.

---

# F-1 — **P1 OVER-ACCEPT: the rail bank launders bd `3d8q` through memory**

## The shape, as a program

```c
/* f01 — ACCEPTS on the subject. */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;      /* park q's rail NAME in every cell */
  q = cq_theta(q, 0.7);                        /* NON-DIAGONAL — relabels q's wire */
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);   /* reads q BEFORE the 0.7 */
  return s + cq_measure(q);
}
```

Its **register spelling** — the same program with the parking done in a register instead of an array —
is the shape bd `3d8q` closed:

```c
/* f02 — DECLINES on ORACLE, BASE and SUBJECT alike. */
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int c = q;                                   /* the same SSA value */
  q = cq_theta(q, 0.7);
  return cq_measure(c) + cq_measure(q);
}
```

## Measured

| program | ORACLE `0e280fc6` | BASE `b6554935` | SUBJECT `784c14fa` |
|---|---|---|---|
| **f01** (bank, stale order) | DECLINE `cq taint escape: tainted value stored to memory` | DECLINE, same | **ACCEPT** — 7 trace lines, STRICT 2b `2 rail mint(s) of which 2 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven` |
| **f02** (register, stale order) | DECLINE `cq opcode lowering: rotation/measure operand predates a non-diagonal gate` | DECLINE, same string | DECLINE, **same string, same `!dbg` (`:6:10`)** |
| **f06** (bank, legitimate order) | DECLINE `kMsgStore` | DECLINE | ACCEPT, 7 lines |
| **f07** (register, legitimate order) | **ACCEPT**, 7 lines | ACCEPT | ACCEPT |

`f06`'s subject trace is **byte-identical** to `f07`'s ORACLE trace (`diff` empty). So the bank's
*legitimate* ordering reproduces the register spelling exactly — which is precisely what makes the
*stale* ordering's silent acceptance a defect rather than a difference of model.

The emitted circuit for **f01**:

```
cqrt_alloc_i32(1) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cqrt_ry_i32(h0, 0x1.6666666666666p-1)     <-- the 0.7 rotation, BEFORE every measure
cqrt_measure_i32(h0) -> 0                 <-- b0[0], which the source says is PRE-rotation
cqrt_measure_i32(h0) -> 0                 <-- b0[1]
cqrt_measure_i32(h0) -> 0                 <-- b0[2]
cqrt_measure_i32(h0) -> 0                 <-- q
```

versus **f06**, which is what the author would have to have written to get that ordering's meaning:

```
cqrt_alloc_i32(1) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cqrt_measure_i32(h0) -> 0 ×3
cqrt_ry_i32(h0, 0x1.6666666666666p-1)
cqrt_measure_i32(h0) -> 0
```

Two well-formed C programs, one statement apart, and the compiler emits a circuit for the first that
realises **neither** reading: the three bank measures observe `h0` after a rotation the source places
after them. There is no valid quantum circuit for f01's source — obtaining the pre-rotation value of a
qubit that is subsequently rotated requires cloning (Rule 8) — so the Prime Directive answer is a loud
decline, which is exactly what `f02` gets.

**It reproduces outside `main`, in the house style** (`i02`, `__attribute__((noinline)) int slice(...)`
called from `main`): ACCEPT, 7 lines, same trace, 2b `1 rail mint … 0 violation(s)`. And it reproduces
**without `-g`** (stage 1 `clang -O1 -emit-llvm`, no debug info): subject rc=0, ORACLE declines.

## Mechanism

Three facts compose, and each is individually sound:

1. **Piece 1 makes a bank cell load tainted but not a rail RECORD.** `recordStaleQuantumReaders` /
   `declineRecordedStaleQuantumReaders` (bd `3d8q`, `OpcodeLowering.cpp`) ask *"does this `cq_measure`
   operand — or `cq_theta` arg-0 — read a rail name that a non-diagonal gate has since relabelled?"*
   via `WireWalk`'s forward/backward wire walks. **Those walks have no memory hop.** The measure's
   operand here is a `LoadInst`, not a rail mint, so the walker finds no wire and the reader is never
   adjudicated. The same is true of `LoopLowering::staleRailRecordRead`, which groups records **per
   ROOT MINT** — a bank load belongs to no group.
2. **Piece 3 (D5) adjudicates WHICH consumer may read a parked rail, never WHEN.**
   `isAdmittedRailBankReader` is a pure shape/width test: entry (1) a collected `@cq_measure_<sfx>`
   whose operand type is the rail type, entry (2) its single-use storage `trunc`. Neither asks anything
   positional. So the allow-list hands the measure a clean bill on a question it never asks.
3. **Piece 2 then makes the load *be* the handle**, so `lowerMeasures` emits a real gate on `h0` — which
   is what turns a missing question into a wrong unitary rather than a dropped measurement.

D5's own header states the reason an allow-list exists at all: *"the fences that would otherwise
adjudicate these consumers are all SSA-shaped and go SILENT on a memory-resident wire."* It then
enumerates two such fences (`hasTaintedCondBranch`, `railWireClosure`) and **stops one short of the one
that matters** — the stale-reader fence landed by the immediately preceding session.

## Rule / lesson

* **Rule 3 / Rule 8 / Rule 2** — the accept is verify-clean, 2b-clean and trace-plausible, and is still
  the wrong unitary. Stage 2b cannot see it (rail *pairing* is correct); the golden byte-diff cannot see
  it (the stream is self-consistent).
* **Lesson L2, exactly**: *"when you WIDEN a set, ask what OTHER set was computed over the same
  closure."* The bank widened **"what can hold a rail"** from an SSA value to a memory cell. The set
  computed over the same closure is **"what counts as a READ of a rail's current label"**, and bd
  `3d8q` computed it three weeks ago over SSA values only.
* **Lesson L1's PREDICATE species, in the spatial rather than the temporal axis.** The increment
  carefully discharges L1 in time (the taint rule inside `collectAndSeed`; D5 inside
  `declineTaintEscapes` so `repropagateControlMerges` re-asks it). It does not ask the same question of
  the fences that ran *beside* it.
* **R1 restated, and not applied.** `SCOPE_B.md` §6 quotes *"a 'does not reach the fence' answer is
  true of the binary and FALSE of the capability"*, then concludes that what changes when the accept
  lands is *"less than it looks"* because *"a bank LOAD is not a member of any group and cannot become
  one"*. That non-membership is not safety — **it is the hole.**

## Direction

**P1 — over-accept.** The safe half (an unproven shape declining) is absent; a program with no valid
circuit gets one.

## Scope, measured — what is and is not affected

The discriminator is **whether the stored value is defined inside the walk loop `L`**.

* **Every shipped accept is safe.** All six registered `tests/e2e/slice_railbank_*.c` slices and every
  `railbank_accept_*.ll` store `cq_theta(b0[i], …)` — a rail **minted inside the loop body**, so no
  register name survives the loop and no later gate can relabel it. `a00` (the canonical shape) re-runs
  ACCEPT with 9 lines and a correct stream.
* **The hole needs a loop-INVARIANT parked rail**, i.e. one register's name written into every cell.
  That is reachable from plain `-O1` C in one line, and it is the natural spelling of "record this
  qubit N times".
* It did **not** reproduce in four neighbouring spellings, all of which decline for unrelated reasons —
  `_Bool` cells (`f03`: `tainted value consumed by an unknown op`), a controlled relabelling gate
  (`f04`: `rotation arm shares the condition's register`), an in-loop relabelling (`f05`:
  `muxed by a classical-condition phi`), and the per-bit which-path shapes (`d01`/`d02`:
  `cq loop lowering: rolled body leaks a rail entangled …`, the bd `s82e` fence, working correctly).
  **Do not read that as containment** — it is four accidents, each owned by a different fence, none of
  which is asking this question.

## The red-green pair to write WITH the fix

Both as `ir-pass/test` fixtures on the linked stage-1 module, plus the e2e pair if a golden is wanted.

* **RED (must decline, mirroring the register spelling's string character-for-character):**
  `railbank_reject_measure_after_nondiagonal_on_parked_rail.ll` — f01 above. Expected:
  `cq opcode lowering: rotation/measure operand predates a non-diagonal gate` at the measure's `!dbg`,
  with the negative RUN line `not %cq-opt … 2>&1 | FileCheck`. ⚠ Per Rule 12's hygiene defect (b) the
  property is pinned by the `not` inversion, not by IR-text `CHECK-NOT`s.
* **GREEN (must keep accepting, byte-identical to today):** `railbank_accept_bool_prep_measureloop.ll`
  and `railbank_accept_int_cells_measureloop.ll` unchanged — the in-loop-minted rail. Plus the new
  **green control** f06 (`railbank_accept_invariant_rail_measured_before_gate.ll`), whose emitted stream
  must stay **byte-identical to the array-free register twin f07**, which is the property that proves
  the fix separated *ordering* rather than banning the shape.

## Where the fix belongs (and the trap in the obvious version)

The question is the stale-reader fence's, not D5's shape grammar's — so the minimal sound fix is to
**give the fence the memory hop it is missing, in one direction only**: when a `cq_measure` operand is a
rail-bank cell load, seed `recordStaleQuantumReaders` with **the rail name the bank's store parked**
(`railStoredToRailBank` already computes that relation in the opposite direction, so the owner exists —
Rule 14: call it, do not re-derive it), and ask the existing wire question of that name between the
STORE and the LOAD.

⚠ **The trap, stated because a naive fix breaks every shipped accept.** In the canonical rolled write
loop the `cqrt_ry` and the store are in the **same activation**, and the back edge puts a non-diagonal
gate "after" the store in program order on every trip. A position-free walk therefore declines
`railbank_accept_bool_prep_measureloop.ll`. The walk must be
`WireWalk::provablyBeforePerActivation`-shaped — the machinery bd `3d8q` already built for exactly this
(`readerStalesItself` / `RequireEmitDominance`).

A cheaper Prime-Directive-safe stopgap, if the wire work is out of scope for the fix window: **refuse a
`Bank` whose stored value is not defined inside `L`.** Measured against the shipped surface, that
conjunct flips **zero** registered accepts (all six slices and all six `railbank_accept_*.ll` store an
in-loop mint) and closes f01, f06, `d03` and `d5e` together. It over-declines f06, which is legitimate —
per the owner's 2026-09-11 ruling that is a defect to file, not a margin — so it should be filed as an
over-decline in the same change rather than left as the answer.

---

# ITEMS

## I-1 (Round 4, correction) — `ArithLowering.cpp:967-969` IS reachable for a bank rail; "measured unreachable" is false

`IMPL_B2.md` §12 round 4 and `SCOPE_B.md` §5.2 say D6's subtraction sites *"were measured unreachable
for a bank rail"* because `isTerminalHandle` stops the nomination at source. That is true of three of
the four families and **false of the fourth**.

I re-derived all of them:

| site | what actually refuses a bank rail | explicit or incidental |
|---|---|---|
| `Uncomputation.cpp:1583/:1588/:1598` (`collectTerminalCandidates`) | `isTerminalHandle` — the shipped D1 door | **explicit** |
| `Uncomputation.cpp:1379-1382` (the interior partition's 4-way subtraction) | `isInteriorTerminalHandle` **(I3)**: `dyn_cast<CallInst>(U); if (!CI) return false;` — and its own comment names *"a `store`"* | structural, and it pre-dates this increment |
| `DagTraversal.cpp:192/:201/:212` (the closure scan's 4 subtractions) | the catch-all at `:348`, `D.NotClosed = true; // any other user we cannot prove reversible` | **incidental** — the same "do not rest on the incidental exclusion" the four neighbouring comments each refuse to rest on |
| `ArithLowering.cpp:967-969` (the M-C late reassignment) | **nothing** | — |

Measured (`h01`, `__attribute__((noinline))`): a bank cell parking `t = q + 7` **does** reach the M-C
site and **does** get converted in place —

```
cqrt_alloc_i32(1) -> h0 ; cqrt_ry_i32(h0, 0x1p-1) ; cqrt_addc_i32(h0, 7) ; cqrt_measure_i32(h0) ×3
```

— and that stream is **byte-identical** to its array-free register twin `h04`, which ACCEPTS on the
ORACLE. So **no over-accept**: the conversion's own `provablyBefore` discipline refused when a later
reader existed (`h02`, `h05` both kept the out-of-place `cq_template_add_i32_hl`, byte-identical to
their register twins `h03`/`h06`).

**What is owed is the correction, not a fix.** The site is live and un-subtracted, so L2's question ("do
these five move together?") is currently answered by measurement on one shape rather than by the
explicit-image discipline every neighbouring set gets. Either add `railStoredToRailBank` there for the
same reason `GraveyardRails` and `railCarriesControlledRotation` are there, or record in the source that
it is deliberately absent and why. **Direction: neither — a documentation/robustness item.**

## I-2 (attack 4, correction) — the cast sink's "cannot move an accept" rests on more than the `phi` test

`applyBank` PASS G's comment says: *"IT FIRES ONLY WHEN THE STORE'S VALUE IS A `phi`, i.e. ONLY ON THE
CONDITIONAL-ARM SHAPE, WHICH IS ENTIRELY THE DECLINING POPULATION TODAY."*

Measured over the fixture population that can reach it: of the **40** modules matching
`ir-pass/test/{railbank_*,lowering_railbank_*}.ll` on the subject (counted by `ls`, not quoted), the
sink fires on **7**, and **all 7 exit rc=1** (decline) —
`railbank_promote_loop_{n2_wholeobj_init,n3,n8}`, `railbank_promote_uninit_bank`,
`railbank_reject_classical_cond_bank`, `lowering_railbank_bank_anchor_{n3,uninit}`.

But the load-bearing premise is **not** the `phi` test. It is that **both** condition classes for a
conditional bank store currently decline, and I measured both separately:

* classical condition → `cq taint escape: tainted value muxed by a classical-condition phi` (`b01` `_Bool`, `b02` `int`);
* tainted condition → `cq controlled lowering: condition predates a non-diagonal gate` (`c01`, `c02`).

Neither is a property of the sink. Either could move: bd `wx8g` already landed the in-loop rolled
bool-controlled prep, and the 2c fence is on the over-decline list. **RETIREMENT TRIGGER to write at PASS
G: the day a conditional bank store accepts, re-derive this claim — the `phi` test alone does not carry
it.**

## I-3 (attack 4 / attack 7, latent P1) — PASS G MANUFACTURES the value PASS 3 refuses to write

PASS 3 of the type rewrite deletes the zero initializer rather than rescaling it, and its comment gives
the reason in the strongest available terms: *"a RESCALED memset would write handle `0` into every cell,
and handle `0` IS A LIVE RAIL in this runtime (`cqrt_alloc_i1(0) -> h0`)."*

PASS G, in `applyBank`, builds `NP->addIncoming(Constant::getNullValue(RailTy), …)` for every non-`zext`
incoming. Measured on the shipped fixture:

```
%cq.bank1    = phi i1 [ %25, %24 ], [ false, %22 ]
%cq.bank.stg = zext i1 %cq.bank1 to i8
store i8 %cq.bank.stg, ptr %cq.bank.addr, align 1
```

After the type rewrite that ¬arm incoming is **handle `0`** parked in a cell — the same live rail PASS 3
declines to create, arriving by a different door. It is unreachable today only because of I-2's two
declines; it is **not** protected by anything that knows about it.

**Direction: latent P1, gated by I-2.** The two sites should carry each other's name, and the fix that
lands a conditional bank store owes the ¬arm a real `|0⟩` rail (a fresh `cqrt_alloc`), not the literal 0.

## I-4 (Round 3 / Rule 14 / L7-with-a-twist) — the rewrite does not call "the same predicate C1 asks"

`rewriteOneBank`'s PASS-collection comment says the whole-object-zero question is *"ASKED BY CALLING
`isWholeObjectZeroStore`, THE SAME PREDICATE THE CARVE'S C1 USER SCAN ASKS (Rule 14)"*, and cites the
drbq Inc-3 (b′) defect — *two spellings of one question* — as what it is avoiding.

It is **two spellings**. C1 (`QramLowering.cpp`) asks `wholeArrayConstantZero(DL, ST->getValueOperand(), AT)`:
`getTypeStoreSize(valueTy) == getTypeStoreSize(ArrTy)`. The rewrite asks
`isWholeObjectZeroStore(ST, AI)` (`RailBankPromote.cpp`): pointer identity ∧ `isSimple()` ∧
`getTypeStoreSize(valueTy) == getTypeAllocSize(allocatedTy)`.

They agree on every reachable module (for an integer-element array `StoreSize == AllocSize`), so **this
is not a defect** — it is a source comment asserting a Rule-14 property the code does not have, in a
Rule-13 core stage, four lines above a warning about exactly that. L7-with-a-twist: fix the comment in
the same change, or the next round re-derives this. **Direction: documentation.**

## I-5 (Round 3, minor) — PASS 3b's silent skip contradicts the stage's own stated contract

`rewriteOneBank`'s header: *"`Fail` is set (and a loud diagnostic fired) on anything the rewrite did not
expect — **NEVER a silent `continue`**."* PASS 3b:

```cpp
for (Instruction *LM : Lifetimes) {
  auto *CI = cast<CallInst>(LM);
  if (isa<ConstantInt>(CI->getArgOperand(0)))
    CI->setArgOperand(0, ConstantInt::get(Type::getInt64Ty(Ctx), NewSize));
}
```

No `else`. C1 admits `lifetime_start`/`lifetime_end` **unconditionally**, with no constant-size check, so
the two enumerations disagree by one case — a non-constant size is silently left describing the
pre-rewrite (smaller) object.

**Measured unreachable, and the reason is LLVM's, not the stage's:** `llvm.lifetime.start.p0`'s size is
`immarg`, so a non-constant size fails `opt -passes=verify` (`immarg operand has non-immediate
parameter`). So the branch cannot be false in a well-formed module. **Direction: hygiene** — either
make it `Fail`, or say at the site that the verifier owns it (the latter is cheaper and is the honest
statement).

## I-6 (attack 2, the MISSED 2) — M2's "no constructible subject" is asserted over a stage list, not measured

M10 is fine: it is L3's shape, the second spelling of a fence whose first spelling refuses the input
first, kept deliberately and reported rather than dropped. I agree with keeping it and with calling it
MISSED.

M2 (`isRailBankAlloca` dropped from the `Bank` arm of `declineTaintEscapes`) is reported MISSED on the
ground that *"to construct a `Bank`-without-record module, a stage would have to MANUFACTURE a bank
shape between the mark slot and `declineTaintEscapes`; none does."* That is an **enumeration of stages**,
which is L5's losing move (*a syntactic answer to a semantic question*). The window contains
`foldIdentityBitcasts`, `promoteFp80Union`, the `flattenPredMuxRegions` fixpoint, `unrollConstTripLoops`,
`recognizeCtlzIdiomLoops` and `detectSpecializations` — at least one of which (PredMux) exists to turn
conditional control flow into straight-line code, which is the transformation that would turn a
`BankRaw`/`Reject*` shape into a `Bank` one.

**I did not construct such a module** and I am not claiming one exists. The item is that the conjunct's
justification should be *"the alternative failure is silent and the direction is narrowing"* — which the
record also says, and which is sufficient on its own — and should **not** additionally claim
unreachability it has not measured. **Direction: documentation.** The conjunct itself is right and must stay.

---

# Coverage of the track's four named Rule-13 rounds

| round | subject as handed over | what I did | outcome |
|---|---|---|---|
| **1(a)** — the spine's disposition of a store-kept parked rail **outside `main`** | re-take, do not read | `i01` (`noinline slice()` called from `main`, 2 defines survive in the lowered module): ACCEPT, 9 lines, 2b `1 rail mint … 0 cqrt_free site(s) … 0 violation(s)`. Re-derived the mechanism: `collectTerminalCandidates` → `isTerminalHandle` → false ⇒ never nominated ⇒ `computeFreePoint` is never called on a bank rail ⇒ `FreePoint::isRecognizedEscapeUser` is never consulted | **clear.** The scoping asked for `isRecognizedEscapeUser` to be taught as well; it was not, and it does not need to be — the nomination never gets that far. Worth one sentence at the D1 door saying so, since `SCOPE_B.md` §5.2 still asks for it |
| **1(b)** — `classifyArms` with BOTH the sunk cast and a surviving store | the track could not measure it | **I could not reach it either.** Both condition classes die before the question is decidable (I-2). Stated as unreached, not as clear |
| **1(c)** — §6's restated D3 question, **in its restated words** | the restated words are R1's *"true of the binary and FALSE of the capability"* | attacked the memory-blindness of every rail-freshness fence in the tree | **F-1** |
| **2** — the taint rule's blast radius; D5 against shapes nobody listed | probed 12 unlisted/listed consumers | all decline (table below). **No over-accept in D5's enumeration.** L4 discipline verified by reading: `declineUnallowedRailBankReaders` walks the whole user list and diagnoses the offending user, so an admitted consumer in front of an unadmitted one cannot hide it. ⚠ The gap is not in the enumeration but in what the enumeration **does not ask** — F-1 |
| **3** — the type rewrite against the verifier's blindness; find a third mutant the matrix lacks | diffed C1's admitted user vocabulary against `rewriteOneBank`'s enumeration, user class by user class | **I-4** and **I-5**. No correctness hole. PASS 2's two gep spellings, PASS 4's cast swap, PASS 5's `mutateType` + `!range`/`!tbaa` drop, PASS 1's alignment bump and PASS 3b's size rescale each check out against C1's set |
| **4** — the spine, outside `main`; D6's five subtraction sites (**the one the track is least confident about**) | re-derived all four families | **I-1**: the `ArithLowering` site is REACHABLE, not unreachable; no over-accept found, correction owed |

⚠ The track wrote *"the measured hit rate says round 4 finds something. Budget it before round 1."*
**Round 4 found a correction; round 1 found the P1.** The heuristic was wrong about which round, and
right about the rate.

---

# The eight briefed attack items, each answered

**1. Width-vs-handle confusion (Rule 15) — enumerate every other site where cell width and rail width can disagree.** Enumerated six; all fenced or safely over-declining.

| site | disposition |
|---|---|
| the measure (entry 1) | fenced: `LD->getType() == RailTy` |
| the storage cast (entry 2) | fenced: `TruncInst` ∧ `hasOneUse()` ∧ `TR->getType() == RailTy` ∧ its user is an admitted measure |
| the erasure (PASS 5) | fenced: only a `trunc` **to** `RailTy` is folded — the second spelling, kept (M10 / L3) |
| a `zext`/`sext`/`bitcast` reader | not on the allow-list ⇒ loud decline |
| a compare / arithmetic reader | not on the allow-list ⇒ loud decline (`e03`, and the shipped `railbank_reject_load_into_arith.ll`) |
| the allocator seed | untouched by the bank — `lowerRotations` mints from the theta's own type |
| the **store**-side derivation (`railBankRailType` reads ANY cast to `CellT`) | self-fencing, and structurally so: a narrowing store cast makes the derived rail WIDER than the cell, so entry (1) fails by type and entry (2) is not expressible. Every reader is unadmitted ⇒ the module declines. The track filed this as an over-decline; I agree with the classification |

**2. The MISSED 2.** → **I-6**. M10 correct and correctly kept; M2's unreachability claim is asserted.

**3. L1 — the round-2 window.** Re-derived stage by stage against `CQLoweringPass.cpp`'s actual order.
The mint is at `:251`, above every taint-consuming stage, and publishes by a **full `propagate`** rather
than a delta — so the taint-GROWTH obligation is discharged structurally, not by `adjudicateTaintDelta`,
and that is sound. The taint rule lives inside `collectAndSeed`, i.e. inside `propagate`, so there is no
second call site. D5 lives inside `declineTaintEscapes`, which both `adjudicateTaintDelta` (`:579`) and
`repropagateControlMerges` (`:616`) call, so the round-2 re-ask is free — and the **last** D5 is inside
`repropagateControlMerges`, i.e. after the second detection round, so an emitter-created bank reader is
still adjudicated. The type rewrite is strictly after the fixpoint. Both entry points carry the mint and
the rewrite (WI-1.12 parity verified by reading `runOnFunction`). **No L1 finding.** F-1 is L1's
*predicate* species in a different axis (a sibling fence, not a later stage) and no slot change fixes it.

**4. The cast sink's "cannot move an accept".** → **I-2** (the claim's real ground) and **I-3** (what
it manufactures).

**5. The A×B composition — C2′, C4 and C6 as preconditions of `applyBank`.** See §"A×B" below.

**6. D5's positive enumeration and the removed entry (3).** The removal is **right, and better argued
than the record claims**. `d5d`'s bank-to-bank copy is folded by `-O1` (the second array is deleted
outright — pinned by `railbank_accept_bank_copy_folded.ll`), so the entry had no customer; removing an
accept door from a Prime-Directive fence is the safe direction, and a surviving copy now declines
loudly. I checked the consumer it might have orphaned: `d5e_bank_alias_double_measure.c` (two banks,
both measured) is a shipped **D→A accept**, and its array-free twin `d04`
(`cq_measure(q)` three times, then a rotation, then a measure) **accepts on the ORACLE**. So that
boundary is bd `yiid`'s (`cq_measure` is not modelled as a wire event) and not this increment's, exactly
as the record says — verified rather than taken. ⚠ But note the asymmetry F-1 exposes: `d03`, which is
`d5e`'s single-bank cousin, accepts **because** of `yiid`, while `f01` — one line different — accepts
because of a hole. The two must not be filed together.

**7. Rule 6 / Rule 8 on the spine change — which rails are left allocated, and is each entangled?**
On every accepting bank the parked rails are **`Measured`**, so the flat-twin disposition (no adjoint, no
free) is the correct one and the emitted stream is byte-identical to the array-free twin (the shipped
`e2e-railbank-flat-twin-identical` gate, and my `f06`-vs-`f07` re-measurement). I attacked the
entangled-leak direction directly — a bank of per-bit which-path rails followed by a non-diagonal
rotation and a measurement of the source register, i.e. bd `s82e`'s divergent half — in both cell widths
(`d01`, `d02`). **Both decline**, on `cq loop lowering: rolled body leaks a rail entangled …`, which is
`declineDephasingUnmarkedLoopRails` doing its job on the bank population. The narrower shape (one
invariant rail parked in N cells, never read, then interfered with) is not constructible at `-O1`: an
unread local array is DCE'd, and once it is read the read is a measurement the user wrote. **No Rule-6/8
finding.** ⚠ This clears the *leak*; it does not clear F-1, which is a stale *read*, not a leak.

**8. F-3 — three structurally-shadowed promoter clauses: dead code or defence in depth?** My opinion:
**keep them, and do not delete on this evidence.** Deleting B2/B5/B4′ because a conjunct in another file
shadows them is the `MERGE_FILINGS` F-1 mistake restated (and 2026-09-14c's F-2 precedent — *delete it
or land it with the widening* — was written about a path made unreachable by the **same** merge, which is
a different maintenance fact from a clause whose shadow is a live fence in another TU). What the track
shipped instead — each fixture keeping the two properties that remain true, plus an L8 retirement
trigger naming the widening that restores isolation — is the right shape. ⚠ One addition: T1/T3/T5/T6 in
`trackA/SIGNATURE.md` and the three fixture headers now form a closure table, and per L3 *a closure table
is worth exactly its most-missing row*. It should be one table in one place, not four headers.

---

# The A×B composition (2026-09-14c `MERGE_FILINGS.md` F-1) — the still-owed opinion

The question: *re-derive **C2′**, **C4** and **C6** as **preconditions of `applyBank`**, not as clauses
of a classifier.*

**The structural answer is better than F-1 feared, and for a reason worth recording.**
`markRailBankAllocas` runs the **full carve again**, on the module **after** the promoter's fixpoint has
settled, and mints only on `RailBankCarve::Bank`. So every precondition the **type rewrite** and the
**D5 allow-list** rely on is re-proven on `applyBank`'s **output**, not inherited from its input. That is
Rule 11 applied to a sibling stage rather than trust, and it is the strongest property in the increment.
Concretely:

* **C2′** (non-self-wrapping affine `{0,+,1}` over an outermost loop, constant trips ≤ N) — re-proven at
  the mint on the promoter's cloned latch gep. It is what makes "each cell written once" true for PASS
  2's index-preserving retype.
* **C4** (exactly one store site) — re-proven at the mint. ⚠ `applyBank` itself **adds** a store, so the
  input's C4 and the output's C4 are different facts about different modules; both are checked, in the
  right order. T6 governs the widening.
* **C6** (totality: `Trips == N`, every in-loop read is of the cell this trip writes) — this is the one
  that does **not** fully re-prove, and the reviewer should know why. The output C6 is **vacuous in its
  in-loop-read half**, because `applyBank` PASS B has already erased every in-`L` load. So the
  forwarding PASS B performed is licensed by the **input** carve only, and the mint cannot re-check it —
  the evidence was consumed. The counting half (`Trips == N`) does re-prove, and it is the half PASS 3 of
  the type rewrite leans on when it **deletes** the initializer.

**So the honest statement is: two of the three are preconditions of `applyBank` that are independently
re-established afterwards; C6's in-loop-read half is a precondition that is established once, by the
input carve, and is thereafter unfalsifiable.** That is not a defect — B6's `BankRaw` requirement is
exactly that proof — but it is the seam, and it is where T1/T3's "widen the promoter and C7 in the same
change" obligation actually bites.

**What the composition does NOT establish, and F-1's own framing is the right one:** none of C2′, C4, C6
or C7 says anything about **when** a parked rail's label is still current. F-1's warning was about
conjuncts *cleared for a different purpose*; the conjuncts here were cleared for the **shape** purpose
and are sound for it. The composition's hole is not in the clauses that were composed — it is in the one
that was never in either track's scope, which is F-1 of this review.

---

# What I attacked and found nothing in (and what would have caught it)

| attacked | result | what would have caught a defect |
|---|---|---|
| D5 with 12 consumer shapes: `ret` at `i1` and `i32`, `select`, a second measure of the same load, an opaque call, `cq_theta` arg-0, a store into an unrelated global, arithmetic, a non-zero array initializer, a classically-conditioned store, a tainted-conditioned store, a bank load as a branch condition (`L9`) | **all decline**, each with a source-located `!dbg`; the `L9` accept is a correct rail-condition kickback (`ry;rz` per rail, then measure) | the probe pipeline; nothing in the suite samples these |
| the Rule-6/8 entangled-leak direction through the bank (`d01`, `d02`, `d03`, `d04`) | correctly declined by `declineDephasingUnmarkedLoopRails`; `d03` is bd `yiid`, verified by its array-free twin accepting on the ORACLE | stage 2b is **structurally blind** here (it counts `cqrt_alloc` sites, and a template-minted rail has none) — only a twin comparison against the register spelling can see it |
| the M-C in-place conversion over a bank-parked rail (`h01`, `h02`, `h05` vs register twins `h04`, `h03`, `h06`) | three pairs, **all byte-identical**; `provablyBefore` correctly refused the conversion whenever a later reader existed | the byte-identity comparison against the register twin; `free_pairing_check` reports `0 violation(s)` either way |
| the type rewrite's user vocabulary vs C1's | agreement; I-4 and I-5 are the residue | only a hand diff of the two enumerations — no mutant in the matrix covers the *vocabulary* axis, only individual passes (M3/M4) |
| the L1 round-2 window, stage by stage | clear | nothing automated; this is read-only reasoning by construction |
| binary hashes vs `GATES.md` | all six match | `shasum` |

⚠ **What could NOT have caught F-1, and this is the part to carry.** The corpus sweep's headline safety
property is **0 A→D over 5557 rows** — and F-1 is a **D→A**. A sweep over a corpus written before the
capability existed cannot sample the capability's new accept surface; 5 of the 27 D→A rows were
spot-checked and `f01`'s shape is in none of them because nobody had written that program yet.
`ir-pass-lit` at 2054/2055 and the 8 e2e railbank entries (**cited** from `trackB/GATES.md`, keyed to
`784c14fa`, which I re-hashed against the binary on disk — **not re-run by this review**), together with
STRICT stage 2b and the twin-identity gates, are green on the subject — and every one of them is green on
`f01` too, because none of them contains a program of that shape. **The only instrument that sees it
is the comparison against the register spelling of the same program** — which is the instrument this
project keeps rediscovering, and which the increment already built for a different axis
(`e2e-railbank-flat-twin-identical`). Extending that twin discipline from *"does the bank match the
register spelling when both accept"* to *"does the bank DECLINE whenever the register spelling
declines"* would have caught F-1 mechanically, and is worth proposing as a gate in the fix.

---

# Summary for the orchestrator

* **Verdict: FINDING.** One P1 over-accept (**F-1**) — the rail bank re-opens bd `3d8q` through memory.
  Not merge-blocking on a technicality: it is merge-blocking on the project's own ordering, since the
  2026-09-14 owner ruling **Q3** put *correctness over expressiveness* for exactly this miscompile.
* **Six items**, three of which are corrections to claims in `IMPL_B2.md` / `SCOPE_B.md` /
  `applyBank`'s source comments (**I-1**, **I-2**, **I-4**), one latent P1 gated by I-2 (**I-3**), and two
  hygiene (**I-5**, **I-6**).
* **The A×B composition is opined on**, with C6's in-loop-read half named as the one precondition that
  is established once and is thereafter unfalsifiable.
* **Rounds 1(a), 2, 3, 4 ran. Round 1(b) could not be reached** and is recorded as unreached, not clear.
* Everything Track B claimed and I re-measured **held**: the hashes, the 27 D→A / 0 A→D counts, the
  seven sink-firing fixtures all declining, the flat-twin byte identity, the canonical accept's stream,
  the width-pun fence, and the D5 enumeration's L4 discipline. The finding is not a broken claim — it is
  a question nobody asked.
