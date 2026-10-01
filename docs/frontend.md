# CQ Frontend — User-Facing Surface

What the algorithm author writes, and what the compiler does with it
before any IR pass runs. The frontend under the taint-driven design is
deliberately minimal: a small intrinsic surface declared in `CQ.h`,
parsed by stock Clang, lowered by `-O1` into stock LLVM IR. There is no
rewriter; there are no special types.

The plan of record is [`../NORTHSTAR.md`](../NORTHSTAR.md). This document
describes what the compiler does **today**. Where it says a construct is
"not lowered yet", that is a compiler gap, not a language rule: the compiler
fails loudly on it (`opt` exits non-zero with a source-located diagnostic),
and only the physics-forced declines in NORTHSTAR goal 1 are permanent. Streams
and diagnostics described as "measured" were produced by running the pipeline
(`build/ir-pass/cq-opt` and the trace runtime) on the quoted source; the
diagnostic strings in the §3.2 site table were checked against the pass source
only.

Section numbers are cited from other documents and from source comments (for
example `frontend.md` §3.1, §3.2, §3.5 from `include/CQ.h`, the lit fixtures and
`tests/frontend/`); keep them stable.

Companion documents:
- [`backend.md`](./backend.md) — what the IR pass and runtime do with
  the IR the frontend hands off
- [`quantum-classical-handling.md`](./quantum-classical-handling.md) —
  taint as the Q/C boundary, mixed-operand semantics
- [`llvm-implementation.md`](./llvm-implementation.md) — the stock LLVM
  C++ APIs the whole pipeline depends on
- [`example.md`](./example.md) — one program walked through every stage

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
- The compilation flow

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
- **The only CQ-specific surface is a header.** `CQ.h` declares two
  register-carrying primitive families (`cq_theta`, `cq_measure`), the
  register-free branch phase `cq_phi`, the `cq_ry` statement macro and one
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

### 3.1 The primitive families

| Primitive | Gate | Taint effect | Purpose |
|---|---|---|---|
| `cq_theta(x, angle)` | Ry(θ) | **Source** — return is tainted | Branching rotation; the only operation that creates superposition |
| `cq_phi(angle)` | branch phase | None — no data operand | Multiplies the CURRENT BRANCH's amplitude by `e^{iθ}` (§3.3) |
| `cq_measure(x)` | Measurement | **Sink** — return is classical | Reads register into a classical scalar |

`cq_phi` is **register-free**: `CQ.h` declares exactly one
`void cq_phi(double angle)`. There is no per-type form and no `_Generic`
dispatch for it, and the retired two-argument spelling `cq_phi(x, φ)` is a hard
compile error — measured, `clang` says `too many arguments to function call,
expected single argument 'angle', have 2 arguments`. The per-type / `_Generic`
machinery below therefore covers `cq_theta` and `cq_measure` only. See §3.3.

The two **register-carrying** families are declared in `CQ.h` as a set of
per-type specializations plus a `_Generic` dispatch macro. The
user-visible call site is the macro; the IR observes the per-type
specialization after preprocessing.

The fan-out covers 15 C scalar types — `bool`, the three character forms,
`short`, `int`, `long`, `long long` in signed and unsigned form, plus
`float`, `double` and `_Float16` — and, on targets where `long double` is x87
extended precision (x86-64), `long double`: 15 types, 16 on x86-64, the same 16
suffixes the pass keeps in `kRows` ([`backend.md`](./backend.md) §3.2). The
suffix convention below is the canonical suffix-to-type map:

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
| `_Float16` | `_f16` | |
| `long double` | `_f80` | only where `__LDBL_MANT_DIG__ == 64` (x86-64); where `long double` is `double` the `double` arm matches, and where it is IEEE-quad it has no association and `cq_theta((long double)…)` is a compile error rather than a wrong lowering |

> **A `bool` register as a CONDITION.** A `bool` is a one-qubit register and
> `if (b) …` hands the pass `br i1 %b` with no compare: the register **is**
> the flag. It is read only as a control — no ancilla is minted for the phase
> and it is never freed. Measured on `_Bool b = cq_theta((_Bool)0, 0.7);`:
>
> | source | emitted |
> |---|---|
> | `if (b) cq_phi(1.0);` | `cqrt_rz_i1(h0, 0x1p+0)` — one gate on `b`'s own rail |
> | `if (!b) cq_phi(1.0);` | `cqrt_rz_i1(h0, -0x1p+0)` — `X·P(θ)·X` is `P(−θ)` up to a global phase, so no `cqrt_x` ever touches a user register |
> | `int a = 5; if (b) a -= 3;` | a data select: `alloc_i1; cqrt_cnot(b, f)`, the two `cqrt_copy_i32_controlled` merges, `cqrt_cnot(b, f); cqrt_free(f)` — the flag is a CNOT copy of `b`, again nothing non-diagonal on `b` |
> | `if (b) r = cq_theta(r, 0.9);` | `cqrt_ry_i32_controlled(h0, h1, θ)` with `b`'s handle as the control |
>
> A `bool` that is rotated inside a loop which also reads it as the branch
> condition (a loop-carried `bool`, `for (…) { if (b) cq_phi(θ); b = cq_theta(b, φ); }`)
> is not lowered yet: measured, `cq controlled lowering: branch phase on a bare i1
> condition under quantum control`.


