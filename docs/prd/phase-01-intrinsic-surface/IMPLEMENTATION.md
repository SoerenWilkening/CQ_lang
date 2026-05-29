# Phase 1 Implementation Plan

Modular, test-driven build plan for the deliverables in
[`PRD.md`](./PRD.md). Each module is small, has an explicit
red→green acceptance gate, and is kept under the 300-LOC ceiling
(largest single module is M1 at ~125 LOC across four files;
largest single file is `include/CQ.h` at ~150 LOC).

Companion documents:
- [`PRD.md`](./PRD.md) — phase scope, design decisions, done criteria
- [`docs/frontend.md`](../../frontend.md) §3 — canonical intrinsic surface
- [`ir-pass/test/CMakeLists.txt`](../../../ir-pass/test/CMakeLists.txt)
  — scaffold pattern reused by M1

---

## 1. Strategy

**Test-driven within a single PR.** Local development order is
test→code: each fixture is written first and watched fail, then the
matching `CQ.h` slice lands and the fixture turns green. Old fixtures
must stay green as each new slice lands. The PR commit history is
re-grouped at the end to satisfy PRD §6 (PRD → header → scaffold →
fixtures), but development never builds the header blind.

**Modular by family.** The three intrinsic families
(`cq_theta`, `cq_phi`, `cq_measure`) and the inversion markers are
developed as independent slices of `CQ.h`. Each slice has its own
fixture; failures point at the responsible slice immediately.

**Reuse, don't reinvent.** The LIT/FileCheck scaffold is a thin
copy-adapt of `ir-pass/test/`. The fixture shape (single-RUN
`-emit-llvm` smoke + per-symbol `CHECK` lines) is the same shape the
IR-pass suite already validates.

---

## 2. Module map

| # | Module | Net new LOC | Files touched |
|---|---|---|---|
| M0 | Pre-flight (baseline + sanity) | 0 | — |
| M1 | LIT scaffold + `check-frontend` target | ~125 | 4 (+1 root CMake edit) |
| M2 | Fixture: `cq_theta_smoke.c` | ~40 | 1 |
| M3 | `CQ.h` slice 1 — theta family + dispatch | ~50 | 1 |
| M4 | Fixture: `cq_phi_smoke.c` | ~40 | 1 |
| M5 | `CQ.h` slice 2 — phi family + dispatch | ~30 | 1 |
| M6 | Fixture: `cq_measure_smoke.c` | ~40 | 1 |
| M7 | `CQ.h` slice 3 — measure family, drop `quantum` macro | ~30 | 1 |
| M8 | Fixture: `cq_stdint_dispatch.c` | ~30 | 1 |
| M9 | Fixture: `cq_invert_markers_survive.c` | ~30 | 1 |
| M10 | `CQ.h` slice 4 — inversion markers + wrapper macros | ~20 | 1 |
| M11 | `cq_mid.h` deletion + `docs/frontend.md` docfix | -112 / +1 | 2 |
| M12 | Final verification + PR commit re-group | 0 | — |
| **Σ** | | ~435 net new | |

Final `include/CQ.h`: ~150 LOC (PRD §2.6 estimate). Largest fixture
file: ~40 LOC. Largest CMake module file:
`tests/frontend/CMakeLists.txt` at ~80 LOC.

---

## 3. Module detail

### M0 — Pre-flight (no code change)

1. Confirm toolchain matches
   `bd remember build-env-cmake-3-31-6-clang-19`: cmake ≥ 3.20,
   clang-19, FileCheck-19, lit (or `python3 -m lit`).
2. Baseline build:
   ```bash
   cmake -S . -B build -DLLVM_DIR=/usr/lib/llvm-19/lib/cmake/llvm
   cmake --build build
   ctest --test-dir build --output-on-failure
   ```
   Record the green-state ctest output — this is the regression
   baseline for PRD §4 done criterion 6 (ir-pass suite stays green).
3. Re-read `docs/frontend.md` §3.1 to internalize the 14-suffix table.
   This table is the source of truth for M3/M5/M7/M8.

**Acceptance.** Baseline build is green; ctest passes with the
existing `ir-pass-lit` (or `ir-pass-shell`) test.

---

### M1 — LIT scaffold + `check-frontend` target

Files (in dependency order):

| File | LOC | Purpose |
|---|---|---|
| `tests/frontend/lit.cfg.py` | ~30 | Substitutions for `%clang`, `%filecheck`; `.c` suffix discovery |
| `tests/frontend/lit.site.cfg.py.in` | ~10 | CMake-substituted variant of the above |
| `tests/frontend/CMakeLists.txt` | ~80 | Resolve clang/FileCheck/lit; emit site config; register `frontend-lit` test + `check-frontend` target |
| `CMakeLists.txt` (root) | +1 | `add_subdirectory(tests/frontend)` |

