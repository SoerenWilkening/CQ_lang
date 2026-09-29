# TRACK_SCRUBGUARD — bd wop9 (P2) · 7gri (P3) · jk56 (P3): `tools/taintset_scrub_guard.py`

Implementer record, session 2026-09-28 (parallel). Branch `worktree-agent-a196dcc5b08be6dc0`
off `main` `9a230646`. **Tooling only — no lowering change.** The two C++ edits are comment
lines (`TaintPropagation.h`, `scrub_selftest.cpp`), and the rebuilt binaries are
**bit-identical to the frozen oracle** (§6). Not self-cleared: an independent reviewer owes
the adversarial round (the ATTACK-FIRST list is §8).

Subject of all three beads: Rule-13 round r3 of bd 8e5r
(`../session-2026-09-25-parallel-9bhg-xdu2-16/review_r3_8e5r/REVIEW.md`, F-R3-1/2/3). Its probes
`guard_fool_r3.py` / `guard_fool_r3b.py` import the guard UNMODIFIED and call `check()`; they
are this record's red tests (§4), re-run from their committed location by
`scrubguard_probes/run_r3_probes.sh`.

Guard shas used below: `d26862662f12f1f5` = `main` `9a230646` (before) · `1f74fca8d9ce7b0e` =
the fix before the last edit · **`99a7df7cf90bb6a2` = the committed guard** (the last edit made
the spelling/base assertions access-free and renamed one mutant label; §2 item 4).

## 1. Mechanism of each finding (re-measured, not copied)

| r3 id | spelling | why the r3 guard passed it (read in its source, reproduced by the probe) |
|---|---|---|
| wop9 (a) C1-C3, C6 | `std::set<llvm::Value *> *`, `DenseMap<Value*,unsigned> *`, `SmallPtrSet<Instruction*,4> *`, `SmallVector<DenseSet<Value*>*>` | `Walk._t` walked a pointee template's arguments only for a `cq::` template; a library pointee was only asked "is it Value-derived?" |
| wop9 (b) B1, B2, B2b | explicit / partial specialization, one selected only under `NDEBUG` | `_dump` kept `CXXRecordDecl`/`ClassTemplateDecl`: the PATTERN was walked, never the specialization the build selects |
| wop9 (c) B8, `Result`, `Impl` | `using R3Rec = RawRec; R3Rec *P;` | the JSON does not desugar a pointee; the alias was resolved to a NAME and `_dump` filtered by SHORT name, walking LLVM's `Result`/`Impl` or a decoy |
| wop9 (d) C4, C5 | pointer to a record in the global namespace / another namespace | only `cq::` pointees were queued for a walk |
| 7gri (a) B3 | `#ifndef CQPass_EXPORTS` raw member | `_base_command()` read ONE of the two compile commands (CQPass) |
| 7gri (b) B4 | `#ifndef LLVM_ANALYSIS_LOOPINFO_H` raw member | the PCH (which holds `LoopInfo.h`) changed preprocessing; only a FAILED compile was retried without it |
| jk56 B7 | `struct R3Key { WeakVH H; ... }; std::set<R3Key>` | `_has_handle` was syntactic over the key's type text; it never entered a record |
| jk56 B14 | `SmallPtrSet<Value*>` added to `LoopBreakRegion` | an ALLOWLISTED member was `continue`d: its whole type subtree was never walked |

## 2. The fix: ask the compiler instead of reading a spelling

The walk core is rewritten. The module API the reviewers' harnesses use is kept (`HEADER`,
`SELFTEST`, `SCRUB_HDR`, `INCLUDE_DIR`, `EXTRA_INCLUDES`, `ALLOWLIST`, `USE_PCH`, `_PCH`,
`check(header, selftest, allowlist, scrub)`); `check` gained an optional `extra_headers`.

1. **Every build configuration (7gri a).** `_configs()` groups the `compile_commands.json`
   commands of every C++ TU under THIS tree that reaches `TaintPropagation.h` through quote
   includes. Measured: two groups — `CQPass` (`-DCQPass_EXPORTS … -fPIC`) and
   `cq-opt/cq-scrub-selftest` (neither flag). A problem in any configuration refuses. A
   database whose entries belong to another tree, garbage JSON, a JSON object instead of a
   list, or a nonexistent compiler now exit through the guard's own diagnostic (r3 saw
   Python tracebacks for the last two).
2. **The canonical type of every member.** For each data member, the compiler is asked for
   `decltype(std::declval<Scope &>().member)` inside an EXPLICIT INSTANTIATION's template
   argument, where access checking does not apply. Measured: private and static members both
   work. The answer comes out through a friend of the instantiation, and the dump prints it
   CANONICAL (`cq_guard_canon::box<cq::R3RawRec2 *>`): aliases, alias templates and pointee
   sugar are resolved and every name is qualified. Members of an anonymous union or struct
   are asked through the parent, and members of an unnamed struct through its field
   (`.Anon.P`, `.Arr[0].P`). **This closes wop9 (c) at the root: no short name is looked up
   anywhere.**
3. **The compiler's own identity for every project type (wop9 b, c, d).** A PROJECT type is
   any record or class-template instance whose canonical name is not under `llvm::` or
   `std::`. That includes the global namespace and `cqx::` (wop9 d). The type is resolved by
   an alias in a probe TU: the alias's `RecordType` names the definition's AST id, and THAT
   node is walked. It is either the explicit or partial specialization the build selects, or
   the implicit instantiation with its arguments substituted (forced through a SFINAE
   `sizeof` when the type is only pointed at). The dump filter only has to make that node
   appear; nothing is chosen by name. A fallback filter covers an inline namespace that the
   canonical print elides (measured on a decoy).
4. **The spelling is verified.** Measured: clang prints an explicit specialization's arguments
   AS WRITTEN, in its own scope (`cq::R4S<R4Alias *>`), so a canonical print can re-spell as a
   DIFFERENT type at global scope. Every member's canonical text is therefore re-spelled
   (qualified names rooted at `::`) and `std::is_same` against the member's real type is
   asserted; a base is checked with `std::is_base_of`. Both checks run inside an explicit
   instantiation's template argument (`chk<req<cond>::type, K>`). A false check is an error
   ON THAT LINE, and a PRIVATE nested type is not an access error. The first spelling was a
   `static_assert`, which rejected a clean private nested record; measured at compiler level
   in `scratchpad t7.cpp`, "'Hidden' is a private member". The null control
   "CLEAN PRIVATE nested record" now pins this.
5. **Library templates are walked behind pointers (wop9 a).** A pointer to an `llvm::`/`std::`
   template is walked exactly like the template by value.
6. **KEY mode (jk56 B7).** The first argument of an `ASSOCIATIVE` container is walked in a
   mode that refuses a handle ANYWHERE in it: inside template arguments, inside project records
   the key holds, and (conservatively, R6) behind pointers.
