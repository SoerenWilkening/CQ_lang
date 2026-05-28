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

#include <cq_mid.h>  /* transpiled-C ABI: qint_mid_t + per-width @cq_*_i32 intrinsic decls */

int main(void) {
    qint_mid_t a = cq_init_i32(3);
    qint_mid_t b = cq_init_i32(5);

    qint_mid_t c;
    c.val = a.val + b.val;        /* stock C arithmetic on .val */

    int32_t measured = cq_measure_i32(c);

    return (int) measured;
}
```

What changed (and what didn't):

- `quantum int a = 3;` → `qint_mid_t a = cq_init_i32(3);`. The
  `cq_init_i32` call is a **taint source** in the IR (§7.1 of the
  architecture doc). Width is encoded in the intrinsic name (`_i32`) —
  Phase 1 ships only the 32-bit family; other widths arrive in later
  phases (architecture §6.1 decision 2026-05-22).
- `quantum int c = a + b;` → `qint_mid_t c; c.val = a.val + b.val;`.
  **Notice:** no `cq_add_qq` intrinsic. The arithmetic stays as ordinary
  C, performed on the `.val` field of the mid-level struct. Clang will
  lower it to a stock LLVM `add` instruction; taint propagation will
  identify it as quantum.
- `(int) c` → `cq_measure_i32(c)`. Measurement is the **taint sink**.
  Returns `i32`; the explicit `(int)` cast back to `int` is a no-op at
  the IR level (both are `i32`).
- No `cq_add_inv` anywhere. Inverses are emitted by the IR pass at the
  last use of each tainted value — and since the only enclosing function
  here is `main`, no inverses are emitted at all (ROADMAP §Phase 5
  rule).

The full contents of `CQ.h` — the user-facing surface:

```c
/* CQ.h — user-facing only; this is the entire algorithm-author surface */

#define quantum __attribute__((annotate("quantum")))
```

That's it. `qint_mid_t` and the per-width intrinsics are an
implementation detail of the *transpiled* C, not something the
algorithm author writes against. They live in a separate header
that the rewriter emits into its output:

```c
/* cq_mid.h — transpiled-C ABI; algorithm authors never #include this */

typedef struct { int32_t val; } qint_mid_t;

qint_mid_t cq_init_i32(int32_t value);
int32_t    cq_measure_i32(qint_mid_t q);
```

Per-width intrinsic family: Phase 1 ships the 32-bit pair
(`cq_init_i32`, `cq_measure_i32`). Other widths (i8/i16/i64) and other
intrinsic families (rotations, conditioning, manual inversion) enter
in later phases. (`cq_alloc` was removed 2026-05-21 — see
`architecture.md` §6.1 Decision note.)

---

## Stage 3 — Raw LLVM IR (`clang -emit-llvm -S example.transpiled.c -O0`)

What Clang produces straight from the rewritten source, before any
optimization:

```llvm
%struct.qint_mid_t = type { i32 }

declare %struct.qint_mid_t @cq_init_i32(i32)
declare i32 @cq_measure_i32(%struct.qint_mid_t)

define i32 @main() {
entry:
  %a        = alloca %struct.qint_mid_t
  %b        = alloca %struct.qint_mid_t
  %c        = alloca %struct.qint_mid_t
  %measured = alloca i32

  ; quantum int a = 3;
  %a_cast = bitcast %struct.qint_mid_t* %a to i8*
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %a_cast)
  %a_init = call %struct.qint_mid_t @cq_init_i32(i32 3)
  store %struct.qint_mid_t %a_init, %struct.qint_mid_t* %a

  ; quantum int b = 5;
  %b_cast = bitcast %struct.qint_mid_t* %b to i8*
  call void @llvm.lifetime.start.p0i8(i64 4, i8* %b_cast)
  %b_init = call %struct.qint_mid_t @cq_init_i32(i32 5)
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
  %m        = call i32 @cq_measure_i32(%struct.qint_mid_t %c_load)
  store i32 %m, i32* %measured

  ; --- scope ends; Clang inserts lifetime.ends ---
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %c_cast)
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %b_cast)
  call void @llvm.lifetime.end.p0i8(i64 4, i8* %a_cast)

  %retval = load i32, i32* %measured
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

declare %struct.qint_mid_t @cq_init_i32(i32)
declare i32 @cq_measure_i32(%struct.qint_mid_t)

define i32 @main() {
  %a_struct = call %struct.qint_mid_t @cq_init_i32(i32 3)
  %a        = extractvalue %struct.qint_mid_t %a_struct, 0

  %b_struct = call %struct.qint_mid_t @cq_init_i32(i32 5)
  %b        = extractvalue %struct.qint_mid_t %b_struct, 0

  %c        = add i32 %a, %b                                  ; ← STOCK LLVM PRIMITIVE
  %c_struct = insertvalue %struct.qint_mid_t poison, i32 %c, 0

  %m        = call i32 @cq_measure_i32(%struct.qint_mid_t %c_struct)
  ret i32 %m
}
```

The `alloca`s, `load`s, `store`s, and lifetime markers have collapsed —
`mem2reg` and `sroa` see through the single-field wrapper. What's left
is a clean SSA chain:

```
@cq_init_i32(3) ─▶ %a_struct ─▶ %a ──┐
                                     ├─▶ %c ─▶ %c_struct ─▶ %m ─▶ ret
@cq_init_i32(5) ─▶ %b_struct ─▶ %b ──┘
                                           @cq_measure_i32
```

---

## Taint analysis on this IR

This is the first analysis the CQ IR pass runs (§7.1 of the architecture
doc). Trace through the values:

| SSA value | Tainted? | Why |
|---|---|---|
| `%a_struct` | **yes** | return of `@cq_init_i32` (taint source) |
| `%a` | **yes** | `extractvalue` of a tainted aggregate |
| `%b_struct` | **yes** | return of `@cq_init_i32` |
| `%b` | **yes** | `extractvalue` of a tainted aggregate |
| `%c` | **yes** | `add i32` with at least one tainted operand |
| `%c_struct` | **yes** | `insertvalue` carrying a tainted scalar |
| `%m` | **classical** | `@cq_measure_i32` is a taint sink; its `i32` is classical |

So the IR pass classifies `%c = add i32 %a, %b` as a **quantum add**.
(`%m` is also the return value — no `trunc` is needed since
`cq_measure_i32` already returns `i32`.)
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

1. Replace `@cq_init_i32(3)` with `cqrt_alloc_classical_i32(3)` —
   allocate a 32-qubit register handle and initialize with the
   classical value 3.
2. Replace the tainted `add i32 %a, %b` with the chosen reversible-adder
   template: a sequence of `cqrt_cnot` and `cqrt_toffoli` calls
   threading through ancilla and result qubit handles.
3. Replace `@cq_measure_i32(...)` with `cqrt_measure_i32(handle)`.
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
