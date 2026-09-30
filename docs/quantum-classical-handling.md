# CQ Quantum/Classical Boundary — Taint as the Implicit Frontier

Where quantum behavior begins and ends in a CQ program, expressed
through a single mechanism — **taint** on LLVM SSA values — rather
than a keyword on declarations or a cast on conversions. This
document explains why taint is the right boundary, what triggers
it, what propagates it, what crosses it, and what does not. It is
the conceptual heart of the design: every other surface (the
frontend intrinsics, the IR pass, the runtime ABI) is downstream of
the decisions stated here.

The plan of record is [`../NORTHSTAR.md`](../NORTHSTAR.md): its goals and
design principles win over anything written here. Where this document
says a construct "fails loudly", read that as *not lowered yet* (a
compiler gap that is filed, never a pass) unless the construct is on
the closed physics list in NORTHSTAR goal 1.

Section numbers are cited from other documents and from source comments
(for example `quantum-classical-handling.md` §5.2, "the classical operand is
not promoted to a handle", from `PredMuxFlatten.cpp` and several lit
fixtures); keep them stable.

Companion documents:
- [`frontend.md`](./frontend.md) — the user-facing intrinsic surface
  (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) and the
  Clang/`-O1` pipeline that prepares the IR
- [`backend.md`](./backend.md) — the IR pass that performs the taint
  analysis and lowering, plus the runtime ABI
- [`llvm-implementation.md`](./llvm-implementation.md) — the stock
  LLVM C++ APIs the pass depends on

---

## 1. Scope

This document defines:

- The single mechanism (taint on SSA values) that separates quantum
  from classical behavior in CQ programs
- What triggers taint, how it propagates through stock LLVM
  opcodes, and where it stops
- How a tainted branch or `select` leaves the taint relation and is
  handed to a control emitter
- How mixed quantum + classical operands are handled — the
  dispatch rule, the runtime entry points, and what the IR pass
  does not do
- How type conversions interact with taint — and why casts are
  representation changes, never measurements
- Why this makes a plain classical function liftable to quantum
  callers without source changes

It does **not** define:

- The user-facing intrinsics themselves (signatures, dispatch
  macros, fan-out across the C scalar types) — see
  [`frontend.md`](./frontend.md) §3 and `include/CQ.h`
- The full lowering of control flow, loops, memory (QRAM) and I/O —
  see [`backend.md`](./backend.md); this document states only the
  parts the boundary itself decides
- The set of opcodes and widths covered by template lowering — see
  `tools/opcode_table.yaml` and [`backend.md`](./backend.md) §12

---

## 2. The boundary in one sentence

**Quantum behavior is a property of SSA values, not of variable
declarations or static types.** A value is quantum if it has been
*tainted* — derived (transitively, by stock LLVM data flow) from a
`cq_theta` result. A value is classical if it has not. The boundary
is therefore implicit: it follows the data, moves where the data
moves, and exists only where taint exists.

There is no `quantum` keyword in `CQ.h`, no struct wrapper, no
type-system distinction in the IR. Two variables both declared
`int a` are indistinguishable until one of them flows through a
taint source — at which point the SSA value emerging from that
flow is quantum, regardless of how the operand was declared.

The rest of this document derives from this single point.

---

## 3. Two operations that must not be conflated

A central goal of CQ is **function lifting**: a plain classical
function accepts tainted arguments and executes as its quantum
analog without source-level modification. A library author writes
`average(a, b)` once; quantum callers and classical callers use the
same body. That goal fixes how two easily-confused operations must
be separated.

- **Type conversion** is a representation change. An `int` and a
  `double` differ in how the same numerical quantity is laid out in
  bits. Conversion adjusts the layout (widen, narrow, sign-extend,
  round to nearest float). It says nothing about whether the bits
  live on transistors or qubits.
- **Measurement** is a substrate change. A qubit register's
  superposed amplitudes collapse to a single computational-basis
  state; the result moves from the qubit substrate to the classical
  substrate. The result's C type is the same as before
  (`cq_measure(int_register)` returns `int`) but the substrate has
  changed.

If a conversion were the measurement primitive, lifting would break
silently. Consider:

```c
double average(double a, double b, int n) {
    return (a + b) / (double) n;      /* (double) cast inside the callee */
}
```

