# Phase 1 PRD — New intrinsic surface in `CQ.h`

Phase-specific design decisions, deliverables, and done criteria for
the rewrite of `include/CQ.h` from the old-design `quantum`-keyword
macro to the taint-driven intrinsic surface.

Companion documents:
- [`ROADMAP.md`](../../../ROADMAP.md) §Phase 1 — phase scope and place
  in the sequence.
- [`docs/frontend.md`](../../frontend.md) §3 — the canonical intrinsic
  surface specification this PRD operationalizes.
- [`docs/rationale/proposal-taint-driven-pipeline.md`](../../rationale/proposal-taint-driven-pipeline.md)
  — the motivation behind retiring the old surface.

---

## 1. Scope

**In scope.**
- Rewrite `include/CQ.h` end-to-end with the taint-driven intrinsic
  surface.
- Delete `include/cq_mid.h` outright.
- Land Stage 1 IR smoke fixtures asserting symbol emission for each
  specialization × family, for common `<stdint.h>` typedefs, and for
  the manual-inversion markers across `-O0`/`-O1`/`-O2`/`-O3`.
- Fix the `docs/frontend.md` §4 example IR snippet (uses `@cq_theta_i32`)
  to match the canonical suffix table (`@cq_theta_si32`).

**Out of scope.** Listed in §5 below; the load-bearing exclusion is
"no IR-pass code changes."

---

## 2. Design decisions

Each decision below was resolved during the PRD-discovery discussion
and is binding for the implementation.

### 2.1 Suffix scheme — `docs/frontend.md` §3.1 table is canonical

The 14 suffixes are `_i1`, `_c`, `_si8`, `_ui8`, `_si16`, `_ui16`,
`_si32`, `_ui32`, `_sl`, `_ul`, `_sll`, `_ull`, `_f32`, `_f64`.
Signed/unsigned distinction encoded at the frontend; runtime ABI is
width-only (signedness stripped by the IR pass in Phase 2+).

The IR snippet at `docs/frontend.md:312` showing `@cq_theta_i32` is a
typo against this table and is corrected as part of this phase.

### 2.2 Platform-dependent `long` / `long long`

The frontend keeps `_sl` and `_sll` as separate `_Generic` arms (C
treats them as distinct types regardless of platform). On LP64, both
Clang-lower to LLVM `i64` at IR; on LLP64, `_sl` → `i32`, `_sll` → `i64`.
The frontend mirrors the platform's native C widths; quantum variables
contain the same bit count as the corresponding classical variables.
The width-only runtime ABI collapses the distinction at the
`cqrt_*` boundary. Smoke fixtures baseline against Linux x86_64 LP64.

### 2.3 `include/cq_mid.h` — delete outright

No deprecation alias. The file existed only to declare the
`qint_mid_t` struct family and `cq_init_*` intrinsics, both of which
the new design eliminates. `#include <cq_mid.h>` after this phase
produces a vanilla "file not found" diagnostic; that is sufficient
signal.

### 2.4 `cq_invert_*` survival mechanism

Two-level structure:

```c
/* Marker declarations — bare extern, no attributes. LLVM cannot prove
   an unknown extern is side-effect-free, so calls survive elimination
   at every -O level. */
void __cq_invert_begin(void);
void __cq_invert_end  (void);

/* User-facing macros — bracket the call with an asm-volatile memory
   barrier so the marker stays at its source position even under -O2/-O3
   code motion (LICM, hoisting, sinking). */
#define cq_invert_begin()  do { __cq_invert_begin(); \
                                __asm__ __volatile__("" ::: "memory"); \
                           } while (0)
#define cq_invert_end()    do { __asm__ __volatile__("" ::: "memory"); \
                                __cq_invert_end(); \
                           } while (0)
```

The `asm volatile("" ::: "memory")` is a compiler-only barrier (no
emitted code) telling LLVM the statement reads/writes all memory.
Loads, stores, and function calls cannot be reordered across it.
Optimization impact is bounded to the immediate vicinity of inversion
regions: code outside brackets optimizes normally; code inside brackets
loses some local reordering opportunities, which is the intended
semantics (the IR pass needs the gate sequence preserved as written).

The IR pass in Phase 7 identifies markers by the symbol names
`__cq_invert_begin` / `__cq_invert_end` and erases them; before Phase 7
runs they remain in the IR for inspection.

### 2.5 `extern "C"` guards

The 42 family decls and the two marker decls are wrapped in
`#ifdef __cplusplus extern "C" { ... } #endif`. The `_Generic` macros
and the `cq_invert_*` macros sit outside the guard (they're
preprocessor constructs, language-agnostic). C++ consumers (current and
future test harnesses, tooling) get unmangled symbols without
boilerplate.

