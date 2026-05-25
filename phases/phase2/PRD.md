# CQ_lang Phase 2 PRD — Type System Breadth

## Goal

Extend the Phase 1 vertical slice from `quantum int` only to **every C integer width and signedness, plus `_Bool` and the two IEEE float widths**. The pipeline shape, intrinsic surface mechanics, IR-pass machinery, and runtime ABI established in Phase 1 are unchanged; Phase 2 is "Phase 1 × N widths" with per-signedness type identity threading.

**Backend implementation remains explicitly out of scope.** All new `cq_template_*` bodies and `cqrt_*` runtime symbols added in Phase 2 are trace-only `printf` stubs, consistent with the frontend-first design principle ([`ROADMAP.md`](../../ROADMAP.md) §Design principles).

## Scope

Phase 2 broadens Phase 1's `quantum int` slice along three orthogonal axes:

1. **Integer widths** — `quantum char`, `quantum short`, `quantum int`, `quantum long`, `quantum long long`, both signed and unsigned (where C distinguishes them)
2. **Boolean** — `quantum _Bool` (alias `quantum bool` via `<stdbool.h>`)
3. **Floating point** — `quantum float`, `quantum double` (first-class at the intrinsic-surface and ABI level; templates remain stubs)

Plus, derived from those:

4. **Same-type quantum-to-quantum assignment** (`quantum T b = a;`) — passes through as ordinary C field assignment; SROA erases it in Phase 2's scope, so no copy template is emitted (see §"On assignment and surviving operations")
5. **Measurement-as-cast** generalized across all widths (`(T) q` for any supported `T`)
6. **`<stdint.h>` typedef compatibility** (`quantum int8_t`, `quantum uint32_t`, etc.) — falls out for free via Clang canonical type resolution

No new operators beyond `+` (Phase 3 brings the rest). No control flow, no functions, no inversion, no uncomputation, **no copy templates** (deferred to whichever phase first introduces surviving assignments — Phase 7/8/9). Same pipeline, same architectural mechanisms; broader type coverage.

## Marker syntax (input)

Unchanged from Phase 1. `quantum` is the macro defined in `<CQ.h>`. The rewriter matches on `AnnotateAttr("quantum")` on `VarDecl`s.

## Supported source patterns and rewrites

The table below extends Phase 1's pattern set. Patterns 1–5 are Phase 1's, generalized across widths. Pattern 6 is new (pure quantum-to-quantum assignment) and uses the same split-form shape as Phase 3.

| # | Source | Rewritten output |
|---|---|---|
| 1 | `quantum T x;` | `qT_mid_t x = cq_init_<sfx>(0);` |
| 2 | `quantum T x = E;` (E classical) | `qT_mid_t x = cq_init_<sfx>(E);` |
| 3 | `quantum T z = a + b;` (both `quantum T`) | `qT_mid_t z; z.val = a.val + b.val;` |
| 4 | `quantum T z = a + E;` (`a` quantum T, `E` classical) | `qT_mid_t z; z.val = a.val + E;` |
| 5 | `(T) q` (`q` quantum T) | `cq_measure_<sfx>(q)` |
| 6 | `quantum T b = a;` (`a` quantum T) | `qT_mid_t b; b.val = a.val;` |

Where `T` ranges over all supported quantum-typed types, `<sfx>` is the per-mid-struct suffix per the table in §"Type map" below, and `qT_mid_t` is the corresponding mid-struct typedef.

