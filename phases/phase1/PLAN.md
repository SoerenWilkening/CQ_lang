# CQ_lang Phase 1 — Implementation Plan

> Companion to [`PRD.md`](./PRD.md). The PRD is the contract; this plan is the
> route. Where the two diverge, the PRD wins.
>
> **Style**: modular, test-driven. Every module ≤ 300 LOC where the language
> lets us; tests for a module land *before* its implementation; the e2e
> golden harness is wired up early so partial progress shows visibly.

---

## 0. Reading order

If you are about to start work, read in this order:

1. [`PRD.md`](./PRD.md) — what we are building.
2. This plan, §1 (goals) → §2 (file layout) → §3 (sequencing).
3. The per-module section (§4) for whichever module you claimed in `bd`.
4. §5 (testing strategy) when you sit down to write the test that will
   gate your change.
5. §6 (open-items dispositions) before you bake an implementation
   decision into code — the PRD leaves several items "decided at impl
   time"; this plan recommends positions and explains why.

---

## 1. Goals, principles, non-goals

### 1.1 Goals (from PRD, restated)

A `.c` file of the [`docs/example.md`](../../docs/example.md) shape compiles
end-to-end via `cqc <file>.c -o <file>` through:

1. The libtooling **rewriter** (extended from v1) → `.transpiled.c`.
2. **`clang -O1 -emit-llvm`** → `.bc`.
3. The **CQ IR pass plugin** (productionized from `prototype/cq_pass.cpp`)
   loaded via `opt -load-pass-plugin` → `.lowered.bc`.
4. **`clang`** linking against stub `libcq_runtime` + stub
   `libcq_templates` → binary.

Running the binary emits a deterministic trace log of stub-call lines.
Acceptance is **byte-exact trace match** against goldens — not value
correctness.

### 1.2 Plan principles

- **Modular.** One file = one concern, ≤ 300 LOC where the language and
  test framework permit. The v1 transpiler already nailed this (largest
  source file: 188 LOC); the plan preserves that discipline.
- **Test-first.** For every module: the test that pins its contract
  lands first (red), then the implementation makes it green. The order
  in §3 is chosen so the e2e fixture set goes red early and turns green
  one row at a time as the pipeline fills in.
- **Three test layers, three audiences.** Per PRD §Testing:
  - **Layer 1 (e2e goldens)** — the acceptance contract. One harness,
    many `(input.c, expected.log)` pairs. Failure here is the only thing
    that fails the phase.
  - **Layer 2 (rewriter unit, GTest)** — fast localization when L1 fails
    *before* the IR pass. Pure string-assembly tests + small in-process
    AST tests, modeled on the existing v1 unit suite.
  - **Layer 3 (IR-pass unit, LIT + FileCheck)** — fast localization when
    L1 fails *after* the rewriter. Hand-written `input.ll`, FileCheck
    directives over `opt -load-pass-plugin` output.
- **No drive-by refactors.** The v1 transpiler module split is already
  good (see §2.3). Touch only what the PRD's table-of-changes touches;
  leave the rest. Specifically: `main.cpp`, `QuantumAttr.{cpp,h}`,
  `SourceText.{cpp,h}` are not modified.
- **Track in `bd`, not in this plan.** The work items in §7 are sketches
  for issue titles; the canonical list is `bd list --status=open`.

### 1.3 Non-goals

Explicitly out of scope for Phase 1, listed because someone *will* be
tempted:

- Backend correctness. Stubs are trace-only.
- Any width other than i32. The rewriter is target-aware (see §4.4 for
  `TypeMap`), so it *can* emit `cq_init_i16` against a 16-bit-int
  target, but Phase 1's tests exercise only i32.
- Any operator other than `+`. Pattern table is exhaustive.
- Uncomputation. Suppressed for `main` (PRD §Pipeline). The prototype's
  `cq-uncompute` pass stays in `prototype/`; not productionized.
- Specialization. The prototype's `cq-specialize` stays in `prototype/`.
- Region handling. The prototype's `cq-control` stays in `prototype/`.
- `add_cq_executable()` CMake macro. PRD punts to Phase 11.
- A binary `cqc`. Shell script suffices for Phase 1.
- Real diagnostics. Passive `!dbg` preservation only (`copyMetadata` /
  `setDebugLoc` calls on substituted instructions, as the prototype
  already does).

---

## 2. File layout

### 2.1 New top-level structure after Phase 1

```
CQ_lang/
├── CMakeLists.txt                  ← NEW (§4.1)
├── include/
│   └── CQ.h                        ← NEW (§4.2)
├── runtime/                        ← NEW (§4.3)
│   ├── CMakeLists.txt
│   ├── cq_runtime.h
│   ├── cq_runtime.c
│   ├── cq_templates.h
│   └── cq_templates.c
├── transpiler/                     ← MODIFIED (§4.4)
│   ├── src/                          (see §2.3 for delta)
│   └── tests/unit/                   (goldens repointed)
├── ir-pass/                        ← NEW (§4.5)
│   ├── CMakeLists.txt
│   ├── src/
│   │   ├── CQLoweringPass.cpp
│   │   └── Plugin.cpp
│   ├── include/
│   │   └── CQLoweringPass.h
│   └── test/                         (LIT + FileCheck)
│       ├── CMakeLists.txt
│       ├── lit.cfg.py
│       └── *.ll
├── tools/
│   └── cqc                         ← NEW (§4.6)
├── tests/
│   └── e2e/                        ← NEW (§4.7)
│       ├── run_e2e.sh
│       └── fixtures/<name>/
│           ├── input.c
│           └── expected.log
├── phases/phase1/
│   ├── PRD.md
│   └── PLAN.md                     ← this file
└── prototype/                      ← UNCHANGED (left as architecture proof)
```

### 2.2 Path decisions (resolving a PRD open item)

PRD §"Open items": "Exact path layout for `ir-pass/`, `runtime/`, and
`tests/e2e/`". This plan commits to:

- `ir-pass/` at top level (mirrors the conventional out-of-tree pass-plugin layout).
- `runtime/` at top level, *not* `runtime/libcq_runtime/` — Phase 1 ships
  one runtime variant and one templates variant; subdirectories are
  premature.
- `tests/e2e/` at top level — separate from `transpiler/tests/e2e/`. The
  latter retires (§4.8).
- `tools/cqc` (not `bin/cqc`) — matches the convention that `bin/` is a
  build output, not a source directory.

### 2.3 Existing transpiler modules — what changes

The v1 split is preserved. Two new files; five modified files.

