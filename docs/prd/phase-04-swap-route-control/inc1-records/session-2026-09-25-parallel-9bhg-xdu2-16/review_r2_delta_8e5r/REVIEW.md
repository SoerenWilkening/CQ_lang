# Rule-13 round r2 (DELTA) — bd 8e5r (+ um24, j8sk) after the merge with `main` ba80bda1

Reviewer: independent agent, 2026-09-26. Scope: what changed since the cleared `818f8afa`,
i.e. `git diff 818f8afa c416f04d` minus d88e's own cleared hunks. I did not re-review
the container mechanism that r1A/r1B cleared. Nothing in the subject worktree was edited or
rebuilt. Everything below was run by me, and each claim states what it was run against.

| binary | sha256 prefix | what |
|---|---|---|
| subject `cq-opt` | `57f0348465bab76f` | `c416f04d`, the worktree's own `build/` (hash-verified, copied before use) |
| subject `cq-opt-debugalloc` | `ff15a90315ca9498` | the same |
| oracle `main` ba80bda1 | `e587c19152bf39e5` | frozen `cq-opt.main_ba80` |
| 8e5r alone `818f8afa` | `8ab548b711175edd` | rebuilt privately; BIT-IDENTICAL to the record's cleared binary (an unplanned build null control) |
| pre-d88e `main` | `b1603d237fc3a739` | frozen `cq-opt.main_e846` (def1b088 era) |
| instrumented subject | `e419bb37…` / 2nd build | `c416f04d` + `probes/instr_subject_c416f04d.patch` (stderr counters; the 2nd build adds the `R2_ALWAYS_SWEEP` switch) |
| instrumented oracle | — | `ba80bda1` + `probes/instr_oracle_ba80bda1.patch` |

## Verdict: **CLEAR-WITH-ITEMS**. 0 P1, 2 P2, 2 P3 (+ notes)

**F-R2-1 should be fixed before this lands.** It is a verdict move against `main`, it comes
from the composition, and the record says it does not exist. The fix is one line.

| id | sev | one line | bead |
|---|---|---|---|
| F-R2-1 | **P2** | **Composition (8e5r × d88e).** d88e moved the bd 2qyz lift re-sweep past `specialize()`. 8e5r made `LiftedConsumers.empty()` count only live members. `specialize()` erases a lifted consumer when it rebuilds an fp-return spec site. So the re-sweep is **SKIPPED**, and a C program **DECLINES on main, on 8e5r alone and on d88e alone, but ACCEPTS on the subject.** This is deterministic and involves no allocator. The two F-EA-8 comments written after the merge say nothing erases in that window. They are false. | `test_C_libtooling-ec7r` |
| F-R2-2 | **P2** | The AST guard is not the closed world it claims. It never walks a `cq::` class **template**, and never walks a project record held **by pointer**. It also compiles the header **without the Release build's `-DNDEBUG`**. Five in-scope raw-`Value *` spellings pass with 0 problems. | `test_C_libtooling-a66j` |
| F-R2-3 | P3 (pre-existing over-decline) | The module-wide 2qyz re-sweep runs after `lowerLoops`' collapse. So a one-register lift in `main` declines a shipped Grover range-oracle loop in an **unrelated function**. This holds on all four binaries. | `test_C_libtooling-3a43` |
| F-R2-4 | P3 | `lit.cfg.py` says it "NEVER falls back". `ir-pass/test/CMakeLists.txt` still has a fallback branch (dead today), and the mtime check passes it: equal paths are not "older". The build line omits `cq-scrub-selftest`. | `test_C_libtooling-sjwe` |
| F-R2-5 | P3 note | The null-`F` branch is unreachable (measured and argued). Its `return false` for "no defined function" also skips the remaining records. Harmless, but not what the comment implies. | — |
| F-R2-6 | P3 note | Record §13.4 row B lists the e2e k65 module as a STREAM mover. That is a **lottery** row: the oracle under the system allocator is wrong **10/20**. It was right on my single sweep, so my row B showed 0 movers on e2e. The record should give the run count. | — |

---

