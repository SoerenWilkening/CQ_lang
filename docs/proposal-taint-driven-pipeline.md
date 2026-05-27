# Proposal — Taint-Driven Pipeline (No `quantum` Keyword)

A proposal to simplify the CQ pipeline by removing the `quantum` keyword,
the AST transpiler, and cast-as-measurement. Replaces them with explicit
`cq_theta()`/`cq_measure()` primitives and purely taint-driven lowering.

This document walks a minimal program through each stage of the proposed
pipeline, matching the format of [`example.md`](./example.md) for direct
comparison. Intended as a discussion base — not a committed design.

---

## Motivation

Three problems with the current `quantum`-keyword design:

1. **Function lifting breaks — hidden casts trigger unwanted measurements.**
   A core goal of CQ is to turn any classical function into a quantum
   function by passing quantum arguments. Under cast-as-measurement, a
   type cast like `(int) x` inside a function body triggers measurement.
   The problem: the caller cannot see what casts exist inside the function.

   Example — a classical utility function with an internal cast:

   ```c
   double average(double a, double b) {
       int count = 2;
       return (a + b) / (double) count;   /* (double) cast — harmless classically */
   }
   ```

   Called as `average(q1, q2)` where `q1` and `q2` are tainted: this
   should compute a quantum average. But `count` inherits taint (it
   participates in arithmetic with tainted values), and the `(double)`
   cast on the tainted `count` would trigger a measurement under
   cast-as-measurement — collapsing the quantum state mid-computation.

   The caller has no way to know this will happen. The cast is an
   internal implementation detail of `average()`. A different
   implementation of the same function might not have the cast and would
   work fine. This makes function lifting unpredictable: whether a
   classical function survives quantum lifting depends on its internal
   casting patterns, which are invisible to the caller.

2. **Type conversion ≠ measurement.** A quantum int and a classical int
   have the same bit representation. Type conversion adjusts
   representation (int→float, widen/narrow), not physical substrate.
   Cast-as-measurement conflates two unrelated operations.

   The `(double) count` cast in the example above is just a
   representation change — converting an integer bit pattern to a
   floating-point bit pattern. In the quantum case this means mapping
   qubits from an integer register onto a floating-point register. No
   measurement is involved; the superposition is preserved. Cast-as-
   measurement turns this routine operation into a destructive one for
   no physical reason.

3. **`quantum` is not a type — it is a taint.** A tainted `int` and a
   declared `quantum int` behave identically once tainted. And undeclared
   variables inherit taint through data flow regardless of their
   declaration:

   ```c
   quantum int a;       /* declared quantum */
   // ... a enters superposition ...
   int b = a + 1;       /* b is tainted — without quantum declaration */
   ```

   The keyword doesn't enforce a containment boundary. It is either
   unenforced (decorative) or, if enforced, breaks function lifting.

### Design principle

Quantum does not introduce new data types. A quantum int *is* an int —
one whose bits happen to live on qubits. The compiler treats them
identically until a branching gate (Ry) is applied; from that point
the variable is tainted and operations on it are lowered to quantum
templates. This is the same taint-propagation mechanism the current IR
pass already implements — the proposal simply removes the redundant
source-level ceremony around it.

---

## Design decisions

| Decision | Current | Proposed |
|---|---|---|
| Measurement | Implicit via type cast: `(int) q` | Explicit: `cq_measure(q)` |
| Quantum declaration | `quantum int a = 3;` | `int a = 3;` (plain C) |
| Taint introduction | `cq_init_*` at declaration | `cq_theta()` at first Ry gate |
| Type conversion on quantum values | Triggers measurement | Does what it does classically |
| Transpiler (AST rewriter) | Required | **Eliminated** |
| Mid-level types (`qint_mid_t` etc.) | 14 struct types + 28 intrinsics | **Eliminated** |
| `quantum` keyword | `#define quantum __attribute__((annotate("quantum")))` | **Eliminated** |

---

## Pipeline overview

**Proposed (3 stages):**