| File | LOC (v1) | Action | Phase 1 LOC est. |
|---|---|---|---|
| `transpiler/src/main.cpp` | 32 | unchanged | 32 |
| `transpiler/src/QuantumAttr.{cpp,h}` | 72 | unchanged | 72 |
| `transpiler/src/SourceText.{cpp,h}` | 55 | unchanged | 55 |
| `transpiler/src/TypeMap.{cpp,h}` | 68 | **rewrite (§4.4.1)** | ≤ 80 |
| `transpiler/src/OperandClass.{cpp,h}` | 69 | unchanged | 69 |
| `transpiler/src/Codegen.{cpp,h}` | 132 | **edit (§4.4.2)** | ≤ 120 |
| `transpiler/src/DeclStmtRewrite.{cpp,h}` | 235 | **edit (§4.4.3)** | ≤ 180 |
| `transpiler/src/CastRewrite.{cpp,h}` | — | **NEW (§4.4.4)** | ≤ 120 |
| `transpiler/src/Matcher.{cpp,h}` | 215 | **edit (§4.4.5)** | ≤ 220 |

Every file is comfortably under the 300-LOC budget. `Matcher.cpp`
is the largest; if it exceeds 250 we split out the cast-callback into a
sibling header.

### 2.4 IR pass module split

`prototype/cq_pass.cpp` is 525 LOC across four passes. Phase 1
productionizes only `cq-lowering` (~200 LOC). The other three passes
stay in the prototype directory.

| File | Phase 1 LOC est. | Responsibility |
|---|---|---|
| `ir-pass/include/CQLoweringPass.h` | ≤ 40 | `CQLoweringPass` struct + public entry |
| `ir-pass/src/CQLoweringPass.cpp` | ≤ 280 | the pass itself: taint, lowering, cleanup |
| `ir-pass/src/Plugin.cpp` | ≤ 50 | `llvmGetPassPluginInfo` registration |

---

## 3. Sequencing

### 3.1 Dependency graph

```
M0 top-level CMake ─┐
                    ├─► M1 CQ.h ──► M4 rewriter ─┐
                    │                            ├─► M6 cqc driver ─► M7 e2e
M2 runtime ─────────┼────────────────────────────┤
M3 templates ───────┤                            │
                    └─► M5 ir-pass ──────────────┘

M8 docs/example.md update — final, after pipeline is green.
```

### 3.2 Recommended landing order

The order is chosen so that **each step adds a testable surface**, and
the e2e harness goes from "not buildable" → "fixtures red" → "fixtures
green" in a way reviewers can watch.

1. **M0 (skeleton CMake)** + **M1 (`CQ.h`)** + **M7-scaffold** (harness
   script + one fixture's `input.c` and `expected.log`, where the
   expected.log is the *target* trace we are building toward — committed
   red). Goal: `ctest` runs; e2e fails with a clear "binary not built"
   message.

2. **M2 (runtime stub)** + **M3 (templates stub)**. Goal: a hand-written
   `.c` file that calls the stubs directly produces the expected.log
   from step 1 when compiled with `clang main.c runtime/*.c`. This
   pins the stub output format **before** any rewriter or IR work.

3. **M5 (IR pass)**. Productionized port of the prototype's cq-lowering.
   Goal: Layer-3 LIT tests green. The pass runs on hand-written
   `input.ll` to produce IR with the right `cqrt_*` / `cq_template_*`
   calls. (Crucial: this validates the pass against the stub-runtime
   ABI defined in step 2 *before* the rewriter exists, so a rewriter
   regression cannot mask an IR-pass regression.)

4. **M4 (rewriter)**. Modified transpiler. Goal: Layer-2 GTest goldens
   updated to the new emission, all green. v1's e2e fixtures get
   *repointed* (their `expected.c` files are rewritten to the new
   emission), still all green.

5. **M6 (`cqc` driver)**. Shell glue between the four stages. Goal: a
   single `cqc input.c -o input` runs the full pipeline.

6. **M7 (e2e fixtures, full set)**. With the pipeline whole, add the
   remaining e2e fixtures (worked-example + mixed-operand + multi-decl
   per PRD acceptance). Goal: all five PRD acceptance criteria.

7. **M8 (`docs/example.md` update)**. Last; the doc has to match what
   actually shipped.

### 3.3 Concurrency

M2/M3 are independent of M1/M5/M4 once the trace-line format is pinned
(step 2 above). M5 is independent of M4. Two reviewers can therefore
parallelize: one drives `runtime/` + `ir-pass/`; the other drives
`transpiler/` modifications. M6 is a one-hour shell-script merge that
both can wait on.

---

## 4. Per-module plans

### 4.1 M0 — top-level `CMakeLists.txt`

**File:** `CMakeLists.txt` (top-level). **LOC budget:** ≤ 80.

**Responsibility:** orchestrate sub-builds and expose `enable_testing()`
so `ctest` runs all three test layers from one tree.

**Interface:** a single top-level configure-and-build:

```bash
cmake -DLLVM_DIR=/usr/lib/llvm-19/lib/cmake/llvm \
      -DClang_DIR=/usr/lib/llvm-19/lib/cmake/clang \
      -B build .
cmake --build build
ctest --test-dir build --output-on-failure
```

**Structure:**

```cmake
cmake_minimum_required(VERSION 3.20)
project(cq_lang C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find LLVM/Clang once, propagate to sub-builds.
find_package(LLVM CONFIG REQUIRED)
find_package(Clang CONFIG REQUIRED)
if(NOT LLVM_VERSION_MAJOR EQUAL 19)
  message(FATAL_ERROR "Phase 1 pins LLVM 19; found ${LLVM_VERSION_MAJOR}")
endif()

enable_testing()

add_subdirectory(runtime)
add_subdirectory(transpiler)
add_subdirectory(ir-pass)
add_subdirectory(tests/e2e)
```

The existing `transpiler/CMakeLists.txt` already finds LLVM/Clang and
builds the transpiler + its unit tests; it stays as-is. The new sibling
`CMakeLists.txt` files (runtime, ir-pass, tests/e2e) follow the same
shape.

**Test:** ctest smoke — `ctest --test-dir build -N` lists all three
suites. No unit test needed; the smoke is "configure and build succeed".

**Acceptance:**
- `cmake -B build .` succeeds against the documented `LLVM_DIR` /
  `Clang_DIR`.
- `cmake --build build` builds every subproject without warnings under
  `-Wall -Wextra`.
- `ctest --test-dir build` runs the three suites (transpiler-unit,
  ir-pass-lit, e2e) — at this point they may fail; the requirement is
  only that they *run*.

---

### 4.2 M1 — `include/CQ.h` and `include/cq_mid.h`

**Files:** `include/CQ.h` (user-facing), `include/cq_mid.h`
(transpiled-C ABI). **LOC budget:** ≤ 30 + ≤ 40.

**Responsibility:** split the surface into the bare minimum a
quantum-algorithm author needs (`CQ.h`) and the intermediate-level ABI
that the rewriter emits into transpiled C (`cq_mid.h`). Authors
`#include <CQ.h>`; they never see or `#include <cq_mid.h>` — the
rewriter inserts it (or `cqc` passes `-include cq_mid.h` at stage 2;
the choice is the rewriter/driver issue's, not this one's).

**Content — `include/CQ.h` (complete):**

