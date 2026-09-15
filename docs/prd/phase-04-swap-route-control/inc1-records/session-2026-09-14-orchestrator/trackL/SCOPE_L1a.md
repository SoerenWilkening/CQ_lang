# SCOPE — L-1a, the bounded rail ARRAY (bd `xdu2`): an implementable design

Session 2026-09-14, **READ-ONLY scoping**. Every verdict below was measured on the frozen **ORACLE**
`build/ir-pass/cq-opt` sha256 `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc` /
`libCQPass.so` `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d` (built from `59ac5b7`;
hash verified before the first probe and unchanged after the last). **No build, no `lit`, no `ctest`,
nothing written outside `$SES/trackL/`.** Line numbers are as of `main` `607b6fe4`. Probes and the
driver: `probes/`, `probes/run.sh`; gate lines: `GATES.md`.

`$PREV` = `…/session-2026-09-13-orchestrator/`. Companion of record: `$PREV/trackL/SCOPE_loop.md`
(the 37-probe survey this document supersedes for spelling (i)).

---

## 0. HEADLINE — three measured corrections to bd `xdu2`, and one citation fix

**(H1) The wall list is THREE, not one — and the other two are already-filed, unbuilt beads.**
`SCOPE_loop.md` §1.1 states *"for spelling (i) the wall list is **exactly one item long**, and behind
it sit Tracks M and R's walls, not new ones."* **That is true of the HAND-UNROLLED twin and false of
the rolled program.** Measured by peeling the store out of the customer in C (`L1_promoted_nostore.c`
— the loop body in exactly the post-promotion form the carve must produce, with no array at all):

