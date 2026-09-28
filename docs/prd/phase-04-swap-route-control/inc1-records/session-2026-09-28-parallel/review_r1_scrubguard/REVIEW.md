# REVIEW r1 — `tools/taintset_scrub_guard.py` rewrite (bd wop9 / 7gri / jk56)

| | |
|---|---|
| Subject | `worktree-agent-a196dcc5b08be6dc0` @ `223685ac`, diff `9a230646..223685ac` |
| Guard under review | `tools/taintset_scrub_guard.py` sha-256 `99a7df7cf90bb6a2…` (the committed guard, §4.3 of the TRACK) |
| Binaries | `build/ir-pass/cq-opt` sha-256 `3f6db37f5cf937b4d70f5736` = the frozen ORACLE `cq-opt.main_9a230646` (measured). The compiler is not the subject. |
| Oracle guard | `main` `9a230646`, sha `d26862662f12f1f5`, in a PRIVATE worktree `<scratch>/rev_r1_scrubguard/wt_oracle` (removed at the end) |
| Time | ~55 min wall (20:51 → ~21:45), load 145–390 throughout |
| Verdict | **NOT-CLEAR** |

## What I ran, literally

Every command is in `probes/run_all.sh`; outputs are in `probes/results/`.

1. `probes/guard_fool_r1.py <subject>`. It imports the guard UNMODIFIED from the subject tree and calls `check()` with the GATE's semantics (`USE_PCH=False`, the setting `main()` forces), so both configurations run and no PCH is used. Controls run first. 22 probes in total over two batches: `results/guard_fool_r1.txt` and `results/guard_fool_r1_batch2.txt`. Every control behaved:
   - N0 is clean: 75 members, 15 tolerated notes, which matches the TRACK's "15 tolerated".
   - C1–C5 and K1–K3 are all refused, each for the right reason.
2. `probes/build_compiles.py`. For every missed header it runs the build's OWN commands from `compile_commands.json` with `-fsyntax-only` and `-I<mutdir>` first, on three TUs:
   - `ir-pass/tools/scrub_selftest.cpp` (cq-opt configuration);
   - `ir-pass/src/CQLoweringPass.cpp` (CQPass configuration);
   - a usage TU that WRITES INTO the raw table (CQPass configuration).
   Every missed header compiles in all three (`results/build_compiles_*.txt`).
3. `probes/guard_fool_r1_oracle.py`. The same probes against the ORACLE guard, for INTRODUCED vs PRE-EXISTING. It uses the subject's database with the paths rewritten to the oracle worktree, and the oracle's own default (PCH): `results/guard_fool_r1_oracle.txt`.
4. `probes/fail_open.py` tests the configuration and compile layers:
   - a malformed DB entry;
   - a compiler SIGKILLed on the final, member-type or identity TU;
   - a compiler that exits 0 silently.
   Outputs: `results/fail_open*.txt`.
5. `probes/composition.py` runs the subject guard over the TaintSet headers of the two other tracks of this session that add a TaintSet member: `results/composition.txt`.

**What I did NOT run.** No lit, no ctest, no `--selftest`, and no corpus or e2e layer. The binaries are the oracle's, and the brief says not to re-run sweeps. I did not re-run the implementer's source mutants S0–S8. My spot-checks of their claims are:
- the `#ifndef CQPass_EXPORTS` control in `fail_open.py` (r3 B3 re-measured: refused by the cq-opt configuration);
- K1–K3 (their §8.8 "measure both": refused);
- C1/C2/C4.

I ran no Debug-configured tree and no non-Apple toolchain.

## The soundness argument, restated, and the step that is ASSERTED

The claim is that every type the walk judges comes from the compiler:
- the canonical member types are re-checked with `is_same`;
- project records are walked by AST identity;
- every configuration is checked, without a PCH.

Six steps are asserted rather than measured, and each is broken below:

- `field_top`'s "an unnamed type is walked where it is defined". It is walked only when the definition is the immediate sibling of the declarator (F-R1-1).
- The type-string parser is total over canonical spellings. It misreads `*const` / `*volatile` / `*__restrict` (F-R1-2).
- A `scrub::` container is safe by its name. Its `StorageT` argument can carry anything (F-R1-5).
- "The instantiation is forced if the program only points at it" equals "the definition the build selects" (F-R1-3).
- "No PCH ⇒ the preprocessing context is the build's". A real TU includes other headers before `TaintPropagation.h` (F-R1-4).
- `_spell`'s "an `(anonymous namespace)::` member is visible in the enclosing namespace". This is false under shadowing, and the base check is only `is_base_of` (F-R1-6).

## Findings

### F-R1-1 — P1, INTRODUCED (a regression: the oracle guard REFUSES it). An unnamed struct type DEFINED OUTSIDE the walked record, held by value, is never walked.

```cpp
struct RvHolder { struct { std::set<llvm::Value *> T; } U; };   // in namespace cq, before TaintSet
struct TaintSet { decltype(RvHolder::U) RvAnon; /* ... */ };
```

Results:
- The guard reports **0 problems** in both configurations (76 members).
- The build compiles both configurations, and the usage TU `TS.RvAnon.T.insert(V)` compiles.
- A1b is the same with an alias over a global unnamed-struct variable, held as a `static inline` member: 0 problems. It is PRE-EXISTING (the oracle misses A1b too).
- The oracle guard refuses A1 (it misreads the text as a "function type" and refuses; `results/guard_fool_r1_oracle.txt`).

The mechanism has three parts:
- The canonical type is `cq::RvHolder::(unnamed struct at …)`, which `parse_type` reads as `anon`.
- `Walk.field_top` then `return`s with the comment "the record is walked where it is defined". But `_walk_record`'s unnamed-record branch walks only a `CXXRecordDecl` that is the IMMEDIATE sibling of this record's declarator, so a definition in another record is never walked.
- `_final` skips the `is_same` spelling assertion for an unspellable canonical text, so no backstop fires.

This contradicts the docstring's "every field and static data member … members of unnamed structs through their field" and "an unnamed type used where the walk cannot follow it" (listed under WHAT IT CATCHES).

**Fix direction.** The unnamed-record branch should record the declarator path it consumed, and `field_top` should refuse `anon` on any other path (closed world). Alternatively, resolve that record through the member TU's `RecordType` decl id. Never skip the spelling assertion silently. Pin with A1 and A1b.

Repro: `python3 probes/guard_fool_r1.py <subject> A1 A1b` and `python3 probes/build_compiles.py <subject> <scratch> A1 A1b`.

### F-R1-2 — P1, PRE-EXISTING. A cv-qualified INNER pointer hides a `Value **`.

Probes:
- `const llvm::Value *const *RvSlots;`, a hand-rolled slot table read by identity in the usage TU: 0 problems.
- `llvm::SmallVector<llvm::Value *volatile *, 2>` (writable): 0 problems.
- Control C2, `const llvm::Value **`: refused.

Mechanism:
- `parse_type` strips `const`/`volatile` only when WHITESPACE precedes them (`\s+(const|volatile)$`). The canonical `*const` has none, so `llvm::Value *const *` parses as `('ptr', ('named', 'llvm::Value *const'))`. `__restrict` is never stripped at all.
- `_ptr` sends a `named` beginning with `llvm::` to `pointee_q`.
- `_final`'s `derived<llvm::Value, ::llvm::Value *const>` is false (not a class), the type is `complete`, and so it is accepted.

The code comment "T ** / T *[N]: judge the innermost pointee" and the docstring's "a raw pointer to a `Value`-derived type" both claim otherwise. The oracle misses it too.

**Fix direction:**
- Strip `const|volatile|__restrict|restrict` after `*` as well.
- Make `pointee_q` / `named_q` require `class` or `enum` in the trait answer, so the next misparse fails CLOSED instead of reading as "complete, not a Value".

