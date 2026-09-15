# FILE_SURFACE — Track B (L-1a W1, second half), session 2026-09-15

**Reported to the orchestrator ahead of `SCOPE_B.md`, per the brief.** Every path is a file the
implementation *will* edit; a file it only *reads* is not listed. Measured against `main` `74eabd2c`
and the frozen ORACLE `cq-opt` `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`
(`shasum -a 256`, re-verified at track open).

---

## 0. THE ANSWER THE ORCHESTRATOR ASKED FOR FIRST

### **NO. The second half does NOT edit `ir-pass/src/LoopLowering.cpp`.** Measured, three ways:

1. `grep -ci railbank ir-pass/src/LoopLowering.cpp` → **0**. Confirmed at `74eabd2c`.
2. `promoteRailBankCells` is called at `CQLoweringPass.cpp:196`, inside the `-O1`-repair normaliser
   fixpoint — **above `detectSpecializations` (:391), `declineTaintEscapes` (:400) and `lowerLoops`
   (:455)**. A promoted cell is an ordinary SSA φ before the loop layer ever runs; `LoopLowering` has
   no bank object to see. All three of the second half's pieces sit at or after that same slot or
   later (§1), so none of them puts a memory-resident value in front of a `LoopLowering` predicate.
3. **D3's ruled decline for `staleRailRecordRead` needs NO code in that file.** The ruling is *"refuse
   loudly any bank rail that would reach `staleRailRecordRead`."* `staleRailRecordRead`
   (`LoopLowering.cpp:1070`, LOUD at `:2332` and `:2721`) reasons over **rail records grouped by ROOT
   MINT** (`ByRoot` `:2296`, `ChainsByRoot` `:2525`) built by `collectRailGates` (`:890`) from
   `GateCalls` = `taint.ThetaCalls ∪ PhiCalls` (`:3686-3688`). Every member of every group is a
   `CallInst`-rooted SSA chain. **A bank LOAD is not a member of any group and cannot become one
   without a `LoadInst` arm in `peelInPlaceStep` (`:298-321`, no `LoadInst` arm anywhere in the
   file).** The second half adds no such arm — the D5 allow-list refuses every non-measure consumer of
   a bank load *before* the loop layer could ask. **The refusal is realised by NOT WIDENING, which is
   zero lines**, in the same style as SCOPE_L1a §4.4's *"do not widen any of them"* verdict.

