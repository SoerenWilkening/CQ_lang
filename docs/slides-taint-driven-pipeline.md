---
marp: true
theme: default
paginate: true
title: "CQ_lang — Taint-Driven Pipeline Proposal"
---

# CQ_lang — Taint-Driven Pipeline

**Removing the `quantum` keyword, cast-as-measurement, and the transpiler**

Proposal for discussion — 2026-05-27

---

# The Original Design

Two core ideas in the current CQ pipeline:

1. **`quantum` keyword** marks variables as quantum types
   ```c
   quantum int a = 3;
   ```

2. **Cast-as-measurement** — type conversion collapses the quantum state
   ```c
   int classical_value = (int) a;   // measurement happens here
   ```

Goal: introduce as little new syntax as possible while covering all quantum algorithms.

---

# The Goal We're Building Toward

Turn **any classical function** into a quantum function by passing quantum arguments.

```c
// Classical function — written by someone else, lives in a library
double average(double a, double b) {
    int count = 2;
    return (a + b) / (double) count;
}

// Quantum call — taint flows through automatically
average(q1, q2);
```

This is **function lifting** — the foundation of CQ's approach to quantum programming.

---

# Problem 1: Hidden Casts Break Function Lifting

Look at `average()` again:

```c
double average(double a, double b) {
    int count = 2;
    return (a + b) / (double) count;
                      ^^^^^^^^
                      This cast is invisible to the caller
}
```

Called with quantum arguments `average(q1, q2)`:
- `count` becomes tainted (participates in arithmetic with tainted values)
- `(double) count` triggers **measurement** under cast-as-measurement
- The quantum state is **destroyed mid-computation**

The caller has **no way to know** this will happen.

---

# Why This Is Fatal

Whether function lifting works depends on **internal casting patterns** — invisible implementation details.

```c
// Implementation A — works fine (no casts)
double average_v1(double a, double b) {
    return (a + b) / 2.0;
}

// Implementation B — silently destroys quantum state
double average_v2(double a, double b) {
    int count = 2;
    return (a + b) / (double) count;   // hidden measurement!
}
```

Same function signature, same behavior classically — but **one survives quantum lifting and the other doesn't**.

Function lifting becomes **unpredictable**.

---

# It Gets Worse: C Is Full of Implicit Conversions

C inserts type conversions **silently** in:
- Integer promotions (`char` + `char` promotes to `int`)
- Arithmetic conversions (`int` + `double` converts the `int`)
- Function argument passing
- Return statements

```c
double pow(double base, double exp);
```

Calling `pow(q, 2)` where `q` is a tainted `int`:
- The compiler inserts **implicit** `int` -> `double` on `q`
- Under cast-as-measurement: **measurement before `pow` even starts**

---

# Problem 2: Type Conversion != Measurement

The `(double) count` cast is just a **representation change**:
- Classical: convert integer bit pattern to floating-point bit pattern
- Quantum: map qubits from integer register to floating-point register

**The superposition is preserved.** No measurement is involved.

Cast-as-measurement conflates two unrelated operations:
- Representation change (what casts actually do)
- Quantum state collapse (what measurement does)

These have nothing to do with each other.

---

# Problem 3: `quantum` Is Not a Type

Consider:

```c
quantum int a;
// ... a enters superposition ...
int b = a + 1;       // b is tainted — without quantum declaration
```

`b` inherits taint through data flow. The `quantum` keyword on `a` didn't prevent this.

The keyword either:
- **Is unenforced** — decorative, the compiler ignores it
- **Is enforced** — breaks function lifting (every internal variable in a lifted function would need `quantum`)

---

# The Key Insight

> A quantum int **is** an int.
> Its bits just happen to live on qubits.

`quantum` doesn't introduce a new data type. It marks something as **taintable**.

But anything is taintable — taint propagates through plain `int` regardless.

So why have the keyword at all?

---

# The IR Proves It: Taint Starts at the Gate, Not the Declaration

Consider what happens with `quantum int a = 3;` in the current pipeline.
The user writes:

```c
quantum int a = 3;        // declared quantum
a = a + 1;                // classical arithmetic — no gate yet
a = a * 2;                // still classical arithmetic
cq_theta(a, 0.5);         // NOW a branching gate is applied
int b = a + 5;            // b should be tainted
```

What does the IR look like **before** the CQ pass runs?

---

# IR Step 1: After Clang -O1 (Before CQ Pass)

```llvm
define i32 @main() {
  %a0 = call i32 @cq_init_i32(i32 3)      ; "quantum" allocation
  %a1 = add i32 %a0, 1                     ; a + 1
  %a2 = mul i32 %a1, 2                     ; a * 2
  %a3 = call i32 @cq_theta_i32(i32 %a2, double 5.0e-01)  ; Ry gate
  %b  = add i32 %a3, 5                     ; b = a + 5
  ...
}
```