**Differences vs `ir-pass/test/`:**
- Substitute `%clang` (resolved via `find_program(NAMES clang-19 clang HINTS ${LLVM_TOOLS_BINARY_DIR})`) instead of `%cq-opt`/`%cq-pass`.
- Discover `.c` suffix instead of `.ll`.
- No pass-plugin dependency; no `TARGET CQPass` guard. The scaffold is
  always-real-LIT (no shell fallback) because the dependency surface
  is just clang + FileCheck + lit, all required by the existing build.
- Add the project `include/` directory to the include search path so
  `-include CQ.h` resolves without a `-I` per RUN line. Pass it via a
  third substitution `%cq_include` expanded by the site config from
  `CMAKE_SOURCE_DIR/include`.

**`check-frontend` convenience target.** Custom `cmake --build … --target check-frontend` wraps the same invocation
the registered ctest uses (mirrors `ir-pass-lit`/`check-ir-pass` if
present, otherwise just calls lit directly on the build dir).

**Acceptance.**
- `cmake --build build --target check-frontend` exits 0.
- With zero fixtures present, lit reports "no tests to run" but the
  CMake exit is clean (configure the target with `--allow-empty-suite`
  or guard the `add_test()` until M2 lands the first `.c`).
- `ctest --test-dir build` still includes the ir-pass test and it
  remains green.

---

### M2 — Fixture: `cq_theta_smoke.c` (test-first)

`tests/frontend/cq_theta_smoke.c`. One RUN line, 14 CHECK directives
(one per suffix), each asserting `@cq_theta_<sfx>` appears in the
emitted IR.

Skeleton:

```c
// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

#include <stdbool.h>

void use(void) {
    bool               b   = 0;
    char               c   = 0;
    signed char        sc  = 0;
    /* … 11 more … */
    double             d   = 0;

    (void) cq_theta(b,   0.1);   // CHECK: call {{.*}} @cq_theta_i1(
    (void) cq_theta(c,   0.1);   // CHECK: call {{.*}} @cq_theta_c(
    /* … 12 more, one per suffix in §3.1 order … */
    (void) cq_theta(d,   0.1);   // CHECK: call {{.*}} @cq_theta_f64(
}
```

Notes:
- `(void)` cast suppresses unused-result warnings under `-Wall -Wextra`
  (root `CMakeLists.txt:11` propagates these).