That is 15 specializations × the **two** register-carrying families
(`cq_theta`, `cq_measure`) = 30 declarations, plus the two `_f80` ones on x86-64,
plus the single `void cq_phi(double angle)`, with 2 `_Generic` dispatch macros
and the `cq_ry` statement macro (§3.2). Showing `cq_theta` in full;
`cq_measure` follows the same shape with the same widths. `cq_phi` does not,
and that is the point of §3.3: a branch phase has no register to dispatch on.

```c
/* CQ.h — sketch of the cq_theta family */

#include <stdbool.h>
#include <stdint.h>

/* Per-type specializations — return type matches operand type.
   EVERY cq_theta_* declaration carries __attribute__((nomerge)) through the
   CQ_THETA_NOMERGE_ macro ("Why `nomerge`" below). Omitted here. */
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
_Float16            cq_theta_f16 (_Float16           x, double angle);
/* + cq_theta_f80 (long double) where long double is x87 extended */

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
    double:             cq_theta_f64,              \
    _Float16:           cq_theta_f16               \
)(x, angle)

/* cq_measure declared the same way but takes only x (no angle arg).
   cq_phi has NO per-type family and NO _Generic macro: it is the one
   declaration `void cq_phi(double angle)` (§3.3). */
```

Two notes on the dispatch:

- **`_Generic` matches by C standard type, not LLVM width.** The macro
  enumerates the standard scalar types; typedefs like `int32_t`,
  `size_t`, `uintptr_t` resolve to their underlying standard type and
  hit the corresponding case (`int32_t → int` on LP64/LLP64, etc.).
- **`long` and `long long` are distinct cases even when same-width.**
  C treats them as separate types regardless of platform sizing, so the
  `_Generic` must list both — both appear as distinct rows in the suffix
  table (`_sl` and `_sll`). The IR pass needs no runtime type tag because the
  specialization name (`_sl` vs `_sll`) identifies the operand at the call
  site, and Clang lowers `long` and `long long` to whatever LLVM integer width
  matches the target ABI.

#### Why every `cq_theta_*` is `nomerge`

`cq_theta(x, θ)` on a quantum `x` rotates **that register**; on a classical `x`
it prepares a **fresh** one. Register identity is therefore part of what a call
means, and it is not part of C's value semantics — so `clang -O1` is free to treat
two `cq_theta` calls with equal operands as the same call. It does, and the result
can be a *different program*:

```c
int t = q / 4;  int r = 5;
if (q2 > 3) { if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9); }
```

IPSCCP substitutes `t := 5` into the first arm, both arms become the identical call
`cq_theta(5, .9)`, and the late SimplifyCFG hoists the pair and **deletes the inner
branch**. What reaches the pass is, instruction for instruction, the stage-1 IR of
the unrelated program `if (q2 > 3) r = cq_theta(5, .9);` — which prepares a fresh
`|5⟩` and never rotates `t`. A second route (sink two calls that differ in one
operand, then fold `select (q == 20), t, 5` to `5` by InstSimplify) produces the
**same module** from a source whose rotated register is *not* the compare's operand.
Because those programs and the legitimate one are the same IR, **no pass-side fence
can separate them**. The evidence exists only until SimplifyCFG runs, so the fix is
in the header: `__attribute__((nomerge))` forbids merging the calls, the branch
survives, and the pass sees the shape it was written and either lowers it or fails
loudly, instead of accepting a different program. (Visible at the call site: at
`-O1` the call carries `attributes #2 = { nomerge nounwind }`.)

**What `nomerge` does NOT close — two open bugs, both pre-existing.** clang puts
`nomerge` on each CALL SITE that names the attributed declaration; it does not reach
the LLVM declaration itself. So:

- **bd `4e4p`** — a call through a FUNCTION POINTER (`int (*f)(int, double) =
  cq_theta_si32; f(x, θ)`) is turned back into a direct call by `-O1` *without* the
  attribute (measured: the resulting call carries only `nounwind`), so the fold
  returns.
- **bd `uw5u`** — `cq_theta((t == s) ? t : s, θ)` is folded by InstSimplify to
  `cq_theta(s, θ)` with **no merge at all** (measured on two quantum registers `t`,
  `s`: the stage-1 IR rotates `s`). That turns a rotation of a fresh mux register
  into an in-place rotation of `s` — a different unitary. No header attribute can
  reach it.

**The costs** (measured):

- **If/else over one register no longer folds into a selected angle.**
  `if (c) r = cq_theta(r, A); else r = cq_theta(r, B);` with a quantum condition
  stays an if/else and lowers as two controlled Ry (`cqrt_ry_i32_controlled(f, h, A)`,
  `cqrt_x(f)`, `cqrt_ry_i32_controlled(f, h, B)`, `cqrt_x(f)`) — the same unitary.
  The **ternary** spelling `r = cq_theta(r, c ? A : B);` produces the select-angle
  call directly (no merge is involved) and lowers by difference: an unconditional
  `ry(h, B)` then one `cqrt_ry_i32_controlled(f, h, A−B)`.
