# Rule-13 round r1A on bd 8e5r / um24 / j8sk (`818f8afa`): container semantics and their consumers

Reviewer lane: container semantics (`ir-pass/include/ScrubOnDelete.h`) and how every
consumer relies on them. The concurrent round covers the verification side (pin vacuity,
the test allocator, the harness, composition with d88e/9bhg, and performance). Subject:
`cq-opt` `8ab548b711175edd`, `cq-opt-debugalloc` `45f8a42708146a12`, both unmodified and
used only for reads. Oracle: `cq-opt.main_e846` `b1603d237fc3a739`. My private rebuild of
`def1b088` produced a bit-identical `cq-opt` (`b1603d237fc3a739`), so the build null
control fired. All instrumented and mutant builds ran in private worktrees under the
session scratchpad, and those worktrees have been removed.

## Verdict: **CLEAR-WITH-ITEMS**. 0 P1, 0 P2, 9 P3.

The containers are semantically correct as specified. I found no wrong membership answer,
no change in iteration order that reaches emission, no stale key still read as live, no
live key read as dead, and no crash. Across 3228 modules the subject produced the same
output (rc, stdout sha256 and first error line) under every allocator mode I added: a
scribble allocator that never frees and fills each freed block with 0xA5, and a shuffle
allocator that assigns every allocation to one of 8 arenas at random, under three seeds.
I also instrumented every query that returns a different answer from a raw container. On
the corpus that instrument logs only the UAF reads the change removes. Each item below is
latent, an instrument gap, or a record/comment correction. None is a live defect.

## Instruments, with controls and denominators (every sweep covers all 3228 modules of `t8e5r/corpus_all.lst`)

| # | instrument | control | result |
|---|---|---|---|
| I1 | **Behaviour-change logger** (`probes/instrument_scrub.py` applied to a private copy of the header). It logs every `count`/`find`/`lookup`/`contains`/`erase`/`insert`/`operator[]`/`try_emplace`/iteration/`size`/`empty`/copy whose answer differs from a raw container's, with the call site (`__builtin_FILE/LINE` default arguments). Under `CQ_OPT_DEBUG_ALLOC=nofree` no address is reused, so **every logged event is a dead pointer being queried, yielded or counted**, which is exactly the set of behaviour changes that go beyond the aliasing fix. | null: instrumented binary equals the subject on 3228/3228. positive: DEADITER/DEADERASE events fire, and under the system allocator 907 modules log recycled-address hits | **nofree: events in 14 modules only.** `DEADITER` at `TaintPropagation.cpp:2150` ×13 and `:1829` ×6, `DEADCOPY` ×9 (the two `beforeTaint` copies), `DEADERASE` at `Specialization.cpp:938` ×2. **Zero** dead-pointer `count`/`find`/`lookup`/`contains`, zero `empty()` flips, zero `size` reads, zero dead inserts (`results/events_sw_inst_nofree.txt`) |
| I2 | **Scribble allocator** (`probes/add_scribble_mode.py`): never frees, fills each freed block with 0xA5. Any read through a pointer to a deleted object then faults deterministically. This covers every pointer-holding record in the pass, including `BreakRegions`, `ControlPlan`, local snapshots and the new containers' own hook arming. | positive: the oracle under scribble crashes **15/3228** | **subject: 0 crashes, 3228/3228 identical to the system allocator** |
| I3 | **Shuffle allocator** (`probes/add_shuffle_mode.py`): no reuse, 8 bump arenas chosen by xorshift. The address order of IR objects becomes a seed-dependent permutation of creation order, so `std::set<Value*>` order and every hash order both move. | positive: the oracle's `lowering_io_controlled_putchar.ll` crashes on 6/20 seeds (um24's address-ordered walk), the subject on 0/20 | **seeds 1, 2 and 3: 3228/3228 identical each.** No emitted stream depends on heap addresses |
| I4 | **Deleter backtraces for listed intrinsics** (`probes/instrument_listnull.py`). Each nulled `ThetaCalls`/`MeasureCalls`/`PhaseCalls` slot logs the backtrace of whatever deleted the call, resolved with `atos`. | owners expected | 8577 events in 2078 modules: `lowerMeasures` 4421, `lowerRotations` 4153, plus 3 from `removeUnreachableBlocksChecked`. The last three sit inside `flattenPredMuxRegions`' fixpoint, which precedes a full `taint = propagate`, and they delete dead code in a module that declines anyway (`results/listnull_deleters.txt`) |

