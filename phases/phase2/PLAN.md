# CQ_lang Phase 2 — Implementation Plan

> Companion to [`PRD.md`](./PRD.md). The PRD is the contract; this plan is the
> route. Where the two diverge, the PRD wins.
>
> **Style**: modular, test-driven. Every module ≤ 300 LOC where the language
> lets us; tests land *before* implementation; existing fixtures act as a
> regression net so Phase 1 stays green while Phase 2 grows around it.

---

## 0. Reading order

1. [`PRD.md`](./PRD.md) — what we are building (and what we explicitly are not).
2. This plan, §1 (principles) → §2 (file layout deltas) → §3 (sequencing).
3. The per-module section (§4) for whichever module you claimed in `bd`.
4. §5 (testing strategy) when you sit down to write the test that gates your change.
5. §6 (open-items dispositions) before pinning a behavior the PRD left to impl.
6. §7 (`bd` issue sketches) when filing or claiming work.

---

## 1. Goals, principles, non-goals

### 1.1 Goal (restated from PRD)

Phase 1's i32 vertical slice generalizes to **14 mid-struct types** (every C
integer width × signedness, `_Bool`, `float`, `double`) without changing the
pipeline shape. Backend stays stub-only. Trace-equivalence remains the
acceptance contract.

### 1.2 Principles

- **Modular, ≤ 300 LOC per source file.** The current largest file is
  `ir-pass/src/CQLoweringPass.cpp` at 395 LOC — **already over budget** —
  and Phase 2 will roughly 5× its per-width logic. Splitting it is a
  prerequisite, not optional. Every other source/header is under 300 and
  must stay there after the additions in §4.
- **Test-first, three layers** (same as Phase 1):
  - **L1 — e2e goldens.** Byte-exact trace match. The acceptance contract.
  - **L2 — rewriter unit (GTest).** Pure string-assembly tests + small
    in-process AST tests, modeled on `transpiler/tests/unit/`.
  - **L3 — IR-pass unit (LIT + FileCheck).** Hand-written `.ll` fragments,
    `opt -load-pass-plugin`, FileCheck directives.
- **Pin the rename first.** Phase 1's `cq_init_i32` / `cq_measure_i32` /
  `cqrt_alloc_classical_i32` → `_si32` / `_si32` / `cqrt_alloc_i32(value)`
  is the riskiest mechanical edit. Do it as **its own module** (M3) with
  every Phase 1 fixture green at the end, before any new-width work begins.
  This keeps the rename's blast radius isolated.
- **Additive, not invasive.** The PRD calls Phase 2 "Phase 1 × N widths."
  Honor that: no new architectural mechanism, no new AST recognition path,
  no QQ/QC dispatch in the rewriter. If you find yourself inventing one,
  stop and re-read PRD §"Rewriter changes" and §"IR pass changes."
- **Track in `bd`, not in this plan.** §7 sketches issue titles; the
  canonical list is `bd list --status=open`. Per `CLAUDE.md`: do not use
  TodoWrite / TaskCreate / markdown todo lists.

### 1.3 Non-goals

- **Backend correctness.** All new `cq_template_*` and `cqrt_*` bodies are
  trace-only `printf` stubs.
- **No new operators beyond `+`.** Phase 3.
- **No copy templates.** Pattern 6 (`quantum T b = a;`) emits the split
  form but no `cq_template_copy_*`; SROA erases it. See PRD §"On
  assignment and surviving operations." Resist the urge to add a copy
  family "for completeness."
- **No diagnostics work.** Mixed-width arithmetic and non-`+` operators
  will fail at IR-pass lowering with opaque "no template" errors. This
  is expected and called out in PRD §"Diagnostics baseline."
- **No control flow, no functions, no inversion, no uncomputation, no
  rotations, no regions.** Each is a later phase.
- **No ROADMAP / docs cleanup.** The CQ.h vs cq_mid.h imprecision and
  `_Complex` placement are deferred to Phase 11 doc-pass per the PRD.

---

## 2. File layout deltas

Phase 2 is overwhelmingly **additive**. The table below names every file
that changes, every file that is new, and every file that is intentionally
left alone. Line counts are current (pre-Phase-2); budgets are post-Phase-2
ceilings.

### 2.1 Headers

| File | Now | Δ | Budget | Notes |
|---|---|---|---|---|
| `include/CQ.h` | 14 | none | n/a | User-facing macro only. Untouched. |
| `include/cq_mid.h` | 31 | grows | ≤ 200 | 14 mid-struct typedefs + 28 intrinsic decls. Stays well under 300. |

### 2.2 Runtime

| File | Now | Δ | Budget | Notes |
|---|---|---|---|---|
| `runtime/cq_runtime.h` | 47 | grows | ≤ 200 | Decl set goes from 4 → 16 symbols (15 + `cqrt_alloc_handle`). |
| `runtime/cq_runtime.c` | 45 | grows | ≤ 250 | Per-width `cqrt_alloc_<W>` + `cqrt_measure_<W>` stubs. Single-line `printf` bodies; comfortably under 300. |
| `runtime/cq_templates.h` | 44 | grows | ≤ 200 | 14 add stubs (Q+Q + Q+C × 7 widths). |
| `runtime/cq_templates.c` | 24 | grows | ≤ 200 | Same — single-line `printf` bodies. |
| `runtime/test_trace.c` | small | grows | ≤ 200 | Exercise every new symbol once for golden-trace coverage. |

### 2.3 Transpiler

| File | Now | Δ | Budget | Notes |
|---|---|---|---|---|
| `src/main.cpp` | 32 | none | n/a | Untouched. |
| `src/QuantumAttr.{cpp,h}` | 46 / 26 | none | n/a | Untouched. Attribute matching is type-agnostic. |
| `src/SourceText.{cpp,h}` | 29 / 26 | none | n/a | Untouched. |
| `src/OperandClass.{cpp,h}` | 38 / 31 | none | n/a | Untouched (operand classification is type-agnostic). |
| `src/Matcher.{cpp,h}` | 255 / 55 | trivial | ≤ 280 | Verify Pattern-6 AST shape lands in the existing `VarDecl + AnnotateAttr` path. No new matchers. |
| `src/TypeMap.{cpp,h}` | 120 / 54 | grows | ≤ 280 / ≤ 120 | Extend table to 14 types; add suffix accessor. |
| `src/DeclStmtRewrite.{cpp,h}` | 200 / 47 | grows | ≤ 280 / ≤ 80 | Keyword recognition: `_Bool` / `bool` / `char` / `short` / `long` / `long long` / `float` / `double` × signedness combos. Pattern-6 detection. **At-risk for 300 LOC.** If it breaches, split keyword-recognition into a new helper (§2.7). |
| `src/Codegen.{cpp,h}` | 86 / 63 | grows | ≤ 200 / ≤ 80 | Suffix-driven `cq_init_<sfx>`; Pattern-6 split-form emission. |
| `src/CastRewrite.{cpp,h}` | 80 / 51 | grows | ≤ 180 / ≤ 80 | Suffix-driven `cq_measure_<sfx>`. |

### 2.4 Transpiler unit tests