```c
/* CQ.h — Phase 1 user-facing header.
 *
 * The minimal surface a quantum-algorithm author needs to `#include`.
 * Just the `quantum` annotation that marks variables for the rewriter
 * to lower. Everything else (qint_mid_t, per-width intrinsics) is a
 * detail of the transpiled C and lives in <cq_mid.h>, which the
 * transpiler emits into its output — algorithm authors never see it.
 */
#ifndef CQ_H_
#define CQ_H_

#define quantum __attribute__((annotate("quantum")))

#endif  /* CQ_H_ */
```

**Content — `include/cq_mid.h` (complete):**

```c
/* cq_mid.h — transpiled-C ABI for Phase 1.
 *
 * Emitted into transpiled output by the rewriter; not part of the
 * user-facing surface in <CQ.h>. Declares the mid-level struct that
 * carries quantum signal at C-source boundaries (`qint_mid_t`) and
 * the per-width frontend intrinsics that clang -O1 -emit-llvm leaves
 * for the cq-lowering IR pass to rewrite into cqrt_ and cq_template_
 * runtime calls.
 *
 * Architecture references: docs/architecture.md §3 (mid-type), §6.1
 * (init), §6.2 (measure).
 */
#ifndef CQ_MID_H_
#define CQ_MID_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct { int32_t val; } qint_mid_t;

qint_mid_t cq_init_i32(int32_t value);
int32_t    cq_measure_i32(qint_mid_t q);

#ifdef __cplusplus
}
#endif

#endif  /* CQ_MID_H_ */
```

**Tests:**
- *L1 (covered by e2e)* — any fixture that `#include <CQ.h>` exercises
  the user-facing header; the transpiled output exercises `cq_mid.h`.
- *Header self-compile smoke* — in `tests/e2e/CMakeLists.txt`, a
  `try_compile` of a one-line file `#include <CQ.h>` and another
  `#include <cq_mid.h>` fails fast on syntax errors.

**Acceptance:**
- A user source `int main(void){ quantum int x = 3; (void)x; return 0; }`
  compiles with `clang -I include -std=c11 -fsyntax-only` against the
  shipped `CQ.h`.
- A transpiled-C source `int main(void){ qint_mid_t a = cq_init_i32(3);
  (void) cq_measure_i32(a); return 0; }` compiles likewise against
  `cq_mid.h`.

**Decisions baked in (vs. PRD/architecture):**
- The split (`CQ.h` user-only, `cq_mid.h` ABI). Algorithm authors should
  see the minimum surface for writing quantum code — `qint_mid_t` and
  the per-width intrinsics are pipeline plumbing, not author-facing
  vocabulary. The rewriter (or the `cqc` driver) is responsible for
  threading `cq_mid.h` into the transpiled C.
- Field type is `int32_t`, not `int`. The PRD architecture §3 says
  `struct { int val; }`; using `int32_t` makes the i32-explicit name
  match (`cq_init_i32`) and removes the ABI ambiguity for cross-target
  builds. Phase 2's other-width siblings will use `int8_t`, `int16_t`,
  `int64_t`, etc.
- Intrinsic decls only — `cq_theta`, `cq_phi`, `cq_when_*`,
  `cq_invert_*` are *not* declared in Phase 1's `cq_mid.h` (PRD §"CQ.h"
  is explicit: "deliberately minimal"). Phase 2 adds them. Forward
  declarations now would be dead surface area.

---

### 4.3 M2 + M3 — `runtime/` (stub trace-only runtime + templates)

**Files:**
- `runtime/cq_runtime.h` — declarations of `cqrt_*`
- `runtime/cq_runtime.c` — implementations
- `runtime/cq_templates.h` — declaration of `cq_template_add_i32`
- `runtime/cq_templates.c` — implementation
- `runtime/CMakeLists.txt` — builds `libcq_runtime` and `libcq_templates`

**LOC budget:** ≤ 120 across all four `.h/.c` files.

#### Symbols and signatures

```c
/* cq_runtime.h */
#include <stdint.h>

int32_t  cqrt_alloc_classical_i32(int32_t value);   /* taint-source lowering */
int32_t  cqrt_measure_i32(int32_t handle);          /* taint-sink lowering */
void     cqrt_free(int32_t handle);                 /* declared, unused in Phase 1 */
```

```c
/* cq_templates.h */
#include <stdint.h>

int32_t  cq_template_add_i32(int32_t lhs_handle, int32_t rhs_handle);
```

**Note on `cq_template_add_i32`'s signature:** resolves PRD open item
"Concrete signature of `cq_template_add_i32`". This plan commits to a
**2-argument, returns-handle** form (see §6.3 for the rationale). The
IR pass emits exactly one such call per tainted `add i32`, and the
returned handle is the SSA replacement for the `add`'s result. No
fresh-alloc preamble; the template owns its own allocation.

#### Trace-line format

Resolves PRD open item "Exact textual format of stub-call trace lines".
This plan commits to one line per call, of the form:

```
<symbol>(<arg1>[, <arg2>...]) -> <return>
```

For the worked example, the trace is exactly:

```
cqrt_alloc_classical_i32(3) -> h0
cqrt_alloc_classical_i32(5) -> h1
cq_template_add_i32(h0, h1) -> h2
cqrt_measure_i32(h2) -> 0
```

Sentinels:
- Each `cqrt_alloc_classical_i32` and `cq_template_add_i32` returns a
  fresh handle from a monotonically incrementing counter (`h0`, `h1`,
  ...). Counter is process-global (a `static int next_handle = 0;` in
  `cq_runtime.c`; `cq_templates.c` calls into `cqrt_alloc_classical_i32`
  no — it has its own counter, exposed via a shared helper to keep
  numbering globally monotonic).
- `cqrt_measure_i32` always returns 0 (PRD: "taint sink (returns 0)").
- `cqrt_free` prints its line, returns void.

**Concrete:** to keep handle numbering monotonic across runtime and
templates without coupling, put the counter behind one symbol —
`cqrt_alloc_handle()` (internal-linkage helper in `cq_runtime.c`).
Both `cqrt_alloc_classical_i32` and `cq_template_add_i32` call it.

#### Tests

- **`runtime/test_trace.c`** — drives the API directly:
  ```c
  int main(void) {
      int h_a = cqrt_alloc_classical_i32(3);
      int h_b = cqrt_alloc_classical_i32(5);
      int h_c = cq_template_add_i32(h_a, h_b);
      cqrt_measure_i32(h_c);
      return 0;
  }
  ```
  Compiled and run as a ctest target; stdout `diff`'d against
  `runtime/test_trace.expected.log` (the four-line trace above). This
  pins the trace format **before** any other module depends on it.

**Acceptance:**
- `make runtime_trace_test && ctest -R runtime_trace_test` passes.
- The four-line trace matches byte-for-byte the expected log committed
  alongside the test.

---

### 4.4 M4 — rewriter modifications

The largest module by surface area. Five files modified, one added.
Sub-sections below cover each.

The architectural change vs. v1: under taint propagation (architecture
§5.2) the rewriter **does not branch on operand quantum-ness** in
arithmetic patterns. All `Form::QuantumPlus*` and `Form::ClassicalPlus*`
distinctions in v1's `Codegen` collapse into a single ".val arithmetic"
emission. The form enum shrinks.