7. **RELAXED mode (jk56 B14).** An allowlisted member is still walked. Raw pointer, `Loop *`,
   `void *` and unapproved-handle FIELDS and sequence elements are tolerated and printed as
   notes; every KEY is strict and every closed-world rule applies. The walk of a record is
   keyed by mode, so `LoopBreakRegion` reached through a non-allowlisted member is still
   refused. The real tree prints 15 tolerated notes: 14 `LoopBreakRegion` fields and
   `RestoringRoutes`.
8. **No PCH in the gate's own run (7gri b).** `main()` asks every configuration without a PCH
   (in parallel). `check()` under `USE_PCH` (the self-test and the reviewer harnesses)
   compiles with a per-configuration PCH and RE-ASKS EVERY CLEAN VERDICT without it. A refusal
   under the PCH is reported as is, because it can only over-refuse.
9. **Two hazards of the new design, found by attacking it before landing.** First, a macro
   defined after the record (`#define Evil Tainted`) would redirect a member question, so
   every identifier a generated line uses is `#undef`ined after the header (source mutant S2
   kills that protection). Second, AST ids are per-process addresses, so the walked-set key
   includes the identity whose compile printed the node (S3; see §5 for why it needs a
   forced-collision harness).
10. **Speed only.** The identity TU of a record also asks, speculatively, the members that
    record had in earlier passes. An answer is used only for a member this pass's own AST
    lists, and a wrong guess is an ignored error. Measured: a warm pass takes 3 compiles
    instead of 5.

Removed: the pattern walk of member class templates that no field instantiates (they hold no
storage; R5), the scope-candidate resolver `_resolve` (no unqualified name reaches the walk
any more), and `_has_handle` (replaced by KEY mode).

**Which bead each part answers.** wop9 = items 2, 3, 4, 5. 7gri = items 1, 8. jk56 = items 6, 7.

## 3. Residuals: what this version does NOT close (also in the docstring, R1-R9)

- **R1** Library, `scrub::`, HANDLES and LEAVES are trusted by NAME. A project header that
  declares a type or a specialization inside `namespace llvm`/`std` is not walked; the tree
  does open `namespace llvm`.
- **R2** RELAXED mode tolerates raw pointer SEQUENCES in allowlisted members.
- **R3** Configurations are found by a textual quote-include closure, and only configured
  builds are seen.
- **R4** Members whose access path cannot be spelled refuse any non-builtin (an
  over-refusal).
- **R5** Uninstantiated member templates are not walked.
- **R6** A handle behind a pointer in a key is refused (an over-refusal).
- **R7** Associative containers are known by name.
- **R8** Bases are verified by `is_base_of` only.
- **R9** A private nested type reached through the identity alias is refused (an
  over-refusal).

**Filed:** bd `test_C_libtooling-gqda` (P3, discovered-from wop9) covers R1 and R7, so that
"documented" is not read as "done". It is PRE-EXISTING by construction: the old guard trusted
`llvm::`/`std::` by name even more broadly. That is argued, not measured on the oracle guard.

## 4. Red → green (the r3 probes, unmodified, from their committed location)

| probe | before (`d2686266`) | after (`1f74fca8`) | after (`99a7df7c`, committed) |
|---|---|---|---|
| `guard_fool_r3` with PCH | controls bad 0, **attacks 8, MISSED 8** | controls bad 0, **MISSED 0** (1584 s) | controls bad 0, **MISSED 0** (348 s) |
| `guard_fool_r3 --no-pch` | controls bad 0, **MISSED 7** (B4 caught) | controls bad 0, **MISSED 0** (1729 s) | controls bad 0, **MISSED 0** (610 s) |
| `guard_fool_r3b` | controls bad 0, **attacks 6, MISSED 6** | controls bad 0, **MISSED 0** (485 s) | controls bad 0, **MISSED 0** (304 s) |

Results are in `scrubguard_probes/results/{before,after,final}_r3{.pch,.nopch,b}.txt`. Every
CAUGHT in the `after` files was caught for the RIGHT reason (§4.1). No probe was caught by a
compile error.

### 4.1 Right-reason check (`after_r3.pch.txt`, `after_r3b.txt`)

