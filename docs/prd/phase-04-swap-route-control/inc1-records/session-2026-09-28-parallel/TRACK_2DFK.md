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