| File | Now | Δ | Budget | Notes |
|---|---|---|---|---|
| `tests/unit/test_type_map.cpp` | 169 | grows | ≤ 280 | Already exercises full int family; extend to verify `_Bool` / `float` / `double` and the new suffix accessor. |
| `tests/unit/test_cast_rewrite.cpp` | 206 | grows | ≤ 280 | Per-type measure-rewrite coverage. **At-risk.** If it breaches, split per axis (int / bool / float). |
| `tests/unit/test_decl_stmt_rewrite.cpp` | 254 | **must split** | ≤ 280 each | Phase 2 expands 6 patterns × 14 types; mechanically 14× the current surface. **Split into 3 files** along type axes (§2.7). |
| `tests/unit/test_source_text.cpp` | 224 | none | n/a | Type-agnostic. Untouched. |
| `tests/unit/test_operand_class.cpp` | 220 | none | n/a | Type-agnostic. Untouched. |
| `tests/unit/test_codegen.cpp` | 186 | grows | ≤ 280 | Per-type init + Pattern-6 split-form. **At-risk.** If it breaches, split. |

### 2.5 IR pass

| File | Now | Δ | Budget | Notes |
|---|---|---|---|---|
| `ir-pass/src/CQLoweringPass.cpp` | **395** | **must split** | ≤ 280 (after split) | Pre-Phase-2 split is a prerequisite. See §2.6 for the layout. |
| `ir-pass/src/Plugin.cpp` | 40 | none | n/a | Plugin registration. Untouched. |
| `ir-pass/include/CQLoweringPass.h` | 45 | minor | ≤ 80 | API stays; internal helper headers in §2.6 are private. |

### 2.6 New files

| File | Budget | Concern |
|---|---|---|
| `ir-pass/include/WidthDispatch.h` | ≤ 120 | Public-to-this-pass header: suffix→width table, intrinsic-name builders, struct-name → mid-struct entry. |
| `ir-pass/src/WidthDispatch.cpp` | ≤ 200 | Implementation of the above. Pure tables + string builders; no LLVM API beyond `Type::getIntegerBitWidth` and `Type::isFloatingPointTy`. |
| `ir-pass/src/TaintPropagation.cpp` | ≤ 200 | Forward taint propagation (was inline in CQLoweringPass). Width-parametric: enumerates every `@cq_init_<sfx>` symbol as a source. |
| `ir-pass/include/TaintPropagation.h` | ≤ 60 | API: `propagate(M, sources) → TaintSet`. |
| `ir-pass/src/MidHandleRebind.cpp` | ≤ 200 | Mid-struct → i32-handle SSA rebinding. Width-parametric. |
| `ir-pass/include/MidHandleRebind.h` | ≤ 60 | API: `rebindMids(M, taintSet) → RebindMap`. |
| `ir-pass/src/OpcodeLowering.cpp` | ≤ 280 | `add <W>` / `fadd <W>` → `cq_template_add_<W>(_hl)`. Width-parametric Q+Q vs Q+C dispatch via operand-taint inspection. |
| `ir-pass/include/OpcodeLowering.h` | ≤ 60 | API: `lowerOps(M, taintSet, rebindMap)`. |
| `ir-pass/src/MeasureLowering.cpp` | ≤ 150 | `@cq_measure_<sfx>` → `cqrt_measure_<W>`. |
| `ir-pass/include/MeasureLowering.h` | ≤ 60 | API: `lowerMeasures(M, rebindMap)`. |
| (optional) `transpiler/src/KeywordRecognizer.{cpp,h}` | ≤ 200 / ≤ 60 | Only created if `DeclStmtRewrite.cpp` breaches 300 LOC. Pure string-set membership + canonical-type resolution helper. |
| 14 e2e fixture dirs | n/a | One per mid-struct type, under `tests/e2e/fixtures/types/<sfx>/`. |
| 2 typedef fixture dirs | n/a | `tests/e2e/fixtures/typedef_int8/`, `tests/e2e/fixtures/typedef_uint32/`. |
| 1 shared-handle fixture | n/a | `tests/e2e/fixtures/shared_handle_measure/`. |
| ~22 LIT fixtures | n/a | Under `ir-pass/test/`. |

After the split, `CQLoweringPass.cpp` becomes the thin orchestrator
(declare external symbols, call the four helpers in order, erase dead
inits). Estimated ≤ 200 LOC post-refactor.

### 2.7 At-risk split decisions (deferred)

These files may or may not need splitting depending on how concisely the
implementation lands. The plan is:

1. Implement under the current single-file layout.
2. If a file exceeds 280 LOC during implementation, split per §2.6 fallbacks.
3. **Do not** split prophylactically — premature splits add navigation cost.

The exception is `CQLoweringPass.cpp`, which is already over budget; that
split is mandatory and is its own module (M12, §4.12).

### 2.8 CMake

| File | Now | Δ | Notes |
|---|---|---|---|
| `CMakeLists.txt` (root) | 64 | none | Subdir orchestration. |
| `transpiler/CMakeLists.txt` | 125 | minor | Add any split test files. |
| `ir-pass/CMakeLists.txt` | 71 | grows | Add the new `.cpp` sources from §2.6. |
| `ir-pass/test/CMakeLists.txt` | 131 | grows | Register the ~22 new LIT fixtures. |
| `runtime/CMakeLists.txt` | 36 | none | Existing static-lib targets unaffected. |
| `tests/e2e/CMakeLists.txt` | 37 | grows | Register the 17 new fixture dirs. |

---

## 3. Sequencing

Five stages, gated by green tests. Each stage must be green before the
next begins. Within a stage, modules can run in parallel except where
arrows mark a dependency.

```
Stage A: Foundation (declarations only)
  M1  Pin suffix scheme + open-items dispositions  ──┐
  M2  cq_mid.h growout (14 mid-structs, 28 decls)    │
  M3  Phase 1 rename (i32 → si32)  ◄─────────────────┤
  M4  Runtime header growout                         │
  M5  Template header growout  ──────────────────────┘
                                            │
Stage B: Stub bodies                        ▼
  M6  Runtime bodies (per-width alloc + measure printf)
  M7  Template bodies (per-width add + _hl printf)
                                            │
Stage C: Transpiler generalization          ▼
  M8  TypeMap 14-type table + suffix accessor
  M9  DeclStmtRewrite keyword recognition + Pattern 6
  M10 Codegen suffix-driven init + Pattern-6 split form
  M11 CastRewrite suffix-driven measure
                                            │
Stage D: IR pass refactor + width-parametric  ▼
  M12 CQLoweringPass split (BEHAVIOR-PRESERVING)
  M13 WidthDispatch helper
  M14 TaintPropagation: width-parametric sources
  M15 MidHandleRebind: width-parametric struct table
  M16 OpcodeLowering: per-width add/fadd templates
  M17 MeasureLowering: per-width measure
                                            │
Stage E: Acceptance                          ▼
  M18 Per-type e2e fixtures (14)
  M19 Typedef fixtures (2)
  M20 Shared-handle fixture (1)
  M21 Full-pipeline acceptance run
```

**Stage A → B gate.** After M1–M5: existing Phase 1 fixtures still pass
under the renamed surface (`_si32`). The new symbols exist as
declarations only — no bodies — and link errors are the expected failure
mode for new-width work.

**Stage B → C gate.** After M6–M7: `runtime/test_trace.c` exercises every
new symbol; the golden trace pins every new printf format string. From
this point on, runtime/template stubs are frozen for the rest of Phase 2.

**Stage C → D gate.** After M8–M11: the rewriter can emit
`cq_init_<sfx>` / `cq_measure_<sfx>` / Pattern-6 split for all 14 types,
verified at L2. But the IR pass still doesn't know about the new
suffixes, so e2e is still mostly red (only the existing 4 Phase-1
fixtures and any si32-only new fixture pass).

