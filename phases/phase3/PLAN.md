# CQ_lang Phase 3 — Implementation Plan

> **Companion to** [`PRD.md`](PRD.md). The PRD locks contracts (operator surface, naming, comparison flag-handle ABI, Q→Q vs Q→C discriminator). This PLAN locks **how** and **in what order** — module boundaries, LOC budgets, test-first discipline, and disposition of every PRD §"Open items".

## 0. Reading order

1. §1 — Goals, principles, non-goals (restated; deviations from Phase 2 highlighted).
2. §2 — File layout deltas (what's new, what splits, every file's LOC ceiling).
3. §3 — Sequencing DAG (modules and their dependencies).
4. §6 — Open-items dispositions (PRD § "Open items" — every entry has a binding answer here).
5. §4 — Per-module plans (M1 … M18).
6. §5 — Testing strategy (three layers; test-first per module).
7. §7–§10 — Work breakdown, risks, done definition, out-of-scope.

## 1. Goals, principles, non-goals

### 1.1 Goal (restated from PRD)

Extend Phase 2's `+`-only opcode slice to the **full LLVM data-opcode surface** Clang emits at `-O1` for the C arithmetic, bitwise, comparison, unary, and cast operator families. The pipeline shape, intrinsic surface, and runtime ABI from Phases 1–2 are unchanged. No new architectural mechanism — taint propagation, mid→handle rebinding, and Q+Q / Q+C dispatch generalize uniformly.

### 1.2 Principles