## Findings

| id | sev | attribution | one line |
|---|---|---|---|
| F-EA-1 | P3 | INTRODUCED, unreachable | `Round1FlattenedPreds` is a raw snapshot, while `InLoopFlattenedPreds` is self-cleaning and its `operator[]` resets a recycled key. A new Pred at a recycled address now makes the round-2 onward pass **skip** a loop. bd `test_C_libtooling-jct8` |
| F-EA-2 | P3 | INTRODUCED (instrument) | `taintset-scrub-guard` misses **14 of 15** natural raw-member spellings, `X{}` among them. bd `test_C_libtooling-c3gf` |
| F-EA-3 | P3 | INTRODUCED by omission (L7) | 8 source comments still describe tables as "raw / never scrubbed" and argue safety from that. One says "~180 erase sites" in three places against a measured 133 |
| F-EA-4 | P3 | PRE-EXISTING, fixed; record | The UAF population is wider than um24's single consumer. Under scribble the oracle also crashes in `propagateWorklist`, called from `repropagateControlMerges` over dead `Tainted` keys, and 4 of those lit fixtures appear in neither the track record nor the bead |
| F-EA-5 | P3 | INTRODUCED, latent | A scrub container dereferences the key on `insert`/`operator[]`, so inserting a pointer to an already-deleted Value is now a UAF and registers a handle on freed memory. A raw container tolerated it. The header does not state the precondition |
| F-EA-6 | P3 | INTRODUCED behaviour change | A listed user intrinsic deleted outside its owner inside the window used to be UB (a dangling slot the owner dereferenced). Now the owner silently skips it. 0 instances on the corpus. The mechanism can now check this cheaply |
| F-EA-7 | P3 | INTRODUCED dead code | `buildClone`'s BirthOrder migration looks up `OldInner` after `retargetSite` erased it, so on the subject that half can never fire. It is inert today |
| F-EA-8 | P3 | INTRODUCED semantic shift | `empty()` on event-witness sets now means "a live member remains", not "it was ever recorded". This affects `LiftedConsumers`, `InLoopFlattenedPreds` and `UntaintedMergeRails`. Argued unreachable |
| F-EA-9 | P3 | INTRODUCED | `ScrubOnDelete.h` is not self-contained. `SpineOpSet` names `llvm::CallInst` without including `llvm/IR/Instructions.h` |

### F-EA-1 (P3): raw snapshot against self-cleaning live map (bd `jct8`)

`repropagateControlMerges` (`TaintPropagation.cpp:2079`) builds
`DenseMap<const BasicBlock*, unsigned> Round1FlattenedPreds(taint.InLoopFlattenedPreds.begin(), …end())`,
and `collapseFlattenedLoopRails` (`LoopLowering.cpp` ~4725) skips a loop when
`It->second <= Before`. Suppose round 1 records Pred P1 and the snapshot is taken. P1 is
then deleted, a new block P2 lands at P1's address, and round 2 records `++map[P2]`.

- **Pre-8e5r:** the dangling key survives on both sides. The live count is 2 against a snapshot of 1, so the loop is **re-offered**.
- **8e5r:** the live map resets on the revived key, so the live count is 1. The raw snapshot still holds 1, and **1 <= 1 skips the loop.**
- **8e5r with a self-cleaning snapshot:** 1 against 0, re-offered.

`probes/round1_snapshot_asym.cpp` reproduces all three deterministically under `lifo`
(`results/container_probes.txt`). The `nofree` null control shows that address reuse is
the trigger. This is an L2 instance: the same function made its sibling snapshot
`beforeTaint` self-cleaning for exactly this reason.

It is **unreachable today**. No pass stage creates a BasicBlock between that snapshot and
the onward pass: the exhaustive scan in `LoopLowering.cpp:7185-7200` names four creators,
all outside the window, and I2/I3 found nothing.

