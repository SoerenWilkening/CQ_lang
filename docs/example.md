# Worked Example — Pipeline End-to-End to LLVM IR

A minimal program walked through each stage of the CQ pipeline up to and
including the LLVM IR the back-end pass receives. Anything below LLVM IR
(gate-runtime calls, simulator output, OpenQASM, hardware transport) is
out of scope for this document.

Read alongside [`architecture.md`](./architecture.md) — this is the
worked-example companion.

---

## What this example exercises

- `quantum int` declarations with classical initialization
- A quantum-quantum binary operation (`+`), lowered to stock LLVM
  arithmetic
- Measurement via type cast
- Forward taint propagation that identifies the stock `add i32` as a
  quantum operation

What this example does **not** exercise (deferred to future examples):

- Quantum-controlled blocks (`if (q_cond)` → `cq_when_*`)
- Manual inversion (`invert(...)`)
- Calls into classical functions with quantum arguments
  (auto-specialization)
- Rotations (`theta`, `phi`)
- Per-op uncomputation at scope exit (omitted because the example's only
  enclosing function is `main`, where uncomputation is suppressed)

---

## Stage 1 — CQ source

```c
/* example.c */

#include <CQ.h>

int main(void) {
    quantum int a = 3;
    quantum int b = 5;

    quantum int c = a + b;        /* out-of-place add; c is a fresh qint */

    int measured = (int) c;       /* measurement-as-cast */

    return measured;
}
```

This is what the user writes. Plain-looking C with the `quantum` keyword
and the cast-to-measure idiom. No inverses, no scope annotations, no
attributes.

---

## Stage 2 — After the AST rewriter

```c
/* example.transpiled.c */

#include "CQ.h"     /* declares qint_mid_t and the ~7-function @cq_* surface */

int main(void) {
    qint_mid_t a = cq_init(3, 16);
    qint_mid_t b = cq_init(5, 16);

    qint_mid_t c;
    c.val = a.val + b.val;        /* stock C arithmetic on .val */

    int64_t measured = cq_measure(c);

    return (int) measured;
}
```

