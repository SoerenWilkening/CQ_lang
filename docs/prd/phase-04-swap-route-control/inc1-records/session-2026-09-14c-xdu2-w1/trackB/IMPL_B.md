# IMPL_B — bd `xdu2` / L-1a clause C5: the PER-ACTIVATION PROMOTER, as shipped

Track B, session 2026-09-14c. Worktree `/Users/sorenwilkening/Desktop/CQ_xdu2B`, branch
`railbank-promoter`, off `main` `c8007c37`. Gate lines (hash-keyed, PROTOCOL format): `GATES.md`.
Probes: `probes/`.

**ORACLE, verified before the first probe:** `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
sha256 `5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8`, `libCQPass.so`
`5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4` — matches the brief.

> ⚠ **A stronger baseline fact than the protocol asks for, and it is worth keeping:** the FIRST build of
> this worktree, before any edit, produced `cq-opt` sha256 `5c6f7490…` and `libCQPass.so` `5276f7ab…` —
> **bit-identical to the ORACLE**. So every oracle-vs-subject row below is a comparison against a binary
> this tree can reproduce byte-for-byte, not merely against "a build of the same commit".

---

## 1. The promotion contract, as shipped

`bool promoteRailBankCells(llvm::Module &M, const TaintSet &taint)` —
`ir-pass/src/RailBankPromote.cpp`, declared `ir-pass/include/RailBankPromote.h`.

**Per activation of the write loop:**

1. the **seed** load becomes the proven initializer **constant**;
2. every intra-activation load becomes the dominating store's **value** — an SSA merge φ where the store
   is conditional;
3. exactly **one** store per activation survives, at the activation's **end** (the latch), storing the
   value live at the end of the activation.

Measured, on `ir-pass/test/railbank_promote_loop_n3.ll` (the customer at N=3), under
`CQ_RAILBANK_DBG=1`:

```
arm:
  %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)   ; (1) the seed is a LITERAL
  %z0 = zext i1 %q to i8
  br label %latch
latch:
  %cq.bank = phi i8 [ %z0, %arm ], [ 0, %head ]                      ; (2) the SSA merge
  %t1 = trunc nuw i8 %cq.bank to i1
  …
  %cq.bank.addr = getelementptr inbounds [3 x i8], ptr %b, i64 0, i64 %i
  store i8 %cq.bank, ptr %cq.bank.addr, align 1                      ; (3) ONE store, at the end
  br i1 %done, label %mend, label %head
