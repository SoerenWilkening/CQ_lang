# Quantum-C Transpiler

A clang-libtooling source-to-source transpiler that rewrites C variables marked with a `quantum` attribute (and `+` expressions involving them) into calls against the stub runtime in [`qint.h`](../qint.h). See [PRD.md](../phases/v1/PRD.md) for the rewrite rules and [PLAN.md](../phases/v1/PLAN.md) for the module layout.

## Prerequisites

- **LLVM/Clang dev install >= 16** (tested with 19.1.7). On Ubuntu:
  ```bash
  sudo apt install clang-19 libclang-19-dev llvm-19-dev libclang-cpp19-dev
  ```
- **C++17 host compiler** (gcc/g++ >= 9). On Ubuntu: `sudo apt install build-essential`.
- **CMake >= 3.20.**
- **GoogleTest** for the unit-test binary. On Ubuntu: `sudo apt install libgtest-dev`.
- **`libzstd-dev`** (recommended). LLVM 19's exported `LLVMSupport` target references `zstd::libzstd_shared` as an interface link dependency. [CMakeLists.txt](CMakeLists.txt) ships a shim that lets configure succeed even if `libzstd-dev` is absent, but installing it produces a cleaner build:
  ```bash
  sudo apt install libzstd-dev
  ```

## Configure

CMake locates LLVM/Clang via `find_package(LLVM CONFIG)` / `find_package(Clang CONFIG)`. When the dev install is not on CMake's default search path, point at the directories containing `LLVMConfig.cmake` and `ClangConfig.cmake` explicitly:

```bash
cmake -S transpiler -B transpiler/build \
  -DCMAKE_C_COMPILER=clang-19 -DCMAKE_CXX_COMPILER=clang++-19 \
  -DLLVM_DIR=/usr/lib/llvm-19/lib/cmake/llvm \
  -DClang_DIR=/usr/lib/llvm-19/lib/cmake/clang
```

`-DLLVM_DIR` / `-DClang_DIR` are the standard CMake overrides for relocated dev installs (PLAN section 7 risk register).

## Build

```bash
cmake --build transpiler/build -j
```

## Build targets

- **`quantum_transpiler`** — the libtooling driver executable. Reads a C source file, writes the rewritten C to stdout. Usage: `quantum_transpiler <input.c> -- -std=c11`.
- **`quantum_transpiler_lib`** — static library holding the reusable modules (`TypeMap`, `QuantumAttr`, `SourceText`, `OperandClass`, `Codegen`, `DeclStmtRewrite`, `Matcher`). Linked into both the driver and the unit-test binary.
- **`quantum_transpiler_unit_tests`** — GoogleTest binary covering each module.
- **`check-quantum`** — CMake custom target that runs the full ctest suite:
  ```bash
  cmake --build transpiler/build --target check-quantum
  ```

## Running tests

```bash
# Full suite
cd transpiler/build && ctest --output-on-failure

# Just unit tests
ctest --output-on-failure -R unit_tests

# Just end-to-end fixtures
ctest --output-on-failure -R e2e_fixtures
```

Full-pipeline acceptance (transpile + lower + compile + run) is owned
by the top-level `tests/e2e/` harness rather than this subproject.

## Running a single fixture

Each fixture under [`tests/e2e/fixtures/`](tests/e2e/fixtures) is a directory containing `input.c` and the golden `expected.c`. Transpile manually:

```bash
./transpiler/build/quantum_transpiler \
  transpiler/tests/e2e/fixtures/01_uninit/input.c -- -std=c11
```

Output goes to stdout. To compare against the golden file (the e2e harness adds the trailing newline that command substitution strips):

```bash
diff -u transpiler/tests/e2e/fixtures/01_uninit/expected.c \
  <(printf '%s\n' "$(./transpiler/build/quantum_transpiler \
       transpiler/tests/e2e/fixtures/01_uninit/input.c -- -std=c11)")
```

Substitute any other fixture name (`02_init_literal`, `03_init_classvar`, `04_q_plus_q`, `05_q_plus_literal`, `06_q_plus_classvar`, `07_multi_decl`, `08_full_example`) to exercise a different pattern.

## Repo layout

```
transpiler/
  CMakeLists.txt         build config (finds LLVM/Clang, GoogleTest)
  src/                   driver + library modules
    main.cpp             libtooling entry point
    TypeMap.*            C type -> num_bits
    QuantumAttr.*        VarDecl -> is-quantum predicate
    SourceText.*         Expr -> original source text
    OperandClass.*       Expr -> Quantum | Classical
    Codegen.*            rewrite-input -> output string (pure)
    DeclStmtRewrite.*    DeclStmt -> SourceRange + replacement
    Matcher.*            MatchFinder wiring + frontend action
  tests/
    unit/                GoogleTest module tests
    e2e/
      run_e2e.sh         iterates fixtures, diffs against expected.c
      fixtures/          one directory per PRD pattern + multi-decl
```