#### 4.4.1 `TypeMap.{cpp,h}` — target-aware width resolution

**LOC budget:** ≤ 80.

**Change:** v1's `numBitsForType` returns hard-coded bit counts (`int`
→ 16, `long` → 32, …) that mismatch real target widths. Phase 1's
emission uses the **intrinsic-name suffix** (`i32`), not a bit count.
Both need rewiring.

**New API:**

```cpp
namespace qct {

// Returns "i1" / "i8" / "i16" / "i32" / "i64" for a quantum-int-shaped
// QualType against the given target. Returns empty string for
// unsupported types (e.g. quantum float in Phase 1).
std::string irWidthSuffix(clang::QualType qt, const clang::TargetInfo &ti);

}  // namespace qct
```

The implementation calls `ti.getIntWidth()`, `ti.getCharWidth()`, etc.
For Phase 1's test fixtures (target = x86_64-linux-gnu), `int` →
`"i32"`. v1's `numBitsForType` is **removed** — no caller in the new
emission path needs the raw bit count.

**Tests (`transpiler/tests/unit/test_type_map.cpp`):**
- v1's bit-count test cases retire.
- New cases: `int` → `"i32"`, `short` → `"i16"`, `char` → `"i8"`,
  `_Bool` → `"i1"`, `long long` → `"i64"`. (Phase 1 *uses* only `i32`
  but the function must be correct for all int widths so Phase 2 has
  no carry-forward debt.)
- One case: float / double → `""` (unsupported in Phase 1).

#### 4.4.2 `Codegen.{cpp,h}` — emission targets

**LOC budget:** ≤ 120 (down from 132 — the form-enum shrinks).

**Change:** the `Form` enum collapses from five values to three. The
QQ/QC/CQ distinctions go away; both quantum-touching adds use the same
".val arithmetic" pattern.

**New `Form`:**

```cpp
enum class Form {
    Uninit,            // `quantum int x;`         → cq_init_<W>(0)
    ClassicalInit,     // `quantum int x = E;`      → cq_init_<W>(E)
    QuantumAdd,        // `quantum int z = X + Y;`  → .val arithmetic on both sides
};
```

**Renderings:**

```
Uninit:         qint_mid_t <name> = cq_init_<W>(0);
ClassicalInit:  qint_mid_t <name> = cq_init_<W>(<initText>);
QuantumAdd:     qint_mid_t <name>; <name>.val = <lhsText> + <rhsText>;
```

For QuantumAdd, **both** operand texts are spliced verbatim, *with*
`.val` appended to quantum operands. The decision of whether to append
`.val` to a given side is made in DeclStmtRewrite via `OperandClass`,
*not* in Codegen — keep Codegen Clang-free, as it already is.

So the actual VarRewriteInput fields for QuantumAdd are
`lhsExpr` and `rhsExpr` (already-decorated strings:
`"a.val"` if quantum, `"5"` if classical), not the v1 split of
`{lhsName, rhsName, lhsText, rhsText}`.

**Tests (`transpiler/tests/unit/test_codegen.cpp`):**
- One test per Form (3 tests):
  - `Uninit` → `qint_mid_t x = cq_init_i32(0);`
  - `ClassicalInit` with `initText="3+f()"` → `qint_mid_t x = cq_init_i32(3+f());`
  - `QuantumAdd` with `lhsExpr="a.val"`, `rhsExpr="b.val"` → `qint_mid_t c; c.val = a.val + b.val;`
  - `QuantumAdd` with mixed: `lhsExpr="a.val"`, `rhsExpr="5"` → `qint_mid_t c; c.val = a.val + 5;`
- Multi-decl test: join two `QuantumAdd`s with the documented separator
  (PRD example uses a single space).
- Width-suffix test: same Uninit case but with width `"i16"` → emission
  contains `cq_init_i16`. (Defends against accidental hard-coding.)

#### 4.4.3 `DeclStmtRewrite.{cpp,h}` — initializer dispatch

**LOC budget:** ≤ 180.

**Change:** the four-way classification in v1's `populateFromInit`
collapses. After classifying operands as Quantum / Classical via
`OperandClass`, the populator emits a `QuantumAdd` form regardless of
which side(s) are quantum — *provided* at least one side is quantum. If
neither side is quantum, fall back to `ClassicalInit` with the whole
binop spliced as text (same as v1's defensive C+C path).

**Concrete:** the new `populateFromInit` keeps the binop-unwrapping loop
v1 already has (peeling `ParenExpr` / `ImplicitCastExpr`), but the
post-classify dispatch is:

```cpp
if (!lhsQ && !rhsQ) {
    // C + C: a "quantum int x = 1 + 2;" — splice the binop verbatim.
    fallbackClassical();
    return;
}
out->form = Form::QuantumAdd;
out->lhsExpr = lhsQ ? (quantumOperandName(lhs.expr) + ".val")
                    : getExprText(lhs.expr, sm, lo);
out->rhsExpr = rhsQ ? (quantumOperandName(rhs.expr) + ".val")
                    : getExprText(rhs.expr, sm, lo);
```

**Width selection:** at the top of `populateFromInit` (after `out->name`
is set), call `qct::irWidthSuffix(vd->getType(), ctx.getTargetInfo())`
and write it to `out->widthSuffix`. Renderers consume this.

**Tests (`transpiler/tests/unit/test_decl_stmt_rewrite.cpp`):**
The v1 tests get repointed (not extended substantially — the input AST
is the same; only the expected replacement string changes). Cases:

- Pattern 1 — `quantum int x;` → `qint_mid_t x = cq_init_i32(0);`
- Pattern 2 — `quantum int x = 7;` → `qint_mid_t x = cq_init_i32(7);`
- Pattern 2 (classvar) — `quantum int x = c;` → `qint_mid_t x = cq_init_i32(c);`
- Pattern 3 — `quantum int z = a + b;` → `qint_mid_t z; z.val = a.val + b.val;`
- Pattern 4 — `quantum int z = a + 5;` → `qint_mid_t z; z.val = a.val + 5;`
- Pattern 4 commuted — `quantum int z = 5 + a;` → `qint_mid_t z; z.val = 5 + a.val;`
- Multi-decl join — `quantum int a = 3, b = 2;` → both decls, joined.
- Defensive: no-quantum-decls early-out unchanged.

#### 4.4.4 `CastRewrite.{cpp,h}` — `(int) q` → `cq_measure_i32(q)` (NEW)

**LOC budget:** ≤ 120.

**Responsibility:** the analog of `DeclStmtRewrite` for the
measurement-as-cast pattern (PRD pattern #5). Pure (Clang-touching only
for AST queries, no Rewriter API calls — that's `Matcher`'s job).

**Interface:**

```cpp
namespace qct {

struct CastRewrite {
    clang::SourceRange range;   // covers the whole CStyleCastExpr
    std::string replacement;    // "cq_measure_i32(<argText>)"
};

std::optional<CastRewrite> buildCastRewrite(const clang::CStyleCastExpr *ce,
                                            const clang::ASTContext &ctx);

}  // namespace qct
```

**Semantics:**
- Match: `CStyleCastExpr` whose subexpression refers (after paren/cast
  peeling) to a `quantum`-annotated `VarDecl`.
- The cast's target type can be `int` (Phase 1's only tested target type)
  or anything compatible by `trunc` / `zext`; the replacement is
  `cq_measure_i32(<argText>)`. The PRD's Pattern 5 emits exactly that;
  Phase 2 will introduce width-discriminated `cq_measure_<W>`.
