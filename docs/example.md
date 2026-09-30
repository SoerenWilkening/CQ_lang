# Worked Example — Pipeline End-to-End

A minimal program walked through the CQ pipeline in four parts: plain C
source with `cq_*` primitives, then raw LLVM IR out of Clang, then the
post-`-O1` IR the pass actually receives, then the lowered IR and the runtime
trace after the pass has run. (The "Compilation flow" section at the end uses
the pipeline's own stage numbers, Stage 1 clang, Stage 2 `cq-lowering`, Stage 3
link, as [`frontend.md`](./frontend.md) §8 does; the four parts here are a
different, finer numbering.)

Every listing below was produced by running the pipeline (LLVM 19 tools,
`build/ir-pass/cq-opt` — the same pass as `libCQPass.so` — and the trace
runtime) on the source shown; IR is trimmed to the function body and value
names are as printed. The plan of record is [`../NORTHSTAR.md`](../NORTHSTAR.md).

Read alongside:

- [`frontend.md`](./frontend.md) — the user-facing intrinsic surface
  that defines the calls (`cq_theta`, `cq_phi`, `cq_measure`,
  `cq_invert_*`) and the compilation flow
- [`backend.md`](./backend.md) — the IR pass that performs taint
  analysis, allocation, opcode lowering, and the runtime ABI the
  lowered IR calls into
- [`quantum-classical-handling.md`](./quantum-classical-handling.md) —
  the Q/C boundary mechanism (taint), mixed-operand semantics, and the
  function-lifting consequence (§7) that motivated the design

---

## What this example exercises

- A plain `int` declaration that stays classical (allocation-free)
- A second `int` promoted to a quantum register by `cq_theta` (the only
  taint source)
- Forward taint propagation through a mixed-operand binary `add`
  (quantum + classical immediate)
- Explicit measurement via `cq_measure` as the sole taint sink
- The end-to-end shape of the lowered IR — no `@cq_*` calls remain,
  only `cqrt_*` and `cq_template_*`

What this example does **not** exercise — each is walked with a real trace in
[`frontend.md`](./frontend.md):

- `cq_phi`, the branch phase (`frontend.md` §3.3)
- Function lifting — clone-on-taint (`frontend.md` §6)
- Quantum control flow — tainted `br i1` and the three arm classes
  (`frontend.md` §7)

---

## Part 1 — CQ source

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
declared in `CQ.h`. `a`, `b`, `c`, and `result` are plain `int` throughout,
distinguished only by whether the SSA value carries taint at the IR layer.

### `CQ.h` — what gets included

`CQ.h` declares the `cq_theta` and `cq_measure` families (each fanned out across
the C scalar types), the register-free `void cq_phi(double)`, the `cq_ry` macro
and the `cq_invert_begin` / `cq_invert_end` markers
([`frontend.md`](./frontend.md) §3). The example uses only the `int`
specializations:

```c
/* CQ.h excerpt — the calls this example needs */
int cq_theta_si32  (int x, double angle);   /* Ry — taint source */
int cq_measure_si32(int x);                  /* measurement — taint sink */

#define cq_theta(x, angle) _Generic((x), int: cq_theta_si32 /* + the other types */)(x, angle)
#define cq_measure(x)      _Generic((x), int: cq_measure_si32 /* + the other types */)(x)
```

(In the real header every `cq_theta_*` declaration also carries
`__attribute__((nomerge))`, which is why the calls below carry a `#2` attribute
group; see `frontend.md` §3.1.) There is no rewriting step. The source goes
straight to Clang.

---

## Part 2 — Raw LLVM IR (`clang -O0 -emit-llvm`)

Before any optimization passes have run. Shown for orientation only:
the CQ pass does **not** accept this form. `-O0` keeps every variable in an
`alloca`, so the tainted value is stored to memory and the pass refuses with
`cq taint escape: tainted value stored to memory`. It operates on the `-O1`
cleanup of this (next part).

