# CQ Frontend — User-Facing Surface

What the algorithm author writes, and what the compiler does with it
before any IR pass runs. The frontend under the taint-driven design is
deliberately minimal: a small intrinsic surface declared in `CQ.h`,
parsed by stock Clang, lowered by `-O1` into stock LLVM IR. There is no
rewriter; there are no special types.

Companion documents:
- [`backend.md`](./backend.md) — what the IR pass and runtime do with
  the IR the frontend hands off
- [`quantum-classical-handling.md`](./quantum-classical-handling.md) —
  taint as the Q/C boundary, mixed-operand semantics
- [`llvm-implementation.md`](./llvm-implementation.md) — the stock LLVM
  C++ APIs the whole pipeline depends on
- [`rationale/proposal-taint-driven-pipeline.md`](./rationale/proposal-taint-driven-pipeline.md)
  — the proposal that motivated the current design

---

## 1. Scope

This document defines:

- The user-facing intrinsic surface in `CQ.h`
- What plain C constructs become quantum operations, and where the
  boundary is
- The contract between source-level CQ and the LLVM IR the backend
  consumes
- The function-lifting model — how classical functions become quantum
  ones without source modification
- Explicit measurement as the sole sink
- The compilation flow (3 stages)

It does **not** define:

- IR-pass transformations — see [`backend.md`](./backend.md)
- Runtime ABI (`cqrt_*`, `cq_template_*` calls) — see
  [`backend.md`](./backend.md)
- Gate-decomposition or simulator details — backend concerns

---

## 2. What the frontend is, and what it is not

Under the taint-driven design, the frontend is the smallest layer that
can plausibly be called one. Concretely:

- **Source is plain C.** Compiled by stock Clang. No CQ-specific
  parser, no AST rewriter, no preprocessor pass beyond standard C
  macros and `_Generic` dispatch in `CQ.h`.
- **The only CQ-specific surface is a header.** `CQ.h` declares three
  primitive families (`cq_theta`, `cq_phi`, `cq_measure`) and one
  inversion bracket (`cq_invert_begin` / `cq_invert_end`). The
  declarations are plain extern C functions; bodies are never linked.
- **Quantum data has no special type.** A `quantum int` keyword does
  not exist. A variable that has been rotated by `cq_theta` becomes
  *tainted* in the IR — its type remains `int`.
- **No `cq_init_*` family.** Allocation is gate-triggered, not
  declaration-triggered. See §4.
- **No source-level `cq_when_*` brackets.** Quantum control is
  recovered structurally from the IR; see §7.

What "frontend" means at this layer is therefore: a header file, the
user's discipline to call into it at the points where quantum behavior
begins, and the standard `clang -O1 -emit-llvm` pipeline. The
load-bearing engineering all lives in the IR pass and the runtime.

---

## 3. Intrinsic surface

### 3.1 The three primitive families

| Primitive | Gate | Taint effect | Purpose |
|---|---|---|---|
| `cq_theta(x, angle)` | Ry(θ) | **Source** — return is tainted | Branching rotation; the only operation that creates superposition |
| `cq_phi(x, angle)` | Rz(φ) | Propagates only | Phase rotation; no-op on classical operands |
| `cq_measure(x)` | Measurement | **Sink** — return is classical | Reads register into a classical scalar |

Each family is declared in `CQ.h` as a set of per-type specializations
plus a `_Generic` dispatch macro. The user-visible call site is the
macro; the IR observes the per-type specialization after preprocessing.

The fan-out covers the same 14 C scalar types the type map tracked
under the previous design — bool, the four character/byte forms, two
short widths, two int widths, two long widths, two long-long widths,
plus `float` and `double`. The suffix convention matches the existing
[`cq_mid.h`](../include/cq_mid.h) declarations:

| C type | Suffix | Notes |
|---|---|---|
| `_Bool` / `bool` | `_i1` | 1-bit |
| `char` | `_c` | distinct from `signed char` per the C standard |
| `signed char` | `_si8` | |
| `unsigned char` | `_ui8` | |
| `short` | `_si16` | |
| `unsigned short` | `_ui16` | |
| `int` | `_si32` | |
| `unsigned int` | `_ui32` | |
| `long` | `_sl` | platform-dependent width (32-bit LLP64, 64-bit LP64) |
| `unsigned long` | `_ul` | |
| `long long` | `_sll` | |
| `unsigned long long` | `_ull` | |
| `float` | `_f32` | |
| `double` | `_f64` | |

This gives 14 specializations × 3 primitive families = 42 declarations,
plus 3 dispatch macros. Showing `cq_theta` in full; `cq_phi` and
`cq_measure` follow the same shape with the same 14 widths.

```c
/* CQ.h — sketch of the cq_theta family */

#include <stdbool.h>
#include <stdint.h>

/* Per-type specializations — return type matches operand type */
bool                cq_theta_i1  (bool               x, double angle);
char                cq_theta_c   (char               x, double angle);
signed char         cq_theta_si8 (signed char        x, double angle);
unsigned char       cq_theta_ui8 (unsigned char      x, double angle);
short               cq_theta_si16(short              x, double angle);
unsigned short      cq_theta_ui16(unsigned short     x, double angle);
int                 cq_theta_si32(int                x, double angle);
unsigned int        cq_theta_ui32(unsigned int       x, double angle);
long                cq_theta_sl  (long               x, double angle);
unsigned long       cq_theta_ul  (unsigned long      x, double angle);
long long           cq_theta_sll (long long          x, double angle);
unsigned long long  cq_theta_ull (unsigned long long x, double angle);
float               cq_theta_f32 (float              x, double angle);
double              cq_theta_f64 (double             x, double angle);

/* User-facing dispatch — type-driven via C11 _Generic */
#define cq_theta(x, angle) _Generic((x),           \
    bool:               cq_theta_i1,               \
    char:               cq_theta_c,                \
    signed char:        cq_theta_si8,              \
    unsigned char:      cq_theta_ui8,              \
    short:              cq_theta_si16,             \
    unsigned short:     cq_theta_ui16,             \
    int:                cq_theta_si32,             \
    unsigned int:       cq_theta_ui32,             \
    long:               cq_theta_sl,               \
    unsigned long:      cq_theta_ul,               \
    long long:          cq_theta_sll,              \
    unsigned long long: cq_theta_ull,              \
    float:              cq_theta_f32,              \
    double:             cq_theta_f64               \
)(x, angle)

/* cq_phi declared the same way (same 14 widths, same return-type rule).
   cq_measure declared the same way but takes only x (no angle arg). */
```

Two notes on the dispatch:

- **`_Generic` matches by C standard type, not LLVM width.** The macro
  enumerates the 14 standard scalar types; typedefs like `int32_t`,
  `size_t`, `uintptr_t` resolve to their underlying standard type and
  hit the corresponding case (`int32_t → int` on LP64/LLP64, etc.).
- **`long` and `long long` are distinct cases even when same-width.**
  C treats them as separate types regardless of platform sizing, so the
  `_Generic` must list both — same convention as `cq_mid.h`. The IR
  pass needs no runtime type tag because the specialization name
  (`_sl` vs `_sll`) identifies the operand at the call site, and Clang
  lowers `long` and `long long` to whatever LLVM integer width matches
  the target ABI.

### 3.2 `cq_theta` (Ry) — the only taint source

`cq_theta(x, θ)` applies a Ry(θ) rotation. Its return value is the
sole rule for introducing taint in the new design: any SSA value that
is the result of a `@cq_theta_*` call is a taint source for the
forward propagation in the IR pass.

Two operand-state cases:

- **Classical operand.** The input is a plain bit pattern that has not
  yet been placed on qubits. The IR pass inserts an allocation
  (`cqrt_alloc_<W>(value)`) before the rotation, then lowers the
  theta call to `cqrt_ry_<W>` on the freshly-allocated handle.
- **Tainted operand.** The input is already on qubits. No allocation
  happens; the theta call lowers directly to `cqrt_ry_<W>` on the
  existing handle. This is the *chained-rotation* case.