`%a0`, `%a1`, `%a2` are all tainted because of `cq_init` — but **no quantum gate has been applied yet**. They are classical values wearing a quantum label.

---

# IR Step 2: What the CQ Pass Currently Does

The pass taints everything from `cq_init` forward:

```llvm
  %h0 = call i32 @cqrt_alloc_i32(i32 3)                  ; qubit allocation
  %h1 = call i32 @cq_template_add_i32_hl(i32 %h0, i32 1) ; QUANTUM add
  %h2 = call i32 @cq_template_mul_i32_hl(i32 %h1, i32 2) ; QUANTUM mul
  call void @cqrt_ry_i32(i32 %h2, double 5.0e-01)         ; Ry gate
  %h3 = call i32 @cq_template_add_i32_hl(i32 %h2, i32 5) ; QUANTUM add
```

`%h0 + 1` and `%h1 * 2` are lowered to **quantum templates** — but they are operating on a definite state `|3>`. These are **wasted quantum operations** doing classical work on qubits.

---

# IR Step 3: What If Taint Starts at the Gate Instead?

Move the allocation to right before `cq_theta` — the first branching operation:

```llvm
  %a1 = add i32 3, 1                                      ; classical add
  %a2 = mul i32 %a1, 2                                    ; classical mul
  %h0 = call i32 @cqrt_alloc_i32(i32 %a2)                ; allocate HERE
  call void @cqrt_ry_i32(i32 %h0, double 5.0e-01)         ; Ry gate
  %h1 = call i32 @cq_template_add_i32_hl(i32 %h0, i32 5) ; quantum add
```

`3 + 1` and `4 * 2` stay as **classical operations** — fast, no qubits needed.
Allocation happens at `%a2 = 8`, right before the gate that actually needs qubits.

---

# The Gate *Is* the Taint Boundary

```
Classical world                  Quantum world
─────────────────────────────── ──────────────────────────
int a = 3;                       |
a = a + 1;         (plain add)   |
a = a * 2;         (plain mul)   |
                                 | cq_theta(a, 0.5)  <-- allocation + Ry
                                 | b = a + 5         (quantum template)
                                 | cq_measure(b)     <-- collapse
```

The `quantum` keyword puts the boundary at **declaration**.
The gate puts the boundary at the **first branching operation**.

The gate boundary is always correct. The keyword boundary wastes qubits on classical work.

**No keyword needed — the gate tells the compiler everything.**

---

# The Solution

Replace three mechanisms with two primitives:

| Remove | Replace with |
|---|---|
| `quantum` keyword | Nothing — plain C types |
| Cast-as-measurement `(int) q` | Explicit `cq_measure(q)` |
| AST transpiler | Nothing — source is already valid C |

The only new surface:

```c
a = cq_theta(a, 0.5);           // Ry gate — creates superposition (taint source)
a = cq_phi(a, 1.0);             // Rz gate — phase rotation (not a taint source)
int result = cq_measure(a);     // Measurement — collapses to classical (taint sink)
```

---

# Before and After: User Code

**Current:**
```c
#include <CQ.h>
quantum int a = 3;
quantum int b = 5;
quantum int c = a + b;
int result = (int) c;            // cast = measurement
```

**Proposed:**
```c
#include <CQ.h>
int a = 3;
int b = 5;
a = cq_theta(a, 0.5);           // explicit gate — taint starts here
int c = a + b;                   // taint propagates
int result = cq_measure(c);     // explicit measurement
```

---

# Pipeline: 4 Stages -> 3 Stages

**Current (4 stages):**
```
Source (.c with quantum keyword)
  -> AST Rewriter         <- ELIMINATED
  -> Clang -O1 -emit-llvm
  -> CQ IR Pass
  -> Link
```

**Proposed (3 stages):**
```
Source (.c — plain C + CQ.h primitives)
  -> Clang -O1 -emit-llvm     (standard compilation)
  -> CQ IR Pass                (taint + lower)
  -> Link
```

The entire transpiler is gone. ~1500 LOC eliminated.

---

# Stage 1: Source

```c
#include <CQ.h>

int main(void) {
    int a = 3;
    int b = 5;
    a = cq_theta(a, 0.5);            // Ry(0.5) — a enters superposition
    int c = a + b;                    // taint propagates
    int result = cq_measure(c);       // explicit measurement
    return result;
}
```

Plain C. No special types. No transpiler step. Goes directly to Clang.

---

