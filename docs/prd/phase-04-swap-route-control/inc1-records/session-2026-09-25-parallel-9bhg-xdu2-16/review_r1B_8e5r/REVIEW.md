# Rule-13 round r1B on bd `8e5r` / `um24` / `j8sk` — VERIFICATION and COMPOSITION

Reviewer: r1B (independent agent). Subject: commit `818f8afa` on
`worktree-agent-a2cf1f874e5ec99d2` (binaries as delivered, **not rebuilt**: `cq-opt`
`8ab548b711175edd`, `cq-opt-debugalloc` `45f8a42708146a12`, `libCQPass.so`
`223953e8a212a2a7`, `cq-scrub-selftest` `4f2a55bcbc02c45c` — all re-hashed before use).
Oracle: frozen `cq-opt.main_e846` `b1603d237fc3a739` (main `def1b088`).
Scope: the INSTRUMENTS (pins, guard, allocator driver, harnesses), COMPOSITION with
bd `d88e` and bd `9bhg`, and COST. The container semantics (dead-marking, iteration
order, RAUW, consumers relying on deleted-key membership) are round r1A's.

## Verdict: `CLEAR-WITH-ITEMS`

The fix's own claims survive an **independent** instrument. Every headline
measurement in `TRACK_8E5R.md` §5–§6 was re-derived with an allocator I wrote from
scratch (`probes/rb8_interpose.cpp`, `DYLD_INSERT_LIBRARIES` + `__interpose`, applied
to the **unmodified frozen oracle** and to the subject's plain `cq-opt`, so no result
here depends on the subject's own `cq-opt-debugalloc`), including two allocator
policies the implementer did not have (`fifo`, `lifo2`: maximal reuse with a different
pairing) and an address-scrambling one (`rand`). None of the reproductions failed.

The items: **one P1** (a composition that goes red: `8e5r × d88e` fails
`taintset-scrub-guard` — loud, one-line fix, merge instruction below), **one P2**
(the structural guard misses 16 of 23 raw-member spellings, including the one
sub-class the implementer had to fix by hand), and eight P3s.

⚠ The P1 is a **merge obligation**, not a defect in `818f8afa`: 8e5r lands as it is;
whichever of 8e5r/d88e lands second owes the one-line change in F-EB-1.

## Findings

| id | sev | one line |
|---|---|---|
| F-EB-1 | **P1** | `8e5r × d88e` mechanical merge (auto-merged, no source conflict) turns `taintset-scrub-guard` + `taintset-scrub-guard-selftest` RED: d88e's `TaintSet::LiftedMergePhi::F` is a raw `llvm::Function *`. |
| F-EB-2 | **P2** | `taintset_scrub_guard.py` MISSES 16/23 raw pointer-bearing member spellings (controls pass), incl. a raw MAPPED pointer in a `ScrubMap` (also invisible to the selftest) and `AssertingVH` (a bare pointer in this Release LLVM). The record's "no raw pointer-bearing member (any depth)" is falsified. |
| F-EB-3 | P3 | The k65 lit/e2e pins have no POSITIVE CONTROL. Measured with a counter build: on the fixed binary k65 under `lifo` hits 12 dead-address queries + 3 revives (0/0 under `nofree`) — the witness is live today, but nothing would say so the day it stops. Also more robust than feared: the oracle is caught under `lifo`, `fifo` and `lifo2` alike. |
| F-EB-4 | P3 | Stale-binary trap, third binary: CLAUDE.md's "name BOTH (`CQPass cq-opt`)" now leaves `cq-opt-debugalloc` stale, and the four um24 `nofree` lines use ONLY that binary. Fallback/`!APPLE` modes make the pins vacuous-GREEN (the headers only promise "cannot go falsely RED"). |
| F-EB-5 | P3 | `CQ_OPT_DEBUG_ALLOC` replaces only NON-aligned `operator new/delete`; LLVM 19's `allocate_buffer` uses ALIGNED new under C++17 and `SmallVector`/`SmallPtrSet` use `malloc`. Right population for this class (Value/User objects, std nodes, hooks), but "maximal, deterministic reuse" must be scoped. No mismatch hazard found. |
| F-EB-6 | P3 | um24 is attributed to `lowerLoops`' prescan; the counter build shows an ITERATION reaching a dead key in 12 shipped modules (6 accepts) on the fixed binary, so on `main` iterations other than the prescan hand freed pointers onward (iterate-and-dereference consumers exist, e.g. `TaintPropagation.cpp:1829`'s round-2 worklist and `AbortParkEmit.cpp:229`; per-module attribution NOT measured). Closed by the container's iteration skip, not by the prescan rewrite. |
| F-EB-7 | P3 | "Live flaky surface on main?" — measured NO at N=10/50, and a large LATENT one: 0 of 2705 shipped modules × 10 system-allocator runs vary on the oracle, 0/650 um24 crashes; but on 225 shipped modules (214 accepts) at least one TaintSet query is decided by a dead address under the system allocator. State both. |
| F-EB-8 | P3 | `ab.py` compared only the FIRST `error:` line of stderr; warnings were never A/B'd oracle vs subject (`cq-opt-equivalence` compares two binaries of ONE tree). Closed here by `ab_full.py` (§4.4). |
| F-EB-9 | P3 | `8e5r × 9bhg` is clean, but 9bhg's post-hoc `taint.Tainted.erase(OldSite)` block erases by a DEAD pointer; under 8e5r it is a no-op that is safe only because nothing allocates between `retargetSite`'s erase and it. Delete it at the merge; correct F-9B-2's comment. |
| F-EB-10 | P3 | `cq-scrub-selftest` keys "reuse REQUIRED" on the exact env string: `CQ_OPT_DEBUG_ALLOC=LIFO` (or a lost ctest `ENVIRONMENT`) silently downgrades to "(not required)"; `nofree` silently skips 81 of 287 checks. Visible only in the printed denominator. |