The user does not need to know which case applies. A variable that is
rotated repeatedly is allocated exactly once, on the first rotation,
because the pass dispatches on operand taint state at lowering time.

Multi-bit registers are tensored: `cq_theta(x, θ)` on a W-bit operand
applies Ry(θ) to each of the W qubits in the register. This matches
Sturm.jl's `q.θ += δ` on `QInt{W}` and is the natural reading; gate-
level decomposition is a backend concern.

### 3.3 `cq_phi` (Rz) — phase rotation, not a taint source

`cq_phi(x, φ)` applies an Rz(φ) rotation. Crucially:

- **Applied to a tainted value:** the IR pass lowers it to
  `cqrt_rz_<W>(handle, φ)`. The output remains tainted (taint
  propagates through but no new taint is introduced).
- **Applied to a classical value:** the operation is physically a
  no-op (Rz on a computational basis state adds only global phase).
  The IR pass deletes the call.

Rz is excluded from the taint-source set deliberately. Adding global
phase to a classical state is observationally meaningless, so a `cq_phi`
call on a non-rotated variable must not promote the variable to a
qubit register. Only `cq_theta` creates superposition; only `cq_theta`
allocates.

### 3.4 `cq_measure` — explicit collapse

`cq_measure(x)` collapses a quantum register into a classical scalar.
It is the sole source of measurement under the new design: there are
no implicit measurements from type conversions, no measurement-on-cast
behavior, no measurement on entry to or exit from a function.

Two properties matter for the user's mental model:

1. **The return is classical.** The SSA result of `@cq_measure_*` is
   not tainted. Downstream uses of the returned value are classical
   arithmetic, classical control flow, classical I/O — anything
   normally legal in C.
2. **The handle is not consumed.** The qubit register persists in a
   classical eigenstate after `cq_measure` returns. Subsequent
   `cq_theta` calls on the same source variable may re-rotate it; the
   register is reused, not freed. From the IR pass's perspective, the
   handle SSA value is unchanged across the measure call.

Casting a quantum-typed value does *not* measure. A `(double) x` on a
tainted `int x` is a representation change (integer-register bit
pattern interpreted as floating-point bit pattern), lowered as a
quantum `sitofp` template under taint. The cast does what casts do
classically.

### 3.5 `cq_invert_begin` / `cq_invert_end` — manual inversion

```c
cq_invert_begin();
    /* gate sequence S — emitted as written, but lowered as S† */
    f(q);
    g(q);
cq_invert_end();
```

The bracketed region is lowered as the adjoint of the gate sequence
written inside it. Each instruction's inverse is mechanically derived
by the backend: NOT/CNOT/Toffoli are self-adjoint; rotations negate
their angle; arithmetic templates use their backend-provided inverse
templates.

This is the only user-facing inversion surface. Auto-uncomputation at
scope exit is a backend responsibility (per-op compile-time adjoints
driven by SSA last-use analysis — see [`backend.md`](./backend.md));
the user writes `cq_invert_*` only when they want explicit control
over a specific region.

The brackets are detected by the IR pass via the marker function names
(`@cq_invert_begin` / `@cq_invert_end`) at module-level call sites.
The user never sees the resulting mangled call (`__cq_invert_<f>`);
the backend synthesizes that name internally when emitting the
inverted sequence.

### 3.6 What is *not* in the intrinsic surface

The following families were considered or existed in earlier designs
and are **not** part of the user-facing surface under the taint-driven
design:

| Family | Status | Why |
|---|---|---|
| `cq_init_*` | Eliminated | Allocation is gate-triggered (§4) — declaring a `quantum int` and then never rotating it produces no qubits. The IR pass inserts allocation immediately before the first `cq_theta` on a classical operand. |
| `cq_alloc_*` | Eliminated as user surface | The backend emits `cqrt_alloc_<W>` internally during lowering, but there is no `CQ.h` declaration for the user to call. |
| `cq_when_begin` / `cq_when_end` | Eliminated as user surface | Quantum control is recovered structurally from tainted branch conditions (§7); no source-level bracketing is needed. |
| `cq_add_qq` / `cq_mul_qc` / etc. | Never existed | Arithmetic uses stock LLVM opcodes (`add`, `mul`, etc.) on tainted operands. The backend identifies them via taint propagation, not via dedicated intrinsics. |
| `quantum` keyword / macro | Eliminated | A quantum int *is* an int; taint is a property of SSA values, not of variable declarations. |

