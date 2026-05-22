# CQ Pass Plugin — Phase 2 / 5 / 7 Prototype

A minimal LLVM pass plugin that validates the no-LLVM-fork architecture
claim from [`../docs/llvm-fork-analysis.md`](../docs/llvm-fork-analysis.md)
across three architecturally novel mechanisms.

## What this validates

That the entire CQ Stage 4 → Stage 5 transformation, automatic
uncomputation, and call-graph specialization can all be implemented as
an out-of-tree pass plugin against stock LLVM 19 — no fork, no patches,
no vendored `llvm-project`.

The plugin exposes four independently-runnable passes:

| Pass | Phase | Mechanism validated | bd issue |
|---|---|---|---|
| `cq-lowering`   | Phase 2 | Forward taint propagation; mid-struct → `i32` handle rebinding; lowering of `@cq_init_i32` / tainted `add i32` / `@cq_measure` to `cqrt_*` runtime calls | `test_C_libtooling-re1` |
| `cq-uncompute`  | Phase 5 | `PostDominatorTree`-based last-use computation; `cqrt_free(handle)` insertion at the post-dominator of all uses; `ReturnInst` escape detection; **multi-BB CFG correctness** (`findNearestCommonDominator` + `getFirstInsertionPt`) | `test_C_libtooling-aqf`, `test_C_libtooling-bhm` |
| `cq-specialize` | Phase 7 | `CloneFunction` + `ValueToValueMapTy` for function cloning; mangled-name renaming; call-site retargeting | `test_C_libtooling-mh3` |
| `cq-control`    | Phase 4 | `cq_when_begin`/`cq_when_end` region detection; substitution of `cqrt_template_*` calls inside regions with `_controlled` variants (control handle prepended); bracket erasure | `test_C_libtooling-dca` |

All five bd issues closed; memories recorded
(`prototype-validated-no-fork-2026-05-22`,
`prototype-phase5-phase7-validated-2026-05-22`,
`prototype-phase4-phase5branch-validated-2026-05-22`).

## What this does NOT validate (deferred)

These items remain to be built. None requires a different LLVM extension
surface than the one this prototype already exercises — they are
downstream implementation work, not architecture validation:

- Multiple widths beyond `i32` (`i1`/`i8`/`i16`/`i64`) — mechanical
  parametrization of the existing pattern
- Real adjoint gate-sequence emission (Phase 5 uses `cqrt_free` as a
  placeholder; real implementation emits inverse template calls before
  the free)
- Bennett wrap-around for specializations (Phase 7 preserves signature;
  real specialization rewrites to `(i32, i32)` handle ABI + forward +
  CNOT-copy + reverse)
- Specialization caching + q-arg-mask discrimination across multiple
  call sites
- Region handling (`cq_when_*`, Phase 4)
- Rewriter → prototype integration (real Stage 4 IR coming from
  libtooling, not hand-written)
- Real template body implementation (templates are extern declarations
  only — the actual gate sequences are runtime/library work)

## Build

Requires LLVM 19 development headers and CMake 3.13+.

```bash
cmake -DLLVM_DIR=/usr/lib/llvm-19/lib/cmake/llvm -B build .
cmake --build build
```

Produces `build/libcq_pass.so`.

## Run

```bash
bash test/run_test.sh                  # Phase 2 — cq-lowering (linear)
bash test/run_test_phase5.sh           # Phase 5 — cq-lowering + cq-uncompute (linear)
bash test/run_test_phase5_branch.sh    # Phase 5 multi-BB — branched CFG
bash test/run_test_phase7.sh           # Phase 7 — cq-specialize
bash test/run_test_phase4.sh           # Phase 4 — cq-control (regions)
```

Or manually:

```bash
# Phase 2
opt-19 -load-pass-plugin ./build/libcq_pass.so -passes=cq-lowering \
       -S test/input.ll -o test/output.ll

# Phase 5 (chained pipeline)
opt-19 -load-pass-plugin ./build/libcq_pass.so \
       -passes='cq-lowering,cq-uncompute' \
       -S test/input.ll -o test/output_phase5.ll

# Phase 7
opt-19 -load-pass-plugin ./build/libcq_pass.so -passes=cq-specialize \
       -S test/input_phase7.ll -o test/output_phase7.ll

opt-19 -passes=verify -disable-output test/output*.ll
```

## Acceptance criteria

The bd issue specifies these. Cross-check against `test/output.ll`:

| Criterion | How verified |
|---|---|
| Builds against stock LLVM 19 (no source patches) | `cmake --build build` succeeds |
| Pass runs without crash | `opt-19 -load-pass-plugin ... -passes=cq-lowering` returns 0 |
| Output IR is well-formed | `opt-19 -passes=verify` returns 0 |
| `@cq_init_i32` → `@cqrt_alloc_classical_i32` | grep for both in output |
| Tainted `add i32` → `@cqrt_template_add_i32` call | grep |
| `@cq_measure` → `@cqrt_measure` | grep |
| Pass plugin < 500 LOC C++ | `wc -l cq_pass.cpp` |

## Files

```
prototype/
├── CMakeLists.txt              — LLVM 19 detection, MODULE library build
├── cq_pass.cpp                 — all four passes (~525 LOC)
├── README.md                   — this file
└── test/
    ├── input.ll                — Stage 4 IR for Phase 2 + Phase 5 (linear)
    ├── input_phase5_branch.ll  — Stage 4 IR for Phase 5 multi-BB (branched)
    ├── input_phase7.ll         — Stage 4 IR for Phase 7 (with fn call)
    ├── input_phase4.ll         — post-lowering IR for Phase 4 (with cq_when_*)
    ├── run_test.sh             — Phase 2 smoke test
    ├── run_test_phase5.sh      — Phase 5 smoke test (chained pipeline)
    ├── run_test_phase5_branch.sh — Phase 5 multi-BB smoke test
    ├── run_test_phase7.sh      — Phase 7 smoke test
    ├── run_test_phase4.sh      — Phase 4 smoke test
    └── output*.ll              — generated by the smoke tests
```

## Architecture context

This prototype implements a small slice of the IR pass specified in:

- [`../docs/architecture.md`](../docs/architecture.md) §7 (IR pass responsibilities)
- [`../docs/backend.md`](../docs/backend.md) §3–§5 (input contract, mid→handle rebinding, IR pass algorithms)
- [`../docs/llvm-fork-analysis.md`](../docs/llvm-fork-analysis.md) (the claim being validated)
