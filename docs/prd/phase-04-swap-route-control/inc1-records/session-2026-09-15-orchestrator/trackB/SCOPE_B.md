# SCOPE — L-1a W1, the SECOND HALF (bd `xdu2`): an implementable design

Track B-scoping, session 2026-09-15. **No pass source was edited, nothing was built, no suite was
run** (PROTOCOL's scoping row). Every verdict below is the per-probe pipeline against the frozen
ORACLE, re-verified at track open:

```
0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d  build/ir-pass/cq-opt
94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b  build/ir-pass/libCQPass.so
```

Probes and their measured answers: `probes/README.md`. The `LoopLowering.cpp` answer the orchestrator
asked for first is `FILE_SURFACE.md` §0 (**no**).

---

## 0. HEADLINE — five measured findings, in the order that changes the plan

**(H1) THE OWNER'S PROGRAM DOES NOT COMPILE WHEN THIS TRACK'S WORK IS DONE, AND THE REMAINING WALLS
ARE NOT THIS TRACK'S.** The brief's acceptance bar — *"`opt` exit 0 … a trace … Not 'the decline
moved'"* — **cannot be met by W1's second half**, and this is measured rather than argued (§1). With
all three deferred pieces hand-emulated on the promoter's own output, the owner's program declines
`cq controlled lowering: control flow inside a loop body under quantum control` at
`iterationLocalRollable`'s conjunct **(c3)** (`ArmClassify.cpp:3903`), because the program measures
`a` after the loop and `a` is a tainted value defined in `L`. Remove that measurement and it declines
`cq loop lowering: loop-carried tainted value crosses iterations` — **X1**, `LoopLowering.cpp:2136`,
bd `ej5w` / W3 — because `a` is a cross-iteration tainted accumulator. **This is the orchestrator's
decision to make before the implementation starts**, and §1.4 states the three options.

**(H2) THE SILENT MISCOMPILE THE BRIEF NAMES IS REPRODUCED, WITH A TRACE.** Piece 3 without piece 1
(`probes/emulate_piece3.sh` on `b12`): `opt` **exit 0**, **STRICT stage 2b `0 violation(s), 0
unproven`**, a plausible **6-line** trace of three minted, rotated rails — and the program's **three
`cq_measure(b0[i])` calls emit nothing at all**. Every gate in the tree is green on a circuit that
drops three measurements. §3.

**(H2b) AND THERE IS A SECOND ONE IN THE SAME EMULATION, VISIBLE ONLY OUTSIDE `main` — WHICH IS WHERE
ALMOST EVERYTHING ACTUALLY LIVES.** The same program in a `noinline` function (`b14`) emits
`ry(+0.5); ry(−0.5); cqrt_free` **per cell** — the spine un-prepares and frees the three qubits the
user is about to measure — with stage 2b reporting `1 verified, 0 violation(s), 0 unproven`. Inside
`main` it cannot happen: `FreePoint.cpp:182-183` short-circuits every handle to `Escaped`.

⚠ **I ASSERTED THE OPPOSITE OF THE TRUTH HERE AND MEASURED IT BEFORE SHIPPING IT (Rule 11), AND THE
CORRECTION MAKES THE FINDING HARDER, NOT SOFTER.** I wrote *"every e2e slice in this tree is
`main`-resident"*. **Measured over an 80-slice sample, compiled at `-O1` and attributed per defining
function: 4 have their quantum work confined to `main`, 10 confined to a non-`main` helper, and
**66 have it in both** — so 76 of 80 slices carry quantum work OUTSIDE `main`.** (`58 of 60` sampled
slices still define more than one function after `-O1` inlining; the house style is `slice()` called
from `main`.) **The `main` short-circuit is the exception, not the rule.** Consequence, and it is a
scope change rather than a nuance: without the D1 conversion of §5.2, a bank slice written in the
house style does not merely lose a safety net — **it DECLINES**,
`cq uncompute: tainted handle reaches an unrecognized user`, because the surviving bank store falls to
`FirstUnrecognized` (`FreePoint.cpp:226-227` → `:272-273`) and `Measure` is never set (the measurement
reads the LOAD, not the handle). **D1 is a precondition of the accept, not a polish item.** §5.2.

**(H3) THE `i8`/`i1` RESIDUAL IS ON THE CRITICAL PATH AND ITS SITE IS EXACT.** The carve reports
`abi=i8` for the owner's `_Bool` bank while the rail is `i1`, and the `zext i1 → i8` the C storage
type forces **sits inside the region arm**. Measured: with it there the arm classifies as a VALUE arm
and declines `cq controlled lowering: value-arm swap-route under quantum control` **anchored at the
`zext` itself**; with the merge φ retyped to `i1` and the cast gone, the same module gets past that
decline. §2.2.

**(H4) THE CAST CANNOT SIMPLY BE DELETED — THE PUN FENCE REFUSES THE RESULT.** `store i1` into an
`i8` cell makes `railBankCarveVerdict` answer **`NotBank`** (`QramLowering.cpp:1263`,
`StoreVal->getType() != CellTy`), whose retirement trigger says in writing that it and
`matchQramAccess`'s twin *"are one fence with two spellings … if either moves, the other moves in the
same change."* The measured design that satisfies both H3 and H4 **without touching that fence** is to
**SINK** the cast out of the arm to the activation-end store: measured `Bank`, `cells=3 abi=i8
trips=3`. §2.3.

**(H5) R2 (the D1 byte-identity measurement) IS ALREADY TAKEN, AHEAD OF THE ACCEPT.** `bool b0[3];`
and `bool b0[3] = {0};` produce **equal-sha256 gate streams** under the piece-3 emulation
(`ef75e8d7…`), and the bank's gate stream is **byte-identical** to Track I's flat twin
`w1_flat_prep_only.c` — which is exactly the 9-line stream the accept must reproduce, three measures
included. §4.

---

## 1. WHAT THE OWNER'S PROGRAM ACTUALLY NEEDS — measured, not inferred

### 1.1 The wall sequence

The owner's file (`example/grover/grover_oracle_uncompute.c`, code body reproduced verbatim as
`probes/b01_owner_verbatim.c`) hits **four** walls in this order. Each row is the decline the program
takes once the row above it is removed, on the ORACLE:

| # | decline (verbatim) | anchor | owner |
|---|---|---|---|
| 1 | `cq taint escape: tainted value stored to memory` | `store i8 %cq.bank, ptr %cq.bank.addr` | **W1, this track** (piece 3) |
| 2 | `cq controlled lowering: value-arm swap-route under quantum control` | `%27 = zext i1 %26 to i8` | **W1, this track** (piece 2 — H3) |
| 3 | `cq controlled lowering: control flow inside a loop body under quantum control` | `%24 = icmp sgt i32 %23, 2` | **NOT this track** — `iterationLocalRollable` **(c3)** |
| 4 | `cq loop lowering: loop-carried tainted value crosses iterations` | the header φ for `a` | **NOT this track** — X1 / bd `ej5w` / W3 |

