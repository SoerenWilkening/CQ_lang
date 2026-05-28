# CQ Quantum/Classical Boundary — Taint as the Implicit Frontier

Where quantum behavior begins and ends in a CQ program, expressed
through a single mechanism — **taint** on LLVM SSA values — rather
than a keyword on declarations or a cast on conversions. This
document explains why taint is the right boundary, what triggers
it, what propagates it, what crosses it, and what does not. It is
the conceptual heart of the taint-driven design: every other
surface (the frontend intrinsics, the IR pass, the runtime ABI) is
downstream of the decisions stated here.

Companion documents:
- [`frontend.md`](./frontend.md) — the user-facing intrinsic surface
  (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) and the
  Clang/`-O1` pipeline that prepares the IR
- [`backend.md`](./backend.md) — the IR pass that performs the taint
  analysis and lowering, plus the runtime ABI
- [`llvm-implementation.md`](./llvm-implementation.md) — the stock
  LLVM C++ APIs every mechanism in this document depends on
- [`rationale/proposal-taint-driven-pipeline.md`](./rationale/proposal-taint-driven-pipeline.md)
  — the proposal that diagnosed the previous design's failures and
  motivated the move to taint-driven semantics

---

## 1. Scope

This document defines:

- The single mechanism (taint on SSA values) that separates quantum
  from classical behavior in CQ programs
- What triggers taint, how it propagates through stock LLVM
  opcodes, and where it stops
- How mixed quantum + classical operands are handled — the
  dispatch rule, the runtime entry points, and what the IR pass
  must never do
- How type conversions interact with taint — and why casts are
  representation changes, never measurements
- The diagnostic the previous (`quantum` keyword + cast-as-
  measurement) design failed on — function lifting with hidden
  casts — and how the taint-driven boundary fixes it

It does **not** define:

- The user-facing intrinsics themselves (signatures, dispatch
  macros, fan-out across the 14 C scalar types) — see
  [`frontend.md`](./frontend.md) §3
- The data-flow algorithm the IR pass uses to compute taint — see
  [`backend.md`](./backend.md) §4
- The full set of stock LLVM opcodes covered by template lowering
  and their per-width / per-shape templates — see
  [`backend.md`](./backend.md) §6.3, §12

---

## 2. The boundary in one sentence

**Quantum behavior is a property of SSA values, not of variable
declarations or static types.** A value is quantum if it has been
*tainted* — derived (transitively, by stock LLVM data flow) from a
qubit-allocating gate call. A value is classical if it has not.
The boundary is therefore implicit: it follows the data, moves
where the data moves, and exists only where taint exists.

A `quantum` keyword on a declaration plays no role in this scheme.
There is no such keyword in `CQ.h`, no struct wrapper, no
type-system distinction in the IR. Two variables both declared
`int a` are indistinguishable until one of them flows through a
taint source — at which point the SSA value emerging from that
flow is quantum, regardless of how the operand was declared.

The rest of this document derives from this single point.

---

## 3. The previous boundary and why it failed

The taint-driven design exists because an earlier
keyword-and-cast design did not compose. Stating that diagnosis
plainly is the right entry point for understanding what the new
boundary buys.

### 3.1 The previous boundary

Under the prior design (now archived at
[`docs/archive/old-design/`](./archive/old-design/)), the
quantum/classical boundary had two source-level expressions:

- **Declaration** — `quantum int a;` marked `a` as living on
  qubits. The frontend rewriter expanded the keyword to a
  `qint_mid_t` struct wrapper and emitted a `@cq_init_i32(value)`
  call to allocate the qubit register at declaration time.
- **Type cast** — a cast like `(int) q` on a `quantum int q` was
  the measurement primitive. The rewriter detected the cast
  pattern and lowered it to a `cqrt_measure_i32(handle)` call.

The keyword identified the quantum *type*; the cast crossed the
boundary in the measurement direction.

### 3.2 The function-lifting-with-hidden-casts diagnosis

A central design goal of CQ is **function lifting**: a plain
classical function should accept tainted arguments and execute as
its quantum analog without source-level modification. A library
author writes `average(a, b)` once; quantum callers and classical
callers both use the same body.

Consider this function, idiomatic in C and harmless under classical
semantics:

```c
double average(double a, double b) {
    int count = 2;
    return (a + b) / (double) count;   /* (double) cast on count */
}
```

Now consider a quantum caller:

```c
double q_avg = average(q1, q2);   /* q1, q2 already tainted */
```

Under classical semantics this is fine. Under quantum semantics
it *must* be fine — the boundary the caller cares about is its own
inputs, not the callee's internal arithmetic.

But under the previous design, the `(double) count` inside the
callee body was a measurement *if* `count` was tainted. And `count`
would become tainted as soon as taint propagated into the body of
`average` — once the cloned specialization seeded its parameters
as tainted, `count` (which interacts with tainted operands in the
final division) inherited taint through the arithmetic chain. The
harmless `(double) count` cast then collapsed the quantum state
mid-computation, returning a classical scalar where the caller
expected a quantum result.

Three properties of this failure made it not patchable in place:

1. **The caller cannot see the offending cast.** The cast is an
   implementation detail of `average`'s body. The function's
   *signature* says `(double, double) → double` — nothing in that
   signature tells the caller that internal cast patterns will
   collapse the state.
2. **Equivalent implementations behave differently.** A different
   author writing the same function without the `(double) count`
   cast — say, by using a literal `2.0` directly — would not
   collapse the state. Whether a classical function is "safe to
   lift" depends on its internal cast patterns; the type system
   gives no way to declare a function "lift-safe."
3. **The failure is silent.** Nothing diagnoses the unwanted
   measurement. The program compiles, the program runs, and the
   caller receives a numerical result that happens not to be
   quantum.

This pattern recurs across libm wrappers, accumulator-style
helpers, division-by-integer-count patterns, and most code that
operates on heterogeneous numeric types. The whole class of code
is exactly what function lifting was supposed to compose with.

### 3.3 The root cause — two unrelated operations conflated

The cast-as-measurement rule treated *type conversion* and
*measurement* as a single operation. They are not.

- **Type conversion** is a representation change. An `int` and a
  `double` differ in how the same numerical quantity is laid out
  in bits. Conversion adjusts the layout (widen, narrow, sign-
  extend, round to nearest float). It says nothing about whether
  the bits live on transistors or qubits.
- **Measurement** is a substrate change. A qubit register's
  superposed amplitudes collapse to a single computational-basis
  state; the result is moved from the qubit substrate to the
  classical substrate. The result's C type is the same as before
  the call (`cq_measure(int_register)` returns `int`) but the
  substrate has changed.

The prior design used the type-conversion syntax `(int) q` to
trigger the substrate change. That choice broke lifting because
type conversion happens routinely inside function bodies for
reasons unrelated to substrate, and the caller cannot see them.

### 3.4 The redesign commitment

The taint-driven design fixes the failure by:

1. **Separating the two operations.** Type conversion under taint
   is a representation change at the quantum layer (a quantum
   cast template); measurement requires an explicit,
   syntactically distinct call (`cq_measure`).
2. **Putting the Q/C boundary on values (taint), not on
   declarations (keyword).** A function body need not be authored
   with quantum awareness; data flow alone determines what is
   quantum and where.
3. **Making the only taint source an unambiguous explicit gate
   (`cq_theta`, i.e. Ry).** No declaration site is a taint
   source; no conversion site introduces taint; nothing
   accidental can mint superposition.

The remaining sections describe how those three commitments play
out.

---

## 4. Taint — sources, propagation, sinks

The taint relation classifies every SSA value into one of two
states — *tainted* (quantum) or *classical* — using a monotone
forward data-flow rule.

### 4.1 The only taint source

A value is *initially tainted* if it is the return value of a
`@cq_theta_<sfx>` call. This is the only initial source of taint
in the entire compilation unit:

```c
int a = 3;                      /* %a is classical */
int a1 = cq_theta(a, 0.5);      /* %a1 is tainted — Ry(0.5) on a
                                   fresh register initialized to 3 */
```

In LLVM IR after Clang `-O1`:

```llvm
%a1 = call i32 @cq_theta_si32(i32 %a, double 5.0e-01)
;     ^^ — %a1 is the seed of the taint relation
```