# Stage 2: LLVM IR (after Clang -O1)

```llvm
declare i32 @cq_theta_i32(i32, double)
declare i32 @cq_measure_i32(i32)

define i32 @main() {
  %a1 = call i32 @cq_theta_i32(i32 3, double 5.0e-01)  ; taint source
  %c  = add i32 %a1, 5                                   ; stock LLVM add
  %m  = call i32 @cq_measure_i32(i32 %c)                 ; taint sink
  ret i32 %m
}
```

No mid-structs. No `extractvalue`/`insertvalue`. Plain `i32` throughout.

SSA naturally splits classical (`3`) from quantum (`%a1`) lifetimes.

---

# Taint Analysis

| SSA value | Tainted? | Why |
|---|---|---|
| `3` (literal) | no | classical constant |
| `5` (literal) | no | classical constant |
| `%a1` | **yes** | return of `@cq_theta_i32` |
| `%c` | **yes** | `add` with tainted operand |
| `%m` | classical | `@cq_measure_i32` is a taint sink |

Same propagation rules as the current pipeline.
Only the seed changes: `@cq_theta_*` instead of `@cq_init_*`.

---

# Stage 3: Lowered IR (after CQ IR Pass)

```llvm
define i32 @main() {
  %h_a = call i32 @cqrt_alloc_i32(i32 3)            ; allocate qubits
  call void @cqrt_ry_i32(i32 %h_a, double 5.0e-01)  ; Ry gate

  %h_c = call i32 @cq_template_add_i32_hl(i32 %h_a, i32 5)  ; Q+C add

  %m   = call i32 @cqrt_measure_i32(i32 %h_c)       ; measure
  ret i32 %m
}
```

Same output shape as the current pipeline. Only `cqrt_*` runtime calls remain.

---

# Function Lifting Now Works

```c
int ipow(int base, int exp) {       // classical function — no changes
    int result = 1;
    for (int i = 0; i < exp; i++)
        result *= base;
    return result;
}
```

```c
int x = 2;
x = cq_theta(x, 0.3);              // x is tainted
int y = ipow(x, 3);                // taint flows through ipow
int out = cq_measure(y);           // measure result
```

The IR pass sees tainted values flow into `ipow` and rewrites its operations to quantum templates. **No source changes. No hidden measurements.**

---

# What About Internal Casts?

Under the new design, `average()` just works:

```c
double average(double a, double b) {
    int count = 2;
    return (a + b) / (double) count;
}
```

- `(double) count` is a **representation change** — lowered to a quantum `sitofp`
- No measurement triggered
- Superposition preserved throughout

The cast does in the quantum case exactly what it does classically.

---

# Impact on Implementation

**Eliminated (~2400 LOC):**
- AST Rewriter (transpiler/src/) — 1500 LOC
- Mid-level types (cq_mid.h) — 500 LOC
- MidHandleRebind pass step — 160 LOC
- Cast-as-measurement rewrite — 200 LOC

**Preserved (unchanged):**
- Forward taint propagation (same algorithm)
- Opcode lowering + template dispatch
- Runtime ABI
- Template library

---

# The Two Quantum Primitives

| Primitive | Gate | Taint | Purpose |
|---|---|---|---|
| `cq_theta(x, angle)` | Ry | **Source** | Creates superposition |
| `cq_phi(x, angle)` | Rz | Propagates only | Phase rotation |

`cq_theta` (Ry) is the **only** taint-introducing operation.

`cq_phi` (Rz) does not create superposition. Applied to a classical value, it's a no-op. Applied to a tainted value, it emits a gate.

Measurement: `cq_measure(x)` — explicit, always.

---

# Open Questions

1. **Return-value vs. pointer syntax**
   `a = cq_theta(a, 0.5)` (clean SSA) vs. `cq_theta(&a, 0.5)` (in-place)

2. **Syntactic sugar**
   Original whiteboard syntax `theta(a) + k;` needs a preprocessor — defer?

3. **Diagnostics**
   How to trace taint back to its source in error messages?

4. **`cq_phi` on classical values**
   Silently remove, or warn the programmer?

---

# Summary

| | Current | Proposed |
|---|---|---|
| Keyword | `quantum int` | `int` (plain C) |
| Measurement | `(int) q` (implicit cast) | `cq_measure(q)` (explicit) |
| Transpiler | Required (AST rewrite) | Eliminated |
| Pipeline stages | 4 | 3 |
| Function lifting | Breaks on internal casts | Works — casts are just casts |
| Taint source | Declaration (`cq_init`) | Gate application (`cq_theta`) |

**Core principle:** Quantum does not introduce new data types.
A quantum int *is* an int — one whose bits live on qubits.
