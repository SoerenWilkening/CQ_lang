# Worked Example — Pipeline End-to-End Under the Taint-Driven Design

A minimal program walked through each stage of the new CQ pipeline:
plain C source with `cq_*` primitives, then raw LLVM IR out of Clang,
then the post-`-O1` IR the pass actually receives, then the lowered IR
after the pass has run.

Read alongside:

- [`frontend.md`](./frontend.md) — the user-facing intrinsic surface
  that defines the calls (`cq_theta`, `cq_phi`, `cq_measure`,
  `cq_invert_*`) and the three-stage compilation flow
- [`backend.md`](./backend.md) — the IR pass that performs taint
  analysis, allocation, opcode lowering, and the runtime ABI the
  lowered IR calls into
- [`quantum-classical-handling.md`](./quantum-classical-handling.md) —
  the Q/C boundary mechanism (taint), mixed-operand semantics, and the
  function-lifting fix that motivated the redesign
- [`rationale/proposal-taint-driven-pipeline.md`](./rationale/proposal-taint-driven-pipeline.md)
  — the staged walkthrough this example mirrors, with the original
  motivation for the design

---

## What this example exercises

- A plain `int` declaration that stays classical (allocation-free)
- A second `int` promoted to a quantum register by `cq_theta` (the only
  taint source)
- Forward taint propagation through a mixed-operand binary `add`
  (H+C → `_hl` template)
- Explicit measurement via `cq_measure` as the sole taint sink
- The end-to-end shape of the lowered IR — no `@cq_*` calls remain,
  only `cqrt_*` and `cq_template_*`

What this example does **not** exercise (deferred to future walkthroughs;
mechanism described in the cited sections of the other docs):

- `cq_phi` (Rz) on a tainted operand
  ([`backend.md`](./backend.md) §6)
- Chained `cq_theta` on an already-tainted handle
  ([`backend.md`](./backend.md) §5.1)
- Quantum control flow — tainted `br i1`, post-dominator-driven
  controlled-form lowering
  ([`backend.md`](./backend.md) §8)
- Function lifting — curated symbol substitution and clone-on-taint
  ([`backend.md`](./backend.md) §7)
- Manual inversion via `cq_invert_begin` / `cq_invert_end`
  ([`frontend.md`](./frontend.md) §3.5, [`backend.md`](./backend.md) §10)
- Per-op auto-uncomputation — suppressed here because the enclosing
  function is `main`, per [`backend.md`](./backend.md) §9.3

---

## Stage 1 — CQ source

```c
/* example.c */

#include <CQ.h>

int main(void) {
    int a = 3;
    int b = 5;

    a = cq_theta(a, 0.5);            /* Ry(0.5) — a enters superposition  */

    int c = a + b;                    /* taint propagates: c is quantum    */

    int result = cq_measure(c);       /* explicit measurement              */

    return result;
}
```

This is what the user writes. **Plain C** — no `quantum` keyword, no
struct wrapper, no cast-to-measure idiom. The only CQ-specific
elements are the `cq_theta` and `cq_measure` call sites, both
declared in `CQ.h`.

Compare against the old surface for the same example (archived at
[`archive/old-design/example.md`](./archive/old-design/example.md)):

```c
/* old design — required quantum keyword and cast-as-measurement */
quantum int a = 3;
quantum int c = a + b;
int measured = (int) c;
```

```c
/* new design — plain C plus explicit primitives */
int a = 3;
a = cq_theta(a, 0.5);
int c = a + b;
int result = cq_measure(c);
```

The new surface adds an explicit `cq_theta` (the Ry rotation that
physically introduces superposition — the prior design would have
needed this eventually too) and replaces the implicit measurement-on-
cast with an explicit `cq_measure` call. The `quantum` keyword and
the `qint_mid_t` wrapper struct are gone; `a`, `b`, `c`, and `result`
are plain `int` throughout, distinguished only by whether the SSA
value carries taint at the IR layer.

### `CQ.h` — what gets included

`CQ.h` declares the four primitive families described in
[`frontend.md`](./frontend.md) §3 — `cq_theta`, `cq_phi`, `cq_measure`
(each fanned out across the 14 standard C scalar types), plus
`cq_invert_begin` / `cq_invert_end`. The example uses only the `int`
specializations:

```c
/* CQ.h excerpt — the calls this example needs */
int cq_theta_si32  (int x, double angle);   /* Ry — taint source */
int cq_measure_si32(int x);                  /* measurement — taint sink */

#define cq_theta(x, angle) _Generic((x), int: cq_theta_si32 /* + 13 more */)(x, angle)
#define cq_measure(x)      _Generic((x), int: cq_measure_si32 /* + 13 more */)(x)
```

There is no transpiler step. The source goes straight to Clang.

---

## Stage 2 — Raw LLVM IR (`clang -O0 -emit-llvm`)

Before any optimization passes have run. Shown for orientation only;
the CQ IR pass operates on the `-O1` cleanup of this (see Stage 3
below).

```llvm
declare i32 @cq_theta_si32  (i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %a      = alloca i32
  %b      = alloca i32
  %c      = alloca i32
  %result = alloca i32

  store i32 3, i32* %a
  store i32 5, i32* %b

  ; a = cq_theta(a, 0.5);
  %a_load1 = load i32, i32* %a
  %a_theta = call i32 @cq_theta_si32(i32 %a_load1, double 5.0e-01)
  store i32 %a_theta, i32* %a

  ; int c = a + b;
  %a_load2 = load i32, i32* %a
  %b_load  = load i32, i32* %b
  %sum     = add i32 %a_load2, %b_load
  store i32 %sum, i32* %c

  ; int result = cq_measure(c);
  %c_load  = load i32, i32* %c
  %m       = call i32 @cq_measure_si32(i32 %c_load)
  store i32 %m, i32* %result

  %r_load  = load i32, i32* %result
  ret i32 %r_load
}
```

Notice what is *not* here: no `%struct.qint_mid_t`, no
`extractvalue`/`insertvalue` chains, no `@cq_init_*` calls. Variables
are plain `i32` slots; the taint-relevant calls (`@cq_theta_si32`,
`@cq_measure_si32`) are visible as ordinary external calls.

---

## Stage 3 — LLVM IR after Clang `-O1`

This is what the **CQ IR pass actually receives** as input. After
`mem2reg` and `SROA` collapse the `alloca`/`load`/`store` traffic and
constant-fold the literals:

```llvm
declare i32 @cq_theta_si32  (i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %a1 = call i32 @cq_theta_si32(i32 3, double 5.0e-01)   ; ← taint source
  %c  = add i32 %a1, 5                                   ; ← stock LLVM add
  %m  = call i32 @cq_measure_si32(i32 %c)                ; ← taint sink
  ret i32 %m
}
```

Four observations:

1. **Plain SSA throughout.** No struct wrappers, no
   `extractvalue`/`insertvalue` work the pass has to undo. The IR pass
   reads taint directly off the SSA def-use graph.
2. **`b` has been folded away.** The classical constant `5` is inlined
   directly into the add. In a less trivial program `b` would survive
   as its own SSA value — the taint analysis is unchanged either way.
3. **`%c = add i32 %a1, 5`** is a stock LLVM `add` instruction. There
   is no `@cq_add` intrinsic. The pass will classify it as quantum
   purely from its operands' taint state.
4. **`%a` was reassigned in the source** (`a = cq_theta(a, 0.5)`); SSA
   handles this by renaming — the pre-rotation classical value is the
   `i32 3` literal, the post-rotation tainted value is `%a1`. No
   pre-existing taint signal needs to flow across the rebinding; the
   `@cq_theta_si32` return *is* the source.

SSA chain:

```
3 ─▶ @cq_theta_si32(·, 0.5) ─▶ %a1 ──┐
                                     ├─▶ %c ─▶ @cq_measure_si32 ─▶ %m ─▶ ret
5 ───────────────────────────────────┘
```

This is the input contract the backend expects, as documented in
[`backend.md`](./backend.md) §3.

---

## Taint analysis on this IR

The first thing the pass does. Per [`backend.md`](./backend.md) §4,
the operand rule is monotone, forward, single-sweep over the SSA DAG:

| SSA value | Tainted? | Why |
|---|---|---|
| `i32 3` (literal) | no | classical constant |
| `i32 5` (literal) | no | classical constant |
| `%a1` | **yes** | return value of `@cq_theta_si32` — taint **source** |
| `%c` | **yes** | `add i32` whose LHS `%a1` is tainted (Q+C mixed) |
| `%m` | classical | return of `@cq_measure_si32` — taint **sink** |

A few things to read from this table:

- The single source of taint in the whole program is the `@cq_theta`
  return. Per [`quantum-classical-handling.md`](./quantum-classical-handling.md)
  §4.1, this is the only way to mint quantum behavior anywhere in the
  pipeline.
- `%c` carries taint despite having one classical operand. Operand
  rule: *any* tainted operand suffices. The classification is
  independent of which side of the binary op the taint sits on; the
  H+C shape is what determines the lowering template, not the
  classification.
- `%m` is hard-classical. Downstream uses of `%m` — here, just the
  `ret i32` — are plain classical SSA. No subsequent operation can
  re-promote it without flowing through a fresh `cq_theta`.

---

## Stage 4 — What the IR pass emits

The pass walks the analysis above and, per
[`backend.md`](./backend.md) §§5–6, rewrites each tainted construct in
place. The steps relevant to this example:

### Step 1 — Allocation lowering at the `cq_theta` site

Per [`backend.md`](./backend.md) §5.1, dispatch on the theta operand's
taint state. Here the operand `i32 3` is a classical literal, so the
classical-operand branch fires:

```llvm
; before
%a1 = call i32 @cq_theta_si32(i32 3, double 5.0e-01)

; after
%h_a = call i32 @cqrt_alloc_i32(i32 3)            ; allocate, init to 3
call void @cqrt_ry_i32(i32 %h_a, double 5.0e-01)  ; Ry(0.5) on the register
; every downstream use of %a1 is replaced by %h_a (the new handle)
```

The runtime ABI is width-only (`cqrt_alloc_i32`, not `cqrt_alloc_si32`)
— signedness drops out at the IR-pass / runtime boundary per
[`backend.md`](./backend.md) §6.4.

### Step 2 — Opcode lowering for the tainted `add`

`%c = add i32 %a1, 5` has one tainted handle and one classical
literal — H+C shape. Per [`backend.md`](./backend.md) §6.2 and
[`quantum-classical-handling.md`](./quantum-classical-handling.md) §5,
the classical operand must **not** be promoted to a handle; the pass
emits the `_hl` variant:

```llvm
; before
%c = add i32 %h_a, 5

; after
%h_c = call i32 @cq_template_add_i32_hl(i32 %h_a, i32 5)
; downstream uses of %c → %h_c
```

The literal `5` flows through the ABI as a value, not as a synthetic
qubit register. This preserves the optimization headroom for future
`cqrt_alloc` elision (§5.2 of
[`quantum-classical-handling.md`](./quantum-classical-handling.md)).

### Step 3 — Measure lowering

`@cq_measure_si32(%h_c)` lowers to the width-only runtime entry point:

```llvm
; before
%m = call i32 @cq_measure_si32(i32 %h_c)

; after
%m = call i32 @cqrt_measure_i32(i32 %h_c)
```

The handle `%h_c` is **not** consumed by the measure — the register
persists in a classical eigenstate after the call per
[`frontend.md`](./frontend.md) §3.4. The `%m` return is classical;
its only use here is the `ret i32`.

### Step 4 — Uncomputation? Not in `main`

The escape rule in [`backend.md`](./backend.md) §9.3 suppresses
auto-uncomputation when the enclosing function is `main` — there is
no caller responsible for downstream cleanup, so no `cqrt_free` is
emitted. In a regular callee, `%h_c` (and `%h_a`) would have their
adjoints emitted at the post-dominator of their last uses. This
example skips that machinery entirely.

### The fully lowered IR

```llvm
define i32 @main() {
  %h_a = call i32 @cqrt_alloc_i32(i32 3)               ; allocate qubit register
  call void @cqrt_ry_i32(i32 %h_a, double 5.0e-01)     ; Ry(0.5)

  %h_c = call i32 @cq_template_add_i32_hl(i32 %h_a, i32 5)   ; Q+C add

  %m   = call i32 @cqrt_measure_i32(i32 %h_c)          ; measure
  ret i32 %m
}
```