**Consequence for the gate topology: Track B is NOT in a `LoopLowering.cpp` group.** Tracks S′ and T,
which are live in that file this session, share **no file** with Track B and therefore share no
S1 group. The one shared-file risk is `tests/e2e/CMakeLists.txt` (PROTOCOL §S1's measured erratum),
which is a mechanical union and explicitly **does not** create group membership.

⚠ **The retirement trigger that makes this answer expire, stated so it cannot rot:** the day any bank
value is admitted as a rail *member* — i.e. the day `peelInPlaceStep` gains a `LoadInst` arm, or
`collectRailGates`' forward walk (`:920-979`, `:971-972`) is taught to resume across a store — the
grouping question D3 deferred becomes live **in this file**, and `(alloca, index SCEV)` (SCOPE_L1a §8
item 2, explicitly *"my proposal, not a measured one"*) must be built with its own Rule-13 round.
`SCOPE_B.md` §6 states where that decline lives in the meantime.

---

## 1. Files the implementation edits

### Pass source (the Rule-13 core — every one of these is a Rule-13 subject)

| file | what changes | piece |
|---|---|---|
| `ir-pass/src/RailBankPromote.cpp` | **(2a)** sink the store-side storage-extension cast OUT of the region arm to the activation-end store, so the merge φ carries the RAIL type; mint `!cq.railbank` on the alloca at `applyBank`'s tail (`:563` currently says in capitals that nothing is minted — that comment is replaced, not contradicted) | 1, 2 |
| `ir-pass/include/RailBankPromote.h` | the contract for both of the above; the B-clause list gains the cast-sink post-condition; **F-9**: `§2.3/§7/§8/§10.1`-style stale B9 wording does not exist here any more (corrected at the 14c gate) — do not re-introduce it | 1, 2 |
| `ir-pass/src/TaintPropagation.cpp` | **(1)** the taint rule: a `load` from a `!cq.railbank` alloca is seeded in `collectAndSeed` (`:97`), i.e. inside `propagate` (`:471`), so every re-propagation carries it. **(3)** `declineTaintEscapes` (`:400` call site; store arm `:1097`) exempts the ONE bank store and gains `declineUnallowedRailBankReaders` — the **positive** D5 allow-list, called from the same function so `adjudicateTaintDelta` (`:1782`, which calls `declineTaintEscapes`) re-asks it at round 2 for free | 1, 3 |
| `ir-pass/include/TaintPropagation.h` | the taint rule's contract + the D5 allow-list's declaration and its retirement triggers | 1, 3 |
| `ir-pass/src/CQLoweringPass.cpp` | ONE new call, `rewriteRailBankCellTypes(M, wd, taint)`, in **both** entry points, between `lowerRotations` (`:774` / the `runOnFunction` twin) and `lowerOps` (`:775`) — **not** SCOPE_L1a §3(a)'s "after `lowerOps`" slot; §2 of `SCOPE_B.md` gives the measured reason | 2 |
| `ir-pass/src/QramLowering.cpp` | `railBankCarveVerdictImpl` (`:1225`) hands back the **RAIL** width beside the CELL width (`RailBankShape::ElemAbi` today is `abiWidthFromType(CellTy)` at `:1426` — measured `abi=i8` for the owner's `_Bool` bank while the rail is `i1`), and gains the accessor the type rewrite and `lowerMeasures` need. ⚠ **The PUN FENCE at `:1263` is NOT touched** — see `SCOPE_B.md` §2.3 | 2 |
| `ir-pass/include/QramLowering.h` | `RailBankShape` gains `RailTy` / `RailAbi` (`:460-468`); `isRailBankAlloca` is declared here (it is **not** shipped today — `trackA/SIGNATURE.md` deviation (2)) | 1, 2 |
| `ir-pass/src/ChainWalk.cpp` | **(D1)** `isTerminalHandle` (`:757`; user loop `:765-768` `if (!CI) continue;` silently skips a `StoreInst`) answers **false** for a handle stored into a `!cq.railbank` cell | 3 |
| `ir-pass/include/ChainWalk.h` | `railStoredToRailBank` declared beside `isTerminalHandle` (`:462`) — the demand-driven structural predicate of SCOPE_L1a §4.3, **never** a `Value *`-keyed set (`TaintPropagation.h:198-225`) | 3 |
| `ir-pass/src/FreePoint.cpp` | **(D1)** `isRecognizedEscapeUser` (`:93`) admits a store into a `!cq.railbank` cell, so the classification at `:199` returns `Escaped` instead of reaching `FirstUnrecognized` (`:226-227`) → `kMsgUnrecognized` (`:272-273`). ⚠ This is an **over-decline removal that is invisible in `main`** (`:182-183` short-circuits) — see `SCOPE_B.md` §5 | 3 |
| `ir-pass/src/MeasureLowering.cpp` | **no logic change expected**; the i32-handle postcondition at `:235` is what the type rewrite must satisfy. Listed because its header comment at `:213-218` (*"a TAINTED measure operand is always already an i32 handle — a theta result RAUW'd … or a `cq_template_*` result"*) acquires a **third** producer and must say so |
| **NEW** `ir-pass/src/RailBankTypes.cpp` + `ir-pass/include/RailBankTypes.h` | the type rewrite (2b): alloca `[N x CellTy]` → `[N x i32]`, every bank access GEP's source element type, every bank `load` rebuilt as `load i32` with its storage-truncation cast erased, the store's cast erased | 2 |
| `ir-pass/CMakeLists.txt` | the new TU | 2 |

### Tests, fixtures, goldens, harness

| file | what changes |
|---|---|
| `ir-pass/test/railbank_*.ll` (**3 re-spelled**, **~14 new**) | **F-3**: `railbank_promote_reject_two_cells.ll`, `…reject_store_outside_loop.ll`, `…reject_inloop_other_read.ll` are re-spelled so the **B** clause refuses a module the **real** carve calls `Bank` (measured: today all three die at the carve first — `SCOPE_B.md` §8). ⚠ `…reject_store_outside_loop.ll` may be **unfixable**; §8 gives the measured argument and the fallback |
| `ir-pass/test/*.ll` (new accepts + D5 negatives) | ~14 files; the list and each one's decline string are in `SCOPE_B.md` §7 |
| `tests/e2e/slice_railbank_*.c` + `.expected.log` | **+4 slices / +5 goldens / +6 ctest entries** (§7.2) |
| `tests/e2e/CMakeLists.txt` | ONE tail anchor; PROTOCOL §S1's erratum applies — expect a conflict per slice-adding branch and resolve by UNION, then run the three post-union checks |
| `ir-pass/test/control_classical_call_arm_reject_localarray_store.ll` | **a two-word TENSE change, and it is an L8 retirement trigger already written into the file.** Track B amended this header at the 14c gate (`:23-49`); its amendment (2) says the SSA-only doctrine *"is being NARROWED rather than retired: L-1a's deferred half adds one rule — a `load` from a `!cq.railbank` alloca is tainted."* Piece 1 IS that half, so *"is being"* becomes *"is"*. ⚠ **The verdict does not move, and the header already says why, measured**: the index `%i` is a function argument with no enclosing loop ⇒ C2′ has no `{0,+,1}` at all; no proven zero initializer; off the `-O1` floor. Re-verify rather than inherit |

### Records (not code)

`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackB/**` and the
implementation's own `GATES.md`.

### Already edited by this scoping agent, outside `trackB/`

`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackL/SCOPE_L1a.md`
— routing item **R4**, five dated corrections to §5, §7 (×3) and §9. The brief authorises this one
file. `git diff --stat`: **+43 / −6**.

---

## 2. Files the implementation must NOT edit, and why each is on the list

| file | why not |
|---|---|
| `ir-pass/src/LoopLowering.cpp` | §0. Zero bank references, and D3's refusal is realised by **not widening** `peelInPlaceStep` / `collectRailGates` |
| `ir-pass/src/ArmClassify.cpp` | the promoter's cast sink (2a) is what makes the arm classify as `StatePrep` instead of a value arm — **measured**, `SCOPE_B.md` §2.2. No classifier clause moves. ⚠ In particular `railWireClosure` (`:525`) is **not** taught a memory hop: that trips `f2SeedPinnedByLiveRegister`'s retirement trigger at `:1283-1295` and forces F2's narrowing to be re-derived from scratch. **Verified against the source, not quoted** |
| `ir-pass/src/Uncomputation.cpp` | `preservesBorrowedParent` (`:588`) must **not** be narrowed (L3, and its parameter is `const CallInst *` so it cannot see a store); D2/D3/D4 are silent-and-safe and are **pinned, not changed** (SCOPE_L1a §4.4(A)) |
| `ir-pass/src/EmitInverse.cpp` | `FreePoint.cpp:85-86` says in writing *"the freeze is decided in DagTraversal step 3b and executed in `Uncomputation::emitDagReversal`. Do NOT mirror it here."* |
| `tools/free_pairing_check.py` | Track I already landed the `!cq.railbank` rules (bd `21re`). **F-8**: they have had no customer; this increment is the customer. Any change here is Track I's, filed, not taken |
| `tools/opcode_table.yaml`, `runtime/*` | **no new runtime symbol, no ABI change.** The bank reuses `cqrt_measure_<W>`; the handle is `i32` at every width (Rule 15) |
| `include/CQ.h` | no frontend surface. `bool b[N]` is plain C |