| probe | refused as |
|---|---|
| B1 | `cq::R3Spec<unsigned int>::P: RAW POINTER` (the explicit specialization's own field) |
| B2 | `cq::R3PS<int *>::P: RAW POINTER` |
| B2b | `cq::R3N<true>::Raw: RAW POINTER` |
| B3 | `[cq-opt/cq-scrub-selftest] …R3NotPlugin: RAW POINTER` (the second configuration) |
| B4 | `[CQPass, no PCH] …R3PchCtx: RAW POINTER` (the re-ask without the PCH) |
| B7 | `cq::R3Key::H: a value HANDLE (llvm::WeakVH) in the KEY of std::set held by cq::TaintSet::R3KS` |
| B8 | `cq::R3RawRec2::P: RAW POINTER` (the alias's real target, not the decoy) |
| B14 | `cq::LoopBreakRegion::R3IdentityTable: RAW POINTER … [inside the KEY of llvm::SmallPtrSet …]` |
| C1-C3, C6 | `RAW POINTER` at the member itself |
| C4 | `R3G::P` |
| C5 | `cqx::R3X::P` |

The r3 positive controls kept their reasons, with one text change. "project template base
instantiated with a Value type" now ALSO reports the instantiation's own field
(`cq::R3TB<llvm::Instruction>::P`), because the instance is now walked in addition to its
argument.

### 4.2 The guard's own self-test (`--selftest`, ctest `taintset-scrub-guard-selftest`)

It now carries the r1A/r1B/r2 corpora (unchanged) plus all of r3 (B1, B2, B2b, B3, B4, B7, B8
with `Result`/`Impl`, B14, C1-C6, C4b) and this fix's own attacks. The own attacks are:

- a mirrored B3′;
- B7′ (a key record inside a `std::pair` in a `std::map`);
- B14′ (a handle-keyed set) and B14″ (a `Loop *`-keyed map) in `LoopBreakRegion`;
- a non-`cq` project template by value;
- an alias template behind a pointer;
- an inline-namespace decoy;
- a private nested record and a private member;
- a reference member;
- an anonymous-union member;
- the AS-WRITTEN spelling decoy;
- a macro defined after TaintSet;
- many template instances in one round;
- a member variable template;
- a pointer-to-member;
- a forward-declared pointee;
- a handle behind a pointer in a key.

Null controls added:

- a bit-field;
- a clean explicit specialization whose primary is raw;
- a clean global record by pointer;
- a clean enum plus a private member;
- a clean private nested record;
- (by design, R2) a raw pointer FIELD added to `LoopBreakRegion`.

Totals: **13 null/equivalence controls + 109 mutants** (was 7 + 74), each mutant required to
be refused FOR THE RIGHT REASON.

| guard | run | result |
|---|---|---|
| `0c3bbd5a` | `--selftest` | 12 controls + 108 mutants, **0 failed**; 1317 s wall at load 197→153 (`results/after_selftest.txt`) |
| `1f74fca8` | ctest `taintset-scrub-guard-selftest` | **Passed**, 1176 s (`results/ctest_scrub.txt`) |
| `99a7df7c` | ctest `taintset-scrub-guard-selftest` | **Passed**, 626.87 s (`results/final_ctest_scrub.txt`); the counts line is in §7.1's run |

`0c3bbd5a` differs from `1f74fca8` only in printing verdicts as they complete.

### 4.3 Final battery on the committed guard `99a7df7cf90bb6a2`

`scrubguard_probes/final_battery.sh` runs sequentially and aborts if the guard changes under
it. Its outputs are `results/final_*`.

| step | result |
|---|---|
| 1. `ctest --test-dir build -R scrub -j4` | **8/8 passed** in 626.97 s, including `taintset-scrub-guard` (60.68 s) and `taintset-scrub-guard-selftest` (626.87 s). Started at load 145 (`final_ctest_scrub.txt`). The self-test exits non-zero on any failed mutant or control, so a pass means 0 failed of 13 + 109. |
| 2. `guard_fool_r3` with PCH | controls bad **0**, attacks 8, **MISSED 0** (348 s). Reasons identical to §4.1 (`final_r3.pch.txt`). |
| 2. `guard_fool_r3 --no-pch` | controls bad **0**, attacks 8, **MISSED 0** (610 s). |
| 2. `guard_fool_r3b` | controls bad **0**, attacks 6, **MISSED 0** (304 s). |
| 3. `fail_closed.py` | **6 cases, 0 bad**: a missing DB, another tree's DB, garbage JSON, a JSON object, a nonexistent compiler and an unknown argument all exit non-zero through the guard's own diagnostic, with no traceback. |
| 4. `source_mutants.py S0 S1` | S0 null: **0 of 15 moved** (646 s). S1 (spelling check dropped): **KILLED** 1/1 (355 s). |
| 4. `id_collision.py` | guard: null clean, forced-collision mutant **refused** (`cq::R4D<4>::P`). S3: null clean, the same mutant **accepted (0 problems)**. |

Load during the battery was 52 → 374. None of the numbers above depends on load.

## 5. Mutation validation of the NEW mechanisms (`scrubguard_probes/source_mutants.py`)

Each source mutant disables one mechanism with a textual edit of the guard's own source (the
anchor is asserted to occur exactly once). The mutated source is loaded with the real
`__file__` and run against the self-test mutants that the mechanism owns, plus the pristine
null. S0 is the no-op null mutant (a comment edit) and runs FIRST over the union of every
target.

| id | mechanism disabled | result (`1f74fca8`, `results/source_mutants.txt`) |
|---|---|---|
| S0 | null (comment) | **0 of 15 checks moved** |
| S1 | spelling check | KILLED (the AS-WRITTEN decoy passes without it) |
| S2 | `#undef` of generated identifiers | KILLED (macro-after-TaintSet) |
| S3 | walked-key includes the identity | **MISSED** on natural input (see below) |
| S4 | KEY mode enters project records | KILLED 2/2 (B7, B7′) |
| S5 | RELAXED instead of exempt | KILLED 3/3 (B14, B14′, B14″) |
| S6 | every configuration | KILLED (B3) |
| S7 | re-ask without the PCH | KILLED (B4) |
| S8 | library template behind a pointer walked | KILLED 4/4 (C1, C2, C3, C6) |

Total: 3755 s under load.

**S3 is honest-MISSED.** AST ids are ASLR-randomized heap addresses, so two identity
compiles printing the same id for different records cannot be produced from C++ input. The
self-test mutant written for it ("many template instances") does not kill S3, and its label
was changed so that it no longer claims to. The protection is instead pinned by
`scrubguard_probes/id_collision.py`, which FORCES a collision by rewriting every identified
node's id to one constant. With the collision forced, the guard still refuses (1 problem:
`cq::R4D<4>::P`) and S3 accepts (0 problems). The null stays clean under both
(`results/id_collision.txt`).

S0 and S1 were re-run on the committed guard, because the spelling-check mechanism changed
in the last edit; see §4.3. S2 and S4-S8 target code that is unchanged since `1f74fca8`.

## 6. The binaries are unchanged; what that makes vacuous

After the final rebuild (`cmake --build build -j4`), the three binaries hash exactly as the
frozen oracle's:

| binary | sha-256 prefix |
|---|---|
| `build/ir-pass/cq-opt` | `3f6db37f5cf937b4d70f5736` |
| `libCQPass.so` | `356df92e0b58bbf787c41a25` |
| `cq-opt-debugalloc` | `36033dbf6641b168d7917bc4` |

`cq-scrub-selftest` is `686ff81202149ff4600dd047`; there is no oracle copy of it. The corpus
A/B against the oracle and the allocator sweeps (`lifo`/`nofree`) were therefore **not run**:
the subject binary IS the oracle binary, so both are vacuous by construction. That is stated
here as a skip with a reason, not as a result.

`lit ir-pass/test` (on `1f74fca8`, same binaries): **2407 discovered, 2406 passed, 1 XFAIL,
0 failed** (709.6 s, `-j4`, under load). The lit layer cannot see the guard; it was run for
the brief.

## 7. Cost (brief: "report the guard's wall time before/after")

Timings alternate old and new so that each pair sees the same load
(`scrubguard_probes/timing_ab.sh`). `real`, `user` and `sys` come from `/usr/bin/time -p`.

| run | old `d2686266` | new | load |
|---|---|---|---|
| gate main run, round 1 (quiet box) | 8.98 s real / 8.1 s cpu | 22.82 s real / 29.1 s cpu | 3.2 → 2.5 |
| gate main run, round 2 | 23.84 s / 10.9 s cpu | 37.55 s / 33.4 s cpu | rising (agents resumed) |
| gate main run, loaded ×2 | 43.8 / 32.9 s real (≈16 / 15 s cpu) | 54.4 / 51.6 s real (≈45 / 43 s cpu) | 75-85 (files overwritten by the quiet-box rerun; transcribed when measured) |
| `--selftest` (alternating pair, `99a7df7c`) | 286.29 s real / 355.7 s cpu (7 + 74, 0 failed) | 853.20 s real / 1659.2 s cpu (13 + 109, 0 failed) | 376 → 419 → 134 |

The main runs were measured on `1f74fca8`; the last edit touches only the final TU's check
lines.

**Why the main run costs about 3×.** It asks TWO configurations where the old guard asked one,
each WITHOUT a PCH (the old run used one). Each pass is 5 compiles (identity of TaintSet,
member types, identity of `LoopBreakRegion`, its member types, final checks) where the old
guard needed about 3. Measured per compile: ≈2.5 s cpu with the PCH and ≈4.3 s without.
**Why the self-test costs more.** A clean verdict now costs 4 passes: 2 configurations × (PCH,
then the re-ask without it). There are 35 more mutants. A refused mutant stops at its first
refusing pass.

### 7.1 What the cost means for the merge gate

The measured ratios are about 2.5× wall and 3.6× cpu for the gate's main run on a quiet box,
and about 3× wall and 4.7× cpu for the self-test under heavy load. On the loaded box the
ctest entry `taintset-scrub-guard-selftest` took 626.87 s (final battery). By the CLAUDE.md
timing section, that makes it a likely LONG POLE of a full `ctest -j6`, next to
`e2e-loop-twin-matrix` (180-400 s).