The four-family surface (`cq_theta`, `cq_phi`, `cq_measure`,
`cq_invert_begin`/`_end`) is the entire user-visible compiler surface
beyond stock C.

---

## 4. Allocation is gate-triggered

Under the previous design, declaring a `quantum int` produced an
`@cq_init_i32` call that the rewriter emitted at declaration time; the
backend allocated qubits at that call site whether the variable was
ever rotated or not.

Under the new design, allocation happens at the *first* `cq_theta` on
a classical operand. A variable that is declared, mutated arithmetically,
and never rotated never touches the qubit substrate:

```c
int a = 3;          /* classical */
a = a + 1;          /* classical add — `a` is now 4 */
a = a * 2;          /* classical mul — `a` is now 8 */
a = cq_theta(a, 0.5);   /* HERE: allocation + Ry(0.5) on a fresh register
                           initialized to 8 */
int b = a + 5;      /* tainted add — `b` becomes a tainted register */
```

What the IR pass sees after Clang `-O1`:

```llvm
define i32 @main() {
  %a2 = ... ; classical SSA chain — may be constant-folded
  %a3 = call i32 @cq_theta_i32(i32 %a2, double 5.0e-01)  ; taint source
  %b  = add i32 %a3, 5                                    ; stock LLVM add
  ; ...
}
```

What the IR pass emits after lowering:

```llvm
  %h_a = call i32 @cqrt_alloc_i32(i32 %a2)        ; allocate, init to %a2
  call void @cqrt_ry_i32(i32 %h_a, double 5.0e-01) ; Ry(0.5)
  %h_b = call i32 @cq_template_add_i32_hl(i32 %h_a, i32 5) ; Q+C add
```

Three consequences for the user:

1. Classical arithmetic stays on classical registers until the first
   rotation. The pre-rotation `a = a + 1; a = a * 2` lines remain
   stock LLVM `add`/`mul` instructions on `i32`, fast and cheap.
2. The register is initialized to whatever value the operand carried
   at the moment of the first rotation. The user never needs to
   write `a = 3; cq_init(a); cq_theta(a, ...)` — the value at the
   rotation site *is* the initialization.
3. Variables that look quantum in intent but are never actually rotated
   produce no qubits at runtime. The frontend has no mechanism to
   "declare quantum" without invoking a gate.

---

## 5. What the user writes vs. what the IR pass derives

The taint-driven design intentionally pushes most of the inference
work to the IR pass. The user writes only the operations whose meaning
cannot be derived from data flow.

| Concern | Written by user | Derived by IR pass |
|---|---|---|
| Quantum allocation | — | From the first `cq_theta` on a classical operand |
| Which arithmetic ops are quantum | — | Forward taint propagation from `@cq_theta_*` returns |
| Which arithmetic ops are mixed Q+C | — | Operand-taint mask per instruction |
| Which function calls need quantum specialization | — | Tainted-argument mask at the callsite (clone-on-taint or curated-symbol substitution) |
| Which branches are quantum-controlled | — | Branch condition's taint state (and post-dominator analysis for the controlled shadow) |
| Allocation lifetime / uncomputation point | — | SSA `Value::users()` + post-dominator last-use analysis |
| Rotation (Ry) | `cq_theta(x, θ)` | — |
| Phase rotation (Rz) | `cq_phi(x, φ)` | — |
| Measurement | `cq_measure(x)` | — |
| Manual inversion | `cq_invert_begin();` / `cq_invert_end();` | Mechanically derive adjoint inside the bracket |

Rule of thumb: the user writes anything that introduces or removes
taint (`cq_theta`, `cq_measure`) or that selects a non-default
realization (`cq_phi`, `cq_invert`). Everything else — including all
arithmetic, all control flow, all function calls — is plain C and
inferred by the pass from taint flow.

