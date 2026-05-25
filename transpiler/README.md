# Quantum-C Transpiler

The libtooling rewriter — Stage 1 of the CQ pipeline. Reads C source with
the `quantum` attribute (set by the `quantum` macro in `<CQ.h>`) and emits
transpiled C that uses the per-width intrinsic surface
(`qint_mid_t`, `cq_init_si32`, `cq_measure_si32`) declared in
[`<cq_mid.h>`](../include/cq_mid.h).

Stages 2–4 (Clang → IR pass → link) live elsewhere in the tree; see the
[top-level README](../README.md) and the
[Phase 1 PRD](../phases/phase1/PRD.md) for the whole pipeline. Full-pipeline
acceptance tests live under [`tests/e2e/`](../tests/e2e/), driven by
[`tools/cqc`](../tools/cqc); this subproject owns rewriter-only build and
test (unit goldens + v1-era e2e fixtures repointed to the Phase 1
emission).

> **History.** The pre-architecture v1 tool was a standalone source-to-source
> transpiler against the stub `qint.h`. Phase 1 supersedes that surface
> (`qint_t` → `qint_mid_t`, `init_qint`/`add` → `cq_init_si32`/`.val`
> arithmetic, retains the rewriter as a sub-build of the top-level project.
> See [`phases/v1/PRD.md`](../phases/v1/PRD.md) for the v1 contract;
> [`phases/phase1/PRD.md`](../phases/phase1/PRD.md) for what changed.

## Modules

| File | Responsibility |
| --- | --- |
| `src/main.cpp` | libtooling entry point |
| `src/TypeMap.{cpp,h}` | C type → IR width suffix (`int` → `"i32"`), target-aware |
| `src/QuantumAttr.{cpp,h}` | `VarDecl` → is-quantum predicate |
| `src/SourceText.{cpp,h}` | `Expr` → original source text |
| `src/OperandClass.{cpp,h}` | `Expr` → Quantum / Classical |
| `src/Codegen.{cpp,h}` | rewrite-input → output string (Clang-free, pure) |
| `src/DeclStmtRewrite.{cpp,h}` | `DeclStmt` → SourceRange + replacement |
| `src/CastRewrite.{cpp,h}` | `CStyleCastExpr` → `cq_measure_si32(…)` (Phase 1 addition) |
| `src/Matcher.{cpp,h}` | MatchFinder wiring + frontend action |

## Build

Normally built as part of the top-level project — the top-level
`CMakeLists.txt` includes this directory as a sub-build:

```bash
cmake -S .. -B ../build \
  -DCMAKE_C_COMPILER=clang-19 -DCMAKE_CXX_COMPILER=clang++-19 \
  -DLLVM_DIR=/usr/lib/llvm-19/lib/cmake/llvm \
  -DClang_DIR=/usr/lib/llvm-19/lib/cmake/clang
cmake --build ../build --target quantum_transpiler -j
```

The standalone-configure path (`cmake -S transpiler -B transpiler/build`)
still works for rewriter-only iteration; the top-level path is the default.

## Targets

- `quantum_transpiler` — the libtooling driver. Reads a C source file,
  writes the rewritten C to stdout.
  Usage: `quantum_transpiler <input.c> -- -std=c11 -I<include-dir>`.
- `quantum_transpiler_lib` — static library holding the reusable modules.
  Linked into the driver and the unit-test binary.
- `quantum_transpiler_unit_tests` — GoogleTest binary covering each module
  (Phase 1's L2 layer per [PLAN.md §5](../phases/phase1/PLAN.md)).
- `check-quantum` — CMake target running the full ctest sweep:
  ```bash
  cmake --build ../build --target check-quantum
  ```

## Running tests

```bash
# Full sub-suite for this subproject
ctest --test-dir ../build --output-on-failure -R "unit_tests|e2e_fixtures"

# Just unit goldens (L2 of the Phase 1 test pyramid)
ctest --test-dir ../build --output-on-failure -R unit_tests

# Just the v1-repointed rewriter-only e2e (input.c -> expected.c diff)
ctest --test-dir ../build --output-on-failure -R e2e_fixtures
```

End-to-end acceptance (transpile + lower + compile + run, with byte-exact
trace-log goldens) is owned by [`tests/e2e/`](../tests/e2e/), driven by
[`tools/cqc`](../tools/cqc) — `ctest -R e2e` from the top-level build.

## Running one fixture by hand

Fixtures under [`tests/e2e/fixtures/`](tests/e2e/fixtures/) (note: the
`transpiler/tests/e2e/` ones, not the top-level acceptance set) are the
v1-era rewriter goldens repointed to Phase 1's emission. Each is a
directory with `input.c` and `expected.c`.

```bash
./../build/transpiler/quantum_transpiler \
  tests/e2e/fixtures/04_q_plus_q/input.c -- -std=c11 -I../include
```

Output goes to stdout. To diff against the golden:

```bash
diff -u tests/e2e/fixtures/04_q_plus_q/expected.c \
  <(printf '%s\n' "$(../build/transpiler/quantum_transpiler \
       tests/e2e/fixtures/04_q_plus_q/input.c -- -std=c11 -I../include)")
```

Available fixtures: `01_uninit`, `02_init_literal`, `03_init_classvar`,
`04_q_plus_q`, `05_q_plus_literal`, `06_q_plus_classvar`, `07_multi_decl`.
(`08_full_example` migrated to top-level `tests/e2e/fixtures/full_example/`
since it gates the full pipeline rather than the rewriter alone.)

## Layout

```
transpiler/
  CMakeLists.txt         sub-build config; finds LLVM/Clang from the top-level cache
  src/                   modules listed above
  tests/
    unit/                GoogleTest per module
    e2e/
      run_e2e.sh         iterates fixtures, diffs against expected.c
      fixtures/          01..07 v1-repointed rewriter goldens
```
