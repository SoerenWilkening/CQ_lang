# CQ_lang — Quantum-C Transpiler

A clang-libtooling source-to-source transpiler that rewrites variables marked
with a `quantum` attribute (and `+` expressions involving them) into calls
against a small runtime API. v1 is a proof-of-pipeline; the runtime is a
stub (see [`qint.h`](qint.h)).

See [`ROADMAP.md`](ROADMAP.md) for the phase trajectory.
v1 spec lives in [`phases/v1/PRD.md`](phases/v1/PRD.md) and its implementation
plan in [`phases/v1/PLAN.md`](phases/v1/PLAN.md).

## How it works (one-screen tour)

Input ([`example_v1.c`](example_v1.c)):

```c
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    quantum int a = 3, b = 2;
    quantum int c = a + b;
    quantum int d = a + 5;
    return 0;
}
```

Output of `quantum_transpiler example_v1.c -- -std=c11`:

```c
#include "qint.h"
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    qint_t a = init_qint(3, 16); qint_t b = init_qint(2, 16);
    qint_t c = add(a, b);
    qint_t d = add(a, init_qint(5, 16));
    return 0;
}
```

The rewritten file compiles with any C compiler against the bundled `qint.h`.

---

## Prerequisites

CMake ≥ 3.20, an LLVM/Clang **dev install** (libtooling headers, not just the
compiler binary), GoogleTest, and a build tool (Ninja or make).

### macOS (Homebrew)

```bash
brew install llvm cmake googletest ninja zstd
xcode-select --install   # for /usr/bin/make and the macOS SDK headers
```

Apple's Xcode-bundled `clang` doesn't ship the libtooling/AST dev libraries —
Homebrew's `llvm` package does.

Resolve your LLVM prefix once per shell session:

```bash
export LLVM_PREFIX=$(brew --prefix llvm)
# Apple Silicon: /opt/homebrew/opt/llvm
# Intel Mac:     /usr/local/opt/llvm
```