```
Source (.c — plain C with cq_theta/cq_phi/cq_measure primitives)
  → Stage 1: Clang -O1 -emit-llvm      (standard compilation — no rewriter)
  → Stage 2: CQ IR Pass                 (taint from cq_theta, alloc, lower opcodes)
  → Stage 3: Link against libcq_runtime (gate-emission stubs)
```

**Current (4 stages):**

```
Source (.c with quantum keyword)
  → Stage 1: AST Rewriter               ← ELIMINATED
  → Stage 2: Clang -O1 -emit-llvm
  → Stage 3: CQ IR Pass
  → Stage 4: Link
```

---

## Quantum primitives

Only two user-facing gate families, plus measurement:

| Primitive | Gate | Taint behavior | Purpose |
|---|---|---|---|
| `cq_theta(x, angle)` | Ry | **Taint source** — return value is tainted | Creates superposition (branching gate) |
| `cq_phi(x, angle)` | Rz | Propagates existing taint, but does **not** introduce new taint | Phase rotation (non-branching) |
| `cq_measure(x)` | Measurement | **Taint sink** — return value is classical | Collapses quantum state |

`cq_theta` (Ry) is the *only* taint-introducing operation. `cq_phi` (Rz)
does not create superposition — if applied to a non-tainted value, it is
physically a no-op. If applied to an already-tainted value, it is lowered
to a gate call but does not change taint status.

---

## What this example exercises

- A variable starting as classical, then becoming tainted via `cq_theta`
- Taint propagation through a mixed Q+C addition
- Explicit measurement via `cq_measure`
- SSA natural splitting of classical vs. quantum lifetimes (no IR-pass
  splitting logic needed)

What this example does **not** exercise (deferred to future proposals):

- `cq_phi` (Rz) applied to an already-tainted variable
- Function lifting (classical function called with tainted argument)
- Quantum control flow, loops, uncomputation

---

## Stage 1 — CQ source

```c
/* example.c */

#include <CQ.h>

int main(void) {
    int a = 3;
    int b = 5;

    a = cq_theta(a, 0.5);            /* Ry(0.5) — a enters superposition */

    int c = a + b;                    /* taint propagates: c is quantum   */

    int result = cq_measure(c);       /* explicit measurement             */

    return result;
}
```

This is what the user writes. **Plain C.** No `quantum` keyword, no
special types, no cast-to-measure idiom. The only quantum-specific
elements are the `cq_theta` and `cq_measure` function calls, declared in
`CQ.h`.

Compare with the current surface (`example.md` §Stage 1):

```c
/* current — requires quantum keyword + cast-as-measure */
quantum int a = 3;
quantum int c = a + b;
int measured = (int) c;
```

```c
/* proposed — plain C + explicit primitives */
int a = 3;
a = cq_theta(a, 0.5);
int c = a + b;
int result = cq_measure(c);
```

The proposed surface adds the `cq_theta` call (which the current surface
would also need eventually — rotations are a fundamental quantum
operation), and replaces the implicit cast with an explicit `cq_measure`.

---

### `CQ.h` — user-facing header

```c
/* CQ.h — complete user-facing surface */

/* Ry gate — creates superposition (taint source)
   Returns the (now-quantum) value. */
int      cq_theta_i32(int x, double angle);
float    cq_theta_f32(float x, double angle);
double   cq_theta_f64(double x, double angle);
/* ... per-width variants for all C scalar types */

/* Rz gate — phase rotation (NOT a taint source)
   If x is already tainted, emits gate. If classical, no-op. */
int      cq_phi_i32(int x, double angle);
float    cq_phi_f32(float x, double angle);
double   cq_phi_f64(double x, double angle);
/* ... per-width variants */

/* Measurement — collapses to classical value (taint sink) */
int      cq_measure_i32(int x);
float    cq_measure_f32(float x);
double   cq_measure_f64(double x);
/* ... per-width variants */

/* Convenience macros — C11 _Generic dispatch by type */
#define cq_theta(x, angle) _Generic((x),   \
    int:    cq_theta_i32,                   \
    float:  cq_theta_f32,                   \
    double: cq_theta_f64                    \
)(x, angle)

#define cq_phi(x, angle) _Generic((x),     \
    int:    cq_phi_i32,                     \
    float:  cq_phi_f32,                     \
    double: cq_phi_f64                      \
)(x, angle)

#define cq_measure(x) _Generic((x),        \
    int:    cq_measure_i32,                 \
    float:  cq_measure_f32,                 \
    double: cq_measure_f64                  \
)(x)
```

