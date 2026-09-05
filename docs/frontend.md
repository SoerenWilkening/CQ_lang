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
| `cq_phi(angle)` | branch phase | None — no data operand | Multiplies the CURRENT BRANCH's amplitude by `e^{iθ}` (§3.3) |
| `cq_measure(x)` | Measurement | **Sink** — return is classical | Reads register into a classical scalar |

> **`cq_phi` is register-free** (owner decision D1; bd
> `test_C_libtooling-3qlq.2`, Increment 1 — see the Status note in §3.3 for
> which branch that is on). `CQ.h` declares exactly **one**
> `void cq_phi(double angle)`. The retired per-register `cq_phi_<sfx>(x, φ)`
> family — the 14 widths in the suffix table below plus the
> target-dependent `long double` / `_f80` specialization, 15 in all — is
> **gone from the header**, with deliberately no migration shim, so
> the old two-argument spelling is a hard compile error — measured, `clang`
> says `too many arguments to function call, expected single argument
> 'angle', have 2 arguments`. §3.1's per-type / `_Generic` machinery below
> therefore covers `cq_theta` and `cq_measure` only; `cq_phi` has no per-type
> form and no dispatch macro at all. `cq_theta` and `cq_measure` are
> otherwise unaffected. See §3.3.

The two **register-carrying** families are declared in `CQ.h` as a set of
per-type specializations plus a `_Generic` dispatch macro. The
user-visible call site is the macro; the IR observes the per-type
specialization after preprocessing. `cq_phi` is not one of them: it takes
no register, so there is nothing to dispatch on and it is a single plain
declaration.

The fan-out covers the same 14 C scalar types the type map tracked
under the previous design — bool, the four character/byte forms, two
short widths, two int widths, two long widths, two long-long widths,
plus `float` and `double`. The suffix convention is defined by the
table below — this is the canonical suffix-to-type map:

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

This gives 14 specializations × the **two** register-carrying families
(`cq_theta`, `cq_measure`) = 28 declarations, plus the single
`void cq_phi(double angle)` — **29 in all** — with 2 `_Generic` dispatch
macros and the `cq_ry` statement macro (§3.2). Showing `cq_theta` in full;
`cq_measure` follows the same shape with the same 14 widths. `cq_phi` does
not, and that is the point of §3.3: a branch phase has no register to
dispatch on.

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

/* cq_measure declared the same way but takes only x (no angle arg).
   cq_phi has NO per-type family and NO _Generic macro: it is the one
   declaration `void cq_phi(double angle)` (§3.3). The per-register
   cq_phi_<sfx>(x, angle) family it replaced is deleted from the header. */
```

Two notes on the dispatch:

- **`_Generic` matches by C standard type, not LLVM width.** The macro
  enumerates the 14 standard scalar types; typedefs like `int32_t`,
  `size_t`, `uintptr_t` resolve to their underlying standard type and
  hit the corresponding case (`int32_t → int` on LP64/LLP64, etc.).
- **`long` and `long long` are distinct cases even when same-width.**
  C treats them as separate types regardless of platform sizing, so the
  `_Generic` must list both — both appear as distinct rows in the §3.1
  suffix table (`_sl` and `_sll`). The IR
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

Multi-bit **Ry** registers are tensored: `cq_theta(x, θ)` on a W-bit
operand applies Ry(θ) to each of the W qubits in the register
(`cqrt_ry_<W>`). This matches Sturm.jl's `q.θ += δ` on `QInt{W}` and is
the natural reading; gate-level decomposition is a backend concern.

**This paragraph is about Ry only, and that restriction is load-bearing.**
The same tensored reading was applied to Rz, and it made the controlled
phase gate useless as an oracle: a per-qubit diagonal gate puts phase
`(−1)^popcount(target)` on the marked branch and *fixes* `|0…0⟩`, so it
can never mark it. That is why `cq_phi` is **register-free** (§3.3) — see
`docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` §1 for the
finding and §3 for the kickback that replaces it.

#### The linear rule

**A rotation consumes the old name.** `cq_theta(x, θ)` does not return a
copy of `x` alongside the original: it names the same physical wire after
the gate. So a read of the *pre-gate* value that the compiler cannot prove
executes **before** the gate is refused — loudly, lowering nothing. This is
one rule of the language, and it is the reason `cq_ry(x, θ)` (below) is the
spelling to reach for: the assignment makes the consumption visible.

```c
int q = cq_theta(seed, 0.3);
int mark = q;              /* another NAME for the same wire, not a copy */
cq_ry(q, 0.4);             /* the wire moves */
int s = mark * 7;          /* REFUSED — `mark` denotes the pre-gate value:
                              cq opcode lowering: operand predates a
                              non-diagonal gate */