- **Not lowered yet:** with a **classical** condition inside a loop,
  `if (i & 1) p = cq_theta(p, .9); else p = cq_theta(p, .3);` fails loudly
  (`loop-carried tainted value crosses iterations`), and so does an if/else with
  common code on one register, e.g. `if (c) { r = Ry(r, .9); r = Ry(r, .1); } else
  { r = Ry(r, .1); }` (`impure phase arm under quantum control`). The ternary
  spelling still lowers.

`cq_phi` and `cq_measure` do **not** carry `nomerge`: a branch phase has no register
whose identity a merge could confuse, so `if (c) cq_phi(A); else cq_phi(B);` still
folds to `cq_phi(c ? A : B)`; and LLVM merges two `cq_measure` calls only when their
operand VALUES agree on every path.

A compiler without `nomerge` is refused with an `#error` rather than silently
re-opening the merge.

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
(`cqrt_ry_<W>`; see `runtime/cq_runtime.h`).

**This paragraph is about Ry only, and that restriction is load-bearing.**
The same tensored reading applied to Rz makes a controlled phase gate useless
as an oracle: a per-qubit diagonal gate puts phase `(−1)^popcount(target)` on
the marked branch and *fixes* `|0…0⟩`, so it can never mark it. That is why
`cq_phi` is **register-free** (§3.3).

#### The linear rule

**A rotation consumes the old name.** `cq_theta(x, θ)` does not return a
copy of `x` alongside the original: it names the same physical wire after
the gate. So a read of the *pre-gate* value that the compiler cannot prove
executes **before** the gate is refused — loudly, lowering nothing. This is
one rule of the language (a read of the pre-gate value would need a copy of an
unknown quantum state), and it is the reason `cq_ry(x, θ)` (below) is the
spelling to reach for: the assignment makes the consumption visible.

```c
int q = cq_theta(seed, 0.3);
int mark = q;              /* another NAME for the same wire, not a copy */
cq_ry(q, 0.4);             /* the wire moves */
int s = mark * 7;          /* REFUSED — `mark` denotes the pre-gate value:
                              cq opcode lowering: operand predates a
                              non-diagonal gate */
```

Reading the stale name into a **rotation operand or a measurement** is refused the
same way — measured, replacing the last line with `cq_measure(mark)` gives
`cq opcode lowering: rotation/measure operand predates a non-diagonal gate`.

Strict single-use is deliberately **not** the rule. Two reads of a rotated
value are ordinary and correct as long as they are provably positioned
before the gate — Grover's oracle reads `q` in the compare *and* rotates
`q` in the same region, which a single-use rule would refuse. The rule is
about **position**, not about count.

The IR pass enforces this one rule at several sites, each with its own
diagnostic, because different stages are the first to see the violation:

| site | file | diagnostic |
|---|---|---|
| the stale-record fence for an in-place rotation arm under quantum control | `ArmClassify.cpp` | `stale rail record read past a controlled Ry` |
| a rail record read at a position where the register no longer holds it, inside a classically-bounded loop | `LoopLowering.cpp` | `cq loop lowering: rail record read past an in-place gate on the same rail` |
| the pass-wide guard: a tainted pure op, or a QRAM access's index register or stored value (`tbl[mark]`, `arr[i] = mark`), scheduled past a non-diagonal wire gate | `OpcodeLowering.cpp` | `cq opcode lowering: operand predates a non-diagonal gate` |
| the same guard for a `cq_theta` operand or a `cq_measure` operand | `OpcodeLowering.cpp` | `cq opcode lowering: rotation/measure operand predates a non-diagonal gate` |

A program that trips any of them is asking for a value the hardware no longer
has.

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
form above.

### 3.3 `cq_phi` — the branch phase (register-free)

```c
void cq_phi(double angle);
```

`cq_phi(θ)` **multiplies the amplitude of the CURRENT BRANCH by
`e^{iθ}`**. It takes no register, because a phase is not a property of a
register — it is a property of the branch of the computation you are
standing in. There is one declaration, not one per type.

**Under a tainted condition it lowers by kickback.** For
`if (c(q)) cq_phi(θ)` the pass mints the condition flag `f = c(q)` into a
fresh `|0⟩` ancilla (the same compare mint every control shape uses), applies
the gate **uncontrolled** to that one qubit, and strips the flag with the
compare's `_unc`. Measured on `int q = cq_theta(0, 0.7); if (q == 5) cq_phi(PI);`:

```
cqrt_alloc_i32(0) -> h0
cqrt_ry_i32(h0, 0x1.6666666666666p-1)
cq_template_icmp_eq_i32_hl(h0, 5) -> h1                 ; mint     f = (q == 5), on a |0> ancilla
cqrt_rz_i1(h1, 0x1.921fb54442d11p+1)                    ; gate     UNCONTROLLED, one qubit
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)               ; strip    f back to |0> on EVERY branch
cqrt_free(h1)                                           ; free
cqrt_measure_i32(h0) -> 0
```

Why it works, in one line: with `f` minted, the state is
`Σ aₓ |x⟩|c(x)⟩`; a diagonal gate on the ancilla makes it
`Σ aₓ e^{iθc(x)} |x⟩|c(x)⟩`; the strip is a permutation back to
`Σ aₓ e^{iθc(x)} |x⟩|0⟩`. The phase landed on the branch and the ancilla is
provably `|0⟩` again, so freeing it is not a hidden measurement. A `¬f` arm
is bracketed by the self-inverse `cqrt_x(f)` on the ancilla — measured on
`if (q == 5) cq_phi(1.0); else cq_phi(2.0);`: `cqrt_x(h1); cqrt_rz_i1(h1, 2.0);
cqrt_x(h1); cqrt_rz_i1(h1, 1.0)` — and never a `cqrt_x` on a user register.