- Width-narrower casts (e.g. `(short) q` when `q` is `quantum int`)
  also use `cq_measure_i32`; the surrounding C does the truncation
  classically. (Architecture §6.2 paragraph 2.)

**Tests (`transpiler/tests/unit/test_cast_rewrite.cpp`, NEW):**
- `(int) q` where `q` is quantum → `cq_measure_i32(q)`.
- `(int) (q)` — paren in operand stripped, same output.
- `(int) classic` where `classic` is non-quantum → `nullopt` (no rewrite).
- Cast in expression context: `int y = (int) q + 1;` — the cast
  reports its `SourceRange` correctly so `Matcher` substitutes only the
  cast, not the surrounding expression.

#### 4.4.5 `Matcher.{cpp,h}` — register the cast callback, switch include

**LOC budget:** ≤ 220 (currently 215; small additions).

**Change:**

1. Add a second `MatchCallback` for `CStyleCastExpr`, wired to
   `buildCastRewrite`.
2. In `EndSourceFileAction`, replace `#include "qint.h"` with
   `#include <CQ.h>`. PRD §"Marker syntax": "The only surface change
   from v1 here: the `#define quantum …` line moves out of user source
   and into the new CQ.h header."

The matcher pattern for casts:

```cpp
auto castMatcher = m::cStyleCastExpr(
    m::hasSourceExpression(
        m::expr(m::ignoringParenImpCasts(
            m::declRefExpr(m::to(m::varDecl(
                m::hasAttr(clang::attr::Annotate))))))))
    .bind("cast");
```

The callback filters down to `"quantum"` annotation via the existing
`hasQuantumAttr` helper.

**Tests:** unit testing `Matcher.cpp` directly is painful (requires a
running `ClangTool`). Covered by:
- Layer 2 `DeclStmtRewrite` / `CastRewrite` tests for the per-callback
  logic.
- Layer 1 e2e fixtures for the integration.

**Acceptance for M4 overall:**
- All Layer-2 GTest cases green.
- All v1 e2e fixtures (01–08) repointed: `expected.c` files rewritten
  to the new emission, the v1 e2e harness still green.
- One `expected.c` example, for fixture 04_q_plus_q:
  ```c
  #include <CQ.h>
  #define quantum __attribute__((annotate("quantum")))   /* will be retired in step 4.8 */
  int main(void) {
      qint_mid_t a = cq_init_i32(3);
      qint_mid_t b = cq_init_i32(2);
      qint_mid_t c; c.val = a.val + b.val;
      return 0;
  }
  ```
  The `#define quantum` line in the input fixture is retired (§4.8)
  and replaced with `#include <CQ.h>`; the rewriter's prepended
  include is then the only `#include`.

---

### 4.5 M5 — `ir-pass/` (productionized CQ lowering pass)

**Files:** see §2.4. **LOC budget:** ≤ 280 in `CQLoweringPass.cpp` + ≤ 50
in `Plugin.cpp` + ≤ 40 in header.

#### What stays the same as the prototype

The prototype's `CQLoweringPass` (lines 37–233 of `prototype/cq_pass.cpp`)
is structurally correct for Phase 1:

- Forward taint propagation from `@cq_init_i32` returns.
- `extractvalue/insertvalue` cleanup for `qint_mid_t` struct ops.
- Tainted `add i32` → template call substitution.
- `cq_measure` call rewrite to `cqrt_measure`.
- Module-level cleanup of frontend intrinsic declarations after lowering.
- Pass-plugin registration via `LLVM_PLUGIN_API_VERSION` +
  `registerPipelineParsingCallback`.

The port keeps all of that.

#### What changes from the prototype

| Change | Why |
|---|---|
| `cq_measure` → `cq_measure_i32` | Match per-width intrinsic family from CQ.h §6.2. |
| `cqrt_measure` → `cqrt_measure_i32` | Symmetry; runtime ABI commits to per-width too. |
| `cqrt_alloc_i32` (fresh-ancilla) call dropped from add lowering | PRD §"Stub libcq_runtime": "fresh-ancilla allocation is **not** in Phase 1". Replaced by direct `cq_template_add_i32(h_a, h_b) → h_c` (see §6.3). |
| `cqrt_template_add_i32` (prototype) renamed to `cq_template_add_i32` | PRD reserves `cqrt_*` for the runtime; templates are `cq_template_*`. |
| Move into `ir-pass/src/` with proper header / plugin split | Productionize from one .cpp into three files (still well under 300 LOC each). |
| Build with CMake target `CQPass` producing `libCQPass.so` | Phase 1 CMake integration; prototype's CMakeLists already does this — port forward. |
| Drop the other three passes from the file | `cq-uncompute`, `cq-specialize`, `cq-control` stay in `prototype/cq_pass.cpp`. Phase 1's plugin only registers `cq-lowering`. |

#### IR-pass test layer (Layer 3)

**Framework:** LIT + FileCheck. The prototype currently uses shell-script
grep tests; Phase 1 upgrades these to LIT-driven for parallelism and
better failure diagnostics.

**Files:**
- `ir-pass/test/CMakeLists.txt` — configures LIT against the build's
  `CQPass.so` and adds the `ctest` integration via `configure_lit_site_cfg`.
- `ir-pass/test/lit.cfg.py` — boilerplate (search for `*.ll`,
  set substitutions `%cq-opt`, `%cq-pass`).
- `ir-pass/test/lowering_basic.ll` — port of `prototype/test/input.ll`,
  with `; RUN:` and `; CHECK:` directives:
  ```
  ; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | FileCheck %s
  ; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
  ; CHECK:     call i32 @cqrt_alloc_classical_i32(i32 3)
  ; CHECK:     call i32 @cqrt_alloc_classical_i32(i32 5)
  ; CHECK:     call i32 @cq_template_add_i32(
  ; CHECK:     call i32 @cqrt_measure_i32(
  ; CHECK-NOT: cq_init_i32
  ; CHECK-NOT: cq_measure_i32{{[^_]}}
  ; CHECK-NOT: extractvalue
  ; CHECK-NOT: insertvalue
  ; CHECK-NOT: add i32
  ```
- `ir-pass/test/measure_only.ll` — a function with init+measure but no
  add. CHECKs assert no `cq_template_add_i32` is emitted.
- `ir-pass/test/passthrough_no_quantum.ll` — a function with only
  classical `add i32`. CHECKs assert nothing is rewritten.