| # | wall | string (verbatim) | site | owner |
|---|---|---|---|---|
| **W1** | the tainted store | `cq taint escape: tainted value stored to memory` | `TaintPropagation.cpp:526` (`kMsgStore`), fired at `:924`, reached through the QRAM carve switch at `:876-893` | **L-1a — this document** |
| **W2** | the in-loop **ITERATION-LOCAL state prep** | `cq controlled lowering: control flow inside a loop body under quantum control` | `ArmClassify.cpp:4396-4397` (R7's loop half, `if (!Rollable)`) — anchor measured as `%6 = icmp sgt i32 %5, 2`, the prep region's own condition | **bd `wx8g`** (unbuilt) |
| **W3** | the in-loop **VALUE arm** on the carried register `a` | `cq loop lowering: loop-carried tainted value crosses iterations` | `LoopLowering.cpp:2106-2110` (`tryCaseA`'s X1) **and its round-2 twin `:2548-2553`** in `collapseRailPhisIn` | **bd `ej5w`** (L-4, unbuilt) |

W2 is not a surprise to the source: `ArmClassify.cpp:4266-4271` says it in writing —
*"R7's LOOP half below is deliberately NOT skipped: it iterates `BaseWireOrder`, which is empty here,
so `Rollable` stays false and **every in-loop state prep declines `control flow inside a loop body`** —
the ITERATION-LOCAL spelling."* A rail that lives in a bank cell has **no header φ**, so
`railPhiRootMint` (`LoopLowering.cpp:360`) finds no mint and `Rollable` can never become true by the
existing clause.

W3 is masked today and its ORDER is explained by a measured gate: `tryCaseA`'s **(L2)** at
`LoopLowering.cpp:2051-2060` returns `false` (leaves the loop unclaimed) whenever the body has **any**
tainted conditional branch — which the prep region is. So X1 is unreachable while W2 stands. Peel the
region away and X1 fires: `L3_uncond_prep_value.c` and, independently, `L6_good_prep_value_arm.c` (the
already-ACCEPTING `p2` in-loop shape plus one `if (b) a -= 3;`) both print `kMsgCrossIter`.

> **The consequence for planning, stated plainly (brief §2f asks for exactly this): L-1a alone does
> not compile the owner's loop cascade.** `xdu2`'s scope — the carve — clears W1 and hands the program
> straight to `wx8g`, which `CLAUDE.md` already records as an over-decline whose *"cost is **total**
> today"*. The owner asked for *"a large loop where MANY of those controlled operations are applied"*;
> the deliverable for that sentence is **L-1a + `wx8g` + `ej5w`**, in that order, and the honest cost
> is the sum (§6).

**(H2) The unrolled twin exists at N=2 and ONLY with a compile-time-constant seed.**
`a_flat_n2.c` **ACCEPTS on this ORACLE** — exit 0, 115 lowered lines, 29 trace lines, STRICT stage 2b
`8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`
— and its gate stream is **byte-identical to the shipped golden
`tests/e2e/slice_control_cascade_two_bools.expected.log`** (the only diff is the position of the single
`cqrt_measure_i32` line, because the probe measures `a` first). The `L8` retirement trigger in that
probe's header fired character-for-character. `a_flat_n3.c` still declines
`state prep seed is proven equal to the condition register` (bd `om35` / this session's Track F).
And `L13_flat_n2_opaque_noinline.c` — the same program with `a` an opaque parameter — **declines
`control flow`** at `%8 = select i1 %6, i32 %7, i32 %0`. Discriminated by `L14`/`L15`: the cause is the
**opaque seed**, not the select's arms. With `a = 5` constant, `-O1` folds trip 0's `a >= 3` away
entirely and there is **no region and no merge φ** (measured: the const-seed twin's `@slice` is four
instructions). So the shipped N=2 accept is *"one folded region + one genuine prep"*, and the rolled
form is *"one genuine prep, K times"* — **they are not the same circuit and cannot be byte-compared**
(§5).

**(H3) The carve is a PER-ACTIVATION PROMOTION, not an element-type rewrite — and `-O1` itself proves
the target form is legal.** `xdu2` clause 5 says *"the alloca's element type is rewritten to the handle
type and the `store`/`load` pair carries handles."* Measured, that is not sufficient, because in the
raw customer the cell is read **twice** per trip and the second read is **partially available**:

```llvm
; a_loop_n3.c at -O1 (verbatim, blocks 8 and 14)
8:   %9  = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5
     %10 = load i8, ptr %9                      ; the SEED  (cell never written yet)
     %11 = trunc nuw i8 %10 to i1
     %12 = tail call zeroext i1 @cq_theta_i1(i1 %11, double 5.000000e-01)
     %13 = zext i1 %12 to i8
     store i8 %13, ptr %9                       ; ← W1 fires HERE (col 26)
14:  %15 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5   ; SAME address
     %16 = load i8, ptr %15                     ; handle on the arm edge, SEED on the pred edge
     %17 = trunc nuw i8 %16 to i1
     %19 = select i1 %17, i32 %18, i32 %6
```

A naive element-type rewrite makes `%16` load **`0` as a handle** on the pred edge — and `h0` is a real
rail in this runtime. The correct reading of `%16` is *the region's merge φ*, which is why the
hand-unrolled twin is Track M's program. So the carve must **forward the cell to SSA within one
activation**, which yields exactly what `-O1` emits for the equivalent source
(`L1_promoted_store.c`, verbatim):

```llvm
10:  %11 = phi i1 [ %9, %8 ], [ false, %4 ]     ; the MERGE φ Track M's leaf grammar wants
     %13 = select i1 %11, i32 %12, i32 %6
     %14 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5
     %15 = zext i1 %11 to i8
     store i8 %15, ptr %14                      ; EXACTLY ONE store per trip, at the trip's end
```

`clang -O1` produced that module from C, so it is not a hand construction: it is the **stock `-O1`
shape of the same program**, and the carve's job is to move the raw spelling onto it. Everything after
the promotion is SSA and the existing control chain applies unchanged.

**(H4) Citation corrections (Rule 11).** `xdu2` cites *"`QramLowering.h:56-60` `qramCarveVerdict`
routes classical-index/value-tainted stores to the generic `kMsgStore` decline by name"*. Verified:
`:56-63` is **`DeferControl`**; the `NotQram` bullet that names *"a classical-address / **value-tainted**
store"* is **`QramLowering.h:53-55`**, implemented at `QramLowering.cpp:985-987` (`if (!taint.Tainted.count(PtrOp)) return QramCarve::NotQram;  // classical-address access (value-tainted store → generic kMsgStore; out of QRAM scope)`). Two more:
`matchQramAccess` is **file-local to an anonymous namespace at `QramLowering.cpp:446`** and is *not*
exported, so "call it" (Rule 14) means exporting it or co-locating the new classifier in that TU; and
`abiWidthFromType` lives at **`OpcodeSupport.cpp:230`** (decl `OpcodeSupport.h:92`), not in
`WidthDispatch.cpp`.

---

## 1. The customer, and what it denotes

```c
int a = 5; bool b[N] = {0};
for (int i = 0; i < N; ++i) { if (a >= 3) b[i] = cq_theta(b[i], .5); if (b[i]) a -= 3; }
int s = cq_measure(a); for (int i = 0; i < N; ++i) s += cq_measure(b[i]);
```

A first-success cascade with a kept history, one fresh qubit per trip. At N=3 the branches are
`000/001/010/100` with `a = 5/2/2/2` and amplitudes `c³, c²s, cs, s` (`c = cos .25`, `s = sin .25`);
norm checks (`SCOPE_loop.md` §0.2). **N-independence of W1 re-measured on this ORACLE**: identical
string, identical site at N=2, N=3, N=8, with the value arm deleted, and with the prep made
unconditional (`a_loop_n{2,3,8}`, `a_loop_n3_noarm`, `a_loop_n3_uncond`). `-O1` stamps
`!{!"llvm.loop.unroll.disable"}` (verified: metadata `!14` on `a_loop_n3`) and at N=8 the module still
contains exactly one `@cq_theta_i1` call — **no constant N scalarises the array**.

---

## 2. §2a — The accept predicate, clause by clause, as code sites

Seven clauses. Five are `xdu2`'s; **two are new and both are Prime-Directive load-bearing** (C2′ and
C6). Every one is a measured decline today; the probe that measures it is named.

| # | clause | the question, and the predicate that answers it | site to call / extend | measured negative |
|---|---|---|---|---|
| **C1** | a **non-escaping** `alloca` of a bounded static element count | *does this pointer resolve to one statically-shaped array object with no other user?* — `walkPtrOrigin` (rejects `isArrayAllocation()` VLAs and non-`ArrayType` allocated types → `kMsgQramDynN`) + `isDirectOriginPtr` (provable zero net base offset) + the alloca-WIDE user scan that admits only access GEPs, a **constant-zero `llvm.memset`** and lifetime markers | `QramLowering.cpp:316` (`walkPtrOrigin`), `:371` (`isDirectOriginPtr`), `:1936-1975` (`processShadowAlloca`'s user scan — the reusable non-escape proof; `kMsgQramEscape` `:1934`/`:1974`, `kMsgQramMixed` `:1943`, `kMsgQramInit` `:1953-1971`) | `N1_vla_bound.c` (VLA), `N2_escaping_array.c` (address passed to an opaque callee), `N3_global_array.c` (a global, not an alloca) — all three `kMsgStore` today |
| **C2** | every access is a **classical-index** in-bounds GEP; a TAINTED index keeps 7.5's decline | *is the trailing GEP index tainted?* — the axis is enforced by **one already-existing parameter**: `matchAddressGep(..., requireTaintedIndex)` at `QramLowering.cpp:398`, decisive line `:421-422` `return !requireTaintedIndex \|\| taint.Tainted.count(RawIndex);`. L-1a calls it with `requireTaintedIndex=false` (already exercised by `qromReadShapeInScope` `:1167-1169`) **and then requires the negation**: a tainted index must fall to the QRAM owner | `QramLowering.cpp:398-433`; in-bounds by `qromIndexKnownInBounds` `:685` | `N4_tainted_index.c` → `cq QRAM access: array address has aliasing fan-out` (7.5's own string, on 7.5's own path) — **the axes are already separated and stay so** |
| **C2′** | **NEW — INJECTIVITY.** the index must be an affine add-recurrence of the enclosing loop with unit step whose range over the proven trip count is injective and within `[0, N)` | *can two activations write the same cell?* If yes, a later trip's **seed** load reads a previously-stored HANDLE, and the promotion of C5 forwards the wrong value. Answer with SCEV: `SE.getSCEV(RawIndex)` is a `SCEVAddRecExpr` for this loop, `isAffine()`, step `+1`, start `0`, and the loop's **constant** max trip count `≤ N`. ⚠ Read the constant-max BTC as an **APInt at its own width** and add the reachability-total conjunct — `CLAUDE.md` Rule 18 records `getSmallConstantMaxTripCount` returning `4294967295` on some vacuous bounds and `0` on others, so **neither return value distinguishes vacuity** | new; the SCEV handle already in the file is `hasFiniteClassicalTripBound` (`LoopLowering.cpp:1239`, uses `getSymbolicMaxBackedgeTakenCount`) — **that is the 7.4 break path and is not this**; do not reuse it, cite it | `N5b_noninjective_var_index.c` (`b[i>>1]`, four trips over two cells) — `kMsgStore` today, must become a NEW named decline. `N5_double_write.c` (constant index) degenerates: `-O1` SROAs it into scalar spelling (ii) and it takes the §3c clobber (bd `x5fp`) — a **degenerate probe**, do not use it for this clause |
| **C3** | the stored **value** is tainted and the cell has an ABI width | *is the rail's width one the runtime can copy?* — `abiWidthFromType` (`OpcodeSupport.cpp:230`) then **`widthHasReversibleCopy`** (`OpcodeSupport.cpp:267`, `{i1,i8,i16,i32,i64}`). ⚠ **NOT `.empty()`** — `OpcodeSupport.h:88-91` is explicit that `i128` has a width string and no reversible copy. ⚠ `matchQramAccess` **never looks at `StoreVal`** except for the pun fence at `:476-484`; the value-side taint + width test is genuinely new code | `OpcodeSupport.cpp:230` / `:267`; the pun fence to copy is `QramLowering.cpp:476-484` | `L8_array_int_cells.c` (`int b[3]`) is an **accept-side** probe, not a negative: it takes the same `kMsgStore` today, so the width axis is untested at the wall. Owed: an `_BitInt(96)` / `long double` cell negative |
| **C4** | no aliasing fan-out, no mixed classical/quantum use of a cell | *is this GEP's sole user this memop, and does the whole alloca have one shape?* — `matchQramAccess`'s `GEP->hasOneUse()` at `QramLowering.cpp:467-469` (the aliasing fence) + the C1 user scan's `kMsgQramMixed` arm. **CALL `matchQramAccess`, do not re-spell the provenance walk** (Rule 14; the drbq Inc-3 (b′) precedent) — which means **exporting it**, see H4 | `QramLowering.cpp:446-517`, decisive `:467-469`, `:485-489` | a two-GEP alias probe is owed (not written — it is off the `-O1` floor and needs hand IR) |
| **C5** | **the PROMOTION** (`xdu2`'s "element type rewritten … store/load carry handles", restated as what it must actually do) | per activation, forward the cell to SSA: replace the **seed** load with the proven initializer constant; replace every intra-activation load with the dominating store's value (an SSA merge φ where the store is conditional); leave **exactly one** store per activation, at the activation's end. §3 gives the staging | new; model it on `MergePhiPeel.cpp` (a pre-detection NORMALISER, not a lowering) and on `QramLowering.cpp:2034-2120`'s collect-then-mutate discipline | `L1_promoted_store.c` is the **target shape as SOURCE** and `-O1` emits it verbatim; `a_loop_n3.c` is the input shape |
| **C6** | **NEW — TOTALITY.** every cell of the bank is stored before any cell is loaded, and `N` equals the proven trip count | *what does a load of a never-written cell return?* After the type rewrite, the memset-zero cell reads as **handle `0`** — which is a live rail in this runtime (`cqrt_alloc_i1(0) -> h0`). Either prove totality or decline. With C2′'s `{0,+,1}` index and a constant trip count equal to `N` and no early exit, it holds | new; the loop's exit structure is `taintedExit` (`LoopLowering.cpp:1073`) for the no-quantum-exit half | `bool b[8]` with `for (i<3)` is owed (over-sized bank) |

**The carve/emitter discipline (the `isRecognizedIOSink` / `qramCarveVerdict` clause).** Copy **QRAM's
realization, not IOSink's.** QRAM's is structural — one function `qramCarveVerdict`
(`QramLowering.h:69-73`) called by the carve at `TaintPropagation.cpp:882`, and the same
`matchQramAccess` called by both emitters (`QramLowering.cpp:521`, `:532`). IOSink's is a **comment
claim**: the carve at `TaintPropagation.cpp:783-787` re-spells `isRecognizedIOSink`'s three conjuncts
inline with a comment at `:775` asserting they match. For L-1a: one new public entry point beside
`qramCarveVerdict`, in the **same TU** so it can call the file-local `walkPtrOrigin` /
`matchAddressGep` / `isDirectOriginPtr` without exporting them, consulted by the carve **and** by the
promoter **and** by the type rewriter.

---

## 3. §2c — The ROUND-2 (L1) question, answered in full

Control detect+lower runs **twice**: round 1 at `CQLoweringPass.cpp:455` / `:942`, the fixpoint
`repropagateControlMerges` at `:489` / `:948`. The three L1 questions:

**(a) Where does each piece run?** L-1a is **three pieces at three slots**, and separating them is what
makes the round-2 answer trivial rather than fragile:

| piece | slot | why |
|---|---|---|
| **the PROMOTER** (C5) | inside the existing `-O1`-repair normaliser fixpoint, `CQLoweringPass.cpp:217-314` — the `while (X(M, taint)) taint = propagate(M, wd);` family (`promoteVolatileScalarLocals` `:217-218`, `promoteFp80Union` `:235-236`, `flattenPredMuxRegions` `:259-260`) — i.e. **before `detectSpecializations` `:329` and before `declineTaintEscapes` `:338`** | it is a NORMALISER. The idiom re-runs `propagate` **from scratch** after every change, which is strictly stronger than a taint delta, so **`adjudicateTaintDelta` is NOT owed** and no consumer guard has run yet. Mirror at `:835-892` for `runOnFunction` |
| **the CARVE VERDICT** (C1–C4, C6) | `declineTaintEscapes`, `TaintPropagation.cpp:876-893`, a second switch beside the QRAM one | a **pure predicate**. `adjudicateTaintDelta` (`TaintPropagation.cpp:1609`) re-runs `declineTaintEscapes` at `:1645`, and `repropagateControlMerges` goes through it — so the carve is **asked again at the fixpoint automatically, in both entry points**. A relaxation here is symmetric by construction |
| **the TYPE REWRITE** (`[N x i1]` → `[N x i32]`, loads become handles) | **after `lowerOps` `:646` and before `lowerMeasures` `:647`** | the handles do not exist until `lowerRotations` `:645`. `lowerMeasures` must see the handle-typed load |

**(b) What does it compute that a later stage consumes over a premise round 2 can falsify?**
The promoter computes **nothing a later stage consumes**: it rewrites IR and hands the result to a full
`propagate`. The carve verdict is re-asked. **The type rewrite is the one piece with a window**, and it
is closed by ORDER, exactly as bd `21mg` closed `lowerMeasures`: it runs after the fixpoint, so the
taint it reads is final. ⚠ **RETIREMENT TRIGGER, write it into the source:** *moving the bank type
rewrite above `repropagateControlMerges` passes an `i32` HANDLE through the measure path as data* —
the same sentence `21mg` earned.

**(c) Does it GROW the taint set?** **Yes, in one place: the bank `load`.** Today taint is SSA-only
(`propagateWorklist`, `TaintPropagation.cpp:374`, walk at `:381` — there is no load/store rule, and the
`StoreInst` itself joins `Tainted` as a *user* while nothing reaches the later load). The measure loop
reads cells written by a **different** loop, so no promotion can forward it. The minimal honest
extension is **one rule**: *a `load` from a `!cq.railbank` alloca is tainted, with the bank's recorded
ABI width.* Because it is added inside `propagate` itself, every re-propagation carries it and
`adjudicateTaintDelta` is again not owed.

> ⚠ **This is the one clause that moves a documented invariant, and it must go to the owner as such.**
> `control_classical_call_arm_reject_localarray_store.ll:6-8` states the current doctrine — *"Storing a
> QUANTUM HANDLE into memory is NOT reachable… taint is SSA-only"* — and pins itself as *"the PERMANENT
> SAFE over-decline (Prime Directive). NEVER lowered."* **L-1a does not retire that fixture** (its index
> `%i` is a function argument with no enclosing loop ⇒ C2′ fails; its array has no zero initializer ⇒ C1
> fails; it is off the `-O1` floor by its own header), but it *does* narrow the doctrine the header
> states, and the header must be amended rather than left to contradict the code.
>
> ⚠ **And one factual claim in that header is FALSIFIED by measurement.** It says the store→load
> forwarding is *"UNREACHABLE on the clang `-O1`/`-O2`/`-O3` validated floor — GVN already forwards
> every provably-same-address round-trip before cq-lowering runs."* `a_loop_n3.c` at `-O1` is a
> counterexample: `%9` and `%15` are the same address and `%16` is **not** forwarded, because the store
> is **partially available** (it is in the conditional arm). The claim holds for fully-available stores
> only.

---

## 4. §2b — The FENCE, spelled: what "a stored rail is FROZEN" must mean, and where

### 4.1 The structural fact that frames it

**The rail/wire/uncompute machinery is memory-blind by construction.** `Uncomputation.cpp`,
`ChainWalk.cpp`, `DagTraversal.cpp`, `FreePoint.cpp`, `EmitInverse.cpp`, `WireWalk.cpp`,
`OpcodeLowering.cpp`, `CondTreeEmit.cpp`, `SelectClassify.cpp`, `SwapRouteEmit.cpp`,
`ControlDetect.cpp` and `RotationLowering.cpp` contain **zero** memory tokens
(`StoreInst`/`LoadInst`/`AllocaInst`/alias); `ArmClassify.cpp`'s single hit in 7224 lines is inside a
comment. The asymmetry that matters: **a `store` is visible as a non-`CallInst` USER** (every walk has
a default branch for it, and the defaults differ per site), **a `load` is invisible everywhere** — a
loaded handle is a fresh `Value *` denoting the same physical rail and nothing relates the two.

### 4.2 The disposition the fence must produce — and it is NOT `FrozenRails`

A bank rail is **stored, then loaded in another loop, then MEASURED**. In the flat twin that rail is
measured through its SSA name and `FreePoint` returns `Measured` (`FreePoint.cpp:261-262`) — **no
adjoint, no free**. The bank form must reach the same disposition. Therefore:

* **NOT `DagTraversal::FrozenRails`** (`DagTraversal.h:80`, seeded `DagTraversal.cpp:414-418`, read at
  the single site `Uncomputation.cpp:329`). Its documented semantics are the opposite of what is
  needed: `DagTraversal.h:70-74` — *"A frozen rail IS still fully reverse-played. The freeze suppresses
  the FREE and never an adjoint — dropping the adjoint breaks invariant (d) for every surviving rail
  that READS the frozen one, which the bd 261j(a) Rule-13 round measured as four separate hidden
  measurements."* A bank rail must **not** be reverse-played: the user measures it.
* **The correct disposition is ESCAPED** — the same class as `ret` / `cq_invert_*`
  (`FreePoint.cpp:267-268`), reached by making the rail refuse to be a terminal at all.

### 4.3 The representation — a metadata membership record, not a `Value *` set

**`TaintPropagation.h:198-225` forbids the obvious spelling, and it is a recorded silent miscompile:**
*"THERE IS NO `ControlledRotationRails` MEMBER, AND ITS ABSENCE IS THE FIX… That is a PRE-`lowerOps`
SSA value… `lowerOps` — the very NEXT pipeline stage — RAUWs to a `cq_template_*` result and ERASES.
The set then held a dangling pointer… `opt` exit 0, verify-clean, a hidden measurement (Rules 6/8).
MEASURED on 5 of 5 out-of-place base opcodes… Read that function's header before re-introducing any
`Value *`-keyed owner set for this fact."*

The two shapes that survived review are (F1) a **demand-driven structural predicate**
(`ChainWalk::railCarriesControlledRotation`, `ChainWalk.cpp:329` — derives the rail from the gate's
use at query time, so it cannot go stale) and (F2) a per-recovery DAG set. **Use F1's shape**, keyed on
**IR metadata on the `AllocaInst`** — the `!cq.branchphase` pattern (`markBranchPhaseGate` /
`isBranchPhaseGate`), which is already this project's answer to "a durable membership record that no
RAUW can dangle":

```
!cq.railbank on the AllocaInst      (minted by the promoter; carries the element ABI width)

railStoredToRailBank(Value *H) :=  any user U of H such that
      U is a StoreInst, U->getValueOperand() == H,
      and walkPtrOrigin(U->getPointerOperand()) is an Alloca carrying !cq.railbank
```

No set, no dangling pointer, no address reuse, askable at any stage, and the origin walk is
**called**, not re-spelled (Rule 14).

### 4.4 The enumeration — every SSA-wire-keyed fence, how it learns, and which way it fails today

Read the **failure** column first: `SILENT` means the fence does not see the rail and therefore does
not protect it; `LOUD` means it declines (safe, and usually an over-decline to convert).

**(A) The spine — the six doors a stored rail can enter**

| door | site | today | what L-1a owes |
|---|---|---|---|
| **D1 — the rail nominated as a dead TERMINAL** | `Uncomputation.cpp:1571` `collectTerminalCandidates` → `ChainWalk.cpp:757` `isTerminalHandle`, whose user loop `:765-768` does `if (!CI) continue;` — **a `StoreInst` user is silently skipped, so a stored rail IS nominated** → `FreePoint.cpp:165` `computeFreePoint` | **LOUD** `kMsgUnrecognized` (`FreePoint.cpp:272-275`, string `:37-38`) — **except** in `main` (`:182-183` short-circuits to `Escaped`) and when the rail is also measured (`:261-262` returns `Measured` **before** the `FirstUnrecognized` check). `TaintPropagation.cpp:917-922` already names that hole: *"Both are bypassed by the Phase-5 net when the handle is ALSO measured… so the decline must happen HERE, pre-lowering."* | **the one fence to convert.** Teach `isTerminalHandle` to answer **false** for a handle satisfying `railStoredToRailBank`, and teach `FreePoint`'s user classification that a store into a `!cq.railbank` cell is a **recognized escape** (`Escaped`, silent) while a store anywhere else stays the loud `kMsgUnrecognized` |
| **D2 — an INTERIOR candidate** | `Uncomputation.cpp:1385` `isInteriorTerminalHandle` (`ChainWalk.cpp:918-923`, `if (!CI) return false;`, comment names *"a `store`"*) | **SILENT skip** (fail-closed → leak) | nothing; record that it is safe by accident and pin it |
| **D3 — a BORROWED PARENT** | `Uncomputation.cpp:1148-1153` (the only spine site that acknowledges a non-call user; its comment: *"a `store` escapes it… leak rather than guess"*) | **SILENT leak** (safe) | nothing; pin it |
| **D4 — upstream in a recovered DAG** | `DagTraversal.cpp:233` closure scan → `:347 D.NotClosed = true;` | **SILENT** (safe) | nothing; pin it |
| **D5 — a `load` re-materialising the handle** | **nowhere.** The loaded `i32` is not recognised as the same rail by `railOf`, `Freeable`, `Owned`, `Borrowed`, `D.Rails`, `D.FrozenRails`, `CondRails`, `BaseWire`, `Gates`, `OnRailOut`, `ChainsByRoot` or `ClaimedRailRoots` | **UNSOUND and SILENT — the one door with no fence anywhere** | the load is tainted by the new propagation rule (§3c) and its **only** admitted consumers are `cq_measure_<sfx>` and a further bank store. **Every other consumer of a bank load is a LOUD decline**, enumerated positively (an allow-list, never a deny-list) |
| **D6 — the ownership subtractions** | the 5-way subtraction at `Uncomputation.cpp:1379-1382` (+ `:1583`, `:1588`, `:1598`), `DagTraversal.cpp:192`/`:201`/`:212`, and the **4**-way one at `ArithLowering.cpp:967-969` (`lowerLateReassignments` — already missing `railCarriesControlledRotation`, 4 of 5) | n/a | add `railStoredToRailBank` at **all** of them. ⚠ L3 applies: `Uncomputation::preservesBorrowedParent` (`:588`) must **NOT** be narrowed — it asks a different and sound question, and its parameter is typed `const CallInst *` so it cannot see a store at all |

⚠ **Place the freeze at the D1/D6 sites, never at `EmitInverse::isInverseEmittable`
(`EmitInverse.cpp:41`) and never inside `FreePoint`'s reversal logic** — `FreePoint.cpp:85-86` says in
writing *"The freeze is decided in DagTraversal step 3b and executed in
`Uncomputation::emitDagReversal`. Do NOT mirror it here."*

**(B) The loop layer — the choke point is one peel**

`peelInPlaceStep` (`LoopLowering.cpp:298`; `:300-307` `dyn_cast<CallInst>` + `GateCalls.count`,
`:308-320` `BinaryOperator`, `:321 return nullptr;`) has **no `LoadInst` arm anywhere in the file**, so
a bank load is its own base, and **14 call sites read `nullptr` as "not a rail."** `GateCalls` is
seeded only from `taint.ThetaCalls ∪ PhiCalls` (`:3686-3688`, `:3573-3575`).

| fence | site | today | owed |
|---|---|---|---|
| **`collectRailGates`** — computes the `Gates` set **and** the `OnRailOut` set in one walk | `LoopLowering.cpp:890`, `noteGate` `:905-914`, forward walk `:920-979`, the only walk line `:922 for (User *U : V->users())` | **SILENT under-collection in BOTH sets at once** — a `StoreInst` user matches no arm, is skipped at `:971-972`, and the closure terminates at the store and resumes nowhere. This is the **F-1/F-3 pair of confirmed silent miscompiles verbatim** (`:757-885`, `LoopPlan.h:186-224`) | **the L2 obligation in its sharpest form.** Four set families move together or not at all: `Gates`, `OnRailOut`, the `MemberSet` skip set (`:1045`) and step-5's `Skip` (`:2806-2807`). `LoopPlan.h:220-224` says explicitly the skip set and the record set must stay different |
| `staleRailRecordRead` | `LoopLowering.cpp:1042`, decisive `:1063-1065`; LOUD at its 3 call sites `:2303-2307`, `:2692-2696`, `:2808-2812` | delegates to `collectRailGates` ⇒ blind. ⚠ **Grouped per ROOT MINT** (`ChainsByRoot` `:2525`, `ByRoot` `:2296`) — **a bank rail has no root mint, so it cannot be grouped at all** | a bank rail needs a grouping key. `b[0]` and `b[1]` are **distinct rails sharing one alloca** — the mirror of the shared-mint alias case the fence was built for (`:2512-2523`). Key by `(alloca, index SCEV)`, or refuse loudly |
| `markIfRailLocal` | `LoopLowering.cpp:3465`; `onRail` `:3481-3484`; M4 `:3505-3508` | **SILENT `return;`** — `onRail(Op)` is false for every load, nothing is marked, the K-per-trip leak stands | ⚠ **`:3526-3537` is a RETIREMENT TRIGGER aimed at exactly this increment**: *"Widening it — even 'just' to admit a hoisted loop-invariant temp — makes [K adjoints vs ONE forward gate] reachable, and **no shipped test would go red**."* Re-derive it in writing |
| `invariantRegisterRootsImpl` | `LoopLowering.cpp:3221`; cands `:3242 for (Value *Op : I.operands())`; `:3337-3339 dyn_cast<CallInst>(Root)` | **SILENT `return false`** — and this is where a bank rail costs the most: a load peels to itself, `:3337-3339` fails, and the **entire extension returns false, taking every other register's discharge down with it** (the shape of finding F-C1-2(2a), `:3295-3311`) | a bank-rail root must be admitted or the whole function must decline — never a silent global `false` |
| the tainted-index memory triple | `LoopLowering.cpp:1975-1978` (`tryBreak`), `:2411-2414` (`markIfIterationLocal`), `:3505-3508` (`markIfRailLocal`) | ⚠ **the load-bearing asymmetry**: all three scan `I.operands()`. For `store i32 %h, ptr %gep` the operand list is `{value, pointer}`, so **the tainted value IS caught — by accident**, since all three are written and commented as tainted-*index* guards. For `%h = load i32, ptr %gep` the only operand is the pointer, never tainted, so **the load side never fires** | do not "tidy" these to scan the pointer operand only — that makes all three blind in both directions |
| `recordRefreshedByDef` | `LoopLowering.cpp:661`, `:663-665` non-φ ⇒ `return true` | ⚠ **SILENT and in the UNSAFE direction** — a load-defined record gets `true`, and the header at `:655-659` says `false` is the safe default; `true` enables the cut at `:718-721` that *removes* declines | an explicit load arm returning `false` |
| `loopHasInPlaceRailStructure` | `LoopLowering.cpp:2452` (exported `LoopPlan.h:349`; consumer `LoopUnrollPrepass`) | returns **false** for a bank rail ⇒ the force-unroll pre-pass would consider the loop free to unroll | check against `llvm.loop.unroll.disable`; an unrolled bank changes the circuit |

**(C) `ArmClassify.cpp` — the condition side (this is what `b[i]` becomes)**

| fence | site | today | owed |
|---|---|---|---|
| `condProvenance` | `:280`, `:297-307` backward operands only | **SILENT** — a load's only operand is its pointer, so the cone is **empty**. It is the completeness carrier for R4 *and* (since `drbq.14`) for **F2's `CondWire`**; its header `:264-279` warns that narrowing it *"makes R4 VACUOUS with every fixture still green"* | after the promotion this is moot **inside** the loop body (the condition is the merge φ, pure SSA). It is live for any bank load used as a condition — which the D5 allow-list must **refuse** |
| **`railWireClosure`** | `:525`, forward `:551-560`, backward `:563-598` | **SILENT** — a `LoadInst` matches no arm and falls off the loop body at `:598`; a `StoreInst` is not a `forwardRailHop` (`:454`). `CondRails` and `BaseWire` become **disjoint by construction** ⇒ R4 vacuous, R6 blind | ⚠ **`f2SeedPinnedByLiveRegister`'s RETIREMENT TRIGGER at `:1283-1295`**: *"if `railWireClosure` as called here and R4's `CondRails` ever DIVERGE… this narrowing must be RE-DERIVED FROM SCRATCH."* **Teaching `railWireClosure` a memory hop trips it.** Do not teach it one; refuse at D5 instead |
| gate **2c** `wireGainsNonDiagonalGate` | `:1890`, decisive `:1914-1915` | **SILENT** — doubly blind (empty seed cone *and* a memory-blind walker). `CLAUDE.md` calls 2c *"the live fence in front of almost everything"*; on a memory-resident wire it returns clean | same: refuse at D5 rather than widen the walker |
| the §13.3 **rail ladder**, all three rungs | `:3261-3263` (i), `:3265-3270` (ii), `:3355-3363` (iii) — all gated on `RailCond = isCondRailLeaf(Region.Condition)` at `:3226`, and `isCondRailLeaf` (`SelectClassify.cpp:627`) requires a `CallInst` named exactly `cq_theta_i1` | a `load i1` can never be a rail leaf ⇒ **LOUD, with the wrong string** | after the promotion the condition is a φ, which Track M's `isCondRailPhiShape` (`SelectClassify.cpp:635`) already admits for the select consumer |
| `railMeasuredBeforeReadPoint` (rung ii) | `:2269`, via `railWireNamesBackward` `:2188` whose walk **terminates at `:2256-2258` `if (!CI) break;`** | **SILENT** — a program that stores a rail, measures it via its SSA name, reloads and controls on it **passes rung (ii)** at all four call sites (`:3265`, `:5344`, `:5798`, `:2440`) | D5's allow-list closes it |
| `markRailCondRead` / `reverifyRailCondReads` | `:2449` / `:2551`; ⚠ `:2571-2573 dyn_cast_or_null<CallInst>(E.first) … continue` **silently drops a non-`CallInst` rail** | SILENT skip | ⚠ **the 6 `markRailCondRead` call sites are all OUTSIDE this file** (`CondTreeEmit.cpp:83`, `:248`; `SwapRouteEmit.cpp:939`, `:960`, `:1731`; `AngleSelectEmit.cpp:217`). **A seventh emitter minted by L-1a re-opens F-B1R2-1 with no diagnostic anywhere** (`ArmAnalysis.h:203-219`). L-1a should mint **no** emitter — §5 |
| **R4** (rotation arm on a condition wire) | `:4273-4285` | **SILENT** — both sides are `railWireClosure`; two closures that cannot cross memory never intersect. `CLAUDE.md` measures R4 firing on **0 of 27** rivals today *because 2c stands in front*; if 2c also goes silent, nothing is left | the promotion keeps both sides in SSA, so R4 stays live. **Measure this explicitly** — it is the clause most likely to be quietly vacated |
| **R6** (no post-region read of the pre-Ry record) | `:4409-4488`, walk `:4414-4415` | **SILENT** — SSA users only. Its own header `:4287-4295` claims it is stricter than `declineStaleRecordOps` because *"a `cq_measure`, a `ret`, **a `store`**… declines"* — true only for a store of a value already in `BaseWireOrder` | the fence that most directly implements *"never in-place rewritten / record never read as a live wire"*, and the one L-1a most needs. The promotion keeps it live inside the body; a bank load feeding anything but a measure must be D5-refused |
| **R7** (the W2 wall) | `:4375-4397`, `if (!Rollable)` at `:4396` | **LOUD** — `BaseWireOrder` is empty for an iteration-local prep, `railPhiRootMint` never runs, `Rollable` stays false | **bd `wx8g`.** The widening L-1a needs is a sixth clause: *`Rollable` is also true when the rotated register is an ITERATION-LOCAL rail whose handle is stored into a `!cq.railbank` cell* — there is nothing to roll, because the rail is fresh per activation and frozen |
| **F1 / F2** | `inPlaceRotationArmTheta` `:798`, `StatePrep` decided at `:821-822` (`!Taint.Tainted.count(arg0)`); F1 `:3876-3957`; **F2** `f2SeedPinnedByLiveRegister` `:1454`, `f2Model` `:1060`, the test `:1682-1684` | after the promotion the seed is the initializer **constant** ⇒ `StatePrep` **TRUE** ⇒ the F1/F2 block runs, which is the measured behaviour (`L1_promoted_nostore` reaches R7, which is downstream of F1/F2) | ⚠ if the design instead lets the arm's theta read a **tainted** bank load, `StatePrep` goes FALSE and **the whole F1/F2 block `:3786-4163` is skipped** while R4/R6 run blindly. That is a silent-accept configuration — **another reason the promotion, not a load-typed seed, is the design** |
| §3c clobber | `diagonalAliasHit` `:326`, consumed `:4656` | `cq_phi` arg-0 chain only ⇒ SILENT null for a bank rail | not L-1a's (it is bd `x5fp`, the scalar spelling) |

**(D) Elsewhere**

| fence | site | today | owed |
|---|---|---|---|
| `hasTaintedCondBranch` | `ControlDetect.cpp:80`, `:82` (and `:260`, `:785`, `:803`, `:864`) | ⚠ **the headline silent failure if taint is let across memory without the promotion**: `br i1 %load` is untainted ⇒ **not a control region at all** ⇒ the arm runs as classical code | the promotion makes the branch condition SSA again; D5 refuses a bank load as a branch condition |
| `lowerMeasures` | `MeasureLowering.cpp:132`, split at `:151` | ⚠ **a major silent hole**: `cq_measure(b[i])` on an **untainted** load lowers to the classical value — no gate, no symbol, **no trace line** — and the golden byte-diff cannot see a measurement that was never emitted | the D5 rule makes the bank load tainted **before** `lowerMeasures` runs. **This is the single most important reason the taint rule and the type rewrite must land together** |
| `Chained` | `RotationLowering.cpp:299` | `taint.Tainted.count(Op)` — a theta on an untainted bank load is silently reinterpreted as a **SOURCE** | coincidentally the desired behaviour after the promotion (the seed *is* classical), but it must be **proved**, not inherited |
| `declineClassicalMuxes` | `TaintPropagation.cpp:1253`, `:1289-1316` | SILENT — `SelectInst`/`PHINode` only; a load out of the array *is* a mux over memory it never sees | covered by the promotion + D5 |
| `inPlaceFenceHolds` (M-C G3–G7) / `priorUseIsSettled` | `ArithLowering.cpp:630` / `:560`, clause (e) at `:562-563 if (!CI) return false;` | ⚠ **ALREADY FAIL-CLOSED** on a store — one of the few fences that does **not** need to learn the freeze | verify and pin; do not change |
| `armWritesMemory` (P10) | `MergePhiPeel.cpp:154`, called `:377-378` | **SILENT skip (no peel)** for `if (a>=3) b[i] = cq_theta(...)` — its arm holds a store. Its header `:139-141` says the stage *"today knows nothing about memory at all"* and *"a merge whose arm WRITES MEMORY belongs to the 7.5 owners"* | ⚠ **a direct obstacle**: the promotion must run **before** `MergePhiPeel` (it does — `:217-314` vs `:451`), and after it the arm holds **no** store, so P10 stops refusing. Verify by measurement, and amend the header |
| `LiteralIntegrity` | `LiteralIntegrity.cpp:192`; note `:193-201` | already warns that *"one static slot is one materialisation… is measurably false inside a rolled loop, where one static slot is read once per trip"* | cite it in the slice header |
| two **crash sites** if the leaf grammar is widened carelessly | `ArmClassify.cpp:6855 cast<CmpInst>(Cond)` (unchecked) and `MeasureLowering.cpp:181-184`'s typed-RAUW guard (the `replaceAllUsesWith` type assert is compiled out in Release) | — | do not widen a leaf grammar to admit a `LoadInst`; refuse at D5 |

### 4.5 The L2 answer, in one line

**When you widen "what can be a rail", these set families were computed over the same closure and move
together or not at all:** `collectRailGates`'s `Gates` **and** `OnRailOut` (`LoopLowering.cpp:905-914`,
`:975-976`); the `MemberSet` skip set (`:1045`) and step-5's `Skip` (`:2806-2807`) — which
`LoopPlan.h:220-224` says must stay **different**; and on the ArmClassify side R6 (`:4415`),
`railWireNamesBackward` (`:2256-2258`), `railWireClosure` (`:563-598`) and `reverifyRailCondReads`
(`:2571`). **The recommended design's answer to all of them is the same: do not widen any of them.**
The promotion keeps the loop body in SSA so every one of these fences stays live on its existing terms,
and the only new object — the bank load — is confined by a positive allow-list (D5) whose complement is
a loud decline.

---

## 5. §2d — The instruments: which witnesses what, and the two blind spots

| instrument | sees | does NOT see | verdict for L-1a |
|---|---|---|---|
| **the golden e2e trace** (the only layer that LINKS) | **every one of the K per-trip `cqrt_alloc`/`cqrt_ry` lines**, the angles, the control/target order | rail identity at a free | ⚠ **this is the primary witness for this increment — the reverse of the usual division of labour.** Say so in every slice header |
| **stage 2b `free_pairing_check.py`** | rail identities, `|0⟩`-at-free | ⚠ **counts `cqrt_alloc` SITES**, so a rolled per-trip alloc reads as **one** rail left allocated when the circuit mints K. Already structurally blind to template-minted rails | **do not cite 2b as clearance here.** Put the sentence in the slice header, not in the review |
| ⚠ **`free_pairing_check.py`'s own premise** | — | — | **`tools/free_pairing_check.py:1259 provably_not_a_rail` carries a load-bearing assumption L-1a falsifies**, in the docstring at `:1292`: *"A handle cannot reach a global and come back — a tainted `store` is a loud decline at `declineTaintEscapes` long before lowering — so a load result is not a rail."* After L-1a a bank `load i32` **is** a rail handle and `provably_not_a_rail` returns `True` (`:1308`) for it, so any rule that reads it as a classical immediate — e.g. a bank load passed as a **control** to `cqrt_copy_i32_controlled` — could discharge a free it should not. **The checker must learn the bank, or the increment must keep the premise true.** This is a Rule-13-class instrument finding, not a nicety |
| **`e2e-loop-twin-matrix`** (288 cells at the time of this scoping: `grep -c '^m_' tools/loop_twin_matrix.expected.txt` = 259 + `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` = 29) | ⚠ **the only thing in the tree that can see a leaked TEMPLATE-minted rail** | a `_Bool` condition — `grep -c bool tools/loop_twin_matrix.py` = **2**, both inside `phi_surface_of_header`; **every one of the 288 cells is blind to it** | **applies and is not optional**, but it needs the `_Bool` axis built first (`SCOPE_loop.md` §2.6). See §6 for the cell count. ⚠ **ANNOTATED 2026-09-14 (closing docs pass): THIS ROW IS STALE AS A MEASUREMENT AND CORRECT AS A DIAGNOSIS.** bd `uq96` (`49b7f7bc`) built that `_Bool` axis the same day: the matrix is now **338 cells** (309 + 29, re-measured at `66428ddc`) and 50 of them carry an `i1` register. The blind spot this row named is the one the axis closed; do not re-quote the `288` / `= 2` figures as current |
| **rolled == hand-unrolled byte identity** | a per-iteration mint that should have been hoisted, a gate dropped on the back edge, an ancilla reused across trips | — | ⚠ **NOT available for the owner's literal program.** With `a = 5` constant, `-O1` folds trip 0's condition in the *unrolled* spelling and cannot in the rolled one (H2), so the two streams legitimately differ. With an opaque `a` the unrolled twin **declines** (`L13`). **The byte-identity gate must therefore be built on a program whose every trip is identical and whose flat twin lowers** — or replaced by K-independence + a per-trip multiset argument, labelled as an INTERNAL-CONSISTENCY gate in the `slice_control_cascade_select_in_loop_outside_prep_unrolled_twin.c:11-15` style. ⚠ **ANNOTATED 2026-09-15 (Track A, routing item R4): THIS ROW'S VERDICT STANDS AND ITS STATED GROUND MUST NOT BE READ AS *'the N=3 twin does not exist'*.** §7's N=3 bullet is HISTORY — bd `om35` landed and `a_flat_n3.c` ACCEPTS on the 2026-09-15 ORACLE (exit 0, 147 lines, measured). The two reasons this row is still correct are independent of that: the H2 constant-fold asymmetry, and `L13_flat_n2_opaque_noinline.c` still declining `cq controlled lowering: control flow under quantum control` on the same ORACLE (re-measured). See the erratum at §7 |
| **K-independence of the lowered IR** | that the loop was rolled, not unrolled | anything about the unitary | measure **without `-g`** (debug metadata inflates the count and a `-g` number is not comparable — `SCOPE_loop.md` §3) |

---

## 6. §2e — The test plan and the COST (bd `xdu2`'s estimate **corrected by measurement**)

### 6.1 Fixtures (Rule 12: a decline fixture **and** an adversarial probe per accept clause)

**Positives (~10):** the rolled array at N=2/3/8 and at K=1000 (K-independence); the promoted-store
shape as a hand-IR pin (the shape `-O1` emits, pinned so a `clang` bump is visible); `int` cells;
the bank with the value arm deleted; the bank with an unconditional prep; the measure loop alone;
the bank whose loads are `cq_measure`d in a different function-level order.

**Negatives, one per clause, each mirroring the diagnostic character-for-character (~12):** C1 VLA
(`N1`), C1 escaping address (`N2`), C1 global (`N3`), C1 non-zero initializer; C2 tainted index
(`N4` — must keep **7.5's** string, not a new one); **C2′ non-injective variable index (`N5b`)**;
C3 unsupported cell width; C4 aliasing fan-out (hand IR); **C6 over-sized bank** (`bool b[8]`,
`for (i<3)`); D5 a bank load used as a **branch condition**; D5 a bank load used as a **gate control**;
D5 a bank load feeding **arithmetic**.

⚠ **Fixture hygiene, all three defects that have each shipped through a green suite:** counts go in
their own whole-file prefix (a positive `CHECK-COUNT` inside a negative prefix **windows** every
negative after it); a `DS_Error` decline writes 0 bytes to stdout, so a decline fixture's IR-text
`CHECK-NOT`s are **vacuous** — the property is pinned by the `not` on the RUN line; and run
`$PREV/trackM/probes/impl/vacuity.py` over every new accept-fixture batch. A bare `-NOT: <word>` can
match the module's own path line (bd `qta2`).

### 6.2 Slices, goldens, ctest

**+5 goldens / +7 ctest entries** (corrected from `xdu2`'s +4/+6): the rolled bank at N=3; its
hand-unrolled twin **as an internal-consistency gate, labelled**; the K=1000 K-independence pin; the
`int`-cell spelling; the measure-loop-only slice; plus the twin `compare_files` gate and one
`e2e-slice-…-uncond` control. **Every slice runs STRICT stage 2b**, and each header must carry the §5
sentence that 2b reads K rails as one.

### 6.3 Twin matrix

`SCOPE_loop.md` §2.6's sub-grid — condition ∈ {`if (b[i])`, `if (!b[i])`, the `i8` trunc/zext
spelling} × {phase arm, value arm, prep} × the existing PREFIX/SUFFIX and preheader-op axes — plus a
**bank axis** (bank vs scalar). **~16–24 cells, not 8**: `xdu2`'s 8 assumes the `_Bool` axis already
exists and it does not (measured: 2 `bool` tokens in the whole script, both in
`phi_surface_of_header`). Both tables regenerate; `--regenerate` refuses while a boundary control has
moved; `e2e-loop-twin-matrix` is the ~180–400 s long pole.

### 6.4 Production lines — the correction

`xdu2` estimates **~150–220 lines**. **Measured calibration against the four most recent comparable
landings** (`git show --numstat <c> -- ir-pass/src ir-pass/include runtime tools`):

| landing | what it was | pass source |
|---|---|---|
| `94c085e` Track R (`rb9x`) | one conjunct added to one F2 test | **+231 / −107** |
| `59ac5b7` Track M (`boi6` D-B) | a new leaf kind in one grammar + one precedence edge | **+463 / −74** |
| `e96f89c` `l4x4.b` | a rail root admitted at two classifier classes | **+764 / −38** |
| `3a3a2b9` `b6ap` | a new pre-detection NORMALISER (`MergePhiPeel.cpp`) + `adjudicateTaintDelta` | **+1212 / −17** |

L-1a is **structurally the `b6ap` shape plus a memory model**: a new normaliser (the promoter), a new
carve verdict in the QRAM TU, a taint rule, a type rewriter, and the D1/D6 freeze at ~8 sites.
**Corrected estimate: ~700–1100 pass-source lines, ~22 fixtures, +5 goldens / +7 ctest,
16–24 matrix cells.** `xdu2`'s 150–220 is low by roughly 4×, and the gap is almost entirely the fence
enumeration of §4, which `xdu2` states as one sentence.

### 6.5 Rule-13 rounds — budget them up front

**Four, not three.** `CLAUDE.md` budgets three and then records the measured hit rate: 7.4 `break`
found 13 over-accept holes across three rounds, three of them **after** the epic was closed as cleared;
3qlq Inc 1's C-1 family found **8 over 6 rounds on one function**, two introduced by a fix and the
eighth by a round reviewing a different increment. L-1a gives the **C-1 in-loop entangled-rail family
its first memory-resident subject** and touches the exact `collectRailGates` walk whose F-1/F-3 pair
were confirmed silent miscompiles. Round 1 should be scoped to §4's enumeration alone.

### 6.6 The full increment, honestly costed

| piece | bead | pass source | rounds | note |
|---|---|---|---|---|
| **L-1a** the bank (W1) | `xdu2` | ~700–1100 | 4 | this document |
| **W2** the in-loop iteration-local prep | `wx8g` | ~120–180 | 3 | one new `Rollable` clause at `ArmClassify.cpp:4396`; ⚠ `CLAUDE.md` records its cost as **total** today |
| **W3** the in-loop value arm | `ej5w` | ~200–300 | 3 | **both** X1 sites, `LoopLowering.cpp:2106-2110` **and** the round-2 twin `:2548-2553`, or round 2 re-declines what round 1 accepted |

---

## 7. §2f — The DEPENDENCY verdict at `main` `607b6fe4`

`xdu2` says L-1a depends on Track M (`59ac5b7`) + Track R (`94c085e`) for the unrolled twin's stream.
**Re-measured on this ORACLE:**

* **Track M's dependency is MET at N=2 and the twin is now an ORACLE-backed stream, not an
  internal-consistency one.** `a_flat_n2.c` accepts (29 lines, 2b `8/6/2 verified`) and its gate
  stream equals the committed golden `slice_control_cascade_two_bools.expected.log`. The Track M merge
  record names `trackL/a_flat_n2` among its 79 DECLINE→ACCEPT movers — independent confirmation.
* ~~**The dependency is UNMET at N=3.**~~ `a_flat_n3.c` declines
  `cq controlled lowering: state prep seed is proven equal to the condition register under quantum
  control` — the `vd.c` wall, **bd `om35`**, which this session's **Track F is SCOPING, not
  implementing**. So at the end of this session the N=3 unrolled twin still does not exist.

  > ⚠ **ERRATUM, 2026-09-15 (Track A, applied IN THE SOURCE this time).** **The bullet above is
  > HISTORY and its conclusion is wrong.** bd `om35` LANDED on 2026-09-14 (`30317792`), after this
  > document was written, and re-measured on the 2026-09-15 ORACLE (`cq-opt`
  > `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`) **`a_flat_n3.c` ACCEPTS**:
  > ```
  > clang -Iinclude -include CQ.h -O1 -g -emit-llvm -S trackL/probes/a_flat_n3.c -o a_flat_n3.s1.ll
  > <ORACLE>/ir-pass/cq-opt -passes=cq-lowering -S a_flat_n3.s1.ll -o a_flat_n3.s2.ll   # exit 0, 147 lines
  > ```
  > (`a_flat_n2.c` likewise, exit 0, 115 lines.) **So the N=3 unrolled twin DOES exist**, and the
  > dependency this bullet calls UNMET is MET.
  >
  > ⚠ **AND THE §5 CONCLUSION THAT RESTED ON IT STILL HOLDS — FOR A DIFFERENT REASON, WHICH IS
  > EXACTLY HOW A STALE PREMISE SURVIVES A CORRECTION.** §5's *"rolled == hand-unrolled byte
  > identity … NOT available for the owner's literal program"* row must NOT be re-derived from "the
  > twin does not exist". Its two live reasons are **independent of `om35`** and both were
  > re-measured here: (i) with `a = 5` constant, `-O1` folds trip 0's condition in the UNROLLED
  > spelling and cannot in the rolled one (H2), so the two streams legitimately differ; and (ii) the
  > opaque-`a` alternative still declines — `L13_flat_n2_opaque_noinline.c` measures exit 1
  > `cq controlled lowering: control flow under quantum control` on the SAME ORACLE. The byte-identity
  > gate therefore still has to be built on a third program, or replaced by K-independence plus a
  > per-trip multiset argument, labelled INTERNAL-CONSISTENCY.
  >
  > This erratum exists because the correction was recorded in
  > `session-2026-09-14c-xdu2-w1/DECISIONS.md` ("Corrections landed by the tracks themselves") and
  > **never applied here**. `CLAUDE.md` L7-with-a-twist, verbatim: *a record correction that is not
  > applied to the source is not a correction* — and that defect was found three times on one
  > sentence before anyone believed it.
* **Track P does not change the unrolled twin.** bd `3qps` is the **PHASE** consumer of the
  merge-φ leaf; the array cascade's arm is a **VALUE** arm (a `select`), already Track M's. bd `4aiu`
  is the ROOT-ONLY widening (a φ at an *interior* position of a compound select condition); the
  cascade's φ is at the root. Neither touches `a_flat_n{2,3}`.
* **Track U (bd `z9t1`) composes but does not block.** `bool b[N];` without an initializer
  (`L7_array_uninit.c`) takes the same `kMsgStore` today. After L-1a, C1's *"constant-zero memset"*
  clause would **refuse** an uninitialized bank — which is the safe direction and is consistent with
  `z9t1`'s ruling that an undef **seed** becomes a concrete zero **at the allocation**. If the owner
  wants `bool b[N];` to compile, the two must be composed deliberately: the bank's per-cell seed is the
  site `z9t1`'s rule would attach to. **File this as a composition question, not as a blocker.**

**Plain statement of the finding (the brief asks for it): the dependency is UNMET for the N≥3 witness,
and L-1a's own scope is insufficient for the owner's program.** L-1a clears W1 and lands on `wx8g`.

---

## 8. What I could NOT turn into a predicate site

1. **C4's aliasing negative has no `-O1`-floor spelling.** `matchQramAccess`'s `GEP->hasOneUse()`
   (`QramLowering.cpp:467-469`) is the predicate, but I could not write a C program that reaches it on
   the validated floor — `-O1` CSEs or sinks every two-user GEP I tried. It needs a hand-IR fixture,
   which is off a scoping agent's instrument.
2. **The grouping key for `staleRailRecordRead`.** Its ROOT-MINT grouping (`ChainsByRoot`
   `LoopLowering.cpp:2525`, `ByRoot` `:2296`) has no key for a bank rail, and `(alloca, index SCEV)` is
   my proposal, not a measured one. Two cells of one alloca are distinct rails and one cell across trips
   is one rail; nothing in the tree expresses that relation today. **Treat this as an open design
   question for the implementer, not as a settled clause.**
3. **Whether R4 stays live after the promotion.** The argument is that the promotion keeps both sides
   of `railWireClosure` in SSA, so `CondRails ∩ BaseWireOrder` is still computable. I could not measure
   it, because W2 declines first. It must be measured on the subject binary in round 1 — R4 currently
   fires on **0 of 27** rivals *because 2c stands in front of it*, so a silently-vacated R4 would be
   invisible.
4. **The exact `Rollable` widening for W2.** I sited the decline (`ArmClassify.cpp:4396`) and the
   source comment that predicts it (`:4266-4271`), and I can state the clause in English, but the
   proof obligation *"nothing to roll because the rail is fresh per activation"* has no existing
   predicate to call — `railPhiRootMint` answers a different question. It is `wx8g`'s to build.

---

## 9. Probes and commands

All under `probes/`, driver `probes/run.sh` (the `PROTOCOL.md` per-probe pipeline against the frozen
ORACLE; every probe was run from the repo root as `./…/trackL/probes/run.sh <probe>.c`).

| probe | verdict on the ORACLE |
|---|---|
| `a_loop_n{2,3,8}`, `a_loop_n3_noarm`, `a_loop_n3_uncond` | DECLINE `tainted value stored to memory` — **W1, N-independent, unmoved from `e96f89c`** |
| `a_flat_n2` | **ACCEPT** — 115 lowered lines, 29 trace lines, 2b `8/6/2 verified`; stream == `slice_control_cascade_two_bools.expected.log` |
| `a_flat_n3` | DECLINE `state prep seed is proven equal to the condition register` (bd `om35`) |
| `L1_promoted_nostore` | DECLINE **`control flow inside a loop body`** — **W2**, anchor `%6 = icmp sgt i32 %5, 2` |
| `L1_promoted_store` | DECLINE `tainted value stored to memory` (col 14) — and its `-O1` IR **is** the carve's target shape |
| `L3_uncond_prep_value`, `L6_good_prep_value_arm` | DECLINE **`loop-carried tainted value crosses iterations`** — **W3**, two independent spellings |
| `L4_uncond_prep_phase`, `L11_promoted_phase_classcond` | **ACCEPT** 9 / 12 trace lines — the in-loop controls to keep byte-identical |
| `L2_prep_only`, `L5_prep_only_phase` | ACCEPT — ⚠ **DEGENERATE**: `a` is never modified, so `-O1` folds `a>=3` and there is no region. Do not cite as an in-loop prep accept |
| `L9_array_phase_arm`, `L10_promoted_phase_nostore` | `kMsgStore`, then `nested control flow` — **a phase arm is strictly harder than the value arm** (it cannot if-convert, so the body carries two tainted branches). The owner's value-arm cascade is the cheaper target |
| `L12/L13_flat_n2_opaque*`, `L14`, `L15` | DECLINE `control flow` at the select — **the shipped N=2 accept needs a compile-time-constant `a`**; discriminated to the opaque seed, not the arms |
| `L7_array_uninit`, `L8_array_int_cells` | `kMsgStore` — the Track U composition and the width axis, both unreachable at the wall today |
| `N1`–`N5b` | the per-clause negatives; see §2 |

⚠ **Not run, by the `PROTOCOL.md` scoping row:** no build, no `lit`, no `ctest`, no corpus sweep, no
injection matrix. Every verdict above is the per-probe pipeline only. The counts quoted in §6 are file
counts and `git --numstat`, both re-measured at `607b6fe4`, not cited from `CLAUDE.md`.