- Returns from extern functions cannot be optimized away (Clang
  can't prove side-effect-freeness), so each call survives `-O1` and
  appears in IR in source order.
- CHECK directives match in sequence; no need for CHECK-DAG.

**Acceptance.** `check-frontend` runs and reports M2 as
FAIL (Clang errors with "implicit declaration of cq_theta"). This
is the expected red state.

---

### M3 — `CQ.h` slice 1: theta family + dispatch

Lands the file skeleton plus the theta surface. Structure (matches
PRD §3.1 ordering):

```c
/* CQ.h — user-facing intrinsic surface (taint-driven design).
 *
 * Three primitive families (cq_theta, cq_phi, cq_measure) and one
 * inversion bracket (cq_invert_begin/_end). See docs/frontend.md §3.
 */
#ifndef CQ_H_
#define CQ_H_

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* cq_theta — Ry(θ) rotation; the sole taint source. */
bool                cq_theta_i1  (bool               x, double angle);
char                cq_theta_c   (char               x, double angle);
signed char         cq_theta_si8 (signed char        x, double angle);
/* … 11 more, exact list from docs/frontend.md §3.1 table … */
double              cq_theta_f64 (double             x, double angle);

#ifdef __cplusplus
}  /* extern "C" */
#endif

#define cq_theta(x, angle) _Generic((x),     \
    bool:               cq_theta_i1,         \
    char:               cq_theta_c,          \
    signed char:        cq_theta_si8,        \
    /* … 10 more … */                        \
    double:             cq_theta_f64         \
)(x, angle)

#endif  /* CQ_H_ */
```

The `extern "C"` brace will be re-opened in M5/M7/M10 to absorb the
remaining decls. The chosen file ordering puts ALL declarations
inside the brace and ALL `_Generic` macros outside, per PRD §2.5.

**Acceptance.**
- M2 fixture passes GREEN.
- `grep -n 'quantum' include/CQ.h` still hits (the old macro stays
  until M7); ir-pass tests stay green (no IR-pass changes).
- Manual: `clang -O1 -emit-llvm -include include/CQ.h -S -x c
  /dev/null -o -` succeeds (header is self-contained).

---

### M4 — Fixture: `cq_phi_smoke.c`

Same shape as M2, suffix-for-suffix. CHECK lines assert
`@cq_phi_<sfx>`.

**Acceptance.** FAIL RED.

---

### M5 — `CQ.h` slice 2: phi family + dispatch

Insert 14 `cq_phi_<sfx>` decls (same parameter shape as theta — `(T,
double)`) inside the `extern "C"` brace. Add `cq_phi` `_Generic`
macro outside the brace.

**Acceptance.**
- M4 fixture GREEN.
- M2 fixture still GREEN.

---

### M6 — Fixture: `cq_measure_smoke.c`

Same shape; CHECK lines assert `@cq_measure_<sfx>`. Each call
becomes `cq_measure(x)` with no angle argument (only operand).

**Acceptance.** FAIL RED.

---

### M7 — `CQ.h` slice 3: measure family + drop `quantum` macro

- Insert 14 `cq_measure_<sfx>` decls (signature: `T cq_measure_<sfx>(T x)`).
- Add `cq_measure` `_Generic` macro.
- **Remove the legacy `#define quantum __attribute__((annotate("quantum")))` line.** Per PRD §2 (in-scope) and §3.1 ("Removed: the `quantum` keyword macro").

**Acceptance.**
- M6 fixture GREEN; M2/M4 still GREEN.
- `grep -n 'quantum' include/CQ.h` returns nothing (PRD §4 done
  criterion 1).

---

### M8 — Fixture: `cq_stdint_dispatch.c`

Locks the `_Generic` resolution behavior for the 11 stdint typedefs
listed in PRD §2.8. Baselined against Linux x86_64 LP64 (`size_t` →
`unsigned long` → `_ul`; `int64_t` → `long` → `_sl` under glibc).

Skeleton:

```c
// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

#include <stddef.h>
#include <stdint.h>

void use(void) {
    int8_t    a; (void) cq_theta(a, 0.1);   // CHECK: call {{.*}} @cq_theta_si8(
    int16_t   b; (void) cq_theta(b, 0.1);   // CHECK: call {{.*}} @cq_theta_si16(
    int32_t   c; (void) cq_theta(c, 0.1);   // CHECK: call {{.*}} @cq_theta_si32(
    int64_t   d; (void) cq_theta(d, 0.1);   // CHECK: call {{.*}} @cq_theta_sl(
    uint8_t   e; (void) cq_theta(e, 0.1);   // CHECK: call {{.*}} @cq_theta_ui8(
    uint16_t  f; (void) cq_theta(f, 0.1);   // CHECK: call {{.*}} @cq_theta_ui16(
    uint32_t  g; (void) cq_theta(g, 0.1);   // CHECK: call {{.*}} @cq_theta_ui32(
    uint64_t  h; (void) cq_theta(h, 0.1);   // CHECK: call {{.*}} @cq_theta_ul(
    size_t    i; (void) cq_theta(i, 0.1);   // CHECK: call {{.*}} @cq_theta_ul(
    intptr_t  j; (void) cq_theta(j, 0.1);   // CHECK: call {{.*}} @cq_theta_sl(
    uintptr_t k; (void) cq_theta(k, 0.1);   // CHECK: call {{.*}} @cq_theta_ul(
}
```

The hardcoded `_sl`/`_ul` choices encode the LP64 baseline (PRD §2.2,
§2.8). On a non-LP64 host this fixture will fail loudly, which is the
intended behavior — the failure points the porter at the documented
known limitation.

**Acceptance.** GREEN with M3+M5+M7 in place (no new code needed —
this fixture only exercises typedef→underlying-type resolution).

---

### M9 — Fixture: `cq_invert_markers_survive.c`

Four RUN lines (`-O0`/`-O1`/`-O2`/`-O3`), two CHECK lines per RUN
(both markers, in source order).

Skeleton:

```c
// RUN: %clang %cq_include -O0 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s
// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s
// RUN: %clang %cq_include -O2 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s
// RUN: %clang %cq_include -O3 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

void use(void) {
    cq_invert_begin();
    cq_invert_end();
}

// CHECK-LABEL: define {{.*}} @use
// CHECK:      call void @__cq_invert_begin()
// CHECK:      call void @__cq_invert_end()
```

CHECK-LABEL pins the search to `@use`'s body so inlining at `-O2/-O3`
cannot accidentally satisfy the assertions from a different caller.

**Acceptance.** FAIL RED at all four `-O` levels.

---

### M10 — `CQ.h` slice 4: inversion markers + wrapper macros

Add inside the existing `extern "C"` brace:

```c
/* Inversion markers — bare extern, no attributes. LLVM cannot prove
   an unknown extern is side-effect-free, so calls survive elimination
   at every -O level (PRD §2.4). */
void __cq_invert_begin(void);
void __cq_invert_end  (void);
```

Add outside the `extern "C"` brace (preprocessor surface):

```c
#define cq_invert_begin()  do { __cq_invert_begin();                       \
                                __asm__ __volatile__("" ::: "memory");     \
                           } while (0)
#define cq_invert_end()    do { __asm__ __volatile__("" ::: "memory");     \
                                __cq_invert_end();                         \
                           } while (0)
```

**Acceptance.** M9 GREEN at all four `-O` levels; all prior fixtures
still GREEN.

---

### M11 — `cq_mid.h` deletion + `docs/frontend.md` docfix

1. `git rm include/cq_mid.h` (PRD §3.2).
2. Edit `docs/frontend.md:312`: `@cq_theta_i32` → `@cq_theta_si32`
   (PRD §3.5; the neighboring `@cq_template_add_i32_hl` and
   `@cqrt_alloc_i32` are correct, do not touch them).

**Acceptance.**
- `test ! -e include/cq_mid.h` (PRD §4 done criterion 2).
- `grep -n '@cq_theta_i32' docs/frontend.md` returns nothing (PRD §4
  done criterion 3).
- `grep -rn 'cq_init\|qint_mid_t\|quantum' include/` returns nothing
  (PRD §4 done criterion 1).
- ir-pass tests stay green — none of them include `cq_mid.h` (they
  consume `.ll` fixtures directly).

---

### M12 — Final verification + PR commit re-group

1. Walk the PRD §4 done-criteria checklist (six items) explicitly.
   Each must be green before pushing.
2. Re-group the local working tree into the four commits PRD §6
   prescribes. Local M-order was test-first; commit order is
   PRD §6 (PRD → header → scaffold → fixtures):

   | Commit | Source modules | Notes |
   |---|---|---|
   | C1: PRD | (this file + `docs/prd/README.md` + PRD.md if not yet committed) | Lands first per PRD §6 |
   | C2: Header rewrite + cq_mid.h delete + docfix | M3 + M5 + M7 + M10 + M11 | The load-bearing change |
   | C3: Test scaffold | M1 | `check-frontend` runs zero tests after this commit |
   | C4: Smoke fixtures | M2 + M4 + M6 + M8 + M9 | Suite goes live |

   Use `git rebase -i` (without `--no-edit`) to re-order, or stage the
   commits in C-order from a fresh branch — pick whichever is cleaner
   given the working state.

3. Push, open PR, verify CI green.

**Acceptance.** PRD §4 checklist fully green; PR pushed.

---

## 4. Verification matrix (mirrors PRD §4)

| PRD §4 criterion | Verified by | Lands at |
|---|---|---|
| 1. `CQ.h` matches §3.1 structure; no `quantum`/`cq_init`/`qint_mid_t` hits | `grep` after M7+M10+M11 | M11 |
| 2. `cq_mid.h` absent | `test ! -e include/cq_mid.h` | M11 |
| 3. `docs/frontend.md` §4 uses `@cq_theta_si32` | `grep` | M11 |
| 4. `check-frontend` passes locally + CI | `cmake --build … --target check-frontend` | M12 |
| 5. All five fixtures green (42 + 11 + 8 patterns) | LIT output | M10 (last fixture turns green) |
| 6. `ir-pass/test/` still green | `ctest --test-dir build -R ir-pass` | M12 (final), re-checked after every module |

The "re-checked after every module" cadence for criterion 6 is the
cheapest insurance against accidental cross-contamination — the
ir-pass suite runs in well under a second.

---

## 5. Risk handling (from PRD §7)

| Risk | Module handling it |
|---|---|
| 7.1 `_Generic` toolchain divergence | M8 baselines LP64; failure is loud + documented |
| 7.2 `asm volatile` barrier portability | M9 RUN-line matrix verifies on the target toolchain; non-Clang/non-GCC ports out of scope |
| 7.3 Future-Clang DCE of bare-extern markers | M9 four-`-O`-level matrix catches regressions on every Clang bump |

No new risks identified beyond PRD §7.

---

## 6. Issue tracking (resolves PRD §8 open item)

**Recommendation:** one umbrella `bd` issue ("Phase 1: new intrinsic
surface in CQ.h") with the 12 modules as a checklist in the
description. Rationale: the modules are small enough that per-module
issues add tracking overhead without adding signal; the umbrella's
checklist gives the same granularity for status reporting without the
per-issue ceremony.

The umbrella issue closes on a single comment that references the
merged PR and pastes the green PRD §4 verification matrix.

Separately, file the `ROADMAP.md` cross-link (PRD §8 second open item)
as a one-line edit landing with C2 or C3 — no issue needed,
housekeeping.

---

## 7. Effort estimate

| Phase | Wall-clock |
|---|---|
| M0 baseline | 10 min |
| M1 scaffold | 60 min (LIT fiddling tends to dominate) |
| M2–M10 red→green cycle (9 modules) | 15 min each ≈ 2h15m |
| M11 deletion + docfix | 5 min |
| M12 verification + commit re-group + PR | 30 min |
| **Total** | **~4 hours active work** |

Estimate excludes CI feedback latency and PR review turnaround.