**Why LIT not shell:** LIT runs each test in isolation with a real
`lit.cfg.py`, integrates with ctest, parallelizes, and gives
line-precise failure diagnostics from FileCheck. The cost is one
small `lit.cfg.py` file and an `lit` binary requirement (already
present with llvm-19-tools).

**Acceptance for M5:**
- `ctest -R ir-pass` (or whatever LIT exposes) runs all `*.ll` tests
  green.
- The Layer 3 tests cover: standard lowering (`lowering_basic.ll`),
  measurement without add, passthrough of classical IR, and the
  edge case where there are no `@cq_init_i32` calls at all (early-out).

---

### 4.6 M6 — `tools/cqc` driver

**File:** `tools/cqc` (executable shell script). **LOC budget:** ≤ 100.

**Responsibility:** the user-facing single command. Orchestrates the
four pipeline stages.

**Interface:**

```bash
cqc <input.c> -o <output>
```

Optional flags worth supporting in Phase 1:
- `--keep-intermediates` — leave `<output>.transpiled.c`, `.bc`,
  `.lowered.bc` in cwd for debugging.
- `--cq-prefix=<dir>` — root of the install (defaults to `$(dirname
  $0)/..`); used to locate `CQ.h`, `libcq_runtime.a`,
  `libcq_templates.a`, `libCQPass.so`, the `quantum_transpiler` binary.
- `--opt=<binary>` — override `opt` (defaults to `opt-19`).
- `--clang=<binary>` — override `clang` (defaults to `clang-19`).

**Structure:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse args → input_c, output, keep_intermediates, prefix, opt, clang.
# (~30 lines of getopt.)

# Stage 1: rewriter
"$prefix/bin/quantum_transpiler" "$input_c" -- \
    -std=c11 -I"$prefix/include" > "$work/transpiled.c"

# Stage 2: clang -O1 -emit-llvm
"$clang" -O1 -emit-llvm -c "$work/transpiled.c" \
    -I"$prefix/include" -o "$work/transpiled.bc"

# Stage 3: opt -load-pass-plugin
"$opt" -load-pass-plugin "$prefix/lib/libCQPass.so" \
    -passes=cq-lowering "$work/transpiled.bc" -o "$work/lowered.bc"

# Stage 4: link
"$clang" "$work/lowered.bc" \
    "$prefix/lib/libcq_runtime.a" \
    "$prefix/lib/libcq_templates.a" \
    -o "$output"

[[ "$keep" == "1" ]] && cp "$work"/* .
```

**Tests:**
- *cqc smoke* (ctest): runs `cqc <fixture>.c -o /tmp/out` for one
  fixture; asserts exit code 0 and `/tmp/out` exists. Doesn't run the
  binary — that's L1's job.

**Acceptance:**
- `cqc tests/e2e/fixtures/worked_example/input.c -o /tmp/out`
  produces `/tmp/out`; `/tmp/out` runs.

---

### 4.7 M7 — `tests/e2e/` (Layer 1)

**Files:**
- `tests/e2e/CMakeLists.txt` — registers each fixture as a ctest case.
- `tests/e2e/run_e2e.sh` — runs `cqc` on a fixture, runs the binary,
  `diff`'s stdout against `expected.log`. Returns exit code per the
  fixture's outcome.
- `tests/e2e/fixtures/<name>/input.c` and `.../expected.log` —
  one per acceptance case.

**LOC budget:** harness ≤ 80 LOC; each fixture's two files combined < 30 LOC.

#### PRD acceptance fixtures (minimum)

PRD §Acceptance criteria #2–#3 require:

| Fixture | Patterns exercised |
|---|---|
| `worked_example/` | docs/example.md Stage 1: init from literal, Q+Q add, measure-as-cast |
| `mixed_operand/` | Q+C add (e.g., `quantum int d = a + 5;`) |
| `multi_decl/` | `quantum int a = 3, b = 2;` |

These three are the **must-have** set. We will also repoint v1's 01–08
into this directory (or retire ones that no longer match — see §4.8).

#### Worked-example expected.log

```
cqrt_alloc_classical_i32(3) -> h0
cqrt_alloc_classical_i32(5) -> h1
cq_template_add_i32(h0, h1) -> h2
cqrt_measure_i32(h2) -> 0
```

#### Mixed-operand expected.log (for `quantum int a = 3; quantum int d = a + 5;`)

```
cqrt_alloc_classical_i32(3) -> h0
cq_template_add_i32(h0, 5) -> h1
```

The rewriter emits `d.val = a.val + 5`. After Clang -O1 + the IR pass,
the tainted `add i32 %a_handle, 5` becomes a call to a **dedicated
runtime entry point** `cq_template_add_i32_hl(%a_handle, i32 5)` whose
trace prints the second arg as a bare integer (no `h` prefix), so the
log line reads `cq_template_add_i32(h0, 5) -> h1`. The Q+Q variant
remains `cq_template_add_i32(h_lhs, h_rhs)` with both args formatted
as handles.

**Resolution of the operand-shape subtlety:** the IR pass dispatches at
lowering time based on LLVM operand kind. If either operand of a tainted
`add i32` is a `ConstantInt` (classical literal, or a classical-var
read folded by Clang's constprop), it calls `cq_template_add_i32_hl`
with operands swapped so the handle is always lhs. Otherwise (both
operands are tainted SSA values, i.e. Q+Q add), it calls the symmetric
`cq_template_add_i32`. The trace-line function name in both cases is
`cq_template_add_i32`; the `_hl` suffix on the C symbol is an
implementation detail (C lacks overloading) and the bare-int vs `h%d`
rendering disambiguates for log readers.

**Never promote a classical operand to a handle** (e.g. by inserting
`cq_init_i32(5)` ahead of the add). A planned future `cq_alloc`
optimization depends on classical operands NOT being materialized as
quantum handles at the IR level — promotion would conflict with it.

#### Multi-decl expected.log (for `quantum int a = 3, b = 2;`)

```
cqrt_alloc_classical_i32(3) -> h0
cqrt_alloc_classical_i32(2) -> h1
```

#### `run_e2e.sh` shape

```bash
#!/usr/bin/env bash
set -euo pipefail
CQC="${1:-./tools/cqc}"
FIXTURES="${2:-$(dirname "$0")/fixtures}"

fail=0
for d in "$FIXTURES"/*/; do
    name=$(basename "$d")
    bin=$(mktemp)
    if ! "$CQC" "$d/input.c" -o "$bin" 2>"$bin.compile.log"; then
        echo "BUILD FAIL: $name"; cat "$bin.compile.log"; fail=1; continue
    fi
    if ! diff -u "$d/expected.log" <("$bin"); then
        echo "TRACE FAIL: $name"; fail=1
    else
        echo "OK: $name"
    fi
