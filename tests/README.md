# Running the test suite — two tiers

Owner ruling 2026-09-29 (bd `test_C_libtooling-2dfk`, bd memory
`owner-ruling-batch-gate-two-tier-2026-09-29`): landings are BATCHED, and the
suite has two tiers.

| tier | command | when |
|---|---|---|
| **FAST** | `ctest --test-dir build -LE heavy -j6 --output-on-failure` | intermediate merges inside a batch |
| **FULL** | `ctest --test-dir build -j6 --output-on-failure` (+ `cmake --build build --target cq-opt-equivalence-full`, `python3 tools/update_code_map.py --check`) | once per BATCH, on `main`, before the push |

`ctest --test-dir build -N -L heavy` lists the heavy tier. It is the matrices and
the instrument self-tests — entries that re-derive a whole disposition table by
compiling many generated programs:

- `e2e-loop-twin-matrix`
- `e2e-railbank-*-matrix` (dynamic-admission, stale, deadcell, guarded-vla, readorder)
- `e2e-condtree-classical-leaf-matrix`
- `e2e-railbank-register-twin-decline`, `e2e-railbank-register-twin-selftest`
- `taintset-scrub-guard-selftest` (and any `-selftest-<n>` shard of it)

Everything else — `ir-pass-lit`, every `e2e-slice-*`, every `*-twin-identical`
gate, the runtime / frontend / record gates and the quick self-tests — is FAST.

**The FULL suite has no label filter**, so it runs every entry regardless of the
labels. A heavy label can only move an entry out of the FAST tier, never out of
the gate. The patterns live in ONE place, `cmake/CQTestTiers.cmake`, and are
applied by name at configure time (so a test added by a parallel track is
classified without anyone remembering to label it); a pattern that matches
nothing is a configure WARNING.

If the FULL gate fails, bisect over the batch's merge commits (fast tier first,
then the failing heavy entry alone: `ctest --test-dir build -R '^<name>$'`).

## The stage cache (why a second run is fast)

Every e2e check is clang -O1 (stage 1) → **cq-opt (stage 2, the pass under
test)** → free-pairing check (2b) → link (3) → run (4) → compare. Stages 1, 2b, 3
and 4 are pure functions of their input bytes, so they are content-addressed
under `build/tests/e2e/.s1cache` and `.runcache` and a previous SUCCESS is
replayed; **stage 2 and every comparison (trace vs golden, rolled vs unrolled,
verdict vs table) run every time**. The key covers the input (source, or the
lowered module), both runtime archives, the link wrapper, the clang bytes, the
toolchain and SDK, the environment variables that steer clang/ld/python, **and
the command**: the literal flag arrays and a digest of the harness files
themselves (`run_slice.sh`, `run_slice_multi.sh`, `stage_cache.sh`,
`tools/cq_stage_cache.py`), so **editing the harness invalidates the whole
cache** (bd `ffm0`: before that, a harness edit that must fail was replayed as
the old pass). A pass change, a rebuilt runtime or a new clang is a miss. Read
`tools/cq_stage_cache.py` for the argument and its declared residuals;
`e2e-stage-cache-selftest` makes the cache fail on purpose, one row per key
component.

- `CQ_E2E_NO_CACHE=1 ctest --test-dir build -j6` — every stage runs, nothing is
  read or recorded (a from-scratch run).
- `rm -rf build/tests/e2e/.s1cache build/tests/e2e/.runcache` — reset.
- A by-hand `bash tests/e2e/run_slice.sh …` without the ctest environment caches
  nothing.