The codebase is exercised against LLVM 19 on Linux but builds cleanly on
LLVM 22 too (see [Troubleshooting](#troubleshooting) for the one API drift).
If you want a known-good version, `brew install llvm@19` and use
`LLVM_PREFIX=$(brew --prefix llvm@19)`.

### Ubuntu / Debian

```bash
sudo apt-get install -y \
  clang-19 libclang-19-dev llvm-19-dev libclang-cpp19-dev \
  cmake build-essential libgtest-dev libzstd-dev
```

LLVM's CMake configs live at `/usr/lib/llvm-19/lib/cmake/{llvm,clang}`.

---

## Build

### macOS

```bash
cmake -S transpiler -B transpiler/build -G Ninja \
  -DCMAKE_C_COMPILER="$LLVM_PREFIX/bin/clang" \
  -DCMAKE_CXX_COMPILER="$LLVM_PREFIX/bin/clang++" \
  -DLLVM_DIR="$LLVM_PREFIX/lib/cmake/llvm" \
  -DClang_DIR="$LLVM_PREFIX/lib/cmake/clang" \
  -DCMAKE_OSX_SYSROOT="$(xcrun --show-sdk-path)"
cmake --build transpiler/build -j
```

`CMAKE_OSX_SYSROOT` is required so Homebrew clang++ finds the macOS SDK's C
headers alongside libc++ — without it the build fails with errors like
`<cwchar> tried including <wchar.h> but didn't find libc++'s <wchar.h> header`.

### Linux

```bash
cmake -S transpiler -B transpiler/build \
  -DCMAKE_C_COMPILER=clang-19 -DCMAKE_CXX_COMPILER=clang++-19 \
  -DLLVM_DIR=/usr/lib/llvm-19/lib/cmake/llvm \
  -DClang_DIR=/usr/lib/llvm-19/lib/cmake/clang
cmake --build transpiler/build -j
```

Produces:

| Target                            | What it is                                   |
| --------------------------------- | -------------------------------------------- |
| `transpiler/build/quantum_transpiler`           | The libtooling driver                      |
| `transpiler/build/quantum_transpiler_unit_tests`| GoogleTest binary covering each module     |
| `check-quantum` (CMake target)    | `cmake --build … --target check-quantum` runs the full ctest suite |

---

## Run

### Transpile a single file

```bash
./transpiler/build/quantum_transpiler example_v1.c -- -std=c11
```

The rewritten C goes to stdout. Everything after `--` is forwarded to clang's
parser. Redirect to a file with `> out.c`.

### Compile and execute the rewritten output

`qint.h` lives at the repo root; pass `-I.` so the inserted
`#include "qint.h"` resolves:

```bash
./transpiler/build/quantum_transpiler example_v1.c -- -std=c11 > /tmp/out.c
cc -std=c11 -I. /tmp/out.c -o /tmp/example
/tmp/example
```

Apple Clang or GCC both work — the rewritten output is plain C. Expected
stdout (for `example_v1.c`) is in
[`example_v1.expected.log`](example_v1.expected.log).

### One-shot acceptance check

[`transpiler/tests/e2e/acceptance.sh`](transpiler/tests/e2e/acceptance.sh)
does transpile + diff against the golden `.c` + compile + run + diff against
the golden log:

```bash
./transpiler/tests/e2e/acceptance.sh ./transpiler/build/quantum_transpiler .
```

Prints `ACCEPTANCE OK` on success.

### Run all tests

```bash
cd transpiler/build && ctest --output-on-failure
```

Four ctests: `smoke_help`, `unit_tests`, `e2e_fixtures` (8 fixtures),
`acceptance`. Filter with `-R`:

```bash
ctest --output-on-failure -R unit_tests
ctest --output-on-failure -R e2e_fixtures
ctest --output-on-failure -R acceptance
```

### Try one specific e2e fixture

```bash
./transpiler/build/quantum_transpiler \
  transpiler/tests/e2e/fixtures/04_q_plus_q/input.c -- -std=c11
```

…then `diff` against `expected.c` in the same directory.

---

## Project layout

```
CQ_lang/
├── ROADMAP.md                   phase-by-phase trajectory
├── README.md                    this file
├── qint.h                       stub backend (qint_t, init_qint, add)
├── example_v1.c                 canonical input
├── example_v1.expected.c        golden rewritten output
├── example_v1.expected.log      golden runtime stdout
├── main.c                       unrelated sandbox (not touched)
├── phases/
│   └── v1/
│       ├── PRD.md               spec (what v1 does)
│       └── PLAN.md              implementation plan (how, by phase)
└── transpiler/
    ├── CMakeLists.txt
    ├── README.md                transpiler-internal build notes
    ├── src/                     modules — TypeMap, QuantumAttr, SourceText,
    │                            OperandClass, Codegen, DeclStmtRewrite,
    │                            Matcher, main.cpp
    └── tests/
        ├── unit/                GoogleTest, one file per module
        └── e2e/
            ├── run_e2e.sh       fixture-diff runner
            ├── acceptance.sh    PRD acceptance criteria 2-4
            └── fixtures/        8 fixtures (input.c + expected.c each)
```

---

## Troubleshooting

**`gmake: No such file or directory`** during configure on macOS — install
Xcode Command Line Tools (`xcode-select --install`) or just use Ninja
(`-G Ninja`).

**`'clang/Rewrite/Core/RewriteBuffer.h' file not found`** — newer LLVM
folded `RewriteBuffer` into `Rewriter.h`. The code already includes
`Rewriter.h`; you shouldn't see this on HEAD.

**`no type named 'RewriteBuffer' in namespace 'clang'`** — LLVM 22 moved
the type to `llvm::`. The code uses `auto` to handle both 19 and 22; pull
HEAD if you still see this.

**`zstd::libzstd_shared` target not found** during CMake configure — install
`libzstd-dev` (Linux) or `brew install zstd` (macOS). The CMakeLists has a
fallback shim but the real package is cleaner.

**Apple Clang vs libtooling Clang mismatch on link** — use Homebrew's
`clang` for both `CMAKE_C_COMPILER` and `CMAKE_CXX_COMPILER`, not just CXX.

**`<cwchar> tried including <wchar.h> but didn't find libc++'s <wchar.h>`**
(or analogous `cstdio`/`cerrno` errors) on macOS — Homebrew clang++ isn't
finding the macOS SDK. Pass `-DCMAKE_OSX_SYSROOT="$(xcrun --show-sdk-path)"`
to the configure command, or `export SDKROOT=$(xcrun --show-sdk-path)`
beforehand.