Rows 3 and 4 are measured on the promoter's own output with rows 1 and 2 hand-removed
(`probes/README.md`, probes `B2`/`B3`/`B6`). Row 3's cause is exact and short:
`iterationLocalRollable`'s **(c3)** is `iterationLocalTaintEscape(L, Taint) == nullptr`
(`ArmClassify.cpp:3903`), and that function (`LoopLowering.cpp:4143-4158`) has **no exemption of any
kind** — *any* tainted instruction in `L` with *any* user outside `L` fails it. The owner writes
`cq_measure(a)` after the loop, and `a`'s per-trip value `%31 = select i1 %cq.bank, i32 %30, i32 %23`
is tainted and defined in `L`.

⚠ **Piece 1 does not change row 3's verdict.** The taint rule taints the three bank LOADS, which are
defined **outside** `L`; (c3) quantifies over values *defined in* `L`. So `B3`'s verdict is the
post-W1 verdict, not an artefact of the emulation.

### 1.2 The scalar control, which removes the bank from the question entirely

`probes/b02_scalar_measure_a_outside.c` is the owner's loop with an **iteration-local scalar `bool`**
and no array at all — no bank, no store, nothing for W1 to do. **It declines
`control flow inside a loop body`**, same conjunct, same reason. `probes/b05_scalar_classical_acc.c`,
identical except that the arm no longer feeds `a`, **ACCEPTS** (9 trace lines, STRICT 2b clean). **The
discriminator is the tainted loop-carried accumulator, and it is orthogonal to the bank.**

### 1.3 Why `wx8g` having landed does not settle it

`CLAUDE.md` §4c records `wx8g` as *"the IN-LOOP iteration-local rail and the retirement of the `l4x4`.b
carve-out."* It is landed and it is real — `b05` is one of its accepts. What it does **not** admit is
an iteration-local rail **beside** a loop-carried tainted register that is read after the loop. That is
the same family as `MERGE_FILINGS.md` §3's three surviving `il*` × `bcar` over-declines, and the
owner's program is a fourth member of it.

### 1.4 THE ORCHESTRATOR'S CHOICE — three options, costed

* **(A) Re-scope Track B to W1 and say so.** The second half lands, the headline does not compile, and
  the honest closing claim is *"the bank compiles; the owner's cascade needs W3."* W1's own accept
  shapes (§7.2) are real, gated, and byte-identity-witnessed (H5). **Recommended**, and it is the only
  option that does not put an unbudgeted second capability inside a Rule-13-core increment.
* **(B) Add W3 (`ej5w`, X1) to this session.** SCOPE_L1a §6.6 costs it at ~200–300 pass-source lines
  and **3 Rule-13 rounds**, and warns that **both** X1 sites must move together
  (`LoopLowering.cpp:2136` **and** the round-2 twin `:2579`) *"or round 2 re-declines what round 1
  accepted."* That is a second Rule-13-core capability **in `LoopLowering.cpp`** — which would put
  Track B into the S1 group with Tracks S′ and T, changing the gate topology this scoping otherwise
  reports as disjoint.
* **(C) Widen (c3) only.** Cheaper-looking and **not recommended**: it is a bare ACCEPT-direction
  relaxation of a conjunct whose own source comment (`LoopLowering.cpp:4432-4463`) records that the
  reason previously given for it was *measurably false* and warns a future widening off it by name.
  And it is insufficient on its own — row 4 is behind it.

⚠ **Whatever is chosen, it must be chosen before the implementation starts.** A track that lands
pieces 1–3 and then discovers row 3 will have spent its Rule-13 budget on the wrong subject.

---

#### ⚠ CORRECTION TO §1.4, dated 2026-09-15, landed at the orchestrator's instruction

Appended, not substituted. Two errors in the options above were found when the orchestrator pressed
this track for the numbers before putting the choice to the owner. **L7-with-a-twist: a record
correction that is not applied to the source is not a correction** — so they are landed here, in the
document a future reader will quote, and not only in the hand-off message.

**(1) Option (B)'s cost DID NOT INCLUDE (c3), and option (B) was therefore UNDER-STATED.** The
`~200–300 lines / 3 rounds` figure is SCOPE_L1a §6.6's **W3 row copied forward**, and that row is about
**X1 and nothing else**. Wall 3 needs the **(c3)** widening, which is separate work:

* **site** — `iterationLocalTaintEscape`, `LoopLowering.cpp:4143-4158`, **16 lines**, deliberately **one
  body with two callers** (`ArmClassify.cpp:3903` at round-1 taint, `LoopLowering.cpp:4489` at final
  taint), so widening the body moves both. **That half is cheap.**
* **cost** — **~150–250 pass lines, ≥2 Rule-13 rounds**, DERIVED not measured, calibrated against
  `94c085e` (one conjunct added to one F2 test, +231/−107).
* **why the expensive half is the ARGUMENT** — the principled widening is *"a tainted value defined in
  `L` whose only outside-`L` users are `cq_measure` sinks is not an escape"*, a bare **ACCEPT-direction
  relaxation of a Rule-13-core predicate** whose own source comment (`:4432-4463`) records that its
  previously-shipped rationale was **measurably FALSE** (F-W2-2) and **warns a future widening off
  leaning on it by name**.
* **why (c) and (b′) do not collapse into each other**, read off `ArmClassify.cpp:5163-5207`: clause (c)
  is asked **only when (b)/(b′) found nothing**, and (b′) searches `BaseWireOrder` — the **rotated
  register's** wire. The owner's rotated register is the fresh per-trip bank rail (a `StatePrep` from
  constant `false`), so **there is no header φ on it and (b′) can never grant**, whatever W3 does to `a`.
  Clause (c) is the correct clause; it fails at **(c3)**, which the file's own comment calls *"a ∀ OVER
  THE WHOLE LOOP, not over one register"*. **The owner's region is refused because of `a` — a register
  the region does not rotate** — so **(c3) still fails after W3 lands.**
* **ownership** — **UNFILED** at the time of writing. Filed 2026-09-15 as **bd `test_C_libtooling-8h7d.11`**
  under bd `8h7d`, deliberately **not** folded into bd `onq1`: `onq1` and the three `il*`×`bcar` cells are
  the same *family* but are filed as `wx8g` residue and none names (c3) or `iterationLocalTaintEscape` —
  and `onq1`'s subject is a decline **the twin matrix isolates**, where this one is **a conjunct the
  matrix cannot see**.

