# Rule-13 round r3 — bd 8e5r: the fixes to r2's F-R2-1 and F-R2-2 (`c416f04d..9cce073d`)

Reviewer: an independent agent, 2026-09-26. The scope is the two fixes and nothing else:
- `c81a2201`: F-R2-1 / bd ec7r, the only logic change.
- `ee046f42`: F-R2-2 / bd a66j, the AST guard.

I also spot-checked `7c1e1622` (the lit/CMake fallback). I did not re-review the container
mechanism (r1A/r1B) or the merge (r2).

I did not edit or rebuild anything in the subject worktree. I copied its binaries out and checked
their hashes before use. The only file the round added to the subject tree is this directory,
which is not committed. Every claim below says which binary it was run against.

| binary | sha256 prefix | source |
|---|---|---|
| subject `cq-opt` | `69250feaf68bbe49` | `9cce073d`, the worktree's `build/` |
| subject `cq-opt-debugalloc` | `b8e9c952e2ccf4fa` | same |
| `c416f04d` `cq-opt` | `57f0348465bab76f` | the implementer's kept copy (`t8e5r/cq-opt.fin`); the hash matches record §13 |
| main `ba80bda1` | `e587c19152bf39e5` | `frozen/cq-opt.main_ba80` |

## Verdict: **CLEAR-WITH-ITEMS**

**The logic fix (F-R2-1) is CLEAR.** I found nothing against it:
- The new gate answers exactly as `main`'s did.
- The member it removed had no other reader.
- The corpus moves only where it should.

**The guard fix (F-R2-2) closes r2's corpus, but the closed-world claim is still false.**
- 6 new in-contract spellings pass with **0 problems**. The Release build compiles each of them with the raw member present.
- 3 more pass by making the guard parse a translation unit (TU) the build never compiles.

That is P2, and it is not P1:
- The guard is not vacuous. It catches all 12 of r2's attacks and every control.
- No miscompile is involved. This is an instrument hole of the same class r2 rated P2.

| id | sev | one line | bead |
|---|---|---|---|
| F-R3-1 | **P2** | The guard's closed world is still open. It passes (a) a **pointer to a library table** of raw `Value *` (`std::set<llvm::Value *> *`, `DenseMap<Value*,unsigned> *`), (b) explicit or partial **specializations** of a project class template, (c) a **pointer to a project alias** whose short name any record in the TU shares, including LLVM's own `Result` and `Impl`, and (d) a pointer to a record **outside `cq::`**. 12 of 12 spellings MISSED. | `test_C_libtooling-wop9` |
| F-R3-2 | P3 | The guard parses a TU the build does not compile. It reads **one** of the two compile configurations: CQPass has `-DCQPass_EXPORTS`, cq-opt does not. Its PCH is also **not verdict-neutral**: one member is MISSED with the PCH and CAUGHT without it. | `test_C_libtooling-7gri` |
| F-R3-3 | P3 | The handle-in-a-KEY rule is syntactic: a `WeakVH` inside a project record used as a `std::set` key passes. An allowlisted member exempts its whole type subtree. | `test_C_libtooling-jk56` |
| N-1 | note | Gate row G8's stated ground is incomplete. Its conclusion holds for a different reason. | — |
| N-2 | note | The new fixture's pin of the ec7r gate depends on the bd 3a43 over-decline existing. | — |

---

## F-R2-1 (the logic): attack items 1–3, CLEAR

### Item 1: is `LiftedConsumers` really dead?

I ran `git grep` for non-comment lines naming `LiftedConsumers` or `LiftedMergePhis`, over
`ir-pass/`, `tools/` and `tests/`, at `ba80bda1`, `c416f04d` and `9cce073d`.