### 2.6 Hand-write the 42 decls

CQ.h is the user-facing surface, scheduled for v1.0 freeze at Phase 10.
Legibility outweighs DRY: the final file is ~150–200 lines, read
end-to-end once, then frozen. `tools/gen_templates.py` continues to
drive `runtime/cq_templates.h` (backend-internal, ~700 declarations,
large surface where autogen earns its keep).

### 2.7 Test framework — LIT + FileCheck

New `tests/frontend/` subdirectory with its own `lit.cfg.py`,
`lit.site.cfg.py.in`, and `CMakeLists.txt`, patterned after
`ir-pass/test/`. Root `CMakeLists.txt` adds the subdir and exposes a
`check-frontend` target. Fixtures are `.c` files with RUN-lines:

```
// RUN: %clang -O1 -emit-llvm -include CQ.h -S %s -o - | FileCheck %s
```

### 2.8 `_Generic` stdint coverage

Smoke fixtures lock in the expected dispatch behavior on the canonical
toolchain (Linux x86_64 LP64, glibc/musl). Typedef coverage:
`int8_t`, `int16_t`, `int32_t`, `int64_t`, `uint8_t`–`uint64_t`,
`size_t`, `intptr_t`, `uintptr_t` (11 typedefs total). The contract:
"common stdint typedefs dispatch through their C-standard underlying
type." Non-conforming libcs fall back to user-side `(int)` casting;
that is documented as a known limitation, not a project commitment.

### 2.9 `docs/frontend.md` §4 docfix

Single edit: `@cq_theta_i32` → `@cq_theta_si32` in the example IR
snippet. The neighboring `@cq_template_add_i32_hl` and
`@cqrt_alloc_i32` are correct as-is (width-only runtime ABI).

---

## 3. Deliverables

### 3.1 `include/CQ.h` — rewrite

File structure (top-to-bottom):

1. Header guard `CQ_H_`.
2. `#include <stdbool.h>`, `#include <stdint.h>`.
3. `extern "C"` open brace (guarded by `__cplusplus`).
4. 14 `cq_theta_<sfx>` decls.
5. 14 `cq_phi_<sfx>` decls.
6. 14 `cq_measure_<sfx>` decls.
7. 2 marker decls (`__cq_invert_begin`, `__cq_invert_end`).
8. `extern "C"` close brace.
9. 3 `_Generic` dispatch macros (`cq_theta`, `cq_phi`, `cq_measure`).
10. 2 marker wrapper macros (`cq_invert_begin`, `cq_invert_end`).
11. Header guard close.

Removed: the `quantum` keyword macro.

### 3.2 `include/cq_mid.h` — deletion

`git rm include/cq_mid.h`. No replacement, no alias.

### 3.3 `tests/frontend/` — test scaffold

- `tests/frontend/lit.cfg.py` — LIT configuration, patterned after
  `ir-pass/test/lit.cfg.py`. Defines `%clang`, FileCheck path,
  fixture-discovery glob.
- `tests/frontend/lit.site.cfg.py.in` — CMake-substituted variant.
- `tests/frontend/CMakeLists.txt` — adds `check-frontend` target,
  invokes `lit` against the fixture directory.
- Root `CMakeLists.txt` — `add_subdirectory(tests/frontend)`.

### 3.4 Smoke fixtures

Five `.c` files in `tests/frontend/`:

| Fixture | RUN-lines | FileCheck patterns |
|---|---|---|
| `cq_theta_smoke.c` | 1 (`-O1`) | 14 — one per type suffix, asserts `@cq_theta_<sfx>` symbol |
| `cq_phi_smoke.c` | 1 (`-O1`) | 14 — symmetric to `cq_theta_smoke.c` |
| `cq_measure_smoke.c` | 1 (`-O1`) | 14 — symmetric to `cq_theta_smoke.c` |
| `cq_stdint_dispatch.c` | 1 (`-O1`) | 11 — one per stdint typedef, asserts the expected `_si*` / `_ui*` / `_sl` / `_ul` / `_sll` / `_ull` symbol per LP64 |
| `cq_invert_markers_survive.c` | 4 (`-O0`, `-O1`, `-O2`, `-O3`) | 2 per RUN — asserts `@__cq_invert_begin` and `@__cq_invert_end` both appear, in source order, in the emitted IR |

Fixture-file aggregation (3 files per family rather than 42 separate
files) keeps the directory listing manageable while preserving
per-symbol FileCheck granularity. A single failed FileCheck line
identifies the exact missing symbol.

### 3.5 Documentation edit

`docs/frontend.md:312` — change `@cq_theta_i32` to `@cq_theta_si32`.

---