| Principle | Source | What it means in Phase 3 |
|---|---|---|
| **Backend stays stubbed.** | [ROADMAP §"Design principles" #1], [memory: `feedback-no-backend-until-frontend-done`] | All ~680 new `cq_template_*` symbols are trace-only `printf` stubs. No reversible-circuit bodies. The phase 11 freeze owns those. |
| **One generator, many consumers.** | New for Phase 3 | A single YAML opcode table drives `cq_templates.h`, `cq_templates.c`, the IR-pass dispatch tables, and the LIT fixtures. Hand-listing 680 symbols is rejected; X-macros are rejected (see §6.1). |
| **Module LOC ≤ 300.** | User constraint | Every source/header file in this PLAN has an explicit LOC ceiling. Anything that would exceed 300 is split *before* it grows past, not retroactively. |
| **Test-first per module.** | Phase 2 §5.2 carried forward | Each module begins with a red test; implementation lands until green; refactor closes the module. See §5.2. |
| **No new rewriter mechanism.** | PRD §"Rewriter changes" | Patterns 7–11 are mechanical AST inspection; transforms are uniform "convert quantum DeclRefExpr to `.val`" rewrites. No per-operator code paths, no QQ/QC dispatch in the rewriter. |
| **No new intrinsics.** | PRD §"Intrinsic surface (cq_mid.h additions)" | The 28-intrinsic surface from Phase 2 is unchanged. Phase 3 is purely opcode-table growth. |
| **Frontend-complete contract.** | PRD §"Scope" #3 | The full template grid is declared up front (forward + inverse, Q+Q + Q+C) so Phase 5 has stable inverse symbols to bind. |
| **Mixed-operand dispatch never promotes classical to handle.** | [memory: `cq-mixed-operand-runtime-dispatch`] | Q+C templates take handle + raw classical scalar (the `_hl` suffix variant). The IR-pass operand-swap logic at `OpcodeLowering.cpp:194` (`BTainted` branch) generalizes to every new binary opcode. |

### 1.3 Non-goals

- **No controlled-forward variants** (`_ctrl` / `_hl_ctrl`). Phase 4 owns these alongside `cq_when_*` region detection. PRD §"Roadmap discrepancy" #1.
- **No 3.3-style classical-mask bit-view optimization.** From the IR pass's view `q & C` is just another tainted `and`; lowers to `cq_template_and_<W>_hl`. Bit-aliasing vs CNOT fan-out is a post-freeze backend concern. PRD §"Roadmap discrepancy" #2.
- **No XOR-copy / swap.** Phase 7 introduces the first context (function-call boundaries) where assignments survive SROA. PRD §"Roadmap discrepancy" #4.
- **No active source-location diagnostics.** Phase 5 owns reversibilizability error reporting. Phase 3 keeps the passive `SourceLocation` + `!dbg` preservation from Phase 2.
- **No `&&`, `||`, ternary.** These lower to tainted `br i1` + `phi` — quantum control flow, Phase 4. Phase 3 covers bitwise `&` / `|` (no short-circuit).
- **No expression statements without LHS** (`a + b;` standalone). Documented soft-failure mode; revisit if a fixture needs it.
- **No `_Bool` (i1) opcode exercise** beyond what Phase 2 already validates. `-O1` lowers `_Bool` arithmetic to `i8` before the IR pass sees it; the i1 templates are declared symmetrically but mostly dead surface.

## 2. File layout deltas

Total files touched: **~18 source files modified, ~8 new source files, 1 new generator script, ~340 generated LIT fixtures, ~35 e2e fixtures.** All new C++/C source modules carry a hard ceiling of **300 LOC**.

### 2.1 Headers

| File | Change | LOC after | Ceiling |
|---|---|---|---|
| `include/CQ.h` | None — `quantum` macro and attribute recognition unchanged | ~unchanged | 300 |
| `include/cq_mid.h` | None — no new intrinsics (init/measure surface unchanged) | ~unchanged | 300 |

### 2.2 Runtime

| File | Change | LOC after | Ceiling |
|---|---|---|---|
| `runtime/cq_runtime.h` | None — no new ABI symbols | 102 | 300 |
| `runtime/cq_runtime.c` | None — no new ABI bodies | 155 | 300 |
| `runtime/cq_templates.h` | **Generated**; grows from 92 → ~700 lines (one declaration per symbol; header includes a generation banner and the source YAML hash) | ~700 | **special — generated, no ceiling**; see §6.1 |
| `runtime/cq_templates.c` | **Generated**; grows from 139 → ~1400 lines (one printf-name stub per symbol) | ~1400 | **special — generated**; see §6.1 |

Generated files exceed 300 LOC by design — they are mechanically produced from a small input. The 300-LOC rule applies to **hand-edited modules** only. The generator output is checked in (no build-time codegen step; see §6.1).

### 2.3 Transpiler (rewriter)

| File | Change | LOC before → after | Ceiling |
|---|---|---|---|
| `transpiler/src/QuantumAttr.{cpp,h}` | None | 46 / 26 | 300 |
| `transpiler/src/TypeMap.{cpp,h}` | None — 14-type table unchanged | 222 / 104 | 300 |
| `transpiler/src/SourceText.{cpp,h}` | Possibly tiny helper for compound-assign source extraction; audit at M7 | 29 → ~50 | 300 |
| `transpiler/src/OperandClass.{cpp,h}` | Minor extension: classifier reused for Patterns 7–9 (LHS quantum-ness queries). See §6.3 | 38 → ~70 | 300 |
| `transpiler/src/Matcher.{cpp,h}` | **Slim — stays at the dispatch level.** Phase 2 binop matcher logic moves to `BinopMatcher.cpp` (rename only; no logic change). Existing 255 LOC → ~120 LOC dispatch shell | 255 → ~120 | 300 |
| `transpiler/src/BinopMatcher.{cpp,h}` | **New** — Phase 2 binop matcher logic extracted verbatim into its own module (Patterns 3–4, generalized to operator-agnostic) | new ~180 | 300 |
| `transpiler/src/AssignMatcher.{cpp,h}` | **New** — Patterns 7 (plain assign), 8 (compound assign) | new ~150 | 300 |
| `transpiler/src/UnaryMatcher.{cpp,h}` | **New** — Pattern 9 (unary on quantum) | new ~120 | 300 |
| `transpiler/src/Codegen.{cpp,h}` | **Slim — stays at the entry point.** Move Phase 2 binop emission into `BinopCodegen.cpp`; this file becomes the multiplex of (Pattern → emitter) | 128 → ~80 | 300 |
| `transpiler/src/BinopCodegen.{cpp,h}` | **New** — Phase 2 binop emission extracted verbatim | new ~110 | 300 |
| `transpiler/src/AssignCodegen.{cpp,h}` | **New** — Patterns 7, 8 emission paths | new ~140 | 300 |
| `transpiler/src/UnaryCodegen.{cpp,h}` | **New** — Pattern 9 emission paths | new ~90 | 300 |
| `transpiler/src/CastRewrite.{cpp,h}` | Destination-quantum-ness discriminator (one-line conditional in `chooseEmission`); Pattern 10/11 emission path | 96 → ~150 | 300 |
| `transpiler/src/DeclStmtRewrite.{cpp,h}` | None — 14-type recognition unchanged. Pattern 11 (implicit Q→Q at VarDecl) routes through this file via the cast discriminator | 264 / 47 | 300 |
| `transpiler/src/main.cpp` | None — wiring already pattern-table-based | 32 | 300 |

**Result:** every hand-edited transpiler file lands under 300 LOC, with the largest being `BinopMatcher.cpp` (extracted Phase 2 logic) at ~180 and `DeclStmtRewrite.cpp` (unchanged from Phase 2) at 264.

### 2.4 Transpiler unit tests

`transpiler/tests/unit/` grows by **~25 new golden pairs**:

- `pattern07_plain_assign/` — 5 fixtures (Q+Q assign, Q+C assign, mixed-suffix assign, assign with cast, assign chain)
- `pattern08_compound_assign/` — 5 fixtures (`+=` `*=` `<<=` `&=` Q+Q, `+=` Q+C)
- `pattern09_unary/` — 5 fixtures (`-q` int, `-q` fp via fneg, `~q`, `!q`, `++q` / `q++`)
- `pattern10_qq_cast_explicit/` — 4 fixtures (i32→i64, i64→i32, f32→f64, int→fp)
- `pattern11_qq_cast_implicit/` — 4 fixtures (matching pattern 10 at VarDecl level)
- `cast_discriminator/` — 2 fixtures (Q→C still works; Q→Q does not measure)

Total: ~25 unit goldens, each ~30–60 lines. PRD estimated 20–30; this lands centered.

### 2.5 IR pass

| File | Change | LOC before → after | Ceiling |
|---|---|---|---|
| `ir-pass/src/Plugin.cpp` | None | 40 | 300 |
| `ir-pass/src/CQLoweringPass.{cpp,h}` | Register `CompareLowering`, `CastLowering`, `UnaryLowering` modules into the pass pipeline; reorder if necessary | 112 → ~140 | 300 |
| `ir-pass/src/TaintPropagation.{cpp,h}` | None — taint is opcode-agnostic (PRD §"IR pass changes" stage 1) | 133 / 59 | 300 |
| `ir-pass/src/MidHandleRebind.{cpp,h}` | None — rebinding is type-table-driven, unchanged | 159 / 50 | 300 |
| `ir-pass/src/WidthDispatch.{cpp,h}` | Extend to cover the new cast-width pairs (from-width × to-width lookup helper); audit shared with `CastLowering` | 200 → ~250 | 300 |
| `ir-pass/src/MeasureLowering.{cpp,h}` | None — measure lowering is per-suffix, unchanged | 129 / 59 | 300 |
| `ir-pass/src/OpcodeLowering.{cpp,h}` | **Refactor**: replace hardcoded `Instruction::Add` / `Instruction::FAdd` switch with table-driven dispatch covering all int/fp arith + bitwise binary opcodes. Operand-swap logic generalizes uniformly | 220 → ~250 | 300 |
| `ir-pass/src/OpcodeTables.{cpp,h}` | **New** — generated dispatch tables: `(LLVM opcode → template symbol stem, width set)`. Generated from same YAML as runtime stubs. See §6.2 | new ~250 (generated) | **special — generated** |
| `ir-pass/src/CompareLowering.{cpp,h}` | **New** — `icmp <pred>` / `fcmp <pred>` dispatch; result type is `int32_t` flag handle (PRD §"Comparison contract") | new ~230 | 300 |
| `ir-pass/src/CastLowering.{cpp,h}` | **New** — all 9 cast opcodes (`sext`, `zext`, `trunc`, `fpext`, `fptrunc`, `sitofp`, `uitofp`, `fptosi`, `fptoui`); per-(from, to) width lookup | new ~270 | 300 |
| `ir-pass/src/UnaryLowering.{cpp,h}` | **New** — `fneg` only (PRD §"Operator surface" — int unaries reuse binary opcodes). Tiny module by design | new ~80 | 300 |
| `ir-pass/src/FlagHandle.{cpp,h}` | **New** — utility for compare-result flag handles: allocates an i1-shaped tainted handle via existing `cq_template_icmp_<pred>_<W>` return value. Stays an i32 handle at the ABI; semantically logical-1-bit | new ~70 | 300 |

**Result:** every hand-edited IR-pass file lands under 300 LOC. `OpcodeTables.cpp` is generated (special) and ~250 LOC; the largest hand-edited file is `CastLowering.cpp` at ~270 — within budget but flagged as the highest-risk LOC ceiling. See §8.1.

### 2.6 Test fixtures

| Directory | Count | Source |
|---|---|---|
| `tests/e2e/fixtures/phase3/int_arith/` | 6 (sub, mul, sdiv, udiv, srem, urem at i32; spot-check i8, i64 → +2) | hand-written |
| `tests/e2e/fixtures/phase3/int_bitwise/` | 6 (and, or, xor, shl, lshr, ashr at i32) | hand-written |
| `tests/e2e/fixtures/phase3/int_compare/` | 5 (one per representative pred-class — eq/ne/slt/ult; ge/le tested via spot-check) | hand-written |
| `tests/e2e/fixtures/phase3/fp_arith/` | 4 (fsub, fmul, fdiv, fneg at f64; fadd is Phase 2) | hand-written |
| `tests/e2e/fixtures/phase3/fp_compare/` | 3 (oeq, olt, one at f64; spot-check f32) | hand-written |
| `tests/e2e/fixtures/phase3/cast_int_widths/` | 3 (sext i8→i32, zext i32→i64, trunc i64→i32) + 1 acceptance chain (3.4-absorbed) | hand-written |
| `tests/e2e/fixtures/phase3/cast_fp_widths/` | 2 (fpext, fptrunc) | hand-written |
| `tests/e2e/fixtures/phase3/cast_cross_domain/` | 2 (sitofp i32→f64, fptosi f64→i32) | hand-written |
| `tests/e2e/fixtures/phase3/unary/` | 4 (`-q` int, `-q` fp, `~q`, `++q`) — `!q` covered by compare fixture | hand-written |
| `tests/e2e/fixtures/phase3/compound_assign/` | 3 (`+=`, `*=`, `&=`) | hand-written |
| `tests/e2e/fixtures/phase3/plain_assign/` | 2 (Q+Q assign, Q+C assign to existing var) | hand-written |
| `tests/e2e/fixtures/phase3/qq_cast/` | 2 (explicit Pattern 10, implicit Pattern 11) | hand-written |
| `tests/e2e/fixtures/phase3/comparison_flag_flow/` | 1 acceptance fixture exercising flag handle into subsequent op / measurement (PRD acceptance §4) | hand-written |
| `ir-pass/test/phase3/<opcode>/` | ~340 LIT fixtures | **generated** |

E2E total: **~37 fixtures** (PRD estimated 30–40). LIT total: **~340 generated**.

### 2.7 Generation harness

| File | Purpose | LOC |
|---|---|---|
| `tools/opcode_table.yaml` | Single source of truth: lists every (opcode, family, widths, variants) tuple in Phase 3's operator surface | ~250 |
| `tools/gen_templates.py` | Generator script — reads YAML; emits `cq_templates.h`, `cq_templates.c`, `OpcodeTables.cpp`, LIT fixtures. Idempotent: re-running on unchanged YAML produces byte-identical output. Embeds YAML hash in output banner. | ~300 |
| `tools/gen_templates_test.py` | Self-test for the generator: round-trip YAML → outputs → assert structural invariants (symbol count matches manifest, no duplicates, all widths covered) | ~120 |

The Python script is invoked manually (`python3 tools/gen_templates.py`) and its outputs are checked into git. Rationale: keeps the build deterministic, avoids a Python build-time dependency, and makes diffs of generated content reviewable. CI runs `gen_templates.py` in a "check mode" that diffs against checked-in output; mismatch fails the build. See §6.1.

### 2.8 CMake

| File | Change |
|---|---|
| `CMakeLists.txt` (root) | Add `tools/` to test target list so `gen_templates_test.py` runs under `ctest` |
| `runtime/CMakeLists.txt` | None — `cq_templates.c` is still a normal source file |
| `transpiler/CMakeLists.txt` | Add new source files (Binop/Assign/Unary Matcher + Codegen split) to the transpiler target |
| `ir-pass/CMakeLists.txt` | Add `OpcodeTables.cpp`, `CompareLowering.cpp`, `CastLowering.cpp`, `UnaryLowering.cpp`, `FlagHandle.cpp` to the IR-pass shared object |
| `ir-pass/test/CMakeLists.txt` | Glob the new `phase3/` LIT fixture directory so `ctest` picks up generated tests |

### 2.9 At-risk split decisions (revisit at end of phase)

| File | Current/projected LOC | Risk | Trigger to split |
|---|---|---|---|
| `CastLowering.cpp` | ~270 | Highest-LOC hand-edited file; 9 opcodes × cross-pair logic | If at PR review time it exceeds 280, split into `IntCastLowering.cpp` + `FpCastLowering.cpp` |
| `WidthDispatch.cpp` | ~250 | Carries new cast-pair lookup tables | If it exceeds 280, factor cast-pair lookups into a sibling `CastWidthDispatch.cpp` |
| `tools/gen_templates.py` | ~300 | At the ceiling by design | If it crosses 300, split per-output generator (`gen_templates_h.py`, `gen_lit.py`, etc.) sharing a common `opcode_loader.py` |

## 3. Sequencing

Modules run roughly in this order. Independent modules can be parallelized; dependencies are explicit.

```
M1 (planning, no code)
 └─ M2 (generator harness)
     ├─ M3 (cq_templates.h generated) ─┐
     ├─ M4 (cq_templates.c generated) ─┼─ M5 (Phase 1+2 regression check)
     └─ M10 (OpcodeTables.cpp generated)
M6 (OperandClass extensions) ──┐
M7 (Matcher split + 7–9)        │
M8 (Codegen split + 7–9)        ├─ M17 (rewriter unit goldens)
M9 (CastRewrite Q→Q + Pat 10–11)┘
M10 (OpcodeTables generated) ─┐
M11 (OpcodeLowering refactor) │
M12 (CompareLowering)         │
M13 (CastLowering)            ├─ M15 (CQLoweringPass wiring)
M14 (UnaryLowering)           │     └─ M16 (LIT fixtures generated)
                              │           └─ M18 (e2e fixtures)
                              │                 └─ M19 (acceptance run + closure)
```

**Parallelization opportunities:** M3/M4/M10 share the generator (M2) but produce independent outputs. M6–M9 (rewriter) and M11–M14 (IR pass) are independent stacks; the e2e harness (M18) needs both.

**Critical path:** M1 → M2 → M10 → M11 → M15 → M16 → M19. The IR-pass stack is the bottleneck for end-to-end coverage; rewriter work can be batched in parallel.

## 4. Per-module plans

Each module documents: **inputs**, **outputs**, **test artifact written first (red)**, **implementation**, **acceptance**, **LOC budget**. Test-first discipline per §5.2.

### 4.1 M1 — Open-items dispositions + opcode-table schema

**No code.** Lock the dispositions in §6 (this PLAN) and the opcode-table schema in `tools/opcode_table.yaml`. Output is a reviewed PR adding `tools/opcode_table.yaml` and this PLAN. Closes [bd] issues describing the design decisions.

**Acceptance:**

- §6 has a binding answer for every PRD §"Open items" entry.
- `tools/opcode_table.yaml` validates against an inline schema comment (one block at top of file listing required keys per opcode kind).
- Counts in the YAML match PRD: 17 binary opcodes total (7 int arith + 6 int bitwise + 4 fp arith), 1 unary (fneg), 2 compare families × pred sets, 9 cast kinds with cross-pair tables.

**LOC budget:** YAML ~250 lines. PLAN entries this section.

### 4.2 M2 — Generator harness (`tools/gen_templates.py`)

**Inputs:** `tools/opcode_table.yaml` from M1.

**Outputs (written by the script):** `runtime/cq_templates.h`, `runtime/cq_templates.c`, `ir-pass/src/OpcodeTables.cpp` (+`.h`), `ir-pass/test/phase3/<opcode>/*.ll` LIT fixtures.

**Test first (red):**

1. Write `tools/gen_templates_test.py` with assertions:
   - Running the generator twice on the same YAML produces byte-identical output (idempotence).
   - Generated `cq_templates.h` has exactly 680 declarations (count by `grep -c "^int32_t cq_template_" cq_templates.h`).
   - Every declared symbol has a matching definition in `cq_templates.c`.
   - Banner line in every generated file embeds the YAML SHA-256 (12 hex chars).
   - `--check` mode exits non-zero when generated files diverge from checked-in.

**Implementation:**

- Parse YAML via `pyyaml` (LLVM build already requires Python 3 + pyyaml).
- For each binary opcode: emit 4 declarations per (width) — forward Q+Q, forward Q+C (`_hl`), inverse Q+Q (`_inv`), inverse Q+C (`_hl_inv`).
- For each unary opcode: emit forward + inverse per width.
- For each compare family: emit per-(predicate, width) — forward Q+Q, forward Q+C, inverse Q+Q, inverse Q+C. Return type `int32_t` (flag handle).
- For each cast: emit forward + inverse per (from, to) pair.
- Body stub is `printf("cq_template_<name>(...)\n"); return <result-handle-or-void>;` — exactly mirrors Phase 2's existing add/fadd stub format.
- `OpcodeTables.cpp` emits two `static const std::array` tables: binary-opcode dispatch and compare-predicate dispatch. Cast dispatch is its own table (PRD §"IR pass changes" — split tables decision; see §6.2).
- LIT fixture template: 5–10 lines asserting the right `call @cq_template_<name>` is emitted in the lowered IR. One fixture per (opcode, width) for Q+Q and Q+C variants of forward direction. Inverse-variant LIT fixtures land in Phase 5 (consumer phase).

**Acceptance:**

- `gen_templates_test.py` passes locally and under `ctest`.
- `--check` flag detects diffs (manually verified by editing one symbol and rerunning).
- Symbol count and family breakdown match the PRD-derived counts in §2.6 (cast: 136, compare: 248 (200 icmp + 48 fcmp), unary: 4, binary: 256 (140 int arith + 120 int bitwise + 32 fp arith), grand total 680 = 256+4+248+136. **Verify in M5.**

**LOC budget:** `gen_templates.py` ~300 (at ceiling — flagged in §2.9). `gen_templates_test.py` ~120. YAML ~250.

### 4.3 M3 — Generated `cq_templates.h`

**Run:** `python3 tools/gen_templates.py --header runtime/cq_templates.h`

**Test first (red):**

- LIT-style sanity check at `runtime/CMakeLists.txt` test target: `gcc -c -E runtime/cq_templates.h -o /dev/null` succeeds (declarations are valid C).
- A small ctest target: `runtime/test_header_compile.c` — `#include "cq_templates.h"`, link, ensure no symbol collisions and no warnings under `-Wall -Wextra -Wpedantic -Werror`.

**Implementation:** Run the generator; commit output.

**Acceptance:** The generated header compiles clean. Symbol count = 680.

**LOC budget:** Generated ~700 LOC (special — see §2.2).

### 4.4 M4 — Generated `cq_templates.c`

**Run:** `python3 tools/gen_templates.py --source runtime/cq_templates.c`

**Test first (red):**

- Extend `runtime/test_trace.c` from Phase 2 to also exercise one symbol per family: `cq_template_sub_i32`, `cq_template_xor_i32`, `cq_template_icmp_slt_i32`, `cq_template_sext_i8_to_i32`, `cq_template_fneg_f64`. Update `test_trace.expected.log` accordingly.

**Implementation:** Run the generator; commit output.

**Acceptance:** Trace test produces the new expected log byte-exact.

**LOC budget:** Generated ~1400 LOC (special).

### 4.5 M5 — Phase 1+2 regression sanity after template growth

**No new code.** Run all Phase 1+2 e2e fixtures (`ctest -L phase1`, `ctest -L phase2`) and confirm they pass unchanged. Confirm transpiler builds without warnings under the larger linkage. Confirm runtime link time has not regressed by more than ~30% (one-time hit; not blocking).

**Acceptance:** Phase 1 fixtures (vertical slice): green. Phase 2 fixtures (14-type coverage, typedefs, shared-handle): green. PRD §"Acceptance criteria" #7.

**LOC budget:** 0.

### 4.6 M6 — Transpiler: `OperandClass` extensions

**Inputs:** None (extends Phase 2's classifier).

**Test first (red):**

- Add `transpiler/tests/unit/operand_class/test_assign_lhs.cpp` — unit test asserting `classifyAssignLHS(BinaryOperator)` returns `Quantum` for `a = …` when `a` is a quantum VarDecl, `Classical` otherwise.
- Same for `classifyUnaryOperand(UnaryOperator)`.

**Implementation:** Add two free functions in `OperandClass.cpp` (~30 LOC additions). They reuse the existing `isQuantumDeclRef` predicate. No new classifier types.

**Acceptance:** Unit tests pass. `OperandClass.cpp` lands at ~70 LOC.

**LOC budget:** `OperandClass.cpp` 38 → ~70.

### 4.7 M7 — Transpiler: Matcher split + Patterns 7–9 matchers

**Inputs:** M6 (`OperandClass` extensions).

**Test first (red):**

1. Extract Phase 2's binop-matching logic from `Matcher.cpp` into `BinopMatcher.cpp` (mechanical move). Confirm all Phase 2 unit goldens still pass byte-exact (regression net per §5.5).
2. Write `transpiler/tests/unit/pattern07_plain_assign/test_basic.cpp` — input: `quantum int a; a = a + 1;` — assert `AssignMatcher::match` recognizes the assign.
3. Same for Pattern 8 (`a += b;`) and Pattern 9 (`-a`, `~a`, `++a`).

**Implementation:**

- `Matcher.cpp` becomes a slim dispatcher: iterates over candidate patterns in order, returns the first match. ~120 LOC.
- `BinopMatcher.cpp` carries Phase 2's binop AST recognition verbatim. ~180 LOC.
- `AssignMatcher.cpp` handles `BinaryOperator(BO_Assign, …)` with quantum LHS (Pattern 7) and `CompoundAssignOperator(…)` with quantum LHS (Pattern 8). ~150 LOC.
- `UnaryMatcher.cpp` handles `UnaryOperator(…)` with quantum operand (Pattern 9, all of `UO_Minus` `UO_Not` `UO_LNot` `UO_PreInc` `UO_PostInc` `UO_PreDec` `UO_PostDec`). ~120 LOC.

**Acceptance:**

- Phase 2 unit goldens green (regression).
- Pattern 7/8/9 recognition unit tests green.
- All split files ≤ 300 LOC.

**LOC budget:** `Matcher.cpp` 255 → ~120; `BinopMatcher.cpp` new ~180; `AssignMatcher.cpp` new ~150; `UnaryMatcher.cpp` new ~120.

### 4.8 M8 — Transpiler: Codegen split + Patterns 7–9 emission

**Inputs:** M7.

**Test first (red):**

1. Extract Phase 2's binop emission from `Codegen.cpp` into `BinopCodegen.cpp` (mechanical move). Confirm Phase 2 unit goldens still pass.
2. Write golden tests for Patterns 7–9 emission:
   - Pattern 7: `a = b + 1;` (a, b quantum int) → `a.val = b.val + 1;`
   - Pattern 8 canonical form per §6.5: `a += b;` → `a.val += b.val;` (compound preserved)
   - Pattern 9 canonical forms per §6.4:
     - `quantum int b = -a;` → `qint_mid_t b; b.val = -a.val;`
     - `quantum int b = ~a;` → `qint_mid_t b; b.val = ~a.val;`
     - `quantum int b = ++a;` → `qint_mid_t b; a.val += 1; b.val = a.val;` (semantic preorder)
     - `quantum int b = a++;` → `qint_mid_t b; b.val = a.val; a.val += 1;` (postorder)

**Implementation:**

- `Codegen.cpp` slims to a multiplex: `(Pattern, MatchResult) → calls into Binop/Assign/Unary/Cast emitters`. ~80 LOC.
- `BinopCodegen.cpp` carries Phase 2 verbatim. ~110 LOC.
- `AssignCodegen.cpp`: Patterns 7, 8 — rewrite quantum DeclRefExprs to `.val` access; preserve operator (for compound). ~140 LOC.
- `UnaryCodegen.cpp`: Pattern 9 — emit prefix/postfix forms per §6.4. ~90 LOC.

**Acceptance:**

- Phase 2 unit goldens green.
- Pattern 7/8/9 unit goldens green.
- All split files ≤ 300 LOC.

**LOC budget:** `Codegen.cpp` 128 → ~80; `BinopCodegen.cpp` new ~110; `AssignCodegen.cpp` new ~140; `UnaryCodegen.cpp` new ~90.

### 4.9 M9 — Transpiler: CastRewrite Q→Q discriminator + Patterns 10, 11

**Inputs:** M6 (OperandClass), M8 (CastCodegen split — if performed; otherwise CastRewrite owns emission directly).

**Test first (red):**

1. `transpiler/tests/unit/cast_discriminator/test_q_to_c.cpp` — Phase 2 path: `int x = (int) q;` still emits `cq_measure_si32(q)`.
2. `transpiler/tests/unit/cast_discriminator/test_q_to_q_explicit.cpp` — `quantum long b = (quantum long) q_int;` emits `qlong_mid_t b; b.val = (long) q_int.val;` and **does not** emit any `cq_measure_*` call.
3. `transpiler/tests/unit/cast_discriminator/test_q_to_q_implicit.cpp` — `quantum long b = q_int;` (where q_int is `quantum int`) emits the same as explicit form.
4. Edge case: `int x = (a == b);` (quantum expr → classical, no cast) — assert the rewriter does **not** rewrite this and the IR pass produces the documented diagnostic (PRD §"Known soft-failure modes" #3). The unit test verifies the rewriter leaves the expression alone; IR-pass diagnostic exercise lives in M16.

**Implementation:** `CastRewrite.cpp` gains a `isDestinationQuantum(CastExpr)` predicate that consults `QuantumAttr` on the target type. The existing `chooseEmission` switch branches on it: quantum destination → emit stock C cast on `.val`; classical destination → emit `cq_measure_<sfx>` (Phase 2 path).

**Acceptance:**

- All 4 unit goldens green.
- Phase 2's existing Q→C cast goldens green (regression).
- `CastRewrite.cpp` ≤ 200 LOC.

**LOC budget:** `CastRewrite.cpp` 96 → ~150.

### 4.10 M10 — IR pass: `OpcodeTables.{h,cpp}` (generated dispatch tables)

**Inputs:** M2 (generator).

**Test first (red):** Compile-only test — the table file compiles as C++17 under the IR-pass build (`ninja CQLoweringPass`). A unit-test stub that links the file and checks `binaryOpcodeTable.size()` matches the YAML count.

**Implementation:** Run `python3 tools/gen_templates.py --opcode-tables ir-pass/src/OpcodeTables.cpp`. Generator emits:

- `static const BinaryOpcodeRow binaryOpcodeTable[]` — rows: `{llvm::Instruction::Add, "add", {i1,i8,i16,i32,i64}, /*hasQQ*/true, /*hasHL*/true, /*hasInv*/true}`.
- `static const CompareRow icmpTable[]` and `fcmpTable[]` — rows include predicate enum value.
- `static const CastRow castTable[]` — rows include from/to width pair.
- Header declares the row structs and `lookup*` helper functions.

**Acceptance:** File compiles. Table sizes match YAML manifest.

**LOC budget:** Generated ~250 LOC (special).

### 4.11 M11 — IR pass: `OpcodeLowering.cpp` refactor (table-driven binary arith + bitwise)

**Inputs:** M10.

**Test first (red):**

1. Add LIT fixtures for each Phase 3 binary opcode at i32 (representative width): `sub`, `mul`, `sdiv`, `udiv`, `srem`, `urem`, `and`, `or`, `xor`, `shl`, `lshr`, `ashr`, `fsub`, `fmul`, `fdiv`. Each ~5 lines asserting `call @cq_template_<op>_<W>(%a_handle, %b_handle)`. Hand-write three of these (`sub`, `xor`, `fsub`) as a sanity check; the rest are auto-generated in M16.
2. Phase 2 LIT fixtures for `add`/`fadd` must continue passing.

**Implementation:**

- Replace the hardcoded `switch (instr.getOpcode())` block at `OpcodeLowering.cpp:127-133` with `BinaryOpcodeRow* row = lookupBinaryOpcode(instr.getOpcode());`.
- If `row == nullptr`, fall back to existing `DiagnosticInfoUnsupported` ("no template for opcode"). The diagnostic now reflects genuine surface coverage gaps, not unimplemented work — see PRD §"IR pass changes" closing paragraph.
- Existing operand-swap logic (`OpcodeLowering.cpp:194`, `BTainted` branch) is reused uniformly for every binary opcode — no per-opcode special case.
- Width resolution (`abiWidthFromType`, lines 49–65) is unchanged.

**Acceptance:**

- Phase 1+2 LIT fixtures green.
- Hand-written Phase 3 LIT fixtures (`sub`, `xor`, `fsub` at i32/f32) green.
- `OpcodeLowering.cpp` ≤ 300 LOC.

**LOC budget:** 220 → ~250.

### 4.12 M12 — IR pass: `CompareLowering.{cpp,h}` (icmp + fcmp + flag-handle)

**Inputs:** M10, M15 wiring deferred.

**Test first (red):**

- LIT fixtures for representative compares: `icmp eq i32`, `icmp slt i32`, `icmp ult i32`, `fcmp oeq f64`, `fcmp olt f64`. Hand-written; rest auto-generated.
- Each asserts `call @cq_template_icmp_<pred>_i32(%a_handle, %b_handle)` and that the SSA result is an `i32` (the flag handle).

**Implementation:**

- New module: detects tainted `ICmpInst` / `FCmpInst`; reads predicate via `CmpInst::getPredicate()`; consults `OpcodeTables` for the symbol stem.
- Calls `FlagHandle::createFlagHandle(builder, callResult)` to register the result as a tainted handle for subsequent lowering passes.
- Operand-swap logic from `OpcodeLowering` is duplicated here in a free helper or factored into `WidthDispatch` for shared use (PLAN time micro-decision; reuse preferred).

**Acceptance:** Hand-written compare LIT fixtures green. Compare-result handle flows correctly through a subsequent operation (`q_flag + 1` style; tested in M18 e2e).

**LOC budget:** `CompareLowering.cpp` ~230, `.h` ~50.

### 4.13 M13 — IR pass: `CastLowering.{cpp,h}` (all cast opcodes)

**Inputs:** M10. **Highest-LOC risk module — flagged in §2.9.**

**Test first (red):**

- Hand-written LIT fixtures: one per cast kind (`sext i8→i32`, `zext i16→i64`, `trunc i64→i32`, `fpext f32→f64`, `fptrunc f64→f32`, `sitofp i32→f64`, `fptosi f64→i32`). 7 hand-written fixtures.
- Each asserts the correct per-(from, to)-width template symbol.

**Implementation:**

- Detect tainted `SExtInst` / `ZExtInst` / `TruncInst` / `FPExtInst` / `FPTruncInst` / `SIToFPInst` / `UIToFPInst` / `FPToSIInst` / `FPToUIInst`.
- Per-instruction handler reads source and destination widths via `Instruction::getSrcTy()` / `getDestTy()` and consults `OpcodeTables::lookupCast(opcode, fromWidth, toWidth)`.
- One template symbol per (cast kind, from-width, to-width). PRD §"Naming convention".

**Acceptance:** Hand-written cast LIT fixtures green. `CastLowering.cpp` ≤ 300 LOC; if it exceeds 280 at PR review, split per §2.9.

**LOC budget:** ~270.

### 4.14 M14 — IR pass: `UnaryLowering.{cpp,h}` (fneg only)

**Inputs:** M10.

**Test first (red):** LIT fixture for `fneg f64` asserting `call @cq_template_fneg_f64(%a_handle)`.

**Implementation:** Detect tainted `FNegInst`; consult `OpcodeTables::lookupUnary` (single-row table — fneg at f32, f64). Tiny module.

**Acceptance:** Hand-written `fneg` LIT fixture green at both widths.

**LOC budget:** ~80 (.cpp), ~30 (.h).

### 4.15 M15 — IR pass: `CQLoweringPass.cpp` wiring

**Inputs:** M11, M12, M13, M14.

**Test first (red):** End-to-end LIT fixture exercising one compare + one cast + one unary in a single function — assert all three lowerings fire in the right order.

**Implementation:** Extend the pass pipeline to invoke `CompareLowering`, `CastLowering`, `UnaryLowering` after `OpcodeLowering`. Order is documented in pass-class comment. No interaction risk: each lowering owns a disjoint set of LLVM `Instruction::Opcode` values.

**Acceptance:** Combined LIT fixture green. Phase 1+2 pass-ordering LIT fixtures green.

**LOC budget:** `CQLoweringPass.cpp` 112 → ~140.

### 4.16 M16 — Generated LIT fixtures (~340)

**Inputs:** M2 (generator emits LIT fixtures), M11–M15 (lowering modules exist).

**Test first (red):** Adding ~340 LIT fixtures *is* the red test; they fail until the implementations are complete.

**Implementation:** Run `python3 tools/gen_templates.py --lit-dir ir-pass/test/phase3/`. Commit the output. CMake glob picks up the directory.

**Acceptance:** All ~340 generated LIT fixtures green under `ctest`. PRD §"Testing L3" full-grid coverage assertion satisfied. The `OpcodeLowering` "no template for opcode" diagnostic does not fire (PRD acceptance §9).

**LOC budget:** Generated. Each fixture ~5–10 lines × ~340 = ~2000–3400 lines total — flagged in CI as auto-generated; not subject to 300-LOC ceiling (each file is small individually).

### 4.17 M17 — Rewriter unit goldens

**Inputs:** M7, M8, M9.

**Implementation:** Author the ~25 unit goldens enumerated in §2.4. Each is an input `.cpp` snippet + a golden `.expected.cpp` rewriter output, run via the existing `transpiler/tests/unit/` harness.

**Acceptance:** All goldens green byte-exact. Phase 1+2 goldens green (regression).

**LOC budget:** ~25 files × ~50 LOC = ~1250 LOC total (test data, not subject to ceiling per-file). Harness code unchanged.

### 4.18 M18 — E2E fixtures by family (~37)

**Inputs:** M3, M4, M9, M15, M16. Full transpiler + IR pass + runtime chain must compile end-to-end.

**Implementation:** Author 37 fixtures across the 12 directories enumerated in §2.6. Each is `input.c` + `expected.log` (printf trace from the runtime stubs). The trace format is unchanged from Phase 2 (`bd remember` entry `trace-format-phase2`).

Representative samples:

```c
// tests/e2e/fixtures/phase3/int_arith/sub_qq_i32/input.c
#include <CQ.h>
int main(void) {
    quantum int a = 7;
    quantum int b = 3;
    quantum int c = a - b;
    return (int) c;
}
```

```
# tests/e2e/fixtures/phase3/int_arith/sub_qq_i32/expected.log
cq_init_si32(7) -> handle 0
cq_init_si32(3) -> handle 1
cq_template_sub_i32(0, 1) -> handle 2
cq_measure_si32(2) -> 4
```

And for the acceptance flag-flow fixture (PRD acceptance §4):

```c
// tests/e2e/fixtures/phase3/comparison_flag_flow/input.c
#include <CQ.h>
int main(void) {
    quantum int a = 5;
    quantum int b = 5;
    quantum _Bool eq = (a == b);   // flag handle
    quantum int c = eq + 1;        // flag flows into add as i1→implicit-zext→add operand
    return (int) c;
}
```

**Acceptance:** All ~37 e2e fixtures green byte-exact. Phase 1+2 e2e green (regression).

**LOC budget:** Each `input.c` + `expected.log` is ~10–30 lines; ~37 fixtures = ~600 LOC test data. Harness unchanged.

### 4.19 M19 — Full-pipeline acceptance run + closure

**Inputs:** M5, M17, M18.

**Implementation:**

1. `ctest -L phase1 && ctest -L phase2 && ctest -L phase3` — all green.
2. Confirm the `OpcodeLowering` "no template for opcode" diagnostic does not fire (PRD acceptance §9).
3. Write `phases/phase3/CLOSURE.md` summarizing what landed vs. PRD scope, recording the four ROADMAP discrepancies as enforced (PRD §"Roadmap discrepancy" 1–4).
4. Update `ROADMAP.md` Phase 3 entry: mark done, note the divergences carried forward. Same pattern as Phase 2's closure (commit `5306170`).
5. Per CLAUDE.md §"Session Completion": `git pull --rebase && git push` until the remote is up to date.

**Acceptance:** All 10 PRD §"Acceptance criteria" items satisfied. CLOSURE.md committed and pushed.

**LOC budget:** CLOSURE.md ~200 lines. No code.

## 5. Testing strategy

### 5.1 Three layers, three audiences (same as Phases 1–2)

| Layer | Audience | Phase 3 volume |
|---|---|---|
| L1 — End-to-end (acceptance) | Phase reviewers, CI gate | ~37 e2e fixtures |
| L2 — Rewriter unit goldens | Rewriter contributors | ~25 unit goldens |
| L3 — IR pass LIT/FileCheck | IR pass contributors | ~340 LIT fixtures (auto-generated) + ~25 hand-written sanity-check fixtures |

### 5.2 Test-first discipline per module

Every M{n} in §4 lists its **red test** first. The discipline:

1. **Red.** Write the failing test artifact (LIT fixture, unit golden, e2e fixture). Confirm it fails for the documented reason.
2. **Green.** Implement until the red test passes. No additional scope.
3. **Refactor.** Tighten the code; confirm the test still passes byte-exact. Run wider regression suite (Phase 1+2) and confirm no breakage.
4. **Commit.** One `bd` issue closure per module. Commit message format from Phase 2 (`phase3-M{n}: <summary>`).

Modules without red tests (M1, M5, M19) are explicitly planning / regression / closure modules.

### 5.3 Fixture growth budget

| Type | Phase 1 | Phase 2 | Phase 3 add | Phase 3 total |
|---|---|---|---|---|
| E2E fixtures | 5 | 21 | +37 | ~63 |
| Rewriter unit goldens | 6 | ~14 | +25 | ~45 |
| IR pass LIT fixtures | ~12 | ~32 | +340 | ~384 |

The LIT-fixture growth is the dominant axis; all auto-generated from `tools/opcode_table.yaml`.

### 5.4 Determinism

- Generator emits files in canonical lex-sorted order. Re-running on unchanged YAML produces byte-identical output (M2 acceptance).
- LIT fixtures use `CHECK-DAG` only where ordering is genuinely free; `CHECK-NEXT` otherwise.
- E2E logs are byte-exact compared to `expected.log` (no float-format tolerance).
- Trace format unchanged from Phase 2 (`bd remember` entry `trace-format-phase2`).

### 5.5 Phase 1+2 regression net

Every module that touches a shared file (Matcher, Codegen, CastRewrite, OpcodeLowering, CQLoweringPass) runs the Phase 1+2 fixture suites as a precondition to closing the module's `bd` issue. M5 establishes the baseline; later modules check against it.

If a refactor-only commit (e.g., M7 binop matcher extraction) breaks a Phase 1+2 fixture, the commit reverts and the refactor is reattempted. No mid-phase Phase-1/2 fixture modifications are permitted in Phase 3.

## 6. Open-items dispositions

Binding answers to every PRD §"Open items" entry. PLAN-stage, not runtime.

### 6.1 Template-stub generation mechanism

**Decision: Python script + YAML input → checked-in generated output.**

- `tools/opcode_table.yaml` — single source of truth.
- `tools/gen_templates.py` — generator; emits `cq_templates.h`, `cq_templates.c`, `OpcodeTables.cpp`, LIT fixtures.
- Outputs are **checked into git**; generator is run manually by the contributor after editing YAML. CI runs `gen_templates.py --check` and fails if checked-in output diverges from a fresh generation.

**Rejected alternatives:**

- **Hand-listing** all 680 symbols — impractical at scale; PRD §"Template surface" already rules this out.
- **X-macros in `cq_templates.h`** — works but produces opaque preprocessor expansion that's hard to inspect at the 680-symbol scale. Diff review and grep-ability suffer. Rejected.
- **Build-time codegen** (CMake `add_custom_command` runs Python at every build) — adds Python as a hard build dependency for users who only want to compile, slows incremental builds, makes the build less reproducible (different Python versions produce slightly different output). Rejected; the contributor-time codegen model is simpler and matches LLVM project norms.

### 6.2 IR-pass table representation

**Decision: split tables per opcode family.**

`OpcodeTables.cpp` declares four `static const std::array` tables:

```cpp
static constexpr BinaryOpcodeRow binaryOpcodeTable[] = { /* 17 rows */ };
static constexpr CompareRow icmpTable[] = { /* 50 rows: 10 preds × 5 widths */ };
static constexpr CompareRow fcmpTable[] = { /* 12 rows: 6 preds × 2 widths */ };
static constexpr CastRow castTable[] = { /* ~68 rows: per (kind, from, to) */ };
```

And four lookup helpers: `lookupBinaryOpcode`, `lookupCompare`, `lookupFCompare`, `lookupCast`. Each is a linear scan (table size ≤ 70 — no need for hashing).

**Rejected alternative:** single flat table keyed by tagged union — adds complexity for no gain at this size.

**Code split correspondingly:**

- `OpcodeLowering.cpp` → consumes `binaryOpcodeTable` (arith + bitwise + future unaries-that-are-actually-binary).
- `CompareLowering.cpp` → consumes `icmpTable` + `fcmpTable`.
- `CastLowering.cpp` → consumes `castTable`.
- `UnaryLowering.cpp` → consumes a small inline table (just `fneg` for now; no need for a separate file table).

### 6.3 `OperandClass` evolution

**Decision: reuse existing classifier with two new free helpers.**

- `classifyAssignLHS(BinaryOperator)` — predicate-style, returns `Quantum`/`Classical` for the LHS of an assignment.
- `classifyUnaryOperand(UnaryOperator)` — same for unary operands.

Both reuse `isQuantumDeclRef`. No new classifier types, no new state. `OperandClass.cpp` grows 38 → ~70 LOC.

### 6.4 Unary increment/decrement representation in transpiled C

**Decision: `++a` → `a.val += 1` (prefix); `a++` → save-then-`a.val += 1` (postfix).**

Form chosen for two reasons:

1. Matches the compound-assign canonical form (§6.5) — consistent with `+= 1` shape.
2. Clang's `-O1` lowering of `a.val++` and `a.val += 1` produces identical `add … 1` IR; the choice is purely cosmetic at the C output level. Going with `+= 1` keeps the rewriter's emitter uniform (no special case for `UO_PostInc`/`UO_PreInc`).

For postfix, the emitter materializes the prior value into a temp before incrementing:

```c
// Source:  quantum int b = a++;
// Output:  qint_mid_t b; b.val = a.val; a.val += 1;
```

This matches C semantics (postfix returns the prior value).

### 6.5 Compound-assign representation in transpiled C

**Decision: preserve the compound operator in the output (`a.val += b.val`), not the expanded form (`a.val = a.val + b.val`).**

Rationale: compound form is shorter, mirrors C source, and Clang lowers both to identical IR post-`-O1`. The rewriter's emitter is also simpler — it only needs to substitute `.val` for the quantum LHS reference, leaving the operator token alone.

### 6.6 LIT fixture auto-generation

**Decision: auto-generate from the same opcode table.**

The generator emits ~340 LIT fixtures into `ir-pass/test/phase3/<opcode>/`. CMake globs the directory.

**Hand-written spot-checks:** for each opcode family (binary arith, binary bitwise, fp arith, icmp, fcmp, cast, unary), one hand-written LIT fixture is committed alongside the generated set with the suffix `_hand.ll`. This catches generator drift if the script ever produces something subtly wrong. The hand-written and generated forms for the same (opcode, width) must match byte-exact under `diff`.

### 6.7 Inverse Q+C variant naming order

**Decision: `cq_template_sub_i32_hl_inv`** (modifier-then-variant, as PRD prefers).

Rationale: the `_hl` modifier tells you *what operand shape*; the `_inv` variant tells you *which direction*. Reading left-to-right, "the Q+C variant of sub at i32, inverse direction" parses cleanly. Inverting the order (`_inv_hl`) would read as "the inverse of sub at i32, Q+C variant" which is fine semantically but inconsistent with `_inv_ctrl` (Phase 4's analogous case) where the controlled variant of an inverse makes less sense than the inverse of a controlled. Pick consistent ordering up front: **modifier first, variant last.**

All ~340 symbol declarations use this convention; the generator script enforces it.

## 7. Work breakdown — `bd` issue sketches

One `bd` issue per module. Suggested titles (final wording at issue-creation time):

| `bd` # (TBD) | Title | Module |
|---|---|---|
| — | phase3-M1: open-items dispositions + opcode-table schema | M1 |
| — | phase3-M2: generator harness (tools/gen_templates.py) | M2 |
| — | phase3-M3: generated cq_templates.h | M3 |
| — | phase3-M4: generated cq_templates.c + trace exercise | M4 |
| — | phase3-M5: Phase 1+2 regression after template growth | M5 |
| — | phase3-M6: OperandClass extensions for Patterns 7–9 | M6 |
| — | phase3-M7: Matcher split + Patterns 7–9 matchers | M7 |
| — | phase3-M8: Codegen split + Patterns 7–9 emission | M8 |
| — | phase3-M9: CastRewrite Q→Q discriminator + Patterns 10, 11 | M9 |
| — | phase3-M10: OpcodeTables generated for IR pass | M10 |
| — | phase3-M11: OpcodeLowering table-driven refactor (arith + bitwise) | M11 |
| — | phase3-M12: CompareLowering (icmp + fcmp + flag handle) | M12 |
| — | phase3-M13: CastLowering (all 9 cast opcodes) | M13 |
| — | phase3-M14: UnaryLowering (fneg only) | M14 |
| — | phase3-M15: CQLoweringPass wiring | M15 |
| — | phase3-M16: generated LIT fixtures (~340) | M16 |
| — | phase3-M17: rewriter unit goldens (~25) | M17 |
| — | phase3-M18: e2e fixtures by family (~37) | M18 |
| — | phase3-M19: acceptance run + CLOSURE.md | M19 |

Each issue carries the module's red test, implementation, and acceptance criteria from §4. Issues file at M1 closure.

## 8. Risks and mitigations

### 8.1 CastLowering.cpp exceeds 300 LOC

**Why:** 9 cast opcodes × cross-pair logic is the densest hand-written file in Phase 3 (~270 projected).

**Mitigation:** Split trigger at 280 LOC into `IntCastLowering.cpp` (sext/zext/trunc) + `FpCastLowering.cpp` (fpext/fptrunc + cross-domain). Splits are mechanical: each handles a disjoint instruction set. Adds ~30 LOC of boilerplate (two files instead of one); still well under the ceiling on each.

### 8.2 Generator output drift between contributors

**Why:** If two contributors hand-edit generated files, output drifts from YAML.

**Mitigation:** CI runs `python3 tools/gen_templates.py --check` and fails on diff. Generated files carry a banner like `// AUTO-GENERATED from tools/opcode_table.yaml (SHA-256: abc123...). DO NOT EDIT.`. Contributors who try to edit generated files see the banner immediately.

### 8.3 LIT fixture count (~340) slows `ctest`

**Why:** Each LIT fixture spawns `opt` + `FileCheck`. 340 invocations may add ~30 seconds to the IR-pass test target.

**Mitigation:** Acceptable cost. `ctest -j N` parallelizes invocations. If the cost ever becomes painful, fold 5–10 small fixtures into a single multi-CHECK file (LIT supports this) — but only after the cost is felt, not preemptively.

### 8.4 Comparison flag handle ABI conflicts with Phase 4

**Why:** Phase 4's `cq_when_*` lowering consumes the flag-handle contract from Phase 3. If Phase 3's ABI choice (i32 handle indexing a logical-1-bit register) collides with what `cq_when_*` actually needs, Phase 4 may force a Phase 3 retrofit.

**Mitigation:** The flag handle is **indistinguishable from any other handle at the ABI** (PRD §"Comparison contract"). Phase 4's `cq_when_*` accepts any tainted handle — i1-semantic or otherwise. The retrofit risk is bounded to "Phase 4 may add a width-check assertion that the handle's logical register is 1-bit" — additive, not breaking.

### 8.5 Inverse stubs declared but unused until Phase 5

**Why:** ~340 inverse symbol declarations sit in `cq_templates.h` for ~6 phases before Phase 5 wires them up.

**Mitigation:** This is the frontend-complete contract by design (PRD §"Stub template library"). The declarations are tiny printf bodies; binary footprint is negligible. Phase 5's auto-uncomp lands and plugs into them; no Phase 3 retrofit needed.

### 8.6 `OperandClass` extensions interact badly with Patterns 7–9 mixed-operand cases

**Why:** Compound assignment `a += b` where `a` and `b` have different mid-types (e.g., `quantum int a; quantum long b; a += b;`) implicitly truncates `b` — does the operand classifier correctly identify the LHS-quantum-ness through the implicit cast?

**Mitigation:** Acceptance fixture `tests/e2e/fixtures/phase3/compound_assign/mixed_width/` exercises this case end-to-end. PRD §"Known soft-failure modes" notes it should work mechanically; the e2e fixture is the verification. If it fails, `OperandClass` gets a `walkThroughImplicitCasts` helper (~15 LOC addition).

### 8.7 Auto-generated LIT fixtures hide a generator bug

**Why:** If `gen_templates.py` emits a subtly wrong LIT pattern (e.g., wrong width in the CHECK line), all 340 fixtures pass against a correspondingly-wrong implementation.

**Mitigation:** Hand-written spot-check fixtures per family (§6.6). The generated and hand-written forms for the same case must match byte-exact under `diff`. Self-test `gen_templates_test.py` verifies generator structural invariants. Catching every possible generator bug is impractical; the spot-checks bound the blast radius.

## 9. Done definition

Phase 3 is done when **all** PRD §"Acceptance criteria" hold AND:

- All 19 modules' `bd` issues are closed.
- `CLOSURE.md` is committed and pushed (per CLAUDE.md §"Session Completion").
- ROADMAP.md Phase 3 entry is marked done, with the four divergences from §"Roadmap discrepancy" recorded.
- The generator self-test (`tools/gen_templates_test.py`) passes.
- The generator `--check` mode passes against the checked-in outputs.
- No new compiler warnings introduced (build under `-Wall -Wextra -Wpedantic` clean).
- Phase 1 + Phase 2 fixtures green (regression preserved).
- `git push` succeeds; `git status` reports up-to-date with origin.

## 10. Out of scope (mirror of PRD §"Out of scope")

| Phase | Item |
|---|---|
| 4 | Controlled-forward template variants (`_ctrl` / `_hl_ctrl`); `cq_when_*` region detection in IR pass; quantum-condition `if` rewriter pattern; `&&`/`||`/ternary lowering |
| 5 | Auto uncomputation IR-pass logic that *consumes* the `_inv` stubs declared in Phase 3; active source-location diagnostics for non-reversibilizable use |
| 6 | `for` loops with classical bounds |
| 7 | User-defined quantum functions + inversion; XOR-copy template family + IR-pass copy detection at call boundaries |
| 8 | Arrays/pointers; QRAM; copy emission for memory-stored quantum |
| 9 | `struct` / `union` / `_Complex` / remaining C surface |
| 10 | Quantum-conditioned `while` |
| 11 | Frontend freeze; ABI lock |
| Backend | Real `cq_template_*` and `cqrt_*` bodies; 3.3-style classical-mask bit-view materialization; `_Float16` / `long double`; fcmp unordered preds if needed |

## References

- [`PRD.md`](PRD.md) — Phase 3 contract definitions
- [`../phase2/PLAN.md`](../phase2/PLAN.md) — predecessor PLAN; module structure and `bd`-tracking pattern carry forward
- [`../phase2/CLOSURE.md`](../phase2/CLOSURE.md) — predecessor closure-note pattern (mirror in M19)
- [`../../ROADMAP.md`](../../ROADMAP.md) §Phase 3 — phase definition (with the divergences called out in PRD §"Roadmap discrepancy")
- [`../../docs/architecture.md`](../../docs/architecture.md) §5 (rewriter), §6 (intrinsic surface), §7 (IR pass)
- [`../../docs/backend.md`](../../docs/backend.md) §5.6 (template selection), §5.7 (lowering map), §5.8 (inverse generation), §7 (template library)
- [`../../CLAUDE.md`](../../CLAUDE.md) — `bd` workflow + session-completion protocol
