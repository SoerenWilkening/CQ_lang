# CQ_lang — Quantum-C Compiler

CQ extends C with a `quantum` keyword that marks variables as quantum data;
arithmetic on quantum values is compiled, not interpreted. Programs flow
through a four-stage pipeline (libtooling rewriter → Clang → LLVM pass
plugin → link) into binaries that drive a runtime backend.

**Status.** Phase 1 landed (2026-05-24): single-width (`i32`) end-to-end
vertical slice — `quantum int`, classical init, quantum-quantum and mixed
add, measurement-by-cast. See [`ROADMAP.md`](ROADMAP.md) for the phase
trajectory; [`phases/phase1/PRD.md`](phases/phase1/PRD.md) for the Phase 1
contract; [`docs/architecture.md`](docs/architecture.md) for the underlying
pipeline design.

## One-screen tour

Input (`tests/e2e/fixtures/worked_example/input.c`):

```c
#include <CQ.h>

int main(void) {
    quantum int a = 3;
    quantum int b = 5;
    quantum int c = a + b;
    int m = (int) c;
    (void) m;
    return 0;
}
```

Compile and run through the four-stage pipeline:

```bash
tools/cqc tests/e2e/fixtures/worked_example/input.c -o /tmp/worked
/tmp/worked
```

Output (stub trace-only runtime — Phase 1 is a pipeline proof, not a real
quantum backend):

```
cqrt_alloc_classical_i32(3) -> h0
cqrt_alloc_classical_i32(5) -> h1
cq_template_add_i32(h0, h1) -> h2
cqrt_measure_i32(h2) -> 0
```

The trace is the Phase 1 acceptance contract: deterministic, byte-exact
against `expected.log`. The backend isn't connected to a simulator or
hardware yet — that's a post-frontend effort (see ROADMAP §Beyond the
frontend).

## Pipeline

```
  example.c  (#include <CQ.h>; user writes `quantum int ...`)
      │
      ▼
  quantum_transpiler        libtooling rewriter
      │                       quantum int x = N;     → qint_mid_t x = cq_init_i32(N);
      │                       quantum int z = a + b; → qint_mid_t z; z.val = a.val + b.val;
      │                       (int) q                → cq_measure_i32(q)
      ▼
  example.transpiled.c
      │
      ▼
  clang -O1 -emit-llvm      mem2reg + sroa flatten qint_mid_t; taint survives.
      │
      ▼
  example.bc
      │
      ▼
  opt -passes=cq-lowering   CQ IR pass plugin (libCQPass.so)
      │                       forward taint propagation from @cq_init_i32 returns;
      │                       tainted add i32 → cq_template_add_i32(_hl);
      │                       @cq_measure_i32 → cqrt_measure_i32.
      ▼
  example.lowered.bc
      │
      ▼
  clang link                links against libcq_runtime.a + libcq_templates.a
      │
      ▼
  example                   binary; ./example prints the call trace.
```

All four stages are driven by [`tools/cqc`](tools/cqc) under the hood —
users normally just run `cqc input.c -o output`. Pass `--emit-ll` to get
text LLVM IR (`.ll`) at stages 2 and 3 instead of bitcode.

## Prerequisites

LLVM 19 (Phase 1 is pinned via a CMake assertion), CMake ≥ 3.20,
GoogleTest, a recent C++17 host compiler.

### Ubuntu / Debian

```bash
sudo apt-get install -y \
  clang-19 libclang-19-dev llvm-19-dev libclang-cpp19-dev \
  cmake build-essential libgtest-dev libzstd-dev
```

LLVM's CMake configs live at `/usr/lib/llvm-19/lib/cmake/{llvm,clang}`.

### macOS (Homebrew)

```bash
brew install llvm@19 cmake googletest ninja zstd
xcode-select --install   # for /usr/bin/make and the macOS SDK headers
export LLVM_PREFIX=$(brew --prefix llvm@19)
```

Homebrew's `llvm@19` is keg-only; export `LLVM_PREFIX` so `cqc` and CMake
find it without a PATH dance. Apple's bundled `clang` ships without the
libtooling dev libraries — Homebrew's `llvm@19` package does.

## Build

Top-level configure builds every subproject (rewriter, IR pass, runtime,
e2e harness) in one tree. The transpiler is a sub-build, not a standalone
project anymore.

### Linux

```bash
cmake -S . -B build \
  -DCMAKE_C_COMPILER=clang-19 -DCMAKE_CXX_COMPILER=clang++-19 \
  -DLLVM_DIR=/usr/lib/llvm-19/lib/cmake/llvm \
  -DClang_DIR=/usr/lib/llvm-19/lib/cmake/clang
cmake --build build -j
```

### macOS

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_C_COMPILER="$LLVM_PREFIX/bin/clang" \
  -DCMAKE_CXX_COMPILER="$LLVM_PREFIX/bin/clang++" \
  -DLLVM_DIR="$LLVM_PREFIX/lib/cmake/llvm" \
  -DClang_DIR="$LLVM_PREFIX/lib/cmake/clang" \
  -DCMAKE_OSX_SYSROOT="$(xcrun --show-sdk-path)"