## F-R2-1 (P2): the lift re-sweep is skipped when `specialize()` erases every lifted consumer

**Mechanism.**
- `liftOneRegisterMergePhi` inserts the erased φ's direct users into `taint.LiftedConsumers`.
- `declineLiftedStaleRecordOps` returns early `if (taint.LiftedConsumers.empty())`.
- On the merged tree, d88e's slot move puts `specialize()` between the two.
- `specialize()` → `retargetSite` REBUILDS a call whose clone's return type changed (fp → `i32` handle). It creates the new call, RAUWs the old one onto it, and erases the old one.
- The self-cleaning set dead-marks the old call. `empty()` is then true, and the full re-sweep does not run.
- On ba80bda1 the raw `SmallPtrSet` keeps the dangling pointer, so the set is non-empty and the re-sweep runs. At 818f8afa the reader ran before `specialize()`, so it runs there too.

**Measured, state level** (`probes/p1_liftskip/k1.ll`, 9 lines of C; `results/instr_summary.txt`):

| binary | counter | runs |
|---|---|---|
| instrumented subject | `R2INSTR LIFT recs=1 liveConsumers=0 SKIP` | 3/3 |
| instrumented ba80 | `R2INSTR LIFT recs=1 rawConsumers=1 RUN` | 3/3 |

The emitted stream is identical on both (modulo ModuleID), because nothing on k1 is stale.

**Measured, verdict level** (`probes/p2_liftskip_verdict/`, plain C, 2 TUs, rebuilt by
`probes/build_probes.sh`; `results/p2_composition.txt`, 3 runs per cell). All modules are
`slice()` = the shipped `e2e-slice-control-grover-loop-range-oracle` loop, plus `main()` as
below.

| module | `main()` | main_e846 (neither) | 818f8afa (8e5r only) | ba80bda1 (d88e only) | **subject (both)** |
|---|---|---|---|---|---|
| p2_N | no lift | ACCEPT | ACCEPT | ACCEPT | ACCEPT |
| p2_C | a one-register lift whose ONLY consumer is `double h(int,int)` | DECLINE | DECLINE | DECLINE | **ACCEPT** |
| p2_T | as p2_C, plus a surviving pure-op consumer (`q ^ 1`) | DECLINE | DECLINE | DECLINE | DECLINE |

Every DECLINE is `in function slice …: cq opcode lowering: operand predates a non-diagonal gate`.

**Direction and severity.**
- The subject's p2_C accept equals the no-lift verdict: `slice()` lowers byte-identical to p2_N's.
- The oracle's decline is the pre-existing over-decline filed as F-R2-3.
- So **no miscompile is exhibited, and this is not rated P1.**
- It is nonetheless a composition-only verdict move against `main`, in a bead whose headline is "no emitted stream moved". "It cannot hide a real stale op" rests on an argument that is written nowhere, which I reconstructed as follows:
  - The only caller-side eraser inside `specialize()` is `retargetSite`.
  - The only thing it erases is a spec call site. That is not in `inLowerOpsScope`, and it starts a fresh wire.
  - Any pure-op or `cq_theta` consumer survives, and so re-arms the sweep (p2_T).
