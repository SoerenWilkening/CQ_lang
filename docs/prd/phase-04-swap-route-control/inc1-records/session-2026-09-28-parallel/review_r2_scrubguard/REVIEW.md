# REVIEW r2: `tools/taintset_scrub_guard.py` round 2 (bd wop9 / 7gri / jk56; r1 findings hdxo ehni ofvm ngfa 5ci2 s6ma)

| | |
|---|---|
| Subject | `worktree-agent-a196dcc5b08be6dc0` at `a5cab4f7`. Diff `223685ac..a5cab4f7`: `6453baa7` (the fix), `30e7a590` (shards), `a5cab4f7` (records). |
| Guard under review | `tools/taintset_scrub_guard.py`, sha-256 `e4ab4f28d0fa30ec`. `check()` is byte-identical to `6453baa7` (`bbf1a106`). I verified this myself: the `6453baa7..30e7a590` diff touches only `_shard_of` → `_shards` and two docstrings. |
| Binaries | `build/ir-pass/cq-opt` sha-256 `3f6db37f5cf937b4d70f5736`, the same as the frozen oracle `cq-opt.main_9a230646` (measured). The compiler is not the subject. |
| Older guards (INTRODUCED vs PRE-EXISTING) | Round 1 `223685ac`, guard sha `99a7df7cf90bb6a2`. Main `9a230646`, guard sha `d26862662f12f1f5`. Each ran from a PRIVATE worktree under `<scratch>/rev_r2_scrubguard/`, with the subject's `compile_commands.json` rewritten to point at that worktree. |
| Time | About 55 min wall (09:38 → 10:35 CEST). Load 9 at the start, 53–107 at the end (other agents). `CQ_GUARD_JOBS=4` throughout. |
| Verdict | **NOT-CLEAR** |

## What I ran, literally

Every command is in `probes/run_all_r2.sh`. All outputs are in `probes/results/`.

1. **`probes/build_compiles_r2.py`: does the build compile each probe header?** For every probe it runs the build's OWN commands from `compile_commands.json`, with `-fsyntax-only` and `-I<mutdir>` placed first, on:
   - `scrub_selftest.cpp` (the cq-opt configuration);
   - `CQLoweringPass.cpp` (the CQPass configuration);
   - a usage TU (CQPass configuration) that WRITES INTO the raw table.

   For the include-order probes it also greps the `-E` output of real build TUs for the member: `CQLoweringPass.cpp`, `SpecializeSeed.cpp` (which reaches the header at include level 2) and `LoopLowering.cpp`. **Every attack header compiles in both configurations, and every usage TU compiles.** The member is in the real TU's `-E` output for B6 (`CQLoweringPass.cpp`), B9 (`SpecializeSeed.cpp`) and B11 (`CQLoweringPass.cpp`, `LoopLowering.cpp`).
   - Correction to my own instrument: the first run's B9 usage TU included `ArmClassify.h`, which does not reach `TaintPropagation.h`. That is the `exit 1` in `build_compiles_r2.txt`. `build_compiles_r2_B9_B6.txt` supersedes that row, using `SpecializeSeed.h`, which does reach it.
2. **`probes/guard_fool_r2.py <subject>`: the subject guard's verdict.** It imports the guard UNMODIFIED and calls `check()` with the gate's semantics (`USE_PCH=False`, both configurations, and the include-order check on). Controls run first. It prints every refusal line and every tolerated note, so the battery probe can be attributed member by member.
   - N0 (pristine) is clean: 75 members, 15 tolerated.
   - C1 is refused as RAW: the B1 table held strictly.
   - C2 is refused as "preprocesses DIFFERENTLY": the A5 shape in `TaintPropagation.h` itself.
   - Output: `guard_fool_r2.txt` and `guard_fool_r2_B11.txt`.
3. **`probes/fail_open_r2.py`: fail-open of the NEW include-order check.** A wrapper compiler misbehaves ONLY on the two `-E` TUs whose names contain `cq_guard_ctx`. The header is the A5 shape, which the intact database refuses (control).
4. **`probes/tree_probes_r2.py`: the gate's own CLI on a REAL mutated tree.** It runs `taintset_scrub_guard.py --compile-commands … --jobs 4`, which is `main()`, in a private worktree of `a5cab4f7` whose `ir-pass/include` I mutate. This is needed because `check()` copies only the TOP-LEVEL `.h` files into its probe directory.
   - Controls D0 (pristine, exit 0) and D3 (A5 shape, exit 1).
   - The worktree was restored after every case; `git status` was clean afterwards.