**There is no transpiler step.** This header is all the user includes.
The source goes directly to Clang.

---

## Stage 2 — LLVM IR after Clang `-O1`

This is what the **CQ IR pass receives** as input. After `mem2reg`:

```llvm
declare i32 @cq_theta_i32(i32, double)
declare i32 @cq_measure_i32(i32)

define i32 @main() {
  %a1 = call i32 @cq_theta_i32(i32 3, double 5.000000e-01)   ; ← taint source
  %c  = add i32 %a1, 5                                        ; ← stock LLVM add
  %m  = call i32 @cq_measure_i32(i32 %c)                      ; ← taint sink
  ret i32 %m
}
```

Key observations:

1. **No mid-structs.** No `%struct.qint_mid_t`, no `extractvalue`,
   no `insertvalue`. Variables are plain `i32` throughout. Compare with
   `example.md` §Stage 4, where the IR contains struct wrapping/unwrapping
   that `MidHandleRebind` must later undo.

2. **SSA naturally splits classical and quantum lifetimes.** The classical
   value `3` flows into `@cq_theta_i32` as an argument; the return value
   `%a1` is a new SSA value — the tainted one. The IR pass seeds taint
   at `%a1` and propagates forward. No special logic needed to determine
   "where did this variable become quantum."

3. **Constants inlined.** Clang's `-O1` inlines `a = 3` and `b = 5`
   directly into the call and add. In more complex examples the values
   would remain as separate SSA values; the taint analysis is unchanged.

4. **`%c = add i32 %a1, 5`** — stock LLVM instruction, exactly as in the
   current pipeline. The taint analysis classifies it as a Q+C mixed
   operation (one tainted operand, one classical literal).

SSA chain:

```
3 ─▶ @cq_theta_i32(·, 0.5) ─▶ %a1 ──┐
                                       ├─▶ %c ─▶ @cq_measure_i32 ─▶ %m ─▶ ret
5 ──────────────────────────────────────┘
```

---

## Taint analysis on this IR

| SSA value | Tainted? | Why |
|---|---|---|
| `3` (literal) | no | classical constant |
| `5` (literal) | no | classical constant |
| `%a1` | **yes** | return value of `@cq_theta_i32` (taint source) |
| `%c` | **yes** | `add i32` with tainted operand `%a1` (Q+C mixed) |
| `%m` | **classical** | `@cq_measure_i32` is a taint sink |

Same propagation rules as the current pipeline. The only difference is
the seed: `@cq_theta_i32` return instead of `@cq_init_i32` return.

---

## What the IR pass does (lowering)

The IR pass performs these steps — note that **MidHandleRebind is gone**:

### Step 1 — Seed taint

Scan for `@cq_theta_*` calls. Their return values are taint sources.
(Also scan `@cq_phi_*` — these propagate existing taint but do not
seed new taint.)

### Step 2 — Insert allocation (new)

For each `@cq_theta_*` call, the input operand is a classical value that
must be loaded onto a qubit register. Insert `cqrt_alloc_<W>` before
the theta call:

```llvm
; before:
%a1 = call i32 @cq_theta_i32(i32 3, double 0.5)

; after:
%h_a = call i32 @cqrt_alloc_i32(i32 3)          ; allocate + init qubits
call void @cqrt_ry_i32(i32 %h_a, double 0.5)    ; apply Ry gate
; %h_a is now the tainted handle
```