**Stage D → E gate.** After M12–M17: the pipeline is width-parametric end
to end. The 17 new e2e fixtures should *almost* pass; M18–M21 wire them
up, repoint goldens, and chase down anything the L2/L3 nets missed.

**Phase 2 done.** All six acceptance criteria from PRD §"Acceptance
criteria" satisfied. §9 below restates them.

---

## 4. Per-module plans

Each module has: scope, files, test plan, acceptance gate, LOC budget,
dependencies. Modules are numbered M1..M21 to match §3 sequencing and §7
`bd` issues.

### 4.1 M1 — Pin suffix scheme + open-items dispositions

**Scope.** Decide every "Open items (decided in implementation)" entry
from PRD §"Open items" *before* writing code that bakes the answer in.

**Decisions to pin (recommended defaults; rationale in §6):**

| Item | Default |
|---|---|
| Suffix scheme | PRD table verbatim: `i1` / `c` / `si8` / `ui8` / `si16` / `ui16` / `si32` / `ui32` / `sl` / `ul` / `sll` / `ull` / `f32` / `f64`. |
| `qchar` alloc | Aliases `cqrt_alloc_i8`; no separate `cqrt_alloc_c`. |
| `qint_mid_t` rename | **Keep `qint_mid_t`** — minimizes Phase-1 churn. The init/measure intrinsics rename (`cq_init_i32` → `cq_init_si32`); the typedef does not. |
| Float `_Bool` cast | No special handling. Phase 2's `quantum float` fixture does not exercise `(_Bool)` cast. |
| `<stdbool.h>` `bool` | One e2e fixture using `bool` instead of `_Bool` to lock behavior. |
| Trace text format | `"cqrt_alloc_<sfx>(<value>) -> h<N>"` and `"cq_template_add_<sfx>[_hl](h<a>, h<b>|<lit>) -> h<N>"`. Pinned at M6/M7. |

**Files.** None. Output is the dispositions in §6 of this plan plus the
M2/M6/M7 contract.

**Test plan.** N/A.

**Acceptance gate.** §6 reads cleanly; the team has consensus that
nothing in the M2 / M6 / M7 contracts is going to be relitigated mid-implementation.

**LOC budget.** N/A (plan-only).

**Depends on.** Nothing.

---

### 4.2 M2 — `cq_mid.h` growout

**Scope.** Declare the 14 mid-structs and 28 intrinsic prototypes. Pure
declarative; no implementation.

**Files touched.** `include/cq_mid.h`.

**Contract (excerpt):**

```c
/* Mid-structs */
typedef struct { _Bool              val; } qbool_mid_t;
typedef struct { char               val; } qchar_mid_t;
typedef struct { signed char        val; } qschar_mid_t;
typedef struct { unsigned char      val; } quchar_mid_t;
typedef struct { short              val; } qshort_mid_t;
typedef struct { unsigned short     val; } qushort_mid_t;
typedef struct { int                val; } qint_mid_t;          /* unchanged */
typedef struct { unsigned int       val; } quint_mid_t;
typedef struct { long               val; } qlong_mid_t;
typedef struct { unsigned long      val; } qulong_mid_t;
typedef struct { long long          val; } qlonglong_mid_t;
typedef struct { unsigned long long val; } qulonglong_mid_t;
typedef struct { float              val; } qfloat_mid_t;
typedef struct { double             val; } qdouble_mid_t;

/* Init prototypes (renamed _i32 → _si32; new families per width) */
qbool_mid_t      cq_init_i1(_Bool value);
qchar_mid_t      cq_init_c(char value);
qschar_mid_t     cq_init_si8(int8_t value);
quchar_mid_t     cq_init_ui8(uint8_t value);
/* … all 14 … */

/* Measure prototypes */
_Bool            cq_measure_i1(qbool_mid_t q);
char             cq_measure_c(qchar_mid_t q);
/* … all 14 … */
```

**Test plan.** L2: a single compile-smoke test in
`transpiler/tests/unit/test_cq_mid_compiles.cpp` (or extended onto an
existing test) that `#include`s `cq_mid.h` and asserts each typedef and
prototype is resolvable. This catches typos in the header.

**Acceptance gate.** Header compiles standalone (no missing types, no
duplicate symbols). Smoke test green.

**LOC budget.** ≤ 200.

**Depends on.** M1.

---

### 4.3 M3 — Phase 1 rename (`_i32` → `_si32`)

**Scope.** Rename Phase 1's i32 intrinsic surface to fit the
per-signedness suffix scheme, *without* introducing any new widths or
new behavior. After M3, the entire Phase 1 pipeline still works,
end-to-end, but speaks `_si32` and `cqrt_alloc_i32(value)` instead of
`_i32` and `cqrt_alloc_classical_i32(value)`.

**Files touched.**

- `include/cq_mid.h` — `cq_init_i32` → `cq_init_si32`,
  `cq_measure_i32` → `cq_measure_si32`. (Lands as part of M2 if M2 and
  M3 are done together.)
- `runtime/cq_runtime.h` + `runtime/cq_runtime.c` — collapse
  `cqrt_alloc_classical_i32(value)` and any `cqrt_alloc_i32()`
  fresh-ancilla slot into a single `cqrt_alloc_i32(value)`.
- `runtime/cq_templates.h` + `runtime/cq_templates.c` —
  `cq_template_add_i32` retains its name (the `_i32` suffix is a
  width-only suffix, not signedness-bearing, at the runtime ABI).
- `transpiler/src/Codegen.cpp` + `transpiler/src/CastRewrite.cpp` —
  emit `_si32` instead of `_i32`.
- `ir-pass/src/CQLoweringPass.cpp` — recognize `@cq_init_si32` /
  `@cq_measure_si32` as taint sources/sinks; lower to
  `cqrt_alloc_i32(value)` / `cqrt_measure_i32(handle)`.
- All Phase 1 e2e fixtures (`worked_example`, `mixed_operand`,
  `multi_decl`, `full_example`) — repoint `expected.log` strings.
- All Phase 1 LIT fixtures — repoint `CHECK:` lines.
- All Phase 1 unit-test goldens — repoint expected strings.

**Why a single module.** The rename is mechanical but touches many files.
Doing it as one module makes the diff reviewable and the bisection
unambiguous if something regresses.

**Test plan.**

- L1: every existing Phase 1 e2e fixture passes (byte-exact) under the
  renamed surface.
- L2: every existing Phase 1 rewriter unit test passes (after repointing
  expected strings).
- L3: every existing Phase 1 LIT fixture passes (after repointing
  FileCheck lines).

**Acceptance gate.** `ctest` + `lit` + the e2e harness all green; `git
grep '\bcq_init_i32\b\|\bcq_measure_i32\b\|cqrt_alloc_classical_i32'`
returns zero hits anywhere except possibly a `CHANGELOG.md` note.

**LOC budget.** Pure rename; net LOC change is roughly zero.

**Depends on.** M1 (suffix scheme pinned), M2 (new header decls exist
alongside).

---

### 4.4 M4 — Runtime header growout

**Scope.** Declare the 15 runtime symbols (7 alloc + 7 measure +
`cqrt_free`). No bodies.

**Files touched.** `runtime/cq_runtime.h`.

**Contract.** Verbatim from PRD §"Stub `libcq_runtime`":