---

## 6. Function lifting

A central design goal of CQ is that a classical function should work
with tainted arguments without modification. This is what makes
libraries like libm composable with quantum code.

### 6.1 The user's view

```c
/* ipow.c — written without quantum awareness */
int ipow(int base, int exp) {
    int result = 1;
    for (int i = 0; i < exp; i++)
        result *= base;
    return result;
}
```

```c
/* main.c */
#include <CQ.h>

int main(void) {
    int x = 2;
    x = cq_theta(x, 0.3);     /* x is tainted */
    int y = ipow(x, 3);        /* tainted x flows into ipow */
    int out = cq_measure(y);   /* measure result */
    return out;
}
```

Two facts the user can rely on:

1. **`ipow` does not need to be edited.** It is plain C; it is shipped
   as plain C; it is consumed by classical callers unchanged. The IR
   pass synthesizes a quantum specialization (`@ipow.q_10` or
   similarly mangled) at the tainted-argument callsite, alongside the
   original `@ipow` which remains for classical callers.
2. **Internal casts do not measure.** A `(double)` cast inside the
   callee — common in averages, divisions, math wrappers — is a
   representation change at IR level (`sitofp`) and lowers to a
   quantum cast template under taint. It does not collapse the
   superposition.

This is the property the previous (`quantum` keyword + cast-as-
measurement) design failed to provide: in that design, hidden casts
inside library code triggered unwanted measurements, and the caller
had no way to know which classical functions were "safe to lift" vs.
which would silently collapse the input state.

### 6.2 The two lifting paths

The IR pass uses different mechanisms depending on whether the
callee's body is visible at pass time.

- **Path 1 — curated symbol substitution** (no visible body). For
  libm, LLVM intrinsics, and other opaque shared-library symbols, the
  pass maintains a table mapping classical symbols to quantum
  templates: `@sin → @cq_template_sin_f64`, `@cos →
  @cq_template_cos_f64`, etc. At a callsite with tainted arguments
  the pass rewrites the symbol; the body is never inspected.
- **Path 2 — clone-on-taint** (visible body). For user code and
  LTO-linked libraries, the pass clones the callee keyed by the
  taint signature of the call, propagates taint through the clone,
  lowers it, and retargets the call. The original function is left
  intact for classical callers.

Both paths are backend mechanisms (see [`backend.md`](./backend.md)).
The user's only obligation at the frontend layer is:

- **Compile with LTO visibility.** The cloning path requires the
  callee's bitcode to be in the same module the pass sees.
  `cqc` arranges this by passing `-flto` to clang and pre-linking via
  `llvm-link` before invoking `opt`. Functions whose bodies are not
  LTO-visible fall back to the curated-symbol table; an unknown symbol
  with tainted arguments causes the pass to error with a diagnostic.

### 6.3 What lifting does not cover

A small number of operations cannot be lifted regardless of body
visibility:

- **Calls with externally-visible side effects.** `printf`, syscalls,
  functions that write to externally-visible globals — these are on
  a Bennett-rejection list. The pass errors at a tainted callsite,
  pointing at the offending operation.
- **Indirect calls with tainted arguments.** `(*fp)(tainted_x)` where
  `fp` cannot be statically resolved. Rejected with a diagnostic.
  Specializing every potential target is an over-approximation; this
  rule may be relaxed in later phases.

Both are diagnosed at compile time; the user sees the error before
the program runs.

---

## 7. Quantum control flow

A branch whose condition is tainted is a quantum branch: the program
is in a superposition of "taken" and "not taken", and instructions in
the branch's shadow execute coherently under the condition.

Under the new design, there is **no `cq_when_begin` / `cq_when_end`
user-facing surface**. The IR pass recovers the controlled region
structurally:

1. Identify each `br i1 %cond, label %T, label %F` whose `%cond` is
   tainted (operand taint, derived from forward propagation).
2. Compute the immediate post-dominator `%merge` via LLVM's
   `PostDominatorTree`.