This replaces the current pipeline's allocation at declaration time
(`cq_init_*` → `cqrt_alloc_*` in `MidHandleRebind`). The key difference:
**allocation is gate-triggered, not declaration-triggered.** A variable
that is never rotated is never allocated.

### Step 3 — Forward taint propagation

Same mechanism as current pipeline (`TaintPropagation.cpp`). Seeds are
the handle values from Step 2. Propagation and sink rules unchanged.

### Step 4 — Opcode lowering

Same as current pipeline (`OpcodeLowering.cpp`). Tainted `add i32` →
`cq_template_add_i32`. Mixed Q+C → `_hl` variant. All ~38 opcodes
handled identically.

### Step 5 — Measure lowering

`@cq_measure_i32(%c)` → `@cqrt_measure_i32(%h_c)`. Same as current.

### Step 6 — Cleanup

Remove `@cq_theta_*`, `@cq_phi_*`, `@cq_measure_*` declarations with
no remaining call sites.

---

## Lowered IR (sketch)

```llvm
define i32 @main() {
  %h_a = call i32 @cqrt_alloc_i32(i32 3)              ; allocate qubit register
  call void @cqrt_ry_i32(i32 %h_a, double 5.0e-01)    ; Ry(0.5)

  %h_c = call i32 @cq_template_add_i32_hl(i32 %h_a, i32 5)   ; Q+C add

  %m   = call i32 @cqrt_measure_i32(i32 %h_c)         ; measure
  ret i32 %m
}
```

No `@cq_*` intrinsics remain — only `cqrt_*` runtime calls and
`cq_template_*` stubs. Same output shape as the current pipeline.

---

## Function lifting — the motivating case

The primary advantage: classical functions work with tainted arguments
**without modification**.

```c
/* ipow.c — standard classical function, no quantum awareness */
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
    x = cq_theta(x, 0.3);              /* x is tainted */
    int y = ipow(x, 3);                /* taint flows into ipow */
    int out = cq_measure(y);           /* measure result */
    return out;
}
```

Under the **current** design, `ipow` would need `quantum int` declarations
for every variable that touches the tainted input — or a transpiler-level
specialization pass. Under the **proposed** design, the IR pass sees
tainted `%x` flow into `ipow`, and every operation inside `ipow` that
touches `%x` (or values derived from it) is rewritten to quantum
templates. No source changes needed.

**Constraint:** this requires the IR for `ipow` to be visible at pass
time. The CQ driver compiles all source to LLVM IR; linking IR modules
before the CQ pass (LTO-style) is a natural extension. Standard library
functions (e.g., from `math.h`) are also available as LLVM bitcode —
the IR pass rewrites their opcodes the same way.

---

## Impact on current implementation

### Eliminated

| Component | Files | ~LOC | Reason |
|---|---|---|---|
| AST Rewriter | `transpiler/src/*.cpp` | 1500 | No `quantum` keyword to rewrite |
| Mid-level types | `include/cq_mid.h` | 500 | No struct wrappers needed |
| `MidHandleRebind` | `ir-pass/src/MidHandleRebind.cpp` | 160 | No mid-structs to unwrap |
| Cast-as-measurement | `transpiler/src/CastRewrite.cpp` | 200 | Replaced by explicit `cq_measure` |
| `cq_init_*` intrinsics | 28 symbols across headers + runtime | — | Replaced by gate-triggered alloc |
| `quantum` macro | `include/CQ.h` | — | Removed |
| Phase 3 CastRewrite patterns | `transpiler/src/CastRewrite.cpp` | — | Casts are just casts now |

### Modified

| Component | Change |
|---|---|
| `TaintPropagation.cpp` | Seed from `@cq_theta_*` returns instead of `@cq_init_*` |
| `CQLoweringPass.cpp` | Add allocation-insertion step; remove `MidHandleRebind` call |
| `CQ.h` | Replace `quantum` macro with primitive declarations |
| `cqc` driver | Remove transpiler invocation |
| `WidthDispatch` | Map `cq_theta_*`/`cq_phi_*` names to widths (same mechanism) |
| Phase 3 opcode table | Cast opcodes (sext, zext, trunc, etc.) are always representation changes, never measurement |