## 1. The pins — can each pass vacuously?

### 1.1 k65 (lit `spec_scrub_dangling_key_clone_classical_mul.ll`, e2e `e2e-spec-scrub-dangling-key`)

**Does anything assert the alias OCCURRED?** No. On the fixed binary the lifo stream,
the nofree stream and the system stream are identical whether or not the clone's `mul`
landed on a freed key, and the fixture checks only the stream. The header discloses
the risk; it does not control for it.

**How robust is the coincidence?** Better than the header fears. `probes/k65_policies.sh`
(5 runs per cell, frozen oracle vs subject `cq-opt`, my interposer):

| binary | sys | lifo | fifo | lifo2 | nofree |
|---|---|---|---|---|---|
| oracle `b1603d23` | wrong 5/5 | wrong 5/5 | wrong 5/5 | wrong 5/5 | **right 0/5** |
| subject `8ab548b7` | right 5/5 | right 5/5 | right 5/5 | right 5/5 | right 5/5 |

(wrong = `call i32 @cq_template_mul_i32_hl`; every subject run and every oracle
`nofree` run hashed `3f4dd46194…`, every oracle reuse run `688a87…`.) Several freed
blocks share the clone's size class, so the alias survives a change of PAIRING. The
e2e slice under `probes/e2e_k65_pol.sh` (OPT replaced by a policy wrapper, 3 runs):
oracle `lifo` FAIL 3/3, `fifo` FAIL 3/3, `nofree` PASS 3/3 (so the golden IS the
no-reuse reference — independently confirmed), subject `lifo`/`fifo`/`nofree` PASS
3/3; oracle under the system allocator PASS 1/3 (the lottery).