```c
int32_t cqrt_alloc_i1(_Bool value);
int32_t cqrt_alloc_i8(int8_t value);
int32_t cqrt_alloc_i16(int16_t value);
int32_t cqrt_alloc_i32(int32_t value);
int32_t cqrt_alloc_i64(int64_t value);
int32_t cqrt_alloc_f32(float value);
int32_t cqrt_alloc_f64(double value);

_Bool   cqrt_measure_i1(int32_t handle);
int8_t  cqrt_measure_i8(int32_t handle);
int16_t cqrt_measure_i16(int32_t handle);
int32_t cqrt_measure_i32(int32_t handle);
int64_t cqrt_measure_i64(int32_t handle);
float   cqrt_measure_f32(int32_t handle);
double  cqrt_measure_f64(int32_t handle);

void    cqrt_free(int32_t handle);
int32_t cqrt_alloc_handle(void); /* internal helper, retained */
```

**Test plan.** Header smoke compile (one TU `#include`s it; the existing
unit-test target links it).

**Acceptance gate.** Header compiles standalone; symbol set matches PRD
exactly.

**LOC budget.** ≤ 200.

**Depends on.** M1.

---

### 4.5 M5 — Template header growout

**Scope.** Declare the 14 template stubs (Q+Q + Q+C × 7 widths).

**Files touched.** `runtime/cq_templates.h`.

**Contract.** Verbatim from PRD §"Stub template library":

```c
int32_t cq_template_add_i1  (int32_t a, int32_t b);
int32_t cq_template_add_i1_hl(int32_t a, _Bool b);
int32_t cq_template_add_i8  (int32_t a, int32_t b);
int32_t cq_template_add_i8_hl(int32_t a, int8_t b);
/* … similarly for i16, i32, i64, f32, f64 … */
```

**Test plan.** Header smoke compile.

**Acceptance gate.** Compiles; symbol set matches PRD.

**LOC budget.** ≤ 200.

**Depends on.** M1.

---

### 4.6 M6 — Runtime stub bodies

**Scope.** Implement every alloc/measure body as a single `printf` line
that matches its golden trace string. Pin the exact format strings —
they become the spec for the rest of Phase 2.

**Files touched.** `runtime/cq_runtime.c`.

**Contract.**

```c
int32_t cqrt_alloc_i1(_Bool v) {
    int32_t h = cqrt_alloc_handle();
    printf("cqrt_alloc_i1(%d) -> h%d\n", (int)v, h);
    return h;
}
/* … one per width. Float trace: %f format; signed/unsigned int trace: %lld with cast. */
```

**Trace conventions (pinned here):**

- Handle prints as `h<N>` (Phase 1 convention).
- Value prints widest-fits: `%lld` (cast `(long long)v`) for ints,
  `%f` for floats, `%d` for `_Bool`.
- One line per call, terminated `\n`.
- No leading whitespace, no extra spacing — `expected.log` golden
  matching is exact.

**Test plan.**

- L1: extend `runtime/test_trace.c` to exercise every new symbol once.
  Lock `test_trace.expected.log` as the runtime-stub golden. This file
  also becomes the canonical reference for what each format string emits.
- L2 (optional): a tiny GTest that captures stdout and asserts the
  per-symbol format string.

**Acceptance gate.** `test_trace` binary's stdout matches its golden,
byte-exact.

**LOC budget.** ≤ 250.

**Depends on.** M3 (alloc collapse already in), M4 (decls exist).

---

### 4.7 M7 — Template stub bodies

**Scope.** Implement every add template as a single `printf` line.

**Files touched.** `runtime/cq_templates.c`.

**Trace conventions.** Same as M6:

```
cq_template_add_i32(h1, h2) -> h3
cq_template_add_i32_hl(h1, 42) -> h2
cq_template_add_f64(h1, h2) -> h3
cq_template_add_f64_hl(h1, 3.140000) -> h2
```

(Note: `_hl` variant carries no signedness in the suffix because, per
PRD §"Width unification at the runtime ABI," signedness is implicit in
the LLVM opcode at the call site.)

**Test plan.** L1 via `runtime/test_trace.c` extension.

**Acceptance gate.** `test_trace` golden green.

**LOC budget.** ≤ 200.

**Depends on.** M3 (`cq_template_add_i32` retained as-is), M5 (decls).

---

### 4.8 M8 — TypeMap 14-type table

**Scope.** Extend the existing target-aware `TypeMap` to cover all 14
types. Add a `suffixFor(QualType)` accessor that returns the
suffix string (`"si32"`, `"f64"`, etc.) used by `Codegen` and
`CastRewrite`.

**Files touched.** `transpiler/src/TypeMap.cpp` + `.h`.

**API additions.**

```cpp
struct TypeMap {
  /* existing */
  llvm::StringRef irWidthSuffix(clang::QualType t) const;  // width-only ("i32")

  /* new */
  llvm::StringRef intrinsicSuffix(clang::QualType t) const;  // ("si32", "f64")
  llvm::StringRef midStructName(clang::QualType t) const;    // ("qint_mid_t", "qfloat_mid_t")
};
```

The split between `irWidthSuffix` (width-only, used by the IR pass via
data-layout reasoning) and `intrinsicSuffix` (signedness-bearing, used
by the rewriter) reflects PRD §"IR pass changes — Width inference":
the IR pass never needs signedness; only the rewriter does.

**Test plan.** Extend `test_type_map.cpp`:

- Per-type lookup of `intrinsicSuffix` against the PRD §"Type map"
  table. 14 cases.
- Per-type lookup of `midStructName`. 14 cases.
- `<stdint.h>` typedef cases: `int8_t`, `uint8_t`, `int16_t`, `uint16_t`,
  `int32_t`, `uint32_t`, `int64_t`, `uint64_t` resolve through
  `getCanonicalType()` to the right underlying entry.
- Target-dependence: under a 64-bit Linux target `long` → `sl` and width
  `i64`; under a Windows or 32-bit target `long` → `sl` and width `i32`.
  (The suffix is platform-stable; the width is not.)

**Acceptance gate.** All new `test_type_map` cases green; no regression
in existing ones.

**LOC budget.** TypeMap.cpp ≤ 280, TypeMap.h ≤ 120,
test_type_map.cpp ≤ 280.

**Depends on.** M1.

---

### 4.9 M9 — DeclStmtRewrite keyword recognition + Pattern 6

**Scope.** Two changes:

1. Extend keyword recognition from `int` only to every quantum-typed
   scalar keyword. The recognizer must handle:
   - Single keywords: `_Bool`, `bool`, `char`, `short`, `int`, `long`,
     `float`, `double`
   - Compound keywords: `signed char`, `unsigned char`, `unsigned short`,
     `unsigned int`, `unsigned long`, `long long`, `signed long long`,
     `unsigned long long`
   - Typedef'd integers from `<stdint.h>` via canonical-type resolution
     (this falls out of `TypeMap` automatically; the recognizer doesn't
     need to enumerate `int8_t` etc.)
2. Detect Pattern 6: a quantum `VarDecl` whose initializer is a
   `DeclRefExpr` to a quantum `VarDecl` of the **same canonical type**.
   Emit a new `VarRewriteInput` variant (`QuantumCopy`) consumed by
   `Codegen` (M10).

**Files touched.** `transpiler/src/DeclStmtRewrite.cpp` + `.h`.

**Risk.** Current file is 200 LOC. Phase 2 adds keyword handling +
Pattern-6 detection. Estimated post-Phase-2 size: 240–290 LOC. If this
breaches 280, split out a `KeywordRecognizer.{cpp,h}` helper (§2.6).

