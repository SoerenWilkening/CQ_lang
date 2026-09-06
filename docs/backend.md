# CQ Backend — IR Pass and Runtime

What the compiler does with the LLVM IR the frontend hands off, and
what the compiled binary calls into at runtime. The backend under the
taint-driven design carries most of the project's compiler weight: a
single LLVM-pass module that drives forward taint propagation,
allocation insertion, opcode lowering, call-graph specialization,
controlled-form lowering, and per-op uncomputation, plus a runtime
library exposing a small handle-based ABI.

Companion documents:
- [`frontend.md`](./frontend.md) — what the user writes and what the
  Stage 4 bitcode coming into the pass actually looks like
- [`quantum-classical-handling.md`](./quantum-classical-handling.md) —
  taint as the Q/C boundary, mixed-operand semantics, classical
  short-circuits
- [`llvm-implementation.md`](./llvm-implementation.md) — the stock
  LLVM C++ APIs every mechanism in this document depends on
- [`rationale/proposal-taint-driven-pipeline.md`](./rationale/proposal-taint-driven-pipeline.md)
  — the proposal that motivated the current design; explains why the
  old `qint_mid_t` / `cq_init_*` / `cq_when_*` surfaces were retired
- [`example.md`](./example.md) — end-to-end worked walkthrough of a
  small program through the pass

---

## 1. Scope

This document defines:

- The Stage 4 LLVM IR **input contract** the backend expects
- The **forward taint propagation** analysis that drives every
  subsequent step
- **Allocation lowering** — when and where `cqrt_alloc_<W>` calls are
  inserted; how operand state dispatches
- **Opcode lowering** — how tainted stock LLVM opcodes (`add`, `mul`,
  `fcmp`, `sitofp`, …) become `cq_template_<opcode>_<width>` calls,
  and how mixed Q+C operands route through `_hl` variants
- **Call-graph specialization** — the two lifting paths (curated
  symbol substitution and clone-on-taint) that let plain C functions
  participate in tainted call chains without modification
- **Controlled-form lowering** — recovering the quantum-control region
  structurally from `PostDominatorTree` rather than from user-emitted
  region brackets
- **Per-op uncomputation** — emitting adjoint gate sequences at SSA
  last-use points
- **Adjoint generation** — mechanically deriving inverses from forward
  templates so the backend ships forward + controlled only
- **Manual inversion** — what `cq_invert_begin` / `cq_invert_end`
  lower to
- The **runtime ABI** — the handle pattern, the 15 `cqrt_*` lowering
  targets, the quantum primitives, the gate primitives
- The **template library** — the reversible-circuit primitives the IR
  pass substitutes for tainted stock LLVM opcodes
- The **compilation flow** at Stages 2 and 3

It does **not** define:

- The user-facing intrinsic surface (`cq_theta`, `cq_phi`,
  `cq_measure`, `cq_invert_*`) — see [`frontend.md`](./frontend.md) §3
- Specific opcode-template circuit families (ripple-carry vs.
  Cuccaro vs. Draper; Karatsuba vs. schoolbook multiplier; etc.) —
  deferred to backend-implementation time
- Simulator internals (statevector representation, gate-counter
  bookkeeping) — runtime-variant concerns

---

## 2. What the backend is, and what it is not

Under the taint-driven design, the backend is where the compiler does
its real work. Concretely:

- **One IR-pass module** that runs after Clang's `-O1` cleanup and
  before standard codegen. Builds against stock LLVM 19 as an
  out-of-tree pass plugin (`opt -load-pass-plugin libCQPass.so`); no
  patches to `llvm-project`, no vendored fork.
- **One runtime library** (`libcq_runtime`) exposing a small
  handle-based ABI (~15 symbols plus gate primitives). The pass
  lowers the IR into calls against this ABI; the linked binary at
  execution time hands control to one chosen runtime variant.
- **A template library** (`libcq_templates`) that maps stock LLVM
  opcodes at each applicable width to reversible-gate templates.
  Declared in [`runtime/cq_templates.h`](../runtime/cq_templates.h);
  the actual template bodies are deferred (Phase 11 freeze of the
  frontend precedes any real-gate-sequence implementation).

What the backend is **not**:

- A separate optimizer that competes with stock LLVM. The pass
  operates on stock SSA, leaves classical code alone, and inherits
  every classical optimization Clang already ran.
- A simulator. The runtime hands gate sequences to whatever output
  target it is bound against (gate counter, simulator state). The
  compiler does not assume any particular execution semantics.
- A whole-function transformer. Uncomputation is per-op, derived
  from per-value SSA provenance — not Bennett-style whole-call
  wrap-around. Bennett's construction is used only at one
  load-bearing point (call-graph specialization synthesis at the
  boundary between CQ source and externally-defined callees, §7).

The no-fork claim was validated 2026-05-22 by a working prototype
at [`../archive/prototype/`](../archive/prototype/) — four passes covering taint
propagation, lowering, post-dominator uncomputation, function
cloning, and region substitution, all on stock LLVM 19.1.7. The
prototype is per-mechanism validation; the production pass at
[`../ir-pass/`](../ir-pass/) integrates the same mechanisms behind a
single `cq-lowering` driver.

---

## 3. Input contract — Stage 4 LLVM IR

What the backend receives from the frontend after `clang -O1
-emit-llvm -include CQ.h`:

### 3.1 IR shape

- Stock LLVM IR. No custom opcodes, no MLIR dialect, no LLVM fork.
- Standard SSA form, post-`mem2reg` / post-`SROA`.
- Plain integer (`i1`/`i8`/`i16`/`i32`/`i64`) and floating-point
  (`float`/`double`) SSA values throughout. **No `qint_mid_t` or
  related struct chains** — the retired mid-level type surface is not
  present in the new design.
- `@cq_theta_<sfx>`, `@cq_measure_<sfx>` and the register-free
  `@cq_phi(double)` calls preserved as opaque external calls. Their
  declarations are side-effecting (no `readnone`, no `readonly`) so LLVM
  does not CSE / DCE them.
- `@cq_invert_begin` / `@cq_invert_end` bracket-marker calls at
  module-level call sites where the user explicitly bracketed a
  region.
- Source-location debug info via `!dbg` metadata, preserved through
  the standard `-O1` pipeline, available to the pass for
  user-source-term diagnostics.

### 3.2 What the pass recognizes

| Call | Pattern-matched as | What the pass does |
|---|---|---|
| `@cq_theta_<sfx>(x, θ)` | Ry rotation; taint **source** | §5 allocation dispatch + lowering to `cqrt_ry_<W>` |
| `@cq_phi(φ)` | **Branch phase**; introduces and propagates **nothing** (no data operand) | **Kickback** under a tainted condition: flag mint + `cqrt_rz_i1(f, φ)` + strip + free; **deleted** when uncontrolled or classically controlled (§6.1a) |
| `@cq_measure_<sfx>(x)` | Measurement; taint **sink** | §6.5 lowering to `cqrt_measure_<W>` |
| `@cq_invert_begin()` / `@cq_invert_end()` | Manual inversion bracket | §10 substitute the bracketed gate sequence with its adjoint |

> **`@cq_phi` is matched by EXACT name, not by prefix** (bd
> `test_C_libtooling-3qlq.2`, Increment 1, SHIPPED 2026-09-05). The
> required prototype is `void(double)`; any other prototype on that name
> declines loudly with
> `cq rotation lowering: unsupported declared prototype for cq_phi`, whether
> or not it is called. The retired 15-width `@cq_phi_<sfx>(x, φ)` family is
> **no longer resolved by the pass at all** — see §6.1a for what actually
> happens to a module that still contains one.

Identification for the two suffixed families is by symbol-prefix string
match on `CallInst::getCalledFunction()->getName()`. The fan-out of suffixes
covers the 14 standard C scalar types the frontend enumerates (see
[`frontend.md`](./frontend.md) §3.1); the pass normalizes
signedness-bearing suffixes (`_si32` vs `_ui32`) to width-only
runtime symbols (`cqrt_alloc_i32`), since the runtime ABI is
width-only by design.

### 3.3 What is deliberately not in the input

| Surface | Status | Why |
|---|---|---|
| `qint_mid_t` / `q*_mid_t` struct types at signatures | Retired | Allocation is gate-triggered (§5); declaration-time struct chains no longer carry the taint signal — `mem2reg`-friendly plain SSA does |
| `@cq_init_<W>` calls | Retired | Replaced by `@cq_theta` as taint source; the rotation site *is* the initialization site |
| `extractvalue` / `insertvalue` chains around `qint_mid_t` | Absent by construction | Nothing to extract from; no struct wrappers in the IR |
| `@cq_when_begin` / `@cq_when_end` calls | Retired | Controlled regions recovered structurally from tainted `br i1` conditions (§8) |
| `__cq_q_<f>_<mask>` mangled specialization calls at the input | Absent | Specialization synthesis is internal to the pass (§7); the input has plain calls to `@f`, the pass clones and retargets |

A pass that finds any of the retired surfaces in its input has
encountered legacy IR; the production pipeline emits none of them.

---

## 4. Forward taint propagation

The first analysis the pass runs, and the substrate every subsequent
step is built on. Standard data-flow over SSA values, monotone,
single sweep over the SSA DAG.

### 4.1 Sources, sinks, propagation rule

```
taint_sources = {
    return value of any @cq_theta_<sfx> call,
}

taint(v) = true iff
    v ∈ taint_sources, OR
    any operand of v's producing instruction is tainted, OR
    v is defined in the dominated shadow of a tainted branch (§8)

taint_sinks = {
    @cq_measure_<sfx> call sites,    // return value is classical
}
```

