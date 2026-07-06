# CQ demo — `foo` on a superposition

Your original program, compiled through the CQ pipeline
(`clang -O1` → `opt -passes=cq-lowering` → link against the trace runtime → run).

## What I changed to match the codebase

CQ has **no `quantum` keyword and no special type** — a value becomes quantum by
passing through a `cq_*` primitive (from `include/CQ.h`), and the out-of-tree LLVM-19
pass propagates that "taint" forward. So the only edits were the intrinsic names +
the include:

| your code        | CQ intrinsic                | meaning                                             |
|------------------|-----------------------------|-----------------------------------------------------|
| `theta(b, 0.5)`  | `cq_theta(b, 0.5)`          | Ry — the **sole** taint source (makes `b` quantum)  |
| `phi(a, 3.14)`   | `cq_phi(a, 3.14)`           | Rz — a phase (propagates taint, never creates it)   |
| `measure(a)`     | `cq_measure(a)`             | the taint sink                                      |
| —                | `#include "CQ.h"`           | the intrinsic surface (compile with `-Iinclude`)    |

`cq_theta/cq_phi/cq_measure` are C11 `_Generic` macros, so `b`/`a` stay plain `int`.

## Result — the faithful version **declines** (and that's correct)

[`foo.c`](foo.c) is your program with just those renames. It **compiles at the C
front-end** ([`foo.frontend.ll`](foo.frontend.ll)) but the `cq-lowering` pass
**loudly declines** it ([`foo.decline.txt`](foo.decline.txt)):

```
error: in function main: cq controlled lowering: control flow under quantum control
```

**Why.** `clang -O1` fuses `int a = foo(b); if (a != 0) …` (with `foo`'s
`if (b<5) a += b`) into a single quantum-conditioned diamond whose merge selects
between a **phase-rotated qubit** (`cq_phi(b)`) and a **classical `0`**:

```
if ((b<5) && (b!=0))  a = cq_phi(b, 3.14);   // one arm: a phase gate on the qubit
else                  a = 0;                  // other arm: a classical constant
measure(a);
```