**(2) The live X1 site is the ROUND-2 TWIN `:2579`, not `:2136`.** Deduced from two measurements rather
than guessed: `B3` and `B6` differ **only** by the post-loop `cq_measure(a)`, an edit that changes
neither `%23`'s nor `%31`'s taint and does not touch the CFG — so `lowerLoops`
(`CQLoweringPass.cpp:455`, which runs **before** `detectControlRegions` at `:537`) behaves identically
on both, and **`B3` did not die there**. Therefore `B6`'s `kMsgCrossIter` comes from **`:2579`, inside
`collapseFlattenedLoopRails`** (`:555`), which is consistent with the orchestrator comment at `:541`
(*"`lowerLoops` above deliberately leaves a loop with IN-BODY tainted control flow to the control
chain"*). ⚠ **That is exactly the site SCOPE_L1a warns about** — *"both X1 sites must move together or
round 2 re-declines what round 1 accepted."*

**(3) THE FOUR-WALL TABLE IS NOT EXHAUSTIVE, and §1's presentation of it should be read accordingly.**
It is an ordering produced by **successive removal on a single program**, and `LLVMContext::diagnose`
**EXITS on the first `DS_Error`**, so every row is *"the first decline once the row above is gone."*
This track never had a binary on which walls 1 and 2 were genuinely absent, so **rows 3 and 4 are the
first two declines of an unknown-length tail.** There is **no evidence** about a wall 5 in either
direction, and this document must not be read as claiming there is none. **What would settle it:**
nothing short of a binary with W1 + (c3) + W3 actually present. **Round 1 of any future option-(B)
attempt should run the wall sequence forward on the real subject binary and REPORT THE LENGTH, not
assume four.**

**OWNER RULING, 2026-09-15 (`DECISIONS.md` E5): option (A).** W1's second half lands; the headline
waits; the honest claim is *"the bank compiles; the owner's cascade needs (c3) + W3."*

---

## 2. PIECE 2 — the type rewrite, and the `i8`/`i1` residual it has to own

### 2.1 What the promoter emits today (measured, `CQ_RAILBANK_DBG=1` on the owner's file)

```llvm
25: %26 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)   ; seed already the constant
    %27 = zext i1 %26 to i8                                    ; <-- IN THE ARM
28: %cq.bank = phi i8 [ %27, %25 ], [ 0, %21 ]                  ; <-- the i8 residual
    %29 = trunc nuw i8 %cq.bank to i1
    %31 = select i1 %29, i32 %30, i32 %23
    %cq.bank.addr = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %22
    store i8 %cq.bank, ptr %cq.bank.addr                        ; <-- kMsgStore fires here
```

`CQ_CTRL_DBG=1` prints `railbank [Bank] cells=3 abi=i8 trips=3`. **`abi=i8` is the C STORAGE width;
the rail is `i1`.** `RailBankShape::ElemAbi` is `abiWidthFromType(CellTy)` (`QramLowering.cpp:1426`)
and `CellTy` is the alloca's element type (`:465`). For `int b0[3]` the two coincide (`abi=i32`, no
cast — measured on `b11`); **the `_Bool` bank is the only `-O1`-floor spelling where they differ, and
it is the owner's.**

### 2.2 Why the cast cannot stay in the arm — MEASURED

| probe | shape | verdict |
|---|---|---|
| `B2` | promoter output, store removed, `zext` **in the arm**, `i8` φ | `value-arm swap-route`, anchored **at `%27 = zext i1 %26 to i8`** |
| `B3` | same, `i1` φ, no `zext`/`trunc` | past it — `control flow inside a loop body` (row 3) |

And the reason it matters beyond classification: `probes/b09_bool_zext_to_int.c` measures what a
tainted `zext i1 → i32` **lowers to** —
`cq_template_zext_i1_to_i32(h0) -> h1`, **a second rail**, with `h0` left allocated. A bank that let
its storage cast reach `lowerOps` would store a *different, entangled* rail from the one it rotated and
leak the original, once per cell.

### 2.3 Why the cast cannot simply be deleted either — MEASURED

`B8` (the "strip the casts, leave the alloca `[3 x i8]`" shape) makes the carve answer **`NotBank`**:
the **PUN FENCE**, `QramLowering.cpp:1263`, `if (StoreVal->getType() != CellTy) return NotBank;`. Its
header carries a **RETIREMENT TRIGGER, BOTH DIRECTIONS** (`:1256-1262`): it and `matchQramAccess`'s
`AccTy != CellTy` are one fence with two spellings, and moving either obliges moving the other in the
same change. **Do not.**

### 2.4 THE DESIGN — sink the cast, do not delete it and do not widen the fence

**(2a) In the promoter (`RailBankPromote.cpp`, `applyBank`).** Build the per-activation merge φ at the
**rail's own SSA type** and place the storage-extension cast at the **activation-end store**, not in the
arm:

```llvm
25: %26 = call i1 @cq_theta_i1(i1 false, double 0.5)
28: %cq.bank    = phi i1 [ %26, %25 ], [ false, %21 ]     ; rail-typed
    %cq.bank.i8 = zext i1 %cq.bank to i8                  ; SUNK to the store
    store i8 %cq.bank.i8, ptr %cq.bank.addr               ; StoreVal type == CellTy: fence untouched
```

**Measured on `B7`: the carve still answers `Bank`, `cells=3 abi=i8 trips=3`, anchored at the sunk
store.** This is the one shape that satisfies H3 and H4 at once.

* **decline string:** none — 2a is an ACCEPT-ONLY normalisation, and a cast it cannot express leaves
  the module byte-untouched for `kMsgStore`, exactly as every other B-clause does.
* **red-green:** `railbank_promote_bool_cell_cast_sunk.ll` (positive: the `i1` φ and the `zext` in the
  store's block, `CHECK`ed against the `CQ_RAILBANK_DBG` module dump) + a **mutation** that puts the
  cast back in the arm and must be CAUGHT.
* **retirement trigger:** *the cast sink exists so the arm classifies as a state prep and so the pun
  fence stays untouched. If `RailBankShape` ever carries the RAIL width as `ElemAbi`, or the pun fence
  learns a cast, re-derive this from scratch — the sink is then doing nothing and the cast is free to
  reach `lowerOps` and mint a second rail (measured: `b09`).*

**(2b) A new stage `rewriteRailBankCellTypes`, called between `lowerRotations` and `lowerOps`** —
`CQLoweringPass.cpp:774`→`:775` and the twin at `:1199`→`:1200`. ⚠ **This is NOT SCOPE_L1a §3(a)'s
slot** (*"after `lowerOps` and before `lowerMeasures`"*), and the change is deliberate: at §3(a)'s slot
`lowerOps` has already turned the sunk cast into `cq_template_zext_i1_to_i8`, which is the second rail
2a exists to prevent. The L1 argument is **unchanged and still sufficient**, because the new slot is
also strictly after `repropagateControlMerges` (`:571` / `:1115`), so the taint it reads is final.

It does exactly four things:

1. the bank `AllocaInst`'s allocated type `[N x CellTy]` → `[N x i32]` (handles; Rule 15 — a runtime
   handle is always `i32` at every width);
