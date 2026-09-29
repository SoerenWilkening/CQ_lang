# TRACK 2DFK — test-suite speed: two tiers, faster long poles, exact-duplicate removal

bd `test_C_libtooling-2dfk` (P1). Owner rulings 2026-09-29 (bd memory
`owner-ruling-batch-gate-two-tier-2026-09-29`): (1) batch landings, one full gate
per batch; (2) a FAST tier for intermediate merges, the HEAVY tier only at the
batch gate; (3) engineer faster tests; (4) fewer tests without dropping intended
coverage. Worktree branch `worktree-agent-ae7eff02a1262b05e`, started from `main`
`d21a59b0`. This is a HARNESS bead: no file under `ir-pass/src` or
`ir-pass/include` changes, and `tools/taintset_scrub_guard.py` and its CMake
entries are untouched (another branch is sharding them).

---

## STAGE 1 — the two tiers (commit 1)

### What changed

- `cmake/CQTestTiers.cmake` (new): `CQ_HEAVY_TEST_PATTERNS` (5 regexes) and
  `cq_apply_test_tiers(dir)`, which walks every directory's `TESTS` property
  recursively and APPENDs the label `heavy` to each matching test. A pattern that
  matches nothing is a configure WARNING (a renamed heavy entry silently in the
  fast tier). Requires CMake ≥ 3.28 for cross-directory test properties; on an
  older CMake it warns and applies no label, so the fast tier degrades to the
  full suite (slower, never weaker). This box runs CMake 4.3.2.
- `CMakeLists.txt`: one `include` + one call, LAST in the file.
- `tests/README.md` (new): the two commands and the heavy list.

No `add_test` line changed. Patterns, not per-call-site labels, because tests are
registered by several parallel tracks at once and a call-site label is the label
the next track forgets; `^taintset-scrub-guard-selftest` also matches the
`-selftest-<n>` shards the other branch introduces, with no edit to its entries.

### The safety argument

`ctest -j6` (the FULL suite / batch gate) has **no label filter**, so it runs
every entry whatever the labels say. A pattern can only move an entry out of the
FAST tier, never out of the gate. The failure mode of a wrong pattern is lost
fast-tier coverage (caught at the batch gate), never a skipped gate.

### The heavy tier (10 entries), and why these

Per-test times from this session's three merge gates (rhk5 / z0re / cepm, loads
32–65 on 12 threads; seconds):

| entry | rhk5 | z0re | cepm |
|---|---:|---:|---:|
| e2e-loop-twin-matrix | 1283 | 753 | 2040 |
| e2e-railbank-stale-matrix | 248 | 174 | 373 |
| e2e-railbank-register-twin-selftest | 242 | 181 | 359 |
| e2e-railbank-register-twin-decline | 198 | 145 | 305 |
| e2e-railbank-deadcell-matrix | 160 | 122 | 258 |
| taintset-scrub-guard-selftest | 116 | 95 | 145 |
| e2e-condtree-classical-leaf-matrix | 110 | 71 | 129 |
| e2e-railbank-readorder-matrix | 81 | 50 | 103 |
| e2e-railbank-guarded-vla-matrix | 47 | 42 | 97 |
| e2e-railbank-dynamic-admission-matrix | 57 | 49 | 64 |

These are the ten slowest entries other than `ir-pass-lit` (95–227 s), which is
deliberately FAST: it is the layer every change must witness. Next slowest after
them: `cq-opt-equivalence` 41–55 s (the stride-8 SAMPLE — its full sweep is a
build target and already batch-gate-only), `e2e-fixture-guard-liveness` 28–47 s,
`install_cq_unit` 14–38 s; every `e2e-slice-*` ≤ 48 s under load (≈1.7 s quiet).
Summed at the cepm gate the ten heavy entries are 3 829 s of 13 858 s.

### Measured