The single-source choice is principled, not minimal-by-omission.
Ry is the gate that physically introduces superposition: it
rotates a qubit out of a computational-basis state into a
non-trivial linear combination of |0⟩ and |1⟩. Every other quantum
operation either preserves whether a value is in superposition
(Rz, arithmetic templates, controlled forms) or removes it
(measurement). Making Ry the unique source aligns the IR-level
boundary with the physical-level boundary.

Two operations that look like they should introduce taint but
deliberately do not:

- **`cq_phi` (Rz).** A phase rotation on a computational-basis
  state adds only global phase — a physical no-op. Adding taint
  here would force allocation of a qubit register for a value
  that will never be observed in superposition. The pass treats
  `cq_phi` on a classical operand as a deletion candidate, and
  `cq_phi` on a tainted operand as taint-propagating only — no
  new source (see [`backend.md`](./backend.md) §6).
- **Plain declarations.** A `int a = 3` is classical. There is no
  surface form that declares a variable "intended quantum" without
  invoking a gate. This is the deliberate replacement of the
  prior `cq_init_*` family — allocation is gate-triggered, not
  declaration-triggered.

### 4.2 Propagation through stock LLVM opcodes

Taint propagates by the **operand rule**: an SSA value `v`
produced by some instruction is tainted if any operand of that
instruction is tainted. The rule is local (one instruction at a
time), monotone (taint never un-propagates), and forward (along
SSA def-use, with no need to re-process predecessors).

Every LLVM data-carrying opcode is a propagation site:

| Opcode | Tainted iff |
|---|---|
| `add %x, %y` | `%x` or `%y` tainted |
| `mul %x, %y` | `%x` or `%y` tainted |
| `icmp <pred> %x, %y` | `%x` or `%y` tainted |
| `fadd %x, %y` | `%x` or `%y` tainted |
| `sext %x` (and other casts) | `%x` tainted |
| `fneg %x` | `%x` tainted |
| `phi [%a, %BB1], [%b, %BB2]` | `%a` or `%b` tainted, **or** the φ sits in a tainted-branch shadow (§4.4) |
| `call @f(%a, %b)` | the return's taint depends on callee specialization (§4.5) |

The propagation runs on whatever IR Clang's `-O1` produces. There
is no requirement that the input be in any special form beyond
the standard `mem2reg` / `SROA` cleanup; the SSA def-use graph
that comes out of `-O1` is the data structure the rule walks.

### 4.3 The only sink — `cq_measure`

A value is *forced classical* if it is the return value of a
`@cq_measure_<sfx>` call. This is the only sink. Downstream uses
of the measure result — arithmetic, control flow, I/O — are
plain classical SSA. No subsequent operation can re-promote the
value to quantum without flowing it through a fresh `cq_theta`.

```c
int q = cq_theta(0, 0.5);    /* tainted */
int m = cq_measure(q);        /* forced classical */
int x = m + 1;                /* classical — add of two classical operands */
```

In LLVM IR:

```llvm
%q = call i32 @cq_theta_si32(i32 0, double 5.0e-01)   ; tainted
%m = call i32 @cq_measure_si32(i32 %q)                ; classical
%x = add i32 %m, 1                                    ; classical
```

The qubit register underlying `%q` is preserved across the measure
call (per [`frontend.md`](./frontend.md) §3.4): the register
persists in a classical eigenstate and may be re-rotated by
subsequent `cq_theta` calls. From the IR-level taint relation's
perspective, however, the measure is a hard sink: `%m` is
classical, and no use of `%m` carries taint forward.

### 4.4 Control-flow taint

A branch whose `i1 %cond` is tainted is a *quantum branch*: the
program is in a superposition of "taken" and "not taken." This
case extends taint propagation in one structural way: **values
defined in the dominated shadow of a tainted branch are
control-tainted**, even if their direct SSA operands are classical
literals.

The motivating case is a φ-node at the post-dominator block:

```c
int x = cq_theta(0, 0.3);    /* x tainted */
int y;
if (x > 0)
    y = 10;
else
    y = 20;
/* y is classical-by-operand (the φ merges two literals) but
   semantically depends on the quantum branch — must be
   control-tainted */
```

In LLVM:

```llvm
%cmp = icmp sgt i32 %x, 0                ; tainted (operand %x is tainted)
br i1 %cmp, label %T, label %F           ; tainted branch
...
merge:
  %y = phi i32 [ 10, %T ], [ 20, %F ]    ; operands are literals
                                           ; — but the φ is in the
                                           ; merge of a tainted branch
                                           ; so %y is control-tainted
```

The IR pass computes the controlled shadow structurally via
`PostDominatorTree` (see [`backend.md`](./backend.md) §8) and
promotes every value defined in that shadow to tainted. The
operand-only rule on its own would miss the φ promotion, so the
structural extension is load-bearing.

There is no user-facing marker for control-flow taint. A plain
C `if (tainted_cond) { ... }` *is* the controlled region; the
brace-bounded shadow is the post-dominated subgraph the pass
identifies. This is consistent with the design principle that
the boundary is implicit and follows the data — including the
data carried by branch conditions.

### 4.5 Taint at function-call boundaries

A call instruction with any tainted argument is a *tainted call*.
The callee is specialized via one of the two lifting paths
([`backend.md`](./backend.md) §7):

- **Curated symbol substitution** — for callees with no visible
  IR body (libm, LLVM intrinsics, opaque shared libraries). The
  pass swaps `@sin` for `@cq_template_sin_f64` etc.; the call's
  return is tainted.
- **Clone-on-taint** — for callees with visible IR bodies (user
  code, LTO-linked libraries). The pass clones the callee, seeds
  taint on the parameters corresponding to the tainted arguments,
  propagates taint through the clone's body recursively, and
  retargets the call. The call's return is tainted iff the
  clone's return value is tainted under the propagation.

Both paths preserve the property that the original function
remains unchanged for classical callers. The IR-pass-level taint
relation is the substrate determining which path applies, what
gets cloned, and where taint stops inside the clone.

---

## 5. Mixed-operand semantics (Q + C)

The most common kind of tainted instruction is one with mixed
operands: one tainted (a handle) and one classical (a literal or
another untainted SSA value). How those are lowered is one of the
load-bearing decisions of the taint-driven design.

### 5.1 The two operand shapes the pass recognizes

For a tainted binary opcode like `add i32 %x, %y`, the pass
classifies the operand shape:

| Shape | LHS taint | RHS taint | Lowering |
|---|---|---|---|
| **H+H** (handle + handle) | tainted | tainted | `cq_template_add_i32(%h_x, %h_y)` |
| **H+C** (handle + classical) | tainted | classical | `cq_template_add_i32_hl(%h_x, %c)` |
| **C+H** | classical | tainted | canonicalized to H+C for commutative opcodes; `_lh` variant deferred otherwise (see [`backend.md`](./backend.md) §6.2) |
| **C+C** (both classical) | classical | classical | left alone (stock LLVM `add`) |