2. every bank access GEP's source element type → `[N x i32]`;
3. the store's value operand ← the `i32` handle (`lowerRotations`' cross-type RAUW has already put it
   there, one hop behind the sunk cast), and the sunk cast is **erased**;
4. every bank `load` rebuilt as `load i32`, its storage-**truncation** cast (`trunc i8 → i1`) RAUW'd to
   the loaded handle and erased.

Step 4 is what `lowerMeasures` requires: its quantum branch refuses a tainted operand that is not
`i32` (`MeasureLowering.cpp:235-237`, `kMsgOperand`).

* **decline string:** `cq rail bank: cell width has no reversible copy` is the carve's (C3, existing).
  2b itself must **not** be able to fail — it runs only on a shape the carve proved. Any inability to
  rewrite is a **bug**, not a decline, and should be an unconditional loud diagnostic with its own
  string so it can never be silent: `cq rail bank: cell type rewrite failed on a proven bank`.
* **red-green:** `railbank_types_i1_cell_measure.ll` / `…_i32_cell_measure.ll` (positives, pinning
  `cqrt_measure_i1` / `cqrt_measure_i32` and **no** `cq_template_zext_*` / `cq_template_trunc_*`
  anywhere) + a negative for an unsupported cell width.
* **retirement trigger, and it is the `21mg` sentence earned again:** *moving this call above
  `repropagateControlMerges` passes an `i32` HANDLE through the measure path as data. Moving it below
  `lowerOps` re-exposes the storage cast to `CastLowering` and mints a second rail per cell.*

### 2.5 A verifier blindness that must be written into the source

After `lowerRotations`, `store i32 %h, ptr %cq.bank.addr` into a `[3 x i8]` alloca is **well-typed** —
opaque pointers give a `store` no pointee constraint — so a 4-byte write into a 3-byte object is
`opt -verify` **clean**. Step 1 is therefore semantically load-bearing and *invisible to the
verifier*: Rule 2's exact shape. Say so at the stage.

### 2.6 The `memset`

A zero-initialised bank keeps its `llvm.memset` through promotion (measured, `b13`). It is admitted by
C1 (`QramLowering.cpp:1385-1398`, constant-zero and whole-object only). Step 1 changes the object's
size, so 2b must either rescale the length or **delete** the memset. **Deleting is sound and C6 is what
licenses it** — C6 totality says every cell is stored before any cell is loaded, so the fill is never
observed. Deleting also has the better failure mode: a rescaled memset writes handle `0` into every
cell, and **handle 0 is a live rail in this runtime** (`cqrt_alloc_i1(0) -> h0`), which is SCOPE_L1a
C6's own hazard sentence one stage later.

---

## 3. PIECE 1 — the taint rule

### 3.1 The site