`cq_phi` is excluded from the source set, and since Increment 1 it is
excluded from the **propagation** relation too — it has no data operand
to propagate through. `void cq_phi(double φ)` is a *branch phase*: it
multiplies the amplitude of the branch it sits in by `e^{iφ}`, so it is
ordered by the **block it sits in**, not by any data dependence. It
introduces no taint (a phase is not superposition), propagates none, and
allocates nothing. Its one operand is the **angle**, which is classical;
a quantum-derived angle declines loudly
(`cq rotation lowering: unsupported quantum-derived rotation angle`, and
`cq controlled lowering: rotation angle under quantum control` inside a
tainted region).

`cq_measure_<sfx>` is the sole sink: every measure call's return value
is classical regardless of input. Downstream uses of the returned
value are classical SSA — classical arithmetic, classical control
flow — and are left alone by every subsequent step.

### 4.2 What the propagation gives the rest of the pipeline

After taint analysis the pass holds, per function:

- A set of tainted SSA values (handles after lowering, but
  pre-lowering: plain `i32`/`f32`/`f64` etc.).
- A set of tainted call sites — call instructions where at least one
  argument is tainted. These drive §7 specialization.
- A set of tainted branch conditions (`br i1 %cond` where `%cond` is
  tainted). These drive §8 controlled-form lowering.

No tainted instruction is yet rewritten. The pass passes through
again to perform allocation insertion (§5), template substitution
(§6), specialization synthesis (§7), region lowering (§8), and
uncomputation (§9), each driven by the same single-pass taint
classification.

### 4.3 Why this works on stock LLVM SSA

`Value::users()`, `Instruction::operand_values()`, and worklist-based
data-flow are stock LLVM APIs available from the new PassManager.
The Phase 2 prototype validates the mechanism end-to-end against
LLVM 19.1.7; no LLVM source modifications and no special
instrumentation are required (see
[`llvm-implementation.md`](./llvm-implementation.md) §2.5).

The single-pass property is important: a tainted `add i32` is a
tainted `add i32` regardless of whether its operands come from a
direct `cq_theta` call, from a cloned-callee body, or from arithmetic
on a previously-tainted intermediate. The same propagation runs
inside cloned bodies during specialization (§7.3); no special
machinery is needed to re-classify after a clone.

---

## 5. Allocation lowering

Under the taint-driven design, qubit allocation is **gate-triggered**:
a `cqrt_alloc_<W>` call is inserted only at `@cq_theta_<sfx>` call
sites whose operand is still classical at lowering time. A variable
that is declared, mutated arithmetically, and never rotated never
touches the qubit substrate.

### 5.1 The dispatch rule at `@cq_theta` call sites

For each `@cq_theta_<sfx>(operand, θ)` call discovered in §4:

- If `operand` is classical (not in the tainted set): **insert
  allocation**. Emit `%h = call i32 @cqrt_alloc_<W>(operand)`
  immediately before the theta call, then lower the theta call to
  `cqrt_ry_<W>(%h, θ)`. The theta call's return SSA value `%v`
  becomes `%h` (the handle); every downstream use is rebound.
- If `operand` is tainted: **no allocation**. The operand is already
  a handle; lower the theta call directly to
  `cqrt_ry_<W>(operand, θ)`. The return SSA value continues to
  reference the same handle.

Pre-lowering example (classical operand):

```llvm
; before
%a1 = call i32 @cq_theta_si32(i32 %a, double 5.0e-01)
```

```llvm
; after
%h_a = call i32 @cqrt_alloc_i32(i32 %a)            ; allocate, init to %a
call void @cqrt_ry_i32(i32 %h_a, double 5.0e-01)   ; Ry(0.5)
; downstream uses of %a1 are replaced by %h_a
```

Pre-lowering example (tainted operand, chained rotation):

```llvm
; before — %h_a is already a handle from a prior allocation
%a2 = call i32 @cq_theta_si32(i32 %h_a, double 3.0e-01)
```

```llvm
; after — no new allocation
call void @cqrt_ry_i32(i32 %h_a, double 3.0e-01)   ; Ry(0.3) on existing register
; downstream uses of %a2 are replaced by %h_a
```

### 5.2 Why dispatch on operand state

This dispatch is the structural mechanism behind the "register is
allocated exactly once on first rotation" guarantee the frontend
documents (see [`frontend.md`](./frontend.md) §3.2). A user who
writes `a = cq_theta(a, 0.1); a = cq_theta(a, 0.2);` allocates once
and rotates twice; the pass sees the same dispatch rule fire twice,
once with classical `%a` and once with tainted `%h_a`.

The classical-operand case is also the bridge between gate-triggered
allocation and the runtime's classical-shadow tracking: the value
passed to `cqrt_alloc_<W>` is the integer (or float) bit pattern at
the moment of first rotation, which the runtime uses to seed the
register's classical interpretation (`qreg_state_t.value` per §11.5).

### 5.3 What this replaces

Under the prior design, allocation was declaration-triggered:
`quantum int a;` emitted a `@cq_init_i32(0)` call that the IR pass
unconditionally lowered to `cqrt_alloc_<W>`. Variables declared
quantum but never rotated still consumed qubits. The new design's
gate-triggered scheme removes that source of over-allocation, at no
cost — the dispatch rule is one extra branch per `@cq_theta` call
site.

Mid-handle rebinding (the old [`docs/archive/old-design/backend.md`](./archive/old-design/backend.md)
§4 step that walked `extractvalue`/`insertvalue` chains around
`qint_mid_t` structs to expose the underlying `i32`) is similarly
retired. The new frontend never emits the wrapping; the SSA the pass
sees is already plain `i32` from the `@cq_theta` return.

---

## 6. Opcode lowering and mixed-operand dispatch

After taint analysis identifies tainted stock LLVM opcodes, the pass
substitutes each one with a call to the corresponding template
function. Templates are declared in
[`runtime/cq_templates.h`](../runtime/cq_templates.h) (autogenerated
from `tools/opcode_table.yaml`); the pass picks the right symbol
based on opcode + width + operand shape.

### 6.1 The lowering map

| Tainted opcode / intrinsic | Lowered |
|---|---|
| `call @cq_theta_<sfx>` (classical operand) | `cqrt_alloc_<W>(value)` + `cqrt_ry_<W>(handle, θ)` (§5.1) |
| `call @cq_theta_<sfx>` (tainted operand) | `cqrt_ry_<W>(handle, θ)` (§5.1) |
| `call @cq_phi` inside a **tainted-condition** arm | **kickback** — flag mint, `cqrt_rz_i1(f, φ)` *uncontrolled* on the flag, compare `_unc` strip, `cqrt_free(f)` (§6.1a) |
| `call @cq_phi` uncontrolled, or under a **classical** condition | **deleted** — a global phase, unobservable (owner decision D2; a documented semantic, no diagnostic) |
| `call @cq_measure_<sfx>` | `cqrt_measure_<W>(handle) → value` |
| tainted `add i<W> %a, %b` (H+H) | `cq_template_add_i<W>(%h_a, %h_b)` |
| tainted `add i<W> %a, C` (H+C) | `cq_template_add_i<W>_hl(%h_a, C)` |
| tainted `mul i<W>` | `cq_template_mul_i<W>{,_hl}` |
| tainted `icmp <pred> i<W>` | `cq_template_icmp_<pred>_i<W>{,_hl}` |
| tainted `fadd f<W>` | `cq_template_fadd_f<W>{,_hl}` |
| tainted `fcmp <pred> f<W>` | `cq_template_fcmp_<pred>_f<W>{,_hl}` |
| tainted `sext`/`zext`/`trunc`/`fptrunc`/`fpext` | `cq_template_<cast>_<from>_to_<to>` |
| tainted `sitofp`/`uitofp`/`fptosi`/`fptoui` | `cq_template_<cast>_<from>_to_<to>` |
| tainted `fneg f<W>` | `cq_template_fneg_f<W>` |
| `@cq_invert_begin` … `@cq_invert_end` brackets | inner gate sequence reversed + adjointed per §10 |

After lowering, the IR contains no `@cq_theta_*` / `@cq_measure_*` calls,
no `@cq_phi` call and no tainted stock opcodes — only `cqrt_*` runtime
calls and `cq_template_*` template calls, with classical control flow
threading them.

### 6.1a `@cq_phi` — the branch phase by kickback

> **Increment 1 of bd `test_C_libtooling-3qlq`, SHIPPED 2026-09-05.** What it
> REPLACED, for readers of older traces and older docs: the retired
> `@cq_phi_<sfx>(x, φ)` lowered to a routed or controlled `cqrt_rz_<W>`, which
> is TENSORED and therefore not an oracle — every Grover golden in this tree
> before that date is the identity on `q`. See §11.3 and
> `retire-swap-route-PRD.md` §1.

`void @cq_phi(double φ)` carries **no register**. It is recognized by
**exact symbol name** (never by prefix) and its prototype must be
`void(double)`; anything else on that name is a loud decline
(`cq rotation lowering: unsupported declared prototype for cq_phi`), fired
whether or not the declaration is called, on the same reserved-name rule
the suffixed families use.

**Under a tainted condition it lowers by kickback**, on the flag the
control path already mints for the compare — no work rail, no
`cqrt_cswap` route, and no `_controlled` gate:

```
mint     cq_template_icmp_<pred>_i<W>_hl(h, k)   -> f    ; f = c(q) on a |0> ancilla
gate     cqrt_rz_i1(f, φ)                                ; UNCONTROLLED, one qubit
strip    cq_template_icmp_<pred>_i<W>_hl_unc(f, h, k)    ; f back to |0> on EVERY branch
free     cqrt_free(f)
```

Three shapes follow from that, and each is a distinct accept. Counts below
are MEASURED from the accept fixtures named beside them.

- **A `¬flag` arm** — the gate arm is the *false* successor, which is what
  `clang -O1` usually produces (Rule 9) — keeps the self-inverse `cqrt_x(f)`
  bracket around the gate, exactly as every other `¬flag` arm does. The
  bracket is **one pair per arm**, never per gate. ⚠ *Per arm, not per
  region*: a merge-tail angle φ contributes its own arm-polarity groups, so
  one region can legitimately emit more than one pair (measured, 4 `cqrt_x`
  from plain C). `control_phase_kickback_negated.ll`: 1 `cqrt_rz_i1`, 2
  `cqrt_x`, 1 `cqrt_free`.
- **`if/else`** puts **one gate per arm** on the **one** minted flag — the
  true arm's `cqrt_rz_i1(f, φ_T)` as-is, the false arm's inside the `cqrt_x`
  bracket — with one mint, one strip and one free for the pair.
  `control_phase_kickback_ifelse_tail_phi.ll`, whose arm also carries its own
  `cq_phi`: 3 `cqrt_rz_i1`, 2 `cqrt_x`, **1** `cqrt_free`.
- **N `cq_phi` calls in one arm** emit **N** `cqrt_rz_i1` gates on that one
  flag, in source order, still with one mint / strip / free and one bracket
  pair. Nothing is summed at compile time: each angle is passed through
  verbatim and `P(φ₁)·P(φ₂) = P(φ₁+φ₂)` happens in the hardware, so the
  IEEE-rounding hazard that constrains the *Ry* angle-select path does not
  arise here. `control_phase_kickback_two_calls.ll`: 2 `cqrt_rz_i1`, 0
  `cqrt_x`, 1 `cqrt_free`.

**Beyond the single compare, the shape of the CONDITION changes only what
the flag is MADE OF, never the gate.** A compound condition
(`if (q == 5 && r == 3) cq_phi(θ)`) mints one leaf flag per tainted compare
and combines them into a root ancilla — `cqrt_toffoli` for AND, the OR and
XOR node emissions the 4.4 select merge already had — puts the ONE
`cqrt_rz_i1` on that root, and tears the network down LIFO. A genuine
depth-2 **nest** (`if (a) { if (b) { cq_phi(θ); } }`) is the same thing
reached by a different syntax: the outer arm's phases ride the outer root,
the inner arm's ride the conjunction ancilla. A **`switch`** puts one
per-case eq-flag under each arm's gate. There is no route and no work rail
anywhere in that list.

**The real traces, from committed goldens.** The gate stream above is not a
sketch — read it off `tests/e2e/*.expected.log`:

```
# slice_control_seq_grover — the flat diamond, un-negated arm (P1)
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_rz_i1(h1, 0x1.921fb54442d18p+1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)

# slice_control_phase_angle_select — the folded if/else (P2): TWO gates,
# ONE flag, the false arm's inside the cqrt_x bracket, NO subtraction
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_x(h1)
cqrt_rz_i1(h1, 0x1.3333333333333p-2)
cqrt_x(h1)
cqrt_rz_i1(h1, 0x1.ccccccccccccdp-1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)

# slice_control_phase_nest — the depth-2 nest (P4): leaf flags, a toffoli
# conjunction ancilla, ONE gate on it, LIFO teardown
cq_template_icmp_eq_i32_hl(h0, 5) -> h2
cq_template_icmp_eq_i32_hl(h1, 3) -> h3
cqrt_alloc_i1(0) -> h4
cqrt_toffoli(h2, h3, h4)
cqrt_rz_i1(h4, 0x1.3333333333333p-2)
cqrt_toffoli(h2, h3, h4)
cqrt_free(h4)
cq_template_icmp_eq_i32_hl_unc(h3, h1, 3)
cqrt_free(h3)
cq_template_icmp_eq_i32_hl_unc(h2, h0, 5)
cqrt_free(h2)
```

⚠ That last stream is worth one more sentence, because it is a committed
`compare_files` gate and not a coincidence: `slice_control_phase_nest.c`
(the nest) and `slice_control_phase_andcond.c` (`if (a == 5 && b == 3)`)
produce **byte-identical goldens** — ONE trace, two sources
(`e2e-phase-nest-andcond-identical`). The nest is not a separate mechanism;
it is the condition tree reached by a different syntax.

**Uncontrolled — or classically controlled — `@cq_phi` is deleted.** It
multiplies the whole state vector by a scalar, which no measurement can
observe. This is a documented semantic and **not** a diagnostic (owner
decision D2): the program is fine, and nothing is printed.

**The emitted gate is not adjointable.** The uncompute spine must never
reverse-play a kickback gate: its inverse would cancel the very phase that
is the answer, and the flag it sits on is stripped and freed inside the
region. Emitted kickback gates therefore carry an instruction-metadata
membership record (`!cq.branchphase`) that the spine's in-place-gate,
basis-preservation and `EmitInverse` predicates refuse first. Read the
`cqrt_rz(q, φ) → cqrt_rz(q, −φ)` row in §10's adjoint table with that
exception. The record is deliberately *instruction metadata* rather than a
`Value *` set built at emission time: it dies with its instruction (so it
cannot dangle when a later stage RAUWs or erases), it survives
`CloneFunctionInto` (Phase-6 specialization), and it is visible in the
lowered `.ll` that fixtures and `free_pairing_check.py` actually read. It is
also asked as **membership of the emitted instruction**, never by name —
`cqrt_rz_i1` alone does not identify a kickback gate. Every emitted kickback
gate carries it (measured: the `!cq.branchphase` count equals the
`cqrt_rz_i1` count in `control_phase_kickback_{diamond,negated,two_calls,
ifelse_tail_phi}.ll` — 1, 1, 2 and 3 respectively).

**The retired `@cq_phi_<sfx>` family is a RESERVED NAME — measured 2026-09-05
on the merged Increment-1 tree.** `CQ.h` no longer declares it, so it can only
reach the pass from hand-written IR or a **stale header**. Any **USE** of it
is a loud decline, whatever the prototype and whatever the operands:

| module contains | disposition |
|---|---|
| `@cq_phi_<sfx>(%tainted, φ)` — arg-0 stays tainted | **loud decline**, `cq rotation lowering: retired register-form cq_phi_si32; use the register-free void cq_phi(double)` |
| `if (q == k) q = cq_phi(q, φ)` on a stale header, where `clang -O1` **const-folds** arg-0 to the classical `k` — so nothing about the call is tainted | **loud decline**, the SAME string |
| a **wrong-prototype** declaration of `@cq_phi_<sfx>` that is CALLED | **loud decline**, the SAME string (it precedes prototype validation) |
| a declaration of `@cq_phi_<sfx>` with **no call site**, right or wrong prototype | **silent, exit 0** — swept. See the narrowing below |

⚠ **The second row is the one that matters, and it was a CONFIRMED silent
miscompile until the Increment-1 round-1 review** (finding F-L6-1). The
boundary is one character wide and the flagship customer was on the wrong
side of it: the other spellings used to decline through
`declineTaintEscapes`, which fires only on a TAINTED OPERAND, and for the
Grover oracle `if (q == 5) q = cq_phi(q, PI)` `clang -O1` const-folds arg-0
to a classical `i32 5` on the equality edge, so that guard structurally
could not fire. The retired call was still CLAIMED as an arm gate by prefix
and never lowered: `opt` exited 0, verify-clean and STRICT stage-2b clean,
the flag was minted / stripped / freed, **the phase gate was DROPPED**, and
an unresolved call was left in the module for `ld` to find. That is Rule 1's
"no third path", violated. Two things fix it: `resolveSources` declines any
USE under the reserved-name string above, and `declineSurvivingIntrinsicCalls`
runs at the END of both pipeline entry points and turns this document's own
postcondition — *no `@cq_theta_<sfx>` / `@cq_phi_<sfx>` / `@cq_measure_<sfx>`
remains in the IR after this pass* — from a comment into a **checked, LOUD**
property. Loud and not `assert`: a Release build has assertions off, and
Release is the build every gate in this tree runs.

⚠ **The decl-only row is a DELIBERATE narrowing of the reserved-name rule the
other front-end names follow** ("even for a decl with NO call sites"), and it
is argued rather than accidental: a declare-only retired symbol is provably
inert (measured — swept when quantum is present, byte-identical passthrough
when it is not), the set that can reach a wrong unitary is exactly the set
with a USE, and a decl-only decline would have reddened ~490 fixtures
mid-migration. What is LOST is the family's prototype validation for an
uncalled declaration; `lowering_legacy_phi_decl_prototype_family.ll` records
that. Now that the corpus is migrated the second reason is spent, so
tightening this to the plain reserved-name rule is an open owner question
(one clause; ~5 fixtures to re-point).

### 6.2 Mixed-operand dispatch: the `_hl` variant

When a tainted opcode has one tainted operand (a handle, conventionally
the left) and one constant (a classical literal, conventionally the
right), the pass emits the `_hl` (handle + literal) variant of the
template. The runtime treats the classical operand as a literal, **not**
as a quantum register — it is not promoted via `cqrt_alloc_<W>` and
no qubits are allocated for it.