**Mixed-width arithmetic** (e.g., `quantum int a + quantum long b`) compiles through the rewriter (no special handling — Clang's usual arithmetic conversions auto-emit `sext`/`zext`+`add`), but the resulting `sext`/`zext` opcodes have no template in Phase 2 and will fail at IR-pass lowering. This is acceptable for Phase 2 and is the explicit motivation for ROADMAP §3.4 "Mixed-width type promotion" being a Phase 3 deliverable.

### Why no special-case rewriter logic for `_Bool` or floats

Patterns 1–6 work uniformly for every type because the rewriter's role ends at translating `quantum T` to `qT_mid_t` and threading `.val`-field arithmetic. The C type of `.val` (e.g., `_Bool`, `int32_t`, `float`) drives Clang's LLVM opcode selection:

- `qbool_mid_t b; b.val = x.val;` (where `b.val` is `_Bool`, `x.val` is `int32_t`) → Clang emits `icmp ne i32 + zext i1 to i8` automatically, reflecting C's "any nonzero → 1" semantics for `_Bool`.
- `qfloat_mid_t z; z.val = a.val + b.val;` (where `.val` is `float`) → Clang emits `fadd float` automatically.
- Sign-dependent operations (`sdiv` vs `udiv`, `sext` vs `zext`, signed/unsigned compares) follow from the per-signedness `.val` type in each mid-struct (see §"Type map").

The IR pass dispatches per LLVM opcode — it never inspects mid-struct names to decide signedness. Signedness threading is purely the rewriter's responsibility (assign the correct mid-struct type) and Clang's responsibility (emit the correct opcode from the `.val` type).

## Type map

Phase 2's mid-struct family. Each is a thin wrapper `struct { T val; }` whose `.val` field carries the C-source-level type Clang uses for opcode selection. After IR-pass lowering, every mid-struct collapses to an opaque `int32_t handle` at the runtime ABI — the `.val` type is irrelevant past the IR pass.

| C type | Mid-struct typedef | Suffix |
|---|---|---|
| `_Bool` / `bool` | `qbool_mid_t`        | `i1`     |
| `char`               | `qchar_mid_t`        | `c`      |
| `signed char`        | `qschar_mid_t`       | `si8`    |
| `unsigned char`      | `quchar_mid_t`       | `ui8`    |
| `short`              | `qshort_mid_t`       | `si16`   |
| `unsigned short`     | `qushort_mid_t`      | `ui16`   |
| `int`                | `qint_mid_t`         | `si32`   |
| `unsigned int`       | `quint_mid_t`        | `ui32`   |
| `long`               | `qlong_mid_t`        | `sl`     |
| `unsigned long`      | `qulong_mid_t`       | `ul`     |
| `long long`          | `qlonglong_mid_t`    | `sll`    |
| `unsigned long long` | `qulonglong_mid_t`   | `ull`    |
| `float`              | `qfloat_mid_t`       | `f32`    |
| `double`             | `qdouble_mid_t`      | `f64`    |

**14 mid-struct types.** Note the char asymmetry: C treats `char`, `signed char`, and `unsigned char` as three distinct types (even when `char` has the same representation as one of the other two on a given target). All other integers have only two (signed/plain ≡ same type, unsigned distinct). The rewriter honors C's type distinctness directly.

**Carry-forward from Phase 1.** `qint_mid_t` keeps its existing definition (`struct { int32_t val; }`); Phase 1 e2e and unit tests remain green with no edits.

**Target-dependence of `long`.** `qlong_mid_t`'s `.val` is `long` (target-dependent: usually 32-bit on Windows, 64-bit on Linux/macOS). This is consistent with C's policy. Suffixes (`sl`/`ul`) abstract over the underlying width so the rewriter's mapping table doesn't need to fork per target.

**`<stdint.h>` typedefs.** `quantum int8_t`, `quantum uint32_t`, etc. work automatically: Clang's `getCanonicalType()` resolves the typedef to the underlying type before `TypeMap` consults its table. `int8_t` → `signed char` → `qschar_mid_t`, etc.

## Intrinsic surface (cq_mid.h additions)

For each mid-struct type, Phase 2 declares three intrinsics: init, measure, and copy.

```c
/* Init — from classical value */
qbool_mid_t        cq_init_i1(_Bool value);
qchar_mid_t        cq_init_c(char value);
qschar_mid_t       cq_init_si8(int8_t value);
quchar_mid_t       cq_init_ui8(uint8_t value);
qshort_mid_t       cq_init_si16(int16_t value);
qushort_mid_t      cq_init_ui16(uint16_t value);
qint_mid_t         cq_init_si32(int32_t value);     /* renames Phase 1's cq_init_i32 */
quint_mid_t        cq_init_ui32(uint32_t value);
qlong_mid_t        cq_init_sl(long value);
qulong_mid_t       cq_init_ul(unsigned long value);
qlonglong_mid_t    cq_init_sll(long long value);
qulonglong_mid_t   cq_init_ull(unsigned long long value);
qfloat_mid_t       cq_init_f32(float value);
qdouble_mid_t      cq_init_f64(double value);

/* Measure — to classical value */
_Bool              cq_measure_i1(qbool_mid_t q);
char               cq_measure_c(qchar_mid_t q);
int8_t             cq_measure_si8(qschar_mid_t q);
/* … one per mid-struct, signature mirrors init */

```

**Total declarations:** 14 mid-structs × 2 intrinsics (init + measure) = **28 intrinsic functions**.

No `cq_copy_<sfx>` intrinsic — see §"On assignment and surviving operations" below for the reasoning.

**Phase 1 rename.** `cq_init_i32` / `cq_measure_i32` are renamed to `cq_init_si32` / `cq_measure_si32` to fit the per-signedness suffix scheme. Phase 1's e2e and unit tests are repointed; no semantics change.

**No other intrinsic families in Phase 2.** Rotations (`cq_theta`, `cq_phi`), control regions (`cq_when_*`), inversion regions (`cq_invert_*`), and specialization-mangling intrinsics are out of scope. Each phase that introduces a new family declares its own intrinsics. This is a deliberate divergence from ROADMAP §Phase 2's "CQ.h: full intrinsic-surface declarations (six families per architecture.md §6)" wording — see §"Roadmap discrepancy" below.

## Stub `libcq_runtime` (extends Phase 1)

Per-width runtime symbols. Phase 1's split between `cqrt_alloc_classical_<W>` and `cqrt_alloc_<W>` is collapsed into a single allocation function per width: every allocation takes an initial classical value (the IR pass passes `0` for fresh-result allocations, the actual value for user-init).

```c
/* Allocation — one per width, takes initial classical value */
int32_t cqrt_alloc_i1(_Bool value);
int32_t cqrt_alloc_i8(int8_t value);            /* serves char / signed char / unsigned char */
int32_t cqrt_alloc_i16(int16_t value);          /* serves short / unsigned short */
int32_t cqrt_alloc_i32(int32_t value);          /* serves int / unsigned int */
int32_t cqrt_alloc_i64(int64_t value);          /* serves long / unsigned long / long long / unsigned long long on 64-bit targets */
int32_t cqrt_alloc_f32(float value);
int32_t cqrt_alloc_f64(double value);

/* Measurement — one per width */
_Bool   cqrt_measure_i1(int32_t handle);
int8_t  cqrt_measure_i8(int32_t handle);
/* … one per width, signature mirrors alloc */

/* Free — shared (handle-typed only, width-irrelevant) */
void    cqrt_free(int32_t handle);
```

**Total:** 7 widths × 2 (alloc + measure) + 1 (free) = **15 runtime symbols** (Phase 1 had 3; net add of 12).

**Width unification at the runtime ABI.** Signedness is a frontend-only concept (it threads through the rewriter's mid-struct choice and Clang's opcode selection). The runtime sees only widths, so `signed char` and `unsigned char` both call `cqrt_alloc_i8`. The runtime's stub `printf` trace line includes the width suffix but not signedness — signedness is implicit in the LLVM opcode at the call site, not in the runtime symbol.

**Target-dependence of `long`.** On 64-bit Linux/macOS, `qlong_mid_t` lowers to `cqrt_alloc_i64`; on Windows or 32-bit targets, to `cqrt_alloc_i32`. The IR pass derives this from `DataLayout` at lowering time, same way `TypeMap` derives it for the rewriter.

**Reasoning for collapsing alloc.** Phase 1 had two alloc functions because architecture.md sketched a backend distinction between "alloc with classical initial value" (preserved as classical bits until R_y application promotes to qubit) and "fresh ancilla alloc" (already a qubit). For the frontend, this distinction is invisible — every allocation that the IR pass emits has *some* initial classical value (0 for fresh result registers, the user's value for explicit inits). Collapsing to one function removes a runtime symbol that exists only to signal a backend optimization hint the frontend has no concept of.

## Stub template library (extends Phase 1)

Phase 2 ships templates for one operation: `add` (the Phase 1 operator, generalized to all widths). No copy templates — see §"On assignment and surviving operations" below.

```c
/* Add — Q+Q and Q+C, per width */
int32_t cq_template_add_i1(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_i1_hl(int32_t a_handle, _Bool b_classical);
int32_t cq_template_add_i8(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_i8_hl(int32_t a_handle, int8_t b_classical);
int32_t cq_template_add_i32(int32_t a_handle, int32_t b_handle);   /* renamed from Phase 1 */
int32_t cq_template_add_i32_hl(int32_t a_handle, int32_t b_classical);
int32_t cq_template_add_i64(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_i64_hl(int32_t a_handle, int64_t b_classical);
int32_t cq_template_add_f32(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_f32_hl(int32_t a_handle, float b_classical);
int32_t cq_template_add_f64(int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_f64_hl(int32_t a_handle, double b_classical);
```

**Total:** 7 widths × 2 (add + add_hl) = **14 template stubs** (Phase 1 had 2; net add of 12).

**Inverse and controlled variants deferred.** Phase 3 brings controlled-forward variants for all opcodes (needed for Phase 4); Phase 5 brings inverse variants (needed for uncomputation). Phase 2's `cq_template_*` stubs are forward-only and uncontrolled.

## On assignment and surviving operations

Pattern 6 (`quantum T b = a;` rewritten to `qT_mid_t b; b.val = a.val;`) emits **no copy template** in Phase 2. The reasoning, which is load-bearing for Phase 2's scope:

**The rule.** The frontend emits a quantum operation if and only if Clang's `-O1` optimization leaves the corresponding C operation visible in the LLVM IR the cq-lowering pass sees. Operations that Clang's SROA + mem2reg erase as dead/redundant are *correctly* erased — the user expressed an intent that the compiler proved unnecessary, and forcing a quantum operation to survive when classical optimization erased it would emit useless work.

**Consequence for Phase 2.** Phase 2's scope contains no functions (Phase 7), no structs/unions (Phase 9), and no arrays/pointers (Phase 8). Every quantum variable lives in a local alloca that SROA can promote to SSA. Local same-type assignment (Pattern 6) under SROA collapses to SSA aliasing — the assigned-to variable evaporates entirely. **There is nothing for the IR pass to lower into a copy.** Phase 2 fixtures will show zero `cq_template_copy_*` calls in their trace logs, and that is the correct trace.

**Worked example.**

```c
quantum float a = 5.0f;
quantum float b = a;
quantum float c = b + 2.0f;
(float) c;
```

After Stage 3 (`clang -O1 -emit-llvm`), SROA flattens the mid-structs and `b` becomes an SSA alias of `%a_val`:

```llvm
%a_val = call float @cq_init_f32(float 5.0)
%c_val = fadd float %a_val, 2.0       ; "b.val + 2.0" became "%a_val + 2.0"
%result = call float @cq_measure_f32(float %c_val)
```

The IR pass sees `cq_init_f32`, `fadd`, and `cq_measure_f32` — three operations — and lowers each per Phase 1's machinery generalized across widths. Trace:

```
cqrt_alloc_f32(5.0) -> handle_1
cq_template_add_f32_hl(handle_1, 2.0) -> handle_2
cqrt_measure_f32(handle_2) -> 0.0
```

No copy. `b` was never an independent register because Clang proved it never needed to be one.

**Edge case: shared handle when both `a` and `b` are measured.**

```c
quantum int a = 5;
quantum int b = a;
(int) a;
(int) b;
```

SROA erases `b`, so both measurements lower to the same handle:

```
cqrt_alloc_i32(5) -> handle_1
cqrt_measure_i32(handle_1) -> 0       # for a
cqrt_measure_i32(handle_1) -> 0       # for b — same handle
```

This is semantically equivalent to a real CNOT-copied `b` (entangled values would yield the same measurement outcomes anyway), and is the **expected, correct** trace shape — *not* a bug to be flagged. Per ROADMAP design principle 5 ("C philosophy: no foot-gun protection"), the compiler does not detect or warn about cases where the user might have *meant* two independent registers. If the user wants behavior that requires two physically independent registers, they will need to introduce an operation that forces the copy (none such exist in Phase 2).

**Where `cq_template_copy_<W>` becomes relevant.** Future phases introduce constructs that produce surviving assignments:

- **Phase 7** (functions): quantum-typed arguments / returns cross call boundaries; SROA cannot prove the receiver and sender are the same value. The IR pass will need to emit `cq_template_copy_<W>` at call boundaries.
- **Phase 8** (arrays / pointers): quantum stored in addressable memory survives SROA.
- **Phase 9** (structs): quantum-as-struct-member survives SROA.
- **Later phase** (taint optimization): refine the copy emissions from Phases 7–9 — elide copies whose source isn't independently consumed downstream. This is the "we want some `cq_copies` not to be required" optimization, and it operates on top of whichever phase first emits copies.

Phase 2 ships **no** machinery for any of these. The copy template family, the IR-pass copy-detection logic, and the taint-elision optimizer are all explicitly future-phase concerns.

## Rewriter changes

Purely additive on Phase 1's code paths. No new files; no new architectural mechanisms; no new AST pattern recognition (Pattern 6 is a new AST shape but uses the existing `VarDecl + AnnotateAttr` recognition).

| Module | Change |
|---|---|
| `TypeMap` (existing)        | Already supports width resolution via `TargetInfo`. Phase 2 extends the mapping table to cover all 14 mid-struct types and exposes a suffix selector (`<sfx>` lookup keyed by canonical type) for use by `Codegen` and `CastRewrite`. |
| `Codegen` (existing)        | Replace i32-hardcoded init emission with `cq_init_<sfx>` lookup via `TypeMap`. Add Pattern 6: detect pure quantum-to-quantum same-type assignment (`VarDecl` initializer is a `DeclRefExpr` to a quantum VarDecl of the same canonical type) and emit the split form `qT_mid_t b; b.val = a.val;` (no intrinsic call — Clang's SROA erases this in Phase 2's scope, see §"On assignment and surviving operations"). |
| `CastRewrite` (existing)    | Replace i32-hardcoded `cq_measure_i32` emission with `cq_measure_<sfx>` lookup via `TypeMap`. |
| `DeclStmtRewrite` (existing)| Extend keyword recognition (already handles `int`; extend to `char`/`short`/`long`/`long long`/`_Bool`/`bool`/`float`/`double`, signed and unsigned). Multi-decl decomposition logic unchanged. |
| `Matcher` (existing)        | No semantic change. Verify `quantum`-attribute matching is type-agnostic (likely already true). |

**No QQ/QC dispatch.** Same as Phase 1 (architecture.md §5.2). Pattern 4's classical operand splices into stock `.val` arithmetic; the IR pass identifies quantum-ness via taint propagation. Phase 2 inherits this discipline; the rewriter does *not* sprout per-pattern QQ/QC branches per width.

## IR pass changes

Productionizes the Phase 1 i32-only lowering into a width-parametric form. No new prototype slices needed (`cq-uncompute`, `cq-control`, `cq-specialize` remain prototypes until their phases land).

| Stage | Phase 1 | Phase 2 |
|---|---|---|
| Forward taint propagation | Hardcoded `@cq_init_i32` as taint source | Loop over all `@cq_init_<sfx>` symbols; same propagation rules |
| Mid → handle rebinding   | Hardcoded `qint_mid_t` recognition | Lookup table keyed by all 14 mid-struct names |
| `@cq_init_<sfx>` lowering | Single rule: `→ cqrt_alloc_classical_i32(value)` | Per-suffix rule: `→ cqrt_alloc_<W>(value)` with W derived from sfx |
| Tainted op lowering       | `add i32` → `cq_template_add_i32` (Q+Q) / `_hl` (Q+C) | Loop over `add <W>` and `fadd <W>` per supported width; same Q+Q vs Q+C dispatch via operand-taint inspection |
| `@cq_measure_<sfx>` lowering | Single rule: `→ cqrt_measure_i32(handle)` | Per-suffix rule: `→ cqrt_measure_<W>(handle)` |
| Copy / assignment lowering | (not in Phase 1) | **None.** SROA erases Pattern 6 assignments before the IR pass sees them; no IR-level evidence of assignment remains. See §"On assignment and surviving operations". |

**Width inference at the IR-pass level.** The IR pass uses LLVM `Type::getIntegerBitWidth()` (or the float type's IEEE classification) on the tainted instruction's operands to select the runtime/template symbol. Suffix-level signedness information is *not* needed at the IR-pass level — Clang has already encoded signedness in the opcode (`sdiv`/`udiv`, `sext`/`zext`, signed/unsigned compares). Phase 2 only emits `add` templates, which are sign-agnostic in two's complement, so signedness threading exercises in the rewriter+`TypeMap` only.

**No new mechanism.** Same taint propagation, same mid→handle rebinding, same template-call substitution. Phase 2 is a parameterization of Phase 1.

## CQ.h / cq_mid.h split (clarification)

Phase 1's split is **unchanged in Phase 2**:

- **`include/CQ.h`** — user-facing; minimal. Contains the `quantum` keyword macro and (optionally) a `CQ_VERSION` macro. The user writes `#include <CQ.h>` and nothing else.
- **`include/cq_mid.h`** — transpiler-emitted into rewriter output via `cqc`'s `-include cq_mid.h` flag. Contains all mid-struct typedefs and intrinsic forward declarations. The user never `#include`s this directly.

**Roadmap discrepancy.** ROADMAP §Phase 2's text "CQ.h: full intrinsic-surface declarations (six families per architecture.md §6)" is imprecise — it conflates the two headers and overstates Phase 2's intrinsic-family scope. The intrinsic surface lives in `cq_mid.h`, not `CQ.h`, and Phase 2 introduces only the **init / measure / copy** intrinsic family (a subset of architecture.md §6's six). Other families (rotations, regions, etc.) are deferred to the phases that consume them, where they will be added to `cq_mid.h` incrementally. ROADMAP wording to be tightened as a follow-up edit (not a Phase 2 deliverable; see "Out of scope" below).

## `cqc` driver

Unchanged from Phase 1 in shape; needs no per-width awareness because cqc just orchestrates the pipeline stages by symbol/path, not by type semantics. Verify that the `-include cq_mid.h` thread-through still works after `cq_mid.h` grows.

## Diagnostics baseline

Unchanged from Phase 1 — passive `SourceLocation` and `!dbg` preservation only. No active diagnostics in Phase 2.

**Known soft-failure modes** (acceptable for Phase 2; will harden in later phases):

- Mixed-width arithmetic (e.g., `quantum int + quantum long`) lowers to `sext`/`zext` opcodes that have no template registered. The IR pass will fail at lowering with an opaque "no template for opcode" error. Phase 3 ships the missing templates; Phase 5 adds source-location-precise diagnostics for this and similar gaps.
- Same with any operator besides `+` (will appear as "no template for `sub i32`" etc. if exercised).
- Cross-type assignment (e.g., `quantum int b = q_long;`) lowers via Clang's implicit conversion, hits the same template gap.

These are documented as known limitations; Phase 2 tests do not exercise them.

## Testing

Three layers, same as Phase 1.

### Layer 1 — End-to-end (acceptance contract)

One e2e fixture per mid-struct type, each consisting of `input.c` + golden `expected.log`. Pattern coverage per fixture:

- Init (Pattern 2)
- Same-type quantum-to-quantum assignment (Pattern 6) — golden shows **no** copy-template lines; the assigned-to variable is correctly absent from the trace
- Q+Q add (Pattern 3)
- Q+C add (Pattern 4)
- Measurement (Pattern 5)

That's **14 e2e fixtures** (one per mid-struct type). Plus the Phase 1 fixtures (`worked_example`, `mixed_operand`, `multi_decl`, `full_example`) remain green after the `cq_init_i32` → `cq_init_si32` rename.

Additionally, one or two **typedef fixtures** (`quantum int8_t`, `quantum uint32_t`) to confirm canonical-type resolution works end-to-end. And at least one **shared-handle measurement fixture** (the edge case in §"On assignment and surviving operations") to lock in the expected trace shape when both `a` and `b = a` are measured.

### Layer 2 — Rewriter unit tests

Extend `transpiler/tests/unit/` with per-type goldens covering all six patterns × the 14 mid-struct types where applicable. Mechanical extension of the existing fixture-driven harness; no new harness machinery.

### Layer 3 — IR pass unit tests

LIT + FileCheck on hand-written `.ll` fragments covering:

- `@cq_init_<sfx>` → `cqrt_alloc_<W>` per width
- Tainted `add <W>` / `fadd <W>` → `cq_template_add_<W>(_hl)` per width
- `@cq_measure_<sfx>` → `cqrt_measure_<W>` per width

Roughly one fixture per (operation, width) combination; ~22 LIT fixtures.

## Out of scope (deferred to later phases)

| Phase | Item |
|---|---|
| 3 | All operators except `+` (`-`, `*`, `/`, `%`, bitwise, comparison, unary, casts beyond measurement); controlled-forward template variants; mixed-width promotion (`sext` / `zext` templates); classical-mask views (`q & C`) |
| 4 | `if (q_cond)` → `cq_when_*` regions |
| 5 | Auto uncomputation; inverse-template variants; real diagnostics |
| 6 | `for` loops |
| 7 | User-defined quantum functions; `invert(...)`; **`cq_template_copy_<W>` family + IR-pass copy detection at call boundaries** (first phase where assignments survive SROA) |
| 8 | Quantum arrays; QRAM; copy emission for memory-stored quantum |
| 9 | `struct` / `union` / **`_Complex`** / remaining C surface; copy emission for struct-member-stored quantum (note: `_Complex` is deferred here, not Phase 2 as ROADMAP §Phase 2 initially claimed — `_Complex T` arrives at the rewriter as an AST node before Clang's lowering and requires struct-with-quantum-members handling) |
| Late | **Taint-optimization pass** to elide unnecessary `cq_template_copy_<W>` calls emitted by Phases 7–9 (the "some cq_copies might not be required" optimization) |
| 10 | Quantum-conditioned `while` |
| 11 | Frontend freeze; ABI lock; ROADMAP wording cleanup (CQ.h vs cq_mid.h, `_Complex` placement) |
| Backend | All real `cq_template_*` and `cqrt_*` bodies; classical simulation; OpenQASM emission; hardware transport |
| Backend | `_Float16` and `long double` (per backend.md §3.3) |

## Deliverables

### New files

- `tests/e2e/<per-type>/` — 14 new fixture directories (or one consolidated `tests/e2e/types/` with subdirs per type)
- `ir-pass/test/<per-width>/` — additional LIT fixtures per width

### Modified files

- `include/cq_mid.h` — grows from 1 mid-struct + 2 intrinsics to 14 mid-structs + 28 intrinsics
- `runtime/cq_runtime.c` + `runtime/cq_runtime.h` — collapse `cqrt_alloc_classical_*` and `cqrt_alloc_*` into single `cqrt_alloc_<W>(value)`; add per-width alloc + measure stubs (15 total runtime symbols)
- `runtime/cq_templates.c` + `runtime/cq_templates.h` — add per-width `cq_template_add_<W>(_hl)` stubs (14 total template symbols; no copy templates in Phase 2)
- `transpiler/src/Codegen.cpp` — generalize init emission; add Pattern 6 (split-form pass-through, no intrinsic)
- `transpiler/src/CastRewrite.cpp` — generalize measure emission
- `transpiler/src/DeclStmtRewrite.cpp` — extend quantum-keyword recognition to all widths/signedness/bool/float
- `transpiler/src/TypeMap.cpp` + `TypeMap.h` — extend mapping table to 14 types; add suffix accessor
- `transpiler/tests/unit/` — repoint existing goldens (`cq_init_i32` → `cq_init_si32`) and add per-type goldens
- `ir-pass/CQPass.cpp` — width-parametric versions of taint, mid→handle rebinding, and lowering rules
- `tests/e2e/` — Phase 1 fixtures repointed for the `_i32` → `_si32` rename
- `ROADMAP.md` — minor wording correction at Phase 2 (`CQ.h` → `cq_mid.h`; `_Complex` moved to Phase 9 explicitly) — *optional, may be deferred to Phase 11 doc-cleanup pass*

### Renamed (Phase 1 carry-forward)

- `cq_init_i32` → `cq_init_si32` (and corresponding `cqrt_alloc_classical_i32` → `cqrt_alloc_i32` per the alloc collapse)
- `cq_measure_i32` → `cq_measure_si32`

### Retired

- `cqrt_alloc_classical_<W>` symbols (collapsed into `cqrt_alloc_<W>(value)`)

## Acceptance criteria

Phase 2 is done when **all** of the following hold:

1. All 14 mid-struct types compile end-to-end through the pipeline for each of Patterns 1–6.
2. The 14 per-type e2e fixtures produce byte-exact golden call logs.
3. The typedef compatibility fixtures (`quantum int8_t`, `quantum uint32_t`) produce expected golden logs identical to their canonical-type counterparts.
4. All Phase 1 e2e fixtures pass under the renamed-intrinsic surface (`_si32` instead of `_i32`).
5. Layer 2 (rewriter unit) and Layer 3 (IR pass unit) tests are green.
6. No regression in Phase 1 fixtures' performance (Phase 2 is purely additive; compile-time should not measurably change).

## Open items (decided in implementation)

These do not block PRD acceptance but are tracked as in-flight implementation decisions:

- **Exact suffix scheme.** The table above uses `si32`/`ui32`/`sl`/`ul`/`f32`/`f64`. Alternative schemes (`s32`/`u32`, `sli`/`uli`, `flt`/`dbl`) are equally defensible. Pinned by the first batch of generated code.
- **Whether `qchar_mid_t` needs its own alloc symbol or aliases `cqrt_alloc_i8`.** Current design aliases (all 8-bit ints share `cqrt_alloc_i8`); revisit if backend-tracing needs to distinguish plain `char` from `signed char` / `unsigned char` (probably it doesn't, since the LLVM opcode at the call site already carries signedness for sign-dependent ops).
- **Whether to also rename `qint_mid_t` → `qsint_mid_t`** for consistency with the new suffix scheme, or keep `qint_mid_t` as the plain-`int` mid-struct name. Recommendation: keep `qint_mid_t` (minimizes Phase 1 churn; `qint` clearly maps to `int`, which is signed by C convention).
- **Float `_Bool` cast semantics.** `(_Bool) q_float` lowers to `fcmp une float %v, 0.0` + `zext`. No special handling needed; just confirm the IR pass dispatches `fcmp` correctly (Phase 3 ships the actual `fcmp` template; Phase 2's e2e fixture for `quantum float` does not exercise `(_Bool)` cast).
- **`<stdbool.h>` interaction.** `bool` is `#define bool _Bool` from `<stdbool.h>`. If the user writes `quantum bool`, Clang sees `quantum _Bool` post-preprocessing. Confirm no surprises; add an e2e fixture using `bool` instead of `_Bool` to lock the behavior.
- **Exact text of `cqrt_alloc_<W>` printf trace lines for the new widths.** Pinned by the first golden fixture per width.

## References

- [`ROADMAP.md`](../../ROADMAP.md) §Phase 2 — phase definition (with the imprecisions called out above)
- [`docs/architecture.md`](../../docs/architecture.md) — §3 (three-level qint_t), §5 (rewriter), §6 (intrinsic surface), §7 (IR pass), §12 (open design questions including bool/control-flow interaction)
- [`docs/backend.md`](../../docs/backend.md) — §3.3 (float handling rationale), §4 (mid-struct), §6 (runtime ABI)
- [`docs/quantum-classical-handling.md`](../../docs/quantum-classical-handling.md) — mixed-operand semantics
- [`phases/phase1/PRD.md`](../phase1/PRD.md) — predecessor; Phase 2 generalizes Phase 1's i32 slice across widths

## Task tracking

Implementation work is tracked in **beads** (`bd`) per project convention. See [`CLAUDE.md`](../../CLAUDE.md).