`collectAndSeed` (`TaintPropagation.cpp:97`), i.e. inside `propagate` (`:471`). One rule: **a `load`
whose pointer resolves to an alloca carrying `!cq.railbank` is seeded into `out.Tainted` and onto the
worklist, at the bank's recorded RAIL width.** Because it is inside `propagate`, every re-propagation
carries it and `adjudicateTaintDelta` is not separately owed (SCOPE_L1a §3(c), and the same argument
`RailBankPromote.h` makes for the promoter's slot).

### 3.2 The metadata, and where it is minted — this is a real open choice

`!cq.railbank` **does not exist today**: `RailBankPromote.cpp:563` says in capitals that nothing is
minted, and `isRailBankAlloca` is not shipped (`trackA/SIGNATURE.md` deviation (2); the retired clause
B9 that claimed otherwise is **F-9**, §9).

The mint must happen **at or before `CQLoweringPass.cpp:196`**, because the `propagate` that the
promoter's fixpoint runs (`:197`) is the one that must see it, and no `propagate` runs after
`:372`.

**Recommendation: mint it in `applyBank`'s tail, i.e. ONLY when the promoter actually fires.** A bank
the carve calls `Bank` but the promoter refuses (a B-clause failure) then keeps `kMsgStore` — the safe
direction, and it keeps the accept exactly as narrow as the promoter's own proof.

* ⚠ **It must NOT bring back an `isRailBankAlloca` guard on the promoter's fixpoint.** F-9 is explicit:
  **B8** is what terminates the fixpoint (`applyBank` replaces every in-`L` load, so the next turn
  finds none), and the retired B9 asserted a mint that did not exist. Minting now does **not** make
  B9 correct; it makes B9 *redundant and dangerous* — a membership guard would mask a B8 regression
  that otherwise does not terminate.
* **the alternative, named rather than hidden:** minting from the CARVE instead would also tag
  `Bank`-but-unpromotable banks. That is a wider accept whose loads become tainted with no promotion
  behind them, and it is *not* recommended — but it is the shape to reach for if a later widening wants
  a bank with no in-loop load.

### 3.3 The negative this rule exists to close — REPRODUCED

`probes/emulate_piece3.sh probes/b12_bank_bool_measureloop.c` emulates **piece 3 alone**:

```
opt exit 0
free_pairing_check: 1 rail mint(s) of which 1 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven
cqrt_alloc_i1(0) -> h0 / cqrt_ry_i1(h0, 0x1p-1)
cqrt_alloc_i1(0) -> h1 / cqrt_ry_i1(h1, 0x1p-1)
cqrt_alloc_i1(0) -> h2 / cqrt_ry_i1(h2, 0x1p-1)
```

Three `cq_measure(b0[i])` in the source; **zero** measurements in the trace. `MeasureLowering.cpp:151`
takes the classical split on an untainted operand and emits *no gate, no symbol, no trace line*
(`:186-195`), and a golden byte-diff cannot see a measurement that was never emitted. **This is the
whole reason pieces 1, 2 and 3 land together**, and this trace is the artefact to put in the
increment's record.

* **red-green:** the positive is any accept slice whose golden carries `cqrt_measure_*`; the
  **negative that actually pins the rule** is a mutation — delete the taint rule and the accept
  fixtures' `CHECK: cqrt_measure_i1` must go red. Put it in the injection matrix, not in a `CHECK-NOT`.
* **retirement trigger:** *the day taint stops being SSA-only for any other reason, re-derive which of
  `declineTaintEscapes`' arms a bank load now reaches. Today it reaches none, because
  `readsTaintedValue` (`TaintPropagation.cpp:931`) is false for a load whose pointer is classical —
  a tainted load is not an escape, its CONSUMERS are.*

---

## 4. R2 — the D1 byte-identity measurement, DESIGNED **and already taken**

R2's obligation: D1 (the uninitialised `bool b0[3]`) does **not** inherit bd `z9t1`'s justification,
because `normalizeUndefRotationSeed` does not reach a memory seed; D1 rests on **C6 totality alone**,
a claim whose witness is future.

**Population.** Every accept the increment lands, paired with its written-`= {0}` twin. At minimum:
`b07`/`b08` (unconditional prep, constant-index measures), `b12`/`b13` (unconditional prep, measure
loop), and the slice pair of §7.2. **The pairing is by program, not by module** — the zero-init twin
carries an extra `llvm.memset` that the uninit one does not, so an IR diff is the wrong instrument and
the **trace** is the right one.

**Command** (after the accept; the emulation below is its rehearsal):

```sh
tests/e2e/run_slice.sh <slice>.c            # uninit spelling
tests/e2e/run_slice.sh <slice>_zeroinit.c   # written = {0} twin
diff <(...uninit trace) <(...zeroinit trace)      # MUST be empty
shasum -a 256 both                                 # MUST be equal
```

**Pass/fail.** Byte-identical traces ⇒ D1's refinement argument holds in the same form `z9t1` shipped
(*the emitted stream is what a written `= 0` produces*). **Any divergence returns D1 to the owner** —
it is a ruling, not an implementation detail.

**PRE-MEASURED, on the ORACLE, ahead of the accept** (`probes/emulate_piece3.sh`, which strips the
store and its cast from the promoter's own output and so does not touch the gate stream):

```
b12 (bool b0[3];)       6 trace lines   sha256 ef75e8d7936811dbaa9f600b4851feabd6dd03ea924fbaaccfabc3d50f34005a
b13 (bool b0[3] = {0};) 6 trace lines   sha256 ef75e8d7936811dbaa9f600b4851feabd6dd03ea924fbaaccfabc3d50f34005a
diff: empty
```

⚠ **What this pre-measurement does and does not witness.** It covers the **gate stream** and therefore
the whole of what C6/D1 is about (the per-cell seed). It does **not** cover the three measures, which
do not exist under the emulation — but the measures are generated from the loads, which are
bit-identical in the two modules. **The real measurement is still owed with the accept**; this one
removes the risk that it is taken for the first time at the end.

**And the target stream is known.** Track I's flat twin `w1_flat_prep_only.c` ACCEPTS on this ORACLE
with 9 trace lines, and the bank emulation's 6 gate lines are **byte-identical** to its 6 gate lines —
the three `cqrt_measure_i1` lines are exactly the delta piece 1 restores. That is the byte-identity
witness SCOPE_L1a §5 asked for, on an **identical-trip** program, per Track I §4.3.

---

## 5. PIECE 3 — the D5 allow-list, and the spine (D1/D6)

### 5.1 D5 — a POSITIVE allow-list, never a deny-list

SCOPE_L1a §4.4(A) calls D5 *"the one door with no fence anywhere"*: the loaded value is not recognised
as the same rail by `railOf`, `Freeable`, `Owned`, `Borrowed`, `D.Rails`, `D.FrozenRails`, `CondRails`,
`BaseWire`, `Gates`, `OnRailOut`, `ChainsByRoot` or `ClaimedRailRoots`.

**Site.** A new `declineUnallowedRailBankReaders`, called from inside `declineTaintEscapes`
(`TaintPropagation.cpp`, call site `CQLoweringPass.cpp:400` / `:1043`-equivalent). Living there buys
the round-2 re-ask for free: `adjudicateTaintDelta` (`:1782`) calls `declineTaintEscapes`, so L1's
PREDICATE species is discharged by **order plus an existing caller**, with nothing new to remember.

**The allow-list (the complete admitted set; everything else is a loud decline):**

1. a `cq_measure_<sfx>` call taking the load as its operand;
2. the load's **storage-truncation cast** (`trunc CellTy → RailTy`, `hasOneUse()`), whose single user
   is (1) — ⚠ **this entry is load-bearing and easy to miss**: at D5 time the cast is still present,
   because 2b has not run yet;
3. a further store into a `!cq.railbank` cell.

**Decline string (new):** `cq rail bank: unsupported reader of a rail-bank cell`, source-located on the
offending reader. It is a *reader* decline, not a store decline, so it must not reuse `kMsgStore`.

**Red-green, three negatives, one per shape SCOPE_L1a §6.1 names** — each mirroring the string
character-for-character, each a `RUN: not …`:

| fixture | shape | why it must decline |
|---|---|---|
| `railbank_reject_load_as_branch_cond.ll` | `if (b0[i]) …` outside the writing loop | `hasTaintedCondBranch` (`ControlDetect.cpp:80`) is blind to a memory-resident condition; without D5 the arm runs as classical code (SCOPE_L1a §4.4(D)) |
| `railbank_reject_load_as_gate_control.ll` | a bank load reaching a `cq_theta` arg-0 | `Chained` (`RotationLowering.cpp:299`) would read it as a SOURCE and re-prepare a live rail |
| `railbank_reject_load_into_arith.ll` | `s += b0[0] + b0[1]` | `lowerOps` would mint templates on a rail nothing owns |

⚠ **Fixture hygiene (Rule 12 defect (b)):** a `DS_Error` decline writes 0 bytes to stdout, so the
property is pinned by the `not` on the RUN line — IR-text `CHECK-NOT`s in these three are **vacuous**.
Run `…/session-2026-09-13-orchestrator/trackM/probes/impl/vacuity.py` over the new *accept* batch (and
note bd `jdec`: that script reports `checked 0` instead of failing — Track J is fixing it).

**Retirement trigger:** *the day a fourth consumer is admitted, ask what ELSE was computed over "the
only readers are measures" — `FreePoint`'s `Measured`/`Escaped` disposition (§5.2) is the first
dependant, and `free_pairing_check.py`'s `adjudicate_memory` is the second (bd `21re`, Track I).*

### 5.2 D1/D6 — the spine, and the reason it is not optional

`ChainWalk::isTerminalHandle` (`ChainWalk.cpp:757`) has `if (!CI) continue;` at `:765-768`, so a
`StoreInst` user is **silently skipped** and a stored rail **is** nominated as a dead terminal. What
happens next is decided in `computeFreePoint` (`FreePoint.cpp:165`):

* in **`main`** → `:182-183` short-circuits to `Escaped`. Silent, no adjoint, no free. **This is the
  disposition §4.2 wants, and every e2e slice gets it by accident.**
* **outside `main`** → the store falls to `FirstUnrecognized` (`:226-227`) → LOUD `kMsgUnrecognized`
  (`:272-273`). An **over-decline**, safe.
* **if anything ever deletes the store** → the rail is genuinely dead and the spine **adjoints and
  frees it**. **MEASURED** (`b14`, `noinline`): `ry(+0.5); ry(−0.5); cqrt_free` per cell, `opt` exit 0,
  2b `1 verified, 0 violation(s), 0 unproven`.

**Therefore:** teach `isTerminalHandle` to answer **false** for a handle satisfying
`railStoredToRailBank`, **and** teach `isRecognizedEscapeUser` (`FreePoint.cpp:93`) that a store into a
`!cq.railbank` cell is a recognised escape. The first is the load-bearing one (it stops the nomination
at source); the second removes the non-`main` over-decline.

`railStoredToRailBank` is the demand-driven structural predicate of SCOPE_L1a §4.3 — a query over the
handle's users at ask time, **never** a `Value *`-keyed owner set (`TaintPropagation.h:198-225` records
that spelling as a shipped silent miscompile), and the origin walk is **called**, not re-spelled
(Rule 14).

⚠ **The measurement that decides how urgent this is, and my own first answer to it was wrong.** I
assumed the `main` short-circuit covered every slice. **It covers almost none.** Sampled over 80
`tests/e2e/slice_*.c`, compiled `-O1` and attributed per defining function: **4** confine the quantum
work to `main`, **10** to a non-`main` helper, **66** to both — `76/80` carry it outside `main`, and
`58/60` still define more than one function after inlining. So the ordinary house style (`slice()`
called from `main`) lands a bank rail squarely on the non-`main` path.

**Therefore D1 is not defence in depth — it is a precondition of the accept.** Without it the canonical
W1 slice declines `cq uncompute: tainted handle reaches an unrecognized user`. Whether a given probe
sees this depends on whether `-O1` inlined the helper (measured on `b14`: without `noinline` the
quantum work moved into `main` and the question vanished), which is exactly the kind of accident that
makes a hazard look absent. **Write the non-`main` fixture (`railbank_accept_nonmain.ll`) AND a
`noinline` slice**, and do not let an inlined probe stand as evidence that the path is unreachable.

**D6** (the 5-way subtraction at `Uncomputation.cpp:1379-1382`, `:1583`, `:1588`, `:1598`;
`DagTraversal.cpp:192`/`:201`/`:212`; the 4-way one at `ArithLowering.cpp:967-969`) gets
`railStoredToRailBank` at **all** of them — L2: they were computed over one closure and move together.
⚠ `Uncomputation::preservesBorrowedParent` (`:588`) is **NOT** narrowed (L3; and its parameter is
`const CallInst *`, so it cannot see a store at all).

### 5.3 The classical-condition bank — a decline, and a crash that is one deletion away

A bank whose per-trip store is under a **classical** condition leaves a merge φ with one tainted and
one untainted incoming. `liftOneRegisterMergePhi` clause (2) (`TaintPropagation.cpp:1310-1313`)
requires **every** incoming tainted, so the lift refuses and `declineClassicalMuxes` declines
`cq taint escape: tainted value muxed by a classical-condition phi` — **measured** (`b06_f`). Safe.

⚠ **But if that φ ever becomes DEAD, the decline disappears and `opt` ABORTS.**
`declineClassicalMuxes` skips a `use_empty()` φ (`:1476-1477`, whose own comment calls a dead φ *"a pure live-range extender"*), `lowerRotations`' cross-type RAUW then
leaves `phi i8 [ i32 %h, … ]`, and the run ends in
`report_fatal_error("Broken module found")` — **measured twice** (`b06_e`, `b06_e_i8`), once in each of
the `i1` and `i8` spellings. In the shipped design the store is always the φ's user so this is
unreachable; **pin it with a fixture and a retirement trigger**, because "the store keeps the φ alive"
is a premise a future DCE can falsify silently.

---

## 6. R1 and R3 — D3's deferred question, and where the decline lives

**R1 restated, correctly.** `MERGE_FILINGS.md` carries it: *"a 'does not reach the fence' answer is
true of the binary and FALSE of the capability."* At `74eabd2c` no binary can put a bank rail in front
of `staleRailRecordRead`, because the bank population dies at `declineTaintEscapes`, above
`lowerLoops`, and `LLVMContext::diagnose` EXITS on the first `DS_Error`.

**What changes when this track's accept lands: less than it looks.** The bank store stops declining,
so a bank module reaches `lowerLoops`. But `staleRailRecordRead` reasons over rail records **grouped by
ROOT MINT**, and a bank LOAD is not a member of any group and cannot become one without a `LoadInst`
arm in `peelInPlaceStep` (`LoopLowering.cpp:298-321` — there is none anywhere in the file).

**So D3's ruled decline is realised by NOT WIDENING, and it costs zero lines in `LoopLowering.cpp`.**
The refusal that actually stands in front of the question is **D5** (§5.1): a bank load whose consumer
is anything but a measure or a further bank store is a loud decline, and every route by which a bank
value could reach a rail record passes through one of those consumers.

**What the measurement becomes for Rule-13 round 1 — say it in these words, not the old ones:**

> *Construct a module in which a bank load reaches `staleRailRecordRead`. If you cannot, say which
> predicate stopped you and whether it is D5 or something else. If D5 is the only thing standing in the
> way, then `(alloca, index SCEV)` is still unbuilt and still owed by the increment that admits a
> fourth D5 consumer — not by this one.*

**R3** (the corpus residue) is the merge-and-gate agent's, unchanged.

---

## 7. THE TEST PLAN

### 7.1 Fixtures (`ir-pass/test/`) — ~17 files, of which **3 are re-spellings** (§8)

**Positives (~7):** the promoted bool bank at N=3 and N=1000 (K-independence, measured **without
`-g`**); the `int`-cell bank ⚠ **with a MEASURE LOOP, not constant-index reads** (§10 item 4); the
cast-sink shape (2a); the type-rewrite shape (2b, pinning `cqrt_measure_i1` and **no**
`cq_template_zext_*`/`trunc_*`); the **non-`main`** accept (§5.2, mandatory); the zero-init twin.

**Negatives (~7):** the three D5 shapes (§5.1); the 2b internal-failure string; the dead-φ crash pin
(§5.3); a `RejectWidth` cell; the classical-condition bank's `kMsgClassicalPhi`.

⚠ Counts go in their **own whole-file prefix** — a positive `CHECK-COUNT` inside a negative prefix
windows every negative after it (Rule 12 defect (a)). A bare `-NOT: <word>` can match the module's own
path line (bd `qta2`). A 0-byte `.ll` module **ACCEPTS** through the passthrough early-out — check
every probe is non-empty before scoring it.

### 7.2 Slices, goldens, ctest — **+4 slices, +5 goldens, +6 entries**

| slice | golden | note |
|---|---|---|
| `slice_railbank_bool_prep_measureloop.c` | ✓ | the canonical W1 accept; its golden **must equal** `w1_flat_prep_only`'s 9-line stream (§4) |
| `slice_railbank_bool_prep_measureloop_zeroinit.c` | ✓ | the **D1/R2 twin**; plus a `compare_files` gate over the two traces |
| `slice_railbank_bool_prep_constidx_measures.c` | ✓ | the owner's measure spelling (`cq_measure(b0[0]) + …`) |
| `slice_railbank_int_cells_measureloop.c` | ✓ | the width axis |
| — | ✓ (5th) | the flat twin `w1_flat_prep_only` as the **byte-identity partner**, if not already registered |

**+2 ctest entries beyond the four slices**: the twin `compare_files` gate and the K-independence pin.
**Every slice runs STRICT stage 2b** (no `--allow-unproven`), and **every slice header must carry the
§5 sentence that 2b counts `cqrt_alloc` SITES, so a rolled per-trip alloc reads as ONE rail** —
SCOPE_L1a §5's instrument row. `tests/e2e/CMakeLists.txt` has ONE tail anchor; expect a conflict per
slice-adding branch and run the three post-union checks.

⚠ **AND E4's OBLIGATION CANNOT BE CHECKED AS WRITTEN — a measured finding.** `DECISIONS.md` E4 says
the slice must be *"byte-identical in its code body"* to the owner's file and records the orchestrator
as having *"verified 2026-09-15: the live code body matches the session brief's reproduction
exactly."* **It does not.** The owner's file carries a trailing space on the blank line inside the loop
(source line 89) and a **double** space in `cq_measure(b0[1])  + cq_measure(b0[2])` (line 130); the
brief's reproduction normalises both. They match **semantically**, not byte-for-byte. The owner's
active body is also **not contiguous** — lines 83–95 then 129–131, with 34 lines of commented-out
earlier spellings in between — so "the code body" needs a definition before it can be diffed.
`probes/b01_owner_verbatim.c` is built from the owner's bytes and carries the exact recipe
(`sed -n '83,95p;129,131p'`, `diff` empty) in its header. **Either state the normalisation in E4, or
have the landing slice carry that `sed` recipe in its own header so a future reader can re-take the
diff.** A drift mitigation that cannot be executed is not a mitigation.

⚠ **Owner ruling E4 — the slice IS the record.** `slice_railbank_owner_cascade.c` must carry the
owner's code body **byte-identical** to `example/grover/grover_oracle_uncompute.c` as measured at
session open, and its header must say so and name that path. ⚠ **Under option (A) of §1.4 that program
still DECLINES**, so it cannot be registered as an accepting slice: register it the way
`slice_control_switch_phase.c` (2026-09-05) and the two bd-`3d8q` conversions (2026-09-14) were —
**kept, unregistered, with a conversion header and an L8 retirement trigger naming `ej5w` by name**,
and **no golden**. bd `zwtm` then closes only when W3 lands. Say that in the closing record rather than
letting `zwtm` look closed.

### 7.3 Twin matrix

No new cells are needed for W1's own accepts (they are not in-loop *control*; the loop carries no
tainted region). SCOPE_L1a §6.3's 16–24-cell bank axis belongs with W3, not here. ⚠ If option (B) is
taken, it comes back in full and `e2e-loop-twin-matrix` (~180–400 s) becomes the long pole.