**Test plan.** Extend `test_decl_stmt_rewrite.cpp`:

- Per-type recognition of `quantum T x;` for all 14 types + 2 typedef
  cases (16 fixtures).
- Per-type recognition of `quantum T x = E;` (classical init) for all
  14 types.
- Per-type Pattern-6 detection: `quantum T b = a;` produces
  `QuantumCopy` variant; with a *different-type* `a`, it does **not**
  (it stays as classical-init or fails at lookup).
- Multi-decl: `quantum int a, b = 0;` still works (Phase 1 carry).

**At-risk.** Existing test file is 254 LOC. Doubling the case set will
breach. Plan: **split into three files** along type axes:

- `test_decl_stmt_rewrite_int.cpp` — int family (Phase 1 carry-forward + new int types)
- `test_decl_stmt_rewrite_float.cpp` — `float`, `double`, plus
  `_Bool` (lives here because its recognition path is closest to floats
  in terms of "non-int width")
- `test_decl_stmt_rewrite_pattern6.cpp` — Pattern-6 detection across
  all types

Pre-split if the projected LOC is obvious. Otherwise split once a file
breaches 280.

**Acceptance gate.** All new cases green; multi-decl Phase 1 cases
unchanged.

**LOC budget.** DeclStmtRewrite.cpp ≤ 280 (with optional split);
each new test file ≤ 280.

**Depends on.** M8 (TypeMap available to keyword recognizer).

---

### 4.10 M10 — Codegen suffix-driven init + Pattern-6 split form

**Scope.** Two changes:

1. Replace i32-hardcoded init emission with a `TypeMap`-driven suffix
   lookup. The rendered string is `cq_init_<sfx>(<value>)` where
   `<sfx>` is `TypeMap::intrinsicSuffix(T)`.
2. Implement Pattern-6 rendering: `qT_mid_t b; b.val = a.val;` (a
   compound statement, two lines in the output). **No intrinsic call.**
   The mid-struct name comes from `TypeMap::midStructName(T)`.

**Files touched.** `transpiler/src/Codegen.cpp` + `.h`.

**Test plan.** Extend `test_codegen.cpp`:

- Per-type init rendering against goldens (14 + 2 typedef cases).
- Pattern-6 rendering: input `(QuantumCopy {name: "b", source: "a",
  type: "int"})` → output `qint_mid_t b; b.val = a.val;`.
- Pattern-3/4 (Q+Q and Q+C add) rendering per-type — should fall out
  of the same suffix change.

**Acceptance gate.** All Codegen test cases green; Phase 1 fixtures
still render byte-identical (modulo M3 rename).

**LOC budget.** Codegen.cpp ≤ 200; test_codegen.cpp ≤ 280.

**Depends on.** M8, M9.

---

### 4.11 M11 — CastRewrite suffix-driven measure

**Scope.** Replace i32-hardcoded measure emission with
`TypeMap::intrinsicSuffix(T)`. Rendered string: `cq_measure_<sfx>(<q>)`.

**Files touched.** `transpiler/src/CastRewrite.cpp` + `.h`.

**Test plan.** Extend `test_cast_rewrite.cpp`:

- `(T) q` rewrites to `cq_measure_<sfx>(q)` for each of the 14 types + 2
  typedefs.
- Macro-boundary and source-location preservation (Phase 1 invariants)
  still hold.

**Acceptance gate.** All Cast tests green; existing macro-boundary
fixture unchanged.

**LOC budget.** CastRewrite.cpp ≤ 180; test_cast_rewrite.cpp ≤ 280.

**Depends on.** M8.

---

### 4.12 M12 — `CQLoweringPass` split (behavior-preserving)

**Scope.** Refactor the 395-LOC monolith into the layout described in
§2.6, *without changing behavior*. After M12, the existing Phase 1 LIT
fixtures still pass byte-for-byte.

**Files touched.**
- `ir-pass/src/CQLoweringPass.cpp` — slim to orchestrator (~150 LOC).
- New: `ir-pass/include/WidthDispatch.h`, `ir-pass/src/WidthDispatch.cpp`,
  `ir-pass/include/TaintPropagation.h`, `ir-pass/src/TaintPropagation.cpp`,
  `ir-pass/include/MidHandleRebind.h`, `ir-pass/src/MidHandleRebind.cpp`,
  `ir-pass/include/OpcodeLowering.h`, `ir-pass/src/OpcodeLowering.cpp`,
  `ir-pass/include/MeasureLowering.h`, `ir-pass/src/MeasureLowering.cpp`.
- `ir-pass/CMakeLists.txt` — register new sources.

**Split contract (post-M12, pre-M13 generalization):**

```cpp
PreservedAnalyses CQLoweringPass::run(Module &M, ...) {
  WidthDispatch wd(M);            // i32-only after M12
  auto taint = TaintPropagation::propagate(M, wd);
  auto rebind = MidHandleRebind::rebindMids(M, wd, taint);
  OpcodeLowering::lowerOps(M, wd, taint, rebind);
  MeasureLowering::lowerMeasures(M, wd, rebind);
  eraseDeadInits(M, taint);
  return PreservedAnalyses::none();
}
```

**Critical: this is a refactor only.** Each new module's `i32`-specific
logic moves over **as-is**. Width-parameterization is M13–M17, done in
separate commits so a regression bisects cleanly.

**Test plan.** Every existing LIT fixture passes byte-for-byte after M12,
without modification. If a single CHECK line needs to change, the split
is not behavior-preserving and must be redone.

**Acceptance gate.** Existing 5 LIT fixtures all green, no diff to their
input or check lines.

**LOC budget.** Every new file ≤ 280; CQLoweringPass.cpp ≤ 200.

**Depends on.** M3.

---

### 4.13 M13 — WidthDispatch helper

**Scope.** Implement the suffix→width tables and intrinsic-name builders
in `WidthDispatch`. This becomes the IR pass's parallel to the
rewriter's `TypeMap`.

**Files touched.** `ir-pass/src/WidthDispatch.cpp`,
`ir-pass/include/WidthDispatch.h`.

**API.**

```cpp
class WidthDispatch {
public:
  explicit WidthDispatch(Module &M);

  /* All known intrinsic suffixes, in canonical order. */
  ArrayRef<StringRef> allSuffixes() const;

  /* Suffix ↔ ABI width (LLVM width, after collapse). */
  StringRef abiWidthFor(StringRef sfx) const;          // "si8" → "i8"; "f32" → "f32"
  Type      *llvmTypeFor(StringRef sfx, LLVMContext&) const;

  /* Intrinsic-symbol resolvers. */
  Function  *initFn(StringRef sfx)    const; // @cq_init_<sfx> or nullptr
  Function  *measureFn(StringRef sfx) const; // @cq_measure_<sfx> or nullptr

  /* Runtime-symbol resolvers (lazy-declared if missing). */
  FunctionCallee allocFn(StringRef abiWidth)   const; // @cqrt_alloc_<W>
  FunctionCallee measureRtFn(StringRef abiWidth) const; // @cqrt_measure_<W>

  /* Template-symbol resolvers. */
  FunctionCallee addTemplate(StringRef abiWidth, bool isQQ) const;

  /* Mid-struct recognition. */
  Optional<StringRef> midStructToSuffix(StructType *st) const;
};
```