Repro: `guard_fool_r1.py <subject> C2 A2 A2b`.

### F-R1-3 — P1 by the rubric, PRE-EXISTING. A template PIMPL: the forced instantiation is not the one the build selects.

```cpp
template <class T> struct RvImpl { int Clean = 0; };      // header
struct TaintSet { RvImpl<int> *RvP = nullptr; /*...*/ };  // header
template <> struct cq::RvImpl<int> { std::set<llvm::Value *> T; };   // a .cpp
```

The guard reports 0 problems. The build compiles, and the `.cpp` TU writes `TS.RvP->T.insert(V)`. The program is WELL-FORMED: no TU implicitly instantiates `RvImpl<int>` before the specialization is declared.

To find `RvImpl<int>`, `_identify` forces an instantiation with the SFINAE `sizeof`. That walks the PRIMARY's instantiation, which no TU of the build ever uses.

The non-template analog (`struct Impl; Impl *P;` defined in a `.cpp`) is REFUSED ("forward-declared pointee" is one of the guard's own mutants). The template form is therefore an asymmetry, not scope. The docstring's (3) claims "the explicit or partial specialization the build actually selects … The instantiation is forced if the program only points at it", and the forcing is exactly what makes that untrue here. Control C4 (the specialization inside the header) is refused.

**Fix direction.** Refuse a project class-template specialization that the header never instantiates and that the probe had to FORCE (treat it like an incomplete pointee). At minimum, add a residual and rewrite (3). The argument for P2: the specialization lives outside the header. If the orchestrator takes that view, the docstring must say so.

Repro: `guard_fool_r1.py <subject> C4 A3`.

### F-R1-4 — P1 by the rubric (IFNDR, see note), PRE-EXISTING. The probe TU's preprocessing context is NOT the build's.

```cpp
struct TaintSet {
#ifdef CQ_IRPASS_CQ_LOWERING_PASS_H_      // defined in CQLoweringPass.cpp, which includes
  static inline std::set<llvm::Value *> RvOrderIdx;   // CQLoweringPass.h BEFORE TaintPropagation.h
#endif
```

- The guard reports 0 problems, with **75 members**: the member does not exist in the probe TU.
- `CQLoweringPass.cpp` compiles with the member present, and so does a usage TU that includes `CQLoweringPass.h` first and inserts into the table.
- The probe TU puts `#include "TaintPropagation.h"` on its first line. A real TU does not: `CQLoweringPass.cpp` includes 23 project headers before it.

The docstring's (5) says "`main()` asks every configuration WITHOUT a precompiled header, **so the preprocessing context is the build's**". That is false: this is the mirror of r3's B4, keyed on source include order instead of the PCH. It is IFNDR, since TaintSet's token sequence differs between TUs. A `static` member avoids any layout effect.

Precedent: r3 graded the same species (B3/B4) under bead 7gri at P3. By this brief's rubric it is P1. I flag the inconsistency rather than resolve it.

**Fix direction.** A cheap and total check: preprocess (`-E`) each distinct real TU's prefix, meaning its lines up to and including the header include. Refuse if the text of any walked record differs from the probe's. At minimum, strike the "so the preprocessing context is the build's" clause and add a residual.

Repro: `guard_fool_r1.py <subject> A5` and `build_compiles.py <subject> <scratch> A5`.

### F-R1-5 — P1 by the rubric, PRE-EXISTING. `scrub::Set<StorageT, PtrT>`: `StorageT` is never walked.

```cpp
struct RvStore : std::set<llvm::Value *> { std::set<llvm::Value *> Hidden; };
struct TaintSet { scrub::Set<RvStore, llvm::Value *> RvScrubbed; /*...*/ };
```

The self-test source is given the one line the guard demands (`T.RvScrubbed`). With that:
- The guard reports 0 problems, and the build and usage TU (`TS.RvScrubbed.insert(V)`) compile.
- Control C5 holds the same `RvStore` as a plain field and IS refused, on both `<base>` and `Hidden`.

Mechanism: `_tmpl` returns for `SCRUB_KEYS_ONLY` before any `_arg`. Only `Map`'s mapped type is walked, and `Set`'s `StorageT` is a free project-type slot. The docstring says WHAT IT WALKS includes "every PROJECT type it reaches … as a template argument". R1 says only that a *specialization* of a scrub container is trusted by name.

**Fix direction.** Walk `Set`'s `StorageT` (KEY mode), or require it to be one of the two approved backing spellings (`std::set<PtrT>`, `SmallPtrSet<PtrT, N>`).

Repro: `guard_fool_r1.py <subject> C5 A9`.

### F-R1-6 — P2, INTRODUCED (the oracle guard REFUSES both). R8 by two more mechanisms, and `_spell`'s justification is false (L7).

Two probes pass with 0 problems, and the build compiles both:

- **A4**, an anonymous-namespace base:
  ```cpp
  struct RvB { int Clean; };
  namespace { struct RvB { std::set<llvm::Value *> T; }; struct RvMid : RvB, ::cq::RvB {}; }
  ```
  held as `RvMid RvM;`.
- **A4b**, a LOCAL class base:
  ```cpp
  struct RvL { int Clean; };
  inline auto rvMake() { struct RvL { std::set<llvm::Value *> T; }; return RvL{}; }
  struct RvMid2 : decltype(rvMake()), RvL {};
  ```

In both cases the raw base re-spells as the clean one, through `_spell` dropping `(anonymous namespace)::` and through clang printing a local class without its function scope. The identity lookup then walks the clean record, and `is_base_of<clean, Mid>` is true, so the raw base is never walked.

`_spell`'s comment says the dropped anonymous-namespace members "are visible in the enclosing namespace". That is false when the enclosing namespace declares the same name: qualified lookup finds the direct member first. R8 names only "AS-WRITTEN specialization arguments". This is also a regression: the oracle walked both `RvB`s by name, and it refused `::RvMid2` in a closed-world refusal.

**Fix direction:**
- Refuse a base whose canonical text contains `(anonymous namespace)`.
- Refuse two bases of one record that re-spell identically (a pure-Python check that catches A4/A4b).
- Correct the `_spell` comment and widen R8's text.

Repro: `guard_fool_r1.py <subject> A4 A4b`.

### F-R1-7 — P2, INTRODUCED. A fail-open path: a malformed database entry silently drops a whole configuration.

In `fail_open.py` F1, the cq-opt / cq-scrub-selftest entries get `"arguments": []` and no `"command"`. `_normalize` raises, and `_configs()` `continue`s. The pass list becomes `[CQPass]` only, and the `#ifndef CQPass_EXPORTS` raw member (r3 B3) reports **0 problems**. The control on the intact database refuses it.

The docstring's (1) says "a missing entry … FAILS CLOSED". CMake does not write such entries, which is why this is not P1.

**Fix.** Raise on any entry for a TU of this tree that cannot be parsed.

Repro: `fail_open.py <subject> <scratch> F1`.

### F-R1-8 — P2, PRE-EXISTING. A type-erased LIBRARY base pointer: `void *` is refused, `llvm::SmallPtrSetImplBase *` is not.

`llvm::SmallPtrSetImplBase *RvErased` points at a heap `SmallPtrSet<llvm::Value *, 8>`, as the usage TU shows. The guard reports 0 problems. This is the same hazard as the refused `void *`: the rationale is "can hold a Value address the compiler cannot see". But a pointer to a non-template library base of a keyed container erases the arguments that the r3 (a) fix walks.

**Fix.** Refuse it, or list it under OUT OF SCOPE. The out-of-scope list names only IR-adjacent objects and plain integers today.

Repro: `guard_fool_r1.py <subject> A10`.

### F-R1-9 — P2, a docstring and comment over-claim (L7).

- The `ALLOWLIST` reason for `BreakRegions` says the premise "never a table asked by IDENTITY … is CHECKED". It is not. `llvm::EquivalenceClasses<llvm::Value *>` (a `std::set`-backed identity table) and `llvm::UniqueVector<llvm::Value *>` (a `std::map`-backed one) added to `LoopBreakRegion` each pass as ONE NOTE with 0 problems (A6/A6b). Only the KEY of a LISTED associative container is checked, as R2 and R7 themselves say. The reason text contradicts the residuals.
- The new `TaintPropagation.h` comment reads "A raw pointer-keyed member FAILS the `taintset-scrub-guard` ctest". That is unqualified, and false by F-R1-1/2/5. The old text said "in the common spellings". The CMake comment says "a compiler-assisted check that no raw Value-identity table is (re)added".

### P3 items

- **F-R1-10.** The type-erasure story is incomplete. `std::set<const char *>` holding reinterpret_cast'd Values passes by contract (builtin pointee, A8), and so does an `alignas` byte array holding a placement-new'd `std::set<Value *>` (argued, not run). OUT OF SCOPE names only plain integers. Add "a pointer to a builtin / raw byte storage" there.
- **F-R1-11.** A crashed member-type TU is reported as "its access path cannot be spelled" (cold F3, `results/fail_open_F3_cold.txt`). It fails closed, but for a misleading reason.
- **F-R1-12.** A7 confirms that R1 / bd gqda covers a BY-VALUE library-named template too: `namespace llvm { template <class T> struct RvEvilBox { std::set<llvm::Value *> S; }; }` held by value passes. By value, a NON-template `llvm::` record should be refused as closed world. That is argued from `_named` → `named_q`, not run. A template is not refused (measured). The gqda text speaks of specializations and types generally. Worth one sentence.
- **F-R1-13.** Self-test concurrency is not bounded by ctest `-j`. `selftest(jobs=6)` × `_identify`'s `ThreadPoolExecutor(4)` means up to about 24 compilers at once from one ctest entry. See the cost opinion below.

## Composition (the other tracks of this session that touch TaintSet)

`probes/composition.py` runs the subject guard on each track's own headers and self-test:

- **z0re** (`agent-a284a60d…` @ `369c61b9`, adds `SmallVector<WeakTrackingVH, 2> RuntimeSeedSourceThetas`): clean.
- **cepm / 3zr4** (`agent-a3c46257…` @ `3a2d690e`, adds `ScrubMap<const llvm::CallInst *, unsigned> SpecPredictedClassical`): **REFUSED** — "self-cleaning member `cq::TaintSet::SpecPredictedClassical` is not exercised by ir-pass/tools/scrub_selftest.cpp". That track's `scrub_selftest.cpp` does not mention the member.

This rule predates this change (the oracle guard carries it). The merge gate will go red on `taintset-scrub-guard` when cepm lands, unless that track adds the member to `scrub_selftest.cpp`. I appended this to bd cepm.

## What I attacked and did NOT break

These are refused, each for the right reason (`results/guard_fool_r1*.txt`):
- C1, an unnamed struct defined INSIDE TaintSet;
- C2, `const Value **`;
- C3, a static raw `std::set`;
- C4, an explicit specialization in the header behind a pointer;
- C5, `RvStore` as a field;
- K1, a KEY record whose BASE holds a WeakVH;
- K2, a KEY `std::tuple<WeakVH,int>`;
- K3, a KEY `std::variant<int,WeakVH>` in a `std::map`.

The last three are the implementer's §8.8 "measure both", now measured.

Fail-closed cases:
- F2: a compiler SIGKILLed on the final TU.
- F4: a compiler exiting 0 silently on the final TU. Both refused: the approved handles lose their `vhbase` proof.
- F3 (cold): SIGKILLed on member-type TUs. Refused.
- F5: silent on identity TUs. Refused ("no complete `cq::TaintSet`").

Argued from the source and not run:
- `std::function` / lambda / function-pointer members refuse as `fn`;
- `_Atomic(T *)` refuses as `fn`;
- a whole-dump JSON truncation discards every document (`_json_docs` raises, so `docs=[]`);
- a project type in `namespace cq::std` / `cq::llvm` is walked (`_library` is prefix-exact);
- a field re-spelled through a shadowed anonymous namespace is caught by the field `is_same`. Only bases escape (F-R1-6).

**L10 on my own instrument.** The first `fail_open.py` scored F3 "CLEAN", and it was vacuous. The guard's module-global SPECULATION cache (`_SPEC`) let the root identity TU answer every member question from the previous checks in the same process, so the compiler that dies on member-type TUs was never invoked. That run is kept as `results/fail_open_v1_speculation_fooled.txt`. The probe now clears `_SPEC` per case, and F3 re-ran cold: refused, 47 problems. Anyone writing crash-injection harnesses against this guard must do the same.

## Standing-lesson questions (tooling change: most are N/A)

- **L1 / L2 / L3 / L4:** N/A. There is no lowering change, and the binaries are the oracle's (sha measured).
- **L5 (a semantic question answered syntactically):** the `parse_type` round trip is where it still lives. See F-R1-1 (the `anon` return), F-R1-2 (cv after `*`), and F-R1-6 (`_spell`).
- **L7:** F-R1-4 (the "so the preprocessing context is the build's" clause), F-R1-6 (the `_spell` comment), and F-R1-9 (the ALLOWLIST reason and the header / CMake comments).
- **Rule 12 / L10:** every finding here comes with a MISSED probe that is a ready self-test mutant (A1, A1b, A2, A2b, A3, A4, A4b, A5, A9, A10, and F1 as a database mutant), plus a null or positive control beside it.

## Opinion on the self-test cost (the implementer's open question)

**Keep it in the gate; do not reduce the corpus; split it and bound its concurrency.**

- Every mutant is a false PASS that shipped once, and the self-test is the instrument's only evidence (L10). This review adds 11 more, so the cost question gets worse and should be settled now.
- Most of the cost is structural. There are 122 checks at about 13 CPU-s each; a refused mutant stops at its first refusing pass, so the "re-ask without PCH" costs only the 13 controls about 4×.
- The 853 s wall under load is inflated by F-R1-13. One ctest entry runs about 24 compilers regardless of `-j`, which also starves the other entries.

Recommendations:
1. Take `jobs` from `CTEST_PARALLEL_LEVEL` or an env var, or put a global compile semaphore around `_run`.
2. Shard the mutant list by a stable hash into 2–3 ctest entries, so that `-j6` overlaps them with `e2e-loop-twin-matrix`.
3. If the owner wants to run it only when `tools/taintset_scrub_guard.py`, `ir-pass/include/*.h` or the toolchain changes, that is a path trigger at the gate. Rule 19 allows no judgement calls there, so it needs an owner ruling, not an agent's.

## Beads

Filed in this review (each `discovered-from` wop9 or 7gri):

| bead | priority | covers |
|---|---|---|
| `test_C_libtooling-hdxo` | 1 | F-R1-1 (INTRODUCED regression) |
| `test_C_libtooling-ehni` | 2 | F-R1-2 |
| `test_C_libtooling-ofvm` | 2 | F-R1-5 |
| `test_C_libtooling-ngfa` | 2 | F-R1-3 + F-R1-4 |
| `test_C_libtooling-5ci2` | 2 | F-R1-6 (INTRODUCED regression) |
| `test_C_libtooling-s6ma` | 3 | F-R1-7…13 hygiene |

A note was appended (append-notes) to bd `test_C_libtooling-cepm` for the composition red.