---

## 8. F-3 — the three re-spellings, measured against the REAL carve

All three pass lit today and **none of them isolates its clause any more**, because the real carve
refuses them before the promoter's B-clause is asked. Measured
(`CQ_CTRL_DBG=1 CQ_RAILBANK_DBG=1`, ORACLE):

| fixture | clause it claims to isolate | what refuses it TODAY |
|---|---|---|
| `railbank_promote_reject_two_cells.ll` | **B2** (one cell per activation) | carve `RejectTotality` — `cq rail bank: array has cells no iteration writes` |
| `railbank_promote_reject_store_outside_loop.ll` | **B5** (one writer) | carve `RejectAlias` — `cq rail bank: array is written from more than one store site` |
| `railbank_promote_reject_inloop_other_read.ll` | *"nothing non-rewritable inside `L`"* | carve `RejectTotality` — same string as the first |

Their `NOTS-NOT: CQ_RAILBANK_DBG: promote bank` checks are **vacuously** satisfied: the promoter never
runs.

**The re-spelling requirement, stated as a property rather than as a patch:** each must be a module the
**real** carve calls `Bank` (assert it positively with `DBG: CQ_CTRL_DBG: railbank [Bank]`, which is
byte-ABSENT on the ORACLE and so non-vacuous) and the **B** clause must be the sole refuser.