```llvm
define i32 @main() {
  %1 = alloca i32, align 4                 ; return slot
  %2 = alloca i32, align 4                 ; a
  %3 = alloca i32, align 4                 ; b
  %4 = alloca i32, align 4                 ; c
  %5 = alloca i32, align 4                 ; result
  store i32 0, ptr %1, align 4
  store i32 3, ptr %2, align 4
  store i32 5, ptr %3, align 4
  %6 = load i32, ptr %2, align 4
  %7 = call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #2
  store i32 %7, ptr %2, align 4
  %8 = load i32, ptr %2, align 4
  %9 = load i32, ptr %3, align 4
  %10 = add nsw i32 %8, %9
  store i32 %10, ptr %4, align 4
  %11 = load i32, ptr %4, align 4
  %12 = call i32 @cq_measure_si32(i32 noundef %11)
  store i32 %12, ptr %5, align 4
  %13 = load i32, ptr %5, align 4
  ret i32 %13
}
```

Variables are plain `i32` slots; the taint-relevant calls (`@cq_theta_si32`,
`@cq_measure_si32`) are visible as ordinary external calls.

---

## Part 3 — LLVM IR after Clang `-O1`

This is what the **CQ IR pass actually receives** as input. After
`mem2reg` and `SROA` collapse the `alloca`/`load`/`store` traffic and
constant-fold the literals:

```llvm
define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #2   ; ← taint source
  %2 = add nsw i32 %1, 5                                                            ; ← stock LLVM add
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2) #3                            ; ← taint sink
  ret i32 %3
}
```

Four observations:

1. **Plain SSA throughout.** No struct wrappers, no
   `extractvalue`/`insertvalue` work the pass has to undo. The IR pass
   reads taint directly off the SSA def-use graph.
2. **`b` has been folded away.** The classical constant `5` is inlined
   directly into the add. In a less trivial program `b` would survive
   as its own SSA value — the taint analysis is unchanged either way.
3. **`%2 = add nsw i32 %1, 5`** is a stock LLVM `add` instruction. There
   is no `@cq_add` intrinsic. The pass will classify it as quantum
   purely from its operands' taint state.
4. **`a` was reassigned in the source** (`a = cq_theta(a, 0.5)`); SSA
   handles this by renaming — the pre-rotation classical value is the
   `i32 3` literal, the post-rotation tainted value is `%1`. No
   pre-existing taint signal needs to flow across the rebinding; the
   `@cq_theta_si32` return *is* the source.

SSA chain:

```
3 ─▶ @cq_theta_si32(·, 0.5) ─▶ %1 ──┐
                                    ├─▶ %2 ─▶ @cq_measure_si32 ─▶ %3 ─▶ ret
5 ──────────────────────────────────┘
```

---

## Taint analysis on this IR

The first thing the pass does. The operand rule is monotone, forward, single-sweep
over the SSA DAG ([`backend.md`](./backend.md) §4, forward taint propagation):

| SSA value | Tainted? | Why |
|---|---|---|
| `i32 3` (literal) | no | classical constant |
| `i32 5` (literal) | no | classical constant |
| `%1` | **yes** | return value of `@cq_theta_si32` — taint **source** |
| `%2` | **yes** | `add i32` whose LHS `%1` is tainted (Q+C mixed) |
| `%3` | classical | return of `@cq_measure_si32` — taint **sink** |

A few things to read from this table:

- The single source of taint in the whole program is the `@cq_theta`
  return. This is the only way to mint quantum behavior anywhere in the
  pipeline ([`quantum-classical-handling.md`](./quantum-classical-handling.md) §4.1).
- `%2` carries taint despite having one classical operand. Operand
  rule: *any* tainted operand suffices. The classification is
  independent of which side of the binary op the taint sits on; the
  operand shape (handle + literal) is what determines the lowering, not the
  classification.
- `%3` is hard-classical. Downstream uses of `%3` — here, just the
  `ret i32` — are plain classical SSA. No subsequent operation can
  re-promote it without flowing through a fresh `cq_theta`.

---

## Part 4 — What the IR pass emits

The pass walks the analysis above and rewrites each tainted construct in
place. The steps relevant to this example:

### Step 1 — Allocation lowering at the `cq_theta` site