`cmake -S . -B build` → `cq test tiers: 10 entr(y/ies) labelled heavy`.
`ctest -N -L heavy` = 10, `ctest -N -LE heavy` = 560, `ctest -N` = 570 (10 + 560).
Planted a bogus pattern `^no-such-test$` → configure printed the WARNING naming
it; reverted → no warning.

### Stage-1 finding (PRE-EXISTING harness defect) — see STAGE 2 for the fix

`tests/e2e/CMakeLists.txt`'s directory-wide `set_tests_properties(${_E2E_ALL_TESTS}
PROPERTIES ENVIRONMENT …)` REPLACES each test's ENVIRONMENT. It runs after
`e2e-spec-scrub-dangling-key` set `CQ_OPT_DEBUG_ALLOC=lifo`, so since `818f8afa`
(2026-09-25) that entry has run `cq-opt-debugalloc` **without** the LIFO
allocator mode its header says is what makes the unfixed binary wrong 10/10 —
measured from `ctest --show-only=json-v1`: its ENVIRONMENT is the four `CQ_*`
variables only. And every entry registered AFTER that pass (the stale / deadcell
/ readorder / condtree matrices, two twin-identical gates) gets no `CQ_*` env at
all — harmless today only because `run_railbank_dynamic_matrix.py` reads no env
(it always links through the clang driver and never caches stage 1).

### Fast tier measured (stage-1 commit `4bc32b56`, before any stage-2 change)

`ctest --test-dir build -LE heavy -j6` from a FRESH build dir (so the pre-existing
stage-1 cache was cold): **560/560 passed, 520.6 s wall**, load 25 (1-min) /
107 (5-min) at start, 21 at end. Summed test time 3 108 s: 462 slices 2 523 s
(median 5.2 s), `ir-pass-lit` 180 s, `cq-opt-equivalence` 115 s,
`taintset-scrub-guard` 76 s, `code_map_drift` 60 s. Record:
`$SCRATCH/2dfk/fast_before.{meta,log,junit.xml}`.

---

## STAGE 2 — the long poles (commit `3c8cc3f6`, code map `da6cc584`)

### Why they were slow (measured, Rule 11)

**Per-slice stage costs** (10 slices, serial, load 170–300, seconds):
stage 1 0.7–1.5 (already cached by bd dgn5), `cq-opt` 0.24–0.33, stage 2b (python
checker) 0.27–0.44, `clang -c` 0.71–1.17, `ld` 0.24–0.41, and **the first exec of
a freshly linked binary 0.84–1.75** — the program itself does ~nothing, so that
is the AV/XProtect scan of a new executable. Stages 2b + 3 + 4 were ≈ 2/3 of a
slice, and every one of them is a pure function of the lowered module.

**`e2e-loop-twin-matrix`** (382 cells = 764 sides, 405 rows with controls): every
side paid an UNCACHED stage 1 (the source is generated and compiled at a random
`mkdtemp` path, so the run_slice cache could never apply), `cq-opt`, the
in-process checker, `clang -c`, `ld`, and a fresh-exe exec — ~764 × 3–10 s of
work at `--jobs 6` inside a `-j6` ctest. The gate time tracks load (753 → 2040 s).

**The railbank matrices**: a SERIAL loop over cases (18–50 each), stage 1 per
case uncached, twins linked through the clang driver; four of the six got no
`CQ_*` environment at all (the defect below). **The register-twin gate**: serial,
stage 1 uncached; **its selftest's B1 re-runs the whole gate**.

### The mechanism — a content-addressed cache for the PURE stages

`tools/cq_stage_cache.py` (python API + configure-time `run-base`) and
`tests/e2e/stage_cache.sh` (the bash spelling, byte-identical key text).

| stage | cached? | key |
|---|---|---|
| 1 clang -O1 | yes (run_slice already; now also run_slice_multi's TUs, the loop matrix's generated sources, the railbank / register sources) | CQ_S1_BASE + flags + source PATH + source bytes (generated sources are written to a content-addressed path first) |
| **2 cq-opt** | **NEVER** — the pass under test | — |
| 2b free_pairing_check (bash runners) | a PASS with empty output only | lowered module + checker source + flags + interpreter path |
| 3 link + 4 run | exit-0 run → `<key>.out` (trace); python API also a NORMAL non-zero exit → `<key>.nz` (status + stdout); never a signal | CQ_RUN_BASE + lowered module + both archives + the link wrapper (+ argv) |
| the comparison (diff vs golden, rolled vs unrolled, verdict vs table, P1/P2) | **NEVER** | — |

`CQ_RUN_BASE` = sha256(CQ_S1_BASE (clang bytes + version + headers), the
derived link wrapper, `ld -v`, `sw_vers`), computed once per configure. The
archives and the wrapper are hashed at TEST time, so a rebuilt runtime is a miss
with no reconfigure.

**The one normalisation, and why it is exact.** The lowered module's first line
`; ModuleID = '<input path>'` names this run's `mktemp -d`; it is dropped from the
2b/3/4 key. It is an IR comment (the lexer discards `;` lines; the stage-3
compile's module identifier comes from its own command-line path, which is also a
fresh temp path today), and `free_pairing_check.py` matches only `^define`,
`^\s*@x =` and `^label:` outside a function — a `;` line can match none of them.
`source_filename` is NOT normalised (it stays in the key).

**What a hit does not re-witness**: "this toolchain still links and runs this IR
on this box today". That is why the toolchain is in the key and why
`CQ_E2E_NO_CACHE=1` exists (every cache off, S1 included). Only successes are
recorded; entries are published by write+rename.

### The env-pass fix (PRE-EXISTING defect, stage-1 finding)

`tests/e2e/CMakeLists.txt`'s directory-wide `set_tests_properties(... ENVIRONMENT)`
is replaced by a `cmake_language(DEFER CALL _cq_e2e_apply_env)` that runs when the
file is fully processed and APPENDS each missing `CQ_*` variable to every test in
the directory. Measured after (`ctest --show-only=json-v1`): every e2e entry has
all six variables, and `e2e-spec-scrub-dangling-key` has
`CQ_OPT_DEBUG_ALLOC=lifo` + the six — it now actually runs under LIFO, and passes
(0.9 s warm, 8 s cold). The per-entry ENVIRONMENT copies below the old pass are
kept (harmless; conflict-free merges for parallel tracks); a NEW entry needs none.

### Harness changes

- `run_slice.sh`, `run_slice_multi.sh`: source `stage_cache.sh`; stages 2b/3/4
  via `cq_stage_2b` / `cq_stage_34_diff`. Stage 4's trace goes to a file, the
  exit status is re-raised after the diff (as `slice | diff` under pipefail did).
  `run_slice_multi` also gets stage-1 caching (CQ TU: run_slice's key exactly;
  lib TUs, compiled without `-include CQ.h`, add a tag), hits COPIED to the same
  `$TMP` path so `llvm-link` sees identical inputs at identical paths.
- `loop_twin_matrix.py`: `build_side` uses `stage1_generated` + `link_and_run`;
  new `--dump-sides FILE` (measurement aid, never read by the gate).
- `run_railbank_dynamic_matrix.py`, `railbank_register_twin_gate.py`: rows /
  pairs on a thread pool (`CQ_MATRIX_JOBS`, default 4), output assembled in
  sorted order; stage 1 + twins' link/run through the cache (twins now use the
  `CQ_LD` split link every other harness uses).
- NEW fast-tier entry `e2e-stage-cache-selftest` (`tools/cq_stage_cache_test.py`).

### Measured — speed (compare only rows at similar load)

| entry | before | after, cold cache | after, warm | load (1-min) |
|---|---:|---:|---:|---|
| e2e-loop-twin-matrix (`--jobs 4`, by hand, ctest env) | 568 s | 474 s | **26 s** | 16→9 / 20→7 / 7→7 |
| railbank-dynamic-admission | 41 s | 5 s | 2 s | ~10–25 |
| railbank-guarded-vla | 39 s | 6 s | 2 s | ” |
| railbank-stale | 91 s | 26 s | 11 s | ” |
| railbank-deadcell | 47 s | 20 s | 13 s¹ | ” |
| railbank-readorder | 25 s | 10 s | 2 s | ” |
| condtree-classical-leaf | 20 s | 13 s | 1 s | ” |
| register-twin-decline | 30 s | 20 s | 5 s | ” |
| register-twin-selftest | 34 s | 32 s | 13 s | ” |
| one e2e slice (8 value-arm slices, `-j1`) | 1.6–2.6 s (S1 hit only) | — | **0.24–0.28 s** | ~20 |
| **FAST tier** `ctest -LE heavy -j6` | **520.6 s** (560 tests) | **378 s** (561) | **145 s** (561) | 25→21 / 4→9 / **6→193** |

¹ measured before the `.nz` refinement: deadcell's twins return `slice(argc)`
(non-zero), so their runs were never recorded; they are now.

Fast tier, summed test time: 3 108 s → 2 187 s (cold) → **866 s (warm)**; slices
2 523 s → 1 769 s → **369 s** (median 5.17 → 3.35 → 0.78 s). The warm fast
tier's wall is now `ir-pass-lit` (131 s under that load) — not addressed here
(it runs the pass under test on every fixture; nothing in it is a pure stage).

### Measured — verdict neutrality (same tree, same binary `cq-opt` `45c895c2f50757a63f583889`)

- **Loop twin matrix, every side of every cell.** `--dump-sides` records, per
  side, the opt exit, first diagnostic, warning count, harness error, residual
  `cq_phi` state and the FULL trace. BEFORE (old `build_side`, no cache) vs
  AFTER-COLD vs AFTER-WARM: **405 of 405 cells, 810 of 810 sides, 589 traces —
  0 mismatches in any field; the `--out` verdict tables byte-identical (405
  rows)**; all three runs print `all cells match loop_twin_matrix.expected.txt;
  all 70 quarantined cells diverge with their pinned signature …; 4 of 4 boundary
  controls as pinned`. (`cmp_sides.py`, records `ltm_{before,after_cold,after_warm}.*`.)
- **The six railbank/condtree matrices + the register-twin gate + its selftest**:
  the OLD harness files (git `HEAD` copies) vs the NEW ones, same sources:
  **stdout+stderr byte-identical (sha-256) for all 8 entries, old vs new-cold vs
  new-warm**, every rc 0. (`ab_rb.sh`, records `ab_rb_{old,old2,new_cold,new_warm}/`.)
  ⚠ My first "old" run of the register selftest went red — an artefact of MY
  comparison layout (the scratch copy resolved the gate's default include as
  `<copy dir>/../include`); re-run with the layout fixed (`old2`): rc 0. It
  exposed a real, pre-existing selftest weakness, filed as bd `be6u` (below).
- **Whole fast tier**: before 560/560; after-cold 560/561 — the one red was
  `code_map_drift`, MY ordering slip (I regenerated `CODE_MAP.md` before `git add`
  of the new files, which the generator lists by `git ls-files`), fixed in
  `da6cc584`; after-warm **561/561**.

### Mutation controls — the cache made to fail on purpose (L10)

**`e2e-stage-cache-selftest`** (22 expectations, through the REAL `run_slice.sh`
in a PRIVATE cache; ~15–70 s depending on load): A cold run records one trace +
one 2b marker; B a warm run invokes neither clang nor the checker (a real hit);
J a no-op `cq-opt` wrapper still hits (NULL control); C a perturbed golden FAILS
on the warm hit; D a perturbed lowering misses, re-links and FAILS — and FAILS
AGAIN on its own recorded entry; E a checker-rejected lowering fails AT stage 2b,
twice, no marker; F a byte-different same-semantics runtime archive misses and
PASSES, a semantically perturbed one misses and FAILS; G `CQ_E2E_NO_CACHE=1` and
H a by-hand run record nothing; I the python and bash keys are the same entry and
`link_and_run` replays it; K a non-zero exit replays with its status.
⚠ D first "passed" — my mutant rewrote the first `double 5.000000e-01`, which is
in `@slice`, dead code `main` never calls; the module changed (a new cache entry)
and the trace correctly did not. Fixed to rewrite every occurrence.

**Meta-mutation of the selftest** (`meta_mut.sh`, planted in `stage_cache.sh`, each
restored): M1 run key ignores the module → CAUGHT (D, I); M2 no diff on a hit →
CAUGHT (C, D); M3 2b marker written on failure → CAUGHT (E); M4 run key ignores
the archives → CAUGHT (F, I); M5 2b key ignores the module → CAUGHT (E). Null
(unmodified) → green. **5 of 5 caught.**

**The loop twin matrix through the WARM cache** (`ltm_mut.sh`): MC0 a no-op `--opt`
wrapper → rc 0 (NULL); MC1 one expected verdict flipped → rc 1,
`m_add_der_none: verdict changed`; MC2 one quarantine digest altered → rc 1,
`QUARANTINED SIGNATURE CHANGED`; MC3 an `--opt` wrapper that rewrites every
`cqrt_ry_*` angle on UNROLLED sides only → rc 1, 268 cells now
`TRACE-DIVERGENCE`, `FAILED (540)` — a changed lowering is a miss, never a replay.

---

## STAGE 3 — duplicates (commit `402a5643`)

### Exact duplicates REMOVED — 6 lit fixtures

Scanner (`dupscan_ll.py`): per fixture, the IR view (every non-comment line) and
the DIRECTIVE view (every RUN/XFAIL/REQUIRES line and every check directive of
every prefix any RUN line names, the file's own name normalised). EXACT = both
views identical: lit ran the same commands over the same module and asserted the
same things twice. 2 489 fixtures → **6 exact groups of 2** (+ 3 same-module
groups with different assertions, which are NOT removed — below).

| removed | kept | why they were one test |
|---|---|---|
| `control_angle_select_reject_cond_alias.ll` | `…_cond_register.ll` | 3qlq's register-free `cq_phi` migration deleted the `qd = cq_phi(q,.1)` alias hop — the module IS the register case |
| `control_inplace_ry_reject_stale_diag_alias_backward.ll` | `…_forward.ll` | same migration: `mark = cq_phi(r,.1)` gone, so `mark` IS `r` and both spellings are one module |
| `control_predmux_reject_selectform_rotation_hop_chained.ll` | `…_poison_arg.ll` | same migration RAUWed each `cq_phi_si32(x,.)` to `x`: the two-hop chain collapsed to the depth-1 `poison` |
| `control_swap_diamond_derived.ll` | `control_swap_diamond.ll` | same migration: the pre-region `qd = cq_phi(q,.)` is gone, the "derived" base is the base |
| `control_swap_reject_nested_inner_clobber.ll` | `…_nested_value_mixed.ll` | identical module AND directives since creation (`ac5f90f6`) |
| `spec_overaccept_probe_callbr_visible.ll` | `spec_reject_callbr.ll` (older) | the probe re-registered the exact module + RUN/CHECK lines |

Four of the six are Rule 12 (c) in practice — "a decline fixture that goes green
because its subject no longer exists pins nothing": each one's whole subject (a
`cq_phi` register alias) became inexpressible at the 3qlq migration. The removed
file's unique header prose is folded VERBATIM into the kept file under a dated
`MERGED` block (incl. any retirement trigger); `merge_dups.py` REFUSED unless the
kept file's IR and directive views are byte-identical after the merge.
`control_swap_diamond_derived_polarity.ll`'s pointer to the removed file is
repointed. NOT changed (pass source is out of scope): `ArmClassify.cpp:542`'s
comment names `` `..._stale_diag_alias_backward.ll` shape `` — the elided prefix
still resolves to the surviving `control_angle_select_reject_stale_diag_alias_backward.ll`.
lit: 2 489 → 2 483 discovered; the 13 fixtures matching the kept names pass.
The 2026-09-15 armgate scan (`…/armgate/probes/dup_body_scan.out`) had listed all
six pairs as IR-duplicates with agreeing verdicts; nobody had removed them.

**e2e: 0 exact duplicates.** `dupscan_e2e.py` keys every run_slice /
run_slice_multi entry on (harness, sha of source, sha of each lib, sha of golden,
flags): 466 entries, 0 groups; 63 `compare_files` gates, 0 registered twice.

### NEAR-duplicates — for OWNER APPROVAL, not removed

1. **Same stage-1 IR, same golden, different C spelling** (`neardup_e2e.py` —
   stage-1 IR minus `ModuleID`/`source_filename`; 424 single-TU slices → 413
   distinct IRs, **11 redundant runs in 8 groups**):
   - `branchless-hypot` / `branchless-hypot-cq`
   - `branchless-scalbln` / `branchless-scalbn`
   - `control-phase-andcond` / `control-phase-nest` — DELIBERATE: the nest's
     header says the two are byte-identical BY CONSTRUCTION and
     `e2e-phase-nest-andcond-identical` pins that `-O1` fold fact. KEEP.
   - `libm-real-{ldexpf,scalblnf,scalbnf}`, `libm-real-{ldexp,scalbln,scalbn}`,
     `libm-real-{ldexpl,scalblnl,scalbnl}`, `libm-real-{nextafterl,nexttowardl}` —
     census rows (`e2e-census-slice-sync` ties each golden to a census cell), so
     removing one is a census decision, not a harness one.
   - `spec-dropped-arg-musttail-inner-twin` / `spec-dropped-arg-volatile-global-twin`
   Saving if all 11 went: ~11 × 0.25 s warm / ~11 × 1.7 s cold. **Recommendation:
   keep all** — each pins a frontend-spelling fact a header or clang change could
   break, and with the cache their cost is noise.
2. **`e2e-railbank-register-twin-selftest` B1 re-runs the whole
   `e2e-railbank-register-twin-decline` gate** as its precondition. With the
   shared cache it is now ~5 s warm; dropping B1 would save that but leaves the
   other B rows without their "the shipped corpus passes on THIS binary" anchor.
   Recommendation: keep.
3. **The 63 `*-twin-identical` `compare_files` gates** cost ~0.05 s each; they
   re-assert golden identity, not re-run anything. No saving worth a review.
4. Matrix cells subsumed by fixtures: NOT surveyed (no cheap exact criterion;
   the loop matrix's cells are generated programs with no fixture spelling).

### Full suite measured (after stage 2, `da6cc584`)

`ctest -j6`, 571 entries: run 1 (fast-tier 2b/3/4 caches cold again after the
heavy measurement cleared them) **571/571 in 705 s** (load 8→4, 5-min 22–25);
run 2 warm **571/571 in 311 s** — but load rose 4 → 98 during it, and the long
pole was the FIRST version of `e2e-stage-cache-selftest` at **291 s**: it ran its
~7 cold link+exec cycles serially and each fresh-executable exec slows badly under
load. That is the next section's fix. For reference this session's three merge
gates took 832–2 360 s (loads 32–65).

### `e2e-stage-cache-selftest` restructured (commit after `da6cc584`) — and what that nearly cost

Row A runs first; the other rows run as 7 parallel GROUPS (4 threads), each with
its own invocation logs (`mkstemp`) and its own run cache. **10.7 s wall at load 9**
(user 12.9 s), 22/22. ⚠ **L10, measured on my own instrument**: the first
restructure gave each group an EMPTY run cache, and the re-run meta-mutation
showed M5 (2b key ignores the module) MISSED and M1 caught only by the key-parity
row — a perturbation can only reveal a key that ignores the module if it runs
against a cache that already HOLDS the good module's entry. Each group now starts
from a COPY of A's populated cache (`warm_copy`, commented as load-bearing), and
the meta-mutation is back to **5 of 5 caught, by the same rows as the serial
version** (M1: D; M2: C, D; M3: E; M4: F, I; M5: E); null green.

### Heavy tier measured (after stage 2, `da6cc584`)

`ctest -L heavy -j6`: **cold 409 s** (load 33→6; the wall is the loop matrix's
cold run, 409 s; stale 112, selftest 96, scrub-guard-selftest 88, deadcell 76,
register-decline 66) — **warm 57 s** (load 5→10; the wall is now
`taintset-scrub-guard-selftest` 57 s, untouched here; loop matrix 24 s, register
selftest 11 s, every railbank matrix 1–4 s). 10/10 both times. For reference the
same ten entries took 64–2 040 s EACH at this session's merge gates (load 32–65).

---

## PROPOSED CLAUDE.md TEXT (for the orchestrator; this track does not edit CLAUDE.md)

**Replace Rule 19's "Where the full `ctest -j6` runs" paragraph (keep items 1–5
and everything after them) with:**

> **Where the suite runs — TWO TIERS, ONE BATCH GATE** (owner ruling 2026-09-29,
> bd memory `owner-ruling-batch-gate-two-tier-2026-09-29`; supersedes the
> per-merge half of the 2026-09-26 ruling). Branches that clear Rule 13 are merged
> to `main` locally in a BATCH. Each intermediate merge runs the **FAST tier**,
> `ctest --test-dir build -LE heavy -j6` (lit, every e2e slice and twin gate, the
> quick self-tests — 561 entries). **Once per batch**, normally at session end
> before `git push`, the **BATCH GATE** runs the FULL suite `ctest -j6` (no label
> filter: every entry, heavy included) + `cq-opt-equivalence-full` +
> `update_code_map.py --check`; if it fails, bisect over the batch's merge
> commits. The HEAVY tier (`ctest -N -L heavy`: the loop twin matrix, the railbank
> and condtree matrices, the register-twin gate + selftest, the scrub-guard
> selftest shards) is labelled by NAME PATTERN in `cmake/CQTestTiers.cmake`, never
> at the `add_test` site, and a pattern that matches nothing is a configure
> warning. A heavy label can only move an entry out of the fast tier — the batch
> gate has no filter. The batch gate is MANDATORY, no judgement call, whenever the
> batch contains any of: [items 1–5 unchanged].

**Replace the "Timing." paragraph of Build & Test with:**

> **Timing, and the stage cache.** Every e2e check is clang -O1 (1) → cq-opt (2,
> the pass under test) → free-pairing check (2b) → link (3) → run (4) → compare.
> Stages 1, 2b, 3 and 4 are pure functions of their input bytes and are
> CONTENT-ADDRESSED (`tools/cq_stage_cache.py`, `tests/e2e/stage_cache.sh`;
> `build/tests/e2e/{.s1cache,.runcache}`): a previous SUCCESS of the same lowered
> module against the same archives and toolchain is replayed. **Stage 2 and every
> comparison — trace vs golden, rolled vs unrolled, verdict vs table — run every
> time.** `CQ_E2E_NO_CACHE=1` switches every cache off; `e2e-stage-cache-selftest`
> makes it fail on purpose. Measured 2026-09-29 (bd `2dfk`): FAST tier 521 s →
> 145 s warm (378 s cold); a warm slice 0.25 s; HEAVY tier 409 s cold, 57 s warm
> (loop twin matrix 568 s → 26 s at `--jobs 4`); the fast tier's wall is now
> `ir-pass-lit`, the heavy tier's `taintset-scrub-guard-selftest`. Quote loads with
> every figure — contention causes false FAILURES, never false passes; re-run a
> `-j` red serially before calling it a regression.

**Add to the Build & Test prose after "Adding fixtures is nearly free":**

> **A new e2e entry needs no `set_tests_properties(... ENVIRONMENT ...)`.** A
> deferred pass at the top of `tests/e2e/CMakeLists.txt` APPENDS the `CQ_*`
> variables to every test in the directory wherever it is registered, and never
> replaces an entry's own ENVIRONMENT. ⚠ The pass it replaced REPLACED every
> earlier test's ENVIRONMENT: `e2e-spec-scrub-dangling-key` ran without its
> `CQ_OPT_DEBUG_ALLOC=lifo` from `818f8afa` to bd `2dfk`.

---

## ATTACK FIRST (for the Rule-13 / harness reviewers)

1. **The key's completeness.** Anything the trace depends on that is NOT in the
   run key is a stale-hit hole: the lowered module (minus ONE comment line),
   both archives, the wrapper, `CQ_RUN_BASE` (clang bytes+version via
   CQ_S1_BASE, wrapper, `ld -v`, `sw_vers`), argv. NOT in it: the libSystem
   dylib bytes (covered only by `sw_vers`), `libclang-cpp`/`libLLVM` bytes behind
   the clang binary (the same exposure CQ_S1_BASE has always had), environment
   variables of the run (the runtime reads none — `grep getenv runtime/` is empty).
2. **The ModuleID normalisation.** Argued exact (comment line; checker regexes
   cannot match a `;` line). Try to construct a lowered module whose FIRST line is
   `; ModuleID = ` and is NOT the printer's comment.
3. **The `.nz` refinement** (python API only): a recorded non-zero exit replays
   with its status. The loop matrix treats any non-zero exit as a harness error;
   the railbank twins and the register gate ignore the status. Is there a caller
   whose verdict depends on the status in a way a replay changes? Signals are never
   recorded.
4. **Concurrency.** Two ctest entries sharing one entry (register gate + selftest
   B1; run_slice + run_slice_multi on the same CQ TU): publish is write+rename,
   readers never see a partial file. A torn `.s1cache` write from the OLD run_slice
   code path (`cp` then `mv`) is unchanged.
5. **`cq_stage_2b`'s capture.** The checker's stdout+stderr are now captured into
   one string and re-printed; a marker is written only on rc 0 AND empty output,
   so the four `--allow-unproven` slices (which print findings) always re-run.
6. **The deferred env pass.** It APPENDS only missing variables. A test that sets
   `CQ_LD=` (empty) on purpose keeps it — none does today (the four per-entry ENVIRONMENT sites,
   read). A test registered in a SUBDIRECTORY of tests/e2e would not be seen (there
   are none).
7. **`CQ_MATRIX_JOBS` threads**: each row writes only its own
   `case-<N>.*` / `<name>.{bank,reg}.*` files in the shared temp dir; output is
   assembled in sorted order (byte-identical stdout measured).

## What I ran (literally) and what I did NOT run

RAN: fast tier before (560/560, 520.6 s) and after cold (560/561, the
`code_map_drift` red fixed in `da6cc584`) and warm (561/561); heavy tier after
cold + warm (10/10, 10/10); the loop matrix by hand before/after-cold/after-warm
with side dumps (0 of 810 sides differ); old-vs-new for the 8 railbank/register
entries (byte-identical output); `e2e-stage-cache-selftest` (22/22) + 5 meta-mutants
(5 caught) + null; loop-matrix mutation controls MC0–MC3; `lit --filter` over the
kept fixtures (13 passed, 2 483 discovered); `update_code_map.py --check` (rc 0).
NOT RUN: a full `lit ir-pass/test` sweep on this branch beyond the fast tier's
`ir-pass-lit` entry (which ran it: 2 483 fixtures, green in both after runs);
`cq-opt-equivalence-full` (no pass change); allocator sweeps (no pass change); the
taintset scrub-guard files (out of scope, another branch).