* **B2:** keep the store at `b[i]` (so C6 totality holds) and put the *second address* on a **load**
  in the same activation. The carve admits an in-loop load access; B2's SCEV-equality-over-addresses
  question then fires alone.
* **B5: this one may be UNFIXABLE, and the reason is structural rather than a spelling problem.** C4's
  second half refuses `Stores.size() != 1` unconditionally (`QramLowering.cpp:1435-1439`), and a bank
  whose *only* store is outside any loop is `NotBank` at `:1265-1267` (`Loop *L = LI.getLoopFor(SI->getParent()); if (!L) return NotBank;`). So **every** module
  that could exercise B5 is refused earlier — B5 is **shadowed**, which is **F-2's finding one clause
  over** (the unreachable multi-store `SSAUpdater` path). ⚠ Do not paper over it with a hand-IR module
  that only *looks* like a B5 subject. **Either delete B5 with a recorded argument, or keep it and
  convert the fixture to a decline whose header states — in the L8 retirement-trigger form — that its
  subject is unreachable and which widening would restore it.** Bring this back through the
  orchestrator; it is a scope question, not a fixture question.
* **inloop_other_read:** same recipe as B2 — make every cell written, keep the non-rewritable in-loop
  construct.

**Then re-run the injection matrix against the real carve.** The 22-mutant matrix that reported
`MISSED 0` mutated the **shim's** clauses; for these three cells it measured a binary that no longer
exists. ~22 rebuilds, the implementation row's gate.

---

## 9. F-9 — four record sites that are HISTORY

`IMPL_B.md` **§2.3, §7, §8 and §10.1** carry the retired clause-**B9** wording — *"NOT ALREADY
PROMOTED (`isRailBankAlloca` — the `!cq.railbank` record this stage MINTS)"*. `RailBankPromote.cpp:563`
contradicts it in capitals, the `.h` was corrected at the 14c gate, and `isRailBankAlloca` is not
shipped. **These four sites are history and must not be cited as design.**