That merge is neither a clean **phase arm** (a phase must stay *in place* on the
rail — no data merge) nor a **value arm** (Bennett copy-out would copy a basis
*label* and cancel the very phase that is the answer — see the project's Rule 7).
CQ is **coherent-first**: rather than silently pick one and compute the wrong
unitary, it declines. This is the compiler's Prime Directive in action —
**over-declining is safe; a silent miscompile is the one unforgivable bug.**

## A compiler-supported restructuring that runs end-to-end

[`foo_working.c`](foo_working.c) keeps the spirit (quantum value → helper → phase →
measure) but makes `foo` a **pure value helper** (`return b+b`, no in-body control)
and applies the phase unconditionally, so there is no phase/value-merge ambiguity.
It lowers clean, links, and runs ([`foo_working.trace.log`](foo_working.trace.log)):

```
cqrt_alloc_i32(1) -> h0            ; qubit for b (argc == 1)
cqrt_ry_i32(h0, 0.500000)          ; superposition
cq_template_shl_i32_hl(h0, 1) -> h1 ; foo's b+b  (clang -O1 folds to b<<1)
cqrt_rz_i32(h1, 3.140000)          ; the phase
cqrt_measure_i32(h1) -> 0          ; measure (runtime is trace-only; returns 0)
```

The runtime is **trace-only** — every gate prints one line; it does not simulate,
and `measure` returns 0. The golden trace *is* the contract.

## What actually happens to `foo` — the quantum clone

In a single file, `clang -O1` **inlines** `foo` (above, `b+b` became an inline
`shl`). To see what the compiler does when `foo` is a real, un-inlined function
receiving a superposition, [`foo_spec_caller.c`](foo_spec_caller.c) +
[`foo_spec_lib.c`](foo_spec_lib.c) keep `foo` in a separate translation unit. The
pass then **specializes** it — cloning `foo` into a *reversible quantum* function
`@__cq_q_foo_1` and Bennett-wrapping it (compute → copy-out → uncompute → free).
[`foo_spec.trace.log`](foo_spec.trace.log):

```
cqrt_alloc_i32(1) -> h0
cqrt_ry_i32(h0, 0.500000)           ; superposition
cq_template_shl_i32_hl(h0, 1) -> h1 ; inside @__cq_q_foo_1: b+b
cqrt_alloc_i32(0) -> h2             ; Bennett copy-out rail
cqrt_copy_i32(h1, h2)               ; copy the result out
cq_template_shl_i32_hl_unc(h1, h0, 1) ; reverse-play foo's forward op (uncompute)
cqrt_free(h1)                       ; free the now-|0> scratch
cqrt_rz_i32(h2, 3.140000)           ; the phase on the clone's result
cqrt_measure_i32(h2) -> 0           ; measure
```

This is the headline CQ feature: **a plain C function, handed a superposition,
becomes a reversible quantum subroutine — no rewrite, no annotations.**

## Your *original* `foo` (with the `if`), un-inlined, now lifts too

`clang -O1` compiles `int a=0; if (b<5) a += b; return a;` to
`select(b<5, b, 0)`. Handed a superposition **un-inlined**, Phase-6
specialization (issue **5po2**) lifts it into the reversible clone
`@__cq_q_foo_1` — emitting the `select` as a controlled-XOR copy
`out = flag ? b : 0` and Bennett-reversing it (the self-inverse controlled copy
zeroes the out rail, the compare `_unc` unmints the flag, both scratch rails free
clean). [`foo_spec_inbody.trace.log`](foo_spec_inbody.trace.log):

```
cqrt_alloc_i32(1) -> h0
cqrt_ry_i32(h0, 0.500000)            ; superposition
cq_template_icmp_slt_i32_hl(h0, 5) -> h1  ; flag = (b<5)   [inside @__cq_q_foo_1]
cqrt_alloc_i32(0) -> h2              ; out rail |0>
cqrt_copy_i32_controlled(h1, h0, h2) ; out = flag ? b : 0
cqrt_alloc_i32(0) -> h3              ; Bennett copy-out
cqrt_copy_i32(h2, h3)
cqrt_copy_i32_controlled(h1, h0, h2) ; reverse (self-inverse → zeroes out rail)
cq_template_icmp_slt_i32_hl_unc(h1, h0, 5) ; reverse (unmints the flag)
cqrt_free(h1)                        ; free flag (proven |0>)
cqrt_free(h2)                        ; free out rail (proven |0>)
cqrt_rz_i32(h3, 3.140000)            ; the phase on the result
cqrt_measure_i32(h3) -> 0            ; measure
```

**A plain C function with in-body control becomes a reversible quantum
subroutine.** (Pre-5po2 this declined *"callee contains tainted control flow
under quantum lift"* — the clone path had no bridge from the top-level control
emitter. See `docs/prd/phase-06-call-graph-specialization/5po2_SELECT_IN_CLONE.md`.)

The one shape still on the frontier is the **single-file** `foo` where `main`
wraps the call in `if (a != 0) a = cq_phi(a, …)`
([`foo_noinline.c`](foo_noinline.c) → [`foo_noinline.decline.txt`](foo_noinline.decline.txt)):
`foo` itself lifts, but `main`'s outer conditional phase is a *separate* tainted-
control decline (the const-folded phase/value merge — bd issue **a8c0**), so the
whole module still declines there.

## Files / reproduce

- `foo.c`, `foo.frontend.ll`, `foo.decline.txt` — the faithful attempt, inlined (declines: `main`'s phase/value merge).
- `foo_working.c`, `foo_working.frontend.ll`, `foo_working.lowered.ll`, `foo_working.trace.log` — the single-file version that runs.
- `foo_spec_caller.c`, `foo_spec_lib.c`, `foo_spec.lowered.ll`, `foo_spec.trace.log` — the multi-file quantum-clone version (pure `foo`).
- `foo_spec_inbody.lowered.ll`, `foo_spec_inbody.trace.log` — **your original `foo` body (with the `if`), un-inlined, now LIFTED to a reversible clone** (issue 5po2).
- `foo_noinline.c`, `foo_noinline.frontend.ll`, `foo_noinline.decline.txt` — single-file `noinline` `foo`: `foo` lifts, but `main`'s outer `if` still declines (issue a8c0).
- `build.sh` — regenerates every artifact above (needs `cmake --build build --target CQPass` first).

```bash
cmake --build build --target CQPass    # build the pass once
bash demo/foo_superposition/build.sh   # reproduce all artifacts
```