The comment at `:2064-2070` ("the worst a recycled address can do is make the onward pass
SKIP a loop — the leak, i.e. the safe direction") is **L7**. The same function's F-R1-1
note, about 150 lines further down, measures that skip as a *confirmed rolled≠unrolled
divergence* in which the per-trip which-path rails leaked.

Fix: take the snapshot as a `ScrubMap`, which is one line plus the parameter type.

### F-EA-2 (P3): guard bypasses (bd `c3gf`)

`probes/guard_bypass.py` adds one member at a time to the header text and calls the gate's
own `check()` on it (`results/guard_bypass.txt`). The null control reports 0 problems over
52 members, and the raw `SmallPtrSet` control is KILLED. The gate **misses** these:

- `llvm::Value *Stray{nullptr};`
- `llvm::DenseMap<llvm::Value *, unsigned> X{};` and `SmallPtrSet<…*> X{};`. `members()` treats every `{` as a frame and throws the declaration away.
- `llvm::SmallSet<llvm::Value *, 4>`, `std::multiset`, `std::array`, `std::optional`, `std::pair` held by value, and `llvm::StringMap<Value*>`.
- a lowercase pointer typedef used as an element.
- a template alias.
- a by-value foreign record such as `LoopBreakRegion LastBreak;`. Only records held inside containers are scanned.
- a parenthesised default initialiser.
- `alignas(8) llvm::Value *`.

Only `unique_ptr<DenseMap<Value*,…>>` is caught. Brace initialisation is the most likely
way a raw member would be written in real code.

### F-EA-3 (P3, L7): comments the change made false

These still describe a raw table or argue safety from one:

- `LoopLowering.cpp:5218-5227`: `InPlaceRailOps` "is a raw `Instruction *` set that NOTHING SCRUBS … The proper close is to scrub …". The residual it names (bd `f8eu` family) is now closed by construction.
- `LoopLowering.cpp:6247`: "that set is a raw `BasicBlock *` set nothing scrubs".
- `LoopLowering.cpp:6652-6667`: `InPlaceRailOps` "NEVER scrubbed", followed by the `isa<BinaryOperator>` "lifetime fence" rationale.
- `LoopLowering.cpp:7176-7211`: "`IterationLocalBlocks` IS A RAW `BasicBlock *` SET THAT NOTHING EVER SCRUBS", plus "a `WeakTrackingVH` would not even apply (it tracks `Value`s…)". A BasicBlock *is* a Value, and this mechanism is the counterexample. The same passage carries the "needs a real scrub" retirement trigger and the "NOT A CLEAN BILL … FreePoint and Uncomputation … PRE-EXISTING … filed" exposure. Both are now closed by construction, and the filed item can be retired.
- `TaintPropagation.h:1257-1264`: `ClaimedRailRoots` "ENTRIES CANNOT DANGLE … RETIREMENT TRIGGER … needs a `WeakTrackingVH`". This is discharged, because the `PairSet` drops a pair when either half is deleted.
- `TaintPropagation.cpp:2064-2070`: see F-EA-1.
- `ScrubOnDelete.h:21`, `TaintPropagation.h:50` and `SwapRouteEmit.h:30` all say "~180 erase sites". The track's own measurement is **133** (121 `eraseFromParent` plus 12 utilities, record §4.2). The last of the three also says "~180 … that never scrubbed", but 63 of the 133 do scrub.
- `TaintPropagation.h` (new block) says "the emitted stream cannot move". Hook allocations change absolute addresses, so this is *measured* (record §6.3 and I3 here), not guaranteed by construction. The record's own §9 item 2 says "evidence is not proof".

Lower priority: the scrub rationales at `ArithLowering.cpp:43-47` and `:1081`,
`CastLowering.cpp:36`, `SelectMergeEmit.cpp:61` and `TaintPropagation.cpp:637/1284/1600`
still present the explicit scrub as the defence.

### F-EA-4 (P3, pre-existing, fixed): the oracle's UAF reads are wider than um24

Under scribble the oracle SIGSEGVs on 15 modules (`results/oracle_scribble_crashes.tsv`).
macOS crash reports put them in **two** consumers:

- `lowerLoops` → `Instruction::getFunction` (um24).
- **`propagateWorklist` ← `repropagateControlMerges`**. This is the round-2 onward worklist `WL(taint.Tainted.begin(), end())` at `TaintPropagation.cpp:1829`, which walks a dead key's `users()`. I1's `DEADITER` events at `:1829` and `:2150` are the same keys.

Under a *reusing* allocator the second is a separate route into the 8e5r class. It reads
the use list of whatever object now occupies the address and taints that object's users.
Four crashing lit fixtures (`control_phase_kickback_onward_merge`,
`control_swap_{reject_,}switch_datamux_angle{,_runtime}` and
`lowering_io_controlled_both_arm`) are not in TRACK_8E5R §6.1 or um24's notes, which
attribute the crashes to the prescan. The subject crashes on 0 modules. The fix covers
this route, but the record should name it.

### F-EA-5 (P3, latent): inserting a deleted pointer is now a UAF

Arming a `CallbackVH` calls `AddToUseList()`, which reads `V->getContext()`. A raw
`std::set` stored a stale pointer without touching it. `probes/dead_insert.cpp` shows the
difference: raw/scribble rc=0, scrub/scribble **rc=139**, scrub/nofree rc=0, where the dead
bytes are still readable. That last run also registers a handle on freed memory.

I found no dead-pointer insert in the pass. The code audit found no insert site that takes
a value it does not hold live, I1 logged 0 dead inserts, and I2 logged 0 crashes. The
header's contract says the container "cannot hold a deleted Value" but never states that
the caller must not insert one. Put that in the header. It matters most for any future
consumer that fills a table from a raw record (an ibtq snapshot or a `ControlRegion` field).

### F-EA-6 (P3): a vanished user intrinsic now gets silence instead of UB

On the oracle, a `ThetaCalls`/`MeasureCalls` entry deleted by a non-owner inside the
window (`detectSpecializations` … `lowerMeasures`, with no re-propagate in between) stayed
as a dangling slot, and `lowerRotations`/`lowerMeasures` then dereferenced it. That is UB,
and it often crashed. On the subject the slot is nulled and the owner **silently skips
it**, so a vanished user gate exits 0 (the `cfmv`/§4h/§4i class).

I4 shows no non-owner deletes a listed call inside the window on the corpus. The one
non-owner deletes dead code before a full re-propagate. So this has no instance today. But
the mechanism now *observes* every such deletion for free. A one-line postcondition would
turn the class into a LOUD check: before `lowerRotations`, any nulled slot whose deleter
was not `erase_value` declines. This matches the woa0 "observe, do not predict" shape.

### F-EA-7 (P3): `buildClone`'s BirthOrder migration can no longer fire

At `Specialization.cpp:938-944`, `resolveSite` → `retargetSite` has already erased
`OldInner` by the time the code runs `cloneTaint.Tainted.erase(OldInner)` and
`BirthOrder.find(OldInner)`. On the subject the key is dead, so `find` returns `end()` by
construction; I1 logged both `DEADERASE` events at `:938`. The migration only worked
because a deleted key used to stay a member. It is inert today: I1 logged no `DEADQ-MAP`
event at `:939`, and `cloneTaint.BirthOrder` never holds an inner call before this loop.
Capture the value before `resolveSite`, or delete the dead half.

### F-EA-8 (P3): `empty()` on sets used as event witnesses

- `declineLiftedStaleRecordOps` (`OpcodeLowering.cpp:342`) tests `LiftedConsumers.empty()` to mean "a lift occurred".
- `collapseFlattenedLoopRails` (`LoopLowering.cpp:4692`) and `repropagateControlMerges` (`TaintPropagation.cpp:2060`) test `InLoopFlattenedPreds.empty()` and `UntaintedMergeRails.empty()` as "a region was emitted".

On the subject these read "a live member remains". I argued that none of them can flip.
Nothing erases between `declineClassicalMuxes` and its re-sweep, and a lifted φ that is a
recorded consumer contributes its own consumers. A recorded Pred survives its own flatten.
The sets are empty only if every `%out` is gone, and then there is nothing left to
propagate. I1 logged 0 `DEADEMPTY` flips. Say it in the comments. The first erasing stage
placed inside one of those windows would silently skip the re-sweep.

### F-EA-9 (P3): the header is not self-contained

A TU that includes `ScrubOnDelete.h` first fails with `no type named 'CallInst' in
namespace 'llvm'` at the `SpineOpSet` alias. I hit this while building the container
probes. It builds in-tree only because of include order.

## What I checked and found sound

- **Dead-marking.** `Dead ⊆ S` holds on every path: `keyDeleted` checks `S.count` first; `erase`, `insert`-revive, `operator[]`/`try_emplace`-revive and `clear` update both sets together; copy-assign is a swap. A revived key stays in its original slot, as it did on the unfixed binary, but now inserts as `.second == true`. That fixes `propagateWorklist`'s `if (Tainted.insert(I).second) push`, which on the oracle under-propagated from an aliased instruction.
- **`operator[]` reset.** It matters only for read-modify-write. The pass has exactly one such use, `++InLoopFlattenedPreds[...]`, and that is F-EA-1.
- **Copy, move and lifetime.** Copies re-arm against their own Core. Moves carry the heap Core, so a hook's back-pointer survives a move and the moved-from container gets a fresh Core. `TaintSet` is never copied (grep); `taint = propagate(M, wd)` is a move. Core members are destroyed hooks-first. `exit()` inside `diagnose` runs no destructors and leaves nothing dangling.
- **RAUW.** It is a no-op for keys in both old and new code, so behaviour is unchanged. `WeakVH` does not follow RAUW (LLVM 19 `Value.cpp`), so the three mapped values keep identity. On the oracle a deleted mapped value dangled; now it reads null. At `SharedCondFlags` that leads to a fresh mint, and at `GuardedStores`/`IOTapeForFn` to a null operand, where the oracle built on freed memory. None of these was reached (I2).
- **Iteration during deletion.** Only the dead set changes, and `skip()` re-reads it on every step. `lowerMeasures` and `lowerRotations` erase through `ToErase` or their own lists. `deleteGlobalPhases` iterates a separate `Survivors` vector, so `erase_value` during that loop is safe. `std::next` in `SwapRouteEmit.cpp:986` gives the same live order.
- **`is_contained`/`contains`.** Set and Map `contains` go through `count` with no recursion. The List version is fixed.
- **Emission order.** No emitter iterates a hashed or address-ordered TaintSet table to decide emission. `ControlledRotations` iteration only builds a set, the reseed and delta sets are used for membership only, and `DagTraversal` breaks ties by BirthOrder. I3 is the measurement.
- **Every consumer asked about a value after it could die.** `PeelClones`, `RailCondReads`, `CmpCondReads`, `RolledLoopRegionGates`, `Round1RailGrants`, `StaleQuantumReaders`, `ScrubbedByReturnTaint`, woa0's `PredMuxRailPhiRecord::Leaves` and `exitDischargeObligations()` are all handle-typed and unchanged. `markBranchPhaseGate` is metadata. `is_contained(ThetaCalls/MeasureCalls, …)` in `promoteLoopCarriedHandleSeeds` (P4) asks about live users. `SpecHandleArgMask.find(Callee)` asks about live callees. `HandleWidth` and `BirthOrder` are read for live operands. I1 confirms this on the corpus: zero dead-pointer queries.
- **ibtq (local raw snapshots).** I spot-audited the ones held across stages that mutate the IR: `GateCalls` in `lowerLoops`, `collapseFlattenedLoopRails`, `promoteLoopCarriedHandleSeeds`, `declineClassicalMuxes`, and `ThetaOrder`. None of their members is erased inside the window that holds them. `Round1FlattenedPreds` is the exception, and it is F-EA-1. **emof:** zero scribble faults on all 7 loop-break e2e slices and the lit break fixtures, which is a stronger result than the implementer's LIFO/nofree runs.

## What I did NOT attack

- Anything the concurrent round owns: pin vacuity, the `%debugalloc-cq-opt` lit wiring, the e2e harness, performance, and composition. On composition, note that d88e landed on `main` (`ba80bda1`) after `def1b088`. Its `TaintSet::LiftedMergePhi { llvm::Function *F; … }` has a raw field, so the guard will correctly **fail** at the rebase and the merge must handle it.
- Multi-function and cross-TU shapes beyond the 22 multi-TU e2e modules and the 523 two-TU family programs. bd `1yeu`'s gap applies here too.
- `Loop *` objects, which LoopInfo frees through aligned `operator new`. The test allocator does not replace aligned new, so I2 cannot see a read through `LoopBreakRegion::L`. By grep, nothing reads it.
- A vanished-intrinsic program (F-EA-6) and a block-creating round-2 stage (F-EA-1). Both are argued and backed by instruments, not built from C.
- A `+Asserts`/ASan build, and more than 3 shuffle seeds.
- The runtime-only entry point `runOnFunction`, which has zero callers.

Probes and results are under `probes/`. The scripts are the instruments above. The binaries
were built in the removed scratch worktrees; to rebuild them, apply `add_scribble_mode.py`
and `add_shuffle_mode.py` to a copy of `ir-pass/tools/cq_debug_alloc.cpp`, apply
`instrument_scrub.py` and `instrument_listnull.py` to a copy of `ScrubOnDelete.h`, and link
with `link_alloc_variant.sh`.