**Uncontrolled — or classically controlled — `cq_phi` is a global phase and
is deleted.** `cq_phi(θ)` at the top of `main`, or inside
`if (classical_flag) { … }`, multiplies the whole state vector by a scalar,
which no measurement can observe. The pass removes it (measured: neither
`cq_phi(1.0)` beside a kickback nor `if (argc > 5) cq_phi(1.0)` leaves a
`cqrt_rz_i1`). This is a **documented semantic, not a diagnostic**: there is
nothing wrong with the program, and no message is emitted.

**There is no multi-bit Rz.** A per-register Rz applied to each of the W qubits
is exactly what makes it useless under control (§3.2). The idiom for a
register-wide Z rotation is a plain classical loop over the bits:

```c
for (int i = 0; i < W; i++)
    if ((q >> i) & 1)
        cq_phi(θ);              /* one branch phase per set bit */
```

Each iteration is an ordinary tainted-condition region, so this needs no new
capability. Measured with `W = 4`, `q = cq_theta(3, 0.7)`: four regions, each
`and`-mask flag → `cqrt_x`-bracketed `cqrt_rz_i1(f, θ)` → `_unc` strip → free
(`-O1` rewrites the condition to `q & (1<<i)` and unrolls the small loop).

**Two worked examples.** Both are the flagship customer:

```c
/* Grover oracle — mark |5> with a -1 phase */
if (q == 5) cq_phi(PI);

/* reflection about |0> — mark |0..0> with a -1 phase */
if (q == 0) cq_phi(PI);
```

A per-qubit register phase would put `e^{iπ·popcount(5)} = +1` on the marked
branch for the first and could not touch `|0…0⟩` at all for the second, because
a per-qubit diagonal gate fixes it. Under the branch phase both put `−1`
exactly where the source says, and the second is not a special case (measured:
`cq_template_icmp_eq_i32_hl(h0, 0) -> h1; cqrt_rz_i1(h1, π); …_unc; cqrt_free`).
A complete two-iteration Grover program is
`tests/e2e/slice_control_grover_2iter.c`, with its golden trace beside it.

**Taint.** `cq_theta` is the sole source, `cq_measure` the sole sink. `cq_phi`
does not propagate anything — it has no data operand to propagate through. It is
ordered by the **block it sits in**, not by a data dependence, which is
precisely what makes it a branch phase. Only `cq_theta` creates superposition;
only `cq_theta` allocates.

#### The one operand is an angle — and the name is reserved

**Any classical expression is a legal angle, including an integer one.**
`cq_phi(7)` compiles by the ordinary implicit `int → double` conversion and *is*
a phase of 7 radians: measured, `if (q == 5) cq_phi(7);` emits
`cqrt_rz_i1(h1, 0x1.cp+2)`. There is no diagnostic. The type system no longer
separates "register" from "angle", so a `cq_phi(x, φ)` shortened to `cq_phi(x)`
is a legal program that means something else — **port an old call by rewriting
it, never by deleting an argument**.

A **run-time** classical angle lowers when it reaches the pass as a value defined
before the branch (measured: a `double` loaded from a `volatile` global). `-O1`
sinks cheap classical computation into the arm — an `int → double` conversion,
a multiply — and that shape is **not lowered yet**: `if (q == 5) cq_phi(argc);`
fails with `cq controlled lowering: control flow under quantum control`.

A **quantum-derived** angle declines loudly and lowers nothing — measured,
`double a = (double)q; cq_phi(a);` gives
`cq rotation lowering: unsupported quantum-derived rotation angle`. The angle of
a rotation is classical, always (quantum data reaching classical code needs an
explicit `cq_measure`).

**`cq_phi` is a reserved name and must not be defined by user code.** The pass
claims the symbol by exact name with the prototype `void(double)`; a declaration
with any other prototype is a loud decline (measured on hand IR,
`declare void @cq_phi(i32)`: `cq rotation lowering: unsupported declared
prototype for cq_phi`). The **retired** per-register `cq_phi_<sfx>(x, φ)` family
is likewise reserved: a call to one declines with `cq rotation lowering: retired
register-form cq_phi_si32; use the register-free void cq_phi(double)`. Do not
define `cq_phi` yourself: at `-O1` Clang inlines a visible body before the pass
runs, so the branch phase would be lost.

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
   handle SSA value is unchanged across the measure call. (Measured:
   `m = cq_measure(q); cq_ry(q, 0.2); cq_measure(q);` emits
   `measure(h0); ry(h0, 0.2); measure(h0)` on one handle.)

Casting a quantum-typed value does *not* measure. A `(double) x` on a
tainted `int x` is a representation change, lowered as a quantum `sitofp`
template under taint (measured: `cq_template_sitofp_i32_to_f64(h0) -> h1`). The
cast does what casts do classically.

### 3.5 `cq_invert_begin` / `cq_invert_end` — manual inversion

```c
cq_invert_begin();
    /* gate sequence S — emitted as written, but lowered as S† */
    f(q);
    g(q);
cq_invert_end();
```