What changed (and what didn't):

- `quantum int a = 3;` → `qint_mid_t a = cq_init(3, 16);`. The
  `cq_init` call is a **taint source** in the IR (§7.1 of the
  architecture doc). The width argument `16` corresponds to `int`'s
  bit-width in the project's type table.
- `quantum int c = a + b;` → `qint_mid_t c; c.val = a.val + b.val;`.
  **Notice:** no `cq_add_qq` intrinsic. The arithmetic stays as ordinary
  C, performed on the `.val` field of the mid-level struct. Clang will
  lower it to a stock LLVM `add` instruction; taint propagation will
  identify it as quantum.
- `(int) c` → `cq_measure(c)`. Measurement is the **taint sink**.
  Returns `i64`; the explicit `(int)` cast back to `int` becomes a
  `trunc i64 → i32` in IR.
- No `cq_add_inv` anywhere. Inverses are emitted by the IR pass at the
  last use of each tainted value — and since the only enclosing function
  here is `main`, no inverses are emitted at all (ROADMAP §Phase 5
  rule).

The relevant excerpt of `CQ.h`:

```c
/* CQ.h — user-facing declarations only; no implementations */

typedef struct { int val; } qint_mid_t;

qint_mid_t cq_init(int64_t value, unsigned num_bits);
int64_t    cq_measure(qint_mid_t);

void cq_theta(qint_mid_t* q, double angle);
void cq_phi  (qint_mid_t* q, double angle);

void cq_when_begin(qint_mid_t cond);
void cq_when_end  (void);
void cq_invert_begin(void);
void cq_invert_end  (void);

/* Plus the `quantum` keyword macro for Phase 2's CQ.h entry. */
```

Six functions plus the `quantum` keyword. That's the entire LLVM-level
extension surface. (`cq_alloc` was removed 2026-05-21 — see
`architecture.md` §6.1 Decision note.)

---

## Stage 3 — Raw LLVM IR (`clang -emit-llvm -S example.transpiled.c -O0`)

What Clang produces straight from the rewritten source, before any
optimization:

```llvm
%struct.qint_mid_t = type { i32 }

declare %struct.qint_mid_t @cq_init(i64, i32)
declare i64 @cq_measure(%struct.qint_mid_t)

define i32 @main() {
entry:
  %a        = alloca %struct.qint_mid_t
  %b        = alloca %struct.qint_mid_t
  %c        = alloca %struct.qint_mid_t
  %measured = alloca i64

  ; quantum int a = 3;
  %a_cast = bitcast %struct.qint_mid_t* %a to i8*
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %a_cast)
  %a_init = call %struct.qint_mid_t @cq_init(i64 3, i32 16)
  store %struct.qint_mid_t %a_init, %struct.qint_mid_t* %a

  ; quantum int b = 5;
  %b_cast = bitcast %struct.qint_mid_t* %b to i8*
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %b_cast)
  %b_init = call %struct.qint_mid_t @cq_init(i64 5, i32 16)
  store %struct.qint_mid_t %b_init, %struct.qint_mid_t* %b

  ; quantum int c; c.val = a.val + b.val;
  %c_cast = bitcast %struct.qint_mid_t* %c to i8*
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %c_cast)
  %a_load   = load %struct.qint_mid_t, %struct.qint_mid_t* %a
  %a_val    = extractvalue %struct.qint_mid_t %a_load, 0
  %b_load   = load %struct.qint_mid_t, %struct.qint_mid_t* %b
  %b_val    = extractvalue %struct.qint_mid_t %b_load, 0
  %sum      = add i32 %a_val, %b_val               ; ← stock LLVM primitive
  %c_zero   = load %struct.qint_mid_t, %struct.qint_mid_t* %c
  %c_with   = insertvalue %struct.qint_mid_t %c_zero, i32 %sum, 0
  store %struct.qint_mid_t %c_with, %struct.qint_mid_t* %c

  ; int measured = (int) c;
  %c_load   = load %struct.qint_mid_t, %struct.qint_mid_t* %c
  %m        = call i64 @cq_measure(%struct.qint_mid_t %c_load)
  store i64 %m, i64* %measured

  ; --- scope ends; Clang inserts lifetime.ends ---
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %c_cast)
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %b_cast)
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %a_cast)

  %m_load = load i64, i64* %measured
  %retval = trunc i64 %m_load to i32
  ret i32 %retval
}
```

Two things to notice in this raw IR:

1. **`%sum = add i32 %a_val, %b_val`** — the quantum addition is a stock
   LLVM `add` instruction. No `@cq_add` call. This is one of the 38
   primitives Bennett's mapper handles; the IR pass will identify it as
   quantum via taint analysis.
2. **`@llvm.lifetime.start/end`** markers bracket each `qint_mid_t`
   stack slot. These are what the IR pass uses to detect "where to emit
   uncomputation," even though we won't emit any here (the enclosing
   function is `main`).

---

## Stage 4 — LLVM IR after Clang's `-O1` cleanup

This is what the **CQ IR pass actually receives** as input. After
`mem2reg` and `sroa`:

```llvm
%struct.qint_mid_t = type { i32 }

declare %struct.qint_mid_t @cq_init(i64, i32)
declare i64 @cq_measure(%struct.qint_mid_t)

define i32 @main() {
  %a_struct = call %struct.qint_mid_t @cq_init(i64 3, i32 16)
  %a        = extractvalue %struct.qint_mid_t %a_struct, 0

  %b_struct = call %struct.qint_mid_t @cq_init(i64 5, i32 16)
  %b        = extractvalue %struct.qint_mid_t %b_struct, 0

  %c        = add i32 %a, %b                                  ; ← STOCK LLVM PRIMITIVE
  %c_struct = insertvalue %struct.qint_mid_t poison, i32 %c, 0

  %m        = call i64 @cq_measure(%struct.qint_mid_t %c_struct)
  %r        = trunc i64 %m to i32
  ret i32 %r
}
```