The `(double) n` is an implementation detail of the callee; nothing
in its signature tells a quantum caller that it would collapse the
state, and an equivalent body written without the cast would not.
So the design commits to three things:

1. **Separate the operations.** Type conversion under taint is a
   representation change at the quantum layer (a quantum cast
   template, §6); measurement requires an explicit, syntactically
   distinct call (`cq_measure`).
2. **Put the Q/C boundary on values (taint), not on declarations.**
   A function body need not be authored with quantum awareness;
   data flow alone determines what is quantum and where.
3. **Make the only taint source an unambiguous explicit gate**
   (`cq_theta`, i.e. Ry). No declaration site is a taint source; no
   conversion site introduces taint; nothing accidental can mint
   superposition.

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
int a1 = cq_theta(a, 0.5);      /* %a1 is tainted */
```

In LLVM IR after Clang `-O1`:

```llvm
%a1 = call i32 @cq_theta_si32(i32 %a, double 5.0e-01)
;     ^^ — %a1 is the seed of the taint relation
```

The pass lowers it to `cqrt_alloc_i32(seed)` followed by
`cqrt_ry_i32(h, 0.5)` when the seed is a still-classical value (a
fresh register is born holding the seed), and to a rotation of the
existing register when the seed is already quantum (the linear rule,
[`frontend.md`](./frontend.md) §3.2). `cq_ry(x, θ)` is the statement
spelling of `x = cq_theta(x, θ)`.

The single-source choice is principled, not minimal-by-omission.
Ry is the gate that physically introduces superposition: it
rotates a qubit out of a computational-basis state into a
non-trivial linear combination of |0⟩ and |1⟩. Every other quantum
operation either preserves whether a value is in superposition
(Rz, arithmetic templates, controlled forms) or removes it
(measurement). Making Ry the unique source aligns the IR-level
boundary with the physical-level boundary.

**The angle is classical.** The angle operand of a rotation — arg 1
of `cq_theta`, arg 0 (the only operand) of `cq_phi` — is a classical
scalar, and taint never flows through it. The exclusion is per
operand *use*, not per value: a value that reaches a `cq_theta` both
as the arg-0 seed and as the angle stays tainted through the seed
edge. The pass never allocates a qubit for an angle. A
quantum-derived angle currently fails loudly (`cq rotation lowering:
unsupported quantum-derived rotation angle`, or `cq controlled
lowering: rotation angle under quantum control` inside a tainted
region); the way to get an angle out of quantum data is an explicit
`cq_measure`.

Two operations that look like they should introduce taint but
deliberately do not:

- **`cq_phi` (the branch phase).** The surface is
  `void cq_phi(double θ)`: it has **no data operand at all**. So it
  introduces no taint and propagates none — there is nothing for
  taint to flow through. It multiplies the amplitude of the branch
  it sits in by `e^{iθ}`, and is ordered by the block it sits in
  rather than by a data dependence. Under a tainted condition it
  lowers by **kickback**: the condition is minted into a flag qubit
  and the phase goes on the flag (`cqrt_rz_i1(flag, θ)`,
  uncontrolled), with nothing applied to any data register.
  Uncontrolled or classically controlled it is a global phase and is
  deleted. The two-argument spelling `cq_phi(x, θ)` no longer
  exists; a use of the retired `cq_phi_<sfx>` names is a loud
  failure. See [`frontend.md`](./frontend.md) §3.3 and
  [`backend.md`](./backend.md) §6.1a.
- **Plain declarations.** An `int a = 3` is classical. There is no
  surface form that declares a variable "intended quantum" without
  invoking a gate: allocation is gate-triggered, not
  declaration-triggered.

### 4.2 Propagation through stock LLVM opcodes

Taint propagates by the **operand rule**: an SSA value `v`
produced by some instruction is tainted if any operand of that
instruction is tainted (except a rotation's angle operand, §4.1).
The rule is local (one instruction at a time), monotone (taint never
un-propagates), and forward (along SSA def-use).

Every LLVM data-carrying opcode is a propagation site:

| Opcode | Tainted iff |
|---|---|
| `add %x, %y` | `%x` or `%y` tainted |
| `mul %x, %y` | `%x` or `%y` tainted |
| `icmp <pred> %x, %y` | `%x` or `%y` tainted |
| `fadd %x, %y` | `%x` or `%y` tainted |
| `sext %x` (and other casts) | `%x` tainted |
| `fneg %x` | `%x` tainted |
| `phi` / `select` | any data operand is tainted (a **tainted condition** is a separate matter, §4.4) |
| `call @f(%a, %b)` | the return's taint follows the callee's specialization (§4.5); a function that returns a quantum handle also taints the result of each direct call to it |

The propagation runs on whatever IR Clang's `-O1` produces. There
is no requirement that the input be in any special form beyond
the standard `mem2reg` / `SROA` cleanup; the SSA def-use graph
that comes out of `-O1` is the data structure the rule walks.
(`-O1` is the validated pipeline: the control-flow shapes the pass
recognizes are the ones `-O1` produces.)

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

`cq_measure_<sfx>` lowers to `cqrt_measure_<W>(handle)`. The compiler
never frees a rail it has seen measured — the measurement owns it —
and never inserts a measurement the user did not write.

### 4.4 Quantum control flow — a tainted branch leaves the taint relation

A branch whose `i1 %cond` is tainted is a *quantum branch*: the
program is in a superposition of "taken" and "not taken." The
operand rule cannot describe what happens next, and the pass does
**not** try to extend it with a control-flow "shadow" of tainted
values. Instead a tainted `br` / `select` / `switch` is handed to a
**control emitter** (or fails loudly if none applies); which
emitter is decided by the class of the arm:

- a **phase arm** (`cq_phi(θ)`) is the register-free kickback of §4.1;
- a **rotation arm** (`cq_theta` on a register the condition does
  not read) is one controlled Ry on that register;
- a **value arm** (an arithmetic result) hoists the arm's pure
  chain into the predecessor so it runs unconditionally on the
  original registers, mints the condition into a flag qubit, and
  merges the answer into a fresh `|0⟩` rail by two controlled
  copies (the second bracketed by `cqrt_x` on the flag), then
  strips the flag back to `|0⟩` and frees it.

The motivating case is the merge of two classical literals:

```c
int q = cq_theta(a, 0.5);   /* q tainted */
int y;
if (q > 0) y = 10; else y = 20;
return cq_measure(y);
```

`y` is classical-by-operand at the merge (its two incoming values are
literals) yet semantically depends on the quantum branch. At `-O1`
the diamond becomes `%y = select i1 (icmp sgt %q, 0), i32 10, i32 20`,
and the lowered module (measured on the built `cq-opt`; regenerate
rather than trust this listing) is:

```llvm
%h     = call i32 @cqrt_alloc_i32(i32 %a)
         call void @cqrt_ry_i32(i32 %h, double 5.0e-01)