```llvm
; before
%c = add i32 %a, 5                                 ; %a tainted, 5 literal
```

```llvm
; after
%h_c = call i32 @cq_template_add_i32_hl(i32 %a, i32 5)
```

The `_hl` dispatch is load-bearing for an as-yet-unspecified future
optimization (`cq_alloc` deferral / elision via backward
"superposition reachability" — see §13 of the old architecture doc).
Promoting the classical operand to a handle would forfeit those
degrees of freedom; the pass deliberately avoids it.

For non-commutative opcodes (`sub`, `sdiv`, `srem`, `lshr`, `ashr`,
`shl`), an `_lh` variant would in principle be needed when the
literal is on the left. In practice the pass canonicalizes operand
order before dispatch where the opcode permits (commutative ops swap
freely; non-commutative ops would need either an explicit `_lh`
template or an LH-shape ancilla expansion). The Phase 1 deliverable
ships HH + HL; LH is deferred until a real call site demands it.

Both H+H and H+C return a fresh handle (`cqrt_template_add_i32`
returns `i32` per [`runtime/cq_templates.h`](../runtime/cq_templates.h));
the runtime allocates an output register for the result and threads
it back to the SSA caller. The pass replaces every downstream use of
the original `add i32`'s result SSA value with the returned handle.

### 6.3 The 38-opcode surface

LLVM IR's data-carrying opcodes — roughly 38 covering integer
arithmetic, bitwise, integer comparison, fp arithmetic, fp comparison,
casts (int↔int, fp↔fp, int↔fp) — are the natural surface a Bennett-
mapper needs to cover for reversibility. Each at applicable widths;
each at applicable operand shapes:

```
int arith    add sub mul sdiv udiv srem urem            × {i1,i8,i16,i32,i64}
int bitwise  and or xor shl lshr ashr                    × {i1,i8,i16,i32,i64}
int compare  icmp {eq,ne,slt,sgt,sle,sge,ult,ugt,ule,uge} × {i1,i8,i16,i32,i64}
fp arith     fadd fsub fmul fdiv frem fneg              × {f32,f64}
fp compare   fcmp {oeq,one,olt,ogt,ole,oge,ueq,une,     (full 14-pred family,
                  ult,ugt,ule,uge,ord,uno}               8rvn) × {f16,f32,f64}
int casts    sext zext trunc                             × applicable width pairs
fp casts     fptrunc fpext                               × applicable width pairs
mixed casts  sitofp uitofp fptosi fptoui                 × int×fp pairs
```

Memory (`load`, `store`, `getelementptr`) and structural ops (`phi`,
`select`) are deferred to a memory-model phase. Vector/SIMD,
transcendental intrinsics without soft impls, and exception-handling
constructs are reasons to **reject** a candidate function from
specialization (§7.4).

### 6.4 Width and signedness normalization