The `alloca`s, `load`s, `store`s, and lifetime markers have collapsed —
`mem2reg` and `sroa` see through the single-field wrapper. What's left
is a clean SSA chain:

```
@cq_init(3,16) ─▶ %a_struct ─▶ %a ──┐
                                    ├─▶ %c ─▶ %c_struct ─▶ %m ─▶ %r ─▶ ret
@cq_init(5,16) ─▶ %b_struct ─▶ %b ──┘
                                          @cq_measure
```

---

## Taint analysis on this IR

This is the first analysis the CQ IR pass runs (§7.1 of the architecture
doc). Trace through the values:

| SSA value | Tainted? | Why |
|---|---|---|
| `%a_struct` | **yes** | return of `@cq_init` (taint source) |
| `%a` | **yes** | `extractvalue` of a tainted aggregate |
| `%b_struct` | **yes** | return of `@cq_init` |
| `%b` | **yes** | `extractvalue` of a tainted aggregate |
| `%c` | **yes** | `add i32` with at least one tainted operand |
| `%c_struct` | **yes** | `insertvalue` carrying a tainted scalar |
| `%m` | **classical** | `@cq_measure` is a taint sink; its `i64` is classical |
| `%r` | **classical** | `trunc` of a classical value |

So the IR pass classifies `%c = add i32 %a, %b` as a **quantum add**.
The instruction itself is plain stock LLVM IR — what's special is the
taint state of its operands.

This is also why the same `add i32` could appear in two different
function instances and be classical in one (no tainted operands) and
quantum in the other — without any function-level annotation. It's a
purely operand-driven analysis.

---

## What the IR pass would do next (sketch only — below the LLVM-IR layer)

To finish the lowering, the IR pass would (still working at LLVM IR
level, just adding lower-level calls):

1. Replace `@cq_init(3, 16)` with `cqrt_alloc_classical(handle, 3, 16)`
   — allocate a qubit register handle and initialize with the classical
   value 3.
2. Replace the tainted `add i32 %a, %b` with the chosen reversible-adder
   template: a sequence of `cqrt_cnot` and `cqrt_toffoli` calls
   threading through ancilla and result qubit handles.
3. Replace `@cq_measure(...)` with `cqrt_measure(handle)`.
4. Skip uncomputation entirely (the enclosing function is `main` —
   ROADMAP §Phase 5).

The resulting IR (`example.lowered.ll`, conventionally) would contain no
`@cq_*` calls and no tainted stock opcodes — only `cqrt_*` runtime
calls. That output is below the scope of this example.

---

## Compilation flow (sketch)

```bash
quantum_transpiler example.c -- -std=c11   > example.transpiled.c   # Stage 2
clang -emit-llvm -S example.transpiled.c                            # Stage 3 (-O0)
clang -emit-llvm -S example.transpiled.c -O1                        # Stage 4
cq_ir_pass example.ll  -o  example.lowered.ll                       # (out of scope)
clang example.lowered.ll  -lcq_runtime  -o example                  # (out of scope)
./example                                                            # builds circuit
```

The transpiler is the v1 tool, slightly extended for Phase 2 surface.
`cq_ir_pass` is the new component that owns the IR-level work described
in §7 of the architecture doc.

---

## Cross-references

- Architecture overview: [`architecture.md`](./architecture.md), §§3–7
- Why arithmetic is stock LLVM and not intrinsics:
  [`architecture.md`](./architecture.md) §2 P4 and §6.6
- Per-op uncomputation rules: [`architecture.md`](./architecture.md) §7.4
- Bennett.jl / Sturm.jl design comparison:
  [`bennett-jl-comparison.md`](./bennett-jl-comparison.md)
- Pipeline whiteboard sketch:
  [`pipeline-sketch.md`](./pipeline-sketch.md)
