# Track 8e5r — dangling `TaintSet` keys: a TOTAL mechanism instead of a site list

Session 2026-09-25 (parallel with bd `d88e`, which owns `liftOneRegisterMergePhi` /
`declineClassicalMuxes`; this track touched neither). Beads: `test_C_libtooling-8e5r`
(P1 silent miscompile), `-um24` (P2 use-after-free read), `-j8sk` (the class). Worktree
based on `main` at `def1b088`. Found by Rule-13 round r1B on bd `9bhg`
(`review_r1B_9bhg/REVIEW.md` F-9B-1..5, in the 9bhg worktree; not on `main`).

ORACLE: frozen `cq-opt.main_e846` `b1603d237fc3a739` (a fresh build of the unmodified
worktree was measured BIT-IDENTICAL to it before any edit — a build null control).
ORACLE+ALLOC: the same sources plus only the test allocator (§3.3), `270be7cf4f0fc89f`.
SUBJECT: see §7 for the final hashes. Probes, sweeps, the mutation driver and every
result file are under `track_8e5r_probes/`.

**Not self-cleared.** This is a Rule-13 lowering-core change (`TaintPropagation.h`'s
`TaintSet` and every emitter that scrubs it). §9 says what to attack first.

> **UPDATE 2026-09-26 — after Rule-13 rounds r1A (container semantics, `CLEAR-WITH-ITEMS`,
> 0 P1 / 0 P2 / 9 P3) and r1B (verification + composition, `CLEAR-WITH-ITEMS`, one P1 that
> is a MERGE OBLIGATION, one P2, P3s)**, records `review_r1A_8e5r/` and `review_r1B_8e5r/` in
> this directory. `main` (ba80bda1, bd d88e) was MERGED into this branch and every finding was
> dispositioned: §12 (the commits and exactly which LOGIC lines changed since the reviewed
> `818f8afa`, for the delta reviewer), §13 (measurements on the merged tree), §14 (the
> disposition of every F-EA-n / F-EB-n). Where this record was wrong it is corrected IN PLACE
> and marked ⚠ CORRECTED (the e2e names in §6.1 were an instrument defect of mine).

## 1. Headline

- **The class is closed by construction, not by a site list.** Every pointer-keyed
  table of `cq::TaintSet` (32 of them: `Tainted`, `BirthOrder`, `HandleWidth`,
  `ThetaCalls`, `MeasureCalls`, `PhaseCalls`, `StaleDeclined`, `InPlaceRailOps`, ...,
  full list §4.1) is now a self-cleaning container (`ir-pass/include/ScrubOnDelete.h`):
  one `llvm::CallbackVH` per key, called back by LLVM's own `~Value()` whoever deletes
  the Value and by whatever route (an emitter, `lowerOps`, an LLVM utility). A deleted
  key is no longer counted, found, looked up or iterated, and a fresh object allocated
  at its address is NOT a member. It OBSERVES deletions; it does not PREDICT erase
  sites, so it cannot miss one.