**`c416f04d` and `main`** have exactly four non-comment sites:
1. the member declaration;
2. the one writer (`liftOneRegisterMergePhi`'s insert loop);
3. the one reader (the `declineLiftedStaleRecordOps` gate);
4. `scrub_selftest.cpp`'s `checkSet` line (c416 only; `main` has no scrub containers).

Two paths could have carried a hidden reader, and neither does:
- **d88e's re-ask** (`declineFalsifiedMergePhiLifts`) reads only `LiftedMergePhis`.
- **TaintSet copies.** The only whole-`TaintSet` assignments are `taint = propagate(M, wd)`. All of them run before `declineClassicalMuxes`, in both entry points (`CQLoweringPass.cpp:149-442` and `1165-1276`). So no copy can drop or carry the member after a lift.

**The code delta** was checked with r2's `strip.py`: a comment- and string-aware stripped diff over every `.cpp`/`.h` changed in `c416f04d..9cce073d`.
- Null control: the same revision twice gives 0 lines.
- The delta is exactly these three things, and nothing else:
  - the declaration removed;
  - the three writer lines removed;
  - `if (taint.LiftedConsumers.empty())` → `if (taint.LiftedMergePhis.empty())`.

**Removing the member removes `ScrubPtrSet` hooks (`CallbackVH`) on consumers.** A value handle has no IR-visible effect. Its only other effect, allocation-pattern churn, would show up as movers under `nofree`/`lifo`, and there are none (item 5, sweeps D1/D2).

### Item 2: is `LiftedMergePhis.empty()` the right predicate everywhere?

**Population.** `LiftedMergePhis` has one writer, `TaintPropagation.cpp:1666`.
- It sits in the lift's ACCEPT block, unconditionally, *before* the RAUW. That is the same block that held the old insert loop.
- Nothing shrinks the vector. There is no `erase`, `clear`, `pop_back` or reassignment after `propagate`.
- The lift has exactly one caller, `declineClassicalMuxes` (`:1748`). That function has two callers: `run()` `:849` and the `runOnFunction` shim `:1442`.
- **A lift that does not record is impossible**, so the P1-direction "wrongly skipped" case has no member.

**Equivalence to `main`.** `main`'s gate read a raw `SmallPtrSet` that is never shrunk. It was non-empty iff a lift had occurred with ≥ 1 `Instruction` user. That second condition always holds:
- `declineClassicalMuxes` skips a `use_empty()` φ at `:1739`, so every lifted φ has a use.
- Every user of an `Instruction` is an `Instruction`.

So head's gate is `main`'s gate, bit for bit in meaning. The only verdicts it can move against `c416f04d` are those where every direct consumer died before the re-sweep, which is the p2_C shape.

**Round 2 and clones.**
- `repropagateControlMerges` (`:660`/`:1363`) runs *before* `declineClassicalMuxes`, so no lift happens in round 2.
- `adjudicateTaintDelta` calls `declineStaleRecordOps`, not the lift.
- `specialize()`'s clones are never lifted, because the lift has no other caller. So no record is made inside a clone.
- Both entry points order the steps the same way: lift → `specialize` → re-ask → re-sweep.

### Item 3: the gate table's method

**Enumeration.** I grepped `(member)(.|->)(empty|size)(` over all 32 self-cleaning members plus the reference aliases (`auto &PC = taint.PhiCalls` …). It agrees with §15.2.

I found one extra hit, `ArmClassify.cpp:3783` `RailCondReads.empty()`. `RailCondReads` is a `SmallVector` of `WeakTrackingVH` pairs, not a scrub container, so it is correctly outside the table.

No scrub container outside `TaintSet` has an `empty()` or `size()` gate. I checked `beforeTaint`, `Round1FlattenedPreds`/`AlreadyProcessed` and the `SpineOpSet *Rec` parameters.

§15.2 counts "11 sites"; there are 13. The `runOnFunction` shim holds two G1 sites, and that shim has zero callers. This is a cosmetic difference.

**Does the instrument's `rawEmpty()` model the raw container?** I read `ScrubOnDelete.h`:
- **`Set`**: a dead key stays in `S` and is marked in `Dead`.
- **`List`**: a dead slot is nulled, not removed.
- **`Map`**: same pattern as `Set`.
- Nothing compacts a dead entry out of storage.
- So `S.empty()` is exactly what the pre-8e5r raw container would say.
- The one divergence is the copy constructor, which skips dead keys. No gate reads a copy.

**The "other direction".** A gate whose non-empty answer is computed over fewer members is not an `empty()` question. Iterating live members only is the container mechanism r1A/r1B cleared. The table does not claim to cover it, and it should not.

**Four rows re-derived independently:**

| row | my derivation | agrees? |
|---|---|---|
| G2 `ValueArmConeOps` | The loop visits every live `Instruction` in the module and asks `count(&I)`. A dead key can never match a live instruction. So the early return is outcome-neutral. | yes |
| G5 `lowerRotations` | After the early return, the function lowers only `ThetaCalls`/`PhiCalls` members. `declineFrozenWire` needs a tainted `freeze`, and taint derives from a live theta (Rule 3). The corpus shows 0 flips. | yes |
| G10 `InLoopFlattenedPreds` | The loop `find`s only `L->blocks()` of freshly built `LoopInfo`, which are live blocks. An all-dead table gives `Touched=false` for every loop. So this row is outcome-neutral **by construction**, as the new source comment says. | yes |
| G8 `UntaintedMergeRails` | **The conclusion holds, but the stated ground is incomplete.** See N-1. | conclusion yes |

### Item 5: measurements (my own harness, `probes/ab3.py`)

`ab3.py` differs from the implementer's `ab.py` in three ways:
- It compares **full** stderr, not just the first `error:` line.
- It aborts on a 0-byte or missing input.
- It prints the denominator first.

The corpus has 3260 modules: 2308 lit fixtures at head, 425 e2e stage-1 modules, 523 family modules, and r2's 4 probes. The load average was 3–10 while it ran. Results are in `results/sweeps.log`:

| # | comparison | result |
|---|---|---|
| 1 | NULL: head twice | **3260/3260 same** (run first) |
| 2 | comparator positive control (one output perturbed) | 1 mover of 4, the perturbed one |
| 3 | `c416f04d` vs head | **3258 same, 2 A2D**: `lowering_reject_lift_resweep_spec_rebuilt_consumer.ll` and `p2_C.ll`. 0 STREAM, 0 STRING, 0 WARN, 0 D2A, 0 CRASH. |
| 4 | `ba80bda1` vs head (lit + e2e + probes, 2737) | **2735 same, 2 STREAM**: the k65 lit fixture and the k65 e2e module, where the oracle is wrong |
| 5 | head vs head-debugalloc `nofree` / `lifo` | **3260/3260 same**, each |

**New fixtures, RUN lines executed verbatim under `pipefail`** (`results/fixture_rg.txt`):

| fixture | `c416f04d` | head | `ba80bda1` |
|---|---|---|---|
| `…_spec_rebuilt_consumer.ll` | **FAIL** 3/3 | PASS 3/3, plus debugalloc lifo and nofree | PASS 3/3 |
| `…_surviving_consumer.ll` | PASS | PASS | PASS |

Harness positive control: `p2_N.ll` piped through the fixture's checks **FAILS**, as it must.

**Pins** (`results/pins.txt`):
- **k65**: every RUN line reproduced (lifo, nofree, sys, FileCheck, both diffs). Head PASS 5/5. `ba80` under the r1B interposer FAIL 3/3.
- **um24 `lowering_reject_break_uncollected_clone.ll`, `nofree` line**: head PASS 5/5. `ba80` under the interposer FAIL 3/3.

---

## F-R3-1 (P2): the guard's closed world is still open (bead `wop9`)

**Harness.** `probes/guard_fool_r3.py` and `guard_fool_r3b.py` work the way r2's did:
- They import the guard **unmodified** from the subject tree, with no `.pyc` written.
- They call `check()` on mutated `TaintPropagation.h` text.
- Controls run first.

**Controls, all correct:**
- 4 null: pristine, pristine with extra includes, a bitfield, pristine again in batch 2.
- 11 positive, including:
  - a raw pointer in a *base* of a project record;
  - a project template base instantiated with `llvm::Instruction`;
  - pimpl to a `.cpp`-only type;
  - a pointer to a forward-declared type;
  - a lambda static member capturing a `Value *`;
  - `std::function<Value*()>`;
  - a named union;
  - `pair<WeakVH,int>` as a `std::map` key;
  - `std::set<Value*>` by value and via `unique_ptr`;
  - a global record by value.

**A MISS is only possible when the mutated header compiled with the build's command.** A compile error counts as a refusal. `probes/presence.py` also compiles every conditional or specialized member with **both** real compile commands and `static_assert`s its raw type.

| spelling | guard | in the build? |
|---|---|---|
| **(a)** `std::set<llvm::Value *> *R;` | **MISSED** | unconditional |
| **(a)** `llvm::DenseMap<llvm::Value *, unsigned> *R;` | **MISSED** | unconditional |
| **(a)** `llvm::SmallPtrSet<llvm::Instruction *, 4> *R;` | **MISSED** | unconditional |
| **(a)** `llvm::SmallVector<llvm::DenseSet<llvm::Value *> *, 2> R;` | **MISSED** | unconditional |
| **(b)** `template<> struct R3Spec<unsigned> { llvm::Value *P; };` + `R3Spec<unsigned> M;` | **MISSED** | PRESENT (CQPass and cq-opt) |
| **(b)** partial: `template<class T> struct R3PS<T *> { llvm::Value *P; };` + `R3PS<int *> M;` | **MISSED** | PRESENT |
| **(b)** a full specialization selected only under `NDEBUG` (holds `SmallPtrSet<Value*,4>`) | **MISSED** | PRESENT (Release) |
| **(c)** `using R3Rec = RawRec; R3Rec *P;` + an unrelated clean `r3other::R3Rec` | **MISSED** | PRESENT |
| **(c)** `using Result = RawRec; Result *P;`, **with no decoy of mine** | **MISSED** | unconditional |
| **(c)** `using Impl = RawRec; Impl *P;`, **with no decoy of mine** | **MISSED** | unconditional |
| **(d)** `R3G *P;` where `struct R3G { llvm::Value *P; }` is at global scope | **MISSED** | unconditional |
| **(d)** `cqx::R3X *P;` where `R3X` is in namespace `cqx` | **MISSED** | unconditional |

The same types are **refused** in other forms, which is why these are holes and not a policy:
- **(a)** by value, via `unique_ptr`, via `optional`, and so on;
- **(d)** by value, as closed-world.

**Mechanisms**, confirmed by trace (`results/b8_trace.txt`, `b8_which.txt`):
- **(a)** `Walk._t` handles a pointer to a template (`inner[0]=="tmpl"`) by walking its arguments **only when** the template is `cq::`. A library template's arguments are skipped, and the pointee goes to `pointee_q`, where "not Value-derived" accepts it.
- **(b)** `_dump` keeps only `CXXRecordDecl` and `ClassTemplateDecl`, so the primary pattern (`T X`) is walked. The trace shows `DUMP R3Spec -> [ClassTemplateDecl]` and nothing else. `ClassTemplateSpecializationDecl` and `ClassTemplatePartialSpecializationDecl` are dropped. The tree already contains a `template <>` (`SpecializePlan.h:122`), so this is not an exotic spelling for the project.
- **(c)** Two things combine:
  - The JSON does not desugar a pointer's pointee, so the unqualified alias resolves to `cq::Result`.
  - `_dump(tmp, "Result")` filters by **short** name and walks whatever records carry that name. The trace shows two empty `Result` records from `llvm/IR/PassManager.h:565/691`, and `Impl` matches `llvm/ADT/Bitfields.h`.

  With a unique short name, the same spelling is refused only by the fallback "no complete definition was found", so it is safe by luck. `results/b8_names.txt`: 9 of 11 common names are refused that way, and `Result` and `Impl` are missed.
- **(d)** Only `cq::` pointees are added to `foreign`. Any other complete, non-`Value` record behind a pointer is accepted unwalked.

**Why P2 and not P1.**
- The guard is not vacuous. It still kills r2's 12 and its own 74 mutants; I re-ran `--selftest`: 7 controls, 74 mutants, 0 failed, 36 s (`results/guard_runs.txt`).
- The missed forms are the same class r2's F-R2-2 was rated P2 for: A6 pointer-held project records, A1 project templates.
- (a) and (c) are the natural spellings: a raw pointer to someone's table, and `using Result = …`.
- The docstring's claims these fall under are "THE WALK IS A CLOSED WORLD … every PROJECT (`cq::`) record or class template reachable … BY POINTER …" and the CMake comment's "no raw pointer-bearing member may be (re)added".

**Fix direction:**
- walk every pointee template's arguments;
- dump specializations too;
- resolve a pointee to its **canonical** record with the compiler, and dump by qualified name;
- walk or refuse any record outside `llvm::` and `std::` behind a pointer.

## F-R3-2 (P3): the guard parses a TU the build does not compile (bead `7gri`)

**(i) Two compile configurations.** `compile_commands.json` holds two commands for `src/TaintPropagation.cpp`:
- CQPass: `-DCQPass_EXPORTS … -fPIC`.
- cq-opt: neither flag. cq-opt-debugalloc and cq-scrub-selftest are built with cq-opt's define set.

`_base_command()` prefers `CQPass.dir`. B3 is `#ifndef CQPass_EXPORTS  llvm::Value *R; #endif`:
- The guard reports **0 problems**.
- `presence.py` shows the member absent in CQPass and **PRESENT in cq-opt**, the binary every lit RUN line and every e2e slice goes through.
- This falsifies "same defines" in the docstring and in record §15.3.
- It is contrived, but it is exactly A5's shape (a define-conditioned member) one define over.

**(ii) The PCH is not verdict-neutral.** The PCH contains every third-party header any project header includes, plus `EXTRA_INCLUDES`. `_compile` retries without it **only on failure**.
- `llvm/Analysis/LoopInfo.h` is in the PCH but not in `TaintPropagation.h`'s closure (measured with `-E -dM`).
- So `#ifndef LLVM_ANALYSIS_LOOPINFO_H  llvm::Value *R; #endif` is **MISSED with the PCH and CAUGHT without it**, with the same probe and the same binary (`results/guard_fool_r3.pch.txt` vs `.nopch.txt`).
- The selftest's "PCH equivalence control" compares only the pristine header.

The fix is cheap: re-run any **clean** verdict without the PCH, since clean is the only verdict that can be a false pass.

**Fail-closed checks all pass** (`results/guard_runs.txt`, `guard_baddb.txt`). Each of these exits 1:
- a missing database;
- the main tree's `build/`, which has no database;
- a database whose entries point at another tree;
- a database naming a nonexistent compiler;
- a garbage JSON file.

The last two exit through a Python traceback rather than the guard's own diagnostic. They still fail closed. An unknown argument exits 2.

The PCH lives in a fresh `mkdtemp` per process and is built from third-party headers only, so a stale PCH across runs is not possible.

## F-R3-3 (P3): the key rule is syntactic, and the allowlist exempts a subtree (bead `jk56`)

**B7.** `struct R3Key { llvm::WeakVH H; bool operator<(…) }; std::set<R3Key> S;` gives 0 problems.
- `_has_handle` does not look inside project records.
- The docstring refuses "a value handle as (part of) an associative-container KEY", and the positive twin, `std::map<std::pair<WeakVH,int>,int>`, is refused.

**B14.** I added `llvm::SmallPtrSet<llvm::Value *, 4>` to `LoopBreakRegion` in a copied `LoopPlan.h` (with `INCLUDE_DIR` pointed at the copy). It gives 0 problems.
- `ALLOWLIST['cq::TaintSet::BreakRegions']` skips the member's whole type.
- So the allowlist reason, "never a table asked by IDENTITY", is a premise nothing enforces.

## Notes

**N-1 (G8's ground).**
- **The row's stated ground:** "the only work is re-propagating FROM live rails".
- **Why that is incomplete:** the early return in `repropagateControlMerges` also skips `detectAndLowerOnwardControl`, a full second round of detection, and the spec re-plan.
- **Why the conclusion still holds:** every recorded `%out` is a `cqrt_alloc_*` `CallInst` (`ClassicalCallArmEmit.cpp:214`, `SwitchDataMuxEmit.cpp:142`, `IOSinkLowering.cpp:784`). A runtime call is never trivially dead, and I found no eraser in the window that removes one.
- **Measured:** 0 flips over 2328 modules.
- **Disposition:** a record wording item, not a finding.

**N-2 (the pin depends on bd 3a43).** The only verdict-level exhibit of the event-vs-population gate is p2_C.
- There the decline lands in `slice()`, a different function, because the re-sweep is module-wide.
- By r2's argument, an in-function stale op reachable only through a spec-site consumer starts a fresh wire. I did not construct one.
- So once bd 3a43 scopes the re-sweep, p2_C would accept under either gate, and the ec7r choice would become unpinned, probably because it becomes unobservable.
- bd 3a43's note already says "re-derive both". The fixture header could state this retirement trigger explicitly (L8).

## What I did NOT attack

- **Test runs:**
  - I did not run the full `ctest` or the full `lit` harness. Pass-level A/B with my own harness, plus the new fixtures', k65's and one um24 line's RUN lines executed by hand.
  - I did not run `cq-opt-equivalence-full` or the duplicate-body scan.
- **Mutants:** I built none. The only binary that distinguishes the two gates is `c416f04d`'s, and I used it.
- **Out of scope by instruction:** the container mechanism, the merge, and F-R2-3's correctness.
- **Guard coverage beyond what is listed above:**
  - spellings built from macros spread across several headers;
  - `scrub::Set`/`Map` instantiated with a non-`Value` key (I expect a compile error, but did not measure it);
  - pointer-to-member types;
  - variable templates;
  - a Debug-configured tree (whether `#ifndef NDEBUG` members are then seen);
  - non-Apple toolchains;
  - whether a stale `compile_commands.json` (flags changed without a reconfigure) is reachable. CMake regenerates it on every reconfigure; I only argued this, and did not measure it.

## Files

- `probes/ab3.py`: the A/B harness.
- `probes/sweeps.sh`: sweeps 1–5.
- `probes/fixture_rg.sh`, `probes/pins.sh`: the fixture red-green runs and the pins.
- `probes/guard_fool_r3.py`: B1–B14.
- `probes/guard_fool_r3b.py`: C1–C6.
- `probes/presence.py`: member presence under both compile commands.
- `probes/b8_trace.py`, `probes/b8_names.py`, `probes/b8_which.py`: the (c) mechanism traces.
- `probes/strip.py`: r2's comment stripper, copied.
- `probes/results/*`: every output quoted above.

No executables. Private copies of the binaries are in the scratchpad only.