cmake --build build -j
```

`CMAKE_OSX_SYSROOT` (or `export SDKROOT=$(xcrun --show-sdk-path)`) is
required so Homebrew clang++ finds the macOS SDK's C headers alongside
libc++.

The build produces:

| Artifact | What it is |
| --- | --- |
| `build/transpiler/quantum_transpiler` | libtooling rewriter binary |
| `build/ir-pass/libCQPass.so` | `opt` pass plugin (registers `cq-lowering`) |
| `build/runtime/libcq_runtime.a` | trace-only runtime (`cqrt_alloc_classical_i32`, `cqrt_measure_i32`, `cqrt_free`) |
| `build/runtime/libcq_templates.a` | trace-only template library (`cq_template_add_i32`, `cq_template_add_i32_hl`) |

The [`tools/cqc`](tools/cqc) shell driver locates all four artifacts under
either an install layout (`<prefix>/{bin,lib,include}`) or the in-tree
build (`<prefix>/build/{transpiler,ir-pass,runtime}`), so it works
directly out of the dev tree.

## Run

### Compile and execute a single program

```bash
tools/cqc tests/e2e/fixtures/worked_example/input.c -o /tmp/worked
/tmp/worked
```

`cqc` options:

- `--keep-intermediates` — leave `<output>.transpiled.c`, `.bc`, and
  `.lowered.bc` next to `<output>` for debugging.
- `--emit-ll` — emit `.ll` (text LLVM IR) instead of `.bc` at stages
  2/3; implies `--keep-intermediates`.
- `--cq-prefix=<dir>` — install/source root (default: parent of `cqc`).
- `--opt=<binary>` / `--clang=<binary>` — override the LLVM tools.
  `LLVM_PREFIX` is honored automatically when set.

### Run all tests

```bash
ctest --test-dir build --output-on-failure
```

The suite covers all three test layers:

| Layer | What | Where | Framework |
| --- | --- | --- | --- |
| L1 e2e | byte-exact trace-log golden per fixture | `tests/e2e/fixtures/*/` | `run_e2e.sh` + ctest |
| L2 rewriter unit | per-module emission goldens | `transpiler/tests/unit/` | GoogleTest |
| L3 IR-pass unit | `opt -load-pass-plugin` output CHECK directives | `ir-pass/test/*.ll` | LIT + FileCheck |

Filter with `-R`:

```bash
ctest --test-dir build -R e2e               # end-to-end fixtures
ctest --test-dir build -R unit_tests        # rewriter unit tests
ctest --test-dir build -R ir-pass           # IR-pass LIT tests
ctest --test-dir build -R runtime_trace     # runtime stub trace pin
ctest --test-dir build -R cqc_smoke         # cqc driver smoke
```

### Run a single fixture by hand

```bash
tools/cqc tests/e2e/fixtures/mixed_operand/input.c -o /tmp/mixed --emit-ll
diff -u tests/e2e/fixtures/mixed_operand/expected.log <(/tmp/mixed)
ls /tmp/mixed.*       # transpiled.c, .ll, lowered.ll — readable intermediates
```

## Project layout

```
CQ_lang/
├── ROADMAP.md                  phase-by-phase trajectory
├── README.md                   this file
├── CMakeLists.txt              top-level orchestration
├── include/
│   ├── CQ.h                    user-facing (just the quantum macro)
│   └── cq_mid.h                transpiled-C ABI (qint_mid_t, cq_init_i32, cq_measure_i32)
├── transpiler/                 libtooling rewriter (modules + unit tests + v1 e2e)
│   └── src/                      TypeMap, QuantumAttr, SourceText, OperandClass,
│                                 Codegen, DeclStmtRewrite, CastRewrite, Matcher, main
├── ir-pass/                    LLVM pass plugin (cq-lowering)
│   ├── src/                      CQLoweringPass.cpp + Plugin.cpp
│   ├── include/                  CQLoweringPass.h
│   └── test/                     LIT + FileCheck (*.ll)
├── runtime/                    trace-only stub runtime + templates
├── tools/cqc                   pipeline driver
├── tests/e2e/                  Phase 1 acceptance fixtures
│   ├── run_e2e.sh
│   └── fixtures/                 worked_example, mixed_operand, multi_decl, full_example
├── docs/                       architecture / backend / examples / design notes
├── prototype/                  Phase 0 architecture-validation prototype (preserved)
└── phases/
    ├── v1/                       PRD/PLAN for the pre-architecture v1
    └── phase1/                   PRD/PLAN for Phase 1
```

## Troubleshooting

**`Phase 1 pins LLVM 19; found <N>`** during configure — the top-level
CMakeLists asserts LLVM 19. Point `-DLLVM_DIR` / `-DClang_DIR` at an
LLVM-19 install; later versions are a Phase 11 concern.

**`zstd::libzstd_shared` target not found** — install `libzstd-dev`
(Linux) or `brew install zstd` (macOS). The top-level CMakeLists has a
shim that lets configure succeed without it, but the real package is
cleaner.

**Apple Clang vs libtooling Clang mismatch on link** — use Homebrew's
`clang` for both `CMAKE_C_COMPILER` and `CMAKE_CXX_COMPILER`, not just
the C++ one.

**`<cwchar> tried including <wchar.h> but didn't find libc++'s <wchar.h>`**
(or analogous `cstdio` / `cerrno` errors) on macOS — Homebrew clang++
isn't finding the macOS SDK. Pass
`-DCMAKE_OSX_SYSROOT="$(xcrun --show-sdk-path)"` to configure, or
`export SDKROOT=$(xcrun --show-sdk-path)` beforehand.

**`cqc: cannot locate <artifact>`** — `cqc` couldn't find one of the
build outputs under `<prefix>`. Pass `--cq-prefix=<repo>` explicitly, or
re-run from a tree where `build/` is a sibling of `tools/`.

**Homebrew `opt-19` / `clang-19` not on PATH** — `cqc` honors
`LLVM_PREFIX`; `export LLVM_PREFIX=$(brew --prefix llvm@19)` is enough.
Alternatively pass `--opt=<path>` / `--clang=<path>` explicitly.