**Not lowered yet.** The header declares the two markers and they survive
`clang -O1` (pinned by `tests/frontend/cq_invert_markers_survive.c`), but the
IR pass does not implement the bracket. Measured on `q = cq_theta(3, 0.5);
cq_invert_begin(); cq_ry(q, 0.25); cq_invert_end(); cq_measure(q);`: `opt`
exits **0**, the bracketed rotation is emitted **forward**
(`cqrt_ry_i32(h, 0.25)`), and the calls `@__cq_invert_begin` / `@__cq_invert_end`
are left in the lowered IR, so the program then fails to **link**
(`Undefined symbols … ___cq_invert_begin`). Do not use the bracket until it is
lowered.

The intended semantics, which the design commits to (NORTHSTAR principle 7,
"adjoints are derived, never authored"): the bracketed region is lowered as the
adjoint of the gate sequence written inside it, each instruction's inverse
derived mechanically — NOT/CNOT/Toffoli are self-adjoint; rotations negate their
angle; arithmetic templates use their generated inverse twins. This is the only
user-facing inversion surface. Ordinary uncomputation at scope exit needs no
bracket: the compiler emits the adjoint of every compiler-minted rail itself
(`backend.md` §9); the user writes `cq_invert_*` only when they want explicit
control over a specific region.

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

The entire user-visible compiler surface beyond stock C is `cq_theta` (and its
statement form `cq_ry`), `cq_phi`, `cq_measure`, and the
`cq_invert_begin`/`_end` markers.

---

## 4. Allocation is gate-triggered

Allocation happens at the *first* `cq_theta` on a classical operand. A variable
that is declared, mutated arithmetically, and never rotated never touches the
qubit substrate:

```c
int a = 3;          /* classical */
a = a + 1;          /* classical add — `a` is now 4 */
a = a * 2;          /* classical mul — `a` is now 8 */
a = cq_theta(a, 0.5);   /* HERE: allocation + Ry(0.5) on a fresh register
                           initialized to 8 */
int b = a + 5;      /* tainted add — `b` becomes a tainted register */
return cq_measure(b);
```

What the IR pass sees after Clang `-O1`:

```llvm
define i32 @main() {
  %1 = tail call i32 @cq_theta_si32(i32 8, double 5.000000e-01)  ; taint source
  %2 = add nsw i32 %1, 5                                         ; stock LLVM add
  %3 = tail call i32 @cq_measure_si32(i32 %2)                    ; taint sink
  ret i32 %3
}
```

The classical chain folded to the literal `8` before the pass ran. What the
pass emits (measured trace):

```
cqrt_alloc_i32(8) -> h0        ; allocate, init to the value at the rotation site
cqrt_ry_i32(h0, 0x1p-1)        ; Ry(0.5)
cqrt_addc_i32(h0, 5)           ; the add: in place, immediate 5
cqrt_measure_i32(h0) -> 0
```

The add is **in place** (`h := h + 5`) because nothing reads the pre-add register
afterwards. If the pre-add value stays live — say a second `cq_measure(a)` — the add
is out of place instead and mints a fresh rail:
`cq_template_add_i32_hl(h0, 5) -> h1` ([`example.md`](./example.md) shows both).

Three consequences for the user:

1. Classical arithmetic stays on classical registers until the first
   rotation. The pre-rotation `a = a + 1; a = a * 2` lines remain
   stock LLVM `add`/`mul` instructions on `i32`, fast and cheap.
2. The register is initialized to whatever value the operand carried
   at the moment of the first rotation. The user never needs to
   write `a = 3; cq_init(a); cq_theta(a, ...)` — the value at the
   rotation site *is* the initialization.
3. Variables that look quantum in intent but are never actually rotated
   produce no qubits at runtime (measured: the same program without the
   `cq_theta` line lowers to no runtime calls at all). The frontend has no
   mechanism to "declare quantum" without invoking a gate.

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
| Which function calls need quantum specialization | — | Tainted-argument mask at the callsite (clone-on-taint of the visible body, §6) |
| Which branches are quantum-controlled | — | Branch condition's taint state; the region is then recovered from the CFG shape by SSA-value identity, arm by arm (§7) |
| Allocation lifetime / uncomputation point | — | Whole-DAG reverse-order adjoint at a post-dominator free point, and only for a rail provably back at `\|0⟩` (`backend.md` §9) |
| Rotation (Ry) | `cq_theta(x, θ)` / `cq_ry(x, θ)` | — |
| Branch phase | `cq_phi(θ)` | Which branch it lands on — from the enclosing tainted condition, by kickback (§3.3) |
| Measurement | `cq_measure(x)` | — |
| Manual inversion | `cq_invert_begin();` / `cq_invert_end();` (not lowered yet, §3.5) | Would derive the adjoint inside the bracket |

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
/* poly.c — written without quantum awareness */
int poly(int a, int b) { return a * a + b; }
```

```c
/* main.c */
int poly(int a, int b);