```

That is the shape `clang -O1` emits for the equivalent scalar source
(`$SESP/trackL/probes/L1_promoted_store.c`), which `SCOPE_L1a.md` §0 H3 pins as the target — with one
measured difference, stated rather than glossed:

> **The φ this stage builds is at the CELL type (`i8`), where the `-O1` target's is at `i1`.** `-O1`
> reaches `i1` by also folding the `zext`/`trunc` round trip around the φ, which is InstCombine's
> phi-of-cast fold and is not this stage's job. The seed side IS byte-identical to the target
> (`@cq_theta_i1(i1 false, …)`), because the fold there is plain constant propagation and this stage
> does it (PASS F). The residual is recorded, not hidden: a carried `_Bool` is an `i8` WIRE in every
> loop form anyway (bd `r903`, which `CLAUDE.md` calls load-bearing there), and the deferred half of W1
> is what will have to read the φ.

**What it does NOT do:** it does not make anything compile. See §3.

---

## 2. The slot, and the L1 proof — every stage in the window, named

**Slot: FIRST in the `-O1`-repair normaliser fixpoint family, immediately after the `lowerByRefInline`
fixpoint and BEFORE `foldIdentityBitcasts`, in BOTH entry points.**

* `CQLoweringPass::run` — `ir-pass/src/CQLoweringPass.cpp:196` (the `while` loop), dump at `:204`.
* `CQLoweringPass::runOnFunction` — `:928` (with the `onlyInF` re-scoping the sibling fixpoints do),
  dump at `:934`.

⚠ **Rule-11 correction to `BRIEF_B.md` §2 and `SCOPE_L1a.md` §3(a).** The brief names
`CQLoweringPass.cpp:217-314` for `run()` and **`:835-892`** for `runOnFunction`. Verified on this tree
(`c8007c37`): `run()`'s fixpoint family is `:217` (`promoteVolatileScalarLocals`) through `:316` (the
end of the ctlz fixpoint) — correct; but `runOnFunction`'s family is **`:893`–`:957`**, and `:835-892`
covers the *folds* that precede it (`foldIdentityBitcasts` `:863`, `foldVolatileConstAllocaLoads`
`:873`, `eraseDeadVolatileScalarStores` `:888`). `runOnFunction` has **no `lowerByRefInline` fixpoint
at all**, so the mirrored slot is defined as *"immediately before `foldIdentityBitcasts`"*, which is
the same relative position in both entry points.

### 2.1 Does it grow the taint set? YES — and by more than the peel does

`MergePhiPeel`'s F-B6-1 species, verbatim. Today taint is SSA-only: `propagateWorklist`
(`TaintPropagation.cpp:374`) has **no load/store rule**, so a bank `load` is UNTAINTED and everything
downstream of it is classical. Replacing that load with the **stored value** makes every downstream
user quantum. On the customer at N=3 the growth is visible in one line: `%t1 = trunc … %s1` was
classical and becomes `%t1 = trunc … %cq.bank`, tainted — which then taints the `select`, the header φ
`%a`, and the `cq_measure_si32` operand.

So the obligation is real and the answer is the **slot**, never the stage's good behaviour.

### 2.2 The window, stage by stage — the answer is ORDER

**Above the slot** (must compute nothing a later stage consumes over a premise the promotion falsifies):

| stage | line | disposition |
|---|---|---|
| `propagate` (initial) | `:114` / `:815` | rebuilt by the promoter's own fixpoint |
| passthrough early-out | `:124` / `:816` | a module with no theta/phi/measure never reaches the promoter |
| `onlyInF` work-list scoping | `:846-853` (`runOnFunction` only) | re-applied inside the promoter's fixpoint, exactly as the sibling fixpoints do |
| `lowerByRefInline` fixpoint | `:145-146` | itself a `while (X) taint = propagate(M, wd);` normaliser — it consumes nothing later |

**Below the slot** — every stage that adjudicates CONSUMERS of tainted values, all of which see the
re-propagated set:

| stage | line (`run`) | why it matters |
|---|---|---|
| `foldIdentityBitcasts` | `:169` | the **SOLE** handler for a same-width int↔int `bitcast`, and `adjudicateTaintDelta`'s **CALL 1** for exactly that reason (bd b6ap F-B6R2-1: a bitcast made tainted by a later taint-growth stage is left standing and dies at `no template for opcode 'bitcast i32'`). Taking the slot ABOVE it closes that window by order — this is the single strongest reason the slot is first rather than merely inside the family |
| `foldVolatileConstGlobalLoads` | `:178` | taint-blind fold |
| `foldVolatileConstAllocaLoads` | `:189` | reads taint; runs after |
| `eraseDeadVolatileScalarStores` | `:204+` | reads taint; runs after |
| `promoteVolatileScalarLocals` fixpoint | `:219` | reads taint; runs after |
| `promoteFp80Union` fixpoint | `:237` | reads taint; runs after |
| `flattenPredMuxRegions` fixpoint | `:261` | reads taint; runs after, through its normal entry point |
| `unrollConstTripLoops` (+ nested PredMux) | `:283` | reads taint; runs after |
| `recognizeCtlzIdiomLoops` (+ nested PredMux) | `:312` | reads taint; runs after |
| `detectSpecializations` | `:331` | the first of the three pure-analysis guards F-B6-1 named |
| `declineTaintEscapes` | `:340` | **this is where the population declines** |
| `declineStaleRecordOps` | `:347` | |
| `recordStaleQuantumReaders` | `:367` | |
| `lowerControlledIOSinks`, `lowerLoops`, `MergePhiPeel`, both detection rounds, `repropagateControlMerges` | `:379`… | all after |

**Therefore `adjudicateTaintDelta` is NOT owed.** The caller runs `taint = propagate(M, wd)` after every
true return — a full rebuild, strictly stronger than a delta — and no consumer guard has run at that
point. This is also why the signature takes `const TaintSet &` and keeps no bookkeeping: at this slot
NOTHING has written bookkeeping into the set, so a rebuild is exact (contrast `MergePhiPeel`, whose own
header explains why it must maintain `Tainted` by hand).

**RETIREMENT TRIGGER, written into `RailBankPromote.h` and at both call sites:** move the call below any
stage in the second table — or add a taint-consuming stage above it — and it owes `adjudicateTaintDelta`
exactly as the peel does, **with no diagnostic anywhere** if the obligation is missed.

### 2.3 The round-2 question proper

Control detect+lower run twice (`repropagateControlMerges`). The promoter runs **once**, far above both
rounds, and computes nothing any later stage consumes: it rewrites IR and hands the result to a full
`propagate`. The only durable artefact it leaves is the `!cq.railbank` **metadata** on the `AllocaInst`,
which is (a) IR-resident so no RAUW can dangle it (`TaintPropagation.h:198-225` records the `Value *`
spelling of this kind of fact as a shipped silent miscompile) and (b) read this session by exactly two
callers, the stage's own B9 fixpoint guard and Track A's `isRailBankAlloca`.

---

## 3. The staged landing, and the measured blast radius

W1 is three pieces; **two** land this session. The taint rule (a `load` from a `!cq.railbank` alloca is
tainted), the `[N x i1]` → `[N x i32]` type rewrite and the D5 allow-list are deferred, because until
they land an **accepted** bank is a silent miscompile — `SCOPE_L1a.md` §4.4(D): `cq_measure(b[i])` on an
untainted load takes `MeasureLowering.cpp:151`'s classical split and emits **no gate, no symbol, no
trace line**, which the golden byte-diff cannot see.

**So after the promotion the program still declines `cq taint escape: tainted value stored to memory`,
at the one surviving store per activation. Measured, not asserted** (`probes/trackl_matrix.txt`; the
per-probe pipeline of `PROTOCOL.md`, ORACLE vs SUBJECT, `-O1 -g`):

| probe | promoted? | oracle verdict | subject verdict |
|---|---|---|---|
| `a_loop_n2` | **yes** | `a_loop_n2.c:10:26` kMsgStore | **identical string, identical line:col** |
| `a_loop_n3` | **yes** | `a_loop_n3.c:10:26` kMsgStore | identical |
| `a_loop_n8` | **yes** | `a_loop_n8.c:10:26` kMsgStore | identical |
| `a_loop_n3_noarm` | **yes** | `…:10:26` kMsgStore | identical |
| `a_loop_n3_uncond` | **yes** | `…:10:14` kMsgStore | identical |
| `L7_array_uninit` (D1) | **yes** | `…:4:38` kMsgStore | identical |
| `L8_array_int_cells` | **yes** | `…:4:38` kMsgStore | identical |
| `L9_array_phase_arm` | **yes** | `…:4:38` kMsgStore | identical |
| `L1_promoted_store` | no (B8) | `…:12:14` kMsgStore | identical |
| `L1_promoted_nostore` | no | `control flow inside a loop body` | identical |
| `N1`…`N5b`, `N4` | no | per-probe | identical |
| `a_flat_n2`, `a_flat_n3`, `L2`, `L4`, `L11`, `p2`, `p9`, `p16`, `p23` | no | ACCEPT | **lowered IR md5 identical** |

**`!dbg`: 0 lost, 0 moved.** The surviving store carries the ORIGINAL store's `DebugLoc` by
construction (`applyBank` PASS D), so `kMsgStore` fires at the same `line:col` in every row above.

**The confinement is STRUCTURAL, not hoped for.** The stage fires only on an alloca whose stores Track
A's carve calls `Bank`, and C3's taint half makes an untainted store `NotBank` — so **no classical array
anywhere in the corpus is a candidate**. `railbank_promote_reject_classical_store.ll` is that conjunct
as a fixture, and it is the most important negative in the batch.

---

## 4. Three MEASURED CORRECTIONS to `SCOPE_L1a.md` §2 — each one an over-decline of a required positive

These are not nits: each refused a program the increment's own fixture list names, and each was found by
running the stage rather than by reading the scope. **Track A must not ship the literal clause text.**

### (a) C4's `GEP->hasOneUse()` refuses the MOTIVATING CUSTOMER

§2 C4 says to call `matchQramAccess`'s aliasing fence, `GEP->hasOneUse()` (`QramLowering.cpp:467-469`).
In `a_loop_n3.c` at `-O1` the arm's gep `%9` has **TWO** uses — the seed `load` **and** the `store` at
the same address. That is not an accident of one probe: it is precisely the shape §0 H3 exists to
describe. A literal `hasOneUse()` makes the whole increment fire on **nothing**.

The property C4 actually needs is *"no user of this address is something other than a cell memop we
have enumerated"*, which is what `hasOneUse()` buys for QRAM's single-access shapes. Shipped as: every
use must be a simple, exact-cell-type load or store with this gep as the **pointer** operand.

### (b) C1's "constant-zero `llvm.memset`" misses two of the three sizes

`clang -O1` writes `bool b[3] = {0}` with a memset and `bool b[2] = {0}` / `bool b[8] = {0}` with a
single **whole-object integer store** (`store i16 0` / `store i64 0`) — the sizes it can do in one
instruction. Measured: with a memset-only clause, N=2 and N=8 did **not** promote and N=3 did.

The whole-object zero store is a **proof** of the same fact, not a second manufacture. Only the
NO-INITIALIZER case (owner ruling D1) invents a value the source never wrote, and only that case carries
the bd `z9t1` disclosure. Fixture: `railbank_promote_loop_n2_wholeobj_init.ll`.

### (c) the read side: `-O1` UNROLLS a short measure loop into off-shape accesses

For `a_loop_n3_noarm.c` / `a_loop_n3_uncond.c`, `-O1` turns `for (i…) s += cq_measure(b[i])` into
`load i8, ptr %b` · `gep inbounds i8, ptr %b, i64 1` · `… i64 2` — a **direct load** and **byte-offset**
geps, none of them the canonical `[N x T], 0, idx` shape. An alloca-wide scan that admits only canonical
geps refuses the whole bank on account of instructions nothing rewrites. Admitted as provable in-bounds
constant-offset **reads**, via `accumulateConstantOffset`. Fixture:
`railbank_promote_unrolled_reads.ll`.

⚠ **And the fence that had to come with (c)**, which is a hazard the scope does not name at all:
such a read is admitted **only outside the write loop**. Inside it, the promotion MOVES the write to the
activation's end, so a second observer would see it at a different point in the trip —
`for (i…) { if (c) b[i] = θ(b[i]); x = b[0]; }` reads `b[0]` AFTER the store on trip 0 in the source and
BEFORE it after the move. That is a **classical** miscompile, `opt -verify` cannot see it, and no rail
fence in the tree looks at memory at all (§4.1). The clause is blunt: **nothing non-rewritable may live
inside the write loop**. Fixture: `railbank_promote_reject_inloop_other_read.ll`.

---

## 5. `armWritesMemory` (P10) — the measurement, and the header amendment

**`SCOPE_L1a.md` §4.4(D) predicts: *"the promotion must run BEFORE `MergePhiPeel` (it does) and after
it the arm holds NO store, so P10 stops refusing. Verify by measurement, and amend the header."*
The first half is true and the prediction is FALSE for the whole bank population** — for a reason that
has nothing to do with the clause.

**Method** (`probes/p10_measurement.txt`): a temporary AUDIT build — the bd b6ap round-2 "temporary
audit build" method — instrumenting `MergePhiPeel`'s P9 / P1 / P10 with a `CQ_PEEL_AUDIT` lever, plus a
`CQ_RAILBANK_OFF` lever in `CQLoweringPass.cpp` so BOTH halves came from ONE binary (the ORACLE cannot
be instrumented — it is read-only). **Reverted immediately; the shipped binary carries neither**, and
`grep -c "CQ_PEEL_AUDIT\|CQ_RAILBANK_OFF" ir-pass/src/*.cpp` is 0.

**Measured.** Over six bank modules — `a_loop_n{2,3,8}`, `a_loop_n3_noarm`, the uninitialized bank and
the `int`-cell bank — with the promoter **OFF** and with it **ON**:

```
  a_loop_n3          : AUDIT lines  promoter OFF = 0   promoter ON = 0
  a_loop_n2          : …                          0                 0
  a_loop_n8          : …                          0                 0
  L7_array_uninit    : …                          0                 0
  L8_array_int_cells : …                          0                 0
  a_loop_n3_noarm    : …                          0                 0
```

**`MergePhiPeel` is NEVER REACHED.** The module dies at `declineTaintEscapes`' `kMsgStore`
(`CQLoweringPass.cpp:340`) seven stages before the peel (`:471`), and `LLVMContext::diagnose` **EXITS**
on the first `DS_Error` (bd `br4a`). P10 is not an obstacle because nothing downstream of the decline
runs at all.

⚠ **And the instrument was made to prove itself, because an instrument's failure mode is to report a
pass.** The same audit binary printed the full `P1 → "P10 asked" → "P10 passed"` sequence on
`control_peel_freeze_incoming.ll` and `control_peel_angle_tail_datamux.ll`, and the
`"P10 armWritesMemory REFUSED"` line on `control_peel_guarded_store_ctrl_unchanged.ll` and
`control_peel_reject_guarded_store.ll`. The zero is a fact about the population, not a dead lever.

⚠ **And when the deferred half lands and the population stops declining, P10 is STILL not the fence in
front of it.** Every rail-bank region is inside the write loop, so **P9** (`regionEntryInLoop`) refuses
it first, and the peel's **≥2-φ containment gate** refuses it again — the promoted latch carries
exactly ONE φ (`%cq.bank`).

**The header amendment** (L7-with-a-twist: *"a record correction that is not applied to the source is
not a correction"* — the same clause was ruled wrong three times on one sentence and kept being read off
the source comment that still carried it). Applied **in this change**, not filed:

* `MergePhiPeel.cpp`, `armWritesMemory`'s header — a new AMENDMENT block carrying the measurement, the
  P9/containment-gate ordering, and a RETIREMENT TRIGGER ("the day P9 is narrowed to admit an in-loop
  peel site, re-run the measurement"). The clause's own text is **unchanged and unweakened**; what is
  corrected is the SCOPE's claim that L-1a would make it the live fence.
* `control_classical_call_arm_reject_localarray_store.ll` — the second amendment SCOPE_L1a §3(b)
  requires. Its header claims the store→load forwarding is *"UNREACHABLE on the clang `-O1`/`-O2`/`-O3`
  validated floor — GVN already forwards every provably-same-address round-trip"*. **That is FALSE as
  written**: `a_loop_n3.c` at `-O1` is a counterexample, because the store is only PARTIALLY AVAILABLE
  (it sits in the conditional arm) and GVN forwards only fully available ones. The fixture's doctrine
  sentence *"taint is SSA-only"* is narrowed too — L-1a's deferred half adds exactly one load rule. ⚠
  **The fixture is NOT retired and its verdict does not move**: measured, the promoter fires **zero**
  times on it (its index is a function ARGUMENT with no enclosing loop, so C2′ has no add-recurrence at
  all; its array has no proven zero initializer; and it is off the `-O1` floor by its own header).

---

## 6. The SSA-construction choice

**`llvm::SSAUpdater`** (`llvm/Transforms/Utils/SSAUpdater.h`), not hand-rolled φ placement, and not
`PromoteMemToReg` (which promotes a whole alloca to registers across the entire function — the exact
thing §0 H3 says is wrong here, because the bank must survive into the measure loop).

**`LoadAndStorePromoter` was considered and rejected**, for one reason: this stage needs the live-in
value at the **loop header** to be the INITIALIZER, not a value flowing round the back edge, and that
utility has no way to express it (its `getValueToUseForAlloca` hook is function-entry-shaped). What is
hand-rolled is therefore only the **access ordering inside each block** — exactly the part
`LoadAndStorePromoter` hand-rolls too — while φ placement stays `SSAUpdater`'s.

**The per-activation containment proof** (also in `RailBankPromote.h`):
`SSA.AddAvailableValue(Header, …)` is registered **unconditionally** for the header — the last in-header
store's value, or the seed. `SSAUpdater` stops its predecessor walk at any block with an available
value, and the header is the **only** block of a natural loop with a predecessor outside `L` or across
the back edge. So every query terminates inside `L` and never reads the latch's value from the previous
trip. The one remaining case — a load **in** the header with no preceding in-header store — is answered
**directly with the seed** and never asked of the updater, because `GetValueInMiddleOfBlock(Header)`
would walk preheader AND latch and build exactly the wrong φ. That is the naive element-type rewrite's
defect in another spelling, and it is the one place a reviewer should look first.

⚠ **The proof is a theorem only under B2 + C2′.** It says "this trip's cell was never written before",
which is the carve's injectivity clause plus B2's one-address rule. Weaken either and the seed is a
previous trip's live rail read as a classical zero.

`ScalarEvolution` is built standalone per function with the `LoopUnrollPrepass.cpp:238-242` idiom
(itself copied from `LoopLowering.cpp:4160-4165`): `AssumptionCache AC(F); TargetLibraryInfoImpl
TLII(Triple(M.getTargetTriple())); TargetLibraryInfo TLI(TLII); ScalarEvolution SE(F, TLI, AC, DT, LI);`
— a default TLI is a conservative TLI, sufficient for trip-count reasoning. ⚠
`TaintPropagation.cpp:1861-1863` warns that *"a `LoopInfo` built mid-fixpoint would describe a loop the
next iteration reshapes"*; that is answered rather than inherited: this slot is **above**
`unrollConstTripLoops`, `recognizeCtlzIdiomLoops` and the PredMux flattener, so the loops SE describes
are the **source** loops, and the rewrite changes **no edge** (it inserts and erases instructions only),
so even a cached tree would stay valid.

---

## 7. Clause table as shipped

| clause | owner | site | fixture |
|---|---|---|---|
| **C1** non-escaping bounded alloca, proven initializer (memset-zero, whole-object zero store, or NONE per D1) | carve | `RailBankCarveShim.cpp` `scanAlloca` | `…reject_escaping_address`, `…reject_nonzero_init`, `…uninit_bank` |
| **C2** classical index | carve | `scanAlloca` (`NotBank` on tainted) | `N4_tainted_index` keeps 7.5's string |
| **C2′** injectivity: affine `{0,+,1}` add-rec, constant EXACT backedge-taken count | carve | `railBankCarveVerdict` | `…reject_noninjective_index` |
| **C3** tainted stored value + `widthHasReversibleCopy` | carve | `railBankCarveVerdict` | `…reject_classical_store`, `…int_cells` |
| **C4** no aliasing fan-out (every gep use is an enumerated cell memop) | carve | `scanAlloca` | — (§4a) |
| **C6** totality: trip count == N, single classical exit | carve | `railBankCarveVerdict` | `…reject_oversized_bank` |
| **B1** one bank, one write loop, no sub-loop | promoter | `planBank` | `…reject_two_cells` (adjacent) |
| **B2** one cell per activation (SCEV address equality) | promoter | `planBank` | `…reject_two_cells` |
| **B3** no early exit (`getExitingBlock() == getLoopLatch()`) | promoter | `planBank` | `…reject_early_exit` |
| **B4** simple, exact-type accesses; no marker/memset inside `L` | promoter | `planBank` | `…reject_volatile_cell` |
| **B5** one writer (no store outside `L`) | promoter | `planBank` | `…reject_store_outside_loop` |
| **B6** every store into the bank is `Bank` by the carve | promoter | `planBank` (**the ONE carve call site**) | all |
| **B7** the canonical gep is materialisable at the latch | promoter | `planBank` | — |
| **B8** ≥1 load inside `L` | promoter | `planBank` | `…reject_already_ssa` |
| **B9** not already promoted (`!cq.railbank`) — the fixpoint's termination | promoter | `planBank` | — |
| **(new)** nothing non-rewritable inside `L` | promoter | `planBank` | `…reject_inloop_other_read` |

---

## 8. The Track-A boundary — ONE call site, and every way it can rot is LOUD

`RailBankPromote.cpp`'s `planBank` calls `railBankCarveVerdict(SI, taint, DT, LI, SE, Msg)` exactly
once, in the B6 loop. It never re-derives the carve (Rule 14; the drbq Inc-3 (b′) defect is filed by
name).

Track A's branch is not in this worktree, so the declaration lives in
`ir-pass/include/RailBankCarve.h` and a **temporary** implementation in
`ir-pass/src/RailBankCarveShim.cpp`. **Both are deleted when Track A merges**, and the design is that
forgetting is impossible:

* Track A defining the same symbols ⇒ **duplicate symbol** link error, in both `libCQPass.so` and
  `cq-opt` (they share one source list);
* Track A declaring `enum class RailBankCarve` in `QramLowering.h` ⇒ **redefinition** compile error in
  any TU that sees both;
* Track A's signature differing ⇒ **unresolved** call site once the shim is deleted.

⚠ **One constraint on Track A that must be relayed:** the verdict must **not** depend on the
`!cq.railbank` metadata. The promoter **mints** that record (`SCOPE_L1a.md` §4.3 — "minted by the
promoter; carries the element ABI width") and reads the verdict **before** minting it. A
metadata-dependent verdict is circular and answers `NotBank` for every bank on first sight.

The promoter's own alloca walk is **not** a second carve: it collects the instructions the rewrite will
touch and refuses anything it cannot express. An accept needs **both**, so a divergence between them can
only ever over-DECLINE.

---

## 9. Gates — and the injection matrix, which took FOUR rounds and is the part to read

Hash-keyed lines: `GATES.md`. Final subject binary `cq-opt` sha256
`9846bca0bf23a01e53f95c64f8252f770538668f753ed34fcc8fc6ead7f638ba`.

**Ran:** `ctest -R ir-pass-lit` → Passed, 64.03 s (`lit ir-pass/test` = **2013 passed, 1 expectedly
failed, of 2014**); one ORACLE-vs-SUBJECT corpus sweep → **4725 rows, 0 MOVERS**; the injection matrix
(four rounds, below); the trackL probe matrix → 34 probes, 8 promoted, **0 verdict movers, 0 `!dbg`
movers**.
**Did not run, deliberately** (PROTOCOL implementation column): the full `ctest -j6`, `^e2e-`,
`cq-opt-equivalence-full`, the twin matrices.

### 9.1 The corpus sweep

3680 committed `.ll` (all of `ir-pass/test` plus every `inc1-records/**/probes/` and
`review_*probes/` dir) **+ 1045 stage-1 modules compiled from the `.c` probes in those dirs** at
`-O1 -g` = **4725 rows**. A row compares **exit code**, **full stderr byte-for-byte**, and the
**lowered-IR md5 within the row** when both accept. The full-stderr compare is deliberate: PROTOCOL S3
records that the shared `corpus.sh` tag regex renders the whole `cq_measure_<sfx>` family as an empty
`D:`, so a decline→decline string change inside it is invisible to a tag diff. Md5s are compared within
a row only, never across sweeps. **0 movers**, so: no ACCEPT row (which would have stopped this track),
no changed string, no moved or lost `!dbg`.

### 9.2 The injection matrix — round 1 said MISSED=7, and it was RIGHT to

⚠ **A decline fixture for an ACCEPT-ONLY normaliser is the vacuity trap in its purest form.** When the
stage refuses, the module is byte-identical to not having the stage at all — so the fixture can pass
because the clause works, or because the clause is unreachable, and those look identical from outside.
The only instrument that separates them is to DELETE the clause from the binary and watch the fixture go
red. So the matrix mutates the **binary**, one clause per mutant, and rebuilds (~50 s each).

| round | mutants | N/A | MISSED | what it found |
|---|---|---|---|---|
| 1 | 12 | 0 | **7** | every miss was a SECOND clause in the conjunction also refusing the shape |
| 2 | 7 | 0 | **2** | combined mutants removing every clause that refuses each shape |
| 3 | 2 | 0 | **0** | after rewriting two probes so the intended clause is the SOLE refuser |
| 4 | 1 | 0 | **0** | M13 — re-adding the `!cq.railbank` mint — CAUGHT by all 7 accept fixtures |

**FINAL MISSED = 0**, over 22 mutants. `N/A = 0` in every round: **a mutation harness that reports
`n/a` is a HOLE, not a pass**, so each round asserts its anchor count is exactly 1 and its mutant
compiles, and prints `*** HOLE ***` otherwise.

**What round 1's seven misses actually were, and why two fixtures were rewritten rather than explained
away.** Defence in depth is not vacuity — but a fixture that passes for a reason other than the one its
header claims still pins the wrong thing. Two of the seven were **the fixture's fault**, and both are
now spelled so the clause under test is the only refuser:

* `…reject_two_cells` used `b[i+1]`, whose STORE index is `{1,+,1}` — refused by the carve's C2′
  (start ≠ 0) long before B2. Rewritten to store `b[i]` and READ `b[2-i]`: the store's index is
  `{0,+,1}`, the carve says `Bank`, and B2's SCEV address equality is the sole refuser. **CAUGHT.**
* `…reject_store_outside_loop` used a straight-line `b[1] = 1` before the loop — refused by the carve
  (a store outside any loop has no add-recurrence). Rewritten to a **second writing loop**, where each
  store is `Bank` on its own and the only refuser is the promoter's "every `Bank` store resolves to the
  same loop". **CAUGHT.** (It also needed a dedicated preheader block: without one,
  `getLoopPreheader()` was null and *that* refused instead — a third clause, found by the same matrix.)

**Two more are recorded as measured SUBSUMPTION rather than fixed**, because fixing them is not
possible from this branch:

* **B3** (`getExitingBlock() == getLoopLatch()`) is entirely subsumed by the shim's C6
  single-exiting-block conjunct. Isolating it needed a module where SCEV CAN compute an exact trip count
  despite a second exiting block — `railbank_promote_reject_second_exiting_block.ll`, whose second exit
  is `i > 100` over a 3-trip `{0,+,1}` — and even there the mutant had to remove BOTH clauses to turn
  the fixture red (round 3, M2′′: **CAUGHT**). ⚠ Whether B3 is subsumed by Track A's **real** C6 is
  **not measurable from this branch** and must be re-run at the merge gate.
* **The `!cq.railbank` negative was VACUOUS where it first sat** and the matrix said so: round 4's M13
  (re-add the mint) was caught by only **3 of 7** accept fixtures. Two hygiene defects, both in
  `CLAUDE.md`'s list: the negative was on the REFUSAL fixtures, where the promoter never runs so the
  mint could never fire; and on the accept fixtures it sat in a prefix carrying a positive
  `CHECK-COUNT`, which **WINDOWS** every negative after it — FileCheck scans forward from the positive
  match, and the `alloca` line is ABOVE it in the dump. Moved to its own whole-file prefix `NOMD`:
  **CAUGHT by all 7.**

### 9.3 Vacuity

The tree's `vacuity.py` ($PREV/trackM/probes/impl/) does not apply to this batch as written: it skips
any module whose `returncode != 0` and matches only handle-form `(i32 %x)` negatives, so it would print
`checked 0` — which is exactly the instrument failure the 2026-09-14 session recorded (a vacuity checker
printing `checked 0` on 29 real negatives). **Every module in this batch declines**, so the whole batch
would have been skipped. The equivalent evidence here is round 4 above: the one negative whose
population could be empty was MEASURED empty and then made non-empty.

---

## 10. ATTACK SURFACE (for Rule-13 round 1)

### 10.1 The mutation, as a precondition → postcondition pair

**Precondition.** A non-escaping `alloca [N x T]`; every user is (i) a canonical access gep
`gep inbounds [N x T], ptr %a, 0, %idx` whose every use is a simple exact-`T` load/store through it,
(ii) a provable in-bounds constant-offset read, (iii) a whole-object constant-zero `memset` or `store`,
or (iv) a lifetime marker. Every store into the object lies in ONE loop `L`; `%idx` there is an affine
`{0,+,1}` add-rec of `L` with a constant exact backedge-taken count equal to `N-1`; `L` has a preheader
and a single latch which is its only exiting block, and its exit condition is classical; every in-`L`
access has the same address SCEV; **nothing of kinds (ii)/(iii)/(iv) is inside `L`**; every in-`L` store
is `Bank` by the carve (hence its value is tainted and `T` has a reversible copy); there is ≥1 in-`L`
load; the canonical gep's operands dominate the latch terminator; the alloca has no `!cq.railbank`.

**Postcondition.** In-`L` loads and stores of the cell are gone and their geps with them. Each in-`L`
load has been RAUW'd to the cell's dominating definition, computed per activation with the header's
live-in fixed at `Constant::getNullValue(T)`. Exactly one `store T %final, ptr %clone` sits immediately
before the latch terminator, carrying the original store's `!dbg`, align and `!tbaa`. Users of a load
replaced by a Constant have been constant-folded transitively (non-φ only). The alloca carries
`!cq.railbank` with `T`'s ABI width. Everything outside `L` is byte-untouched. **No diagnostic is
emitted, ever.**

### 10.2 Every LLVM utility called, and its precondition

| utility | precondition this stage owes | discharged by |
|---|---|---|
| `SSAUpdater::AddAvailableValue(BB,V)` | `V` is available at the END of `BB` | PASS A registers the last in-block cell store's value, or the seed for the header |
| `SSAUpdater::GetValueInMiddleOfBlock(BB)` | every predecessor walk terminates at a block with an available value | the header always has one, and it is the only block of a natural loop with an outside/back-edge predecessor. ⚠ Never called on the header itself |
| `SSAUpdater::GetValueAtEndOfBlock(Latch)` | same | same |
| `Instruction::clone` + `insertBefore(Term)` | the clone's operands dominate `Term` | B7, asked explicitly with `DominatorTree` |
| `ConstantFoldInstruction` | none (returns null when it cannot fold) | seeded only from users of a load replaced by a `Constant`; **φ excluded** (a loop-carried φ erased from a loop-body worklist is bd memory `DCE-under-block-iterator-loopphi-uaf`) |
| `GetElementPtrInst::accumulateConstantOffset` | none | result range-checked against the object size, non-negative, ≤63 active bits |
| `ScalarEvolution::getBackedgeTakenCount` | a valid `Loop *` | `CouldNotCompute` is not a `SCEVConstant`, so the same test that reads the bound refuses it. ⚠ `getSmallConstantMaxTripCount` is deliberately NOT used (Rule 18: `4294967295` on some vacuous bounds, `0` on others) |
| `DominatorTree` / `LoopInfo` / `ScalarEvolution` standalone | must describe the loops the clauses talk about | built per call, above every stage that reshapes control flow |

### 10.3 Deletion discipline

No recursive deletion anywhere. bd memory `DCE-under-block-iterator-loopphi-uaf` — an inline
`RecursivelyDeleteTriviallyDeadInstructions` under `make_early_inc_range` crashes across a loop-φ back
edge — and **this stage operates inside a loop body, which is that hazard's home**. The worklist is
closed and bounded (loads, then stores, then the geps dead because of those two), collected before any
mutation, deduped (one gep can carry several memops — erasing it twice is a use-after-free `opt -verify`
never sees), and held through `WeakTrackingVH`.

### 10.4 The three programs I think are most likely to be the next hole

1. **A bank cell read through a POINTER the promoter cannot see as a bank user** — e.g. a `select` or
   `phi` over two cell addresses, or an address that round-trips through `ptrtoint`/`inttoptr`. Today
   every such user is refused by the alloca-wide walk, so the hole would be an *over-decline*, not an
   over-accept — **unless** a future widening admits pointer phis (which QRAM's `walkPtrOrigin` already
   does, and which Track A's real C1 will therefore drag in). The moment the origin walk sees through a
   pointer phi, "every user is enumerated" stops being a syntactic fact and the in-`L` observer fence
   (§4c) loses its ground. **This is the one I would attack first.**
2. **A bank whose write loop has an inner loop that does not touch the bank.** B1 refuses only accesses
   in a sub-loop; the LOOP may still contain one. `SSAUpdater` will happily build φs inside that
   sub-loop for a cell definition that crosses it, and I believe that is correct (the sub-loop's back
   edge is inside the activation), but it is **reasoned, not measured** — no probe in this batch has an
   inner loop, and §0 H3's containment proof is stated only for the outer back edge.
3. **A bank in a function that is also a Phase-6 specialization clone source.** `detectSpecializations`
   runs far below the slot and clones bodies; a clone made *after* the promotion carries `!cq.railbank`
   on a **cloned** alloca, and nothing in this increment says what the record means on a clone. The
   record is inert this session (two readers, both structural), so the hole is latent — but the deferred
   taint rule will read it, and a clone is exactly how a membership record acquires a second owner.

### 10.5 What I deliberately did NOT do, and why it is a refusal rather than an omission

* **No widening of any wire walker to cross memory.** `SCOPE_L1a.md` §4.4(C) and
  `ArmClassify.cpp:1283-1295` are explicit: teaching `railWireClosure` a memory hop trips
  `f2SeedPinnedByLiveRegister`'s retirement trigger, which the owner's own three-bool file depends on.
  The promotion keeps the loop body in SSA precisely so that none of those fences has to learn anything.
* **No taint rule, no type rewrite, no D5 allow-list, no freeze at the D1/D6 sites.** Deferred half.
* **No `staleRailRecordRead` grouping key** (owner ruling D3: refuse loudly, then measure). The promoter
  does not reach that fence — the population declines at `declineTaintEscapes`, far above `lowerLoops`
  — so there is nothing to refuse yet and nothing to measure until the taint rule lands. Stated here so
  round 1 can ask the D3 measurement question against the right binary.

---

## 11. What I could NOT do

1. **I could not measure the promoter against Track A's real classifier.** Track A's branch is not in
   this worktree, so `RailBankCarveShim.cpp` implements the PUBLISHED contract (`trackA/SIGNATURE.md`
   including its same-day ADDENDUM) and every verdict in this document is against that stand-in.
   **Everything in §3, §7 and §9 about the accept surface must be re-measured at the merge gate.**
   Concretely, the coordinator's question — *do the promoter's accept surface and Track A's `Bank`
   surface agree?* — has this answer: **they agree by construction on everything I can see, and there
   are exactly three places they could diverge**, each named so the merge agent can probe it rather
   than discover it:
   * **the RAW-vs-PROMOTED shape.** Track A measured BOTH as `Bank` and its deviation (3) exists for
     that reason. My promoter sees the RAW shape (the read-modify-write gep with TWO uses), and I
     independently measured that a literal `hasOneUse()` refuses the motivating customer (§4a). The two
     tracks reached the same correction from opposite directions, which is the strongest agreement
     evidence available without the merge.
   * **the outermost-loop conjunct.** Load-bearing for ME and not duplicated (Rule 14). Round-2 mutant
     **M12 measured that deleting it makes the promoter FIRE** on the nested-outer shape. If Track A's
     conjunct is ever relaxed, the promoter is an over-accept — a wrong unitary, not a wrong decline.
   * **"the classified store is the only store anywhere in the bank"** (Track A's deviation (3), last
     sentence). My `applyBank` handles several in-`L` stores through `SSAUpdater`, so that path is
     **currently unexercised** — the carve refuses a multi-store bank before it is reached. Not a bug;
     an untested branch, and the merge gate should know it is untested.
2. **I could not isolate B3 against the real carve** (§9.2).
3. **I could not use the tree's `vacuity.py`** (§9.3).
4. **I did not build the D3 `staleRailRecordRead` grouping key**, and the D3 measurement question is
   not answerable yet: the population declines at `declineTaintEscapes`, far above `lowerLoops`, so
   nothing reaches that fence and there is nothing to refuse or measure until the taint rule lands.
   Round 1 should ask the question against the binary that HAS the deferred half, not against this one.
5. **I did not run** the full `ctest -j6`, `^e2e-`, `cq-opt-equivalence-full` or the twin matrices —
   the PROTOCOL matrix gives those to the merge-and-gate agent, once per GROUP, and Track A and Track B
   are the same GROUP.

## 12. Filed — over-declines and untested paths, for the follow-on tracker

* **B3 is an over-decline on a provably-never-taken second exit.**
  `railbank_promote_reject_second_exiting_block.ll` is labelled as an over-decline pin, not a hazard
  pin: the second exit cannot be taken, no write is dropped, and the promotion would be sound. B3
  refuses it because "the latch is the only exiting block" is the cheapest sound spelling of "every
  activation reaches the latch". The widening is a reachability question — *every block holding a cell
  store reaches the latch within `L`* — and needs its own red-green pair. Per the owner's 2026-09-11
  ruling this is a **defect to file, not a safety margin**.
* **B1 refuses an access in a SUB-loop of the write loop.** Sound in principle (the sub-loop's back edge
  is inside the activation, so `SSAUpdater` would build the right φ), unmeasured here, and refused
  rather than widened.
* **The multi-store-per-activation path of `applyBank` is unexercised** (see §11.1).
* **The `i8`-vs-`i1` φ residual** (§1): the promoted φ is at the cell type where `-O1`'s is at `i1`,
  because the `zext`/`trunc` round trip around it is InstCombine's phi-of-cast fold. It costs nothing
  today (the population declines) and the deferred half will have to read the φ.