5. **`probes/guard_fool_r2_cmp.py` and `probes/cmp_main_extra.py`: the same probes on the round-1 guard and on the main guard.**
   - The main guard's `check()` takes no `extra_headers`, so for B1, B2, B7 and B8 the extra files were written into the private main worktree's real include directory and then restored.
   - Main uses its own default semantics (PCH), as review r1 did.

**What I did NOT run:**
- no `--selftest` shard;
- no ctest, no lit, no corpus.

The binaries are the oracle's. The brief says not to re-run the implementer's sweeps. I spot-checked the implementer's round-2 claims:
- the C2/D3 A5 control is refused as claimed;
- the r1 fail-open row F2-class (signal): my G3 is refused;
- the shard-commit-is-shard-only claim (diff read).

**What I did not attack:**
- no Debug tree and no non-Apple toolchain;
- no attack on the `scrub::` shape rules or on the template-pimpl rule beyond reading them (§"Tested and did not break").

## The soundness argument, restated, and the steps that are ASSERTED

Round 2 claims six closures:
- an unnamed record is identified by the compiler's `(unnamed struct at FILE:LINE:COL)`;
- a base is verified by `is_base_of` plus the injected-class-name looked up through the derived class;
- the include-order check makes the probe's preprocessing context the build's, up to R10;
- the allowlisted "fields" policy makes "never a table asked by IDENTITY" a checked premise;
- the configuration layer and the compile layer fail closed;
- type-erased library bases are closed-world.

Five steps are asserted rather than measured, and each falls to a header the Release build compiles:

1. **"`FILE:LINE:COL` is the compiler's identity for an unnamed record."**
   - It is the record's PRESUMED location: the macro EXPANSION point, after any `#line`.
   - It is also keyed without the walk MODE.
   - (F-R2-1, F-R2-2.)
2. **"`typename D::B` names the base."** The derived class can declare its own `B` (F-R2-3).
3. **"The header's include closure" is computed by a regex over QUOTE includes of top-level `.h` files in the probe directory.** The compiler reads more files than that (F-R2-4).
4. **"One union context approximates every real TU's."**
   - The union context `#undef`s every closure guard, so "a closure file was included first", which is what real TUs do, is never simulated (F-R2-5).
   - It also compares TEXT (F-R2-6, L5).
5. **"No output from the preprocessor" reads as "no difference"** (F-R2-8).

## Findings

### F-R2-1: P1, REGRESSION vs main, not closed by round 2 (bd hdxo). An unnamed struct walked RELAXED inside the allowlisted `LoopBreakRegion` is accepted STRICTLY anywhere by `decltype`

```cpp
// LoopPlan.h, inside the allowlisted LoopBreakRegion (policy "fields"):
struct { llvm::Value *Tab[64]; unsigned N = 0; } RvU;
// TaintPropagation.h, namespace cq, a record held STRICTLY by TaintSet:
struct RvMid { decltype(LoopBreakRegion::RvU) E; };        // TaintSet: RvMid RvM;
```

**Measured:**

| guard | verdict |
|---|---|
| subject | **MISSED** (0 problems). The table is listed only as a relaxed-mode note on `LoopBreakRegion`. |
| round-1 guard | MISSED |
| main guard | CAUGHT (as a "function type" misparse, a lucky over-refusal) |
| control C1 (the same unnamed struct held strictly in TaintSet) | refused RAW |

Build: both configurations compile, and a usage TU that writes into `T.RvM.E.Tab[]` and searches it by identity compiles.

**Cause.** `W.anon_walked` is a set of location keys, not of `(key, mode)` pairs.
- `LoopBreakRegion` is walked in `relaxed_fields` mode in the same batch as `RvMid`, which adds the key.
- `field_top` then accepts `RvMid::E` in STRICT mode without walking it.
- The docstring says records are keyed by mode "so a record reached both through an allowlisted member and through an ordinary one is walked strictly as well". That is false for unnamed records.

The spelling needs no macro and no `#line`. It is the most natural of this class.

**Repro:**
```
cd <scratch> && CQ_GUARD_JOBS=4 python3 probes/guard_fool_r2.py <SUBJ> N0 C1 B1
```