The IR pass dispatches on **LLVM operand kind** at lowering time:
an `isa<ConstantInt>(operand)` test (or "this SSA value is not in
the tainted set") decides which template name is emitted. The
shape decision is local to the instruction; no global analysis is
needed beyond the taint classification already in hand from §4.

### 5.2 The classical operand is never promoted to a handle

The H+C case is where the design's most important runtime-ABI
rule lives: **the classical operand is passed to the runtime as a
literal, not allocated onto a fresh qubit register.** Concretely,
the lowering does *not* look like this:

```llvm
; NOT what the pass emits
%h_y = call i32 @cqrt_alloc_i32(i32 %c)              ; allocate for the literal
%h_z = call i32 @cq_template_add_i32(i32 %h_x, i32 %h_y)
```

It looks like this:

```llvm
; what the pass actually emits
%h_z = call i32 @cq_template_add_i32_hl(i32 %h_x, i32 %c)
```

Three reasons drive the rule:

1. **Preserve the classical operand's identity.** Once a classical
   value has been promoted to a qubit register, it has paid a
   non-zero qubit cost and the rest of the pipeline has no easy
   way to recover the fact that it was "originally a literal."
   Keeping the literal as a literal across the runtime ABI keeps
   the option open.
2. **Preserve the future `cq_alloc` deferral / elision
   optimization.** A planned optimization backward-analyzes the
   IR for "superposition reachability" and elides
   `cqrt_alloc_<W>` calls whose downstream uses never reach a
   superposition-meaningful sink. Promoting a classical literal
   to a handle introduces a synthetic allocation site that the
   elision analysis cannot prove unnecessary without first
   recovering "this was a literal" — work the `_hl` dispatch
   already did at lowering time, and that the elision pass would
   have to redo. The rule preserves the degrees of freedom the
   optimization needs.
3. **Match the runtime's mixed-shape capability.** The template
   library is explicitly parameterized by operand shape (see
   [`backend.md`](./backend.md) §12.2): `cq_template_add_i32`
   and `cq_template_add_i32_hl` are different symbols with
   different signatures. The runtime is built around the
   distinction; the IR pass passes the right shape through.

This rule is not negotiable. Any future template op
(`cq_template_sub_i32`, `cq_template_mul_i32`, …) follows the
same pattern — distinct runtime entry points per operand shape,
dispatched by the IR pass based on LLVM operand kind, never
promoting classical operands to handles. Any future change to
mixed-operand lowering must preserve all three properties above.

### 5.3 Operand symmetry and non-commutative ops

For commutative opcodes (`add`, `mul`, `and`, `or`, `xor`,
`fadd`, `fmul`), the pass canonicalizes operand order before
dispatch so the tainted operand is conventionally on the LHS.
This collapses H+C and C+H to a single `_hl` template; no `_lh`
is needed.

For non-commutative opcodes (`sub`, `sdiv`, `srem`, `lshr`,
`ashr`, `shl`, `fsub`, `fdiv`), canonicalization is not possible:
`a - b` and `b - a` differ in result. Each shape in principle
needs its own template — `_hl` (handle on LHS) and `_lh` (handle
on RHS). The current pass ships `_hl` only; `_lh` is deferred
until a real call site demands it (see
[`backend.md`](./backend.md) §6.2). When the demand arrives the
pass dispatches on the same operand-kind check; no change to the
overall rule is required.

### 5.4 The classical operand's flow is preserved

A classical SSA value passed to an `_hl` template stays
classical throughout. Its uses outside the template call are
unchanged; the template call is just another use. The pass
inserts no allocation, no rebinding, and no handle wrapper for
the classical side.

On its side of the ABI, the runtime is free to perform any
classical-shadow shortcut it wants for the operation (e.g., if
the handle's register has not yet entered superposition, the
`_hl` template body may decline to apply any gates and just
update the register's classical shadow value). This optimization
lives entirely behind the runtime boundary and is invisible to
the IR-emitted caller.

---

## 6. Conversion semantics — representation, never measurement

Type conversion at the LLVM-IR level — `sext`, `zext`, `trunc`,
`fpext`, `fptrunc`, `sitofp`, `uitofp`, `fptosi`, `fptoui` — is a
**representation change**. It says how a numerical value is
encoded in bits; it says nothing about whether those bits live on
classical transistors or quantum qubits. The taint-driven design
honors this: under taint, every cast opcode lowers to its
corresponding quantum cast template; none of them is ever a
measurement.

### 6.1 The principle

**Substrate is a property of the SSA value; representation is a
property of the operation.** Two values with the same C type
(`int` and `int`) can differ in substrate (one tainted, one not);
two values with different C types (`int` and `double`) may share
substrate (both tainted, both on qubits) or not, but the
conversion between them is a representation operation regardless
of substrate.

This is the core observation the previous design got wrong by
conflating the two. The taint-driven design takes them as
genuinely independent dimensions:

| | int → int | int → double | double → int |
|---|---|---|---|
| **Classical operand** | stock `sext` / `zext` / `trunc` | stock `sitofp` / `uitofp` | stock `fptosi` / `fptoui` |
| **Tainted operand** | `cq_template_<cast>_<from>_to_<to>` | `cq_template_sitofp_…` | `cq_template_fptosi_…` |

The right column under "tainted operand" is what the previous
design replaced with measurement; under the new design it is a
representation change at the quantum layer, implemented by a
quantum cast template that maps the tainted register's qubits to
a new representation without observing the underlying state.

### 6.2 What a quantum cast template does

Conceptually, `cq_template_sitofp_i32_to_f64(handle_int)`:

1. Allocates a fresh register at the target representation (f64).
2. Maps the bits of the source register onto the bits of the
   target register according to the conversion's mathematical
   rule. For int-to-float this is a reversible permutation of
   computational-basis states (Bennett's classical-to-reversible
   construction at the per-op layer); for widening it is a
   circuit that copies the low bits and zero/sign-extends the
   high bits.
3. Returns the new handle.

The source register is not consumed; it remains a valid handle
for as long as its SSA uses extend. Auto-uncomputation at last
use applies the inverse representation circuit and frees both
handles (see [`backend.md`](./backend.md) §9). At no point is
the register measured.

Concrete gate sequences for each cast template are deferred to
template-implementation work that runs after the frontend
freeze; declarations live in
[`runtime/cq_templates.h`](../runtime/cq_templates.h).

### 6.3 The user-visible consequence

The user writes C casts as they always have:

```c
int q = cq_theta(0, 0.5);     /* tainted */
double d = (double) q;         /* representation change; d tainted */
int back = (int) d;            /* representation change back; tainted */
int m = cq_measure(back);      /* THIS is the measurement, explicitly */
```

What this guarantees:

1. **Casts are never the measurement primitive.** A function
   author can write `(int) x` inside a callee body without
   worrying that the caller has tainted `x`. The cast does what
   casts do: change representation.
2. **Measurement is syntactically obvious.** Every measurement
   in the program is spelled `cq_measure(...)`. A reviewer can
   grep for them. There is no other path to a measurement gate
   at runtime.
3. **Cast chains compose.** `(int)(double) q` and
   `(double)(int) q` are both legal under taint; each cast
   lowers to a quantum template. Neither chain collapses the
   state. The user can reason about them at the source level as
   they would in plain C.

### 6.4 What this is not

Two failure modes the rule does not introduce, despite the strong
"casts never measure" statement:

- **A cast in a tainted shadow is still a representation change.**
  Inside an `if (tainted_cond) { ... }`, casts are subject to
  control-form lowering (their templates become controlled
  variants), but they remain casts — not measurements. The same
  rule applies recursively in nested tainted branches.
- **Measurement-on-cast cannot be opted into.** There is no
  flag, attribute, or syntactic form that turns a cast into a
  measurement. If a user wants measurement, they write
  `cq_measure(...)`. The asymmetry is by design: a single,
  unambiguous syntax for state collapse, with no path to
  reintroduce the diagnosable failure mode that motivated the
  redesign.

---

## 7. The function-lifting fix

The taint-driven boundary's most important downstream
consequence is that **classical functions lift to quantum callers
without modification and without surprise**. This section walks
the diagnostic from §3 through to closure under the new rules.

### 7.1 The motivating callee, revisited

```c
double average(double a, double b) {
    int count = 2;
    return (a + b) / (double) count;
}
```

Under classical semantics this function is a four-line average.
Under the previous design with a tainted caller it would
silently collapse the state at `(double) count`.

### 7.2 What the new pipeline does

The IR pass receives this body via the clone-on-taint path
(§4.5). For the call `average(q1, q2)` with both arguments
tainted, the pass clones `average` with signature `(tainted,
tainted)`, seeds taint on both parameters, and runs propagation
through the clone's body. Each instruction lowers per §4–§6:

```
IR before lowering (in the cloned specialization):
  %sum    = fadd double %a, %b              ; tainted (operands tainted)
  %count  = ... constant 2                  ; classical literal
  %countd = sitofp i32 %count to double     ; classical (operand classical)
  %avg    = fdiv double %sum, %countd       ; H+C division
  ret double %avg

IR after lowering:
  %h_sum  = call double @cq_template_fadd_f64(double %h_a, double %h_b)
  ; %count and %countd are not touched — they remain classical SSA
  %h_avg  = call double @cq_template_fdiv_f64_hl(double %h_sum, double %countd)
  ret double %h_avg
```

Three things happen automatically:

1. **`int count = 2`** stays classical. The constant `2` is a
   literal; no operand of any instruction in `count`'s definition
   chain is tainted. Taint never reaches `count`.
2. **`(double) count`** is therefore a classical `sitofp` on a
   classical operand. The pass leaves it alone — stock LLVM IR,
   no template lowering, no measurement.
3. **`(a + b) / (double) count`** is the only place the boundary
   shows up. The `fadd` is H+H tainted (lowered to
   `cq_template_fadd_f64`). The `fdiv` is H+C: tainted handle
   `%h_sum` on the LHS, classical `%countd` on the RHS. The pass
   emits the `_hl` variant; the classical operand is passed
   through as a value, not promoted to a handle. No
   `cqrt_alloc_<W>` is inserted for `%countd`.

The result is a tainted `%h_avg` returned to the caller. No
measurement happens inside the body. The author of `average` did
not need to know anything about CQ to write a function that
works for both classical and quantum callers.

### 7.3 Why each prior failure mode is addressed

Recapping §3.2:

| Prior failure | How the new design addresses it |
|---|---|
| Caller cannot see the offending cast | There is no offending cast — casts never measure under taint |
| Equivalent implementations behave differently | They behave the same — representation-only cast lowering is independent of authoring choice |
| Failure is silent | Measurement is now syntactically explicit (`cq_measure`); a reviewer can find every measurement by grep, and an unintended one would require an unintended `cq_measure` call, not an unintended cast |
| Boundary lives on declarations | Boundary lives on values — it follows the data, not the type system; `count` is not classical by virtue of a declaration, it is classical because no tainted value flowed into it |

### 7.4 The properties guaranteed to library authors

A function author writing C code can rely on:

1. **Cast neutrality.** `(int) x`, `(double) y`,
   `(short)(int) z`, and similar conversions inside a function
   body do not measure. If the caller passes tainted arguments,
   conversions become quantum representation changes; if the
   caller passes classical arguments, they are stock LLVM casts.
2. **Constant safety.** A literal anywhere inside a function body
   (`int count = 2`, `for (int i = 0; i < n; i++)`, `* 1.5`) is
   classical. Its uses contribute classical operands to mixed
   operations; the `_hl` lowering keeps the literal as a literal
   across the runtime ABI.
3. **Arithmetic ubiquity.** Stock `+`, `-`, `*`, `/`, comparisons,
   shifts, and bitwise operations all work on tainted operands
   without source modification. The pass lowers them to template
   calls via the same mechanism that classified them as
   quantum — taint propagation on stock LLVM opcodes.
4. **Composition with libm and intrinsics.** `sin`, `cos`,
   `sqrt`, `fabs`, etc., have curated quantum templates; calling
   them with tainted arguments substitutes the symbol at
   lowering time, no source change. Symbols on the
   Bennett-rejection list (`printf`, syscalls — see
   [`backend.md`](./backend.md) §7.4) diagnose at compile time.

The fundamental promise the boundary mechanism makes — *write
your library once, in plain C, and it lifts* — is what the
taint-driven design exists to keep.

---

## 8. Cross-references

| Concern | Where it is documented |
|---|---|
| User-facing intrinsic surface (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) | [`frontend.md`](./frontend.md) §3 |
| IR-pass mechanism that computes taint (data-flow algorithm; operand handling; control-flow shadow) | [`backend.md`](./backend.md) §4, §8 |
| Allocation lowering, including the `_hl` runtime entry-point dispatch | [`backend.md`](./backend.md) §5, §6.2 |
| 38-opcode template surface and the autogenerated declaration set | [`backend.md`](./backend.md) §6.3, §12 |
| Function-lifting paths — curated substitution and clone-on-taint | [`backend.md`](./backend.md) §7 |
| Stock LLVM C++ APIs every mechanism uses | [`llvm-implementation.md`](./llvm-implementation.md) |
| Proposal that diagnosed the prior failures and motivated the redesign | [`rationale/proposal-taint-driven-pipeline.md`](./rationale/proposal-taint-driven-pipeline.md) |
| End-to-end worked example, source → lowered IR | [`example.md`](./example.md) |
| Design comparison with Sturm.jl / Bennett.jl (resync to taint-driven design pending) | [`bennett-jl-comparison.md`](./bennett-jl-comparison.md) |
| Archived prior-design Q/C handling doc (cast-as-measurement) | [`archive/old-design/quantum-classical-handling.md`](./archive/old-design/quantum-classical-handling.md) |