**Positive control, measured (the recommendation made concrete).** A PRIVATE counter
build (`probes/posctl_counter.patch` on `818f8afa`; not for landing as is) counts
every query the self-cleaning container answered differently from a raw table
(`query_hits`: a `count/find/lookup` on a dead address; `iter_skips`; `revives`:
an insert at a dead address). k65 on the fixed binary:
`lifo` → `query_hits=12 iter_skips=0 revives=3`; system → `12/0/3`; `nofree` → `0/0/0`.
**Recommendation:** land the counters (an `inline` counter plus an exit report behind
`CQ_SCRUB_STATS`, or a weak hook only `cq_debug_alloc.cpp` defines) and add
`CQ_SCRUB_STATS=1` + `CHECK: query_hits={{[1-9]}}` to the k65 `lifo` RUN line and the
e2e slice. Then an allocation-sequence change that makes the pin a non-witness turns it
RED instead of leaving it green.

### 1.2 um24 `nofree` RUN lines

**Does the old code crash under no-reuse, and why?** Yes, deterministically. My
interposer on the frozen oracle, 10 runs per cell (`results/um24_policies.txt`):
the four named fixtures SIGSEGV 10/10 under `nofree`, `lifo` and `fifo`, and decline
cleanly (`rc=1`) 10/10 under the system allocator; `lowering_io_controlled_putchar`
crashes 1/10 (lifo), 4/10 (fifo), 2/10 (nofree); `…printf_sgt` 1/10 (lifo), 1/10
(fifo), 0/10 (nofree). The subject is clean in every cell. **Mechanism:**
`eraseFromParent` → `SymbolTableListTraits::removeNodeFromList` sets `Parent = nullptr`
BEFORE the node is deleted. Under `nofree` the dead bytes are never reused, so the
old prescan's `dyn_cast<Instruction>(V)` still succeeds (SubclassID intact) and
`getFunction()` = `getParent()->getParent()` dereferences null. Under the system
allocator the block is reused near-deterministically (macOS's same-size LIFO) by an
object whose field at `Parent`'s offset is a valid pointer, which is why it "works".
The implementer's "80/80" is consistent with my 40/40 (nofree) + 40/40 (lifo) +
40/40 (fifo).

**Vacuity on the FIXED binary.** The counter build shows `iosink_reject_mux_literal_callee`,
`…xor_bareout`, `…xor_derived` each with `iter_skips=2` (the container IS exercised),
but `lowering_reject_break_uncollected_clone` with `0/0/0` in all three modes: on the
fixed binary nothing iterates a dead key there, so its `nofree` line is held by the
prescan rewrite ALONE. With the container's iteration skip also present, that line is
killed only by M7 ∧ M12 together — consistent with the matrix's "M12 EQUIVALENT", and
worth one sentence in that fixture's header.

### 1.3 `cq-scrub-selftest`

It does guarantee the address when `CQ_OPT_DEBUG_ALLOC` is exactly `lifo` (a miss is
a FAIL — `StrictReuse`), and it does NOT depend on a coincidence for steps (1)–(3). But
(F-EB-10): `CQ_OPT_DEBUG_ALLOC=LIFO` → "31/31 (not required)", pass; `=nofree` →
"206 checks … 0/31 (not required)", pass — 81 checks skipped silently. Mitigated in
practice because the system allocator reproduces the reuse 31/31 anyway (measured),
which also means the `-sysalloc` ctest entry is, on macOS, a duplicate of `-lifo`.
Suggest `--require-reuse` as an ARGUMENT on the lifo entry instead of re-reading the
env string. A raw revert of a member that still compiles (a `SmallPtrSet`/`DenseMap`
member) fails at step (3); one that does not compile (`std::set` without `contains`,
`SmallVector` without `contains`) is a build failure — both loud. Mapped VALUES are
not probed (see F-EB-2 G22).

## 2. `cq-opt-debugalloc` as an instrument

- **Same objects:** `nm -U` over both binaries (93 753 defined symbols) differs ONLY
  by the 14 allocator symbols (`__Znwm`, `__ZdlPv`, … the anonymous-namespace
  `cqNew`/`cqDelete`/`CqFreeList`, three `GCC_except_table`s). ✔
- **Stale objects (F-EB-4):** `add_dependencies(cq-opt-debugalloc cq-opt)` is one-way;
  `cmake --build build --target CQPass cq-opt` — the recipe CLAUDE.md prescribes
  ("if you must name targets, name BOTH") — never relinks `cq-opt-debugalloc`, and
  `ctest -R ir-pass-lit` builds nothing. The four um24 `nofree` lines run ONLY
  `%debugalloc-cq-opt`, so on a stale driver they report on old code. Suggested
  guard: `lit.cfg.py` refuses to run when `cq-opt-debugalloc` is older than `cq-opt`
  (or compare an embedded build id); and CLAUDE.md's Build block names
  `CQPass cq-opt cq-opt-debugalloc cq-scrub-selftest`. Also: without the target the
  substitution falls back to `%cq-opt` (ignores the variable) and on non-Apple `lifo`
  degrades to the system allocator — both make the pins pass without exercising reuse.
  The headers say "cannot go falsely RED"; the converse — "can go vacuously GREEN" —
  is the one that matters for a regression pin and is unstated.
- **Coverage (F-EB-5):** only `operator new/new[]/nothrow` and their deletes are
  replaced. LLVM 19 `allocate_buffer`/`deallocate_buffer` call ALIGNED
  `operator new(size_t, align_val_t)` whenever `__cpp_aligned_new` is defined (C++17),
  so `DenseMap`/`DenseSet` bucket arrays, `StringMap` entries and `BumpPtrAllocator`
  slabs stay on libc++/malloc in every mode; `SmallVector` growth and big-mode
  `SmallPtrSet` use `malloc`. My interposer (same scope) counted **861**
  `operator new` calls for the whole k65 run. The population that IS pooled — `User`
  objects (`::operator new(Size + uses)`), std node containers, the `KeyHook`s — is
  exactly this defect's population, and pairs stay consistent (every pooled block is a
  real `malloc` block, so a cross-family free is harmless). Scope the sentence.