### F-R2-2: P1 (adversarial spelling), REGRESSION vs main, not closed by round 2 (bd hdxo). The unnamed-record key can be FORGED by a macro expansion or by `#line`

- **B4, macro.** One macro expansion inside TaintSet defines a clean unnamed field and a member class template holding `struct { std::set<llvm::Value *> T; } U;`, and TaintSet declares `decltype(RvH4<>::U) RvEvil4;`.
  - Both unnamed structs print the SAME expansion point. It is `TaintPropagation.h:118:3` in main's copy, which main's refusal text shows.
  - The clean one is walked, so the raw one is accepted.
- **B5, `#line 7000`.** A raw unnamed struct in a record outside TaintSet is forged to the same `FILE:LINE:COL` as a clean unnamed field inside it.

| guard | B4 | B5 |
|---|---|---|
| subject | **MISSED** | **MISSED** |
| round 1 | MISSED | MISSED |
| main | CAUGHT (misparse) | CAUGHT (misparse) |

Both compile in the build, and a usage TU inserts into `RvEvil4.T` / `RvEvil5.T`.

**Why P1.** The docstring claims "an unnamed type the walk did not reach through its own declarator" is refused. Neither spelling is one an agent writes by accident.

**Fix direction** (also closes F-R2-1). Treat the key as a HINT, not an identity:
- record the ACCESS EXPRESSION and MODE of the declarator through which each unnamed record was walked;
- accept a field of that type only if it was walked in a mode at least as strict;
- have `_final` assert `std::is_same<decltype(<field access>) (extents stripped), decltype(<walked declarator access>)>`, which is asked of the compiler like every other spelling.

As a cheap backstop, also refuse `#line` and GNU line markers in closure files.

**Repro:**
```
python3 probes/guard_fool_r2.py <SUBJ> B4 B5
```

### F-R2-3: P1, REGRESSION vs main, defeats round 2's fix (bd 5ci2). A derived class that declares `using RvB = ::cq::RvB;` makes the anonymous-namespace RAW base pass as the clean one

```cpp
struct RvB { unsigned N = 0; };                                              // clean, cq::RvB
namespace { struct RvB { std::set<llvm::Value *> S; }; using RvRawB = RvB; } // raw, cq::(anon)::RvB
struct RvD : ::cq::RvB, RvRawB { using RvB = ::cq::RvB; };                   // TaintSet: RvD RvDV;
```

Two things happen for the raw base's text, `cq::(anonymous namespace)::RvB`:
- `_spell` gives `::cq::RvB`. `is_base_of<::cq::RvB, ::cq::RvD>` holds because the clean one IS a base. `typename ::cq::RvD::RvB` finds RvD's OWN alias, which is the clean record, so `is_same` holds.
- `_identify` resolves `::cq::RvB`, and a direct declaration beats the anonymous namespace's using-directive, so the walk walks the CLEAN body. The raw base is never seen.

| guard | verdict |
|---|---|
| subject | **MISSED** |
| round 1 | MISSED |
| main | CAUGHT (it walks both bases by name) |

Build: compiles. A usage TU does `static_cast<cq::RvRawB &>(T.RvDV).S.insert(V)`.

**The docstring over-claims in R8.** It says "a derived class that declares its OWN member named like the base … is refused (over-refusal)". That holds only when the alias names something else.

**Fix direction.** C++17 gives no name-free way to verify a base, so REFUSE any base whose canonical text contains `(anonymous namespace)` or a function-local class. The re-spelling is lossy exactly there, and the tree holds none today. (Fields are protected by the `is_same` check against the robbed member type; bases have no such anchor.)

**Repro:**
```
python3 probes/guard_fool_r2.py <SUBJ> B3
```

### F-R2-4: P1, PRE-EXISTING vs main (main has no include-order check), a claimed round-2 closure (bd ngfa). The include-order check's CLOSURE misses every closure file that is not a quote-included top-level `.h`

The check claims to refuse "an include-order dependent header" (docstring (6); WHAT IT CATCHES). The member is the A5 shape (`#ifdef CQ_IRPASS_CQ_LOWERING_PASS_H_`), which the check REFUSES when it is written in `TaintPropagation.h` itself (C2 / D3). Moved one include away, it passes:

| probe | how the member's file is reached | subject verdict |
|---|---|---|
| B7 | `#include <RvCtx7.h>`: an ANGLE include of a project header. `-I ir-pass/include` is in the build. | **MISSED** |
| B8 | `#define H "RvCtx8.h"` / `#include H`: a COMPUTED include | **MISSED** |
| D1 | `#include "detail/RvSub.h"`: a SUBDIRECTORY of `ir-pass/include`. The gate CLI on a real tree **exits 0**. | **MISSED** |
| D2 | `#include "TaintMembers.def"` INSIDE TaintSet: the LLVM X-macro idiom. The gate CLI on a real tree **exits 0**. | **MISSED** |

For D1 and D2 the real `CQLoweringPass.cpp -E` contains `std::set<llvm::Value *> RvSubS;` / `RvDefMember;`, and `-fsyntax-only` exits 0 (`tree_probes_r2.txt`). Round 1 also missed B7 and B8 (no check). Main missed B7 and B8.

**Cause.**
- `_closure` follows only `#include "X"` (regex) for names that exist in the probe directory.
- `check()` copies only TOP-LEVEL `*.h`, so a subdirectory or a `.def`/`.inc` file is read from the REAL tree through the build's `-I` and never compared.

R10 lists (a) `.cpp` defines, (b) macro combinations and (c) TU-local headers, and none of these.

**Fix direction.** Take the closure from the COMPILER: the `-M`/`-H` dependency list of the probe compile. Refuse any project file in it that is not in the probe directory, or copy the whole `ir-pass/include` tree including other extensions.

**Repro:**
```
python3 probes/guard_fool_r2.py <SUBJ> B7 B8
python3 probes/tree_probes_r2.py <private-wt> <cc_wt.json>
```

### F-R2-5: P1, PRE-EXISTING vs main, a claimed round-2 closure (bd ngfa). The union context `#undef`s every CLOSURE guard, so a closure file that a real TU includes FIRST is never simulated

```cpp
// TaintPropagation.h, right after its own #define guard, BEFORE its #include "LoopPlan.h":
#ifdef CQ_IRPASS_LOOP_PLAN_H_
#define CQ_RV_LOOPPLAN_FIRST 1
#endif
// ... inside TaintSet:
#ifdef CQ_RV_LOOPPLAN_FIRST
  static inline std::set<llvm::Value *> RvLpFirst;
#endif
```

This is the same class as the self-test's own A5, except that the macro is a CLOSURE header's guard:
- `LoopLowering.cpp` includes `LoopPlan.h` before `TaintPropagation.h`, and so, measured, does `CQLoweringPass.cpp` (transitively).
- The probe context has the guard undefined.
- The union context DEFINES all closure guards, includes everything, `#undef`s them all, and only then includes the header. So at the header's first line `CQ_IRPASS_LOOP_PLAN_H_` is undefined in both contexts, and they are identical.

**Measured.**
- Subject: MISSED. Round 1: MISSED. Main: MISSED.
- The real `LoopLowering.cpp -E` and `CQLoweringPass.cpp -E` both contain `static inline std::set<llvm::Value *> RvLpFirst;` (`build_compiles_r2_B11.txt`).
- The case is not in R10: it is a single macro, not a combination, and the header is not TU-local.

**Fix direction** (also closes R10(a)/(b)/(c) and F-R2-6's B9). Drop the union approximation and `-E` the REAL TUs:
- for each `src` of each configuration, `-E` it with the probe directory first on `-I`;
- compare the closure segments against the lone header's.

That is about 54 TUs × 2 configurations of `-E`, parallel under the semaphore. That costs seconds, not minutes, and it measures the build rather than approximating it.

**Repro:**
```
python3 probes/guard_fool_r2.py <SUBJ> B11
python3 probes/build_compiles_r2.py <SUBJ> <scratch> B11
```

### F-R2-6: P2, PRE-EXISTING vs main. The include-order check is TEXTUAL over line-marker attribution, so three more routes pass (L5)

- **B6, `#line 1 "RvElsewhere.h"` before the `#ifdef`.** From that point the `-E` lines are attributed to a file that is not in the closure, so they are never compared. The member is in the real `CQLoweringPass.cpp -E`.
- **B9, `#if __INCLUDE_LEVEL__ > 1`.** Every probe TU, and both `-E` contexts, include the header at level 1. `SpecializeSeed.cpp` reaches it at level 2 through `SpecializeSeed.h`, and its real `-E` contains `RvLevel` (measured).
  - This CORRECTS the TRACK's ATTACK-FIRST §R2.3 item 1, which predicted that `__INCLUDE_LEVEL__` "would make the two contexts differ spuriously. That is an over-refusal." It is a false PASS.
- **B10, no macro at all.** `RvSel<CQLoweringPass>::type`, SFINAE on `sizeof(T)`, is `unsigned` when the header is alone and `std::set<llvm::Value *>` in `CQLoweringPass.cpp`, where `cq::CQLoweringPass` is complete before the header. The token text is identical in every context. Build: a usage TU inserts into it.

Subject, round 1 and main all MISSED all three.

**Why P2.** B6 and B9 are adversarial spellings, and B10 cannot be closed by any textual check. But docstring (6) and WHAT IT CATCHES claim "an include-order dependent header" with no semantic caveat. R10's closing sentence ("the rest is IFNDR the compiler cannot catch either (TaintSet's token sequence would differ per TU)") does not cover B10, where the token sequence is identical.