```

Strict single-use is deliberately **not** the rule. Two reads of a rotated
value are ordinary and correct as long as they are provably positioned
before the gate — Grover's oracle reads `q` in the compare *and* rotates
`q` in the same region, which a single-use rule would refuse. The rule is
about **position**, not about count.

The IR pass enforces this one rule at **three sites**, each with its own
diagnostic, because three different stages are the first to see the
violation:

| site | file | diagnostic |
|---|---|---|
| **R6** — the stale-record fence for an in-place rotation arm under quantum control | `ArmClassify.cpp` | `stale rail record read past a controlled Ry` |
| `staleRailRecordRead` — a rail record read at a position where the register no longer holds it, inside a classically-bounded loop | `LoopLowering.cpp` | `cq loop lowering: rail record read past an in-place gate on the same rail` |
| `declineStaleRecordOps` — the pass-wide guard: a tainted pure op scheduled past a non-diagonal wire gate | `OpcodeLowering.cpp` | `cq opcode lowering: operand predates a non-diagonal gate` |

Three sites, one rule. A program that trips any of them is asking for a
value the hardware no longer has.

> **The rule is the language semantics; the enforcement is per-site and is
> not yet complete.** Measured 2026-09-05 against `52d7764`: the example
> above declines, but replacing the arithmetic with a **measurement** of the
> same stale name —
> `int q = cq_theta(seed,.3); int mark = q; cq_ry(q,.4); cq_measure(mark);`
> — is **accepted** in a straight-line function and lowers to
> `alloc; ry(h,.3); ry(h,.4); measure(h)`, i.e. `mark` is measured at the
> post-gate value. `declineStaleRecordOps` covers tainted **pure ops** only,
> and the other two sites are scoped to a loop and to a control region
> respectively. Do not rely on the compiler to catch this spelling; write
> `cq_ry` and stop naming the old value.

#### `cq_ry(x, θ)` — the statement surface

```c
#define cq_ry(x, angle) ((x) = cq_theta((x), (angle)))
```

`cq_ry(x, θ)` is exactly `x = cq_theta(x, θ)` and reaches the IR pass as
the identical construct at `-O1` (pinned by `tests/frontend/cq_ry_macro.c`,
which asserts the same `@cq_theta_<sfx>` call with its result feeding the
next use, at three widths). It is **not** a new primitive and **not** a new
taint source; it is the linear rule made syntactically explicit.

`cq_theta` stays declared as the expression form, because state preparation
has no in-place spelling: `int r = cq_theta(5, θ)` rotates a **fresh**
register seeded with the classical constant `5`. A register-free
`a = cq_theta(θ)` is not available and is not a deferred feature — after
`mem2reg` there is no variable `a` for it to name, and such a call arrives
at the pass as an unrelated value, i.e. byte-identical to the state-prep
form above (measured; PRD §4.2).

### 3.3 `cq_phi` — the branch phase (register-free)

> **Status.** The semantics below are what the compiler does (owner decisions
> D1–D4, 2026-09-05,
> `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` §2). Both
> halves — the `CQ.h` surface and the kickback lowering — **SHIPPED in
> Increment 1 (bd `test_C_libtooling-3qlq.2`, 2026-09-05)**. ⚠ Before that
> merge the header declared a retired per-register form `cq_phi(x, φ)` and the
> pass lowered it to the tensored `cqrt_rz_<W>(handle, φ)`, which is the defect
> this section exists to remove (§3.2, PRD §1); that spelling is now a hard
> COMPILE error at the header and a loud decline in the pass, so a program
> written against the old surface cannot silently mean something else.

```c
void cq_phi(double angle);
```

`cq_phi(θ)` **multiplies the amplitude of the CURRENT BRANCH by
`e^{iθ}`**. It takes no register, because a phase is not a property of a
register — it is a property of the branch of the computation you are
standing in. There is one declaration, not fifteen.

**Under a tainted condition it lowers by kickback.** For
`if (c(q)) cq_phi(θ)` the pass mints the condition flag `f = c(q)` into a
fresh `|0⟩` ancilla (the same compare mint every control shape already
uses), applies the gate **uncontrolled** to that one qubit, and strips the
flag with the compare's `_unc`:

```
mint     cq_template_icmp_..._hl(h, k)   -> f      ; f = c(q), on a |0> ancilla
gate     cqrt_rz_i1(f, θ)                          ; UNCONTROLLED, one qubit
strip    cq_template_icmp_..._hl_unc(f, h, k)      ; f back to |0> on EVERY branch
free     cqrt_free(f)
```

Why it works, in one line: with `f` minted, the state is
`Σ aₓ |x⟩|c(x)⟩`; a diagonal gate on the ancilla makes it
`Σ aₓ e^{iθc(x)} |x⟩|c(x)⟩`; the strip is a permutation back to
`Σ aₓ e^{iθc(x)} |x⟩|0⟩`. The phase landed on the branch and the ancilla is
provably `|0⟩` again, so freeing it is not a hidden measurement. A `¬f` arm
keeps the self-inverse `cqrt_x(f)` bracket, as every other `¬flag` arm does.

**Uncontrolled — or classically controlled — `cq_phi` is a global phase and
is deleted.** `cq_phi(θ)` at the top of `main`, or inside
`if (classical_flag) { … }`, multiplies the whole state vector by a scalar,
which no measurement can observe. The pass removes it. This is a
**documented semantic, not a diagnostic**: there is nothing wrong with the
program, and no message is emitted (owner decision D2).

**There is no multi-bit Rz.** The old per-register form applied Rz to each
of the W qubits, and that tensored reading is exactly what made it useless
under control (§3.2, PRD §1). The documented idiom for a register-wide Z
rotation is a plain classical loop over the bits:

```c
for (int i = 0; i < W; i++)
    if ((q >> i) & 1)
        cq_phi(θ);              /* one branch phase per set bit */