- The corpus cannot see this class. Over all 3254 modules the counters show 30 + 5 RUN and **0 SKIP**, so the class has no member there. "0 movers vs main" is therefore not evidence about it (§4k's empty-quadrant lesson).

**False comments (L7).** Both were written in `e24126b1`, *after* the merge commit `0b07629e`:
- `OpcodeLowering.cpp:343-347`: "nothing erases between `declineClassicalMuxes` and this re-sweep".
- `TaintPropagation.h:78-83`: "Argued not to flip at any of its three readers (nothing erases a recorded member in those windows; r1A I1: 0 flips)". r1A's I1 measured 818f8afa, where that window was empty.
- The other two F-EA-8 readers (`InLoopFlattenedPreds`, `UntaintedMergeRails`) have windows d88e did not touch. I found nothing there.

**Suggested fix.**
- Gate on `!taint.LiftedMergePhis.empty()`. That is d88e's own, non-self-cleaning record that a lift occurred, and it restores `main`'s verdicts exactly.
- Correct both comments.
- Pin p1 (SKIP state) and p2_C (the verdict) as fixtures.
- F-R2-3 is the separate question of whether the re-sweep should be module-wide at all.

## F-R2-2 (P2): holes in the AST guard

**Probe.** `probes/guard_fool_r2.py` imports the guard **unmodified** and calls its
`check()`. Controls: 2 null (clean) and 6 positive (refused); all correct. Results are in
`results/guard_fool_r2.txt`. **11 of 12 attacks MISSED.**

**In scope** (the docstring's own contract says project records are walked and "anything else FAILS"):

| attack | spelling | why it passes |
|---|---|---|
| A1 | `template <typename T> struct R2RawHolder { llvm::Value *P; T X; }` held as `R2RawHolder<int>` | A `cq::` class template takes the library-template rule, whose type arguments are `int`, so its fields are never walked |
| A2 | `SmallVector<R2RawHolder<unsigned>,2>` | same |
| A5 | `#ifdef NDEBUG llvm::Value *…; #endif` | The build compiles with `/usr/bin/c++ -O3 -DNDEBUG` (`build/ir-pass/CMakeFiles/CQPass.dir/flags.make`); the guard uses Homebrew `clang++` with neither define. The member ships and the gate never sees it |
| A6 | `SmallVector<R2RawRec *>` where `R2RawRec` holds a raw `Value *` | A pointer to a non-`Value` type is accepted without walking it. The record's "(any depth)" claim is false |
| A7 | the same, as a `ScrubMap` MAPPED type | same |

**Out of the documented `Value`-only scope, but the same alias class.** The docstring should
name these rather than say "closed world":
- A3 `SmallPtrSet<const void *>`
- A4 `DenseMap<uintptr_t,…>`
- A8 `shared_ptr<void>`
- A9 `DenseMap<Loop *,…>` (bd emof's class)
- A10 `SmallVector<Use *>`
- A11 `std::set<WeakVH>` (a handle nulled in place inside an ordered container)

**Caught**: a raw pointer behind a `using` in another header, `std::function`,
`PointerIntPair`, `BasicBlock::iterator`, `unique_ptr<Instruction>`, and a nested record held
by value.

**Re-measured claims, all TRUE** (`results/guard_runs.txt`, `results/guard_selftest_rerun.txt`):
- The clean header: 57 members, 0 problems.
- `--selftest`: 2 null controls, 57 mutants, 0 failed.
- Fail-closed on a nonexistent `--clang` and on a bad `--llvm-include` (rc 1).

**Cost.**
- `--selftest` took **109 s wall / 399 s user CPU** under load (record: 66 s). That is the heaviest CPU consumer the change adds to ctest.
- A PCH of the header's include set, built with the build's flags, would remove most of it without changing what is asked. Passing the build's defines would also close A5.
- Report only; nothing was changed.

## F-R2-3 (P3, pre-existing over-decline)

The same p2 matrix shows it:
- p2_T declines in `slice()` on all four binaries, while p2_N accepts.
- The lift that triggers it is in `main()`.

An always-sweep mutant of the subject (`R2_ALWAYS_SWEEP=1`; `results/ab_always_sweep_{lit,e2e}.txt`) declines five shipped accepts:
- lit: `control_swap_inloop_{derived,range}_cond.ll`;
- e2e: `control-grover-loop-derived`, `control-grover-loop-range-oracle` and `control-inplace-ry-loop-derived`.

That is the late-slot hazard `TaintPropagation.cpp` already documents for the 3d8q reader
sweep. The ruling of 2026-09-11 makes it a defect. It is not in this delta's scope.

## F-R2-4 (P3): the lit / CMake fallback

`probes/litcfg_fallback_probe.py` executes `lit.cfg.py`'s block verbatim (`results/litcfg_fallback_probe.txt`):

| case | result |
|---|---|
| (1) target present | no fatal; the driver's own path |
| (2) the CMake no-target branch sets the driver path equal to the `cq-opt` path | **no fatal**; `%debugalloc-cq-opt` silently becomes `cq-opt`, and every allocator pin passes vacuously |
| (3) control: driver older than `cq-opt` | FATAL |

- The branch is dead today: `add_executable(cq-opt-debugalloc)` is unconditional and precedes `add_subdirectory(test)`.
- Its comment still says "cannot go falsely RED". r1B F-EB-4 said that was the wrong half to promise.
- Misfire analysis of the mtime check:
  - No false fatal on a complete build: `add_dependencies(cq-opt-debugalloc cq-opt)` orders the links, and coarse mtimes compare equal, never "older".
  - It cannot detect *both* binaries being stale (the old `CQPass`-only trap). That is pre-existing.
- CLAUDE.md's "name ALL THREE" build line omits `cq-scrub-selftest`.

## F-R2-5 / F-R2-6 (P3 notes)

**F-R2-5.**
- The null-`F` branch is unreachable:
  - No `Function` is erased in `specialize()`. Grep of `Specializ*.cpp` finds none, and none among its callees (`lowerCloneControl`/PredMux, `lowerOps`/`lowerQramReads` on `cloneTaint`).
  - `NULL-F` fired in 0 of 3254 modules.
- Its decline verdict is right. Two blemishes:
  - It anchors on the first defined function, so the function name is misattributed when `L.DL` is empty.
  - `return false` exits the whole record loop.

**F-R2-6.** The k65 e2e module, 20 runs each: `results/ab_e2e_fam.txt`, and the command in §"measurements".

| binary / allocator | wrong stream |
|---|---|
| ba80 system | 10/20 |
| ba80 + r1B `rb8` lifo | 20/20 |
| ba80 + `rb8` nofree | 0/20 |
| subject system | 0/20 |
| subject debugalloc-lifo | 0/20 |

## The attack list, item by item

1. **The logic list is complete.** Checked with a comment- and whitespace-stripped diff (`strip.py`, string-literal aware), run over every `.cpp`/`.h` in `0b07629e..c416f04d`.
   - Controls first: the same revision twice gives 0 diffs; `e24126b1` alone gives 0 code changes over 8 files; `152fafe1` shows its change (positive control).
   - The full delta is exactly items 1–5 plus `#include "llvm/IR/Instructions.h"` in `ScrubOnDelete.h` and `#include "ScrubOnDelete.h"` in `LoopPlan.h`. Nothing unlisted.
   - The merge commit's tree equals `git merge-tree --write-tree 818f8afa ba80bda1` except for the regenerated `CODE_MAP.md` and the records, so it is a pure auto-merge.
2. **Merge semantics.**
   - d88e's 21 fixtures are unchanged vs ba80bda1 (git), and 2305 of 2306 lit fixtures are byte-identical vs ba80 in stdout, stderr and rc.
   - d88e's `WeakTrackingVH` records never *query* a dead pointer: a handle is live or null, and `GateCalls` is rebuilt at re-ask time.
   - A followed-to value answers differently from ba80 only when it sits at a dead key's address. That is the 8e5r class, and there the subject gives the no-reuse reference.
   - The retargetSite fp rebuild re-inserts `NewCall` (quantum) on both binaries, or on neither (classical).
   - The composition hazard I did find is F-R2-1, through the other d88e change: the slot move.
3. **Item 2 (null `F`).** Unreachable, per F-R2-5. The fallback verdict (decline) is sound.
4. **Item 3.**
   - The `ScrubMap` snapshot is used only through `find`/`end`/`->second` (`LoopLowering.cpp:4749-4753`).
   - The copy constructor skips dead keys and re-arms hooks. For a live key the answers equal the old `DenseMap`'s.
   - Iteration order is never used.
   - The one semantic change is the intended one: a block revived at a dead Pred's address reads `Before = 0`.
5. **Item 4.**
   - The complete set of `BirthOrder` writers (grep `BirthOrder[`/`NextBirth`) is `lowerOps`-family, the emitters, `lowerCloneSelect`, `lowerQramReads`, `lowerRotations` and `propagate`'s rail-bank seed.
   - None can write the outer clone's `cloneTaint` before or during the inner-call loop:
     - `seedClone` does not.
     - PredMux has no writer and calls none.
     - A nested `buildClone` has its own `cloneTaint`.
     - `specialize()` runs once per entry point.
   - Measured: `BIRTHORDER-NONEMPTY` in 0 of 3254 modules. The path is exercised (`INNER-REBUILD`) in 2 lit modules.
   - The deleted erase-by-dead-pointer was equivalent: nothing allocates between `retargetSite`'s erase and it, and `std::set` is address-ordered.
6. **The AST guard.** See F-R2-2.
7. **The driver/lit changes.** See F-R2-4. Allocator modes were re-measured:
   - `LIFO`, `lifo2` and `' '` exit 2 with a message.
   - `lifo`, `nofree` and unset run.
   - The selftest: `--require-reuse` without `lifo` exits 2; `lifo` gives 287/0 with reuse 31/31 REQUIRED; `nofree` gives 206/0 with 31/31 branches (81 checks) SKIPPED and reported; the system allocator gives 287/0.
8. **Re-measurement** (`probes/ab_r2.sh` + `ab_cmp_r2.py`). Each module's stdout IR, stderr and rc are compared; 0-byte inputs are refused; no pipes before `rc`.

   | comparison | modules | result |
   |---|---:|---|
   | lit, null: subject twice | 2306 | 2306 same |
   | comparator positive control (one perturbed output) | 2306 | 1 mover |
   | lit, ba80 vs subject | 2306 | 2305 same, 1 STREAM (the k65 fixture) |
   | e2e, null: subject twice | 425 | 425 same |
   | e2e, ba80 vs subject (single system run; see F-R2-6) | 425 | 425 same |
   | alias families, subject system vs debugalloc lifo | 523 | 523 same |
   | alias families, subject system vs debugalloc nofree | 523 | 523 same |

   The pins, 10 runs each (`results/pins_r2.txt`):

   | pin | subject | ba80 + rb8 |
   |---|---|---|
   | k65 | PASS 10/10 | FAIL 10/10 |
   | four um24 `nofree` lines | 40/40 clean decline | 40/40 SIGSEGV |

**Harness traps that fired on me (L10), and what caught them.**
- My first e2e/family sweep passed a zsh-unsplit glob as ONE argument. `ab_r2.sh`'s empty-input refusal stopped it (exit 3).
- My first k65 repeat compared outputs whose ModuleID paths differed, and reported "non-reference 20/20" for everything. The **subject** row, as a null control, exposed it.

## What I did NOT attack

- **The runs I did not make:**
  - The full `ctest`.
  - The `lit` harness itself: I ran pass-level A/B with the default invocation, not each fixture's RUN lines and FileCheck, except the pins.
  - `cq-opt-equivalence-full`, the duplicate-body scan and `update_code_map.py --check`.
- **The cleared container mechanism** (scrub containers, hooks, allocator internals). Out of scope by instruction.
- **Whether F-R2-1 hides a real stale op (P1).** I did not search beyond the reconstructed argument; a second caller-side eraser inside `specialize()` would change it.
- **Whether F-R2-3's in-loop decline is an over-decline or a true positive.** I treated it as the former on the strength of the shipped rolled-vs-unrolled twin gates, and did not verify it independently.
- **The oracle's family flakiness at N=10**, the 9bhg composition, and non-Apple builds.
- **Guard spellings built with macros spread across several headers**, beyond A5.

## Files

- `probes/guard_fool_r2.py`
- `probes/ab_r2.sh`, `probes/ab_cmp_r2.py`
- `probes/pins_r2.sh`
- `probes/litcfg_fallback_probe.py`
- `probes/build_probes.sh`
- `probes/p1_liftskip/{caller.c,lib.c,k1.ll}`
- `probes/p2_liftskip_verdict/{caller_{C,T,N}.c,lib.c,p2_{C,T,N}.ll}`
- `probes/instr_{subject_c416f04d,oracle_ba80bda1}.patch`
- `probes/results/*`

No executables. Private worktrees were removed after the review.