**Fix.**
- STATE B10 as a residual.
- Refuse `#line`, line markers, `__INCLUDE_LEVEL__`, `__COUNTER__`, `__FILE__` and `__BASE_FILE__` in closure files. This is cheap.
- F-R2-5's per-TU `-E` also closes B9.

**Repro:**
```
python3 probes/guard_fool_r2.py <SUBJ> B6 B9 B10
```

### F-R2-7: P2 (docstring and ALLOWLIST over-claim), PRE-EXISTING vs main (it exempted the subtree wholesale). The "fields" policy tolerates identity TABLES in `LoopBreakRegion`

The docstring and the ALLOWLIST reason say the "fields" policy "is what makes the reason 'never a table asked by IDENTITY' a checked premise". B2 adds the following to `LoopBreakRegion`, and every one is tolerated as a note:
- `llvm::Value *RvTab[64]` (a C array);
- `llvm::Value **RvHeap` (a heap array);
- `llvm::SmallVector<RvSlot, 8>` with `struct RvSlot { llvm::Value *V; }` (a sequence of one-pointer records).

Subject: 0 problems, 18 tolerated. The usage TU searches `RvTab` and `RvSlots` by identity.

Meanwhile `llvm::SmallVector<llvm::Value *>` and `std::array<llvm::Value *, 4>` there ARE refused. The letter of the rule ("a record's OWN field") is honoured, so this is an over-claim, not a false pass against the rule text. Only the "checked premise" sentence is false.

**Fix.** Either refuse array/indirection depth > 0 and pointer fields of records reached through a container under "fields", or reword to what is checked.

**Repro:**
```
python3 probes/guard_fool_r2.py <SUBJ> B2
```

### F-R2-8: P2, INTRODUCED (new code in round 2). The include-order check FAILS OPEN on a preprocessor that prints nothing or no line markers

`_preprocessed` returns `{}` when there is no attributed output. `_context_problem` then compares `None == None` for every closure file and reports no problem. There is no canary, unlike round 2's own `CQALIVE` fix for the final probe (F-R1-11).

Measured on the A5-shape header (`fail_open_r2.txt`):

| case | verdict |
|---|---|
| intact database | refused |
| **G1**: wrapper exits 0 with no output on the two `-E` TUs | **CLEAN** |
| **G2**: wrapper adds `-P` (no line markers) | **CLEAN** |
| G3: SIGKILL | refused, truthfully ("killed by signal 9") |

**Fix.** Require that `TaintPropagation.h` has attributed lines in BOTH outputs, and that the two outputs attribute the same set of closure files. Otherwise raise `GuardError`.

**Repro:**
```
python3 probes/fail_open_r2.py <SUBJ> <scratch>
```

### F-R2-9: P3. Record and hygiene

- (a) The TRACK's §R2.3 `__INCLUDE_LEVEL__` prediction has the wrong direction (F-R2-6).
- (b) Nothing checks that CMake registers all three shards. A `foreach(_k 1 2)` edit would silently drop a third of the corpus. The shards are self-consistent only if every `k` in `1..n` is registered.
- (c) `build_compiles_r2.txt`'s B9 row is my own instrument error. It is superseded, see "What I ran".

## Standing-lesson questions (tooling-adapted)