- **bd 8e5r (P1) is gone, deterministically.** k65 (the reviewer's repro) and all 523
  alias-family programs (`alias_gen`, `gen2`, `gen3`, `gen5`, `gen6`) produce the
  no-reuse REFERENCE output in **5230/5230 runs in each of three allocator modes**
  (system, maximal-reuse LIFO, no-reuse), where the oracle is non-reference in
  **564/5230** runs under the system allocator (86 modules, 16 of them also crash)
  and **800/5230** under LIFO (80 modules, 10/10 each) (§6.2).
- **bd um24 (P2) is gone.** `lowerLoops`' prescan no longer dereferences a set member
  (it walks the function and looks live pointers up, the spelling its two neighbours
  already used) — and the set can no longer hold a deleted key anyway. The four
  fixtures the reviewer named, plus two more lit fixtures (`lowering_io_controlled_printf_sgt`
  under LIFO, `lowering_io_controlled_putchar` under no-reuse) and SEVEN e2e slices this
  track found, SIGSEGV on the oracle under a deterministic allocator (both LIFO and
  NO-reuse: the dead instruction's parent pointer is null); the subject declines/
  accepts cleanly in every mode (§6.1).
- **No emitted stream moved.** Corpus A/B over 2284 lit fixtures + 421 e2e stage-1
  modules: 0 movers vs the oracle under the system allocator; the subject is
  ALLOCATOR-INDEPENDENT on all 3228 modules (system == LIFO == no-reuse, byte for
  byte); and the subject equals the ORACLE UNDER NO-REUSE on 3216/3228, the 12
  exceptions being the oracle's own um24 crashes (§6.3).
- **Four deterministic pins**, none of them an allocation lottery: a per-member
  self-test of every `TaintSet` table (`cq-scrub-selftest`, two ctest entries), a
  structural guard that no raw pointer-keyed member can be (re)added
  (`taintset-scrub-guard`, with its own mutant self-test), a lit fixture + an e2e slice
  for k65 under a test-only maximal-reuse allocator, and a `nofree` RUN line on the four
  um24 fixtures. Red on the oracle, green on the subject, measured repeatedly (§5).

## 2. The defect class, re-measured on `main`

`review_r1B_9bhg` measured on the 9bhg subject; this track re-measured on `main`
(`def1b088`, no 9bhg) before changing anything:

- **k65** (`alias_gen3/k65.c`): the frozen oracle emits the wrong clone body
  `cq_template_mul_i32_hl(i32 7 /*as a HANDLE*/, i32 %0)` under the system allocator in
  **10/10** runs of one batch and **7/10** of another (the reviewer measured 28/30 on
  `983f9361`) — a lottery whose odds drift from batch to batch; under the
  test allocator's LIFO mode **10/10**; under its no-reuse mode **0/10** (the reference:
  `%3 = mul nsw i32 %0, 7` classical, `add_hl(%1, %3)`).
- **v12 / w9 / w12 / w15** (9bhg's headline shape + the `ya` shape) DECLINE on `main`
  deterministically (they need 9bhg's accept); they are witnesses only on the composed
  binary. ⚠ **Owed at the 9bhg composition**: re-run `alias_gen5`/`alias_gen6` on the
  composed binary, and correct 9bhg's `Specialization.cpp` comment *"it is closed here at
  its source"* (F-9B-2) — that comment is not on `main`, so this track could not.
- **um24**: under the system allocator the four fixtures decline cleanly on the oracle;
  under LIFO and under NO-REUSE they SIGSEGV 10/10 (`Instruction::getFunction` on an
  erased `putchar`/`printf` sink / `exit.cond` select whose parent is null).
  `lowering_io_controlled_putchar` crashes 1/10 under no-reuse (the `std::set` walk is
  address-ordered, so whether the dead key is reached before a live key of `F` is an
  ASLR lottery).

## 3. Route choice

### 3.1 (a) total mechanism, not (b) a scrub at every erase site

The site list is a PREDICTION and it was measured to be wrong at scale: the dynamic
enumeration (§4.3) attributes **24098 deletions of a `TaintSet` key that NO explicit
scrub preceded**, in **2183 of 3228** corpus modules, to **29 distinct `cq::` producer
functions** — the reviewer's detector listed 6. Adding 29 scrubs (and the next one) is
exactly the discipline that failed. The containers make the question moot.

### 3.2 The container design (`ScrubOnDelete.h`) — and the two semantic traps it avoids

- **Drop-in API.** `scrub::Set<Storage, T*>` (over the UNCHANGED `std::set`/`SmallPtrSet`),
  `scrub::Map<K*, V>` (over `DenseMap`), `scrub::List<T*, N>` (over `SmallVector`),
  `scrub::PairSet` (`ClaimedRailRoots`). 535 `Tainted` references, 329 `count` calls:
  none needed an edit. What did: 16 `X.erase(std::remove(...))` scrubs →
  `X.erase_value(...)` (identical meaning), one `It + 1` → `std::next(It)`, the dead
  `runOnFunction` shim's `remove_if`, two `beforeTaint` snapshots (§3.4), and the
  `SpineOps` pointer type in `EmitInverse`/`BreakReversePlay` signatures.
- **Trap 1 — ITERATION ORDER (goldens must not move).** A physical removal would
  reorder survivors: `SmallPtrSet` erases in small mode by swapping the LAST element into
  the hole, and `DenseMap` hands a tombstone to the next insert. So the callback only
  MARKS the address dead; every query treats a dead address as absent. Survivors keep
  exactly the slots and order they had on the unfixed binary, and a fresh object inserted
  at a dead address is a NEW member (`insert().second == true`) that inherits the dead
  slot — precisely where the unfixed binary put it. A `List` nulls the dead SLOTS instead
  (a vector can hold one address twice; the dead slot stays null forever).
- **Trap 2 — ITERATION SAFETY.** `lowerMeasures` walks `MeasureCalls` and erases each
  call from inside the loop; a physical removal would shift the vector under it. Marking
  (or nulling) touches no storage, so a loop may erase the element it is visiting — pinned
  by the self-test for both a `std::set` and a `List`.
- **Identity, never RAUW.** `allUsesReplacedWith` is the inherited no-op, so a key is the
  OBJECT, exactly the raw pointer's meaning. (Tables that must follow RAUW were already
  `WeakTrackingVH` and are untouched.)
- **Mapped raw pointers** (`SharedCondFlags`, `IOTapeForFn`, `GuardedStores` values) are
  now `WeakVH`: a deleted mapped value reads back null instead of dangling.
- **A hook must disarm itself** inside `deleted()` (`setValPtr(nullptr)` first): a handle
  left registered on a finished `~Value()` is `llvm_unreachable` — UB in Release.

⚠ **An instrument caught the first build's bug, which is why it is in the record.** The
first subject build SIGILLed (a stack overflow) on four shipped fixtures: `List::contains`
called `llvm::is_contained(*this, V)`, and LLVM 19's `is_contained` forwards to a member
`contains()` when one exists — i.e. back into itself. The um24 harness surfaced it as
`rc=132` in every allocator mode before any other measurement ran. Fixed with an explicit
`std::find`, and the comment says why.

### 3.3 The deterministic allocator, and why it is a SEPARATE test binary

A dangling key does harm only when the allocator REUSES its address, so any pin run under
the system allocator is a lottery (r1B F-9B-3). `ir-pass/tools/cq_debug_alloc.cpp`
replaces the global `operator new/delete` with `CQ_OPT_DEBUG_ALLOC=lifo` (a freed block is
handed to the very next allocation of its exact size class: maximal, deterministic reuse)
or `=nofree` (nothing freed: the no-aliasing reference; a stale dereference reads the dead
object, whose parent is null). It is linked into:

- `cq-opt-debugalloc` — **cq-opt's own object files re-linked** with the allocator
  (`$<TARGET_OBJECTS:cq-opt>`, one extra link, no recompile), lit `%debugalloc-cq-opt`;
- `cq-scrub-selftest`.

It is deliberately NOT in `cq-opt`: the first version put it there and the launch cost was
measured at **+5 ms CPU per spawn with the variable UNSET** (88.4 → 93.3 ms, 60 launches,
`startcpu.py`; dyld/static-init cost of replacing the global allocator). `%cq-opt` runs
~3000 times per lit run, so the harness's default driver stays exactly as it was:
the pristine mutation build of the final tree produced a `cq-opt` bit-identical to the
worktree's, and `libCQPass.so` never contained any of it.

### 3.4 Two local snapshots were members of the class too

`repropagateControlMerges` and `propagateFromSeeds` computed a taint DELTA as
`Tainted − beforeTaint` over a raw `std::set` copy. A raw copy keeps a deleted member's
address, so a value tainted later at a reused address read as "already tainted" and
dropped out of the delta the caller adjudicates (`adjudicateTaintDelta`, the L1
obligation) — a latent under-adjudication in the SAME class. Both snapshots are now
`TaintedValueSet` (self-cleaning). No corpus module moved (the corpus has no member of
this sub-class either; §9 item 4).

### 3.5 bd um24 — the prescan, fixed in its own right

With the containers, `taint.Tainted` cannot yield a deleted key. But a LIVE key that is
momentarily DETACHED (parent null) would still make `getFunction()` a null dereference, so
`lowerLoops`' "cheap skip" now takes the spelling its two neighbours
(`declineDephasingUnmarkedLoopRails`, `promoteLoopCarriedHandleSeeds`) already used: walk
the live IR of `F`, ask the set. Same answer, no dereference of a member. ⚠ L7: both
neighbours' comments said the `lowerLoops` prescan was *"sound THERE because it runs before
any region flatten"* — FALSE (it SIGSEGVed on shipped fixtures; `lowerControlledIOSinks`
and `lowerLoops`' own `break` lowering erase before it). Corrected at the source.

## 4. The j8sk enumeration

### 4.1 Tables (the guard's scan of `struct TaintSet`, 52 members incl. nested fields)

| kind | members | disposition |
|---|---|---|
| `scrub::List<CallInst *, 8>` | `ThetaCalls` `PhiCalls` `MeasureCalls` `PhaseCalls` | self-cleaning (slot nulled) |
| `scrub::Set<std::set<Value *>>` | `Tainted` | self-cleaning (address-ordered storage unchanged) |
| `scrub::Set<SmallPtrSet<…>>` | `IntrinsicInvokes` `StaleDeclined` `ValueArmConeOps` `LiftedConsumers` `ControlOwnedRails` `PromotedCarriedHandlePhis` `DischargedFlagGates` `OutputRails` `GraveyardRails` `IterationLocalBlocks` `InPlaceRailOps` `PreLoopCommittedInPlaceOps` `UntaintedMergeRails` `UserSourceRotations` `UserChainedRotations` `UserPhaseRotations` `SpineOps` | self-cleaning |
| `scrub::Map<…>` | `BirthOrder` `HandleWidth` `SharedCondFlags`(→`WeakVH`) `ControlledRotations` `SpecHandleArgMask` `InPlaceRailIdx` `IOTapeForFn`(→`WeakVH`) `InLoopFlattenedPreds` `GuardedStores`(→`WeakVH`) | self-cleaning keys; raw mapped pointers became `WeakVH` |
| `scrub::PairSet` | `ClaimedRailRoots` | a pair dies with EITHER component |
| value handles already | `StaleQuantumReaders` `PeelClones` `RailCondReads` `CmpCondReads` `CondLiteralGates` `ScrubbedByReturnTaint` `RolledLoopRegionGates` `Round1RailGrants` | unchanged (null/follow on deletion by themselves) |
| **allowlisted, raw** | `RestoringRoutes` | NO WRITER anywhere (grep); the guard fails the day it gains one |
| **allowlisted, raw — RESIDUAL** | `BreakRegions` (`LoopBreakRegion`: raw block/value/`Loop *` fields) | a per-loop RECORD, dereferenced, never asked by identity; NOT closed here (§10, new bead) |

### 4.2 Static erase sites (`track_8e5r_probes/results/erase_sites.tsv`)

`enum_erase.py` extracts every IR-deleting call in `ir-pass/src/*.cpp` — `eraseFromParent`
(121), `eraseDeadDecls` (3), `removeUnreachableBlocks[Checked]` (4), `PromoteMemToReg` (2),
`ConstantFoldTerminator`, `dropAllReferences`, `MergeBlockIntoPredecessor` (1 each):
**133 sites in 28 files**, **63** with an explicit TaintSet scrub within 15 lines (a
heuristic column; the enclosing-function column is heuristic too — use the dynamic table
for attribution). Under the mechanism none of the 133 needs a scrub; the 63 existing
scrubs are kept as belt-and-braces (removing them is churn in Rule-13 files for no
observable change).

### 4.3 Dynamic attribution (`track_8e5r_probes/results/trace_sites.tsv`)

A trace build (NOT committed; `patch_trace.py`) prints a backtrace from `KeyHook::deleted()`.
A callback fires ONLY for a key nobody scrubbed (an explicit erase disarms the hook first),
so each trace is a deletion that relied on nothing before this change. Over all 3228
corpus modules: **24098 events in 2183 modules, 29 producers** (first `cq::` frame, `atos`):

| events | modules | producer | stage |
|---:|---:|---|---|
| 8819 | 1946 | `lowerRotations` | after `specialize` |
| 4722 | 240 | `lowerOps` | after |
| 4438 | 1787 | `lowerMeasures` | after |
| 2130 | 256 | `flattenPredMuxRegions` | before |
| 1093 | 213 | `RegionFlattener::convertPhis` | before |
| **980** | **139** | **`lowerShadowMemory`** (bd 8e5r's producer) | before |
| **628** | **144** | **`lowerQramReads`** (bd 8e5r's producer) | before |
| 593 | 384 | `emitPhaseKickbackRegion` | before |
| 117 | 45 | `promoteFp80Union` | before |
| 83 | 59 | `promoteRailBankCells` | before |
| 80 | 11 | `recognizeCtlzIdiomLoops` | before |
| 67 | 14 | `unrollConstTripLoops` | before |
| 52 | 23 | `emitAngleSelectRegion` | before |
| 45 | 24 | `emitPhaseKickbackNestRegion` | before |
| 43 | 8 | `removeUnreachableBlocksChecked` | before |
| 32 | 28 | `lowerIOSinks` (um24's putchar/printf sink) | before |
| 31 | 28 | `flattenRegion` | before |
| 31 | 23 | `retargetSite` (the fp3 producer 9bhg fixed at its source; still live on `main`) | during |
| 28 | 19 | `deleteGlobalPhases` | before |
| 19 | 7 | `emitSwitchPhaseRegion` | before |
| 19 | 8 | `deleteDeadPreservingCqOwned` | before |
| 19 | 19 | `emitBreakForward` (um24's `exit.cond`) | before |
| 14 | 9 | `promoteVolatileScalarLocals` | before |
| 4 | 3 | `lowerByRefInline` | before |
| 3 | 3 | `emitInPlaceRotationRegion` | before |
| 3 | 3 | `eraseDeadVolatileScalarStores` | before |
| 2 | 1 | `flattenRegionTree` | before |
| 2 | 2 | `foldConstantConeAndBranches` | before |
| 1 | 1 | `resolveSite` | during |

The trace cannot say WHICH table held the key (the hook knows its container, not its
member name). "before/during/after" is relative to `specialize()`, the stage whose clone
allocations turned a stale key into a miscompile; the "after" rows are the dangling
`Tainted`/`ThetaCalls`/`MeasureCalls` entries every accepted module carried into
`lowerOps`/`uncompute` (the reviewer's `pre-lowerOps`/`pre-uncompute` rows).

## 5. Pins — red on the oracle, green on the subject

| pin | kind | oracle | subject |
|---|---|---|---|
| `ir-pass/test/spec_scrub_dangling_key_clone_classical_mul.ll` (k65 as ONE module: `volatile` inputs instead of `argv`) | lit: `lifo` + `nofree` via `%debugalloc-cq-opt`, system via `%cq-opt`; FileCheck the clone body; `diff` all three | FAIL 20/20 (FileCheck: `cq_template_mul_i32_hl(i32 7, …)`) | PASS 10/10 |
| `iosink_reject_mux_literal_callee`, `lowering_reject_break_uncollected_clone`, `lowering_reject_inplace_rail_stale_w1_xor_{bareout,derived}` — one added RUN line each, `env CQ_OPT_DEBUG_ALLOC=nofree not %debugalloc-cq-opt` | lit | FAIL 80/80 (20 runs × 4; `Segmentation fault: 11`, `not` fails on a crash) | PASS 40/40 |
| `e2e-spec-scrub-dangling-key` (`tests/e2e/spec_scrub_dangling_key_{caller,lib}.c`, golden 33 lines) | e2e multi-TU, `cq-opt-debugalloc` under `lifo` | FAIL 10/10 (trace `cq_template_mul_i32_hl(h7, 5)` on freed `h7`, `add_hl(h1, 10)`; stage 2b `3 verified, 0 violation(s)`) — the oracle under `nofree` PASSES 5/5, i.e. the golden IS the no-reuse reference | PASS 10/10 (lifo), 5/5 (system) |
| `cq-scrub-selftest` (ctest `ir-pass-scrub-on-delete-selftest-{lifo,sysalloc}`) | per-member, every `TaintSet` table: insert, DELETE, then `count`/`find`/`lookup`/`contains`/`size`/`empty`/iteration by pointer comparison only; then a fresh object at the SAME address (LIFO reuse REQUIRED under `lifo`: 31/31) must NOT be a member, must insert as NEW, a map must yield the DEFAULT; plus copy, move and erase-while-iterating | n/a (tests the containers; see the mutation matrix §8) | 287 checks, 0 failures |
| `taintset-scrub-guard` (+ `-selftest`) | structural: no raw pointer-bearing member (any depth), every wrapped member exercised by the self-test, no stale allowlist | n/a | 52 members scanned, 5 aliases verified, 0 problems; 10/10 guard mutants killed (3 added after the matrix found M11, §8) |

What is pinned DETERMINISTICALLY: the self-test (independent of any allocation
coincidence — the dead-key checks are pointer comparisons, and the reuse is manufactured),
the guard, and the um24 `nofree` lines (null parent). What is pinned by a MANUFACTURED
COINCIDENCE: the k65 fixture and e2e slice — deterministic for a given binary under LIFO,
but an unrelated change to the pass's allocation sequence could move which freed block the
clone's `mul` lands on and turn them into non-witnesses while the defect stayed. The fixture
header says so; the self-test is the pin that does not depend on it.

## 6. Measurements

### 6.1 um24 (5 fixtures × 3 modes × 10 runs)

Oracle+alloc: the four named fixtures `rc=1` (system) / `rc=139` (lifo 10/10, nofree 10/10);
`lowering_io_controlled_putchar` 9/10 clean + 1/10 `139` under nofree. Subject: every cell
10/10 clean (`rc=1` / `rc=0`). The corpus sweeps (§6.3) add **seven e2e slices** that also
SIGSEGV on the oracle under LIFO and under nofree and `lowering_io_controlled_printf_sgt.ll`
(LIFO) — shipped goldens that pass only because macOS malloc reuses a same-size block
near-deterministically, for something with a readable parent field (r1B F-EB-7 wording).
⚠ **CORRECTED 2026-09-26 — THE SEVEN NAMES FIRST PRINTED HERE WERE WRONG** (an instrument
defect of exactly L10's kind, found while measuring the merged tree): `build_e2e_s1.py` paired
each `ctest -N -V` "Test command" line with the PREVIOUS test's name (ctest prints the command
BEFORE `Test #N: name`), so every e2e stage-1 module was NAMED one test late — contents complete
and correct, names shifted. The parser now pairs by test NUMBER, and the re-measured list (frozen
`main` ba80bda1 under r1B's independent no-reuse interposer, §13.4 D) is: `io-both-arm`,
`io-controlled`, `loop-break`, `loop-break-qq`, `loop-break-qq-derived`, `loop-break-qq-i64`,
`mixed-value-io` (the first print had `io-chained-theta` and `loop-value-accum` instead of
`loop-break-qq-i64` and `mixed-value-io`). r1B §4.5 quoted the old names off this record.

### 6.2 The alias families, repeated (`multirun.py`, 523 modules × 10 runs per config)

Reference = oracle+alloc under `nofree` (its own 10 runs were identical: 0/5230 non-ref).

| config | modules with any non-reference run | crashes | non-reference runs |
|---|---:|---:|---:|
| subject, system | **0/523** | 0 | **0/5230** |
| subject, lifo | **0/523** | 0 | **0/5230** |
| subject, nofree | **0/523** | 0 | **0/5230** |
| frozen oracle, system | 86/523 | 16 | 564/5230 |
| oracle+alloc, lifo | 80/523 | 11 | 800/5230 (80 modules × 10/10) |

Per family (oracle system / oracle lifo non-reference modules): `alias_gen` 21/16 (16 crash
under system), `gen2` 33/32 (k74), `gen3` 32/32 (k65), `gen5` 0/0, `gen6` 0/0 (both need
9bhg). Subject 0 everywhere. First measured on the intermediate build `557590cb`
(`subj2`, allocator still inside `cq-opt`); **re-run on the FINAL binaries** (`cq-opt`
`8ab548b7`, `cq-opt-debugalloc` `45f8a427`), reference again oracle+alloc `nofree`:
system **0/5230**, lifo **0/5230**, nofree **0/5230**, 0 crashes
(`results/fin_multi_fam.tsv`).

### 6.3 Corpus A/B (2284 lit fixtures + 399 single-TU + 22 multi-TU e2e stage-1 modules,
plus the 523 families = 3228; `ab.py`, denominators printed, null controls FIRST)

| A | B | modules | result |
|---|---|---:|---|
| subject:system | subject:system (**null, the SUBJECT twice**) | 3228 | 3228 same |
| oracle:system | oracle:system (null, the oracle twice) | 3228 | 24 differ — all family modules (14 STREAM, 6 CRASH, 2 A2D, 2 D2A): the instrument SEES flakiness |
| oracle:system | subject:system | 2705 (lit+e2e) | **2705 same — 0 A→D, 0 D→A, 0 stream, 0 string** |
| oracle+alloc:lifo | subject:lifo | 2705 | 2693 same, 12 CRASH→clean (5 lit + 7 e2e, §6.1) |
| subject:system | subject:lifo | 3228 | 3228 same |
| subject:system | subject:nofree | 3228 | 3228 same |
| oracle+alloc:**nofree** | subject:system | 3228 | 3216 same, 12 = the oracle's nofree crashes |

The rows above were measured on the intermediate `subj2`; **every subject row was re-run
on the FINAL binaries** with identical outcomes (`results/ab_condensed.txt`, the `fin_*`
entries; every A/B file is condensed there to its denominator, class counts and
non-`same` rows): the final `cq-opt`
twice 3228/3228 same; oracle vs final 2705/2705 same; final `cq-opt` (system) vs final
`cq-opt-debugalloc` under system / lifo / nofree 3228/3228 same each (so the debug driver is
output-identical to the harness driver); oracle+alloc `nofree` vs final 3216 same + the same
12 oracle crashes.

The last row is the strongest statement: **with the system allocator the fixed pass emits
exactly what the unfixed pass emits when no address is ever reused**, on every module where
the unfixed pass survives no-reuse at all.

### 6.4 Cost

Per-invocation CHILD CPU (`cputime.py`, interleaved A/B, under a load average of 50–290
from other agents — ratios only): oracle → oracle+alloc-in-cq-opt **+4.9%** (143 modules ×
3), oracle+alloc → scrub subject **+0.9%**; hence the allocator's move into its own binary
(§3.3). Launch-only (`startcpu.py`, 60 launches): oracle 144.6 ms, final `cq-opt` 147.1 ms,
`cq-opt-debugalloc` 154.1 ms. Full `lit` (2285 fixtures, private site configs, oracle and
final subject alternating, `tools/littime.sh`): oracle 100.1 s / 112.4 s, subject 97.6 s /
119.4 s, at load averages 62 / 245 / 205 / 377 before each run — indistinguishable at this
load. The oracle's runs show **exactly 5 failures, the 5 new red pins** (the k65 fixture +
the four um24 `nofree` lines); the subject 2284 passed + 1 XFAIL.

## 7. Final build, suites and gates (as literally run)

Final binaries (sha256 prefixes; unchanged by the last comment-only edits, re-hashed after
the final build): `cq-opt` **`8ab548b711175edd`**, `cq-opt-debugalloc` `45f8a42708146a12`,
`libCQPass.so` `223953e8a212a2a7`, `cq-scrub-selftest` `4f2a55bcbc02c45c`.

- **Full `ctest --test-dir build -j6`: 505/505 passed, 640.43 s**, load average 331 at
  start falling to 5 by the end — not comparable with a quiet-box figure. Counts: ctest
  505 (was 500: +`ir-pass-scrub-on-delete-selftest-{lifo,sysalloc}`, `taintset-scrub-guard`,
  `taintset-scrub-guard-selftest`, `e2e-spec-scrub-dangling-key`); `^e2e-` 486;
  `^e2e-slice-` 418; `ls ir-pass/test/*.ll` **2285** (+1); goldens 421 (+1).
  ⚠ An EARLIER full run on the same binaries went 504/505 — `code_map_drift` red because
  `CODE_MAP.md` was regenerated before a later comment edit shifted a line; regenerated, and
  the run above is the one quoted.
- `ir-pass-lit` inside it: 124.47 s; standalone `lit` §6.4.
- **`cmake --build build --target cq-opt-equivalence-full`: 2285 fixtures, 0 mismatches**
  (cq-opt vs stock `opt` + plugin: stdout, stderr and exit code).
- `python3 tools/update_code_map.py --check`: clean.
- The e2e slice, lit fixture and um24 lines red/green: §5.

## 8. Mutation matrix (`tools/mutate.py`; `results/mutation_matrix.log`)

Each mutant is applied to a private copy of the final source tree (anchors asserted to
occur exactly as expected; the tree is sha256-verified restored afterwards), REBUILT
(`cq-opt`, `cq-opt-debugalloc`, `cq-scrub-selftest`), and every detector is run:
D1 the k65 lit fixture ×3, D2 the four um24 fixtures ×3, D3 the e2e slice under LIFO ×3,
D4 the self-test (LIFO), D5 the structural guard, D6 a corpus A/B of all 3228 modules
(mutant `debugalloc:lifo` vs final `debugalloc:lifo`). Two NULL controls run FIRST.

| mutant | what it breaks | D1 k65 | D2 um24 | D3 e2e | D4 selftest | D5 guard | D6 corpus (of 3228) |
|---|---|---|---|---|---|---|---|
| pristine | nothing (null; `cq-opt` bit-identical to the worktree's, `8ab548b7`) | 0/3 | 0/12 | 0/3 | 0 fail | pass | 0 moved |
| M0 | swap two independent statements in `Set::erase` (null; binary changes) | 0/3 | 0/12 | 0/3 | 0 fail | pass | 0 moved |
| M1 | `KeyHook::deleted` never notifies (mechanism OFF) | **3/3** | **8/12** | **3/3** | **183 fail** | pass | **80** (29 A→D, 11 crash, 40 stream) |
| M2 | `Set` never marks dead | **3/3** | **7/12** | **3/3** | **130** | pass | **80** |
| M3 | `Map` never marks dead | 0/3 | 0/12 | 0/3 | **38** | pass | 0 |
| M4 | `List` never nulls a slot | 0/3 | 0/12 | 0/3 | **13** | pass | 0 |
| M5 | `PairSet` never drops a pair | 0/3 | 0/12 | 0/3 | **2** | pass | 0 |
| M6 | `Set::count` ignores dead | **3/3** | 0/12 | **3/3** | **57** | pass | **80** |
| M7 | `Set` iteration yields dead keys | 0/3 | **7/12** | 0/3 | **18** | pass | 0 |
| M8 | `Map::lookup` returns a stale value | 0/3 | 0/12 | 0/3 | **14** | pass | 0 |
| M9 | revive-insert reports "not new" | 0/3 | 0/12 | 0/3 | **18** | pass | 0 |
| M10 | revive `operator[]` keeps the stale value | 0/3 | 0/12 | 0/3 | **5** | pass | 0 |
| M11 | `using TaintedValueSet = std::set<Value *>` (raw revert) | **3/3** | 0/12 | **3/3** | **no build** | ⚠ **pass (MISSED)** → fixed, see below | **80** |
| M12 | `lowerLoops` prescan back to key-dereferencing | 0/3 | 0/12 | 0/3 | 0 | pass | 0 — EQUIVALENT (below) |

Readings:

- **Every non-equivalent mutant is killed by at least one detector, and by the
  self-test in all but M11** (where the self-test does not compile — a build failure is a
  loud kill, but it is the guard's job to name it). **Six mutants (M3, M4, M5, M8, M9,
  M10) are killed ONLY by the self-test**: the corpus has no module in which a map, list
  or pair-set alias changes an emitted stream under LIFO. That is the empty-quadrant
  lesson (§4k) measured, and it is why the per-member self-test exists.
- The **80** D6 movers of M1/M2/M6/M11 are exactly the 80 family modules the oracle gets
  wrong under LIFO (§6.2): the defect IS the `Set::count` alias; M7 alone (iteration)
  reproduces um24 without moving any stream.
- ⚠ **M11 FOUND A HOLE IN THE GUARD — L10's failure mode, a PASS.** The guard accepted a
  member as self-cleaning by the SPELLING of its type (`TaintedValueSet`), and retargeting
  the alias in `ScrubOnDelete.h` reverted `Tainted` to a raw `std::set` with the guard
  reporting 0 problems. Clause (4) now verifies that every trusted alias still resolves to
  a `scrub::` container, and the guard's own self-test carries the M11 text plus two more
  alias mutants (10/10 killed). The fix is to the INSTRUMENT, not the pass, so the matrix
  was not re-run for it.
- **M12 is an EQUIVALENT mutant under the mechanism, by argument, and no pin can separate
  it.** With self-cleaning `Tainted`, the old key-dereferencing prescan only ever visits
  live keys; it would still null-dereference a live key that is DETACHED (parent null),
  and no pipeline stage leaves a detached instruction in `Tainted` at `lowerLoops` (not
  constructed; argued from the stage list, not proved). The rewrite is defence in depth
  and matches its neighbours' spelling; M7+M12 together would re-open um24.

## 9. What a Rule-13 reviewer should attack first

1. **The deferred-dead semantics.** `Set::insert` at a dead address returns `true` and
   re-arms; `Map::operator[]` at a dead address RESETS the stale mapped value; `size()` is
   `S.size() - Dead.size()` and relies on `Dead ⊆ S` (maintained by `keyDeleted`'s
   `S.count` check, `erase`'s `Dead.erase`, `clear`). Try to break `Dead ⊆ S`.
2. **The "order is preserved" claim.** It is relative to the unfixed binary UNDER THE SAME
   ALLOCATION SEQUENCE; the fix itself allocates (hooks), so absolute addresses differ, and
   `Tainted` is address-ordered. Evidence that emitted streams do not depend on it: the
   subject is byte-identical across three allocator modes on all 3228 modules. Evidence is
   not proof — look for a stage that iterates `Tainted` and EMITS in iteration order.
3. **Code that relied on a dangling key staying a member.** Any site that asks
   `Tainted.count(V)` for a `V` it knows was deleted now gets `false` (was `true`). The
   no-reuse A/B shows no output depends on it over the corpus; grep for values collected
   before an erase and asked about after it.
4. **The residuals (§10)**: 40 LOCAL raw snapshots of these tables (`SmallPtrSet GateCalls(
   taint.ThetaCalls…)` and friends) that are exactly as safe as the window they are held
   across; `BreakRegions`' raw record fields (and its `Loop *` into a destroyed
   `LoopInfo`); pointer-keyed state OUTSIDE `TaintSet` (`ControlPlan` regions, `SpecPlan`,
   file-static ledgers such as `exitDischargeObligations()`).
5. **`cq-opt-debugalloc` as an instrument.** It replaces `operator new/delete` only; aligned
   new/delete stay libc++'s (consistent pairs). LIFO mode writes the free-list link into a
   freed block's first word. Try to make a pin pass vacuously.

## 10. What I did NOT attack, residuals, new beads

- **Local raw snapshots** of `TaintSet` tables (~40 sites building a plain container from
  `taint.X.begin()`): not audited site by site — **bd `test_C_libtooling-ibtq`** (P3).
- **`BreakRegions`' raw record fields** (allowlisted in the guard): **bd
  `test_C_libtooling-emof`** (P3). Its `Loop *L` points into a `LoopInfo` that
  `lowerLoops` destroys; it is written and, by grep, never read.
- **Pointer-keyed state OUTSIDE `TaintSet`** (`ControlPlan`/`ControlRegion` records,
  `SpecPlan`, file-static ledgers like `exitDischargeObligations()`, `ClonePlan` maps): out
  of j8sk's scope (keys of the taint set and its side maps); not enumerated.
- **No `+Asserts`/ASan build.** ASan's quarantine would SUPPRESS the reuse this class needs
  (r1B's argument, agreed); the deterministic allocator plus the self-test is the stronger
  instrument here. Not attempted: `-DLLVM_ENABLE_ABI_BREAKING_CHECKS` epoch checks.
- **The 9bhg composition** (v12/w9/w12/w15 are witnesses only there; F-9B-2's comment) —
  owed when 9bhg lands on or after this change.
- **Cross-function / multi-module** shapes beyond the 22 multi-TU e2e modules and the 523
  two-TU family programs (bd `1yeu`'s structural gap applies here too).
- Performance was measured under a load average of 50–377 from concurrent agents; ratios
  and interleaved runs only, no quiet-box absolute.

### 10b. Beads

- `8e5r`, `um24`, `j8sk`: notes appended (commit, mechanism, measurements, this record);
  **not closed** — the change owes its Rule-13 rounds.
- NEW: `ibtq` (local raw snapshots), `emof` (`BreakRegions` records), both discovered-from
  `j8sk`.

## 11. Source comments corrected (L7)

- `LoopLowering.cpp` × 2 (`declineDephasingUnmarkedLoopRails`, `promoteLoopCarriedHandleSeeds`):
  the "`lowerLoops`' prescan is sound THERE" claim — FALSE, now says so.
- `RegionFlatten.cpp` × 2, `SwapRouteEmit.h` (§6.1 step 9), `MergePhiPeel.cpp` ("`Tainted`
  is a `std::set<Value *>`"), `TaintPropagation.h` (`StaleDeclined`, the new struct-level
  invariant block, the three `WeakVH` mapped values): the explicit scrubs are now
  belt-and-braces, not the defence.
- `TaintPropagation.cpp` × 2: why the `beforeTaint` snapshots must be self-cleaning.
- NOT corrected here (not on `main`): 9bhg's `Specialization.cpp` *"closed here at its
  source"* and TRACK_9BHG §3/§7 item 6 (F-9B-2) — owed at the 9bhg composition.

## 12. After the Rule-13 rounds — the merge with `main` and the delta (2026-09-26)

Commits on `worktree-agent-a2cf1f874e5ec99d2`, in order, each separate; the reviewed
`818f8afa` is intact (a MERGE, not a rebase). Not merged into `main`, not pushed.

| commit | what | kind |
|---|---|---|
| `cb3e6609` | the two review records, verbatim | records |
| `0b07629e` | merge `main` `ba80bda1` (bd d88e). Every source file auto-merged; the one conflict was the generated `CODE_MAP.md` (regenerated). **Guard RED at this commit, by design** — r1B F-EB-1's positive control firing on d88e's raw `LiftedMergePhi::F` | merge |
| `152fafe1` | F-EB-1 / bd lin4 | LOGIC |
| `c150d983` | F-EA-2 / F-EB-2 / bd urf8 (c3gf closed as its duplicate): the semantic guard | instrument |
| `c268f545` | F-EA-1 / bd jct8, F-EA-7, F-EB-10, F-EB-4 / bd m91g, F-EA-9 | LOGIC + instrument |
| `e24126b1` | F-EA-3, F-EA-5, F-EA-8, F-EB-5, the CLAUDE.md build line | COMMENTS ONLY — proved by `tools/comment_only_check.py` (comment-stripped diff, null + positive controls): 10 code files, 0 non-comment changes; and the rebuilt `cq-opt` is BIT-IDENTICAL to `c268f545`'s (`57f0348465bab76f`) |
| (this) | this record, §12–§14 | record |

### 12.1 EXACTLY which lines of LOGIC changed since `818f8afa` (for the delta reviewer)

Everything else in `git diff 818f8afa..HEAD` is d88e's own (`ba80bda1`, reviewed on its own
track), the guard tool, the test drivers, records, or comments (proved above).

1. **`TaintPropagation.h` `struct LiftedMergePhi`** (d88e's): `llvm::Function *F = nullptr;` →
   `llvm::WeakVH F;`. `Base`/`Incomings` unchanged (`WeakTrackingVH` — the re-ask must FOLLOW a
   RAUW; the reason is written at the member).
2. **`TaintPropagation.cpp` `declineFalsifiedMergePhiLifts`**: `(void)M;` removed; a new first
   step `Fn = cast_or_null<Function>(L.F)` — if null, DECLINE with the same `kMsgClassicalPhi`
   anchored on the first defined function of `M` (return `false` only if `M` has none); the
   diagnostic uses `Fn` instead of `L.F`. Argued unreachable (no Function is erased in the
   window); the non-null path is byte-identical (the 21 d88e fixtures: 21/21 same vs `ba80bda1`).
3. **`TaintPropagation.cpp` `repropagateControlMerges`**: `DenseMap<const BasicBlock *, unsigned>
   Round1FlattenedPreds(taint.InLoopFlattenedPreds.begin(), …end())` →
   `ScrubMap<const BasicBlock *, unsigned> Round1FlattenedPreds = taint.InLoopFlattenedPreds;`
   (a self-cleaning copy). **`LoopPlan.h` / `LoopLowering.cpp` `collapseFlattenedLoopRails`**:
   the `AlreadyProcessed` parameter type follows (`const ScrubMap<…> *`); its body is unchanged
   (`find`/`end`/`->second` keep their meaning; a dead key is absent). `LoopPlan.h` now includes
   `ScrubOnDelete.h`, which therefore gained `llvm/IR/Instructions.h` (F-EA-9 — the build broke
   without it, reproducing r1A's finding).
4. **`Specialization.cpp` `buildClone`, the inner-site fp-rebuild migration**: DELETED
   `cloneTaint.Tainted.erase(OldInner)` and the five-line `BirthOrder` migration of `OldInner`
   onto `Inner`. Kept: `cloneTaint.Tainted.insert(Inner)` and the `HandleWidth` record. Ground
   (written at the site): the erase was by a DEAD pointer (redundant under self-cleaning, and a
   latent hazard — an erase by a dead address removes a LIVE object revived there); the
   migration was dead by construction (`cloneTaint.BirthOrder` is written only by
   `lowerCloneSelect` / `lowerQramReads` / `lowerOps`, all after this loop). Moving the lookup
   before the erase would have moved a dead lookup, so it was deleted. Stream unchanged (§13.4 B).
5. **Test drivers only (not the pass)**: `cq_debug_alloc.cpp` mode parsing (unknown value /
   non-Apple `lifo` → exit 2); `scrub_selftest.cpp` `main` (`--require-reuse`, mode validation,
   `skipBranch` counting); `lit.cfg.py` (`%debugalloc-cq-opt` never falls back; missing or
   older-than-`cq-opt` → `lit_config.fatal`); `ir-pass/CMakeLists.txt` (`--require-reuse`, the
   guard's `--clang`/`--llvm-include`).

## 13. Measurements on the merged tree (as literally run)

Final binaries (sha256): `cq-opt` `57f0348465bab76f85c80298536d83f431362aa5808ca20b9d17ad4ac8cd63ab`,
`cq-opt-debugalloc` `ff15a90315ca94987db3554fb5a8c98927e513fe94fc5c495ce050712e754ee1`,
`libCQPass.so` `bb9c7a0653f1e50bbfc6373db36aefe8699d2e896bbd98fed41a09d09d91b731`,
`cq-scrub-selftest` `97bc7e5159ac2dab6c75c26df218215ae308ce1033d90e3eee985872cb515e7a`.
ORACLE: frozen `main` `ba80bda1` `cq-opt` `e587c19152bf39e5`. The oracle cannot read
`CQ_OPT_DEBUG_ALLOC`, so its allocator runs use **r1B's INDEPENDENT interposer**
(`review_r1B_8e5r/probes/rb8_interpose.cpp`, `DYLD_INSERT_LIBRARIES`, dylib `dda46979…`) on the
unmodified frozen binary; `tools/ba80_debugalloc_wrapper.sh` maps `CQ_OPT_DEBUG_ALLOC` onto it so
the lit pins run against the oracle unchanged. Corpus: 2306 lit fixtures + 425 e2e stage-1
modules (400 single-TU + 25 multi-TU, rebuilt with the FIXED name pairing, §14.2) + the 523
alias-family programs = **3254**. Sweep log: `results/merged_final_sweeps.log`.

### 13.1 The pins, red on the oracle, green on the merged tree

| pin | oracle `ba80bda1` (+ r1B interposer) | merged tree |
|---|---|---|
| lit `spec_scrub_dangling_key_clone_classical_mul.ll` | FAIL 10/10 (FileCheck: `cq_template_mul_i32_hl(i32 7, i32 %0)`) | PASS 10/10 |
| the four um24 `nofree` lines | FAIL 40/40 (`Segmentation fault: 11`) | PASS 40/40 |
| `e2e-spec-scrub-dangling-key` (lifo) | FAIL 10/10; under `nofree` PASS 5/5 (the golden IS the no-reuse reference) | PASS 10/10 |
| full `lit` | 2300 passed + 1 XFAIL, **exactly 5 failed = the 5 new pins** (twice) | 2305 passed + 1 XFAIL (twice) |

### 13.2 `cq-scrub-selftest`, every mode

`lifo --require-reuse` ×3: 287 checks, 0 failures, reuse 31/31 (REQUIRED), 0 branches skipped.
system: 287/0, reuse 31/31 (not required). `nofree`: 206/0, **31/31 aliasing branches (81
checks) SKIPPED — reported** (F-EB-10). `CQ_OPT_DEBUG_ALLOC=Lifo` / `LIFO`: exit 2, message on
stderr. `--require-reuse` without `lifo`: exit 2.

### 13.3 The guard

Clean header: 57 members walked, 0 problems (`results/guard_v2_clean.txt`). `--selftest`: 2 null
controls clean, 57 mutants all refused for the RIGHT reason (`results/guard_v2_selftest.txt`).
r1A `guard_bypass.py` UNMODIFIED: 15 candidates, **0 MISSED**; r1B `guard_fool.py` UNMODIFIED: 23
mutants, **0 MISSED**, controls OK (`results/guard_v2_vs_r1{A,B}_corpus.txt`; r1B G2/G24 are
killed there by a compile error — undeclared `SmallSet`/`Base0` in their harness — and their
right-reason versions are in `--selftest`). Fail-closed controls: a nonexistent `--clang` and a
wrong `--llvm-include` both exit 1 with a message.

### 13.4 Corpus A/B (null controls FIRST, denominators printed)

| | A | B | modules | result |
|---|---|---|---:|---|
| A | subject `cq-opt` (system) | the same, again (**null, the SUBJECT twice**) | 3254 | 3254 same |
| A2 | subject under r1B `rand` (scrambled address order) | the same, again | 3254 | 3254 same |
| B | `main` ba80bda1 (system) | subject (system) | 2731 (lit + e2e) | **2729 same, 2 STREAM** — both the 8e5r k65 program (the lit fixture and its e2e module), where the ORACLE emits the wrong `cq_template_mul_i32_hl(7, …)`; 0 A→D, 0 D→A, 0 string moves |
| C | subject `cq-opt` (system) | `cq-opt-debugalloc` system / lifo / nofree | 3254 ×3 | 3254 same ×3 (the debug driver is output-identical; the subject is allocator-independent) |
| D | `main` ba80bda1 under r1B **no-reuse** | subject (system) | 3254 | **3241 same, 13 = oracle SIGSEGVs** (6 lit: `iosink_reject_mux_literal_callee`, `lowering_io_controlled_both_arm`, `lowering_io_controlled_putchar`, `lowering_reject_break_uncollected_clone`, `…_xor_bareout`, `…_xor_derived`; 7 e2e: `io-both-arm`, `io-controlled`, `loop-break`, `loop-break-qq`, `loop-break-qq-derived`, `loop-break-qq-i64`, `mixed-value-io`) |
| E | subject (system) | subject under r1B `lifo` / `fifo` | 3254 ×2 | 3254 same ×2 |

### 13.5 Alias families, 523 programs × 10 runs × 7 configs (`results/merged_F_multi_fam.tsv`)

Reference = `ba80bda1` under r1B `nofree` (its own 10 runs: 0/5230 non-reference).

| config | modules with any non-reference run | crashes | non-reference runs |
|---|---:|---:|---:|
| subject `cq-opt`, system | **0/523** | 0 | **0/5230** |
| subject `cq-opt-debugalloc`, lifo | **0/523** | 0 | **0/5230** |
| subject `cq-opt-debugalloc`, nofree | **0/523** | 0 | **0/5230** |
| subject `cq-opt`, r1B `fifo` | **0/523** | 0 | **0/5230** |
| `main` ba80bda1, system | 81/523 | 12 | 676/5230 |
| `main` ba80bda1, r1B `lifo` | 80/523 | 11 | 800/5230 |

### 13.6 Suites and gates

- d88e's family on the merged tree: lit filter `classical_mux_phi|onereg|spec_lift|lift` 63/63;
  its 4 e2e entries 4/4; its 21 fixtures byte-identical to `ba80bda1` (null subject-twice 21/21).
- **`cmake --build build --target cq-opt-equivalence-full`: 2306 fixtures, 0 mismatches.**
- `python3 tools/update_code_map.py --check`: clean.
- **Duplicate-body scan** (L8, `tools/dup_body_scan.py`, controls first): 2306 fixtures, 2297
  bodies, 9 groups — **IDENTICAL to the 9 groups on `main` ba80bda1** (pre-existing deliberate
  twins); the merge resurrected nothing (`results/merged_dup_body_scan.txt`).
- Full `lit` (private sites, alternating): oracle 59.0 / 68.0 s, subject 73.3 / 67.0 s at load
  averages 10 / 49 / 39 / 54 before each run — not resolvable at that load; r1B §6 measured
  +1.2% ± 0.35% CPU per invocation, all launch cost, in a quiet window.
- **Full `ctest --test-dir build -j6`: 509/509 passed in 587.18 s** (load average 36 at the
  start, 4 at the end — not a quiet-box figure). `ir-pass-lit` 91.55 s,
  `taintset-scrub-guard-selftest` 66.44 s (it compiles the header 59 times; the heaviest new
  entry), `taintset-scrub-guard` 5.40 s, both `ir-pass-scrub-on-delete-selftest-*` ≤ 0.03 s,
  `e2e-spec-scrub-dangling-key` 2.57 s. Counts: ctest 509 (505 at `818f8afa` + d88e's 4).
  `ls ir-pass/test/*.ll` 2306.

## 14. Rule-13 dispositions

| id | sev | disposition |
|---|---|---|
| F-EA-1 (bd jct8) | P3 | **FIXED** `c268f545` — self-cleaning `ScrubMap` snapshot; the "safe direction" comment corrected as FALSE (§12.1 item 3) |
| F-EA-2 (bd c3gf) | P3 | **FIXED** `c150d983` together with F-EB-2; c3gf **closed as a DUPLICATE of urf8** |
| F-EA-3 | P3 | **CORRECTED AT THE SOURCE** `e24126b1` — the LoopLowering / TaintPropagation.h passages, "~180" → 133, "cannot move" → measured; lower-priority scrub rationales marked belt-and-braces |
| F-EA-4 | P3 | **RECORDED** (§14.1): the second UAF consumer, `propagateWorklist` via `repropagateControlMerges`, and its extra crashing fixtures |
| F-EA-5 | P3 | **DOCUMENTED** `e24126b1` — the insert-a-deleted-pointer precondition in `ScrubOnDelete.h` and `TaintPropagation.h` |
| F-EA-6 | P3 | **FILED, not built** — bd `test_C_libtooling-r77x` (a non-owner-deleted user intrinsic is now skipped silently; make it a loud postcondition) |
| F-EA-7 | P3 | **FIXED** `c268f545` — the dead migration and the dead-pointer erase deleted with the reason at the site (§12.1 item 4) |
| F-EA-8 | P3 | **DOCUMENTED** `e24126b1` — at the headers and at each of the three event-witness readers |
| F-EA-9 | P3 | **FIXED** `c268f545` — `ScrubOnDelete.h` includes `llvm/IR/Instructions.h` (verified: a TU including only it compiles) |
| F-EB-1 (bd lin4) | **P1** (merge obligation) | **RESOLVED** `152fafe1` — `WeakVH F` + null-checked `cast_or_null` at the reader; `Base`/`Incomings` stay `WeakTrackingVH` with the reason at the member; not AssertingVH, not an allowlist entry. The guard's selftest carries "d88e's raw F restored" and "AssertingVH for F" as mutants |
| F-EB-2 (bd urf8) | **P2** | **FIXED** `c150d983` — the guard asks the compiler (§13.3); urf8 updated, not closed (owes the delta review) |
| F-EB-3 (bd p5p7) | P3 | **KEPT as the bead, not built** (positive-control counters on the k65 pins) |
| F-EB-4 (bd m91g) | P3 | **FIXED** `c268f545` + `e24126b1` — lit fatal on a missing/older driver (controls fired), loud exit on an unknown mode or non-Apple `lifo`, no fallback to `%cq-opt`, CLAUDE.md names all three targets. Residual: the e2e ctest passes the driver path directly (lit is the fence) |
| F-EB-5 | P3 | **CORRECTED** `c268f545`/`e24126b1` — "maximal reuse" scoped to non-aligned new/delete in `cq_debug_alloc.cpp`, the fixture header and the e2e CMake comment |
| F-EB-6 | P3 | **RECORDED** (§14.1) |
| F-EB-7 | P3 | **RECORDED** (§14.1) |
| F-EB-8 | P3 | **NOTED** — `ab.py` compares the FIRST `error:` line only; r1B's `ab_full.py` closed it by measurement (2705/2705 same incl. warnings). Not re-run on the merged tree |
| F-EB-9 | P3 | **OWED AT THE 9bhg COMPOSITION** — 9bhg's post-`resolveSite` `taint.Tainted.erase(OldSite)` block erases by a dead pointer; delete it at that merge (the reasoning of F-EA-7 here) and correct F-9B-2's comment |
| F-EB-10 | P3 | **FIXED** `c268f545` — §13.2 |

### 14.1 The three record items (F-EA-4, F-EB-6, F-EB-7), stated

- **F-EA-4 — the UAF population is wider than um24's one consumer.** Under r1A's scribble
  allocator the oracle crashes in TWO consumers: `lowerLoops`' prescan (um24) AND
  `propagateWorklist` ← `repropagateControlMerges`, whose round-2 worklist
  `WL(taint.Tainted.begin(), end())` walks a DEAD key's `users()`. Under a reusing allocator
  that second route is itself an entry into the 8e5r class (it reads the use list of whatever
  object now occupies the address and taints its users). Crashing lit fixtures this record did
  not name before: `control_phase_kickback_onward_merge`,
  `control_swap_{reject_,}switch_datamux_angle{,_runtime}`, `lowering_io_controlled_both_arm`
  (the last also in §13.4 D). The subject crashes on 0 modules under every allocator run.
- **F-EB-6 — what closes um24's broader population is the ITERATION SKIP, not the prescan
  rewrite.** r1B's counter build shows an iteration reaching a dead key in 12 shipped modules
  (6 accepts) on the fixed binary — iterate-and-dereference consumers other than the prescan
  exist (`TaintPropagation.cpp`'s round-2 worklist, `AbortParkEmit.cpp:229`). The container's
  dead-skip closes them all. Per r1B §1.2, `lowering_reject_break_uncollected_clone`'s `nofree`
  line is killed only by the two mutants together (M7 iteration-skip off ∧ M12 prescan
  reverted) — consistent with §8's "M12 EQUIVALENT" — and its header could say so (not done).
- **F-EB-7 — no LIVE flaky surface on the shipped corpus, and a LARGE latent one.** r1B: 0 of
  2705 shipped modules vary across 10 system-allocator runs on the oracle; 0/650 um24 crashes at
  N=50. But under the system allocator **225 shipped modules (214 of them accepts) had ≥ 1
  TaintSet lookup decided by a deleted address** (573 queries), with **0 output change** on the
  corpus (§13.4 B). So the A/B's "0 movers" is evidence about EXERCISED modules, not an empty
  quadrant (1029 of 3228 modules exercise the dead-marking under the system allocator).

### 14.2 An instrument defect of mine, found while measuring (L10)

`build_e2e_s1.py` paired each `ctest -N -V` command with the PREVIOUS test's name (ctest prints
`N: Test command:` BEFORE `Test #N: name`). Module CONTENTS were complete and correct, so every
A/B count stands; every per-module NAME from the e2e corpus was one test late — the seven e2e
names of §6.1 were wrong (corrected there), and r1B §4.5 inherited them. Found because an A/B
mover NAMED `e2e-spec-fp80-union` contained `k1`'s `mul nsw i32 %0, 7`. The parser now pairs by
test number; every name in §13 was re-measured with it.