- **LIFO determinism:** deterministic per module across 10 runs on 60 family modules
  (every non-reference oracle module was non-reference in 10/10 lifo runs), i.e. no
  address-dependent control flow perturbed the pairing in that sample.

## 3. The guard (F-EB-2) — `probes/guard_fool.py`

Controls first: pristine tree clean; the guard's own M11 alias retarget and a plain
raw `SmallPtrSet` member both KILLED. Then 23 raw-member mutants, each asked of the
guard's own `check()` (`results/guard_fool.txt`):

**MISSED (16):** `std::set<Value*> X{};` (brace init: the `{…}` pushes a code frame and
resets the statement) · `llvm::SmallSet<Value*,8>` (not in `RAW_CONTAINER`) · a
`using` alias declared outside `TaintSet` · a `typedef` inside it · a macro-spelled
type · `SmallPtrSet<Value*, (4)>` and `… = decltype(X)()` (any `(` drops the
statement) · `std::array<Value*,4>` · `std::optional<Instruction*>` ·
`std::pair<Value*,unsigned>` · `StringMap<Value*>` · an anonymous `struct { Value *P; }`
member · a `union` member · a foreign record held BY VALUE (`LoopBreakRegion One;`) ·
a raw KEY whose mapped type is a scrub container plus a `// T.X` mention in the
selftest · **`ScrubMap<llvm::Value *, llvm::Instruction *>` — a raw MAPPED pointer**,
which the guard trusts by the `ScrubMap` spelling and which `checkMap` never probes
(it tests the key half only). That last one is precisely the sub-class the
implementer converted by hand (`SharedCondFlags`, `IOTapeForFn`, `GuardedStores` →
`WeakVH`); nothing stops a fourth.

**KILLED (7):** `unordered_map`, `SmallDenseMap`, `MapVector`, pointer in a pair KEY,
and three by accident (a `final` nested record and one with a base are flagged as
"foreign" because the nested-struct regex does not match them; a class-scope alias
shadowing `ScrubPtrSet` is flagged because the alias statement itself is parsed as an
unexercised member).