No `@cq_*` intrinsic calls remain. Only `cqrt_*` runtime calls,
`cq_template_*` template calls, and stock LLVM classical IR threading
them — exactly the output contract [`backend.md`](./backend.md) §13.1
describes.

---

## Compilation flow

The three-stage flow that produced the IR above
([`frontend.md`](./frontend.md) §8, [`backend.md`](./backend.md) §13):

```bash
# Stage 1: frontend — plain Clang -O1 with CQ.h on the include path
clang -O1 -emit-llvm -include CQ.h example.c -o example.bc

# Stage 2: backend IR pass — taint propagation, allocation, opcode lowering,
# measure lowering. No uncomputation here (enclosing function is main).
opt -load-pass-plugin libCQPass.so -passes=cq-lowering \
    example.bc -o example.lowered.bc

# Stage 3: standard codegen + link against templates and one runtime variant
clang example.lowered.bc -lcq_templates -lcq_runtime -o example

./example   # emits the circuit
```

The driver `cqc` wraps this multi-step flow into a single
clang-flavored command line; for multi-file programs the cloning path
needs an `llvm-link` pre-link so callee bodies are visible to the
pass (see [`backend.md`](./backend.md) §13.2).

---

## What this walkthrough leaves to follow-up examples

| Mechanism | Documented in | Walked end-to-end here? |
|---|---|---|
| Forward taint propagation | [`backend.md`](./backend.md) §4 | yes (table above) |
| Allocation lowering on classical operand | [`backend.md`](./backend.md) §5.1 | yes (Step 1) |
| Allocation skipped on tainted operand (chained rotation) | [`backend.md`](./backend.md) §5.1 | no |
| H+C `_hl` template dispatch | [`backend.md`](./backend.md) §6.2 | yes (Step 2) |
| `cq_phi` deletion / propagation | [`backend.md`](./backend.md) §6 | no |
| Function lifting (curated symbol substitution) | [`backend.md`](./backend.md) §7.1 | no |
| Function lifting (clone-on-taint) | [`backend.md`](./backend.md) §7.2 | no |
| Controlled-form lowering for tainted branches | [`backend.md`](./backend.md) §8 | no |
| Per-op auto-uncomputation at SSA last use | [`backend.md`](./backend.md) §9 | suppressed in `main` |
| Manual inversion bracket | [`backend.md`](./backend.md) §10 | no |

A future walkthrough will pick one of these (probably function lifting
through `ipow`, mirroring the proposal's §Function-lifting example) to
demonstrate the substrate the next layer of the pipeline depends on.

---

## Cross-references

| Concern | Where |
|---|---|
| User-facing intrinsic surface (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) | [`frontend.md`](./frontend.md) §3 |
| Compilation flow, single-file and multi-file | [`frontend.md`](./frontend.md) §8 / [`backend.md`](./backend.md) §13 |
| Forward taint propagation algorithm | [`backend.md`](./backend.md) §4 |
| Allocation lowering (gate-triggered) | [`backend.md`](./backend.md) §5 |
| Opcode lowering + `_hl` mixed-operand dispatch | [`backend.md`](./backend.md) §6 |
| Why classical operands are never promoted to handles | [`quantum-classical-handling.md`](./quantum-classical-handling.md) §5.2 |
| Runtime ABI (`cqrt_alloc_<W>`, `cqrt_ry_<W>`, `cqrt_measure_<W>`) | [`backend.md`](./backend.md) §11 |
| Template library (`cq_template_<op>_<W>{,_hl}`) | [`backend.md`](./backend.md) §12 |
| Why no `quantum` keyword; why no cast-as-measurement | [`quantum-classical-handling.md`](./quantum-classical-handling.md) §3, [`rationale/proposal-taint-driven-pipeline.md`](./rationale/proposal-taint-driven-pipeline.md) |
| Same example under the prior `quantum`-keyword design | [`archive/old-design/example.md`](./archive/old-design/example.md) |