Options for the orchestrator or the owner, **not taken here**:
- keep the self-test in the gate as is;
- run it with fewer jobs;
- split it into two ctest entries (the r1/r2 corpus and the r3/own corpus) so that `-j6` can
  overlap them.

The self-test's `jobs=6` is unchanged from the old guard. Each check's identity dumps fan out
to 4 threads, as before.

## 8. ATTACK FIRST — for the reviewer who will try to fool it again (L10)

An instrument's failure mode is to report a pass. These are the places I would attack first,
most promising first:

1. **R1, the namespace spoof.** Declare `namespace llvm { struct Evil { Value *P; }; }` in a
   project header and hold `llvm::Evil *`. Or explicitly specialize a library template for a
   project type (`template <> class llvm::SmallVector<cq::X, 2> { Value *P; };`). Both are
   judged as library and not walked. This is a known pass.
2. **R7, an unlisted keyed container.** `llvm::EquivalenceClasses<WeakVH>`, `FoldingSet`,
   `llvm::IntervalMap`, `std::priority_queue<WeakVH>` (ordered by the handle): KEY mode never
   starts. A raw `Value *` element in them is still refused in strict mode.
3. **R2, the allowlisted sequence.** `SmallVector<Value *>` added to `LoopBreakRegion` is a
   note, not a problem, by design; argue whether `is_contained` makes it an identity table.
4. **Canonical-text round trip.** Find a type whose canonical print re-spells to the SAME type
   while hiding a pointer: function types in template arguments, `__attribute__((vector_size))`,
   `_Atomic`, `decltype` of a lambda, a dependent type left in a partial specialization body.
   Anything `parse_type` mis-parses into `lit` or `named` without refusing is a pass.
   Specifically, `parse_type` treats a leading `&`, `nullptr` or a digit as a NON-TYPE
   argument (`lit`).