**`AssertingVH` is trusted and is a bare pointer here** (G25/G27 MISSED):
`/usr/local/opt/llvm@19/include/llvm/Config/abi-breaking.h:16` —
`#define LLVM_ENABLE_ABI_BREAKING_CHECKS 0`, under which `AssertingVH` is a plain
`Value *` with no handle. It is also the idiomatic "fix" for F-EB-1.

Clause (3)'s "exercised by the selftest" is a text search of the UNSTRIPPED selftest,
so a comment `// T.X` satisfies it (G19, coverage only).

**Recommendation:** invert the guard to a CLOSED world — accept only member types
built from an explicit whitelist (the scrub aliases; `WeakVH`/`WeakTrackingVH`;
scalars; `StringRef`; `DebugLoc`; nested records it recurses into), require a
`ScrubMap`'s MAPPED type to be a scalar or a handle, drop `AssertingVH`/`CallbackVH`,
parse brace initialisers, key the allowlist by qualified path, and search the
selftest comment-stripped for a `checkSet|checkMap|checkList(…T.X…)` call.

## 4. Harness claims, re-run

### 4.1 The 523-program families — sample, independent allocator

60 modules (40 drawn from the 86 the implementer found oracle-flaky, 20 from the 437
clean; seed 8, `results/fam_sample.lst`), 10 runs per cell, reference = the oracle
under MY `nofree` (unique per module). `results/fam_sample_summary.txt`:

| binary | sys | lifo | fifo | nofree | rand | dbg:lifo | dbg:nofree |
|---|---|---|---|---|---|---|---|
| oracle | 40/60 mods, 269/600 runs, 40 crash runs | 38/60, 380/600, 50 crash | 37/60, 370/600, 20 crash | 0/60 | 30/60, 54/600, 5 crash | — | — |
| subject | **0/600** | **0/600** | **0/600** | **0/600** | **0/600** | **0/600** | **0/600** |

The subject's 4200 runs are all the oracle's no-reuse reference. The `rand` column is
the positive control for the address-scrambling policy (it moves the oracle).

### 4.2 Null controls and address independence, whole corpus

- Subject `cq-opt`, all 3228 modules, 3 system + 3 `rand` runs each (19 368 runs):
  **0 modules with more than one (rc, stdout), 0 crashes.** This is the "subject twice"
  null control r1B asked for, three times over, plus an address-order attack on the
  "`Tainted` is address-ordered but no stage emits in its order" claim.
- Oracle, SHIPPED corpus (2284 lit + 421 e2e stage-1), 10 system-allocator runs each
  (27 050 runs): **0 modules vary, 0 crashes.** The implementer's two-run oracle null
  (24 movers) was all FAMILY modules; at N=10 no SHIPPED module moves either.
- (§4.5: the oracle under MY `nofree` vs the subject over all 3228.)

### 4.3 Is there a live flaky surface on `main`? (F-EB-7)

Observed: **no**. Oracle, system allocator, the 13 modules the implementer names
(5 lit + 7 e2e + putchar) × 50 runs = **0/650 crashes**, all single-outcome
(`results/um24_sys50.txt`), and 0/27 050 on the shipped corpus (§4.2). Latent: **large.**
The counter build (`results/hits_sys.tsv`) run under the SYSTEM allocator — i.e. the
allocation sequence the fixed pass actually sees in production — finds **225 of 2705
shipped modules (214 of them accepts) with ≥1 TaintSet query answered for a dead
address (573 queries)**, 574 with a revive, 12 with an iteration reaching a dead key
(family modules: 229/523). On `main` each of those decisions was taken by reading a
freed-address key; the implementer's oracle-vs-subject A/B (2705/2705 identical) shows
none of them changed an output on this corpus. The landing record should state both
halves — and the second is the good news for the A/B: its population is NOT an empty
quadrant for the dead-marking semantics (1029 of 3228 modules exercise the container
under the system allocator; 1333 under `lifo`), so "0 movers" is evidence about
exercised modules. "Pass only because the system allocator HAPPENS to reuse" should
read "because macOS malloc reuses a same-size block near-deterministically" — the
same fact that makes the family lottery's odds batch-correlated rather than i.i.d.