done
exit "$fail"
```

**Acceptance:**
- `ctest -R e2e` runs all fixtures green.
- PRD acceptance criteria 1–3 satisfied.

### 4.8 v1 e2e fixtures — repoint, retire, or migrate

PRD §Deliverables → Modified files:
> `transpiler/tests/e2e/` — existing v1 e2e fixtures either repointed to
> the new pipeline (acceptable since they exercise the v1 patterns Phase
> 1 supersedes) or retired with equivalent coverage moving to `tests/e2e/`.

The 8 v1 fixtures (`01_uninit` ... `08_full_example`) all exercise
patterns Phase 1 supersedes. Recommended treatment, **fixture by
fixture**:

| Fixture | Disposition |
|---|---|
| 01_uninit (`quantum int x;`) | Repoint `expected.c` to new emission; keep in `transpiler/tests/e2e/`. v1 harness still exercises the rewriter alone. |
| 02 — 07 | Same as 01. |
| 08_full_example | Retire from v1's e2e; migrate to `tests/e2e/fixtures/full_example/` with `expected.log` (full-pipeline trace) instead of `expected.c`. |

Rationale: keeping rewriter-only goldens under `transpiler/tests/e2e/`
preserves localizable debug aid (PRD calls L2 a "debug aid"); the
worked-example fixture moves up to `tests/e2e/` because it's the
acceptance contract, not a debug aid.

The PRD specifies that any fixture using an unsupported pattern (e.g.,
v1's hypothetical `amplitude(...)`) must be "documented as deferred,
not silently dropped." None of 01–08 uses such patterns — they all map
to the new pipeline cleanly.

---

### 4.9 M8 — `docs/example.md` update

**File:** `docs/example.md`. **LOC budget:** the doc currently is 311
lines; the rewrite is expected to land within ±20 lines (the structure
is already right; only the intrinsic names change).

**Changes per PRD:**

- Stage 1 source: `(int) c` instead of `(int) c → cq_measure` narration.
- Stage 2 transpiled C: emit `cq_init_i32(3)` not `cq_init(3, 16)`
  (per-width family from architecture §6.1 decision 2026-05-22).
- Stage 2 transpiled C: emit `int32_t measured = cq_measure_i32(c);`
  not `int64_t measured = cq_measure(c);` (per-width family from
  architecture §6.2 decision 2026-05-22).
- Stage 2 transpiled C: include `<CQ.h>` (`#include <CQ.h>`), not
  `#include "CQ.h"` — small detail, but consistency.
- CQ.h excerpt: per-width intrinsic surface; remove the
  `cq_alloc` line (removed 2026-05-21 per architecture §6.1
  decision); update `cq_measure` → `cq_measure_i32` etc.
- Stage 3/4 LLVM IR: same — `@cq_init_i32` (already correct in current
  doc), `@cq_measure_i32` (currently `@cq_measure`), no `i32 16`
  width argument (currently has `(i64 3, i32 16)`).

**Tests:** docs aren't auto-tested. Manual review against:
- The architecture decisions of 2026-05-22.
- The actually-shipping `CQ.h`.
- The actual `expected.log` of `tests/e2e/fixtures/worked_example/`.

---

## 5. Testing strategy

### 5.1 Layer matrix

| Layer | Framework | Where | When | What gates phase acceptance |
|---|---|---|---|---|
| L1 e2e | shell `run_e2e.sh` + ctest | `tests/e2e/` | landed last | **yes** — golden trace match |
| L2 rewriter unit | GTest | `transpiler/tests/unit/` | first | no (debug aid), but expected green |
| L3 IR-pass unit | LIT + FileCheck | `ir-pass/test/` | second | no (debug aid), but expected green |
| Smokes | ctest target | each subbuild | every | no, but expected green |

### 5.2 What kills phase acceptance

Per PRD §Acceptance criteria: only L1 e2e + L2 + L3 green is required.
Smoke failures are debugging convenience. So:

1. `cqc <fixture>.c -o <fixture>` builds.
2. Worked-example fixture trace matches golden byte-for-byte.
3. Repointed v1 e2e fixtures still pass (under `transpiler/tests/e2e/`).
4. L2 + L3 green.
5. `docs/example.md` updated to match shipped surface.

### 5.3 Test parallelism + flake hygiene

- Handle counter is **per-process monotonic**. The trace is
  deterministic *within one process* and across runs (no
  multi-threading in stubs). Different fixtures get different processes,
  so handles always start at `h0` per fixture — that's a property the
  goldens rely on. **Do not** make the counter static across processes
  via a temp file.
- `run_e2e.sh` `diff -u`'s actual against expected. No timestamp /
  pid / cwd-dependent output is allowed in the trace.
- LIT tests don't depend on each other; CHECK directives are local to
  one file.

### 5.4 What we are *not* testing in Phase 1

- Correctness of returned values from `cq_template_add_i32`. The trace
  is the contract.
- Multi-process / multi-thread behavior.
- Compile diagnostics. Errors that fall out of Clang or `opt -verify`
  are acceptable surfaces; we don't pin their text.

---

## 6. Open-items dispositions

These resolve the PRD's "Open items (decided in implementation)" list.

### 6.1 Trace-line format

**Decision:** `<symbol>(<args>) -> <return>` per call, one per line, no
trailing whitespace, LF newline. Handle sentinel: `h0, h1, ...`.
Return-void calls (`cqrt_free`) omit ` -> <return>`.

**Rationale:** the simplest format that's parseable by `diff`, doesn't
need quoting, and is what most C trace stubs emit. Matches PRD's
"deterministic sequence of stub-call lines".

### 6.2 Path layout

See §2.2. **Decision:** `ir-pass/`, `runtime/`, `tools/cqc`, `tests/e2e/`
at top level; `include/CQ.h` at top level.

### 6.3 `cq_template_add_i32` signature

PRD: "single template call per `add`; argument shape — handles only?
handles + width? — TBD".

**Decision:** two C symbols, IR-pass dispatch on operand kind.

```c
/* Q+Q (both operands are tainted SSA handles). */
int32_t cq_template_add_i32(int32_t lhs_handle, int32_t rhs_handle);

/* Q+C (rhs is an LLVM ConstantInt — classical literal or
 * const-propagated classical var). */
int32_t cq_template_add_i32_hl(int32_t lhs_handle, int32_t rhs_literal);
```

**Rationale:**
- **Returns a handle.** Avoids inventing a fresh-ancilla intrinsic
  (`cqrt_alloc_i32`) that PRD explicitly excludes from Phase 1. Both
  template entry points own their own allocation and expose only the
  resulting handle to the IR pass.
- **Two C symbols, not one.** A single symbol cannot distinguish
  "rhs is a handle" from "rhs is a literal" at runtime, but the
  trace must — log readers need `(h0, h1)` for Q+Q and `(h0, 5)` for
  Q+C. C has no overloading, so the IR pass picks the symbol at
  lowering time based on whether the LLVM operand `isa<ConstantInt>`.
  The trace-line function name is `cq_template_add_i32` in both cases;
  the `_hl` suffix is C-symbol-name only.