%h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 0)   ; the flag
%out   = call i32 @cqrt_alloc_i32(i32 0)                        ; fresh |0> rail
%selop = call i32 @cqrt_alloc_i32(i32 10)
         call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop, i32 %out)
         call void @cqrt_x(i32 %h_cmp)                          ; ¬flag bracket
%selop1= call i32 @cqrt_alloc_i32(i32 20)
         call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %selop1, i32 %out)
         call void @cqrt_x(i32 %h_cmp)
         call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 0)
         call void @cqrt_free(i32 %h_cmp)                       ; flag back to |0>
%m     = call i32 @cqrt_measure_i32(i32 %out)
```

The merged value is therefore a **fresh quantum rail** (`%out`), and
taint is re-seeded from it: control detection and lowering run to a
fixpoint with taint re-propagation in between, because each round's
emitters mint new quantum values that later stages must see. The
operand rule alone would have left the `select` classical. A tainted
`br` / `select` / `switch` that no emitter can lower fails loudly
(`… under quantum control`); it is never passed on as classical
control over quantum state.

There is no user-facing marker for control-flow taint. A plain C
`if (tainted_cond) { ... }` *is* the controlled region; the pass
recovers the region structurally, by matching its shape in the CFG
and SSA by value identity ([`backend.md`](./backend.md) §8.1). This is consistent with the design principle that the
boundary is implicit and follows the data — including the data
carried by branch conditions. What each emitter does and which
region shapes it accepts is in [`backend.md`](./backend.md) §6.1a and
§8.

### 4.5 Taint at function-call boundaries

A call instruction with any tainted argument is a *tainted call*.
What happens depends on what the pass can see of the callee:

- **A visible body** (user code, a linked library, or a library
  function whose real source has been injected before `cq-lowering`)
  is lifted by **clone-on-taint**. The pass clones the callee once
  per (callee, tainted-argument mask), seeds taint on the
  corresponding parameters, lowers the clone's body with the same
  rules as any other code, wraps it (forward stream, copy-out of the
  result onto a fresh rail, reverse of the forward stream), gives it
  internal linkage under a `__cq_q_<callee>_<mask>` name and
  retargets the call. The original function is untouched for
  classical callers. The call's result is tainted iff the clone
  returns a quantum value; §7 shows a measured example.
- **A curated `llvm.*` intrinsic** with a reversible template
  (bit manipulation, min/max, saturating arithmetic, the rotation
  form of funnel shifts, and the hardware-backed floating-point
  survivors) is lowered directly to a `cq_template_*` call.
  Membership is by exact `Intrinsic::ID`, never by name.
- **A library function such as `sin` or `pow`** is not recognized by
  name. Its real implementation is compiled from injected source, so
  the pass sees stock opcodes (NORTHSTAR goal 2).
- **A callee with no visible or injected body** and a tainted
  argument fails loudly (`cq taint escape: tainted value consumed by
  an unknown callee`): there is no implementation to lift, which is
  one of the closed physics reasons in NORTHSTAR goal 1.

---

## 5. Mixed-operand semantics (Q + C)

The most common kind of tainted instruction is one with mixed
operands: one tainted (a handle) and one classical (a literal or
another untainted SSA value). How those are lowered is one of the
load-bearing decisions of the design.

### 5.1 The operand shapes the pass recognizes

For a tainted binary opcode like `add i32 %x, %y`, the pass
classifies the operand shape by **taint membership** (not by
`isa<Constant>`: a classical function argument is as classical as a
literal):

| Shape | LHS | RHS | Template |
|---|---|---|---|
| **QQ** (handle, handle) | tainted | tainted | `cq_template_add_i32(h_x, h_y)` |
| **HL** (handle, literal) | tainted | classical | `cq_template_add_i32_hl(h_x, c)` |
| **LH** (literal, handle) | classical | tainted | commutative opcodes are canonicalized to HL; non-commutative ones (`sub`, shifts, `fsub`, `fdiv`, …) use `cq_template_<op>_<W>_lh(c, h)` with source order preserved |
| classical, classical | classical | classical | left alone (stock LLVM `add`) |

Integer and floating-point compares have QQ and HL forms only: a
classical left operand is canonicalized by flipping the predicate
(`5 < x` ⇒ `x > 5`), so there is no `_lh` compare. The runtime
ABI is width-only: signedness lives in the opcode or predicate the
pass reads (`add nsw` vs `nuw`, `icmp slt` vs `ult`) and is stripped
before the runtime sees it, and every handle is an `i32`.

The shape decision is local to the instruction; no global analysis
is needed beyond the taint classification already in hand from §4.
The symbol grammar is
`cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>][_hl|_lh][_controlled][_inv]`
plus a void `_unc` twin per forward symbol; `tools/opcode_table.yaml`
is its single source of truth.

### 5.2 The classical operand is not promoted to a handle

In opcode lowering (arithmetic, compares, casts) **the classical
operand is passed to the runtime as a literal, not allocated onto a
fresh qubit register.** The lowering does *not* look like this:

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

Two reasons carry the rule:

1. **A classical operand has no superposition to carry.** Promoting
   it would spend a qubit register on a value that is the same on
   every branch.
2. **The runtime ABI is built around operand shape.**
   `cq_template_add_i32` and `cq_template_add_i32_hl` are different
   symbols with different signatures, generated from the same table
   ([`backend.md`](./backend.md) §12.2); the pass passes the right
   shape through.

Any new template op follows the same pattern: distinct runtime entry
points per operand shape, dispatched by the pass on taint membership,
never promoting classical operands to handles.

**Where a classical value *is* materialized on a rail.** The rule is
about opcode lowering, not about every place a classical value meets
quantum data. A rail is born from a classical seed (`cq_theta`,
§4.1), and the merge of a quantum branch copies *from handles*: in
the example of §4.4 the literals `10` and `20` are each allocated
onto a temporary rail (`cqrt_alloc_i32(10)`) that serves as the copy
source of `cqrt_copy_i32_controlled`.

### 5.3 The classical operand's flow is preserved

A classical SSA value passed to an `_hl` template stays classical
throughout. Its uses outside the template call are unchanged; the
template call is just another use. The pass inserts no allocation,
no rebinding, and no handle wrapper for the classical side (the
`%4 = sitofp i32 %2 to double` of §7 stays an ordinary classical
instruction and is handed to `cq_template_fdiv_f64_hl` as a
`double`).

---

## 6. Conversion semantics — representation, never measurement

Type conversion at the LLVM-IR level — `sext`, `zext`, `trunc`,
`fpext`, `fptrunc`, `sitofp`, `uitofp`, `fptosi`, `fptoui` — is a
**representation change**. It says how a numerical value is
encoded in bits; it says nothing about whether those bits live on
classical transistors or quantum qubits. Under taint, every cast
opcode whose (opcode, width) pair has a template lowers to that
quantum cast template; none of them is ever a measurement. A pair
with no template is a loud failure — a gap to fill, not a
measurement in disguise.

### 6.1 The principle

**Substrate is a property of the SSA value; representation is a
property of the operation.** Two values with the same C type
(`int` and `int`) can differ in substrate (one tainted, one not);
two values with different C types (`int` and `double`) may share
substrate (both tainted, both on qubits) or not, but the
conversion between them is a representation operation regardless
of substrate.

| | int → int | int → double | double → int |
|---|---|---|---|
| **Classical operand** | stock `sext` / `zext` / `trunc` | stock `sitofp` / `uitofp` | stock `fptosi` / `fptoui` |
| **Tainted operand** | `cq_template_<cast>_<from>_to_<to>` | `cq_template_sitofp_…` | `cq_template_fptosi_…` |

### 6.2 What a quantum cast template does

`cq_template_sitofp_i32_to_f64(handle_int)` is an **additive
producer**: it returns a fresh handle at the target representation
and leaves the source register intact. Conceptually it maps the bits
of the source register onto the target register by the conversion's
mathematical rule, without observing the state. The whole-DAG
uncompute pass later emits the template's `_unc` twin and frees the
produced rail at its post-dominator, and only where the rail is
provably back to `|0⟩` (a rail it cannot prove is left allocated,
never freed dirty). At no point is the register measured.

The runtime that ships today is a **trace backend**: each `cqrt_*`
and `cq_template_*` call prints one line, and the golden trace is the
contract. The gate-level bodies of the cast templates are not
implemented; their declarations are generated into
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
   worrying that the caller has tainted `x`.
2. **Measurement is syntactically obvious.** Every measurement the
   user wants is spelled `cq_measure(...)`, and the compiler inserts
   none of its own. A reviewer can grep for them. There is no flag,
   attribute, or syntactic form that turns a cast into a
   measurement.
3. **Cast chains compose.** `(int)(double) q` and
   `(double)(int) q` are both legal under taint; each cast
   lowers to a quantum template and neither collapses the state.

A cast inside a quantum-controlled arm is still a cast: a value
arm's pure chain — casts included — is hoisted and runs
unconditionally on the original registers, and only the merge copy
is controlled (§4.4).

---

## 7. The function-lifting consequence

The boundary's most important downstream consequence is that
**classical functions lift to quantum callers without modification
and without surprise.** Take the callee of §3, called with two
tainted arguments and one classical one, and keep it out of line so
that the lifting path is visible:

```c
__attribute__((noinline))
double average(double a, double b, int n) { return (a + b) / (double) n; }