3. Treat every value defined in the dominated shadow as
   *control-tainted* — including φ-node results at `%merge` whose
   direct operands are classical literals (a φ between `10` and `20`
   looks classical operand-wise, but the selected value depends on
   the quantum branch).
4. Lower every instruction in the shadow to its controlled form, with
   `%cond` as the control wire.

The user's view is therefore: a plain C `if (tainted_cond) { ... }`
*is* the controlled region. The brace-bounded shadow is the
post-dominated subgraph that gets controlled-form lowering. The user
does not need to bracket it.

### Why no user-facing `cq_when`

A `cq_when` marker would only matter if the user wanted to
quantum-control on a condition the pass would not flag as tainted.
But quantum control on a classical condition has no physical content:
a classical 1 reduces to unconditional application, a classical 0 to
no-op. There is no superposition of "applied vs. not" without a
tainted control wire.

So tainted-condition is **necessary and sufficient** for controlled-
form lowering. Source-level markers would be redundant ceremony.

### Scope under construction

The end-to-end mechanism is described above; the prototype validates
the linear-single-BB and multi-BB cases. Nested tainted branches,
loops with tainted bounds, and `cq_invert_*` interaction with
controlled regions are downstream backend work and do not affect the
frontend surface — the user continues to write plain C control flow
regardless.

---

## 8. Compilation flow

The frontend's deliverable to the backend is a single bitcode module
post-Clang-`-O1`. Three stages:

```
.c source (plain C + #include <CQ.h>)
   ▼
Stage 1: clang -O1 -emit-llvm -include CQ.h
   │   (standard C compilation; _Generic dispatch resolves at parse
   │    time; mem2reg/sroa run inside -O1)
   ▼
Stage 2: opt -load-pass-plugin libCQPass.so -passes=cq-lowering
   │   (taint propagation, allocation insertion, opcode lowering,
   │    function specialization, control-flow lowering, adjoint
   │    synthesis — see backend.md)
   ▼
Stage 3: clang lowered.bc -lcq_templates -lcq_runtime
       (standard codegen + link; resulting binary emits the circuit)
```

### Single-file program

```bash
clang -O1 -emit-llvm -include CQ.h example.c -o example.bc
opt -load-pass-plugin libCQPass.so -passes=cq-lowering \
    example.bc -o example.lowered.bc
clang example.lowered.bc -lcq_templates -lcq_runtime -o example
./example
```

### Multi-file program (function lifting across translation units)

Clone-on-taint requires callee bodies in the same bitcode module the
pass sees. Pre-link with `llvm-link` (or build with `-flto`) *before*
invoking `opt`:

```bash
clang -O1 -emit-llvm -include CQ.h main.c -o main.bc
clang -O1 -emit-llvm util.c -o util.bc           # util.c needs no CQ.h
llvm-link main.bc util.bc -o combined.bc          # bitcode link first
opt -load-pass-plugin libCQPass.so -passes=cq-lowering \
    combined.bc -o combined.lowered.bc
clang combined.lowered.bc -lcq_templates -lcq_runtime -o program
```

`cqc` (the project driver) wraps this multi-step flow under a single
invocation that mirrors a stock `clang -flto` command line.

---

## 9. Cross-references

| Concern | Where it is documented |
|---|---|
| Stock LLVM C++ APIs the whole pipeline uses | [`llvm-implementation.md`](./llvm-implementation.md) |
| Why no `quantum` keyword; why no cast-as-measurement | [`rationale/proposal-taint-driven-pipeline.md`](./rationale/proposal-taint-driven-pipeline.md) |
| Taint as Q/C boundary; mixed-operand semantics; conversion semantics | [`quantum-classical-handling.md`](./quantum-classical-handling.md) |
| Forward taint propagation algorithm; allocation insertion; opcode lowering; specialization; controlled-form lowering; uncomputation | [`backend.md`](./backend.md) |
| End-to-end worked example, source → lowered IR | [`example.md`](./example.md) |
| Design convergences and divergences with Sturm.jl / Bennett.jl | [`bennett-jl-comparison.md`](./bennett-jl-comparison.md) |