- **Never promote literal → handle.** The dispatch keeps the classical
  operand as a bare integer through the runtime ABI. A planned future
  `cq_alloc` optimization depends on classical operands NOT being
  silently materialized as quantum handles at the IR level — promotion
  would conflict with it.
- **No width parameter.** Width is in the symbol name (`_i32`). Phase 2
  introduces sibling `cq_template_add_i8`, `cq_template_add_i64`, etc.,
  each with its own `_hl` variant for mixed operands.

**Trade-off acknowledged:** in-place vs. out-of-place add semantics is
*explicitly deferred* per PRD. This signature is consistent with either
choice — the runtime can later be reimplemented to mutate `lhs_handle`
in place (Phase 3 + XOR-copy) or to allocate fresh (current Phase 1
stub). The IR-pass-facing ABI does not change.

### 6.4 `opt` pass pipeline

PRD: "`-O1` before our pass, or `mem2reg` + `sroa` only? Cheaper option
may suffice for Phase 1".

**Decision:** `cqc` invokes `clang -O1 -emit-llvm` (full O1) before
`opt -load-pass-plugin -passes=cq-lowering`.

**Rationale:**
- O1 already runs `mem2reg` and `sroa`, plus other cleanups that don't
  hurt taint propagation (`instcombine` may constant-fold, but
  `@cq_init_i32` is non-readnone so its calls survive — see
  architecture B3 / backend.md §B3).
- The prototype's tests already validate behavior under -O1.
- Cheaper to keep one well-trodden flag than to handcraft a pipeline.

### 6.5 Mangling discipline for future intrinsics

PRD: "CQ.h is deliberately minimal in Phase 1; later phases extend."

**Decision:** Phase 1's `CQ.h` ships exactly two intrinsic decls
(`cq_init_i32`, `cq_measure_i32`) and the `quantum` macro + struct.
Future phases extend, not rewrite. No forward-declarations of Phase 2+
intrinsics.

### 6.6 Width-suffix mapping (Phase 1 surface)

Phase 1 only emits `cq_init_i32` and `cq_measure_i32` in tests, but
`TypeMap::irWidthSuffix` returns a correct suffix for every C int
width per the target. This is **policy**, not implementation: tests
exercise i32 only, but the function works for the whole int family.

**Rationale (PRD §"Width resolution"):** "the policy is target-aware so
the rewriter doesn't acquire a Phase-2 carry-forward debt".

---

## 7. Work breakdown (`bd` issue sketches)

Per CLAUDE.md, the canonical work list is in `bd`. The list below is a
**starting set** of issue titles + dependencies — file them with
`bd create` at the start of the phase. They map 1:1 onto the modules in
§4 and the sequencing in §3.2.

| # | Title (suggested) | Module | Blocks | Type |
|---|---|---|---|---|
| 1 | Top-level CMake + subbuild wiring | M0 | 2, 4–6 | task |
| 2 | `include/CQ.h` header | M1 | 3, 4 | feature |
| 3 | Stub `libcq_runtime` (alloc_classical + measure_i32 + free) | M2 | 4, 6 | feature |
| 4 | Stub `libcq_templates` (`cq_template_add_i32`) | M3 | 6 | feature |
| 5 | Runtime trace-format test (4-line worked-example expected.log) | M2 | 6 | task |
| 6 | Productionize `cq-lowering` pass from prototype | M5 | 9 | feature |
| 7 | LIT/FileCheck test harness for `ir-pass/test/` | M5 | — | task |
| 8 | LIT tests: `lowering_basic.ll`, `measure_only.ll`, `passthrough.ll` | M5 | 9 | task |
| 9 | TypeMap: target-aware `irWidthSuffix` | M4.1 | 10 | task |
| 10 | Codegen: collapse Form enum to Uninit / ClassicalInit / QuantumAdd | M4.2 | 11, 12 | task |
| 11 | DeclStmtRewrite: new emission via QuantumAdd | M4.3 | 13 | task |
| 12 | CastRewrite (new module) | M4.4 | 13 | feature |
| 13 | Matcher: register cast callback + switch to `<CQ.h>` include | M4.5 | 14 | task |
| 14 | Repoint v1 e2e goldens to new emission | §4.8 | 15 | task |
| 15 | `tools/cqc` shell driver | M6 | 16 | feature |
| 16 | `tests/e2e/` harness + worked-example fixture | M7 | 17, 18 | feature |
| 17 | `tests/e2e/` mixed-operand + multi-decl fixtures | M7 | 18 | task |
| 18 | docs/example.md update | M8 | — | docs |

Dependencies map to PRD acceptance criteria 1–5. Items 1–8 form the
"plumbing" pre-req for the rewriter modifications (9–14), which gate
the driver and e2e (15–17), which gate the doc (18).

---

## 8. Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `cq_template_add_i32` signature picks up an additional `width` arg later | M | trace goldens churn | Lock the symbol shape via §4.3 *before* the IR pass lands; if Phase 2 needs different signature it's a new sibling intrinsic, not a rename. |
| Per-width intrinsic family creep into Phase 1 | M | scope drift | PRD is explicit: CQ.h minimal; this plan enforces (§4.2 decisions baked in). |
| LIT not available in build env | L | replaceable | Fall back to shell-based grep tests in `ir-pass/test/`; LIT is a quality-of-life upgrade, not a correctness requirement. |
| Handle counter races in parallel ctest runs | L | flake | Counter is per-process; ctest runs one process per test target. Documented at §5.3. |
| Clang's mem2reg/sroa doesn't flatten qint_mid_t as expected at some Clang patchlevel | L | regression | Phase 1 pins LLVM 19; the prototype validated this against 19.1.7. Listed in build-env memory. |
| Repointing v1 e2e fixtures clobbers debug aid | L | low | §4.8 keeps L2 fixtures in `transpiler/tests/e2e/`; only 08_full_example migrates. |
| Trace format diverges between `cqrt_alloc_classical_i32` and the
template's internal allocations | M | golden brittleness | Single shared `cqrt_alloc_handle()` helper; documented at §4.3 trace format. |

---

## 9. Done definition

Phase 1 is done when, in the order PRD §Acceptance criteria lists them:

1. ☐ `cqc <fixture>.c -o <fixture>` builds end-to-end against a local
   LLVM/Clang 19 install, producing a runnable binary, for each fixture
   in `tests/e2e/fixtures/`.
2. ☐ `tests/e2e/fixtures/worked_example/` (the
   [`docs/example.md`](../../docs/example.md) Stage 1 source written
   through CQ.h) builds and runs; its stdout matches
   `expected.log` byte-for-byte.
3. ☐ v1's repointed e2e fixtures (in `transpiler/tests/e2e/`) all
   pass; no fixture silently dropped.
4. ☐ Layer 2 (GTest, `ctest -R unit`) and Layer 3 (LIT, `ctest -R lit`)
   suites green.
5. ☐ `docs/example.md` updated to match Phase 1's intrinsic surface.

Plus the project-wide session-close protocol from `CLAUDE.md`:
all `bd` issues closed or rolled forward, `git push` succeeded.