- **L2/L3.** Two keys are computed over the same walk: `W.walked` is keyed by mode, and `W.anon_walked` is not. The narrowing of one was not carried to the other. That is F-R2-1, L2's shape.
- **L5.** Three syntactic answers to semantic questions:
  - the unnamed-record identity by printed location (F-R2-2);
  - the include closure by regex (F-R2-4);
  - include-order dependence by text (F-R2-6).
- **L7.** False or unruled prose:
  - the ALLOWLIST "checked premise" (F-R2-7);
  - R8's "is refused" (F-R2-3);
  - `anon_walked`'s docstring "walked through a declarator of the record being walked". It is ANY record, in ANY mode.
- **L10.** The new check's failure mode is a pass (F-R2-8), and the instrument had not been made to fail on a silent preprocessor.
- **Rule 14.** The "is this the header's closure" question now has two spellings with different answers:
  - `_includes_header`'s quote-include walk for configuration discovery (R3);
  - `_closure`'s probe-directory walk.

  Neither is the compiler's own answer.

## Tested and did not break (coverage, not silence)

- **Library-template battery (B12), one probe of 14 members.** Every one was refused, for a named reason:
  - `SmallVectorImpl<Value*> *`
  - `std::function<void()>`
  - `PointerIntPair<Value*,1>`
  - `PointerUnion<Value*,BasicBlock*>`
  - `MutableArrayRef<Value*>`
  - `std::any`
  - `unique_function<void()>`
  - `DenseMapBase<…> *`
  - `std::shared_ptr<void>`
  - `SmallVectorTemplateCommon<Value*> *`
  - `function_ref<void()>`
  - `std::reference_wrapper<Value> *`
  - `iterator_range<Value**> *`
  - `std::pair<Value*,int> *`

  `std::array<unsigned char, 64>` passed, which is the documented OUT OF SCOPE byte-storage case.
- **Fail-closed on SIGKILL of the new `-E` TUs (G3).**
- **The controls:**
  - N0, C1 and C2 behave;
  - D0 and D3 on a real tree through `main()`;
  - N0 on the round-1 and main guards.
- **Not attacked beyond reading:**
  - the `scrub::` shape rules. The by-name trust is R1, and a same-named `scrub::Set` in an inline namespace is ambiguous under the `is_same` re-spelling, so it is refused. This is argued, not run.
  - the template pimpl rule. Member classes and member templates of an instantiated template, reached by pointer, resolve to "missing"/"uninstantiated" and are refused. This is also argued, not run.
- **The configuration layer's F1 fix.** I only read it.

## The self-test cost question (owner decides): my opinion

Keep the **gate entry** (`taintset-scrub-guard`, about 30–60 s) at every merge gate. Run the **self-test shards** at every merge gate where the full suite runs. I do not recommend the proposed narrow path trigger (the guard, `ir-pass/include/*.h`, the toolchain).

1. **The self-test's verdicts depend on more than those paths.**
   - The include-order mutants (A5′) depend on `ir-pass/src/*.cpp` INCLUDE LISTS. `_context_problem` builds its union context from every TU's `#include`s. `LazyValueInfo.h` is included by exactly one `.cpp` (`ArmClassify.cpp`, measured by grep). If that include moves, A5′ flips to MISSED, silently, on a merge that touched no header.
   - The COV mutants depend on `ir-pass/tools/scrub_selftest.cpp`.
   - The configurations depend on the CMake files and on the compiler.

   So a correct trigger is `ir-pass/**`, both `CMakeLists.txt`, `tools/taintset_scrub_guard.py` and the compiler identity. That is nearly every code merge, and the saving is small.
2. The self-test is the instrument's only defence against L10 ("an instrument's failure mode is to report a pass"). A path trigger that is too narrow turns a silent flip into an unobserved one.
3. The cost is mostly concurrent wall time. Three `--jobs 2` shards of about 390 s run beside `e2e-loop-twin-matrix` (about 180–400 s), which is already the long pole. The marginal wall cost at `-j6` is well under the shards' own 390 s, so the price is CPU contention, not a longer critical path. That is measured by the implementer, not by me.

If the owner still wants a trigger, it must be the wide one above, not the narrow one.

## Beads

Notes were appended (`--append-notes`) to the open round-1 beads each finding re-opens: hdxo (F-R2-1/2), 5ci2 (F-R2-3), ngfa (F-R2-4/5/6), s6ma (F-R2-7/8). No bead was created or closed.