⚠ **And this increment makes half of that wording TRUE AGAIN, which is the trap.** Piece 1 mints
`!cq.railbank` (§3.2). **It still does not license B9**: B8 is what terminates the fixpoint, and a
membership guard would *mask* a B8 regression rather than back it up. When the mint lands, the four
`IMPL_B.md` sites must be marked with a dated note saying *the mint is back and the guard is not* —
not silently left to look prescient. `CLAUDE.md` L7-with-a-twist: a record correction that is not
applied to the source is not a correction, and this is its mirror — a source change that resurrects
half of a retired record.

---

## 10. WHAT I COULD NOT TURN INTO A PREDICATE SITE

1. **The E-exempt spine measurement.** `probes/emulate_piece3.sh` **deletes** the bank store; the real
   design **exempts** it. So `b14`'s adjoint-and-free trace is evidence about *store-deleted*, and the
   store-kept disposition (`FreePoint`'s classification with a `StoreInst` user present) is
   **unmeasurable on any binary that exists**. I read it out of the source
   (`FreePoint.cpp:195-228` → `FirstUnrecognized` → `cq uncompute: tainted handle reaches an
   unrecognized user`, unless `main` or `Measure`) and I could not execute it. **Round 1 must measure
   it, and must be told that "I could not reach it" is not an answer** — R1's lesson, third instance.
   ⚠ And it must measure it **outside `main`**: `b14` showed that without `noinline` the helper is
   inlined and the question disappears, and §5.2's sample says 76 of 80 slices are in the outside-`main`
   population.
2. **Whether the type rewrite's four steps are exhaustive.** I enumerated the bank's IR surface from
   four measured `-O1` shapes (`_Bool`/`int` × constant-index/measure-loop). I have **no proof** the
   set of bank-touching constructs is closed; C1's user scan is the nearest thing to one, and it is a
   *carve* predicate asked of the alloca's users, not a *rewrite* predicate asked of everything the
   rewrite must retype. Step 1 changing the object size without the verifier noticing (§2.5) is what
   makes an omission here silent. **Make 2b enumerate from C1's own user scan and fail loudly on
   anything it did not expect** — never `continue`.
3. **The grouping key for `staleRailRecordRead`.** Unchanged from SCOPE_L1a §8 item 2: `(alloca, index
   SCEV)` is a proposal, not a measurement, and §6 explains why nothing in this increment forces it.
4. **A C-level `int`-cell bank with constant-index measures.** `probes/b10` declines
   `cq rail bank: array mixes a rail cell access with an unrecognized one`: at `-O1` clang emits the
   constant-index reads of an `[3 x i32]` array as **byte-offset geps** (`getelementptr inbounds i8,
   ptr %1, i64 4`), which `railBankCellAddress`' cell-type agreement refuses. The `_Bool` bank escapes
   this only because its cell type *is* `i8`. So SCOPE_L1a §6.1's *"`int` cells"* positive **must** use
   a measure loop (`b11`, measured `Bank abi=i32`). I could not tell from measurement whether the
   byte-offset gep is worth admitting or is correctly refused, and **I did not widen it** — it is a
   separate, costed question.
5. **Whether the sunk cast changes the ARM classification in the store-present module.** I measured the
   two ends (`B2`: cast in the arm ⇒ value arm; `B3`: no cast ⇒ past it) and the carve's verdict on the
   sunk shape (`B7`: `Bank`). I could **not** measure `classifyArms` on a module that has *both* the
   sunk cast and a surviving store, because the store declines first and `diagnose` exits. The
   inference is sound (the cast leaves the arm) but it **is** an inference. Measure it on the subject
   binary in round 1, before anything else.
6. **Everything about option (B).** If W3 is added, none of the X1 reasoning in §1 is mine — I measured
   *that* X1 fires and *where*, not what it would take to make it not fire.

---

## 11. COST

| item | count | basis |
|---|---|---|
| pass-source lines | **~450–700** | SCOPE_L1a §6.4's calibration, scaled down: the promoter, the carve and the classifier already exist (the 14c landing was the `b6ap`-shaped part). What remains is one new small TU (2b), one taint seed, one allow-list, two spine predicates and the cast sink. Compare `59ac5b7` (+463/−74) and `94c085e` (+231/−107) |
| new fixtures | **~14** | §7.1 |
| re-spelled fixtures | **3** | §8 (F-3) — ⚠ one of the three may be unfixable |
| slices / goldens / ctest entries | **+4 / +5 / +6** | §7.2 |
| twin-matrix cells | **0** | §7.3 — and 16–24 if option (B) |
| injection-matrix rebuilds | **~22** | F-3's re-run against the real carve |
| **Rule-13 rounds** | **4** | §12 |

---

## 12. RULE-13 BUDGET — four rounds, each with a named subject

`CLAUDE.md` budgets three and then records the measured hit rate that says otherwise; SCOPE_L1a §6.5
already argued four for W1 as a whole, and the second half is the half that **creates the memory-
resident subject**. Do not merge rounds.

* **Round 1 — the two measurements this scoping could not take.** §10 items 1 and 5, in that order, on
  the subject binary; plus §6's restated D3 question **in its restated words**. Nothing else.
* **Round 2 — the taint rule's blast radius.** Every consumer a bank load can reach that D5 does not
  name. Attack the allow-list with the three shapes of §5.1 *and* with shapes nobody listed: a bank
  load into a `phi`, into a `select`, into a `freeze`, into a second `cq_measure` of a different width,
  into a `ret`. The lesson to carry in: L4 — *a wire question must be a gate SET, not a BOOLEAN over a
  return-first walker*; D5 must enumerate the load's users and take the difference, never stop at the
  first bad one.
* **Round 3 — the type rewrite against the verifier's blindness.** §2.5 and §10 item 2. The question is
  not *"does it verify"* (it will) but *"is every bank-touching construct retyped"*. Mutate: leave one
  gep at the old element type and check that a gate goes red. If none does, that is the finding.
* **Round 4 — the spine, outside `main`.** §5.2, and specifically the claim that a second half which
  changed nothing in the spine would pass every gate this tree can run. L2: when you widen *"what can
  be a rail"*, ask what other set was computed over the same closure — D6's five subtraction sites are
  that set.

⚠ **The measured hit rate says round 4 finds something.** 7.4 `break` found three of its thirteen holes
in a round that ran **after** the epic was closed as cleared; 3qlq Inc 1 found its eighth on one
function in a round reviewing a *different* increment. Budget the fourth round before the first.