Dispatch on the theta operand's taint state. Here the operand `i32 3` is a
classical literal, so the classical-operand branch fires:

```llvm
; before
%1 = tail call i32 @cq_theta_si32(i32 3, double 5.0e-01)

; after
%h = call i32 @cqrt_alloc_i32(i32 3)              ; allocate, init to 3
call void @cqrt_ry_i32(i32 %h, double 5.0e-01)    ; Ry(0.5) on the register
; every downstream use of %1 is replaced by %h (the new handle)
```

The runtime ABI is width-only (`cqrt_alloc_i32`, not `cqrt_alloc_si32`)
— signedness drops out at the IR-pass / runtime boundary. A handle is always an
`i32`.

### Step 2 — Opcode lowering for the tainted `add`

`%2 = add nsw i32 %1, 5` has one tainted handle and one classical
literal. The classical operand must **not** be promoted to a handle
([`quantum-classical-handling.md`](./quantum-classical-handling.md) §5.2); it flows
through the ABI as a value, not as a synthetic qubit register. And because the
register `%1` has **no other use** after this add, the pass emits the add
**in place** — the register itself becomes the sum:

```llvm
; before
%2 = add nsw i32 %h, 5

; after
call void @cqrt_addc_i32(i32 %h, i32 5)           ; h := (h + 5) mod 2^32
; downstream uses of %2 → %h
```

`cqrt_addc_<W>(h, imm)` is the in-place add of a classical immediate
(`runtime/cq_runtime.h`). The reason it is in place: out of place, the add would
mint a fresh rail and leave the parent standing as a live basis *record* of the
same wire, which would dephase any later non-diagonal gate applied to it.

If the pre-add value **stays live** — say the program also measures `a` — the
add is out of place instead, and mints a fresh handle through the `_hl`
(handle + literal) template. Measured on
`int c = a + b; int ra = cq_measure(a); int rc = cq_measure(c);`:

```llvm
%h    = call i32 @cqrt_alloc_i32(i32 3)
call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
%h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 5)   ; fresh rail, %h stays live
%m    = call i32 @cqrt_measure_i32(i32 %h)
%m1   = call i32 @cqrt_measure_i32(i32 %h_op)
```

and its trace is `alloc(3) -> h0; ry(h0, 0.5); cq_template_add_i32_hl(h0, 5) -> h1;
measure(h0); measure(h1)`.

### Step 3 — Measure lowering

`@cq_measure_si32(%2)` lowers to the width-only runtime entry point, on the
handle the add produced (`%h`, since the add was in place):

```llvm
; before
%3 = tail call i32 @cq_measure_si32(i32 %2)

; after
%m = call i32 @cqrt_measure_i32(i32 %h)
```

The handle is **not** consumed by the measure — the register persists in a
classical eigenstate after the call ([`frontend.md`](./frontend.md) §3.4). The
`%m` return is classical; its only use here is the `ret i32`.

### Step 4 — Uncomputation: nothing to do here

Nothing in this program needs uncomputing: its only register is the one that is
measured, and a measured register belongs to the measurement — the compiler never
frees it (a hidden reset of a measured, possibly entangled register would be a
second measurement). The compiler does emit adjoints and `cqrt_free` for rails it
mints as **intermediates**, but only where the rail is provably `|0⟩` again: the
flag of a controlled region and its strip ([`frontend.md`](./frontend.md) §3.3),
or `x*x` in `x*x*x`, whose `cq_template_mul_i32_unc` and `cqrt_free` appear in the
stream even inside `main`. A function's final live register is left for its
caller, and in `main` there is no caller to hand it to, so it is left allocated
(`FreePoint.cpp`); [`frontend.md`](./frontend.md) §6.1 shows the full stream for
a lifted function.

### The fully lowered IR

```llvm
define i32 @main() local_unnamed_addr {
  %h = call i32 @cqrt_alloc_i32(i32 3)                 ; allocate qubit register
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)  ; Ry(0.5)
  call void @cqrt_addc_i32(i32 %h, i32 5)              ; Q+C add, in place
  %m = call i32 @cqrt_measure_i32(i32 %h)              ; measure
  ret i32 %m
}
```