The runtime ABI is width-only: `signed char` and `unsigned char`
both lower to `cqrt_alloc_i8` and to `cq_template_add_i8`. Signedness
is implicit in the LLVM opcode at the call site (`add nsw` vs `add
nuw`, `icmp slt` vs `icmp ult`) rather than in the runtime symbol.
This is asymmetric with the frontend intrinsic surface, which **does**
carry signedness (`cq_theta_si32` vs `cq_theta_ui32`) because the
frontend needs to preserve the C type at the source level. The pass
bridges these — see [`docs/frontend.md` §3.1](frontend.md#31-the-three-primitive-families)
and [`ir-pass/src/WidthDispatch.cpp`](../ir-pass/src/WidthDispatch.cpp)
(the `kRows`/`MidRow` tables) for the suffix-to-width map, and
[`runtime/cq_runtime.h`](../runtime/cq_runtime.h)'s preamble for the
rationale.

---

## 7. Call-graph specialization (function lifting)

A central goal of CQ is that a plain classical function should work
with tainted arguments without source modification. The pass
implements this by synthesizing per-callsite **quantum
specializations** of called functions, using one of two mechanisms
depending on whether the callee's body is visible at pass time.

### 7.1 Path 1 — curated symbol substitution

For callees whose body is not in the bitcode module the pass sees
(libm, LLVM intrinsics, opaque shared-library symbols), the pass
maintains a curated table mapping classical symbols to quantum
templates:

```
@sin            → @cq_template_sin_f64
@cos            → @cq_template_cos_f64
@llvm.sqrt.f64  → @cq_template_sqrt_f64
@fabs           → @cq_template_fabs_f64
...
```

At a call site with at least one tainted argument, the pass rewrites
the called function. The original body is never inspected. errno-style
side effects in the original symbol are discarded by the quantum
template by construction; symbols on a Bennett-rejection list
(`printf`, syscalls, functions writing to externally-visible globals)
cause the pass to emit a compile-time error pointing at the call site
via `!dbg`.

### 7.2 Path 2 — clone-on-taint

For callees whose body is visible (user code, LTO-linked libraries),
the pass clones the callee keyed by the call site's **taint
signature**: a bit-mask indicating which argument positions are
tainted. The clone is then taint-propagated and lowered as if it
were a top-level function:

1. Compute the signature: for each parameter position, `1` if the
   corresponding argument is tainted, `0` otherwise.
2. Look up `(callee, signature)` in the specialization cache. If
   present, retarget the call site and skip the rest.
3. Otherwise, clone via `llvm::CloneFunction` + `ValueToValueMapTy`,
   rename the clone via a mangled scheme
   (`__cq_q_<callee>_<signature>`), set internal linkage so unused
   clones DCE away, and seed taint on the corresponding parameters
   in the clone's body.
4. Recurse: run §4 taint propagation, §5 allocation lowering, §6
   opcode lowering, §8 controlled-form lowering, §9 uncomputation on
   the clone.
5. Retarget the call site to the clone via
   `CallInst::setCalledFunction`.

The original function is left intact for classical callers. A clone
with signature `(tainted, classical)` of `int ipow(int, int)` runs
side by side with the original `@ipow` in the final binary; classical
callers see no change.

### 7.3 The worklist algorithm

```
worklist = { call sites with any tainted argument }
visited  = ∅

while worklist not empty:
    call    = worklist.pop()
    callee  = call.getCalledFunction()
    sig     = tainted_arg_mask(call)
    key     = (callee, sig)

    if key ∈ visited: continue
    visited.add(key)

    if callee ∈ curated_table:
        substitute_symbol(call, curated_table[callee, sig])
        continue

    if callee.body is None:
        emit diagnostic: "no IR available for {callee}, cannot specialize"
        continue

    if not classify_reversibilizable(callee):
        emit diagnostic: "non-reversibilizable callee {callee}"
        continue

    clone = clone_and_lower(callee, sig)
    cache[key] = clone
    call.setCalledFunction(clone)

    for inner_call ∈ clone if tainted_arg_mask(inner_call) != 0:
        worklist.push(inner_call)
```

The Phase 7 prototype validates `CloneFunction` +
`ValueToValueMapTy` + `setCalledFunction` end-to-end against stock
LLVM 19. Recursive call graphs converge because the signature is
preserved across recursive calls inside a clone, so the same key
hits the cache.

### 7.4 The rejection set

A candidate function is rejected from specialization if any of the
following appears in its IR:

| Reject | Reason |
|---|---|
| inline asm | opaque to the pass |
| syscall | non-pure, non-reversible side effect |
| `volatile` load/store | shared state |
| atomic instructions | shared state / non-determinism |
| EH (`invoke`, `landingpad`, `catchpad`, `resume`) | non-reversible |
| `setjmp` / `longjmp` (libc decl) | non-local control |
| indirect call without statically resolvable target | unknown reversibilizability |
| recursion without static depth bound | possibly non-terminating |
| vector / SIMD intrinsics | not yet implemented |
| transcendental intrinsics without soft impl | not yet implemented |

The pass emits a diagnostic at the rejecting instruction with
source-location precision via `!dbg`. Each rejection is the
**default** position, not a fundamental impossibility — devirtualizable
indirect calls, per-call-site variadic monomorphization, and inline-asm
escape hatches via annotation attributes are relaxations the
post-Phase-11 optimization layer may admit.

A reachable callee that fails the classifier is, by default, a
compile-time error. An optional flag (`-fcq-measurement-bridge`)
will insert `cqrt_measure_<W>` at the boundary so the program
proceeds classically into the offending callee, but this is opt-in:
silent measurement at function boundaries was the failure mode of
the prior `quantum`-keyword design that the taint-driven approach
exists to fix.

---

## 8. Controlled-form lowering (quantum control flow)

A branch whose condition is tainted is a quantum branch: the program
is in a superposition of "taken" and "not taken", and instructions in
the branch's shadow execute coherently under the condition. The new
design recovers the controlled region **structurally** from the LLVM
CFG; there is no user-emitted `cq_when_*` marker to detect.

### 8.1 Identifying a tainted branch

After taint analysis, scan each function for branches matching
`br i1 %cond, label %T, label %F` where `%cond` is tainted. A
tainted `%cond` is almost always the result of a tainted `icmp` or a
tainted truncation; the same propagation rule catches both.

### 8.2 Post-dominator-driven shadow computation

For each tainted branch:

1. Compute the immediate post-dominator `%merge` via LLVM's
   `PostDominatorTree` (accessed from a Module pass via
   `FunctionAnalysisManagerModuleProxy` — Phase 5 prototype confirms
   this composition).
2. The **shadow** is every basic block dominated by the branch and
   strictly pre-dominating `%merge` (i.e., the diamond between
   branch and merge, excluding both endpoints).
3. Treat every value defined in the shadow as **control-tainted**.
   This includes:
   - Direct propagation through operand-taint (same as §4).
   - φ-node results at `%merge` whose operands are classical
     literals — a φ between `10` and `20` looks classical
     operand-wise, but the selected value semantically depends on
     the tainted branch, so it must be promoted to control-tainted.

### 8.3 Controlled-variant substitution

Each tainted instruction in the shadow is substituted with the
**controlled** variant of its template. The control wire is the
handle that backs `%cond`:

- For an instruction already lowered to `cq_template_<op>_<width>`:
  substitute `cq_template_<op>_<width>_controlled` and prepend the
  control handle as the first argument.
- For an instruction yet to be lowered: lower as in §6 but pick the
  `_controlled` variant from the start.
- For a function call (specialization): re-clone with the q-arg-mask
  augmented to include "control-tainted in shadow" as a distinct
  flag; the clone's body recursively undergoes controlled-form
  lowering.

Memory stores in the shadow become controlled stores. Nested tainted
branches AND with the outer condition (Toffoli-style), and the
control wires accumulate — a doubly-nested shadow lowers to gates
controlled on both conditions.

### 8.4 Why no source-level marker is needed

A source-level `cq_when` would only matter if the user wanted to
quantum-control on a condition the pass would not flag as tainted.
But quantum control on a classical condition has no physical content:
a classical `1` reduces to unconditional application, a classical
`0` to no-op. There is no superposition of "applied vs. not" without
a tainted control wire. So tainted-condition is **necessary and
sufficient**; source-level brackets would be redundant ceremony.

This is the same conclusion as Sturm.jl's distinction between
`when(q)` (quantum) and `if Bool(q)` (classical-after-measurement);
in CQ both spellings collapse to "plain C `if`" because the
condition's taint state determines the lowering shape unambiguously.

### 8.5 Scope under construction

The current prototype validates the controlled-substitution mechanism
on linear single-BB regions (Phase 4 cq-control pass) and the
post-dominator-driven uncomputation on multi-BB CFG (Phase 5 multi-BB
test). Nested tainted branches, loops with tainted bounds, and
`cq_invert_*` interaction with controlled regions are downstream
backend work; the substrate (PostDominatorTree, controlled-variant
template substitution, signature-augmented cloning) is already
demonstrated.

---

## 9. Uncomputation — whole-DAG LIFO reversal

Phase 5 (modules `ChainWalk` / `DagTraversal` / `FreePoint` /
`Uncomputation`, runs **last** in `CQLoweringPass::run`) recovers the
**whole forward DAG** of each dead, source-derived tainted **data** handle
and reverses it **once**: a single reverse-program-order pass adjoints each
gate **exactly once** (over the void in-place `_unc` ABI, §10) and frees
each rail right after its last reverse-use. This productionizes the prior
*per-op, per-terminal* `_inv` slice into whole-DAG reversal that handles the
fan-out and Q+Q shapes the conservative slice bailed on (PRD §2.1/§2.11).

The reversal is sound only for a **closed, non-measured, non-escaped,
acyclic** DAG whose every gate **dominates** the single insertion point —
acyclic + dominating ⇒ each gate ran exactly once on every reaching path.
Any shape that cannot be *proven* to meet that bar either declines **loudly**
(`DiagnosticInfoUnsupported`, `opt` exits non-zero) or is left allocated as a
Rule-6/8 **safe leak** — never freed dirty (§9.3). The Prime Directive in
one place: over-declining is safe, over-accepting is a silent collapse.

### 9.1 Terminal selection and DAG recovery

A **terminal** is a tainted **data producer** — a `cqrt_alloc_<W>` mint or an
**uncontrolled** `cq_template_*` result — *all* of whose users are benign:
an in-place rotation on the handle (`cqrt_ry/rz_<W>`, mints no new value), a
`cqrt_measure_<W>` sink, or a non-call classical read (`ChainWalk::
isTerminalHandle`). Any *other* gate that takes the handle as an operand
(another data/compare/cast template, a controlled gate) consumes the register
forward, so the handle is not the terminal. Phase-4-owned control rails are
**subtracted up front** (DD-4 — `TaintSet::ControlOwnedRails`): a flag, work,
or merge out-rail the swap-route emitter owns is never selected, so its
reversal-or-leak stays Phase 4's responsibility.

`DagTraversal::recoverDataDag` then walks **backward** from the set of
Insert-classified terminals through every **tainted operand** — a
template-produced handle is itself a gate and hops to *all* its tainted
parents (Q+Q ⇒ two parents); an alloc / non-call handle is a root — collecting
in-place rotations and reassigning template producers. A visited-set dedups a
shared fan-out prefix so it is recovered **once**. The recovered gates are
sorted into program order (same block ⇒ position, else dominance, with
`BirthOrder` only as a FileCheck-stable tie-break).

A **closure / measure / escape** analysis then runs over every **rail** (a
root, or a template producer's result — the values the DAG zeroes and frees;
rotations mint no rail): every forward consumer of a rail must itself be a
recovered DAG gate. A measure sink upstream sets `MeasuredUpstream`; a `ret`
or `cq_invert_*` consumer sets `Escaped`; a `ControlOwnedRails` member or any
out-of-DAG consumer (a controlled copy/cswap, an uncovered gate) sets
`NotClosed`.

### 9.2 Adjoint emission — the void in-place `_unc` ABI

At the single insertion point the driver (`Uncomputation::emitDagReversal`)
walks the recovered gates in **reverse program order**, emitting each gate's
adjoint **exactly once** (a `Seen` set skips an already-adjointed shared-prefix
gate). For a `cq_template_*` data gate the adjoint is its **void in-place
`_unc`** form — `void cq_template_…_unc(out, src…)` — which **zeroes the rail
in place by recomputing `f` from the still-live sources** (Bennett uncompute),
**not** the fresh-minting inverse operation `_inv`. This is the load-bearing
correctness choice (DD-2, Rule 6/8): threading the old `_inv` would free a
**dirty / entangled** rail, a hidden projective measurement that collapses the
state. Rotations re-emit with a **negated angle**; `cqrt_x` / `cqrt_cswap` are
self-adjoint and re-emit as-is (§10).

The **DD-3 slot convention** pins the `_unc` argument order against the
generated stub: **`out` is arg 0** (the rail to zero — the forward call's own
result handle), followed by the **forward operands in their original order**.
So forward `cq_template_sub_i32_lh(i32 100, i32 %h) → %r` inverts to
`cq_template_sub_i32_lh_unc(i32 %r, i32 100, i32 %h)`, matching the generated
`void cq_template_sub_i32_lh_unc(out, a_classical, b_handle)`. Pinning the
slots is what guards the Q+Q operand-swap miscompile: a `mul_qq` whose two
handle operands are reversed in the `_unc` call links cleanly yet recomputes
the wrong rail.

Each rail is freed (`cqrt_free`) right after the adjoint of its **earliest**
forward gate — which, by SSA dominance, is emitted **last** among that rail's
reverse-touches, so the free lands after every reverse-read of the rail. The
result is exactly one `cqrt_free` per allocated rail, none double-freed; the
end-to-end goldens (`tests/e2e/slice_uncompute_dead_dag.c`,
`slice_uncompute_dead_shapes.c`) pin the full reversed streams — the **only**
layer that links and so the only proof every `_unc` symbol the emitter mints
resolves and signature-matches the generated runtime ABI.

### 9.3 Classification and loud declines

`FreePoint::computeFreePoint` classifies each terminal as **Insert**,
**Measured**, or **Escaped**; only `Insert` terminals reach reversal. The
decline-vs-skip discipline (the silent-skip class abolished in WI-5 — every
unprovable shape now declines, never silently leaks a dirty rail):

| Shape | Outcome |
|---|---|
| Dead, closed, acyclic, all gates dominate the merge | **reverse + free** |
| `ret` / `main` / `cq_invert_*` escape | **skip** (no emit; the caller / Phase 7 owns it) |
| `NotClosed` / `Escaped` rail in the recovered DAG | **safe leak** — left allocated, never a dirty free (Rule 6/8) |
| Gate applied to a handle **after** its measurement | **loud** — `gate applied to handle after measurement` |
| A non-terminal rail read by a measure sink | **loud** — `dead chain would free a measured register` |
| A recovered gate with no in-place adjoint (permutation / controlled) | **loud** — `dead chain contains an un-invertible primitive` |
| A mutating gate that does **not** dominate the merge (split across branch arms) | **loud** — `dead chain spans divergent control-flow arms` |
| Tainted live range crosses a loop backedge | **loud** — `tainted handle live range crosses a loop backedge` |
| Handle reaches an unrecognized user / non-reconverging CFG | **loud** — `tainted handle reaches an unrecognized user` |

`FreePoint` and the `Uncomputation` driver **own** these exact diagnostic
strings (each is prefixed `cq uncompute:` in the source — elided in the table
above for width); the negative LIT fixtures (`ir-pass/test/
lowering_uncompute_*.ll`) mirror each one character-for-character (Rule 12), so
code and test cannot drift. The un-invertible pre-scan consults the **same** `isInverseEmittable`
predicate the emitter uses, *before* any emission — so emit and decline can
never disagree and no half-reversed chain or dirty free of an un-adjointed
rail is ever produced (DD-1: the driver owns the message; `emitInverseChain`
returns `bool`).

### 9.4 What this preserves and what it changes

The per-op compile-time-adjoint principle survives, but the granularity moved
from *per-terminal* to *whole-DAG*: SSA dominance makes reverse-program-order a
valid reverse-**topological** order, so fan-out and Q+Q reconvergence are
handled by one `Seen`-deduped pass rather than bailed on, and the post-dominator
machinery now computes a **single** insertion point for the whole DAG. The
inverse is the **void in-place `_unc`** (recompute-from-sources), replacing the
fresh-minting `_inv` thread — the `_inv` symbols are still generated (DD-2) but
the spine no longer emits them. No `cqrt_cswap` is used (PRD §2.11): a
superposed source that *would* need a controlled swap to disentangle is exactly
the `NotClosed` / entangled case that safe-leaks instead.

Whole-call Bennett-style wrap-around is **not** used for uncomputation. It is
used only at one place: §7.2 clone synthesis, when the pass needs the
boundary-preserving forward + CNOT-copy + reverse construction so the clone
fits a handle-ABI signature without leaking ancillas to the caller.

---

## 10. Per-op adjoints and manual inversion

For every forward template, the inverse is mechanically derived;
the backend ships forward + controlled-forward only. Manual
inversion via `cq_invert_begin` / `cq_invert_end` reuses the same
mechanism.

### 10.1 The `emit_inverse` rule

```
emit_inverse(forward_sequence):
    for each gate g in reverse(forward_sequence):
        if g is an uncontrolled cqrt_ry/rz(q, θ):   re-emit with θ negated
        if g is cqrt_x / cqrt_cswap:                re-emit as-is (self-adjoint)
        if g is an uncontrolled data cq_template_*: emit its void `_unc` form
        else:                                       UN-INVERTIBLE → loud decline
```

`isInverseEmittable` (`ir-pass/src/EmitInverse.cpp`) is the **single accept gate**
the inverter recognizes; anything outside it is loud-declined by the driver
(`cq uncompute: dead chain contains an un-invertible primitive`), never guessed.
The realized adjoint relations:

| Gate | Inverse |
|---|---|
| `cqrt_x(q)` | `cqrt_x(q)` (self-adjoint, as-is) |
| `cqrt_cswap(f, a, b)` | `cqrt_cswap(f, a, b)` (self-adjoint, as-is) |
| `cqrt_ry(q, θ)` | `cqrt_ry(q, -θ)` |
| `cqrt_rz(q, φ)` | `cqrt_rz(q, -φ)` — **except** a `cqrt_rz_i1` carrying `!cq.branchphase` (§6.1a), which is **refused**: adjointing a kickback gate cancels the answer |
| uncontrolled data `cq_template_<op>_<W>…` | its void `_unc` (§9.2) |
| anything else (`cqrt_cnot`, `cqrt_toffoli`, a controlled form, a **compare**) | **un-invertible → loud decline** |

Note the inverter realizes adjoints only for the gates it actually emits: the
self-adjoint involutions are `cqrt_x` / `cqrt_cswap`, **not** `cqrt_cnot` /
`cqrt_toffoli` / `cqrt_h` (those are never emitted on a data DAG and the spine
refuses to *guess* an adjoint — they route to the loud decline). Compares
(`icmp`/`fcmp`) are likewise un-invertible here (see below).

For a `cq_template_<op>_<W>` **data** template the adjoint is **not** a
negated-angle re-emit but the **void in-place `_unc`** form
`cq_template_<op>_<W>…_unc(out, src…)` — it zeroes the rail by recomputing the
forward function from the still-live sources (Bennett), rather than minting a
fresh inverse result (§9.2). This is `emitInverseCall`'s third branch; the DD-3
slot convention (`out` first, then the forward operands in order) pins the `_unc`
call to the generated stub signature. The template library generates the
**forward**, `_inv` (fresh-minting adjoint), and `_unc` (void in-place adjoint)
symbols for every **binary / unary / cast** op — plus `_controlled` twins where
the swap-route emitter needs them; see
[`runtime/cq_templates.h`](../runtime/cq_templates.h) for the declared set. The
**compare** family (`icmp`/`fcmp`) is the deliberate exception: it has forward +
`_inv` only and **no `_unc` grid** (the uncompute axis is binary + unary + cast
only — `tools/opcode_table.yaml`), so a dead data-position compare reaching the
spine **declines loudly** rather than minting a nonexistent `…_unc` symbol
(`isCompareTemplate` excludes it from `isInverseEmittable` — the WI-7 over-accept
fix). The uncompute spine emits **only `_unc`** for data templates (DD-2); the
`_inv` symbols are generated but no longer emitted by the spine (a half-minting
`_inv` thread would free a dirty rail — Rule 6/8; the icmp/fcmp `_inv` strips are
still emitted directly by `CompareLowering` for Phase-4 control flags).

### 10.2 The derived-adjoint commitment

Adjoints are **derived by the IR pass**, not hand-authored: `emit_inverse`
produces the inverse of a visible gate sequence by reversing it and applying
the per-gate rule (negated angle / self-adjoint / void `_unc`). So the
hand-written core surface ships **forward** and **controlled-forward** gate
primitives only; the data-template ABI is **autogenerated** (forward, `_inv`,
`_unc`, and the `_controlled` twins the swap-route emitter consumes) from
`tools/opcode_table.yaml`. The controlled-**adjoint** shape is never needed for
data uncompute: a dead data DAG is reversed by the **uncontrolled** void `_unc`
spine (§9), and Phase-4 control rails are reversed in place by their own
emitter (route-bracketed reverse-play), never by this spine. ⚠ **The clause in
parentheses is HISTORY since 3qlq Inc 2 (2026-09-06):** no control emitter
reverse-plays anything any more — a phase arm's flag is stripped by its compare
`_unc` and a value arm's hoisted chain is reversed by **this very spine**, since
the chain is ordinary tainted arithmetic in the pred rather than a bracketed
region stream. What survives is the division of labour, not the mechanism: the
FLAG and the merge out-rail are still `ControlOwnedRails` and still the emitter's
responsibility, and the chain-final rail is deliberately left allocated
(`retire-swap-route-PRD.md` §0 E1).

### 10.3 Manual inversion via `cq_invert_begin` / `cq_invert_end`

A user-written

```c
cq_invert_begin();
    f(q);
    g(q);
cq_invert_end();
```

is lowered as follows:

1. The pass identifies the bracketed region via the
   `@cq_invert_begin` / `@cq_invert_end` marker calls at module-level
   call sites.
2. The bracketed gate sequence (every `cqrt_*` or `cq_template_*`
   call between the markers, plus their controlled-form
   substitutions if the region sits inside a tainted-branch shadow)
   is collected.
3. `emit_inverse` is applied to the collected sequence, producing
   the adjoint.
4. The original forward calls in the bracket are replaced with the
   adjoint sequence; the marker calls themselves are erased.

This is distinct from auto-uncomputation (§9): auto-uncomputation
runs without user intervention at SSA last-use points; manual
inversion applies the adjoint of an explicitly bracketed operation
the user wants to undo (e.g., de-preparing a state after a
measurement, undoing oracle preparation in phase estimation).

When the user writes `invert(f)(args)` at the source level
(spelling per [`frontend.md`](./frontend.md) §3.5), the frontend
lowers it to a bracketed form internally; the pass treats it the
same way as a hand-bracketed region.

---

## 11. Runtime ABI

The contract between IR-emitted code and `libcq_runtime`. The
handle pattern is the load-bearing element; everything else is
supporting detail.

### 11.1 The handle abstraction

IR-emitted code references qubit registers via opaque `i32`
handles. The runtime maintains a register-state table indexed by
handle; rich state (qubit indices, classical shadow, mask,
allocation tracking) lives entirely behind that boundary.

The pattern matches POSIX file descriptors + the kernel's file
table, OpenGL handles + the GPU driver's resource state, JNI
references + the JVM's object table. No quantum-specific quirk here
— it is exactly how compiled programs reference runtime-owned rich
state from a stable ABI.

Why the handle (and not a struct-by-value or a pointer to a runtime
struct):

- ABI stability under runtime evolution: a runtime can add fields to
  its internal state struct without recompiling IR-emitted code.
- Platform calling-convention quirks disappear: no struct-by-value
  lowering surprises (structs >16B → hidden pointer on x86-64 SysV;
  memcpy'd on Windows x64; etc.).
- Multiple runtime variants share one IR + one template library.
- Reference identity is automatic: two calls referencing handle `7`
  refer to the same register.

### 11.2 Allocation, measurement, free

The 15 `cqrt_*` allocation/measurement/free symbols declared in
[`runtime/cq_runtime.h`](../runtime/cq_runtime.h) cover allocation
(7 per-width variants), measurement (7 per-width variants), and
free (one width-irrelevant entry). (These 15 are one family of the
hand-written core ABI; the header also declares the rotation,
controlled-rotation, gate-primitive, `cqrt_cswap`, and `cqrt_copy_<W>`
families — see §11.3/§11.4 and PRD Part II §8.1.)

```c
/* Allocation — width-only ABI. Takes an initial classical value;
   returns a fresh handle. */
int32_t cqrt_alloc_i1 (bool    value);
int32_t cqrt_alloc_i8 (int8_t  value);
int32_t cqrt_alloc_i16(int16_t value);
int32_t cqrt_alloc_i32(int32_t value);
int32_t cqrt_alloc_i64(int64_t value);
int32_t cqrt_alloc_f32(float   value);
int32_t cqrt_alloc_f64(double  value);

/* Measurement — width-only ABI. Takes a handle; returns the
   classical value of the matching width. */
bool    cqrt_measure_i1 (int32_t handle);
int8_t  cqrt_measure_i8 (int32_t handle);
int16_t cqrt_measure_i16(int32_t handle);
int32_t cqrt_measure_i32(int32_t handle);
int64_t cqrt_measure_i64(int32_t handle);
float   cqrt_measure_f32(int32_t handle);
double  cqrt_measure_f64(int32_t handle);

/* Free — width-irrelevant. Returns qubit indices to the pool. */
void cqrt_free(int32_t handle);
```

Width-only at the runtime layer is intentional: signedness does
not change the qubit count or the gate set; the IR pass already
disambiguates signed vs. unsigned operations at the LLVM-opcode
layer (`add nsw` vs. `add nuw`, `icmp slt` vs. `icmp ult`). The
frontend intrinsic surface carries signedness for source-level
clarity (`cq_theta_si32` vs. `cq_theta_ui32`); the pass strips it
when lowering to the runtime.

At the **runtime** layer `cqrt_measure_<W>` is trace-only and does not
physically reclaim the handle. The **compiler**, however, treats measurement
as **terminal**: a measured handle gets **no adjoint and no `cqrt_free`** —
the measurement *is* its reclamation, so `FreePoint` classifies it `Measured`
and the uncompute spine skips it (§9.3). There is **no measure-then-reuse
path**: a gate applied to a handle **after** its measurement is a **loud
reject** (`cq uncompute: gate applied to handle after measurement`), and a
dead chain that would free a register read by a measure declines loudly
(`cq uncompute: dead chain would free a measured register`) — freeing a
measured register is a hidden projective collapse (Rule 5/6). "Measured ⇒ done." A handle is
freed by `cqrt_free` only along the **non-measured** dead-handle path, where
the uncompute spine emits the whole-DAG adjoint then the free (§9.2).

### 11.3 Quantum-specific primitives

Beyond allocation/measurement/free, the runtime exposes two
quantum primitives the templates and the lowered theta/phi calls
emit:

```c
void cqrt_ry_i<W>(int32_t handle, double angle);  // Ry on each qubit of the register
void cqrt_rz_i<W>(int32_t handle, double angle);  // Rz on each qubit of the register
```

(fp counterparts `cqrt_ry_f<W>` / `cqrt_rz_f<W>` are declared
similarly.) Multi-bit registers are tensored: `cqrt_ry_i32(h, θ)`
applies `Ry(θ)` to each of the 32 qubits in the register. This
matches the frontend's per-bit rotation semantics (see
[`frontend.md`](./frontend.md) §3.2) and Sturm.jl's `q.θ += δ` on
`QInt{W}`.

> **Rz — emitted at `i1` only, from 3qlq Inc 1 (bd `test_C_libtooling-3qlq.2`,
> SHIPPED 2026-09-05, parts A and B both landed).** The tensored
> reading above is the whole `cqrt_rz_<W>` semantics and it is exactly what
> made a routed or controlled Rz useless as an oracle: the marked phase is
> `(−1)^popcount(target)`, and a per-qubit diagonal gate fixes `|0…0⟩`, so it
> can never mark it (`retire-swap-route-PRD.md` §1). `cq_phi` is therefore
> register-free, and the ONLY Rz the pass emits is the kickback gate
> `cqrt_rz_i1(flag, θ)` on a flag ancilla — §6.1a here,
> [`frontend.md`](./frontend.md) §3.3 for the source surface. The `W>1`
> widths and the whole `cqrt_rz_<W>_controlled[_inv]` family stay **declared
> but unemitted** until the Phase-11 freeze decides them (owner question Q1,
> PRD §5/§12); the *declarations* are unchanged, so this adds **no** runtime
> symbol and the emitted set strictly shrinks (owner decision D3).
>
> ⚠ **"Emitted at `i1` only" ARRIVED IN STAGES, and the intermediate state is
> recorded because it is what a half-read claim looks like.** Increment 1 part
> A converted the flat diamond, the angle select and the in-loop region and
> left **three** tensored minters standing — `NestedRouteEmit` (the depth-2
> nest), `SwitchRouteEmit`'s routed phase path, and the then-callerless
> `RotationLowering::emitRz` — measured at the part-A hand-back as exactly 3
> of 1602 fixtures still making the pass emit a non-`i1` `cqrt_rz`. **Part B
> removed all three** (`NestedRouteEmit.cpp` and `emitRz` are DELETED;
> `SwitchRouteEmit` is a per-case eq-flag kickback), and both parts are merged.
> **MEASURED after the merge:** the round-2 review swept 1661 fixture outputs
> and found 35 emitting an Rz and **0** at any width other than `i1`, with
> `#cqrt_rz_i1 == #!cq.branchphase` in every one; tree-wide, `grep -h
> 'cqrt_rz_' tests/e2e/*.expected.log | grep -v 'cqrt_rz_i1('` returns **0**
> across 304 committed goldens, and `cqrt_rz_<W>_controlled` returns **0** as
> well. Still measure rather than assume when you quote it: sweep the corpus
> and grep the pass output for a `cqrt_rz` that is not `cqrt_rz_i1`, because a
> new emitter is all it takes.

### 11.4 Gate primitives

For internal use by the template library and by Phase 11
optimization passes:

```c
void cqrt_x       (int32_t q);
void cqrt_h       (int32_t q);
void cqrt_cnot    (int32_t ctrl, int32_t tgt);
void cqrt_toffoli (int32_t c1, int32_t c2, int32_t tgt);
```

These are not emitted by the IR pass for stock LLVM opcodes;
instead the pass emits `cq_template_<op>_<W>` calls, and the
template bodies (or post-lowering inlining at the runtime layer)
decompose into these primitives. Since Phase 4.1, however, the
control emitter does emit `cqrt_x` directly (the ¬flag
bracket); `cqrt_h` and `cqrt_cnot` remain unemitted placeholders until
Phase 8, while `cqrt_toffoli` IS emitted — by `CondTreeEmit`'s AND
node (and the 4.3 nest's conjunction ancilla through it), by
`Specialization`'s condition network, and by the 7.4 break
reverse-play (measured: `grep -rn 'toffoliFn' ir-pass/src`).
⚠ **`cqrt_cswap` is no longer the control path's routing primitive**
(3qlq Inc 1 + Inc 2, both landed 2026-09-06 — the swap route is
retired for BOTH arm classes): its ONE minter is the 7.2
`AbortParkEmit`, via `emitRoute`'s single call site
(`AbortParkEmit.cpp:396`), and exactly **1** of 319 committed goldens
contains one. A future optimization pass operating on lowered IR may
fuse, cancel, or commute gates at this level.

Phase 4.2 adds the per-width **reversible basis copy** to the
hand-written core ABI (PRD Part II §8.1 — the design's only new
ABI; the `cqrt_cswap` precedent, not the generated
`cq_template_*` surface):

```c
void cqrt_copy_i1 (int32_t src, int32_t dst);
void cqrt_copy_i8 (int32_t src, int32_t dst);
void cqrt_copy_i16(int32_t src, int32_t dst);
void cqrt_copy_i32(int32_t src, int32_t dst);
void cqrt_copy_i64(int32_t src, int32_t dst);
```

`cqrt_copy_<W>(src, dst)` is the keep-sources-live transversal-CNOT
basis copy `|x⟩_src |0⟩_dst → |x⟩_src |x⟩_dst` (`dst` must be a
fresh `|0⟩` register; the emitter allocates it immediately before
the copy). Like `cqrt_cswap` and the ¬flag `cqrt_x` bracket — and
unlike the YAML-generated `cq_template_*` surface — it is emitted
directly by the IR pass. **Since 3qlq Inc 2 (2026-09-06) its live
customer is the value `switch`'s PRELOAD** — `cqrt_copy_<W>(p, out)`
once at the top of a V3 region, before the per-case XOR-delta
controlled copies — while the flat value diamond / if-else merges
entirely through the `_controlled` twins. ⚠ HISTORY, dated: it was
introduced as "the copy-out step of the value-arm (method-B)
swap-route lowering", and that lowering is retired (there is no
route and no reverse-play in any value emitter now). It copies a computational-basis *label*, not a
state — it is wrong for any phase/superposition carrier (a CNOT
copy of an `Rz`/`Ry` answer dephases it), it never frees or
consumes its source (freeing a superposed source stays
`cqrt_cswap`-only), and it is an involution, so there is no
`cqrt_copy_<W>_inv` twin. The family is **integer-width only**: a
floating-point merge φ under tainted control is categorically an
angle, never data, so `f32`/`f64` twins would be dead ABI whose
only possible caller is exactly that miscompile. Trace follows the
no-arrow void convention: `cqrt_copy_<W>(h<src>, h<dst>)`.

**Freeze note:** the Phase-8/10 ABI freeze re-opens for exactly
this one family — the 5 `cqrt_copy_i{1,8,16,32,64}` symbols
(reserved in advance by the ROADMAP Phase-8 "Reconciliation with
swap-route Phase 4 (principle 7)" note). No other symbol is added;
the generated `cq_template_*` surface is untouched.

### 11.5 Multiple runtime variants share one IR

The handle ABI is the abstraction boundary; whatever the runtime
does behind it is its concern. Same compiled binary, different
runtime implementations:

| Runtime | Behavior at each `cqrt_*` call |
|---|---|
| `libcq_runtime_count.so` | Increment per-gate counters; no quantum state maintained |
| `libcq_runtime_sim.so` | Apply the gate to a statevector simulator |

Both variants implement the same handle ABI; the IR-emitted code
cannot tell them apart. `_count` is the resource-estimator mode
(useful for circuit-complexity analysis, gate-count diffs across
algorithm variants, regression testing of optimization passes
without committing to a simulator's numerical accuracy). `_sim` is
the execution mode (runs the algorithm on a statevector backend).
The link-time choice of runtime variant is the only knob between
them.

The classical-shadow short-circuit at measurement
(`qreg_state_t.value` carrying the deterministic value when no
superposition has been introduced, returned by `cqrt_measure_<W>`
without an actual measurement gate) is a runtime-internal
optimization, transparent to the IR-emitted caller. A compile-time
analog — eliding `cqrt_alloc_<W>` for tainted values that never
reach a superposition sink — is a stronger version of the same
idea, parked for Phase 11 evaluation.

### 11.6 Lifecycle and versioning

Optional lifecycle hooks (`cqrt_init`, `cqrt_finalize`,
`cqrt_begin_circuit`, `cqrt_end_circuit`) let the runtime perform
explicit setup/teardown or batch the gate sequence. The pass does
not emit these by default; they are intended for runtime-variant
glue code.

Symbol versioning on the `cqrt_*` surface (ELF symbol versions /
Mach-O equivalents) handles compatibility between compiled
binaries and runtime upgrades. A `cqrt_abi_version()` query
function lets a runtime variant declare its capability set for
three-way compatibility (compiler ↔ templates ↔ runtime). The
versioning scheme is open; the discipline is mandatory before any
binary distribution of compiled CQ programs.

---

## 12. Template library

The reversible-circuit primitives the IR pass substitutes for
tainted stock LLVM opcodes. Declared in
[`runtime/cq_templates.h`](../runtime/cq_templates.h); bodies
deferred to post-Phase-11 implementation (frontend freeze precedes
real-gate-sequence work).

### 12.1 The autogenerated declaration set

The template surface is parametric in (opcode × width × operand
shape × forward/inverse). Manually maintaining ~38 opcodes × ~5
widths × ~3 shapes × 2 (forward + inverse) ≈ a few hundred
declarations would be tedious and bug-prone; the project's
generator (`tools/gen_templates.py` reading
`tools/opcode_table.yaml`) emits `runtime/cq_templates.h`
mechanically. The generated header carries a SHA hash of the source
YAML in its preamble; CI rebuilds the header and verifies the hash
matches.

The declared symbols cover the 38-opcode surface from §6.3 across
applicable widths and operand shapes, plus the `_inv` counterpart
for each.

### 12.2 Operand-shape dispatch (`_hl`, `_lh`)

Each template family carries a base symbol for the all-handle case
plus suffixed variants for mixed handle / classical-literal cases:

```c
int32_t cq_template_add_i32      (int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_i32_hl   (int32_t a_handle, int32_t b_classical);
int32_t cq_template_add_i32_inv  (int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_i32_hl_inv(int32_t a_handle, int32_t b_classical);
```

The IR pass picks the symbol based on operand LLVM kind at the
call site: `ConstantInt` on the RHS dispatches to `_hl`; tainted
SSA handle on the RHS dispatches to the base symbol. For
non-commutative opcodes, an `_lh` shape would be needed when the
literal is on the LHS; commutative opcodes canonicalize operand
order and avoid the need.

### 12.3 Template variants (future)

Multiple reversible-gate-sequence variants may exist for the same
opcode + width pair:

- `cq_template_add_i32_ripple` — ripple-carry adder, depth O(W),
  ancilla O(W)
- `cq_template_add_i32_cuccaro` — Cuccaro adder, depth O(W),
  ancilla O(1)
- `cq_template_add_i32_draper` — QFT-based, depth O(log W), no
  ancilla but transcendental rotations
- `cq_template_mul_i32_karatsuba` — Karatsuba multiplier

Selection mechanism (open):

- **Compiler flag** (`-fcq-adder=cuccaro`) — coarse-grained,
  uniform.
- **Cost model** (minimize depth / ancilla / gate count) — fine-grained,
  driven by Phase 11 cost-model infrastructure.
- **Backend hint** — different `libcq_runtime` variants prefer
  different templates (e.g., the `_count` variant may favor
  templates whose gate count reflects a target hardware family;
  the `_sim` variant may favor templates with simpler
  numerically-stable rotations).

Phase 1 ships one canonical variant per opcode-width pair; the
variant-selection policy is a Phase 11 concern.

### 12.4 Distribution shapes

| Shape | Where | Optimization | Note |
|---|---|---|---|
| **LLVM bitcode (`.bc`)** | `libcq_templates.bca` archive | LTO can inline + DCE the gate sequence | Cleanest; requires bitcode-aware link |
| **Native (`.a` / `.so`)** | `libcq_templates.{a,so}` | Call-boundary opaque to LLVM opt | Simplest distribution; one call per opcode |
| **Pass-internal IRBuilder** | Inside the IR pass binary | Full IR-builder access; no precompiled artifact | Templates regenerated per build |

Recommended default: ship `.bc` for builds that can use LTO, fall
back to `.a` for deployment where LTO is impractical. Per-deployment
choice, not per-program.

---

## 13. Compilation flow

The backend's responsibility spans Stages 2 and 3 of the three-stage
flow the frontend documents (see [`frontend.md`](./frontend.md) §8).

### 13.1 Single-file program

```bash
clang -O1 -emit-llvm -include CQ.h example.c -o example.bc       # Stage 1 (frontend)
opt -load-pass-plugin libCQPass.so -passes=cq-lowering \
    example.bc -o example.lowered.bc                              # Stage 2 (backend pass)
clang example.lowered.bc -lcq_templates -lcq_runtime -o example   # Stage 3 (codegen + link)
./example                                                          # emits circuit
```

Stage 2's input is per §3; Stage 2's output contains no `@cq_*`
intrinsic calls and no tainted stock opcodes — only `cqrt_*`
runtime calls, `cq_template_*` template calls, and stock LLVM
classical IR threading them. Stage 3 is plain Clang codegen + LTO
link against the templates archive and one runtime variant.

### 13.2 Multi-file program (function lifting across translation units)

The clone-on-taint path (§7.2) needs callee bodies in the same
bitcode module the pass sees. Pre-link with `llvm-link` (or build
with `-flto`) *before* invoking `opt`:

```bash
clang -O1 -emit-llvm -include CQ.h main.c -o main.bc
clang -O1 -emit-llvm util.c -o util.bc                            # no CQ.h needed
llvm-link main.bc util.bc -o combined.bc                          # bitcode-link first
opt -load-pass-plugin libCQPass.so -passes=cq-lowering \
    combined.bc -o combined.lowered.bc
clang combined.lowered.bc -lcq_templates -lcq_runtime -o program
```

Functions whose bodies are not LTO-visible flow through the curated
symbol table (§7.1) instead — no bitcode required. An unknown
symbol with tainted arguments at a call site causes the pass to
error with a diagnostic pointing at the call site via `!dbg`.

The `cqc` driver wraps the multi-step flow under a single
invocation mirroring a stock `clang -flto` command line.

### 13.3 Cross-language input

Any function whose LLVM bitcode is reachable can participate in
the call-graph closure regardless of source language. To bring in
C++, Rust, Fortran, etc.:

1. Compile with the language's `-emit-llvm` (or equivalent, e.g.
   `rustc --emit=llvm-bc`, `flang -emit-llvm`).
2. Include the resulting `.bc` in the LTO link.
3. The pass discovers callable functions via the call graph.
4. Specializations are synthesized on demand via §7.2.

Closed-source binary libraries without IR cannot be specialized.
The pass emits a diagnostic per §7.4.

---

## 14. Cross-references

| Concern | Where it is documented |
|---|---|
| User-facing intrinsic surface (`cq_theta` / `cq_phi` / `cq_measure` / `cq_invert_*`) | [`frontend.md`](./frontend.md) §3 |
| Why no `quantum` keyword; why no cast-as-measurement; why `qint_mid_t` was retired | [`rationale/proposal-taint-driven-pipeline.md`](./rationale/proposal-taint-driven-pipeline.md) |
| Taint as Q/C boundary; mixed-operand semantics; conversion semantics | [`quantum-classical-handling.md`](./quantum-classical-handling.md) |
| Stock LLVM C++ APIs each mechanism uses | [`llvm-implementation.md`](./llvm-implementation.md) |
| No-fork validation prototype | [`../archive/prototype/README.md`](../archive/prototype/README.md) |
| Production pass-plugin sources | [`../ir-pass/`](../ir-pass/) |
| Runtime ABI header (the 15 `cqrt_*` symbols) | [`../runtime/cq_runtime.h`](../runtime/cq_runtime.h) |
| Template library declarations (autogenerated) | [`../runtime/cq_templates.h`](../runtime/cq_templates.h) |
| Template generator source-of-truth | [`../tools/opcode_table.yaml`](../tools/opcode_table.yaml), [`../tools/gen_templates.py`](../tools/gen_templates.py) |
| End-to-end worked example, source → lowered IR | [`example.md`](./example.md) |
| Design convergences and divergences with Sturm.jl / Bennett.jl | [`bennett-jl-comparison.md`](./bennett-jl-comparison.md) |