```

Each iteration is an ordinary tainted-condition region, so this needs no new
capability: measured 2026-09-05 (PRD §2 D4) it lowers **rolled** at K=4 and
at K=32 with IR size independent of K, and `-O1` rewrites the condition to
`q & (1<<i)`. "Rz directly on qubit `i`" is a **backend** peephole over that
fixed gate idiom — the width-only runtime ABI (Rule 15) cannot address a
single qubit and gets no symbol for one (owner decision D3: this epic adds
**no** runtime symbol; the emitted Rz set *shrinks* to `cqrt_rz_i1`).

**Two worked examples.** Both are the flagship customer, and both are
programs the pre-3qlq compiler accepted and lowered to the identity on `q`:

```c
/* Grover oracle — mark |5> with a -1 phase */
if (q == 5) cq_phi(PI);

/* reflection about |0> — mark |0..0> with a -1 phase */
if (q == 0) cq_phi(PI);
```

Under the register form the first put `e^{iπ·popcount(5)} = +1` on the
marked branch and the second could not touch `|0…0⟩` at all, because a
per-qubit diagonal gate fixes it. Under the branch phase both put `−1`
exactly where the source says, and the second is not a special case.

**Taint.** The model is unchanged: `cq_theta` is the sole source,
`cq_measure` the sole sink. `cq_phi` no longer propagates anything — it has
no data operand to propagate through. It is ordered by the **block it sits
in**, not by a data dependence, which is precisely what makes it a branch
phase. Only `cq_theta` creates superposition; only `cq_theta` allocates.

#### The one operand is an angle — and the name is reserved

Two consequences of the one-argument prototype are worth stating outright,
because the old surface's type discipline is gone with it.

**Any classical expression is a legal angle, including an integer one.**
`cq_phi(n)` with an `int n` compiles by the ordinary implicit `int → double`
conversion and *is* a phase of `n` radians. There is no diagnostic — measured
2026-09-05 at `-Wall -Wextra -Wconversion`,
`volatile int g = 7; int c = g; if (q == 5) cq_phi(c);` emits
`cqrt_rz_i1(f, 0x1.cp+2)`, i.e. a 7-radian phase, and nothing is wrong with
that lowering. The type system no longer separates "register" from "angle",
so **port an old call by rewriting it, never by deleting an argument**: a
`cq_phi(x, φ)` shortened to `cq_phi(x)` is a legal program that means
something else.

The realistic version of that slip is caught, however, because the *register*
is quantum: a **quantum-derived** angle declines loudly and lowers nothing —
`cq rotation lowering: unsupported quantum-derived rotation angle`
uncontrolled, and `cq controlled lowering: rotation angle under quantum
control` inside a tainted region. Only a *classical* mis-typed angle is
silent.

**`cq_phi` is a reserved name and must not be defined by user code.** The
pass claims the symbol by **exact** name with the prototype `void(double)`;
a declaration with any other prototype is a loud decline,
`cq rotation lowering: unsupported declared prototype for cq_phi`, and that
fires **whether or not the declaration is called** (measured 2026-09-05 on the
merged Increment-1 tree, both spellings). The **retired** 15-width
`cq_phi_<sfx>(x, φ)` family is likewise reserved: any USE of one declines with
`cq rotation lowering: retired register-form cq_phi_<sfx>; use the
register-free void cq_phi(double)` — measured on the tainted, the
`clang -O1` const-folded and the wrong-prototype spellings alike — while a
declaration with **no call site** is silently swept (a deliberate narrowing,
`docs/backend.md` §6.1a).

A *definition* is the one case still left open. Measured 2026-09-05 on the
merged Increment-1 tree, a module that defines `void @cq_phi(double)` with an
observable body compiles at **exit 0 with no diagnostic**, and the body never
runs: the definition itself is discarded, and each call is read as a branch
phase — lowered to a kickback gate under a tainted condition, deleted outright
under classical control (D2). `cq_phi` / `void(double)` is a short, collidable
C signature, so this is a real hazard for a TU that happens to spell it.
Whether a defined `@cq_phi` should instead be a loud decline, on the same
reserved-name rule the other 33 front-end names follow, is an **open owner
question** from the Increment-1 round-1 review (finding F-L6-6, carried as
Q-R1-3) and is not decided here.

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
  %a3 = call i32 @cq_theta_si32(i32 %a2, double 5.0e-01)  ; taint source
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
| Rotation (Ry) | `cq_theta(x, θ)` / `cq_ry(x, θ)` | — |
| Branch phase | `cq_phi(θ)` | Which branch it lands on — from the enclosing tainted condition, by kickback (§3.3) |
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
4. Mint the condition into a flag qubit `f` (a fresh `|0⟩` ancilla), lower
   the shadow by the mechanism its **arm class** demands, then strip `f`
   back to `|0⟩` with the compare's `_unc` and free it.

The user's view is therefore: a plain C `if (tainted_cond) { ... }`
*is* the controlled region. The brace-bounded shadow is the
post-dominated subgraph that gets controlled-form lowering. The user
does not need to bracket it.

Step 4's "arm class" is the one thing worth knowing at the source level,
because the three classes are not interchangeable (`CLAUDE.md` Rule 7):

- **A phase arm** — the arm is `cq_phi(θ)` — is **kickback**: the gate goes
  on the flag `f`, **uncontrolled** (`cqrt_rz_i1(f, θ)`), and the strip
  carries the phase back onto the branch (§3.3). Nothing is applied to the
  data register at all, and there is no work rail. *This is the Increment-1
  lowering (bd `test_C_libtooling-3qlq.2`, SHIPPED 2026-09-05 — see §3.3's
  Status note). It replaced a controlled per-qubit Rz on the register, which
  is the defect §3.3 documents, and it is the lowering at every phase site:
  the flat diamond and `if/else`, the folded angle select, the compound
  condition tree, the depth-2 nest and the `switch`.*
- **A rotation arm** — the arm is `cq_theta` on a register the condition
  does not read — is applied **in place**, as one controlled gate
  (`cqrt_ry_<W>_controlled(f, h, θ)`). A swap route cannot carry an Ry:
  `Ry(θ)|0⟩ ≠ |0⟩` would leave the inactive rail dirty and entangled.
- **A value arm** — the arm assigns an arithmetic result — is
  compute → copy-out → uncompute: the arm's chain runs on the original
  register and the answer is merged into a fresh rail under the flag. A
  value arm that rewrites a register the condition reads is a **loud
  reject**.

Mixing classes in one arm is a loud reject, and so is anything the pass
cannot prove: over-declining is safe, and a silently wrong unitary is the
one unforgivable bug.

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

### Optimization-level guidance

The `-O` level passed to Clang at Stage 1 and to Clang at Stage 3 are
independent choices with different risk profiles. Stage 2 (the
`cq-lowering` pass itself) takes no `-O` level.

| Stage | Default | `-O`-level-safe? | Notes |
|---|---|---|---|
| Stage 1 (pre-IR-pass) | `-O1` | floor only | `-O1` is the validated floor: mem2reg / SROA must run before the pass sees the IR (§3.1 of [`backend.md`](./backend.md) requires post-`mem2reg`/post-`SROA` SSA). `-O0` is not supported. `-O2+` is not prohibited but introduces risks (see below). |
| Stage 3 (post-pass codegen) | matches user's `-O` | yes, any level | Stage 3 IR contains only stock LLVM ops on classical SSA plus opaque `cqrt_*` and `cq_template_*` externals. Whatever Clang chooses to do at `-O3` is by definition safe — there are no tainted ops left for stock optimizations to miscompile. Most binary runtime performance comes from this stage. |

Stage-1 risks at `-O2`:

- **Aggressive inlining** can pre-empt clone-on-taint (§7.2 of
  [`backend.md`](./backend.md)) by inlining a callee before the pass
  observes the call site, collapsing the taint signature.
- **IPSCCP / argpromotion** can rewrite function signatures, breaking
  the per-callsite taint-signature key the specialization cache uses.
- **LoopUnroll / LoopVectorize** on a tainted loop (tainted bound,
  tainted condition, tainted body) reshapes the CFG the pass walks.
- **SimplifyCFG** can flatten branches whose post-dominator the
  controlled-form lowering depends on (§8 of `backend.md`).
- **GVN** can CSE across tainted values, fusing distinct handles into
  one.

Stage-1 risks at `-O3` add one more hazard:

- **SLPVectorize** can fuse a tainted scalar op with an adjacent
  untainted scalar op into a single vector op. The current template
  surface (§12 of `backend.md`) covers scalar opcodes only, so a
  vector-tainted op silently miscompiles without dedicated
  vector-tainted-op template support.

If a user pushes `-O3` at Stage 1 before vector-tainted templates
exist, the workaround is `-fno-vectorize -fno-slp-vectorize` to
suppress the vectorizers while keeping the rest of `-O3` active.

Raising the Stage-1 default above `-O1` requires a regression test
matrix: small CQ programs compiled at each `-O` level, lowered IR
diffed, runtime gate sequences compared. Until that matrix exists,
the default stays `-O1`.

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