**Test plan.** L3 LIT fixtures aren't a great fit for testing this helper
directly. Add a small GTest module under
`ir-pass/test/unit/test_width_dispatch.cpp` if `WidthDispatch` ends up
non-trivial; otherwise rely on L3 coverage from M14–M17.

**Acceptance gate.** Used by M14–M17 without modification.

**LOC budget.** WidthDispatch.cpp ≤ 200, .h ≤ 120.

**Depends on.** M12.

---

### 4.14 M14 — TaintPropagation: width-parametric sources

**Scope.** Generalize the taint-source set from `{@cq_init_si32}` to
`{@cq_init_<sfx> for sfx in WidthDispatch::allSuffixes()}`. Propagation
rules unchanged.

**Files touched.** `ir-pass/src/TaintPropagation.cpp`.

**Test plan.** L3 fixtures:
- `ir-pass/test/lowering_taint_*.ll` — one per suffix exercising the
  taint source. Verify the same instructions get tainted regardless of
  width. (Roughly 14 fixtures, can collapse into one parameterized via
  LIT's `%s` substitution if practical.)

**Acceptance gate.** L3 green; M16/M17 don't see untainted-source bugs.

**LOC budget.** TaintPropagation.cpp ≤ 200.

**Depends on.** M12, M13.

---

### 4.15 M15 — MidHandleRebind: width-parametric struct table

**Scope.** Generalize from `qint_mid_t` recognition to all 14
mid-structs via `WidthDispatch::midStructToSuffix`. Rebinding logic
(replace struct-typed SSA value with i32 handle) is unchanged.

**Files touched.** `ir-pass/src/MidHandleRebind.cpp`.

**Test plan.** L3:
- Per-type LIT fixtures showing the rebind output. ~7 fixtures (one per
  ABI width; signedness is invisible at this level).

**Acceptance gate.** L3 green.

**LOC budget.** MidHandleRebind.cpp ≤ 200.

**Depends on.** M12, M13.

---

### 4.16 M16 — OpcodeLowering: per-width add/fadd

**Scope.** Generalize from `add i32` → `cq_template_add_i32(_hl)` to:
- `add iW` → `cq_template_add_iW(_hl)` for W ∈ {1, 8, 16, 32, 64}
- `fadd <fW>` → `cq_template_add_fW(_hl)` for fW ∈ {float, double}

Per-width selection driven by `Type::getIntegerBitWidth()` /
`Type::isFloatTy()` / `Type::isDoubleTy()` on the operand type. Q+Q vs
Q+C dispatch via operand-taint inspection (Phase 1 mechanism, unchanged).

**Files touched.** `ir-pass/src/OpcodeLowering.cpp`.

**Test plan.** L3:
- 7 widths × 2 dispatch variants (Q+Q, Q+C) = 14 LIT fixtures.
- One negative fixture: a `sub i32` instruction in a tainted context
  produces a clean "no template for opcode" failure (Phase 3 will fix
  this; Phase 2 just confirms the failure mode is loud, not silent).

**Acceptance gate.** L3 green; the negative `sub` case produces a
recognizable error string.

**LOC budget.** OpcodeLowering.cpp ≤ 280.

**Depends on.** M12, M13, M14, M15.

---

### 4.17 M17 — MeasureLowering: per-width measure

**Scope.** Generalize from `@cq_measure_si32` only to every
`@cq_measure_<sfx>` in `WidthDispatch::allSuffixes()`. Each lowers to
`cqrt_measure_<W>(handle)` with `W` derived from sfx via
`abiWidthFor`.

**Files touched.** `ir-pass/src/MeasureLowering.cpp`.

**Test plan.** L3:
- 7 ABI widths × 1 fixture = 7 LIT fixtures.

**Acceptance gate.** L3 green.

**LOC budget.** MeasureLowering.cpp ≤ 150.

**Depends on.** M12, M13.

---

### 4.18 M18 — Per-type e2e fixtures (14)

**Scope.** One e2e fixture per mid-struct type. Each fixture covers
Patterns 1, 2, 3, 4, 5, 6 (where applicable for the type).

**Files created.** `tests/e2e/fixtures/types/<sfx>/input.c` +
`expected.log` for each of:
`i1`, `c`, `si8`, `ui8`, `si16`, `ui16`, `si32`, `ui32`, `sl`, `ul`,
`sll`, `ull`, `f32`, `f64` — **14 dirs.**

**Fixture template (excerpt):**

```c
/* tests/e2e/fixtures/types/f32/input.c */
#include <CQ.h>
int main(void) {
  quantum float a = 1.5f;
  quantum float b = a;             /* Pattern 6: no trace line */
  quantum float c = b + 2.5f;      /* Pattern 4 (Q+C) */
  quantum float d = b + c;         /* Pattern 3 (Q+Q) */
  (float) d;                       /* Pattern 5 */
  return 0;
}
```

```
# tests/e2e/fixtures/types/f32/expected.log
cqrt_alloc_f32(1.500000) -> h1
cq_template_add_f32_hl(h1, 2.500000) -> h2
cq_template_add_f32(h1, h2) -> h3
cqrt_measure_f32(h3) -> 0.000000
```

(Note: `b` does **not** appear because Pattern 6 collapses to SSA
aliasing under SROA. This is the load-bearing PRD claim from
§"On assignment and surviving operations.")

**Test plan.** Each fixture is its own L1 acceptance check. The harness
(extant in `tests/e2e/CMakeLists.txt`) runs `cqc` + binary + diff
against golden.

**Acceptance gate.** All 14 fixtures green; bytes match.

**LOC budget.** N/A (fixtures are data).

**Depends on.** M16, M17.

---

### 4.19 M19 — Typedef fixtures (2)

**Scope.** Confirm `<stdint.h>` typedefs flow through canonical-type
resolution end to end.

**Files created.**
- `tests/e2e/fixtures/typedef_int8/input.c` — uses `quantum int8_t`,
  golden identical to `types/si8/expected.log` modulo any width-specific
  literals.
- `tests/e2e/fixtures/typedef_uint32/input.c` — uses `quantum uint32_t`,
  golden identical to `types/ui32/expected.log`.

**Test plan.** L1 acceptance.

**Acceptance gate.** Goldens match their canonical-type counterparts.

**Depends on.** M18.

---

### 4.20 M20 — Shared-handle measurement fixture

**Scope.** Lock in the trace shape for the PRD's "edge case: shared
handle when both `a` and `b` are measured" worked example.

**Files created.** `tests/e2e/fixtures/shared_handle_measure/input.c`:

```c
#include <CQ.h>
int main(void) {
  quantum int a = 5;
  quantum int b = a;
  (int) a;
  (int) b;
  return 0;
}
```

```
# expected.log
cqrt_alloc_i32(5) -> h1
cqrt_measure_i32(h1) -> 0
cqrt_measure_i32(h1) -> 0
```

**Test plan.** L1 acceptance. This fixture's purpose is to prove the
trace shape is *correct as-is* — a future contributor who "fixes" this
by adding a copy template emission has reintroduced a misfeature.
The fixture should carry a `README` or top-of-file comment citing
PRD §"On assignment and surviving operations."

**Depends on.** M18.

---

### 4.21 M21 — Full-pipeline acceptance run

**Scope.** Run the full L1+L2+L3 suite, verify the 6 acceptance criteria
in PRD §"Acceptance criteria," produce a Phase 2 closure summary.

**Files touched.** None (test/release activity).

**Acceptance gate.**

1. ✅ All 14 mid-struct types compile end-to-end for Patterns 1–6.
2. ✅ 14 per-type e2e fixtures byte-exact green.
3. ✅ Typedef fixtures green and identical to canonical counterparts.
4. ✅ All Phase 1 e2e fixtures pass on the renamed surface.
5. ✅ L2 (rewriter unit) + L3 (LIT) green.
6. ✅ No regression in Phase 1 compile-time (informal check, not gated).

**Depends on.** M18, M19, M20.

---

## 5. Testing strategy

### 5.1 Three layers, three audiences (same as Phase 1)

| Layer | Tool | Failure mode | When to use |
|---|---|---|---|
| L1 e2e | `cqc` + binary + diff | Wrong end-to-end behavior | Acceptance contract; the only thing that *fails the phase*. |
| L2 rewriter unit | GTest + fixture goldens | Wrong text emitted by transpiler | Fast localization when L1 fails before the IR pass. |
| L3 IR pass | LIT + FileCheck | Wrong instructions after `opt` | Fast localization when L1 fails after the rewriter. |

### 5.2 Test-first discipline per module

For every module M-N:

1. Write the test(s) that pin the contract. They are **red**.
2. Implement until **green**.
3. Read the diff and prune any helper code the test didn't exercise.

The L1 e2e suite is the slowest of the three. Use it as the acceptance
gate, not the inner loop. The inner loop is L2 (for rewriter modules) or
L3 (for IR-pass modules).

### 5.3 Fixture growth budget

Phase 1 had:
- 4 e2e fixtures, 6 transpiler e2e fixtures, 5 LIT fixtures, 6 unit-test files.

Phase 2 adds:
- 17 e2e fixtures (14 per-type + 2 typedef + 1 shared-handle)
- ~22 LIT fixtures (per (width × operation))
- 0–4 new unit-test files (from at-risk splits)

This is a 4× fixture multiplier. Run-time impact should be minimal
(each e2e is dominated by `cqc` invocation latency; LIT runs in
parallel via `lit -j`).

### 5.4 Determinism

All `printf` trace lines are deterministic (no thread non-determinism,
no PRNG). Handles are allocated by `cqrt_alloc_handle` which is a simple
counter. Golden matching is exact-bytes.

### 5.5 Phase 1 regression net

After M3, **every Phase 1 fixture must remain green for the rest of
Phase 2.** If any module breaks a Phase 1 fixture, that's a stop-the-line
signal — almost certainly the module touched something it shouldn't
have.

---

## 6. Open-items dispositions (PRD §"Open items")

The PRD leaves six items "decided in implementation." **This section
is the canonical disposition.** Each item below is pinned by M1
(`cq-p2-m01`) and locks the contract for M2 / M6 / M7. Code landing
after M1 takes these as fixed; reopening any item requires a new `bd`
issue and an explicit amendment to this section.

### 6.1 Suffix scheme

**Pinned: the PRD table verbatim.** `i1` / `c` / `si8` / `ui8` / `si16`
/ `ui16` / `si32` / `ui32` / `sl` / `ul` / `sll` / `ull` / `f32` / `f64`.

**Rationale.** It's already in the PRD; reopening it costs days. The
scheme is regular (signedness prefix `s`/`u`; width digits where
unambiguous), and `_si32` matches LLVM's mental model of "signed 32-bit
integer."

### 6.2 `qchar_mid_t` runtime alloc

**Pinned: aliases `cqrt_alloc_i8`.** No separate `cqrt_alloc_c`.

**Rationale.** Signedness is invisible at the runtime ABI per PRD §"Width
unification." Plain `char` shares the i8 alloc with `signed char` and
`unsigned char`. If the backend ever needs to distinguish (it doesn't,
because LLVM opcodes already carry signedness), a future phase can
split.

### 6.3 `qint_mid_t` rename

**Pinned: keep `qint_mid_t`.** The intrinsic `cq_init_i32` → `cq_init_si32`
renames; the typedef does not.

**Rationale.** Minimizes Phase-1 churn. `qint` clearly maps to `int`
(signed by C convention). Renaming the typedef would force a touch to
every existing Phase 1 fixture's `expected.c` (transpiler e2e goldens),
multiplying the M3 rename's blast radius for marginal gain.

### 6.4 Float `_Bool` cast semantics

**Pinned: no special handling in Phase 2.** Phase 2's `quantum float`
fixture does not exercise `(_Bool) q_float`.

**Rationale.** The cast lowers to `fcmp une float %v, 0.0` + `zext`
which has no template in Phase 2. Adding template support is an M16
extension; the open item only matters if M16's negative-test framing
catches the case. Defer to Phase 3 with the rest of cross-type cast
work.

### 6.5 `<stdbool.h>` `bool` behavior

**Pinned: lock with an e2e fixture using `bool` instead of `_Bool`.**

**Rationale.** `bool` is `#define bool _Bool` (or `_Bool` directly under
`-std=c23`); both lower to the same canonical type. The fixture is
cheap insurance against a future surprise.

Add to `tests/e2e/fixtures/types/i1/input.c` a sibling
`tests/e2e/fixtures/types/i1_stdbool/input.c` using `bool` instead of
`_Bool`; goldens identical.

### 6.6 Trace text format

**Pinned format (binding contract for M6/M7):**

| Symbol | Format |
|---|---|
| `cqrt_alloc_i1` | `cqrt_alloc_i1(<0\|1>) -> h<N>\n` |
| `cqrt_alloc_iW` (W ∈ 8,16,32,64) | `cqrt_alloc_iW(<value as %lld>) -> h<N>\n` |
| `cqrt_alloc_fW` (W ∈ 32,64) | `cqrt_alloc_fW(<value as %f>) -> h<N>\n` |
| `cqrt_measure_iW` | `cqrt_measure_iW(h<N>) -> <0 as %lld>\n` |
| `cqrt_measure_fW` | `cqrt_measure_fW(h<N>) -> <0.0 as %f>\n` |
| `cq_template_add_<W>` | `cq_template_add_<W>(h<a>, h<b>) -> h<N>\n` |
| `cq_template_add_<W>_hl` | `cq_template_add_<W>_hl(h<a>, <lit>) -> h<N>\n` |

**Rationale.** Consistent with Phase 1's pattern (`-> h<N>` handle
notation); single-line; no extra whitespace; `%lld` for ints widest-fits
without forking the format per width; `%f` for floats accepts default
6-digit precision (matches Phase 1's pattern).

---

## 7. Work breakdown (`bd` issue sketches)

One issue per module. Title convention: `cq-p2-mNN <slug>`. File these
via `bd create` before starting; the canonical list lives in `bd`, not
in this plan.

| ID | Title |
|---|---|
| `cq-p2-m01` | Pin Phase 2 suffix scheme & open-item dispositions |
| `cq-p2-m02` | `cq_mid.h` growout: 14 mid-structs + 28 intrinsic decls |
| `cq-p2-m03` | Phase 1 rename: `_i32` → `_si32`, `cqrt_alloc_classical_i32` → `cqrt_alloc_i32(value)` |
| `cq-p2-m04` | `cq_runtime.h` growout: 15 symbol decls |
| `cq-p2-m05` | `cq_templates.h` growout: 14 add-template decls |
| `cq-p2-m06` | Runtime stub bodies: per-width alloc + measure printf |
| `cq-p2-m07` | Template stub bodies: per-width add + _hl printf |
| `cq-p2-m08` | `TypeMap` 14-type table + suffix accessor |
| `cq-p2-m09` | `DeclStmtRewrite` keyword recognition + Pattern 6 detection |
| `cq-p2-m10` | `Codegen` suffix-driven init + Pattern-6 split form |
| `cq-p2-m11` | `CastRewrite` suffix-driven measure |
| `cq-p2-m12` | `CQLoweringPass` split (behavior-preserving) |
| `cq-p2-m13` | `WidthDispatch` helper |
| `cq-p2-m14` | `TaintPropagation` width-parametric sources |
| `cq-p2-m15` | `MidHandleRebind` width-parametric struct table |
| `cq-p2-m16` | `OpcodeLowering` per-width add/fadd templates |
| `cq-p2-m17` | `MeasureLowering` per-width measure |
| `cq-p2-m18` | E2E fixtures: 14 per-type |
| `cq-p2-m19` | E2E fixtures: 2 typedef |
| `cq-p2-m20` | E2E fixture: shared-handle measurement |
| `cq-p2-m21` | Phase 2 closure: 6-criterion acceptance run |

Each issue references this plan section (`PLAN.md §4.N`) and the PRD
section it implements.

---

## 8. Risks and mitigations

### 8.1 CQLoweringPass split regresses Phase 1

**Risk.** M12 is a 395-LOC monolith split into 4–5 files. A non-trivial
chance that one of the splits introduces a subtle ordering or
visibility bug.

**Mitigation.**
- M12 is its own commit, separate from M13–M17.
- M12's acceptance gate is "every existing LIT fixture passes
  byte-for-byte without modification." Any CHECK-line change means M12
  wasn't behavior-preserving.
- Bisecting is trivial: `git revert` M12 if a width-parametric module
  later regresses.

### 8.2 Test-file LOC creep past 300

**Risk.** `test_decl_stmt_rewrite.cpp` (254 LOC) and
`test_cast_rewrite.cpp` (206 LOC) will both balloon as 14-type coverage
lands. Worst-case 4–5× growth.

**Mitigation.**
- Plan §4.9 splits `test_decl_stmt_rewrite` into three files along type
  axes.
- For `test_cast_rewrite`, defer split to first-breach: it may stay
  under 280 if cases are sufficiently terse.
- Prefer data-driven (table-of-cases) loops over per-test boilerplate
  where the framework allows; GTest's `INSTANTIATE_TEST_SUITE_P` is fine
  if it doesn't make failure attribution worse.

### 8.3 `long`'s target-dependent width breaks one platform

**Risk.** `qlong_mid_t`'s `.val` is `long` (target-dependent). On
Linux/macOS 64-bit it lowers to `cqrt_alloc_i64`; on Windows or 32-bit
targets to `cqrt_alloc_i32`. CI might run only on one platform.

**Mitigation.**
- Plan §4.8 specifies a target-dependence test in `test_type_map`. This
  is unit-level and platform-independent (the test fixes the target
  triple manually).
- E2E fixtures rely on the platform's default target. If CI is
  64-bit-only, accept that and document. Phase 2 doesn't aspire to
  cross-platform CI.

### 8.4 Mixed-width arithmetic produces opaque errors

**Risk.** A user writing `quantum int a + quantum long b` triggers
`sext`/`zext` opcodes that have no template. M16's negative-test design
must catch this *as a known limitation* without confusing it for a
Phase 2 bug.

**Mitigation.**
- M16 includes an explicit negative-test fixture for `sub` (no template
  registered) with a recognizable failure message.
- README or `tests/e2e/fixtures/types/README.md` documents the known
  soft-failures from PRD §"Diagnostics baseline."

### 8.5 Float printf precision drift

**Risk.** `%f` defaults to 6-digit precision. A literal like `1.5f`
should print as `1.500000`. If different platforms' printf produce
different defaults (e.g., locale-dependent decimal separator), goldens
break.

**Mitigation.**
- Set `LC_ALL=C` in the e2e harness (one-line CMake change).
- Use `%f` not `%g`; `%g` is less stable across libc implementations.
- Pin precision explicitly (`%.6f`) if `%f`'s default ever varies.

### 8.6 SROA doesn't actually erase Pattern 6 on every platform

**Risk.** The "Pattern 6 emits no copy template" claim depends on
Clang's `-O1` SROA actually erasing the assigned-to variable. If a
codegen detail (e.g., volatile qualifier, struct alignment, ABI
attribute) blocks SROA, the IR pass will see an unexpected
mid-struct value flow and lower it to … nothing useful.

**Mitigation.**
- M18 fixtures' goldens explicitly assert the no-copy trace shape. If
  SROA misbehaves, the L1 trace will show an unexpected
  `cqrt_alloc_*` for `b` and the fixture will fail loudly.
- The shared-handle fixture (M20) is the canonical lock-in.

---

## 9. Done definition

Phase 2 is done when *every one* of these holds:

1. **All six PRD acceptance criteria** (PRD §"Acceptance criteria") satisfied.
2. **All `bd` issues** `cq-p2-m01` through `cq-p2-m21` closed.
3. **No file in the repo** exceeds 300 LOC, with these explicit exceptions:
   - Test fixtures (data, not code)
   - Generated build artifacts
4. **Phase 1 fixtures green** under the renamed surface.
5. **17 new e2e fixtures green** byte-exact.
6. **~22 LIT fixtures green.**
7. **L2 unit-test green.**
8. **No regression** in Phase 1 compile-time (informal eyeball; not gated).
9. **`git push` succeeds** and `git status` reports up-to-date with origin
   (per `CLAUDE.md` session-completion mandate).
10. **A Phase 2 closure note** in `phases/phase2/` (or a `bd remember`
    entry) summarizing actual vs. planned LOC and any deviations from
    this plan, so Phase 3 can read what shipped.

---

## 10. Out of scope (mirror of PRD §"Out of scope")

Restated here for the reviewer's convenience; do not implement any of
these as part of Phase 2:

- Any operator besides `+` → Phase 3
- Controlled-forward template variants → Phase 3
- Mixed-width promotion (`sext`/`zext` templates) → Phase 3
- Classical-mask views (`q & C`) → Phase 3
- `if (q_cond)` → Phase 4
- Auto uncomputation, inverse templates, real diagnostics → Phase 5
- `for` loops → Phase 6
- Functions, `invert(...)`, **copy templates at call boundaries** → Phase 7
- Arrays, QRAM → Phase 8
- `struct`, `union`, `_Complex` → Phase 9
- Quantum-conditioned `while` → Phase 10
- Frontend freeze, ABI lock, doc cleanup → Phase 11
- All real `cq_template_*` / `cqrt_*` bodies → Backend
- `_Float16`, `long double` → Backend

---

## References

- [`PRD.md`](./PRD.md) — Phase 2 contract.
- [`phases/phase1/PRD.md`](../phase1/PRD.md) — predecessor PRD.
- [`phases/phase1/PLAN.md`](../phase1/PLAN.md) — predecessor plan
  (this plan's structure is modeled on it).
- [`ROADMAP.md`](../../ROADMAP.md) §Design principles — frontend-first
  rule, "no foot-gun protection," etc.
- [`docs/architecture.md`](../../docs/architecture.md) §3, §5, §6, §7,
  §12.
- [`docs/quantum-classical-handling.md`](../../docs/quantum-classical-handling.md) —
  mixed-operand semantics; load-bearing for M16.
- [`CLAUDE.md`](../../CLAUDE.md) — agent rules: `bd` for tracking,
  push-before-done.
