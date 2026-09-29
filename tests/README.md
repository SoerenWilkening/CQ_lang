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