## 4. Done criteria

Phase 1 is complete when ALL of the following hold:

1. `include/CQ.h` matches the structure in §3.1; `grep -n 'quantum\|cq_init\|qint_mid_t'` returns no hits.
2. `include/cq_mid.h` is absent from the working tree.
3. `docs/frontend.md` §4 example IR uses `@cq_theta_si32`.
4. `cmake --build <build> --target check-frontend` (or equivalent
   `ninja check-frontend`) passes locally and in CI.
5. All five fixtures in `tests/frontend/` are green:
   - 14 specializations × 3 families covered (42 FileCheck patterns
     across the three `*_smoke.c` files).
   - 11 stdint typedefs covered.
   - Both markers survive at each of `-O0`/`-O1`/`-O2`/`-O3` in source
     order.
6. `ir-pass/test/` LIT suite remains green (Phase 1 makes no IR-pass
   code changes; old-design `.ll` fixtures still drive the unchanged
   pass).

---

## 5. Out of scope

Deferred to subsequent phases per `ROADMAP.md`:

- **IR-pass code changes.** Phase 2 repoints `TaintPropagation` from
  `@cq_init_*` to `@cq_theta_*` and introduces gate-triggered
  allocation. Phase 1 does not touch `ir-pass/src/`.
- **`ir-pass/test/*.ll` fixture repointing.** Phase 2 owns this
  transition; Phase 1 leaves the old-design `.ll` files in place,
  green against the still-old-pointed IR pass.
- **Runtime symbol additions.** `cqrt_ry_<W>`, `cqrt_rz_<W>` etc.
  land in Phase 2 alongside the pass change; Phase 1 does not touch
  `runtime/`.
- **End-to-end / link-time validation.** Phase 1 verifies Stage 1
  only (Clang frontend → bitcode); no linking, no runtime execution.
  Phase 9 owns the end-to-end harness.
- **`cqc` driver updates.** The driver continues to invoke the old
  pipeline; the new pipeline replaces it after Phase 2 lands.

---

## 6. Sequencing and commit shape

Single PR, four commits in this order:

1. **PRD commit** — `docs/prd/README.md` + this file. Lands first so
   review can start from the design.
2. **Header rewrite + cq_mid.h deletion + docfix** — `include/CQ.h`
   end-to-end, `include/cq_mid.h` removed, `docs/frontend.md` §4 edit.
   The load-bearing change.
3. **Test scaffold** — `tests/frontend/lit.cfg.py`,
   `lit.site.cfg.py.in`, `CMakeLists.txt`, root CMake wiring.
   No fixtures yet; `check-frontend` runs zero tests and exits clean.
4. **Smoke fixtures** — the five `.c` files. With this commit
   `check-frontend` runs the full suite and gates merge.

Rationale for not splitting further: Phase 1 is ~250 lines of new
content plus one deletion plus one docfix. Splitting (3) and (4) into
separate PRs introduces more review overhead than it saves.

---

## 7. Risks

### 7.1 `_Generic` toolchain divergence

A non-glibc / non-musl libc could define `int32_t` as `signed long` on
some target where `int` and `long` are both 32-bit; the `_Generic` arm
for `int` would miss and the typedef fixture would fail. Mitigation:
Phase 1 baselines against the canonical Linux x86_64 LP64 toolchain
documented in
[`bd remember build-env-cmake-3-31-6-clang-19`](../../../). Exotic
targets are deferred to a post-freeze portability matrix.

### 7.2 `asm volatile` barrier portability

GCC-style inline asm is supported by Clang on every target the project
cares about (x86_64, aarch64). MSVC needs a different barrier
mechanism (`_ReadWriteBarrier()` or similar) — Phase 1 does not target
MSVC; if a future Windows port lands, the barrier macro grows a
toolchain `#ifdef`.

### 7.3 Future-Clang DCE of bare-extern markers

If a future Clang release becomes aggressive enough to flag unknown
externs as removable (it should not under C-standard semantics, but
optimization passes evolve), the marker-survival fixtures catch the
regression immediately because they run at all four `-O` levels.

---

## 8. Open items to resolve before merge

- **`bd` issue tracking granularity.** Either one umbrella issue
  ("Phase 1: new intrinsic surface in CQ.h") with the four commits as
  the closing comment, or four small issues per commit unit. To be
  decided before implementation begins.
- **`ROADMAP.md` cross-link.** A one-line edit in ROADMAP §Phase 1
  pointing at this PRD ("See [`docs/prd/phase-01-intrinsic-surface/PRD.md`](docs/prd/phase-01-intrinsic-surface/PRD.md)
  for the resolved design.") lands with commit 1 or commit 2 — minor
  housekeeping decision.