double f(int n) {
    double q1 = cq_theta(1.0, 0.5);
    double q2 = cq_theta(2.0, 0.3);
    return cq_measure(average(q1, q2, n));
}
```

At `-O1` the callee is `fadd`, `sitofp i32 %n to double`, `fdiv`. The
lowered module (measured on the built `cq-opt`; regenerate rather
than trust this listing) contains, besides the untouched original
`@average`, the clone for the mask "arguments 0 and 1 tainted":

```llvm
define internal i32 @__cq_q_average_011(i32 %0, i32 %1, i32 noundef %2) {
  %h_op  = call i32 @cq_template_fadd_f64(i32 %0, i32 %1)          ; QQ
  %4     = sitofp i32 %2 to double                                 ; classical, untouched
  %h_op1 = call i32 @cq_template_fdiv_f64_hl(i32 %h_op, double %4) ; HL: literal stays a literal
  %cqq.out = call i32 @cqrt_alloc_f64(double 0.0)
  call void @cqrt_copy_f64(i32 %h_op1, i32 %cqq.out)               ; copy-out
  call void @cq_template_fdiv_f64_hl_unc(i32 %h_op1, i32 %h_op, double %4)
  call void @cq_template_fadd_f64_unc(i32 %h_op, i32 %0, i32 %1)
  call void @cqrt_free(i32 %h_op)
  call void @cqrt_free(i32 %h_op1)
  ret i32 %cqq.out
}
```

(Without `noinline`, `-O1` inlines the small callee and the same
three instructions are lowered in place in `@f`.)

Three things happen automatically:

1. **`n` and `(double) n`** never receive taint: no operand in
   their definition chain is tainted. The `sitofp` is a classical
   instruction on a classical operand, so the pass leaves it alone —
   no template, no measurement.
2. **`fadd`** is QQ and lowers to `cq_template_fadd_f64`.
   **`fdiv`** is HL: tainted handle on the left, classical `double`
   on the right. The classical operand is passed as a value; no
   `cqrt_alloc_f64` is inserted for it.
3. **The clone is Bennett-wrapped**: the answer is copied onto a
   fresh rail, and the forward stream is run backwards so the
   intermediates return to `|0⟩` before being freed. The caller
   receives a tainted handle and no measurement happened inside the
   body.

The author of `average` needed to know nothing about CQ to write a
function that works for both classical and quantum callers.

### 7.1 The properties guaranteed to library authors

A function author writing C code can rely on:

1. **Cast neutrality.** `(int) x`, `(double) y`,
   `(short)(int) z`, and similar conversions inside a function
   body do not measure. If the caller passes tainted arguments,
   conversions become quantum representation changes; if the
   caller passes classical arguments, they are stock LLVM casts.
2. **Constant safety.** A literal anywhere inside a function body
   (`int count = 2`, `* 1.5`) is classical. Its uses contribute
   classical operands to mixed operations; the `_hl`/`_lh` lowering
   keeps the literal as a literal across the runtime ABI.
3. **Arithmetic ubiquity.** Stock `+`, `-`, `*`, `/`, comparisons,
   shifts, and bitwise operations all work on tainted operands
   without source modification. The pass lowers them to template
   calls via the same mechanism that classified them as
   quantum — taint propagation on stock LLVM opcodes.
4. **Composition with libraries.** A `math.h` function lifts because
   its real source is injected and lowered like any other body
   (NORTHSTAR goal 2); a curated `llvm.*` intrinsic lowers to its
   template (§4.5).

The fundamental promise the boundary mechanism makes — *write
your library once, in plain C, and it lifts* — is what the
design exists to keep.

---

## 8. Cross-references

| Concern | Where it is documented |
|---|---|
| Plan of record: goals, closed list of valid declines, design principles | [`../NORTHSTAR.md`](../NORTHSTAR.md) |
| User-facing intrinsic surface (`cq_theta`, `cq_phi`, `cq_measure`, `cq_invert_*`) | [`frontend.md`](./frontend.md) §3, `include/CQ.h` |
| IR-pass mechanism that computes taint (data-flow algorithm) | [`backend.md`](./backend.md) §4 |
| Allocation lowering, including the `_hl` runtime entry-point dispatch | [`backend.md`](./backend.md) §5, §6.2 |
| Branch phase by kickback; control-flow lowering | [`backend.md`](./backend.md) §6.1a, §8 |
| Template library and the generated declaration set | [`backend.md`](./backend.md) §12, `tools/opcode_table.yaml` |
| Function-lifting paths (clone-on-taint, curated intrinsics) | [`backend.md`](./backend.md) §7 |
| Stock LLVM C++ APIs the pass uses | [`llvm-implementation.md`](./llvm-implementation.md) |
| End-to-end worked example, source → lowered IR | [`example.md`](./example.md) |