No `@cq_*` intrinsic calls remain. Only `cqrt_*` runtime calls,
`cq_template_*` template calls, and stock LLVM classical IR threading
them — exactly the output contract [`backend.md`](./backend.md) §13.1 describes.

Linked against the trace runtime and run, the program prints its circuit, one
line per gate (the trace runtime does not simulate; `measure` returns 0):

```
cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cqrt_addc_i32(h0, 5)
cqrt_measure_i32(h0) -> 0
```

---

## Compilation flow

The flow that produced the IR above ([`frontend.md`](./frontend.md) §8), from the
repository root with LLVM 19's tools on `PATH`:

```bash
# Stage 1: frontend — plain Clang -O1 with CQ.h on the include path
clang -O1 -emit-llvm -c -include CQ.h -Iinclude example.c -o example.bc

# Stage 2: backend IR pass — taint propagation, allocation, opcode lowering,
# measure lowering.
opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering \
    example.bc -o example.lowered.bc

# Stage 3: standard codegen + link against templates, then runtime
# (this order is load-bearing: template bodies call cqrt_*)
clang example.lowered.bc -Lbuild/runtime -lcq_templates -lcq_runtime -o example

./example   # emits the circuit
```

`tools/cqc` wraps this multi-step flow into a single command line
(`cqc example.c -o example`); for multi-file programs the cloning path needs the
callee bodies in the same module, which `cqc` arranges with `llvm-link` before
`opt` ([`frontend.md`](./frontend.md) §8).

---

## Where the other mechanisms are walked

| Mechanism | Documented in |
|---|---|
| Forward taint propagation | [`backend.md`](./backend.md) §4; table above |
| Allocation lowering on classical operand | Step 1 above; [`frontend.md`](./frontend.md) §4; [`backend.md`](./backend.md) §5.1 |
| Allocation skipped on tainted operand (chained rotation) | [`frontend.md`](./frontend.md) §3.2; [`backend.md`](./backend.md) §5.1 |
| Q+C add: in place (`cqrt_addc`) vs out of place (`_hl` template) | Step 2 above; [`backend.md`](./backend.md) §6.1, §6.2 |
| `cq_phi` branch phase — kickback under control, deletion uncontrolled | [`frontend.md`](./frontend.md) §3.3; [`backend.md`](./backend.md) §6.1a |
| Function lifting (clone-on-taint) | [`frontend.md`](./frontend.md) §6; [`backend.md`](./backend.md) §7 |
| Quantum control flow: tainted branches (phase / rotation / value arms) | [`frontend.md`](./frontend.md) §7; [`backend.md`](./backend.md) §8 |
| Manual inversion bracket | [`frontend.md`](./frontend.md) §3.5; [`backend.md`](./backend.md) §10.3 (declared, not lowered yet) |

---

## Cross-references

| Concern | Where |
|---|---|
| User-facing intrinsic surface (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) | [`frontend.md`](./frontend.md) §3 |
| Compilation flow, single-file and multi-file | [`frontend.md`](./frontend.md) §8; [`backend.md`](./backend.md) §13 |
| Forward taint propagation algorithm | [`backend.md`](./backend.md) §4 |
| Allocation lowering (gate-triggered) | [`frontend.md`](./frontend.md) §4; [`backend.md`](./backend.md) §5 |
| Opcode lowering + mixed-operand dispatch | [`backend.md`](./backend.md) §6; [`quantum-classical-handling.md`](./quantum-classical-handling.md) §5 |
| Why classical operands are never promoted to handles | [`quantum-classical-handling.md`](./quantum-classical-handling.md) §5.2 |
| Runtime ABI (`cqrt_alloc_<W>`, `cqrt_ry_<W>`, `cqrt_measure_<W>`, `cqrt_addc_<W>`) | [`backend.md`](./backend.md) §11; `runtime/cq_runtime.h` |
| The plan of record | [`../NORTHSTAR.md`](../NORTHSTAR.md) |