5. **Speculation.** Speculation is supposed to be speed only. Try to make a speculative line
   answer DIFFERENTLY from the pass's own question for the same `(prefix, member)`: a context
   difference between the identity TU and the member TU, or `#undef` sets that differ between
   them (they are computed per TU from that TU's own text).
6. **The `#undef` list.** It covers only identifiers that appear in generated lines. A
   function-like macro, or a macro that expands to `private:`, defined after the record and
   named like a helper this file uses (`get`, `box`, `chk`, `req`, `declval`, …) is undefined
   too. Look for one that is not.
7. **Configuration discovery (R3).** A TU in another target that includes the header through
   `#include MACRO`, `-include`, or a header outside `ir-pass/include`, and whose flags differ,
   is not recognised as a configuration.
8. **KEY mode through a base.** A key record whose BASE holds the handle is walked through
   `_walk_record`'s bases in key mode, so it should be refused. So should a key that is a
   `std::tuple<…>` / `std::variant<…>` holding a handle. Measure both.
9. **Enum / union / anonymous edges.** A union KEY, an enum with an underlying type from a
   project alias, a named record nested inside an unnamed struct (R4, over-refusal), a bit-field
   of enum type.
10. **Fail-closed paths.** A compiler that crashes (signal) during the identity dump, a JSON
    dump truncated by a crash (`_json_docs` → `ValueError` → the root reports "does not
    compile"), and a `compile_commands.json` whose entry has `arguments` instead of `command`.

## 9. What I did NOT run

- **The full `ctest -j6`.** Rule 19: it belongs to the orchestrator at the merge gate. This
  change touches `CMakeLists.txt` (comments only), so the gate is mandatory under Rule 19 item 3.
- **Corpus A/B, e2e A/B and the allocator sweeps**, because the binaries are the oracle's (§6).
- **A Debug-configured tree.** With `NDEBUG` absent, the members under `#ifndef NDEBUG` are
  still unseen. That is R3's "only configured builds".
- **Non-Apple toolchains**, and a `compile_commands.json` with the `arguments` form. The latter
  is handled by the code but not exercised.
- **S2 and S4-S8 on the committed sha** (they ran on `1f74fca8`; their code is unchanged since).
- **`presence.py`.** It measures the BUILD's view of r3's members, which this change does not
  touch.

## 10. Proposed CLAUDE.md text (not applied — the brief forbids editing CLAUDE.md)

For the Rule-19 row "`taintset-scrub-guard` when a `TaintSet` member changes" (no change
needed), and for the Build & Test *Timing* paragraph, one sentence:

> Since bd wop9/7gri/jk56 (2026-09-28) `taintset-scrub-guard-selftest` asks two build
> configurations with and without a PCH per clean verdict: ~850 s real at load ~400, ~627 s in a
> loaded `ctest -R scrub` — a candidate long pole next to `e2e-loop-twin-matrix`; the gate's own
> run is ~23 s on a quiet box.

---

# ROUND 2 — the review r1 findings (bd hdxo P1 · ehni · ofvm · ngfa · 5ci2 P2 · s6ma P3)

The first review of the rewrite is `review_r1_scrubguard/REVIEW.md` (verdict **NOT-CLEAR**). Its
directory is committed untouched with this round. It found 13 headers the build compiles in both
configurations, each with a raw identity table reachable from `cq::TaintSet`, that passed the
committed guard `99a7df7c`. Three of them (A1, A4, A4b) are regressions against the old guard.

## R2.1 What changed, finding by finding

| finding | bead | fix |
|---|---|---|
| F-R1-1 unnamed type defined OUTSIDE the walked record (A1, A1b) | hdxo | An unnamed record is identified by the compiler's `(unnamed struct at FILE:LINE:COL)`. A field of unnamed type is accepted only when THAT record was walked through a declarator of the record being walked. Anything else is refused as "defined outside the record". A pointer to an unnamed type follows the same rule. |
| F-R1-2 `*const` / `*volatile` / `*__restrict` misparsed (A2, A2b) | ehni | `parse_type` strips cv/restrict right after `*`/`&` as well. Defence in depth: a pointee the compiler says is neither a class, a union nor an enum now REFUSES instead of accepting (source mutant N2 shows this second layer catching A2/A2b by itself). |
| F-R1-3 template pimpl (A3) | ngfa | Identity lookup no longer forces instantiation. A class-template specialization the header never instantiates, reached by pointer or by `unique_ptr`, is REFUSED ("only POINTED AT"), the same contract as the non-template pimpl. The primary's forced instantiation is walked as well. Contract in docstring (3) + R11. |
| F-R1-4 include-order dependent member (A5) | ngfa | A new check (docstring (6)). For every clean verdict, in the no-PCH pass of each configuration, the header's include closure is `-E`'d twice and must be textually identical: once alone, and once after every header any TU of that configuration includes plus every project header (closure guards pre-defined, then undefined). What it cannot see is R10: a `.cpp`'s own `#define`s, macro COMBINATIONS, and TU-local headers. The false clause "so the preprocessing context is the build's" is struck. |
| F-R1-5 `scrub::Set<StorageT, P>` storage never walked (A9) | ofvm | Every scrub container must have the shape ScrubOnDelete.h ships: `Set<std::set<P> \| SmallPtrSet<P, N>, P>`, `List<P, N>`, `PairSet<P1, P2>`, `Map<P, V>` (with V walked). Any other shape is refused. |
| F-R1-6 base re-spelled through an anonymous namespace / a local class (A4, A4b) | 5ci2 | A base must satisfy `is_base_of<S, D>` AND `is_same<typename D::<short>, S>`: the base's injected-class-name, looked up through the derived class, must be the spelled record. The lookup is ambiguous for A4 and names the local class for A4b/A4b′, so both fail. The `_spell` comment is corrected (L7). |
| F-R1-7 malformed DB entry drops a configuration (F1) | s6ma | `_configs_from` raises on any entry of this tree that cannot be parsed, and on any entry without `file`. |
| F-R1-8 `llvm::SmallPtrSetImplBase *` (A10) | s6ma | A pointer to a LIBRARY non-template record is now CLOSED WORLD: refused unless listed in `APPROVED_POINTEES` (empty; the tree holds none). `TYPE_ERASED_TEMPLATES` (`llvm::SmallVectorBase`) is refused by value and behind a pointer. |
| F-R1-9 identity tables inside the allowlisted `LoopBreakRegion` (A6, A6b) | — | `ALLOWLIST_POLICY`. Under "fields" (the default; BreakRegions), a raw pointer is tolerated only as a record's OWN field. Inside ANY library container the argument walk is strict, so `SmallVector<Value *>` (the old R2) is refused too. Under "any" (RestoringRoutes, whose reason is "no writer"), raw pointers are tolerated anywhere except in a KEY. EquivalenceClasses / UniqueVector / priority_queue joined ASSOCIATIVE. The ALLOWLIST reason and the `TaintPropagation.h` / CMake comments now say what is checked (L7). |
| F-R1-10 builtin-pointer / byte-storage type erasure (A8) | s6ma | Listed under OUT OF SCOPE; A8 is pinned in the self-test as a known pass. |
| F-R1-11 crash misreported | s6ma | A compiler killed by a signal is a GuardError. A member-type probe with no answer and no error is a GuardError. The final probe carries a CANARY `static_assert` whose absence is a GuardError. |
| F-R1-12 by-value library-named template (A7) | gqda | Note appended to bd gqda. Pinned in the self-test as "RESIDUAL R1 pinned". |
| F-R1-13 unbounded concurrency | s6ma | A global compile semaphore (`--jobs N` / `CQ_GUARD_JOBS`). The self-test is SHARDED (`--shard K/3`) into three ctest entries, each `--jobs 2`; the gate run uses `--jobs 2`. |

## R2.2 Measurements (the fields marked FINAL come from the committed guard; see R2.4)

Guard shas:
- `99a7df7c` is round 1's committed guard, the one the reviewer measured.
- `bbf1a106` is the round-2 commit `6453baa7`. Every "FINAL" row below was measured on it.
- `e4ab4f28` is commit `30e7a590`. It changes ONLY the self-test's shard assignment and its
  docstring (`_shard_of` → `_shards`; the diff is quoted in that commit), and `check()` is
  byte-identical. Only the cost rows were re-measured on it.

The binaries are unchanged. After the rebuild, `cq-opt` is `3f6db37f5cf937b4d70f5736`,
`libCQPass.so` is `356df92e0b58bbf787c41a25` and `cq-opt-debugalloc` is `36033dbf6641b168d7917bc4`,
the same as the frozen oracle. The two C++ edits are comment lines. So lit, corpus A/B and the
allocator sweeps were NOT re-run: they would be vacuous (§6).

### Review r1's probes (`guard_fool_r1.py`, imported unmodified, gate semantics USE_PCH=False)

| probe | before (`99a7df7c`, the reviewer's run) | after, FINAL (`bbf1a106`) |
|---|---|---|
| controls N0, C1-C5, K1-K3 | 0 bad | **0 bad** |
| A1, A1b (unnamed type elsewhere) | MISSED | CAUGHT: "defined outside the record" |
| A2, A2b (`*const`, `*volatile`) | MISSED | CAUGHT: RAW POINTER |
| A3 (template pimpl) | MISSED | CAUGHT: "only POINTED AT" |
| A4, A4b (anon-ns / local base) | MISSED | CAUGHT: "base's canonical spelling … does not name this record's base" |
| A5 (include order) | MISSED | CAUGHT: "preprocesses DIFFERENTLY" |
| A6, A6b (allowlisted identity tables) | MISSED (a note) | CAUGHT: RAW POINTER |
| A9 (scrub::Set storage) | MISSED | CAUGHT: "not an approved backing" |
| A10 (`SmallPtrSetImplBase *`) | MISSED | CAUGHT: "APPROVED_POINTEES" |
| A7 (R1 by-value library-named template) | MISSED | MISSED, **by contract** (R1, bd gqda; pinned in the self-test) |
| A8 (`std::set<const char *>`) | MISSED | MISSED, **by contract** (OUT OF SCOPE; pinned) |

Totals: **14 attacks, 12 CAUGHT, 2 MISSED**, and both misses are documented known passes
(`results_r2/final_guard_fool_r1.txt`, 613 s).

### The r3 corpora (FINAL, `bbf1a106`, `results/final_r2_r3*.txt`)

| probe | result |
|---|---|
| `guard_fool_r3` with PCH | controls bad 0, attacks 8, **MISSED 0** (415 s) |
| `guard_fool_r3 --no-pch` | controls bad 0, attacks 8, **MISSED 0** (451 s) |
| `guard_fool_r3b` | controls bad 0, attacks 6, **MISSED 0** (108 s) |

### Fail-closed (FINAL)

| probe | result |
|---|---|
| `fail_closed.py` (main, via the CLI) | **6 cases, 0 bad** |
| reviewer's `fail_open.py` | **6 of 6 refused** |

`fail_open.py` rows, each refused with a truthful reason:
- the control (the intact DB with the `#ifndef CQPass_EXPORTS` member): `[cq-opt/cq-scrub-selftest, no PCH] … RAW POINTER`;
- F1 malformed entries: "the entry for … cannot be parsed" (was **CLEAN** in review r1);
- F2 SIGKILL on the final TU: "killed by signal 9";
- F3 SIGKILL on member-type TUs: "killed by signal 9" (was a misleading "access path cannot be spelled");
- F4 silent on the final TU: "did not report its canary";
- F5 silent on identity TUs: "no complete `cq::TaintSet` definition could be identified".

The self-test also carries five database cases, run in shard 1, all correct.

### The guard's self-test

Contents: 153 entries (16 expected-clean, including two pinned known passes, and 137 mutants),
plus 5 DB cases and the PCH equivalence control.

| run | guard | result |
|---|---|---|
| FINAL `ctest -R scrub -j4` | `bbf1a106` | **10/10 passed**: `taintset-scrub-guard` 28.40 s; selftest-1of3 754.32 s, -2of3 395.31 s, -3of3 458.01 s; plus the six other scrub entries (`results_r2/final_ctest_scrub.txt`, load 40 → 103) |
| development run, the three shards concurrently | earlier dev version | 0 failed apart from one entry (`dev1_*`). That entry was A5′: `#ifdef LLVM_ANALYSIS_LOOPINFO_H` was refused by the PCH pass as RAW, for a different reason than expected, because the PCH holds LoopInfo.h. It is now two entries: A5′ uses `LLVM_ANALYSIS_LAZYVALUEINFO_H`, a header only `.cpp` files include, and is caught by the include-order check; A5″ is the LoopInfo case, expected RAW. |

### Source mutants of the round-2 mechanisms (`source_mutants_r2.py`, `results_r2/source_mutants_r2.txt`, on `bbf1a106`)

| id | disables | result |
|---|---|---|
| N0 | null (a comment edit), run FIRST | **0 of 17 checks moved** |
| N1 | the unnamed-type location key | KILLED 2/2 (A1, A1b become clean) |
| N2 | cv/restrict stripping after `*` | KILLED 3/4. A2/A2b are still REFUSED, now by the second layer ("neither a class, a union nor an enum"), which shows the misparse fails closed. A2″ held. |
| N3 | the scrub shape check | KILLED 1/1 |
| N4 | force every instantiation (the round-1 behaviour) | KILLED 2/2 (A3, A3′ become clean) |
| N5 | base check = `is_base_of` only | KILLED 3/4. A4′ held: a single shadowed anonymous-namespace base is not a base under `is_base_of` either. |
| N6 | the include-order check | KILLED 2/2 (A5, A5′) |
| N7 | the fail-closed DB parse | KILLED: DB F1 now yields 1 configuration |
| N8 | strict library-container arguments under "fields" | KILLED 1/1 (A6′) |

Total 1618 s. `APPROVED_POINTEES` (A10) was not given a source mutant, to stay within the ≤8
budget. Its self-test entry pins it.

### Composition (read-only, FINAL `bbf1a106`, `results_r2/final_composition.txt`)

| worktree | HEAD | verdict |
|---|---|---|
| cepm `agent-a3c46257bc3bd028d` | `1f5dbf98` (moved from `7f0be42f`) | **clean**: 77 members, 0 problems |
| z0re `agent-a284a60d747f2ed82` | `5651797e` | **clean**: 76 members, 0 problems |

Both were also clean with the dev guard `bbf1a106` while cepm was still at `7f0be42f` and z0re at
`9a68064f`. cepm's `SpecPredictedClassical` is exercised by its `scrub_selftest.cpp`.

## R2.3 ATTACK FIRST (round 2) — where I would try to fool it next

1. **The include-order check's single union context (R10).** Three ways in, each argued and not
   measured:
   - a `.cpp` that `#define`s a macro before its includes;
   - `#if defined(A) && !defined(B)` where the union context defines both;
   - a TU that includes a header through a relative path the probe directory cannot reach.
   Also `__COUNTER__` / `__INCLUDE_LEVEL__` in the header, which would make the two contexts
   differ spuriously. That is an over-refusal.
2. **The `-E` segment attribution.** The check compares only lines attributed to closure files by
   line markers. Two routes around it:
   - a member produced by a macro whose *expansion text* is identical but whose meaning differs
     (a type alias defined differently before the header);
   - a closure file without a classic guard, which is refused. Try to make `_guard_macro` pass on a
     header whose guard is not really a guard (`#ifndef X` / `#define X` followed by more
     preprocessor logic).
3. **The unnamed-record location key.** Its identity is `basename:line:col`. Try two different
   unnamed records at the same line and column in two DIFFERENT closure headers with the SAME
   basename, which is impossible in one directory. Also try a macro that defines two unnamed
   structs whose spelling locations coincide (`(unnamed struct at <scratch space>`...).
4. **Base identity by injected-class-name.**
   - A derived class that hides the base's injected name with its own member of the SAME type:
     `struct D : Raw { using Raw = Raw; }` is legal only if the alias names the same type.
   - A base reached through `using Base::Base;` inheriting constructors.
   - Dependent bases in a walked partial specialization's body.
5. **The scrub shape check.** `Set<std::set<P, Cmp>, P>` with a custom comparator that dereferences
   P is refused, by design. `Set<llvm::SmallPtrSet<P, N>, P>` where N is an expression. A `List<P, N>`
   whose P is a pointer to a project type holding raw pointers: scrub keys are trusted as pointers
   to Values (`asValue` `static_cast`s them), so they must be Value-derived to compile.
6. **The pimpl rule.**
   - A specialization the header instantiates only inside an unevaluated context (`sizeof` in a
     static_assert): that counts as instantiated, and a `.cpp` cannot specialize it afterwards.
   - A partial specialization declared in a `.cpp` for arguments the header never instantiates
     (refused: "only POINTED AT").
   - A member template or a nested class of an instantiated template, specialized in a `.cpp`
     (R5-adjacent, not measured).
7. **APPROVED_POINTEES / TYPE_ERASED_TEMPLATES.** A library TEMPLATE whose arguments do not say what
   it holds and that is not on the list: `llvm::SmallVectorTemplateCommon<char>`, `std::any`
   (non-template, so refused), `llvm::detail::…`, `std::function<void()>` (refused as fn). R7-class.
8. **R1 / gqda.** A project type or specialization inside `namespace llvm`/`std` is still trusted by
   name (A7 pinned). This is the biggest known pass.
9. **The self-test shards.** Every entry runs in exactly one shard: `_shards` is a function of the
   full, sorted entry list. A reviewer could check that a shard failure cannot hide as "0 mutants
   selected". An empty shard is refused, and duplicate labels are refused.
10. **Concurrency.** `--jobs` bounds compilers per PROCESS. Three shards plus the gate run is at most
    8 compilers from the scrub entries. `ctest -j6` can still co-schedule them with the twin
    matrix.

## R2.4 Cost (the reviewer's recommendation, implemented and measured)

What changed:
- A global compile semaphore: `--jobs N` / `CQ_GUARD_JOBS`.
- The self-test is SHARDED into `taintset-scrub-guard-selftest-{1,2,3}of3`, each run with
  `--jobs 2`; the gate run is `taintset-scrub-guard --jobs 2`. Every ctest entry therefore runs at
  most 2 compilers, whatever `-j` the gate uses.
- `_shards` deals the costly expected-clean entries round-robin: 5+46 / 6+46 / 5+46 entries.

The corpus is kept whole (153 entries). All timings come from `/usr/bin/time -p` (children
included) and run old and new BACK TO BACK. The load was NOT quiet: other agents ran throughout,
so each row carries its load.

| run | old guard `d2686266` (main) | new (`e4ab4f28`; check() = `bbf1a106`) | load |
|---|---|---|---|
| gate run, pair 1 | 31.31 s real / 12.2 s cpu | 63.98 s real / 57.6 s cpu (default --jobs 4) | 8 → 82 → 169 |
| gate run, pair 2 | 8.80 s real / 8.2 s cpu | 26.68 s real / 44.1 s cpu | 169 → 144 → 97 |
| gate run inside `ctest -R taintset-scrub-guard -j4` | — | 54.89 s (--jobs 2) | 94 → 6 |
| self-test | 130.61 s real / 343.6 s cpu (one process, unbounded, 7 + 74 checks) | `ctest -R taintset-scrub-guard -j4`: **389.22 s real** / 1917.4 s cpu; shards 388.72 / 360.33 / 347.28 s (153 entries + 5 DB + PCH control) | 77 → 94 → 6 |
| self-test, hash-sharded (before `_shards`) | — | `ctest -R scrub -j4`: shards 754.32 / 395.31 / 458.01 s | 40 → 103 |
| self-test, round 1 (for reference) | — | one process: 853.20 s real / 1659.2 s cpu (122 checks, ~24 compilers) | ~400 |

Reading:
- The gate's WALL time for the self-test is the longest shard, about 389 s here. Balanced shards
  took the long pole from 754 s to 389 s.
- CPU is about 5.6× the old guard's, and that is structural. Every clean verdict costs two
  configurations × (a PCH pass, a no-PCH pass and the `-E` include-order check). The corpus is
  1.9× larger (153 entries against 81).
- CPU is no longer a burst: 2 compilers per entry, instead of the ~24 that starved the other
  entries in round 1.
- If the owner wants fewer seconds, the lever is a path trigger at the gate: run the self-test only
  when `tools/taintset_scrub_guard.py`, `ir-pass/include/*.h` or the toolchain changes. That is an
  owner ruling (Rule 19), not taken here.

## R2.5 Not run / open

- **Not run:** lit, e2e, corpus A/B and the allocator sweeps. The binaries are the oracle's and
  nothing the pass compiles changed (two comment edits). The full `ctest -j6` is the merge gate's.
- **Not run:** a Debug-configured tree, and a non-Apple toolchain.
- **Proposed CLAUDE.md timing text.** It replaces round 1's §10 proposal; I have not applied it.
  > `taintset-scrub-guard` is now 1 gate entry plus 3 self-test shards (`--jobs 2` each); the shards
  > took ~350–390 s each in a `-j4` run at load ~90, and CPU is structural (two configurations ×
  > PCH / no-PCH / include-order check per clean verdict).
- **Open for the orchestrator:** whether to keep the self-test at every gate or behind a path
  trigger (an owner ruling).

---

# ROUND 3 — the review r2 findings (bd hdxo · 5ci2 · ngfa · s6ma), under the owner's threat-model ruling

The review is `review_r2_scrubguard/REVIEW.md` (verdict **NOT-CLEAR**). Its directory is committed
untouched with this round.

Two owner rulings govern this round (2026-09-29, bd memory
`owner-ruling-scrub-guard-threat-model-2026-09-29`):
1. **Threat model.** The guard defends against raw identity tables an agent PLAUSIBLY WRITES BY
   MISTAKE. Deliberate evasion is out of scope, listed as residual R12 and graded P3. A regression
   against main's guard on any spelling is still a finding.
2. The self-test runs at every merge gate, and the three shards stay as they are.

Main was merged twice before the battery:
- `25e44ab9` brought in rhk5 and z0re;
- `53eb9486` brought in cepm and fmt3, which landed during the round.

Both times CODE_MAP.md was regenerated rather than hand-merged. The C++ diff of this branch against
main is comment lines only (0 non-comment lines, measured).

## R3.1 What changed, finding by finding

| finding | fix |
|---|---|
| F-R2-1 (P1, regression): an unnamed struct walked RELAXED in `LoopBreakRegion` was accepted STRICTLY elsewhere via `decltype` | Every unnamed-record USE is now asked of the compiler. `_final` asserts `is_same` between the use's robbed member type and the robbed type of some DECLARATOR through which an unnamed record was walked, after `core<>` strips cv, references, pointers and extents. The declarator must have been walked in a mode at least as strict as the use (`MODE_RANK`: relaxed_any < relaxed_fields < strict < key). |
| F-R2-2 (P1, regression, deliberate): a location key forged by one macro expansion or by `#line` | Closed by the same assertion. The printed `(unnamed struct at FILE:LINE:COL)` is no longer an identity anywhere, and `_anon_key` is deleted. |
| F-R2-3 (P1, regression, deliberate): the derived class's own `using RvB = ::cq::RvB` steered the base check | A base whose canonical text contains `(anonymous namespace)` is refused. So is a derived class that declares its OWN member named like a base (any kind of member). The second rule also closes the local-class variant, rv2 B3′. |
| F-R2-4 (P1 by the old standard): the closure was quote-only, top-level `.h` | Cheap improvements. `check()` copies the WHOLE `ir-pass/include` tree, and the probe dir is FIRST on `-I` for every probe TU. The closure is the set of files the compiler's `-E` ENTERS under the probe dir (from line markers), so quote, angle, computed, subdirectory and `.def` includes all count. A closure file outside the probe dir, anywhere under the repo, is refused. Real-TU preprocessing is filed as **bd `test_C_libtooling-j2fp` (P2)**. |
| F-R2-5 (P1 by the old standard): "a closure file included first" was never simulated | A third context includes the closure's OTHER guarded files, then the header. Real TUs are still not preprocessed (R10, bd j2fp). |
| F-R2-6 (P2): `#line "other"`, `__INCLUDE_LEVEL__`, SFINAE | `#line`, GNU line markers, `__INCLUDE_LEVEL__`, `__COUNTER__`, `__FILE__`, `__BASE_FILE__` and `__FILE_NAME__` in a closure file are refused; this is cheap, even though these are deliberate spellings. SFINAE on completeness (B10) is residual R12, pinned in the self-test as a known pass. |
| F-R2-7 (P2): "fields" tolerated `Value *Tab[64]`, `Value **`, `SmallVector<struct{Value*}>` | Under policy "fields" a raw pointer is tolerated only as ONE pointer held directly as a field. A pointer array, a pointer-to-pointer, and EVERY argument of a library container are walked strictly; the one exception is the element records of the allowlisted member's own top-level container. The ALLOWLIST reason and the docstring now say exactly this (L7). |
| F-R2-8 (P2, introduced in round 2): the include-order check failed OPEN on a silent preprocessor | Every `-E` TU carries a sentinel line. Missing sentinel, missing line markers, or no line attributed to `TaintPropagation.h` in any context is a `GuardError`, so the gate fails closed. The check also compares the SET of closure files each context ENTERS; this is what caught D2, the `.def` whose lines exist only in context. |
| F-R2-9 (P3) | (a) The round-2 ATTACK-FIRST prediction about `__INCLUDE_LEVEL__` had the wrong direction; corrected in R12. (b) Shard 1 now checks that `ir-pass/CMakeLists.txt` registers exactly shards 1..n. |

**A defect in round 3's own first version.** It took the closure as "files with attributed lines",
which missed a `.def` whose content is entirely context-conditional (rv2 D2). It is now "files
entered".

**Instrument notes.**
- The first `ctest -R scrub` on the fix (`first_ctest_scrub_5d769485.txt`) failed shards 1 and 3.
  Three entries, r1 A1, A1b and A4′, were killed FOR THE WRONG REASON: they are now refused by the
  new mechanisms, with new messages. Their expected reasons were updated in `e86c5f45`;
  `check()` is unchanged.
- My `run_mutants.py --no-pch` run reported r1 A5″ as wrong-reason. That entry is designed for
  the PCH pass. In gate semantics (no PCH) the include-order check refuses it first. This is an
  artefact of the harness mode, not a guard defect.

## R3.2 Measurements (committed guard `44ad3cb0c8d83923`, commit `e86c5f45`)

`scrubguard_probes/final_battery_r3.sh` runs sequentially and aborts if the guard changes under it.
Binaries of the merged tree (`53eb9486`): `cq-opt` `45c895c2f50757a63f583889`, `libCQPass.so`
`2d6493e852831ed8b1226629`, `cq-opt-debugalloc` `82ebc3ea45f9e90aab3ff4f7`, `cq-scrub-selftest`
`efe8356a637afdfb7ac9b944`. These are main's code: this branch's C++ is comments only.

The guard on the real merged tree is **clean**: 76 members in both configurations, 15 tolerated notes.

| layer | before (reviewer's run on `e4ab4f28`) | after, FINAL (`44ad3cb0`) |
|---|---|---|
| `ctest -R scrub -j4` | — | **10/10 passed**: the gate entry took 51.27 s; selftest shards 1/2/3 took 733.19 / 629.89 / 636.00 s; 733.60 s real; load 41 → 13 (`final_ctest_scrub.txt`) |
| review r2 corpus (`guard_fool_r2.py`, gate semantics) | 11 attacks (10 + B11), **11 MISSED** | controls 0 bad; 11 attacks, **10 CAUGHT, 1 MISSED: B10**. B10 is the SFINAE case, R12 by the ruling, and is pinned. |
| review r1 corpus (`guard_fool_r1.py`) | (round 2: 12 caught) | controls 0 bad; 14 attacks, **12 CAUGHT, 2 MISSED: A7, A8**. A7 is R1 and A8 is out of scope; both are pinned. |
| r3 `guard_fool_r3` PCH / no-PCH, `guard_fool_r3b` | (round 2: 0/0/0 missed) | **0 / 0 / 0 MISSED**, controls 0 bad |
| reviewer `fail_open_r2.py` (F-R2-8) | G1 **CLEAN**, G2 **CLEAN** (fail-open) | **4/4 refused**, each with a truthful message: G1 "lost its sentinel line", G2 "attributes no line to TaintPropagation.h", G3 "killed by signal 9" |
| reviewer `fail_open.py` (r1) | 6/6 | **6/6 refused** |
| `fail_closed.py` (databases, via the CLI) | 6/6 | **6/6** |
| source mutants `source_mutants_r3.py` | — | P0 null **0 of 12 moved**; P1-P8 **all KILLED** (see below) |
| code map | — | `update_code_map.py --check` passes after each merge and commit |

Per-probe reasons, all right-reason (`final_guard_fool_r2.txt`):

| probe | refused as |
|---|---|
| B1 | RAW (the `Tab[64]` array, now strict under "fields") **and** the unnamed-type use "is not — per the compiler — the type of any unnamed record …" |
| B4, B5 | "per the compiler" |
| B2 | RAW, for each of the three shapes |
| B3 | both "ANONYMOUS NAMESPACE" and "declares its own member `RvB`" |
| B6, B9 | "uses `#line` / `__INCLUDE_LEVEL__`" |
| B7, B8, B11 | "preprocesses DIFFERENTLY"; B11 in the "closure's other headers first" context |

Source mutants (`final_source_mutants_r3.txt` P0-P4; P5-P8 in `final_source_mutants_r3_P5_P8.txt`,
re-run after a stale P5 anchor made the first run stop at P5; guard unchanged, sha `44ad3cb0`):

| id | disables | result |
|---|---|---|
| P1 | the mode rank on unnamed uses | KILLED 1/1 (rv2 B1′) |
| P2 | the compiler identity check | KILLED 2/2 (rv2 B4, B5) |
| P3 | the own-member-named-like-base rule | KILLED 1/1 (rv2 B3′) |
| P4 | the token ban | KILLED 1/1 (rv2 B9) |
| P5 | the "closure first" context | KILLED 1/1 (rv2 B11) |
| P6 | a top-level-`.h` closure | KILLED 2/2 (rv2 D1, D2) |
| P7 | the array / pointer-to-pointer strictness | KILLED 2/2 (rv2 B2a, B2b) |
| P8 | container-record strictness | KILLED 1/1 (rv2 B2c) |

The F-R2-8 fail-closed rule has no source mutant; it is measured by `fail_open_r2.py` instead.

**Composition.** cepm and z0re both LANDED on main during this round, and their worktrees are gone.
`composition.py` therefore hit a missing directory (the traceback is in the battery log). The
answer is the real-tree run on the merged tree, which contains both TaintSet members:
`taintset-scrub-guard` passed, clean. cepm's `SpecPredictedClassical` is exercised by the merged
`scrub_selftest.cpp`.

**Self-test inventory.**
- 176 entries: 19 expected-clean, including three pinned known passes (R1 / A7, R12 SFINAE B10,
  and the A8 out-of-scope case), and 157 mutants.
- Shards: 6+52 / 7+52 / 6+53.
- Shard 1 also runs 5 database cases, the PCH control and the CMake shard-registration control.

## R3.3 Not run

- The reviewer's `tree_probes_r2.py`. It needs a private `git worktree` of this commit.
  - D1 (subdirectory) and D2 (`.def`) are covered as self-test entries rv2 D1 and D2 through
    `check(extra_headers=…)`. `main()` reaches the same code: `check()` copies the whole include tree.
  - Its D0/D3 controls correspond to the pristine run and rv2 C2.
- `build_compiles_r2.py` was not re-run; the reviewer established that every attack header compiles.
- lit, e2e and corpus A/B: this branch changes no compiled code (comments only).
- The full `ctest -j6`: that is the merge gate's.

## R3.4 ATTACK FIRST (round 3)

1. **R10, the include-order check's synthetic contexts** (bd j2fp is the total fix):
   - a `.cpp`'s own `#define` before its includes;
   - "a closure file first AND another header's macro" combinations;
   - a header only a real TU's ORDER puts first.
2. **The unnamed-record rule's declarator detection.** A candidate is the FieldDecl immediately after
   an unnamed complete CXXRecordDecl in the same record. Look for a construct where that FieldDecl's
   type is NOT that record, which would make a raw unnamed type a candidate. The is_same check
   compares use against candidate, not candidate against record.
3. **The own-member rule.** It collects names of all non-implicit inner nodes. Test inherited-member
   `using` declarations, and bases named through a template-id.
4. **The token ban** is textual over comment-stripped closure files. Try `__LINE__`-dependent
   spellings, `_Pragma("line …")`, and string-literal tricks inside macros.
5. **The sentinel line** is a bare identifier. A macro named `cq_guard_ctx_sentinel` defined by a
   closure header would change it; that is deliberate, R12-class.
6. **The known passes:** R1 (bd gqda), R12's SFINAE case, A8 byte/char erasure.