### Preserved

| Component | Why unchanged |
|---|---|
| Forward taint propagation (mechanism) | Same algorithm, different seed |
| Opcode lowering + template dispatch | Operates on tainted stock LLVM opcodes — no change |
| Width dispatch | Same width mapping, different intrinsic names |
| Measure lowering | `cq_measure_*` → `cqrt_measure_*` (same pattern) |
| Runtime ABI (`cqrt_alloc_*`, `cqrt_measure_*`, templates) | Unchanged |
| Template library (stubs + future backends) | Unchanged |

---

## `cq_phi` (Rz) — non-branching gate

`cq_phi` does not create superposition. Its taint behavior:

- **Applied to a tainted value:** the gate is lowered to `@cqrt_rz_<W>`.
  The output remains tainted (taint propagates through).
- **Applied to a non-tainted value:** physically a no-op (Rz on a
  computational basis state adds only global phase). The IR pass can
  silently remove it or emit a diagnostic.

Example:

```c
int a = 3;
a = cq_theta(a, 0.5);    /* a is now tainted */
a = cq_phi(a, 1.0);      /* Rz(1.0) applied to tainted a — emits gate */

int b = 7;
b = cq_phi(b, 1.0);      /* b is NOT tainted — no-op, removed by IR pass */
```

---

## Open questions

1. **Return-value vs. pointer syntax.** This proposal uses the return-value
   form `a = cq_theta(a, 0.5)` which preserves clean SSA. The pointer form
   `cq_theta(&a, 0.5)` is more natural for an "in-place gate" mental model
   but prevents `mem2reg` promotion and complicates taint propagation.
   **Recommendation:** return-value form.

2. **Syntactic sugar.** The original whiteboard syntax was `theta(a) + k;`.
   This cannot be a plain C function call (the `+ k` is separated from the
   arguments). If desired, it would require a minimal preprocessor or
   macro. Worth deferring — function-call syntax works and avoids any
   transpiler dependency.

3. **Diagnostics / taint tracing.** Without the `quantum` keyword as an
   explicit marker, taint errors (e.g., "cannot pass tainted value to
   `printf`") need a trace: "tainted because of `cq_theta(y)` on line 17,
   which propagated through `z = x + 1` on line 22." Standard compiler
   diagnostic infrastructure can support this.

4. **`cq_phi` on classical values.** Silently remove, or warn? A warning
   could catch programmer intent errors ("you applied Rz but never applied
   Ry — the phase has no observable effect").

5. **Phase 3 in-progress work.** Opcode lowering itself is unchanged. But
   cast-rewrite patterns become pure representation changes. How much of
   the Phase 3 implementation can be preserved vs. needs rework?

---

## Compilation flow

```bash
# Proposed (3 stages):
clang -O1 -emit-llvm -include CQ.h example.c -o example.bc      # Stage 1
opt -load-pass-plugin libCQPass.so -passes=cq-lowering \
    example.bc -o example.lowered.bc                              # Stage 2
clang example.lowered.bc -lcq_templates -lcq_runtime -o example  # Stage 3
./example                                                          # emits circuit

# Current (4 stages):
quantum_transpiler example.c > example.transpiled.c               # ← eliminated
clang -O1 -emit-llvm -include cq_mid.h example.transpiled.c ...
opt -load-pass-plugin libCQPass.so ...
clang example.lowered.bc -lcq_templates -lcq_runtime -o example
```

---

## Cross-references

- Current worked example: [`example.md`](./example.md)
- Architecture (current): [`architecture.md`](./architecture.md), §§3–7
- Roadmap: [`ROADMAP.md`](../ROADMAP.md)
- Pipeline sketch: [`pipeline-sketch.md`](./pipeline-sketch.md)
- Taint propagation design: [`architecture.md`](./architecture.md) §7.1