### 4.4 Full-stderr A/B (F-EB-8)

`probes/ab_full.py` — rc, full stdout and FULL stderr (warnings included), over the
2705 shipped modules, null control (oracle vs oracle) first: **null 2705/2705 same;
oracle vs subject 2705/2705 same** (`results/ab_full.txt`). The implementer's
zero-mover claim holds for warnings too; F-EB-8 is closed by measurement and stays a
P3 only as a note on `ab.py`'s scope.

### 4.5 Oracle no-reuse vs subject, whole corpus, independent allocator

The frozen oracle under MY `nofree` vs the subject under the system allocator, all
3228 modules: **3217 identical, 11 different — every one an oracle SIGSEGV** (the 4
um24 fixtures + the 7 e2e stage-1 modules the implementer names;
`results/corpus_ora_nofree_vs_subject.txt`). The implementer's 3216 + 12 differs by
`lowering_io_controlled_putchar`, which crashes 2/10 under no-reuse (§1.2) and did not
in my single run. Independent confirmation of the record's strongest sentence: with
the system allocator the fixed pass emits what the unfixed pass emits when no address
is ever reused.

## 5. Composition

### 5.1 `8e5r × d88e` (d88e `52d35e5d`, committed head) — F-EB-1

Private worktree `818f8afa` + `git merge --no-commit 52d35e5d`: every source file
auto-merged; only `CODE_MAP.md` conflicted (regenerated). Built with
`probes/compose_build.sh` (Release, full build).