int main(void) {
    int x = cq_theta(2, 0.3);   /* x is tainted */
    int y = poly(x, 5);          /* tainted x flows into poly */
    int z = poly(4, 5);          /* classical call of the same function */
    return cq_measure(y) + z;    /* measure result */
}
```

Two facts the user can rely on:

1. **`poly` does not need to be edited.** It is plain C; it is consumed by
   classical callers unchanged. The IR pass synthesizes a quantum specialization
   at the tainted-argument call site, alongside the original `@poly` which
   remains for classical callers. Compiled with `cqc main.c poly.c -o out`
   (two translation units, so `-O1` cannot inline `poly` first), the lowered
   module contains `@poly`, an internal `@__cq_q_poly_01`, a call
   `@__cq_q_poly_01(h, 5)` at the tainted site, and the classical
   `poly(4, 5)` still calls `@poly`.
   The name is `__cq_q_<callee>_<mask>`, the mask a binary string with bit *i*
   set when argument *i* is tainted, most significant bit first (`01` = argument 0).
2. **Internal casts do not measure.** A `(double)` cast inside the
   callee — common in averages, divisions, math wrappers — is a
   representation change at IR level (`sitofp`) and lowers to a
   quantum cast template under taint. It does not collapse the
   superposition.

The specialization computes the result, copies it into a fresh `|0⟩` rail
and uncomputes its intermediates. Measured trace for the program above:

```
cqrt_alloc_i32(2) -> h0
cqrt_ry_i32(h0, 0x1.3333333333333p-2)
cq_template_mul_i32(h0, h0) -> h1                 ; a*a
cq_template_add_i32_hl(h1, 5) -> h2               ; + b
cqrt_alloc_i32(0) -> h3
cqrt_copy_i32(h2, h3)                             ; result copied out
cq_template_add_i32_hl_unc(h2, h1, 5)             ; intermediates uncomputed
cq_template_mul_i32_unc(h1, h0, h0)
cqrt_free(h1)
cqrt_free(h2)
cqrt_measure_i32(h3) -> 0
```

This is the property the previous (`quantum` keyword + cast-as-measurement)
design failed to provide: hidden casts inside library code triggered unwanted
measurements, and the caller had no way to know which classical functions were
"safe to lift".

### 6.2 What can be lifted

The IR pass uses different mechanisms depending on what is visible at pass time.

- **A visible body — clone-on-taint.** For user code and any library whose
  body is in the same module, the pass clones the callee keyed by the taint
  signature of the call, propagates taint through the clone, lowers it, and
  retargets the call. The original function is left intact for classical
  callers. The user's only obligation is to make the callee's IR reach the pass
  in the same module: `cqc` compiles every input with `clang -O1`, joins the
  translation units with `llvm-link` and runs `opt` on the result (§8), so
  `cqc main.c lib.c -o out` is enough. Without the body the call is refused
  (measured, a call to a function only declared: `cq taint escape: tainted value
  consumed by an unknown callee`).
- **A library function — its source, in the module.** A `math.h` function
  such as `sin` with quantum arguments and no body in the module fails the
  same way (measured: `sin(x)` on a tainted `double` gives `cq taint escape:
  tainted value consumed by an unknown callee`). A library function means its
  real implementation compiled into the module before the pass runs, so the pass
  sees ordinary opcodes; it is never recognized by name. Today that injection is
  done by the coverage harness (`tools/library_coverage/`); `tools/cqc` links
  only the sources it is given and does not inject a library body itself
  ([`backend.md`](./backend.md) §7.1). Library coverage and its accounting are
  NORTHSTAR goal 2.
- **A hardware-mapped LLVM intrinsic.** A handful of operations that
  `clang -O1` turns into an `@llvm.*` intrinsic (`sqrt`, `fabs`, `floor`, the
  integer bit intrinsics `ctpop`/`ctlz`/`cttz`/`bswap`, `smin`/`umax`, …) lower
  directly to a template (measured: `sqrt(x)` on a tainted `double` gives
  `cq_template_sqrt_f64(h0) -> h1`).

### 6.3 What lifting does not cover

- **An opaque external with a tainted argument** — a callee with no visible or
  injected body — cannot be lifted: there is no implementation to lower. It is
  refused at compile time, pointing at the call (`cq taint escape: tainted value
  consumed by an unknown callee`). This is one of the physics-forced declines of
  NORTHSTAR goal 1.
- **An indirect call with a tainted argument** — `(*fp)(tainted_x)` where `fp`
  is chosen at run time — is **not lowered yet**. Measured with `fp` selecting
  between two visible functions: the same `cq taint escape … unknown callee`
  diagnostic. Specializing every potential target is the direction, not a
  language rule.
- **Output.** A tainted value passed to `printf` is not refused: measured with
  `printf("%d\n", x)` on a tainted `int`, the call is replaced by an append to a
  reversible output tape (`cqrt_tape_alloc`, `cqrt_tape_write_i32(tape, h)`) — a
  kept `|0⟩`-initialised output rail, with the measurement deferred to tape
  inspection (`runtime/cq_runtime.h`, "Reversible I/O output tape"). Reading
  quantum data into classical code any other way still needs an explicit
  `cq_measure`.

All of these are diagnosed at compile time; the user sees the error before
the program runs.

---

## 7. Quantum control flow

A branch whose condition is tainted is a quantum branch: the program
is in a superposition of "taken" and "not taken", and the branch's arms
execute coherently under the condition.

There is **no `cq_when_begin` / `cq_when_end` user-facing surface**. The IR pass
recovers the controlled region structurally ([`backend.md`](./backend.md) §8):

1. Identify each `br i1 %cond, label %T, label %F` (and each `select` and
   `switch`) whose condition is tainted (operand taint, derived from forward
   propagation).
2. Recover the region's shape from the CFG and SSA by value identity, before
   anything is mutated: a flat diamond, an if/else, a nest, a `switch`, and, for
   general acyclic control flow, the sub-graph between the branch and its merge
   (its immediate post-dominator), which is rewritten into straight-line
   predicated code first. A shape the pass cannot recover is refused loudly.
3. Classify the arms and hand the region to the emitter for their class. Values
   defined inside an arm are **not** marked tainted "by shadow"; what the branch
   changes is carried by what the emitter mints. In particular a merge whose
   direct operands are classical literals (a φ between `10` and `20` looks
   classical operand-wise, but the selected value depends on the quantum branch)
   is replaced by a fresh quantum rail, and taint is re-seeded from that rail
   by a second detection round (`backend.md` §2 stage 4, §4.1).
4. Mint the condition into a flag qubit `f` (a fresh `|0⟩` ancilla), lower the
   arms by the mechanism their **arm class** demands, then strip `f` back to
   `|0⟩` with the compare's `_unc` and free it.

The user's view is therefore: a plain C `if (tainted_cond) { ... }`
*is* the controlled region. The user does not need to bracket it. (`clang -O1`
often rewrites a small `if` into a `select` or straight-line arithmetic before
the pass sees it; the lowering below is the same.)

The "arm class" of steps 3 and 4 is the one thing worth knowing at the source level,
because the classes are not interchangeable — a basis-copy is the wrong
tool for a phase, because a CNOT copies a basis *label*, not a *phase*:

- **A phase arm** — the arm is `cq_phi(θ)` — is **kickback**: the gate goes
  on the flag `f`, **uncontrolled** (`cqrt_rz_i1(f, θ)`), and the strip
  carries the phase back onto the branch (§3.3). Nothing is applied to the
  data register at all. This covers the flat diamond and `if/else`, the folded
  angle select, and a condition built from several tainted compares (measured:
  `if (q > 2) { if (p == 1) cq_phi(0.5); }` on two registers gives one flag per
  compare, a `cqrt_toffoli` conjunction ancilla, one `cqrt_rz_i1` on it, and the
  LIFO teardown).
- **A rotation arm** — the arm is `cq_theta` on a register the condition
  does not read — is applied **in place**, as one controlled gate
  (`cqrt_ry_<W>_controlled(f, h, θ)`); the rotated register and the control
  register are left allocated. Measured on
  `if (q == 5) r = cq_theta(r, 0.9);`:
  ```
  cq_template_icmp_eq_i32_hl(h0, 5) -> h2
  cqrt_ry_i32_controlled(h2, h1, 0x1.ccccccccccccdp-1)
  cq_template_icmp_eq_i32_hl_unc(h2, h0, 5)
  cqrt_free(h2)
  ```
  A controlled state preparation (`if (c) r = cq_theta(SEED, θ)`) lowers the
  same way on a fresh rail.
- **A value arm** — the arm assigns an arithmetic result — is a
  **controlled-copy merge**: the arm's chain runs unconditionally on the
  original register (it is hoisted above the branch), the flag is minted, and
  the answer is merged into a fresh `|0⟩` rail by two `cqrt_copy_<W>_controlled`,
  the second under `cqrt_x(f)`, and the flag is stripped and freed. The source
  register stays live and the chain's final rail is left allocated. Measured on
  `int y = x > 1 ? x + 3 : 7;`:
  ```
  cq_template_add_i32_hl(h0, 3) -> h1            ; the chain, unconditionally
  cq_template_icmp_sgt_i32_hl(h0, 1) -> h2       ; the flag
  cqrt_alloc_i32(0) -> h3                        ; fresh |0> result rail
  cqrt_copy_i32_controlled(h2, h1, h3)
  cqrt_x(h2)
  cqrt_alloc_i32(7) -> h4
  cqrt_copy_i32_controlled(h2, h4, h3)
  cqrt_x(h2)
  cq_template_icmp_sgt_i32_hl_unc(h2, h0, 1)     ; strip the flag
  cqrt_free(h2)
  ```

A class mixture, or a shape the pass cannot prove, is refused loudly
(measured, for example `control flow under quantum control` for a `switch` whose
cases carry different phases, and `impure phase arm under quantum control`); each
is a compiler gap to be filed, not a rule about the language. A silently wrong
unitary is the one unforgivable bug, so a construct is lowered only when its
lowering is proven.

### Why no user-facing `cq_when`

A `cq_when` marker would only matter if the user wanted to
quantum-control on a condition the pass would not flag as tainted.
But quantum control on a classical condition has no physical content:
a classical 1 reduces to unconditional application, a classical 0 to
no-op. There is no superposition of "applied vs. not" without a
tainted control wire.

So tainted-condition is **necessary and sufficient** for controlled-
form lowering. Source-level markers would be redundant ceremony.

### Loops

A loop with a classical trip count lowers, with tainted control inside its body
(measured: `for (int i = 0; i < 6; i++) if (q & (1 << i)) cq_phi(0.1);`). A loop whose trip
count depends on quantum data has **no finite bound the compiler derives today**
and is refused (measured: `while (n * n < q) n++;` on a tainted `q` gives
`cq controlled lowering: loop under quantum control`). Whether a construct like
this is admissible in principle is NORTHSTAR goal 1: a quantum-dependent loop
needs a finite bound, and a bound the programmer supplies is valid. Some loops
with a classical run-time trip count that carry a tainted value across
iterations are not lowered yet either (measured: `for (i < argc) s = s * 3 + 1;`
on a tainted `s` gives `cq loop lowering: loop-carried tainted value crosses
iterations`).

---

## 8. Compilation flow

The frontend's deliverable to the backend is a single bitcode module
post-Clang-`-O1`. Three stages:

```
.c source (plain C + #include <CQ.h>)
   ▼
Stage 1: clang -O1 -emit-llvm -c -include CQ.h
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

All LLVM tools must be LLVM 19. On a Homebrew machine they live in
`$(brew --prefix llvm@19)/bin`, which is not on `PATH`.

### Single-file program

```bash
clang -O1 -emit-llvm -c -include CQ.h -I<cq>/include example.c -o example.bc
opt -load-pass-plugin <cq>/build/ir-pass/libCQPass.so -passes=cq-lowering \
    example.bc -o example.lowered.bc
clang example.lowered.bc -L<cq>/build/runtime -lcq_templates -lcq_runtime -o example
./example
```

(`-emit-llvm` needs `-c` or `-S`; without one clang tries to link and refuses:
`-emit-llvm cannot be used when linking`.) **Link order is load-bearing:**
`libcq_templates` before `libcq_runtime`, because the template bodies call
`cqrt_*`. The default runtime is the trace backend: each `cqrt_*` and
`cq_template_*` call prints one line (`symbol(args) -> ret`) and `measure` returns
0; a production backend is selected at install time (`tools/install_cq.py`,
[`backend-provider.md`](./backend-provider.md)).

### Multi-file program (function lifting across translation units)

Clone-on-taint requires callee bodies in the same bitcode module the
pass sees. Compile every translation unit with `-O1`, `llvm-link` them, and only
then run `opt`. Only the CQ translation unit takes `-include CQ.h`:

```bash
clang -O1 -emit-llvm -c -include CQ.h main.c -o main.bc
clang -O1 -emit-llvm -c util.c -o util.bc          # util.c needs no CQ.h
llvm-link main.bc util.bc -o combined.bc            # bitcode link first
opt -load-pass-plugin libCQPass.so -passes=cq-lowering \
    combined.bc -o combined.lowered.bc
clang combined.lowered.bc -L<cq>/build/runtime -lcq_templates -lcq_runtime -o program
```

`tools/cqc` wraps exactly this under one invocation:
`cqc main.c util.c -o program` (the first input is the CQ translation unit,
every later one a plain C library; `LLVM_PREFIX=$(brew --prefix llvm@19)` tells it
where the tools are).

### Optimization-level guidance

The `-O` level passed to Clang at Stage 1 and to Clang at Stage 3 are
independent choices. Stage 2 (the `cq-lowering` pass itself) takes no `-O` level.

| Stage | Default | Notes |
|---|---|---|
| Stage 1 (pre-IR-pass) | `-O1` | `-O1` is the validated floor: `mem2reg` / SROA must run before the pass sees the IR. `-O0` is not supported and fails loudly (measured: `cq taint escape: tainted value stored to memory`, the `alloca` traffic). `-O2` and `-O3` are **not validated**: they reshape more of the IR (inlining, IPSCCP, loop and branch rewrites) before the pass sees it. |
| Stage 3 (post-pass codegen) | matches user's `-O` | Stage 3 IR contains only stock LLVM ops on classical SSA plus `cqrt_*` and `cq_template_*` externals, declared with no `readnone`/`readonly` attributes, so ordinary optimization cannot reorder or merge them. |

`-O1` itself rewrites more than one might expect, and the pass is written against
what it produces: it swaps branch polarity (`if (u != k)` becomes `icmp eq` with
the arms exchanged), sinks and hoists classical computation across a branch,
folds a small `if` into a `select`, and unrolls small constant-trip loops. In
particular **SimplifyCFG merges identical calls across the two arms of a branch**
and so can delete a branch whose arms only became identical because IPSCCP
substituted a pinned register; for `cq_theta` that would be a miscompile, and
`CQ.h` forbids it with `nomerge` for DIRECT calls (§3.1, "Why every `cq_theta_*`
is `nomerge`"; a call through a function pointer escapes it, bd `4e4p`, and the
`select` fold at `cq_theta`'s operand needs no merge at all, bd `uw5u`).

---

## 9. Cross-references

| Concern | Where it is documented |
|---|---|
| The plan of record: goals and design principles | [`../NORTHSTAR.md`](../NORTHSTAR.md) |
| Stock LLVM C++ APIs the whole pipeline uses | [`llvm-implementation.md`](./llvm-implementation.md) |
| Taint as Q/C boundary; mixed-operand semantics; conversion semantics | [`quantum-classical-handling.md`](./quantum-classical-handling.md) |
| Forward taint propagation algorithm; allocation insertion; opcode lowering; specialization; controlled-form lowering; uncomputation | [`backend.md`](./backend.md) |
| End-to-end worked example, source → lowered IR | [`example.md`](./example.md) |
| Backend providers (the trace backend and production backends) | [`backend-provider.md`](./backend-provider.md) |