- `taintset-scrub-guard`: **FAIL** — `raw pointer-bearing member F: llvm::Function *F`
  (d88e's nested `struct LiftedMergePhi { llvm::Function *F = nullptr; DebugLoc DL;
  WeakTrackingVH Base; SmallVector<WeakTrackingVH,2> Incomings; }`).
  `taintset-scrub-guard-selftest`: **FAIL** (it asserts a clean tree first).
- `lit ir-pass/test`: 2303 discovered, **2302 passed, 1 XFAIL**. `cq-scrub-selftest`
  lifo/sys: 287 checks, 0 failures. d88e's e2e (`e2e-slice-spec-lift-*`, the twin
  gate) and `e2e-spec-scrub-dangling-key`: PASS.
- d88e's 18 fixtures, 10 runs × {sys, dbg:lifo, dbg:nofree, fifo} on the composed
  `cq-opt-debugalloc`: every fixture ONE outcome, byte-identical to d88e alone
  (`frozen/cq-opt.d88e_preP3` under my sys/lifo/fifo/nofree)
  (`results/d88e_cmp_pol.txt`, `results/d88e_alone_pol.txt`).
- Is `F` a live hazard? Not today: nothing in `specialize()` erases a Function
  (`grep eraseFromParent Specialization.cpp` — instructions only) and the reader runs
  right after it. But the guard is right to refuse it.

**Correct merge:** `llvm::WeakVH F;` and `cast<Function>(L.F)` (null-checked) at its
one reader in `declineFalsifiedMergePhiLifts`. **Not** `AssertingVH<Function>` (passes
the guard, zero protection at `ABI_BREAKING_CHECKS=0`), and **not** an ALLOWLIST entry
(the allowlist is keyed by the unqualified member NAME, so "F" would exempt every
future `F` in every nested record). **Keep `Base`/`Incomings` as `WeakTrackingVH`**:
d88e's re-ask must FOLLOW a RAUW (`retargetSite`'s fp rebuild, a second lift onto an
earlier lift's base); the scrub containers are IDENTITY-keyed and dead-mark, and
swapping them in would make a RAUW'd incoming read "gone" and the re-ask decline
(`…_fp_rebuilt.ll` is the accept that depends on following). The guard already
accepts `WeakTrackingVH`; only `F` needs changing. (Verified on the text: both
`WeakVH F` and `AssertingVH F` make the guard clean — the second is the trap.)

### 5.2 `8e5r × 9bhg` (`30529716`) — clean, with one merge edit (F-EB-9)

Private worktree `818f8afa` + `git merge --no-commit 30529716` (only `CODE_MAP.md`
conflicted). Guard clean (52 members), selftest 287/0, `lit` 2296 discovered,
**2295 passed, 1 XFAIL**; `e2e-spec-classical-return`, `e2e-spec-fp-arg`,
`e2e-spec-fp80-union`, `e2e-spec-scrub-dangling-key` PASS.

The r1B_9bhg witnesses, 10 runs × 7 policies (`results/v_w_pol.txt`):

| module | 9bhg alone `8b837d1f` | composed |
|---|---|---|
| v12 | sys: 6/10 DECLINE; lifo, fifo 10/10 DECLINE; rand 3/10 DECLINE; nofree 10/10 accept `1d09beb2` | `1d09beb2` in all 70 runs |
| w9 | sys 4/10, lifo/fifo 10/10, rand 2/10 wrong (`1cdf9606`); nofree `c573193a` | `c573193a` in all 70 |
| w12 | sys, lifo, fifo 10/10 wrong (`2a1c4942`); rand 2/10 wrong + 1 decline; nofree `64e54b44` | `64e54b44` in all 70 |
| w15 | sys 4/10, lifo/fifo 10/10 wrong (`b6ac8c11`); nofree `5aaa85b6` | `5aaa85b6` in all 70 |

So the composition is allocator-independent and equals 9bhg's own no-reuse reference;
9bhg alone is allocator-dependent under four policies.

**The redundant scrub.** 9bhg adds, after `resolveSite` returns, `if (Cand.Site !=
OldSite) { taint.Tainted.erase(OldSite); BirthOrder…; HandleWidth…; StaleDeclined… }`.
`OldSite` was already `eraseFromParent`'d inside `retargetSite`, so this erases by a
DEAD pointer. Under 8e5r it is a no-op (`WasDead` → returns 0, disarms the hook) —
safe ONLY because nothing allocates between `retargetSite`'s erase and it (read: the
final `retargetSite` in `buildClone` is followed by `return SpecRecord{…}`; the
cache-hit path returns immediately). Were a future edit to allocate there, the
stale-pointer erase would remove a live object REVIVED at that address. **Merge:**
delete the block (8e5r makes it redundant), or move the scrub BEFORE the erase inside
`retargetSite`; and correct 9bhg's `Specialization.cpp` comment *"it is closed here at
its source"* (F-9B-2, still owed — the class had 29 producers).

### 5.3 The triple `8e5r × 9bhg × d88e`

Built privately (`818f8afa` + 30529716 + 52d35e5d). `lit`: 2314 discovered,
**2313 passed, 1 XFAIL**; guard **FAIL** on `F` (F-EB-1, unchanged); selftest 287/0;
the four 9bhg witnesses one outcome in all 70 runs each and equal to the 9bhg column
above (`results/v_w_all.txt`); d88e's 18 fixtures single-outcome across
dbg:lifo/dbg:nofree/sys and byte-identical to the frozen 9bhg×d88e composition
(`frozen/cq-opt.comp_9bhg_d88e`) on the five accepts (the five hashes differ from
8e5r×d88e — a 9bhg effect, reproduced by the binary without 8e5r).

### 5.4 Merge plan

1. **8e5r lands first** (it is the one that changes the TaintSet types; the other two
   then merge onto a tree whose guard is live). Its own items are P3 and non-blocking.
2. **d88e onto 8e5r:** textual merge is automatic; then the ONE edit of F-EB-1
   (`llvm::Function *F` → `llvm::WeakVH F`, `cast<Function>` + null check at the
   reader), keep `WeakTrackingVH` for `Base`/`Incomings`, re-run `taintset-scrub-guard`
   + `-selftest` + lit. Do not use `AssertingVH`; do not allowlist `F`.
3. **9bhg onto 8e5r(+d88e):** textual merge automatic; delete (or move before the
   erase) the post-`resolveSite` `OldSite` scrub block; correct F-9B-2's comment and
   TRACK_9BHG §3/§7 item 6; re-run `alias_gen5`/`alias_gen6` under the allocator modes
   on the landed binary (§5.2 is the expected result).
4. After any of these merges: the L8 duplicate-body scan, and the full `ctest -j6`.

## 6. Cost

Paired, interleaved, per-invocation child CPU (`probes/costab.py`: user+sys from
`wait4`, modules shuffled per round, A/B order randomised per module), measured in a
QUIET window (load average 2–5), null control FIRST:

| comparison | modules × rounds | mean ratio | 95% CI | per-module median |
|---|---|---|---|---|
| NULL: oracle vs a byte-identical copy | 150 × 6 | 0.9997 | [0.9956, 1.0038] | 0.9988 |
| subject / oracle, 120 random + 30 largest shipped modules | 150 × 6 | **1.0119** | **[1.0085, 1.0153]** | 1.0111 |
| subject / oracle, the passthrough module ×50 (launch only) | 50 × 6 | 1.0098 | [1.0031, 1.0166] | 1.0082 |
| subject / oracle, the 30 largest shipped modules | 30 × 8 | 1.0110 | [1.0057, 1.0163] | 1.0154 |

**+1.2 % ± 0.35 % CPU per `cq-opt` invocation (≈ +0.8–1.0 ms on an ≈ 80 ms spawn),
and it is LAUNCH cost** — the passthrough module (no pass work at all) pays the same
ratio as the largest modules, so the scrub machinery's own run-time cost is below this
instrument's resolution; the likely cause is the larger binary (41 891 064 vs
41 789 008 bytes). At ≈ 3000 spawns per lit run that is ≈ 2.5–3 s of CPU per run.
Full-`lit` wall/CPU (4 alternating runs, `results/lit_timing.txt`) could not resolve it:
the load rose 2 → 15 during the four runs and wall time rose monotonically with it
(48.9 / 55.7 / 56.0 / 60.1 s). The implementer's "+0.9 %" under load 50–377 is
consistent. Not a significant cost.

## 7. Bead filings

New beads, all discovered-from `test_C_libtooling-8e5r`:
- `test_C_libtooling-lin4` (P1) — F-EB-1, the 8e5r × d88e merge obligation.
- `test_C_libtooling-urf8` (P2) — F-EB-2, the guard's 16 MISSED spellings.
- `test_C_libtooling-p5p7` (P3) — F-EB-3, the positive-control counters.
- `test_C_libtooling-m91g` (P3) — F-EB-4 (+ F-EB-10), the stale/vacuous-green driver.

F-EB-5/6/7/8/9 are items for the landing record, not beads (F-EB-9 is step 3 of the
merge plan).

## 8. What I did NOT attack

- The container SEMANTICS (dead-marking, `Dead ⊆ S`, iteration order, RAUW, code that
  relied on a deleted key staying a member) — round r1A's surface. My only contact with
  it is empirical: 19 368 subject runs under system + address-scrambling allocators
  moved nothing, and the counter build's exercised population.
- The 40 local raw snapshots (bd `ibtq`), `BreakRegions` (bd `emof`), pointer-keyed
  state outside `TaintSet`.
- A `+Asserts`/ASan build; cross-function shapes beyond the 523 two-TU families.
- d88e's UNCOMMITTED working-tree edits (its worktree had modified
  `TaintPropagation.{h,cpp}` etc. at review time): I composed the COMMITTED head
  `52d35e5d`. The F-EB-1 field is in the committed header; re-check the guard on
  whatever d88e actually lands.
- The mutation matrix was not re-run; the guard's post-matrix fix (clause 4) was
  attacked directly (§3) instead.
- The `+5 ms` in-`cq-opt` allocator launch cost (§3.3 of the record) was not
  re-measured.
- Private build note: the triple worktree needed an intermediate LOCAL commit on a
  detached HEAD to merge twice; it is on no branch and was removed with the worktree.
