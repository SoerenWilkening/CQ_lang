# CQ Backend — IR Pass and Runtime

What the compiler does with the LLVM IR the frontend hands off, and what the
compiled binary calls into at runtime. The backend carries most of the
project's compiler weight: a single LLVM-pass module (`cq-lowering`) that
drives forward taint propagation, allocation, opcode lowering, call-graph
specialization, quantum-control lowering and whole-DAG uncomputation, plus a
runtime library exposing a small handle-based ABI.

The plan of record is [`../NORTHSTAR.md`](../NORTHSTAR.md). This document
describes the mechanisms as implemented; the claims were checked against
`include/CQ.h`, `ir-pass/`, `runtime/` and `tools/`, and where a detail is not
pinned by a cited fixture or golden the source is the authority. Where a
passage says a shape is *not lowered yet*, that is a compiler gap in the sense
of NORTHSTAR goal 1 — the pass fails loudly, the gap is filed in bd, and it is
not a design position. Only the four physics walls on that list are valid
declines.

Section numbers are cited from other documents and from source comments (for
example `backend.md §5.1`, `§11.3`, `§11.4`); keep them stable.

Companion documents:
- [`frontend.md`](./frontend.md) — what the user writes and what the
  bitcode coming into the pass looks like
- [`quantum-classical-handling.md`](./quantum-classical-handling.md) —
  taint as the Q/C boundary, mixed-operand semantics
- [`llvm-implementation.md`](./llvm-implementation.md) — the stock LLVM C++
  APIs the mechanisms depend on
- [`example.md`](./example.md) — end-to-end walkthrough of a small program
  through the pass
- [`backend-provider.md`](./backend-provider.md) — what a production static
  backend must implement to replace the trace runtime

---

## 1. Scope

This document defines:

- The LLVM IR **input contract** the backend expects
- The **forward taint propagation** that drives every later step
- **Allocation lowering** — where `cqrt_alloc_<W>` calls are inserted
- **Opcode lowering** — how tainted stock LLVM opcodes become
  `cq_template_*` calls, how mixed quantum/classical operands dispatch to the
  `_hl` / `_lh` shapes, and how `cq_phi` lowers
- **Call-graph specialization** — how plain C functions participate in
  tainted call chains without modification
- **Quantum control flow** — how a tainted `br` / `select` / `switch` is
  recovered structurally and lowered per arm class
- **Uncomputation** — the whole-DAG reverse-program-order adjoint spine
- **Adjoint generation and manual inversion**
- The **runtime ABI** (`cqrt_*`) and the **template library**
  (`cq_template_*`)
- The **compilation flow**

It does **not** define:

- The user-facing intrinsic surface (`cq_theta`, `cq_phi`, `cq_measure`,
  `cq_invert_*`) — see [`frontend.md`](./frontend.md) §3
- Reversible-circuit families for the opcode templates (ripple-carry vs.
  Cuccaro vs. Draper, and so on). The shipped template bodies are trace-only
  stubs (§12.3); the circuit behind each symbol is a backend concern
- Simulator internals. There is no simulator in this repository (owner
  decision 2026-06-10); correctness is established by golden trace diff plus
  adversarial review

---

## 2. What the backend is, and what it is not

- **One IR-pass module**, `cq-lowering`, that runs after Clang's `-O1`
  cleanup. It builds against stock LLVM 19 as an out-of-tree module plugin
  (`opt -load-pass-plugin libCQPass.so -passes=cq-lowering`); there is no
  patch to `llvm-project`. It is orchestrated by `CQLoweringPass::run`
  (`ir-pass/src/CQLoweringPass.cpp`) with one width-parametric source file per
  concern in `ir-pass/src/`. A module containing no `cq_theta`, `cq_phi` or
  `cq_measure` call is left byte-identical.
- **Two static runtime archives** that together implement the emitted ABI:
  `libcq_runtime.a` (the hand-maintained `cqrt_*` core, §11) and
  `libcq_templates.a` (the generated `cq_template_*` surface, §12). The
  shipped implementation is a **trace runtime**: every call prints one line and
  nothing is simulated. A production backend replaces both archives wholesale
  ([`backend-provider.md`](./backend-provider.md)).
- **Not a competing optimizer.** The pass operates on stock SSA, leaves
  classical code alone, and inherits every classical optimization Clang
  already ran.
- **Not a simulator.** The runtime hands gate calls to whatever backend is
  linked.
- **Not a whole-function transformer.** Uncomputation is whole-DAG reversal of
  the dependence DAG of dead tainted values (§9). Bennett-style
  compute–copy–uncompute is used at one place only: the wrap around a
  synthesized specialization clone (§7.2).

### Stage order inside the pass

Read off `CQLoweringPass::run`; the exact sequence is in the source.

1. **Propagate** taint from `@cq_theta_*` results (§4).
2. **Normalising pre-passes** that emit no gate and re-propagate taint after
   they change the module: dead call-argument drop, by-ref producer inlining,
   bounded rail-bank promotion, volatile-scalar and `fp80`-union promotion,
   block-predicate flattening of general acyclic tainted control (`PredMux`),
   small constant-trip loop unrolling, the shift-count-loop-to-`ctlz`
   recognizer. Their shared discipline is accept-only: an off-pattern shape is
   left byte-untouched for its existing loud owner.
3. **Guards** that decline loudly before any lowering: taint escapes, stale
   records, stale quantum readers.
4. **Detection and lowering of I/O sinks, loops and control regions**
   (`lowerLoops`, `detectControlRegions`, `lowerControlRegions`, §8), then a
   **second round**: taint is re-seeded from the merge rails the emitters
   minted (`repropagateControlMerges`) and control detection and lowering run
   again to a fixpoint. Any stage between the rounds must not assume "taint is
   settled" for a value derived from a merge rail.
5. **Memory and specialization**: tainted-index QRAM reads and stores, the
   classical-mux guard, then clone-on-taint (§7.2).
6. **Data lowering**: `lowerRotations` (§5), `lowerOps` (§6),
   `lowerMeasures`, break reverse-play, late reassignments.
7. **`uncompute`** (§9) — **last**, so it sees the final lowered module.
8. **Postconditions**, each a loud decline rather than an `assert` (assertions
   are off in Release): no front-end intrinsic call survives
   (`declineSurvivingIntrinsicCalls`), no unpaired `undef` literals, no
   undischarged marked-body rail. Then dead front-end declarations are swept.

---

## 3. Input contract — LLVM IR after `clang -O1`

What the backend receives from the frontend after `clang -O1 -emit-llvm
-include CQ.h`:

### 3.1 IR shape

- Stock LLVM IR. No custom opcodes, no MLIR dialect, no LLVM fork.
- Standard SSA form, post-`mem2reg` / post-`SROA`. `-O1` is the validated
  floor: `-O0` leaves the values in memory and is unsupported; `-O2` / `-O3`
  inline and reshape the IR the pass keys on and are not the validated floor.
- Plain scalar SSA values: `i1`/`i8`/`i16`/`i32`/`i64` and
  `half`/`float`/`double`/`x86_fp80`. `i128` and `i80` occur only as
  mid-computation intermediates (`tools/opcode_table.yaml`); neither is a
  `cq_theta` / `cq_measure` operand type.
- `@cq_theta_<sfx>`, `@cq_measure_<sfx>` and the register-free
  `void @cq_phi(double)` preserved as opaque external calls. They are plain
  bare declarations (no `readnone` / `readonly`), so LLVM does not CSE or DCE
  them. Every `cq_theta_*` declaration additionally carries `nomerge`
  (`include/CQ.h`) so `-O1` cannot merge two rotations that CQ reads as
  different registers and erase the branch between them. Clang applies the
  attribute at each *direct* call site, so a call through a function pointer
  does not carry it (`include/CQ.h` records the open cases).
- `@__cq_invert_begin` / `@__cq_invert_end` marker calls, each pinned by an
  empty `asm volatile("" ::: "memory")` barrier that the `cq_invert_begin()` /
  `cq_invert_end()` macros emit. See §10.3 — the pass does not lower them yet.
- `!dbg` metadata, preserved through `-O1`, used to source-locate diagnostics.

### 3.2 What the pass recognizes

| Call | Pattern-matched as | What the pass does |
|---|---|---|
| `@cq_theta_<sfx>(x, θ)` | Ry rotation; taint **source** | §5 allocation dispatch + lowering to `cqrt_ry_<W>` |
| `@cq_phi(φ)` | **Branch phase**; introduces and propagates **nothing** (no data operand) | **Kickback** under a tainted condition: flag mint + `cqrt_rz_i1(f, φ)` + strip + free; **deleted** when uncontrolled or classically controlled (§6.1a) |
| `@cq_measure_<sfx>(x)` | Measurement; taint **sink** | Lowered to `cqrt_measure_<W>` (§6.1) |
| `@__cq_invert_begin()` / `@__cq_invert_end()` | Manual inversion bracket | Not lowered yet (§10.3) |

The `cq_theta` and `cq_measure` families are identified by **exact declared
symbol name** taken from a fixed suffix table (`kRows` in
`ir-pass/src/WidthDispatch.cpp`: 16 suffixes — the 14 standard C scalar types
plus `_Float16` and, on x86-64, `long double`), never by name prefix.
`long` / `unsigned long` resolve to `i64` or `i32` from the module's
`DataLayout`. The pass normalizes signedness-bearing suffixes (`_si32` vs
`_ui32`) to width-only runtime symbols (`cqrt_alloc_i32`), since the runtime
ABI is width-only (§6.4).

Every recognized declaration is prototype-validated, whether or not it is
called. A wrong prototype declines loudly (`cq rotation lowering: unsupported
declared prototype for <name>`, and the `cq measure lowering` analogue). A
name outside the suffix table (for example `cq_measure_xyz999`) is not part of
the surface and is treated as an ordinary external.

`@cq_phi` is matched by **exact name** and must be `void(double)`. The retired
register form `@cq_phi_<sfx>(x, φ)` is a **reserved name**: `CQ.h` no longer
declares it, so it can only reach the pass from hand-written IR or a stale
header, and any **use** of it declines loudly with `cq rotation lowering:
retired register-form cq_phi_<sfx>; use the register-free void cq_phi(double)`
(`lowering_reject_legacy_phi_register_form*.ll`). A declaration with no call
site is not diagnosed (`lowering_legacy_phi_decl_prototype_family.ll` records
what is lost by that). The reason the register form is gone is technical, not
stylistic: `cqrt_rz_<W>` is **tensored** — Rz on each qubit of the register —
so a phase applied through it marks `(−1)^popcount(target)` and can never mark
`|0…0⟩`. A branch phase carried on a flag has no such problem (§6.1a).

### 3.3 What is deliberately not in the input

| Surface | Status | Why |
|---|---|---|
| `qint_mid_t` / `q*_mid_t` struct types at signatures | Absent | Allocation is gate-triggered (§5); plain `mem2reg`-friendly SSA carries the taint signal |
| `@cq_init_<W>` calls | Absent | `@cq_theta` is the taint source; the rotation site *is* the initialization site |
| `@cq_when_begin` / `@cq_when_end` calls | Absent | Controlled regions are recovered structurally from tainted branch conditions (§8) |
| `__cq_q_<f>_<mask>` mangled specialization calls at the input | Absent | Specialization synthesis is internal to the pass (§7); the input has plain calls to `@f` |

---

## 4. Forward taint propagation

The first analysis the pass runs, and the substrate every later step is built
on. Forward data flow over SSA values (`propagate` in
`ir-pass/src/TaintPropagation.cpp`, a work-list that processes each value once).

### 4.1 Sources, sinks, propagation rule

```
taint_sources = { return value of every @cq_theta_<sfx> call }

tainted(v) iff
    v ∈ taint_sources, OR
    v is produced by an instruction that USES a tainted value,
      except across:
        - a @cq_measure_<sfx> call (the sink: its result is classical),
        - the angle operand (arg 1) of a rotation, when the value reaches the
          rotation ONLY as its angle,
        - the result of a call to a visible callee that the specializer
          predicts returns a classical value (§7.2)

a tainted `ret` taints the result of every direct call to its function
```

The angle exclusion is **per operand use, not global**: a value that is also
used as an arg-0 handle elsewhere stays tainted. A quantum-derived angle
declines loudly (`cq rotation lowering: unsupported quantum-derived rotation
angle`, and `cq controlled lowering: rotation angle under quantum control`
inside a tainted region). Never allocate a qubit for an angle.

`cq_phi` is excluded from the source set and from the propagation relation
alike — it has no data operand to propagate through. `void cq_phi(double φ)`
is a *branch phase*: it multiplies the amplitude of the branch it sits in by
`e^{iφ}`, so it is ordered by the **block it sits in**, not by data
dependence. It introduces no taint (a phase is not superposition), propagates
none, and allocates nothing.

`cq_measure_<sfx>` is the sole sink: its return value is classical regardless
of input. Downstream uses are classical SSA and are left alone by every later
step.

Control flow does **not** taint by shadow. A `br` / `select` / `switch` whose
*condition* is tainted is handled by the control emitters (§8), which mint the
merge rails; taint is then **re-seeded from those rails** by a second
propagation (`repropagateControlMerges`, §2 stage 4).

### 4.2 What the propagation gives the rest of the pipeline

After propagation the pass holds a `TaintSet` (`ir-pass/include/TaintPropagation.h`):

- the set of tainted SSA values (plain `i32`/`f32`/`f64`… before lowering,
  `i32` handles after);
- the collected `cq_theta`, `cq_phi` and `cq_measure` call sites, so later
  stages do not re-walk the module;
- the tainted call sites — calls with at least one tainted argument, which
  drive §7 specialization;
- the tainted branch conditions, which drive §8.

Every pointer-keyed table in the set is self-cleaning on IR deletion
(`ScrubOnDelete.h`), so a stage that erases an instruction cannot leave a
dangling key that a fresh allocation at the same address would inherit.

### 4.3 Why this works on stock LLVM SSA

`Value::users()` and work-list data flow are stock LLVM APIs available from
the new PassManager; no LLVM source modification is needed (see
[`llvm-implementation.md`](./llvm-implementation.md)). The same propagation
runs inside cloned bodies during specialization (§7.2) over a fresh, disjoint
`TaintSet`, so no special machinery is needed to re-classify after a clone.

---

## 5. Allocation lowering

Qubit allocation is **gate-triggered**: `cqrt_alloc_<W>` is inserted only at a
`@cq_theta_<sfx>` call whose operand is still classical at lowering time. A
variable that is declared, mutated arithmetically and never rotated never
touches the qubit substrate. (`lowerRotations`,
`ir-pass/src/RotationLowering.cpp`.)

### 5.1 The dispatch rule at `@cq_theta` call sites

For each `@cq_theta_<sfx>(operand, θ)` call:

- If `operand` is classical (not tainted): **insert allocation**. Emit
  `%h = call i32 @cqrt_alloc_<W>(operand)` immediately before the call, then
  lower the theta to `cqrt_ry_<W>(%h, θ)`. The theta's result SSA value is
  replaced by `%h`, and every downstream use is rebound.
- If `operand` is tainted: **no allocation**. The operand already is a handle;
  lower the theta to `cqrt_ry_<W>(operand, θ)`, and the result continues to
  reference the same handle.

Whether a theta is a *source* or *chained* is decided at **final** taint,
after both control rounds.

```llvm
; before — classical operand
%a1 = call i32 @cq_theta_si32(i32 %a, double 5.0e-01)
; after
%h_a = call i32 @cqrt_alloc_i32(i32 %a)            ; allocate, init to %a
call void @cqrt_ry_i32(i32 %h_a, double 5.0e-01)   ; Ry(0.5)
; downstream uses of %a1 are replaced by %h_a
```

```llvm
; before — %h_a is already a handle from a prior allocation
%a2 = call i32 @cq_theta_si32(i32 %h_a, double 3.0e-01)
; after — no new allocation
call void @cqrt_ry_i32(i32 %h_a, double 3.0e-01)   ; Ry(0.3) on the existing register
; downstream uses of %a2 are replaced by %h_a
```

A theta inside a tainted-condition arm whose register is disjoint from every
wire the condition reads is hoisted to the predecessor and lowered as
`cqrt_ry_<W>_controlled(flag, handle, θ)` instead (§8.3).

### 5.2 Why dispatch on operand state

This dispatch is the structural mechanism behind the "register is allocated
exactly once on first rotation" guarantee the frontend documents (see
[`frontend.md`](./frontend.md) §3.2 and §4). A user who writes
`cq_theta(&a, 0.1); cq_theta(&a, 0.2);` allocates once and rotates
twice; the pass sees the same dispatch fire twice, once with classical `%a`
and once with tainted `%h_a`.

The value passed to `cqrt_alloc_<W>` is the integer (or float) bit pattern at
the moment of first rotation — the register's initial classical value.

A `cq_theta` whose seed is `undef` / `poison` is allocated at zero, silently
(`normalizeUndefRotationSeed`, declared in `RotationLowering.h`): an undefined
seed may be refined to any value, and the pass picks zero.

---

## 6. Opcode lowering and mixed-operand dispatch

After taint analysis identifies tainted stock LLVM opcodes, the pass
substitutes each with a call to the corresponding template. Templates are
declared in [`runtime/cq_templates.h`](../runtime/cq_templates.h),
autogenerated from `tools/opcode_table.yaml`; the pass picks the symbol from
opcode + width + operand shape (`ir-pass/src/TemplateName.cpp`).

### 6.1 The lowering map

| Tainted opcode / intrinsic | Lowered |
|---|---|
| `call @cq_theta_<sfx>` (classical operand) | `cqrt_alloc_<W>(value)` + `cqrt_ry_<W>(handle, θ)` (§5.1) |
| `call @cq_theta_<sfx>` (tainted operand) | `cqrt_ry_<W>(handle, θ)` (§5.1) |
| `call @cq_phi` inside a **tainted-condition** arm | **kickback** — flag mint, `cqrt_rz_i1(f, φ)` *uncontrolled* on the flag, compare `_unc` strip, `cqrt_free(f)` (§6.1a) |
| `call @cq_phi` uncontrolled, or under a **classical** condition | **deleted** — a global phase, unobservable (a documented semantic, no diagnostic) |
| `call @cq_measure_<sfx>` | `cqrt_measure_<W>(handle) → value` |
| tainted binary op, both operands tainted | `cq_template_<op>_<W>(%h_a, %h_b)` (QQ) |
| tainted binary op, one classical operand | `cq_template_<op>_<W>_hl(%h, C)`; `_lh(C, %h)` for a non-commutative op with the literal on the left (§6.2) |
| tainted `icmp` / `fcmp` | `cq_template_icmp_<pred>_<W>[_hl](…)` / `cq_template_fcmp_<pred>_<W>[_hl](…)`, returning a **flag handle** |
| tainted `sext`/`zext`/`trunc`/`fpext`/`fptrunc`/`sitofp`/`uitofp`/`fptosi`/`fptoui`/`bitcast` (the in-scope pairs) | `cq_template_<cast>_<from>_to_<to>(%h)` |
| tainted `fneg f<W>` | `cq_template_fneg_<W>(%h)` |
| tainted `add` / `sub` / `xor` with a classical immediate that reassigns a rail whose parent has no later data use, and the recognized loop-carried rail self-update | in place: `cqrt_addc_<W>(h, imm)` (a `sub` by a constant is an add of its negation) / `cqrt_xorc_<W>(h, imm)` — void, no fresh rail (`classifyInPlaceReassignment`, `ArithLowering.cpp`; `LoopLowering.cpp`) |
| curated `llvm.*` intrinsics (bit and rotate idioms, min/max/abs, saturating add/sub, `sqrt`, the rounding family, `fabs`/`copysign`/`fmin`/`fmax`, `fma`/`fmuladd`, `lrint`/`llrint`) | `cq_template_<op>_<W>[…]` additive producers (§7.1) |
| tainted `select`, merge `phi`, `switch` | control lowering, §8 |
| tainted-index array access | `cqrt_qram_*`, see below |
| tainted `printf` / `putchar` integer argument | appended to a kept output tape, `cqrt_tape_*` (`IOSinkLowering.h`) |
| `@__cq_invert_begin` … `@__cq_invert_end` | not lowered yet (§10.3) |

An out-of-place template returns a **fresh handle** for its result; the pass
replaces every downstream use of the original SSA value with it. After
lowering the IR contains no `@cq_theta_*` / `@cq_measure_*` / `@cq_phi` call
and no tainted stock opcode — only `cqrt_*` runtime calls and `cq_template_*`
template calls, with classical control flow threading them.

Tainted-index reads and stores of a bounded, known-shape array are lowered by
`QramLowering.cpp` to `cqrt_qram_alloc_<W>` / `cqrt_qram_load_<W>` /
`cqrt_qram_store_<W>` (and `_controlled` for a store under tainted control,
`GuardedStoreArmEmit.h`); static-index memory is scalarized away by clang
before the pass sees it. What happens to a local array whose loaded value is
measured or returned (uncompute versus leak, and the coherent-return decline)
is written up in
[`design/qram-local-array-uncompute.md`](./design/qram-local-array-uncompute.md).

### 6.1a `@cq_phi` — the branch phase by kickback

`void @cq_phi(double φ)` carries **no register**. It is recognized by exact
symbol name and its prototype must be `void(double)` (§3.2).

**Under a tainted condition it lowers by kickback**, on the flag the control
path already mints for the compare — no work rail, no `cqrt_cswap` route and no
controlled gate:

```
mint     cq_template_icmp_<pred>_i<W>_hl(h, k)   -> f    ; f = c(q) on a |0> ancilla
gate     cqrt_rz_i1(f, φ)                                ; UNCONTROLLED, one qubit
strip    cq_template_icmp_<pred>_i<W>_hl_unc(f, h, k)    ; f back to |0> on EVERY branch
free     cqrt_free(f)
```

Three shapes follow. The counts are read from the accept fixtures named
beside them (`ir-pass/test/`).

- **A `¬flag` arm** — the gate arm is the *false* successor, which is what
  `clang -O1` usually produces — keeps the self-inverse `cqrt_x(f)` bracket
  around the gate. The bracket is **one pair per arm**, never per gate, and a
  merge-tail angle contributes its own arm-polarity groups, so one region can
  legitimately emit more than one pair. `control_phase_kickback_negated.ll`:
  1 `cqrt_rz_i1`, 2 `cqrt_x`, 1 `cqrt_free`.
- **`if/else`** puts **one gate per arm** on the **one** minted flag — the true
  arm's `cqrt_rz_i1(f, φ_T)` as-is, the false arm's inside the `cqrt_x`
  bracket — with one mint, one strip and one free for the pair.
  `control_phase_kickback_ifelse_tail_phi.ll`: 3 `cqrt_rz_i1`, 2 `cqrt_x`,
  1 `cqrt_free`.
- **N `cq_phi` calls in one arm** emit **N** `cqrt_rz_i1` gates on that flag,
  in source order, with one mint / strip / free. Nothing is summed at compile
  time: each angle is passed through verbatim, so no IEEE-rounding hazard
  arises. `control_phase_kickback_two_calls.ll`: 2 `cqrt_rz_i1`, 0 `cqrt_x`,
  1 `cqrt_free`.

The negation is never a `cqrt_x` on a **user register**. When the control is a
user rail (a bare `_Bool` register condition), the arm that must fire on
`b == 0` uses the diagonal `cqrt_rz_i1(b, −θ)`, since `X·P(θ)·X = e^{iθ}·P(−θ)`
and the leftover `e^{iθ}` is a global phase.

**Beyond the single compare, the shape of the condition changes only what the
flag is made of, never the gate.** A compound condition
(`if (q == 5 && r == 3) cq_phi(θ)`) mints one leaf flag per tainted compare and
combines them into a root ancilla — `cqrt_toffoli` for AND, the OR and XOR
node emissions the select merge also uses (`CondTreeEmit.cpp`) — puts the ONE
`cqrt_rz_i1` on that root, and tears the network down LIFO. A depth-2 nest
(`if (a) { if (b) { cq_phi(θ); } }`) is the same thing reached by a different
syntax. A `switch` puts one per-case equality flag under each arm's gate.

**Real traces, from committed goldens** (`tests/e2e/*.expected.log`):

```
# slice_control_seq_grover — the flat diamond, un-negated arm
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_rz_i1(h1, 0x1.921fb54442d18p+1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)

# slice_control_phase_angle_select — the folded if/else: TWO gates,
# ONE flag, the false arm's inside the cqrt_x bracket, NO subtraction
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_x(h1)
cqrt_rz_i1(h1, 0x1.3333333333333p-2)
cqrt_x(h1)
cqrt_rz_i1(h1, 0x1.ccccccccccccdp-1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)

# slice_control_phase_nest — the depth-2 nest: leaf flags, a toffoli
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

`slice_control_phase_nest.c` (the nest) and `slice_control_phase_andcond.c`
(`if (a == 5 && b == 3)`) produce **byte-identical goldens**, gated by the
ctest entry `e2e-phase-nest-andcond-identical`: the nest is the condition tree
reached by a different syntax, not a separate mechanism.

**Uncontrolled — or classically controlled — `@cq_phi` is deleted.** It
multiplies the whole state vector by a scalar, which no measurement can
observe. This is a documented semantic and not a diagnostic.

**The emitted gate is not adjointable.** The uncompute spine must never
reverse-play a kickback gate: its inverse would cancel the very phase that is
the answer, and the flag it sits on is stripped and freed inside the region.
Every emitted kickback gate therefore carries an instruction-metadata
membership record, `!cq.branchphase` (`ChainWalk.cpp`), that the spine's
in-place-gate, basis-preservation and `EmitInverse` predicates refuse first.
Read the `cqrt_rz(q, φ) → cqrt_rz(q, −φ)` row of §10.1 with that exception.
The record is *instruction metadata* rather than a `Value *` set so that it
dies with its instruction, survives `CloneFunctionInto` (specialization), and
is visible in the lowered `.ll` that fixtures and `free_pairing_check.py`
read. It is asked as **membership of the instruction**, never by name —
`cqrt_rz_i1` alone does not identify a kickback gate. Every emitter site
records it: `#!cq.branchphase` equals `#cqrt_rz_i1` in each of the three
fixtures above (their `MDCNT` and `MDTAG` prefixes).

A register-wide Z rotation is the classical per-bit loop
`for (i…) if ((q >> i) & 1) cq_phi(θ)` — see
[`frontend.md`](./frontend.md) §3.3.

### 6.2 Mixed-operand dispatch: the `_hl` and `_lh` variants

When a tainted opcode has one tainted operand (a handle) and one classical
operand, the pass emits the `_hl` (handle + literal) or `_lh` (literal +
handle) variant. The runtime treats the classical operand as a literal, **not**
as a quantum register — it is never promoted through `cqrt_alloc_<W>` and no
qubit is allocated for it. The classification is by taint membership, not by
`isa<Constant>` (`ArithLowering.cpp`):

```llvm
; before
%c = add i32 %a, 5                                 ; %a tainted, 5 literal
; after
%h_c = call i32 @cq_template_add_i32_hl(i32 %a, i32 5)
```

- Both operands tainted → the QQ template. For a commutative opcode the
  operands are ordered by rail birth order for a stable trace; for a
  non-commutative one source order is preserved because it is semantic.
- One operand tainted, commutative opcode → always `_hl(handle, literal)`,
  whichever source side held the literal.
- One operand tainted, non-commutative → `_hl` with the handle on the left,
  `_lh(literal, handle)` with the literal on the left (`100 - x`, `3 << x`).
  The YAML carries the `_lh` shape on every axis for `sub`, `sdiv`, `udiv`,
  `srem`, `urem`, `shl`, `lshr`, `ashr`, `fsub`, `fdiv`, `frem`.
- Compares never have an `_lh` form: a literal on the left is canonicalized by
  flipping the predicate (`5 < x` ⇒ `x > 5`).

Both QQ and `_hl`/`_lh` return a fresh handle
(`int32_t cq_template_add_i32(int32_t a_handle, int32_t b_handle)` in
[`runtime/cq_templates.h`](../runtime/cq_templates.h)).

### 6.3 The opcode surface

The templates cover the data-carrying LLVM opcodes below, at the widths the
YAML lists (`tools/opcode_table.yaml`, the single source of truth):

```
int arith    add sub mul sdiv udiv srem urem        × {i1,i8,i16,i32,i64,i128}
int bitwise  and or xor shl lshr ashr               × {i1,i8,i16,i32,i64,i128}
                                                       (i80: and or shl lshr only)
fp arith     fadd fsub fmul fdiv frem               × {f16,f32,f64,f80}
fp unary     fneg                                   × {f16,f32,f64,f80}
int compare  icmp {eq ne slt sgt sle sge ult ugt ule uge}  × {i1,i8,i16,i32,i64,i80}
fp compare   fcmp {oeq une olt ogt ole oge one ord uno ueq ugt uge ult ule}
                                                    × {f16,f32,f64,f80}
casts        sext zext trunc fpext fptrunc sitofp uitofp fptosi fptoui bitcast
                                                    × the pairs the YAML lists
```

`i128` and `i80` are mid-computation intermediates only, never a
`cq_theta` / `cq_measure` width, and `i80` exists solely for the `fp80`
bit-pattern extraction idiom. `f128` is not shipped. A predicate, opcode or
width outside the YAML has **no generated template** and declines loudly
rather than minting a phantom symbol.

Memory (`load`, `store`, `getelementptr`) and the structural ops (`phi`,
`select`) are not part of the template grid: a tainted-condition `select` /
merge `phi` / `switch` is control lowering (§8), tainted-index array access is
QRAM (§6.1), and a tainted value that is stored to memory or reaches any other
instruction the pass does not lower declines at the taint-escape guard
(`cq taint escape: tainted value stored to memory`, `… reaches an unsupported
instruction`). Vector/SIMD values and transcendental functions without an
injected body are likewise not lowered yet — see §7.

### 6.4 Width and signedness normalization

The runtime ABI is width-only: `signed char` and `unsigned char` both lower to
`cqrt_alloc_i8` and to `cq_template_add_i8`. Signedness is implicit in the
LLVM opcode at the call site (`add nsw` vs `add nuw`, `icmp slt` vs
`icmp ult`) rather than in the runtime symbol. This is asymmetric with the
frontend intrinsic surface, which **does** carry signedness
(`cq_theta_si32` vs `cq_theta_ui32`) so the source-level C type is preserved.
The pass bridges the two: see [`frontend.md`](./frontend.md) §3.1,
[`ir-pass/src/WidthDispatch.cpp`](../ir-pass/src/WidthDispatch.cpp) (the
`kRows` suffix-to-width table) and the preamble of
[`runtime/cq_runtime.h`](../runtime/cq_runtime.h). A runtime handle is
**always `i32`** regardless of the logical width; the logical width of a
handle is recovered from the callee name or from `TaintSet::HandleWidth`,
never from the laundered `i32` SSA type.

---

## 7. Call-graph specialization (function lifting)

A plain classical function should work with tainted arguments without source
modification. The pass provides three routes, by what is visible at pass time:

1. a curated `llvm.*` intrinsic lowers directly to a template (§7.1);
2. a callee whose **body is visible** is cloned on its taint signature and
   wrapped (§7.2) — this includes a library function whose real source was
   injected into the module before the pass;
3. anything else — an opaque external with no visible body — declines loudly
   (§7.4).

### 7.1 Curated intrinsics, and library functions by source injection

A library function means its real implementation, **injected as source**
before `cq-lowering` so the pass sees stock opcodes. The one exception is a
**direct route**: an operation whose reversible circuit a backend supplies
(hardware-backed, or with a Bennett.jl implementation as reference) lowers to
ONE template call, matched by exact `Intrinsic::ID`. This is what the owner
means by a *hand-written* function: the compiler emits the call and the
backend writes the circuit. CQ never writes its own C or IR implementation of
a library function to stand in for the real source (bd `3c6m.78`).

What the pass does curate is a set of `llvm.*` intrinsics, matched by exact
`Intrinsic::ID` (never by name prefix) and lowered to additive-producer
templates (`IntrinsicLowering.cpp`, `tools/intrinsic_table.yaml`, generated
into `runtime/cq_intrinsic_templates.{h,c}`):

- bijections (forward + `_inv` + `_unc`): `bswap`, `bitreverse`, and
  `fshl`/`fshr` in the rotation form (both value operands equal, constant
  amount);
- non-injective but pure and total (forward + `_unc` only): `smin`/`smax`/
  `umin`/`umax`, `abs`, `ctpop`, `ctlz`/`cttz`, the saturating
  `uadd`/`sadd`/`usub`/`ssub`, and the hardware-backed fp family — `sqrt`,
  `floor`/`ceil`/`trunc`/`round`/`rint`/`nearbyint`, `fabs`, `copysign`,
  `fmin`/`fmax`, `fma`/`fmuladd` — at `f16`/`f32`/`f64`/`f80`.

`lrint` / `llrint` lower through `tools/libm_table.yaml`
(`runtime/cq_libm_templates.{h,c}`). Each of these is reversible because the
`_unc` twin **recomputes `f(sources)` from the still-live source operands** and
XORs the result rail back to `|0⟩`; it never recovers the input, so it is
sound for a non-injective `f` only while the sources stay live.

A tainted call to any other external — the transcendentals, `pow`, direct
libm entry points — has no template and declines loudly
(`cq taint escape: tainted value consumed by an unknown callee`) unless its
source has been injected. `tools/cqc` injects it (bd `3c6m.72`): the build
compiles openlibm at a pinned commit to one bitcode bundle
(`tools/libm_bundle.py`, target `cq_libm_bundle`, installed next to the pass)
in which every definition is renamed `__cq_libm_<name>` and only the math.h entry
points stay external, and `cqc` `llvm-link`s it into every program that uses a CQ
primitive (a purely classical program never sees it). The pass (`LibmBinding.h`) retargets only a call with a
tainted operand — to a declared `@<name>`, or to an `@llvm.<fn>.<ty>` intrinsic
LangRef defines equal to the libm function — to `__cq_libm_<name>` when that body
is public and has the call's exact type and calling convention (a program's own
external definition of the name wins), and the specializer lifts it like any
visible classical callee (§7.2; no inlining). A lifted math.h call inherits the
lifter's open stale-argument defect (bd `r2j3.6`). A classical call keeps its callee and the
system libm, and the pass erases every bundle body nothing uses, so a purely
classical program is unchanged. A curated intrinsic keeps its direct template,
and a tainted unary libcall whose intrinsic is curated at its width (`@sin(double)`
on a `-fmath-errno` target) is rewritten to it first. Since bd `3c6m.71` (owner
ruling 2026-10-06) the curated set includes `sin`, `cos`, `tan`, `asin`, `acos`
and `atan` at `f64` only: one backend call `cq_template_<fn>_f64` whose reference
circuit is Bennett.jl's `soft_<fn>` (musl ports, ≤1 ULP reference; the contracts
are recorded in `tools/intrinsic_table.yaml`). `atan2` has no LLVM 19 intrinsic and
is not on this route yet (bd `3c6m.77`).
The bundle forwards every name with a direct route at a width to its intrinsic
(`wprobe.direct_shims`, read from `tools/intrinsic_table.yaml`), so a lifted body
that calls `sin` on a `double` (openlibm's `tgamma`) reaches the same one-call
lowering as a user's call. `sinf`/`cosf`/`tanf` and `sinl`/`cosl`/`tanl` have no
direct route and get openlibm's source, which does not lower yet (bd `3c6m.79`). The census (`runtime_census.py`) compiles
every probe through `tools/cqc`; per NORTHSTAR goal 2 a function counts only when
it compiles for non-trivial input.

### 7.2 Clone-on-taint

For a callee whose body is visible (user code, `llvm-link`ed libraries,
injected library source), the pass clones the callee keyed by the call site's
**taint signature**, a bit-mask of which argument positions are tainted:

1. **Detect** (`detectSpecializations`, pure analysis, before any mutation):
   every direct `CallInst` with a tainted argument gets a mask (bit `i` ⇔
   argument `i` tainted, LSB = parameter 0). One authoritative predicate,
   `classifyCandidate` (`SpecializeReject.cpp`), decides whether the site is
   liftable; only proven-liftable sites enter the plan.
2. **Look up** `(callee, mask)` in the clone cache; if present, retarget and
   stop.
3. **Clone** (`specialize` in `Specialization.cpp`, the clone itself `cloneFor`
   in `SpecializeClone.cpp`): clone the callee, name it
   `__cq_q_<callee>_<mask>` (the mask rendered MSB-first, zero-padded to the
   arity, parameter 0 rightmost — `__cq_q_ipow_01`), and seed taint on the
   tainted parameters over a **fresh `TaintSet` disjoint from the caller's**.
4. **Lower** the clone with the scoped data lowering (opcode lowering,
   PredMux flatten, QROM reads) and capture its forward `cq_template_*` stream.
5. **Bennett-wrap** the clone (`BennettWrap.cpp`): allocate an output rail,
   copy the result rail into it (`cqrt_copy_<W>`, *before* the reverse, since
   the reverse zeroes the result rail), reverse the captured stream with the
   whole-DAG adjoint (`emitInverseChain`), and free the scratch rails only
   after the reversal succeeds. Borrowed parameters are read-only and never
   freed. The clone therefore implements `|x⟩|0⟩ → |x⟩|f(x)⟩` and leaves no
   ancilla behind. A void `@<clone>_unc(i32 out, <clone params>)` twin is
   synthesized so a nested or top-level uncompute can reverse a call to the
   clone.
6. **Retarget** the call site with `CallInst::setCalledFunction`, and reconcile
   the call result's taint with what the clone actually returns.

The original function is left intact for classical callers.
Specialization never runs `uncompute`: the single module-wide `uncompute` (§9)
owns reversal of the caller, and the clone bodies are invisible to it. The copy
in step 5 is sound because a clone body is purely classical — it contains no
`cq_*` primitive, so its returned value is basis-valued, and a basis copy
cannot dephase a phase that is not there.

### 7.3 The worklist

```
plan = detectSpecializations(module)     # tainted-arg direct calls → Pending / Diagnosed;
                                         # re-run on the round-2 taint, so a call whose argument
                                         # only became quantum after control lowering is found too
for site in plan.Pending:                # drained once by `specialize`, after both control rounds
    key = (callee, mask(site))
    if key not in cache:
        cache[key] = clone_seed_lower_wrap(callee, mask)     # §7.2 steps 3–5
    site.setCalledFunction(cache[key])
```

An inner call inside a clone body to another visible liftable callee is
lifted the same way (nested wrap; the two clone bodies keep disjoint taint
sets). Recursive call graphs are **not** admitted (§7.4).

### 7.4 What is not lifted

`classifyCandidate` accepts a **visible, purely classical, non-recursive,
straight-line value function**, plus a constant-table read and a liftable
`select`/`phi` (which the clone's flatten turns into a controlled copy). A
candidate that fails is rejected with a source-located diagnostic at the
offending instruction. Today's rejection set (`SpecializeReject.h`):

Messages below are prefixed `cq specialization: ` in the source.

| Reject | Message |
|---|---|
| recursion (self or mutual) | `recursive callee has no static depth bound` |
| callee contains a `cq_*` primitive | `callee contains a quantum primitive (cq_*); only classical functions are lifted` |
| callee measures | `callee measures under quantum lift` |
| tainted control flow inside the callee (beyond the liftable `select`/`phi`) | `callee contains tainted control flow under quantum lift` |
| a tainted argument, or the return, whose width has no reversible handle copy: anything other than `i32` and `f16`/`f32`/`f64`/`f80` (so `i8`/`i16`/`i64`/`i128`, `fp128`, vectors) | `floating-point quantum argument or return has no reversible copy` (the wording predates the integer cases) |
| arity above the 64-parameter mask | `callee arity exceeds the 64-parameter specialization mask limit` |
| interposable / derefinable linkage | `callee has a non-link-exact definition (interposable/derefinable linkage); the linker may bind a different body` |
| returned value is `undef` / `poison` | `callee return value denotes no value (undef/poison)` |
| inline asm, `syscall`, atomics, EH, `setjmp`/`longjmp`, volatile access or other memory access, vector/SIMD, an indirect or body-less nested call | `callee contains a non-reversibilizable construct under quantum lift (<kind>)` |
| a `musttail` forward of a `preallocated` argument | the same non-reversibilizable message (no valid alternative spelling exists) |

A declaration-only or indirect callee *at the call site* is a shape reject: the
site is not in the plan, so the taint-escape guard fires `tainted value
consumed by an unknown callee` on it.

Each row is a **default position of today's pass**, not a fundamental
impossibility. Under NORTHSTAR goal 1 the walls that genuinely stand are
cloning, quantum data reaching classical code without `cq_measure`, an
unbounded quantum-dependent recursion, and an opaque external with no body to
lift; the rest (tainted control flow inside a lifted callee, a quantum argument or
return of a width other than `i32`/`f16`/`f32`/`f64`/`f80`, memory access, and so
on) are gaps to close. A quantum `f16`/`f32`/`f64`/`f80` argument or return
lifts: the clone takes it as an `i32` handle and copies the result out with
`cqrt_copy_f<W>` ([`quantum-classical-handling.md`](./quantum-classical-handling.md) §7). No flag inserts a
measurement at a function boundary: the compiler never inserts a measurement
the user did not write.

---

## 8. Quantum control flow

A branch whose condition is tainted is a quantum branch: the program is in a
superposition of "taken" and "not taken", and the branch's arms execute
coherently under the condition. The pass recovers the controlled region
**structurally** from the LLVM CFG and SSA; there is no user-emitted marker.

It does **not** work by rewriting every gate in the region's shadow into a
`_controlled` variant. It classifies each arm by what it does to quantum state
and lowers each class by the method that is sound for that class:

- a **phase** arm puts the answer on the **flag** (kickback, §6.1a);
- a **value** (classical-permutation) arm computes on the original register
  unconditionally and **merges by a controlled basis copy** into a fresh `|0⟩`
  rail;
- a **rotation** (Ry) arm controls the rotation **in place**.

⚠ A phase must never be merged by a basis copy: a CNOT copies a basis *label*,
not a *phase*, so the source's uncompute cancels the very superposition that
was the answer and the state dephases. That is why the phase arm is the
kickback.

### 8.1 Identifying and recovering a region

`detectControlRegions` (`ControlDetect.cpp`) scans for a `br i1`, `select` or
`switch` whose condition or scrutinee is tainted, recovers the region shape by
SSA-value identity **before any mutation**, and either hands the region to an
emitter or declines it loudly. A tainted control construct is never passed to
the backend as classical control over quantum state; there is no third path.
Diagnostics use the dialect `cq controlled lowering: <shape> under quantum
control`.

Two normalisers run before detection, because `-O1` reshapes what the
detector would otherwise see (it sinks and hoists ops into arms, fuses
consecutive regions with equivalent conditions into one diamond with several
merge φs, folds an if/else over one register into a select on the angle, and
swaps branch polarity so the gate arm is often the *false* successor):

- `MergePhiPeel` turns each independent merge φ of a fused multi-φ diamond
  into a `select` with its own compare clone, so the region has the one merge
  φ the classifiers require.
- `flattenPredMuxRegions` (`PredMuxFlatten.cpp`) rewrites a maximal eligible
  **acyclic** tainted region — arbitrary-depth nests of tainted `br` / `switch`
  over pure speculatable dataflow, DAG reconvergence, N-incoming merges — into
  straight-line code: edge predicates as (possibly inverted) compares composed
  with `and`/`or`, merge φs as chained selects. It mints no gate; the result is
  the tainted-`select` program the select merge already lowers.

The condition's flag is minted by the ordinary compare lowering
(`cq_template_icmp_<pred>_<W>_hl(q, k) → f` on a `|0⟩` ancilla), and **stripped
by the compare's `_unc`** at the end of the region, so `f` returns to `|0⟩` on
every branch and its `cqrt_free` is a proven-`|0⟩` free. A **bare `_Bool`
register condition** (a `br i1` with no compare) is the exception: the register
*is* the flag, it is read only as a control, and it is never `cqrt_x`-bracketed
and never freed.

### 8.2 Arm classes

`ArmClassify.cpp` classifies each arm, and a region is lowerable only when its
arms are homogeneous:

- **Phase** — the arm holds only `cq_phi` calls.
- **Value** — the arm is a pure linear chain of supported tainted integer
  operations over the register the merge reads. Its **classical cone** — the
  arm's non-chain instructions, proven untainted, side-effect-free,
  non-escaping and speculatable — is recorded on the region and hoisted with
  it, and emits no gate.
- **In-place rotation** — the arm is one tainted-operand `cq_theta` on a
  register whose physical wire is disjoint from every wire the condition
  reads. The same shape with a *fresh* register is **controlled state
  preparation** (`int r = SEED; if (COND) { r = SEED; cq_theta(&r, θ); }`, whose
  arm call after `-O1` is `cq_theta_<sfx>(SEED, θ)`).

An arm that value-rewrites a variable the condition reads (a *clobber*) is not
lowered; a phase arm beside a value arm (`mixed phase/value arm`) is not
lowered yet.

### 8.3 Lowering by shape

| Shape | Mechanism | Emitter |
|---|---|---|
| **phase arm** — flat diamond, if/else, folded angle select (Rz stem), compound condition tree, depth-2 nest, `switch`, rolled inside a classically bounded loop | **kickback**: mint flag → `cqrt_rz_i1(f, θ)` uncontrolled per `cq_phi` → `_unc` strip → free; a `¬flag` arm on an ancilla is `cqrt_x`-bracketed, on a rail it is `rz(−θ)` | `emitPhaseKickbackRegion`, `emitPhaseKickbackNestRegion`, `emitKickbackGroup` (`SwapRouteEmit.cpp`); `SwitchRouteEmit.cpp`; `AngleSelectEmit.cpp` |
| **value arm** — diamond, if/else | **controlled-copy merge**: hoist the arm's chain into the predecessor so it runs unconditionally on the original register, build a `select`, hand it to the select merge | `emitValueRegion` → `SelectMergeEmit` verbatim |
| tainted-condition integer- or scalar-fp-data **`select`** | mint flag; `%out = cqrt_alloc_<W>(0)`; `cqrt_copy_<W>_controlled(f, true_val, %out)`; then `cqrt_x(f)`, `cqrt_copy_<W>_controlled(f, false_val, %out)`, `cqrt_x(f)`; compare `_unc` strip; **one** `cqrt_free(f)` | `SelectClassify` + `SelectMergeEmit.cpp` |
| tainted-scrutinee **`switch`** | homogeneous phase: per-case equality flag + kickback. Homogeneous value and all-constant data-mux: **preload + XOR-delta** — `cqrt_copy_<W>(p, out)` once, then per case a hoisted chain, a QQ `xor` delta, an equality flag and one `cqrt_copy_<W>_controlled`. An equality-guarded diamond (`if (q == k) cq_phi(θ)`) is an ordinary phase arm: `EqFoldArm`'s const-fold re-anchor served only the retired register form | `SwitchClassify` + `SwitchArmProve` + `Switch{Route,Value,DataMux}Emit` |
| **in-place Ry arm** on a register disjoint from every condition wire | the arm's theta is hoisted and lowered as `cqrt_ry_<W>_controlled(f, h, θ)`; the rotated register is then **pinned live** (never reverse-played, never freed — `Ry(θ)\|0⟩ ≠ \|0⟩`). A negated arm is spelled by additivity, `ry(h, θ); ry_controlled(h_b, h, −θ)`, never `cqrt_x` on a user register | `emitInPlaceRotationRegion` |
| **in-place Ry arm on the condition's own register** (`if (q > 5) cq_theta(&q, θ)`, acyclic, compare condition) | the flag is minted, then `cqrt_ry_<W>_controlled(f, h, θ)` (a `¬flag` arm `cqrt_x`-brackets the flag, an ancilla); **no strip and no free**: after the Ry the predicate is not a function of `q`'s basis, so the flag is left allocated holding the pre-Ry predicate. Exception: when every tainted compare operand is a record the program reads after the region (`int d = q & 6; if (d == 2) …; … d …`), the strip after the gate is exact and the flag is stripped and freed there (`CondFlagKept` false). A template condition chain, and since bd `p3kd.13` a lifted call's `__cq_q_*` result (its Bennett twin as the adjoint), is discharged before the gate; a chain rail the program reads after the gate stays allocated as its own data; a chain rail that is neither (a lifted result whose twin cannot be synthesized, bd `ln16`) is refused loudly by a late postcondition, `declineUndischargedKeptFlagChains`. M-A warns `non-diagonal gate over a live derived record` at the gate (bd `dm7f.4`) | same, `ControlRegion::CondFlagKept` |
| controlled **state prep** | `cqrt_alloc_<W>(SEED)` + `cqrt_ry_<W>_controlled(f, h, θ)` on the fresh rail, pinned live the same way; the seed may be a run-time value | same, state-prep kind |
| folded if/else **angle select** — Ry stem | by difference: unconditional `R(h, B)` plus one `cqrt_ry_<W>_controlled(f, h, A−B)`; **constant arms only** | `AngleSelectEmit` |
| folded if/else angle select — Rz stem | a kickback pair `cqrt_rz_i1(f, B)`, `cqrt_rz_i1(f, A)` — no subtraction, so run-time arms are admissible | `AngleSelectEmit` |
| a **pure classical call** in a tainted arm (`if (c) p += f(k)`) | the call runs classically, is hoisted into the predecessor, and its `i32` result is merged by the select-merge mechanics | `ClassicalCallArmEmit` |
| a **tainted-index store** under a tainted condition | the store is flattened into the predecessor and lowered as `cqrt_qram_store_<W>_controlled(flag, arr, idx, val)` with the flag left live so its `_unc` is gated by the same predicate | `GuardedStoreArmEmit` |
| a noreturn sink arm (`abort`, `exit`, `__assert_fail`, …) | **park**: `cqrt_cswap` the routed handle into a fresh graveyard rail under the flag, record the flag on the output tape, run the sibling uncontrolled; the graveyard rail and flag are kept, never freed | `AbortParkEmit` |
| a **classically bounded loop** whose body holds a tainted region | the loop CFG is kept and the region is lowered once inside it (**rolled**; IR size is independent of the trip count). A loop the rolled path does not claim, but whose trip count is a small proven constant, is unrolled instead | `LoopLowering.cpp`, `LoopUnrollPrepass.cpp` |
| **sequential** regions (`if (q) {…}; if (q') {…}`) | ordering, not a new lowering: a precedence graph is Kahn-sorted; an unresolvable alias or a cycle is not lowered | `lowerControlRegions` |

`RegionFlatten` erases the CFG diamond after emission. `cqrt_cswap` has **one**
minter in the whole pass, the abort park above.

Three conventions are load-bearing:

- **Nothing non-diagonal ever touches a user register under control.** A gate
  that must fire on `b == 0` is the diagonal `rz(h_b, −θ)`. A non-diagonal
  gate has no such escape, hence the additivity spelling above.
- **A rail root that needs a ¬-copy gets a CNOT copy, never a bracket:**
  `bf = cqrt_alloc_i1(0); cqrt_cnot(h_b, bf)`, the shipped stream on `bf`, then
  `cqrt_cnot(h_b, bf); cqrt_free(bf)`.
- **Left allocated on purpose:** a value arm's chain-final rail, a
  controlled-Ry arm's rotated register and its control register, and a
  kickback flag whose chain the spine refuses to close are not freed, because
  the rail is not provably `|0⟩` (§9, §11.2). A leaked qubit is accepted; a
  dirty free is a hidden measurement.

### 8.4 Why no source-level marker is needed

A source-level `cq_when` would only matter if the user wanted to
quantum-control on a condition the pass would not flag as tainted. But quantum
control on a classical condition has no physical content: a classical `1`
reduces to unconditional application, a classical `0` to no-op. There is no
superposition of "applied vs. not" without a tainted control wire. So
tainted-condition is **necessary and sufficient**, and source-level brackets
would be redundant ceremony. The user writes a plain C `if`.

### 8.5 What is not lowered yet

Everything not in §8.3 fails loudly with a source-located diagnostic and
lowers nothing. Under NORTHSTAR goal 1 these are gaps, not walls, unless they
fall on the closed physics list. The named fences a widening has to argue with:

- **`condition predates a non-diagonal gate`** — a compare's operand register
  is rotated by a non-diagonal gate between the compare's definition and the
  flag mint, so the flag would read a stale basis. This fence sits in front of
  most alternative readings of the state-prep shape.
- **Stale readers and stale rails in loops** — a `cq_theta` arg-0 or a
  `cq_measure` operand that reads a name the pass cannot prove executes before
  a non-diagonal gate on the same wire declines
  (`rotation/measure operand predates a non-diagonal gate`). A QRAM access reads
  its index register, and a store its value, where the access runs, so the same
  case for `tbl[q]` or `arr[i] = q` declines with the pure-op message
  (`operand predates a non-diagonal gate`; bd r2j3.2).
- **Loop scope** — the rolled loop lowering claims natural, single-latch loops
  whose exit test is classical. A loop whose exit depends on quantum data
  declines (`loop under quantum control`); NORTHSTAR goal 1 admits such a loop
  when a finite bound is supplied or derived, and no bound derivation exists in
  the pass today. Multi-latch and irreducible cycles are left unclaimed and
  decline downstream; the remaining loop shapes (nested tainted loops, in-loop
  value arms, and so on) are fenced one by one in `LoopLowering.cpp`, so read
  its `kMsg*` strings and header comments for the current set.
- **Break** — an early `break` on a tainted value is lowered only for the
  canonical rolled single-rail shape; multiple break sites, a break across
  nested loops, a break that does not reconverge and a phase-carrying break
  each decline with their own `cq loop lowering: …` message.
- **`switch` off-pattern matrix** — `SwitchClassify`'s G0–G11 ladder declines
  what is not one of the accepted homogeneous shapes: multi-φ merges, a
  non-empty default beside mixed arms, fp / vector / `i128` arms, nested
  switches, a clobber, a tainted angle, a jump-table fold.
- **A quantum-derived rotation angle anywhere.**
- **`bare i1 register condition`** for the consumers that have not been given a
  rail leaf: the unfolded value diamond, the classical-call arm and the
  Ry-stem angle select.

---

## 9. Uncomputation — whole-DAG LIFO reversal

`Uncomputation` (with `ChainWalk` / `DagTraversal` / `FreePoint`) runs **last**
in `CQLoweringPass::run`. It recovers the **whole forward DAG** of each dead,
source-derived tainted **data** handle and reverses it **once**: a single
reverse-program-order pass adjoints each gate exactly once (over the void
in-place `_unc` ABI, §10) and frees each rail right after its last
reverse-use. Fan-out and Q+Q reconvergence are handled by one deduplicated
pass rather than bailed on.

The reversal is sound only for a **closed, non-measured, non-escaped, acyclic**
DAG whose every gate **dominates** the single insertion point — acyclic and
dominating means each gate ran exactly once on every reaching path. Any shape
that cannot be *proven* to meet that bar either declines **loudly**
(`DiagnosticInfoUnsupported`, `opt` exits non-zero) or is left allocated as a
**safe leak** — never freed dirty (§9.3). Over-declining is safe; freeing an
entangled rail is a silent collapse.

Besides the dead-terminal reversal the spine also discharges **interior**
rails that die before the function's end (`planInteriorDischarges`), and a
rail minted outside a loop and read only inside it is discharged **once at the
loop exit** rather than per trip.

### 9.1 Terminal selection and DAG recovery

A **terminal** is a tainted **data producer** — a `cqrt_alloc_<W>` mint or an
**uncontrolled** `cq_template_*` result — *all* of whose users are benign: an
in-place rotation on the handle (`cqrt_ry/rz_<W>`, which mints no new value), a
`cqrt_measure_<W>` sink, or a non-call classical read
(`ChainWalk::isTerminalHandle`). Any *other* gate that takes the handle as an
operand consumes the register forward, so the handle is not the terminal.
Rails a control emitter owns are **subtracted up front**
(`TaintSet::ControlOwnedRails`; likewise `OutputRails` and `GraveyardRails`):
a flag, work or merge out-rail is never selected, so its reversal-or-leak stays
that emitter's responsibility.

`DagTraversal::recoverDataDag` walks **backward** from the Insert-classified
terminals through every **tainted operand** — a template-produced handle is
itself a gate and hops to *all* its tainted parents (Q+Q ⇒ two parents); an
alloc or non-call handle is a root — collecting in-place rotations and
reassigning template producers. A visited-set dedups a shared fan-out prefix so
it is recovered **once**. The recovered gates are sorted into program order
(same block ⇒ position, else dominance).

A **closure / measure / escape** analysis then runs over every **rail** (a root,
or a template producer's result — the values the DAG zeroes and frees;
rotations mint no rail): every forward consumer of a rail must itself be a
recovered DAG gate. A measure sink upstream sets `MeasuredUpstream`; a `ret` or
`cq_invert_*` consumer sets `Escaped`; a `ControlOwnedRails` member or any
out-of-DAG consumer (a controlled copy, a `cqrt_cswap`, an uncovered gate) sets
`NotClosed`.

### 9.2 Adjoint emission — the void in-place `_unc` ABI

At the single insertion point `Uncomputation::emitDagReversal` walks the
recovered gates in **reverse program order**, emitting each gate's adjoint
**exactly once** (a `Seen` set skips an already-adjointed shared-prefix gate).
For a `cq_template_*` data gate the adjoint is its **void in-place `_unc`**
form — `void cq_template_…_unc(out, src…)` — which **zeroes the rail in place
by recomputing `f` from the still-live sources** (Bennett uncompute), **not**
the fresh-minting inverse operation `_inv`. This is the load-bearing
correctness choice: threading `_inv` would free a **dirty / entangled** rail, a
hidden projective measurement that collapses the state. Rotations re-emit with
a **negated angle**; `cqrt_x` / `cqrt_cswap` / `cqrt_cnot` / `cqrt_toffoli` are
involutions and re-emit as-is (§10.1).

The **slot convention** pins the `_unc` argument order against the generated
stub: **`out` is arg 0** (the rail to zero — the forward call's own result
handle), followed by the **forward operands in their original order**. Forward
`cq_template_sub_i32_lh(i32 100, i32 %h) → %r` inverts to
`cq_template_sub_i32_lh_unc(i32 %r, i32 100, i32 %h)`, matching the generated
`void cq_template_sub_i32_lh_unc(out, a_classical, b_handle)`. Pinning the
slots is what guards the Q+Q operand-swap miscompile: a `mul_qq` whose two
handle operands are reversed in the `_unc` call links cleanly yet recomputes
the wrong rail.

Each freeable rail is freed (`cqrt_free`) right after the adjoint of its
**earliest** forward gate — which, by SSA dominance, is emitted **last** among
that rail's reverse-touches, so the free lands after every reverse-read of the
rail. A rail is freed at most once, and only when the reversal provably returns
it to |0⟩: reverse-play restores a rail's **birth** state, so a template rail (a
`cq_template_*` or `cqrt_qram_load_*` result) or a `cqrt_alloc_<W>` root with a
null-constant seed is freed, while a root born from a
runtime or nonzero seed is reverse-played back to |seed⟩ and left allocated
(`BirthFreeze`, bd 5c5b). Rails recorded into a kept carrier are likewise kept
(the record freezes). Every adjoint is emitted either way. The end-to-end goldens
(`tests/e2e/slice_uncompute_dead_dag.c`, `slice_uncompute_dead_shapes.c`) pin
the full reversed streams — the **only** layer that links and so the only
proof that every `_unc` symbol the emitter mints resolves and signature-matches
the generated runtime ABI.

### 9.3 Classification and loud declines

`FreePoint::computeFreePoint` classifies each terminal as **Insert**,
**Measured** or **Escaped**; only `Insert` terminals reach reversal:

| Shape | Outcome |
|---|---|
| Dead, closed, acyclic, all gates dominate the merge | **reverse**; free each rail born \|0⟩ (template and QRAM-load rails, null-seeded roots); keep the rest |
| `ret` / `main` / `cq_invert_*` escape | **skip** — no emit; the caller owns it |
| `Measured` terminal | **skip** — the measurement consumed it; no adjoint, no free |
| `NotClosed` / `Escaped` rail in the recovered DAG | **safe leak** — left allocated, never a dirty free |
| Gate applied to a handle **after** its measurement | **loud** — `gate applied to handle after measurement` |
| A non-terminal rail read by a measure sink | **loud** — `dead chain would free a measured register` |
| A recovered gate outside `isInverseEmittable` | **loud** — `dead chain contains an un-invertible primitive` |
| A mutating gate that does **not** dominate the merge (split across branch arms) | **loud** — `dead chain spans divergent control-flow arms` |
| Tainted live range crosses a loop backedge | **loud** — `tainted handle live range crosses a loop backedge` |
| Handle reaches an unrecognized user / non-reconverging CFG | **loud** — `tainted handle reaches an unrecognized user` |

`FreePoint` and the `Uncomputation` driver **own** these exact diagnostic
strings (each is prefixed `cq uncompute:` in the source — elided above for
width); the negative fixtures (`ir-pass/test/lowering_uncompute_*.ll`) mirror
each one character-for-character. The un-invertible pre-scan consults the
**same** `isInverseEmittable` predicate the emitter uses, *before* any
emission, so emit and decline can never disagree and no half-reversed chain or
dirty free of an un-adjointed rail is produced.

### 9.4 What this preserves and what it changes

SSA dominance makes reverse-program-order a valid reverse-**topological**
order, so fan-out and Q+Q reconvergence are handled by one `Seen`-deduplicated
pass, and the post-dominator machinery computes a **single** insertion point
for the whole DAG. The inverse is the void in-place `_unc`
(recompute-from-sources); the `_inv` symbols are still generated but the spine
never emits them (a half-minting `_inv` thread would free a dirty rail). No
`cqrt_cswap` is used for uncomputation: a superposed source that *would* need a
controlled swap to disentangle is exactly the `NotClosed` / entangled case that
safe-leaks instead.

Whole-call Bennett-style wrap-around is **not** used for uncomputation. It is
used only at one place: §7.2 clone synthesis, where the pass needs the
boundary-preserving forward + copy + reverse construction so the clone fits a
handle-ABI signature without leaking ancillas to the caller.

---

## 10. Per-op adjoints and manual inversion

For every forward template the inverse is derived mechanically; the runtime
ships forward gates and the generated `_inv` / `_unc` twins. Manual inversion
via `cq_invert_begin` / `cq_invert_end` is meant to reuse the same mechanism.

### 10.1 The `emit_inverse` rule

`isInverseEmittable` (`ir-pass/src/EmitInverse.cpp`) is the **single accept
gate** for what the inverter recognizes; `emitInverseCall` consults it first,
and anything outside it is loud-declined by the driver, never guessed. In
order:

| Forward gate | Inverse |
|---|---|
| a gate carrying `!cq.branchphase` (a kickback `cqrt_rz_i1`) | **refused** — adjointing it cancels the answer (§6.1a) |
| `cqrt_ry_<W>(h, θ)` / `cqrt_rz_<W>(h, θ)`, uncontrolled (the pass emits Rz at `i1` only) | the same symbol with `-θ` |
| `cqrt_ry_<W>_controlled(f, h, θ)` / `cqrt_rz_<W>_controlled(f, h, θ)` (nothing mints the `rz` stem) | the same symbol with `-θ`, the control threaded unchanged through arg 0 |
| `cqrt_x(q)`, `cqrt_cswap(f, a, b)` | as-is (self-adjoint) |
| `cqrt_cnot(c, t)`, `cqrt_toffoli(c1, c2, t)` (exact arity, void) | as-is (self-adjoint; re-emitted under the still-live controls) |
| `cqrt_copy_<W>_controlled(f, src, dst)` | as-is (a controlled XOR is an involution) |
| `cqrt_xorc_<W>(h, imm)` | as-is |
| `cqrt_addc_<W>(h, imm)` | the same symbol with `-imm` |
| uncontrolled data `cq_template_*` (including the compare grid) | its void `_unc` form (§9.2) |
| `cqrt_qram_load_<W>(arr, idx)` | `cqrt_qram_load_<W>_unc(out, arr, idx)` |
| `cqrt_qram_store_<W>(arr, idx, val)` | `cqrt_qram_store_<W>_unc(arr, idx, val)` — the same arguments, **not** out-first; it pops the backend's per-store tape, in strict LIFO order per array |
| a call to a specialization clone `@__cq_q_<callee>_<mask>` | its `@…_unc(out, args…)` twin |
| anything else (an `_inv` / `_unc` twin, the plain uncontrolled `cqrt_copy_<W>`, a `cq_template_*_controlled` form, an indirect call) | **un-invertible → loud decline** |

The exact-arity / VOID tests are load-bearing: a hand-written non-void or
off-arity same-named fake is a call the recipe cannot invert (it would mint a
rail the recipe never zeroes), and a bare prefix match would claim it.

For a `cq_template_<op>_<W>` **data** template the adjoint is **not** a
negated-angle re-emit but the void in-place `_unc`
`cq_template_<op>_<W>…_unc(out, src…)` — it zeroes the rail by recomputing the
forward function from the still-live sources, rather than minting a fresh
inverse result. The template library generates the **forward**, `_inv`
(fresh-minting adjoint) and `_unc` (void in-place adjoint) symbols for every
binary, unary, cast **and compare** op — `tools/opcode_table.yaml` gives the
compare rows `unc_qq` and `unc_hl` (no `_lh` on any axis) — plus `_controlled`
twins on the binary axis. The uncompute spine emits **only `_unc`** for data
templates; the `_inv` symbols are generated but the spine does not emit them.
The compare `_inv` strip is still emitted directly by `CompareLowering` for
control flags.

### 10.2 The derived-adjoint commitment

Adjoints are **derived by the IR pass**, never hand-authored: `emit_inverse`
produces the inverse of a visible gate sequence by reversing it and applying
the per-gate rule (negated angle / self-adjoint / void `_unc`). The
controlled-**adjoint** shape is never needed for data uncompute: a dead data
DAG is reversed by the **uncontrolled** void `_unc` spine (§9). No control
emitter reverse-plays a region stream — a phase arm's flag is stripped by its
compare `_unc`, and a value arm's hoisted chain is ordinary tainted arithmetic
in the predecessor that this very spine reverses. What remains the emitter's
responsibility is the division of labour: the flag and the merge out-rail are
`ControlOwnedRails`, and the chain-final rail is deliberately left allocated
(§8.3).

### 10.3 Manual inversion via `cq_invert_begin` / `cq_invert_end`

**Not lowered yet.** The user surface exists (`include/CQ.h`,
[`frontend.md`](./frontend.md) §3.5): `cq_invert_begin(); f(q); g(q);
cq_invert_end();` compiles to `@__cq_invert_begin` / `@__cq_invert_end` marker
calls pinned by asm memory barriers, and `tests/frontend/
cq_invert_markers_survive.c` checks that they survive at `-O0` through `-O3`.
The pass does not consume them: no stage collects the bracketed gate sequence,
applies the adjoint, or erases the markers (the XFAIL fixture below says so in
its own header). The only place the pass names the markers is `ArmClassify`'s
classical-cone fence, which refuses to hoist a marker call out of a value arm.
The taint-escape guard and `FreePoint` do treat a callee whose name starts with
`cq_invert_` as a recognized handle escape (the hand-off the manual-inversion
design was built around), but the emitted markers are spelled `__cq_invert_*`
and take no operands, so they never reach that path.

The intended lowering, pinned by the XFAIL fixture
`ir-pass/test/lowering_invert_add_i32.ll`, is:

1. identify the bracketed region from the marker calls;
2. collect the gate sequence between the markers (every `cqrt_*` or
   `cq_template_*` call; how a bracket that sits inside a tainted-branch region
   composes with the control emitters is not decided);
3. apply `emit_inverse` (§10.1) to the collected sequence;
4. replace the forward calls with the adjoint sequence and erase the markers.

The fixture expects the bracketed `add` to lower to
`cq_template_add_i32_hl_inv`. This is distinct from auto-uncomputation (§9),
which runs without user intervention on dead handles; manual inversion
applies the adjoint of an explicitly bracketed operation the user wants to
undo (de-preparing a state after a measurement, undoing oracle preparation in
phase estimation). Until it lands the `cq_invert_*` surface is a compiler gap
under NORTHSTAR goals 1 and 3 (oracle construction with uncompute is on the
acceptance corpus), and its intended semantics — including how the
`_inv` versus `_unc` choice interacts with the "free only a provable `|0⟩`
rail" discipline — need a decision before it is built. `EmitInverse` is
deliberately decoupled from selection and placement (`emitInverseCall` takes a
`CurHandle` a bracket caller can thread a relabelled register through), so the
spine is ready to be reused.

---

## 11. Runtime ABI

The contract between IR-emitted code and the runtime. The handle pattern is the
load-bearing element; everything else is supporting detail. The declarations
are in [`runtime/cq_runtime.h`](../runtime/cq_runtime.h); the shipped bodies
are in `runtime/cq_runtime.c`.

### 11.1 The handle abstraction

IR-emitted code references qubit registers via opaque `i32` handles. The ABI
places no structure on a handle: whatever state a backend keeps for it (qubit
indices, register width, allocation tracking) lives entirely behind the
boundary. The trace runtime just numbers them from a process-global monotonic
counter (`cqrt_alloc_handle()`), which the template stubs share so numbering
stays monotonic across both archives. Two calls referencing handle `7` refer to
the same register.

Why a handle and not a struct-by-value or a pointer to a runtime struct:

- ABI stability under runtime evolution: a runtime can add fields to its
  internal state without recompiling IR-emitted code.
- Platform calling-convention quirks disappear: no struct-by-value lowering
  surprises.
- Every backend shares one IR and one template library.
- Reference identity is automatic.

Three kinds of handle exist and are distinguished only in the trace: a
register or flag rail prints as `h<N>`, an output tape as `t<N>`, a QRAM array
as `a<N>`. Tape and array handles are classical resource tokens, not qubits,
and the uncompute spine ignores them.

### 11.2 Allocation, measurement, free

```c
/* Allocation — width-only ABI. Takes an initial classical value; returns a
   fresh handle. W ∈ { i1, i8, i16, i32, i64, f16, f32, f64, f80 }. */
int32_t cqrt_alloc_i1 (bool    value);   int32_t cqrt_alloc_i8 (int8_t  value);
int32_t cqrt_alloc_i16(int16_t value);   int32_t cqrt_alloc_i32(int32_t value);
int32_t cqrt_alloc_i64(int64_t value);   int32_t cqrt_alloc_f16(_Float16 value);
int32_t cqrt_alloc_f32(float   value);   int32_t cqrt_alloc_f64(double  value);
int32_t cqrt_alloc_f80(long double value);

/* Measurement — width-only ABI, same nine widths. Takes a handle; returns the
   classical value of the matching width. The trace runtime returns 0. */
bool    cqrt_measure_i1 (int32_t handle);   /* … cqrt_measure_<W> … */

/* Free — width-irrelevant. */
void cqrt_free(int32_t handle);
```

Width-only at the runtime layer is intentional: signedness does not change the
qubit count or the gate set, and the pass disambiguates signed from unsigned at
the LLVM-opcode layer (§6.4).

`cqrt_free` is **compiler-emitted only**, and only where the rail is provably
`|0⟩`: it is a hardware reset, which is a projective measurement, so freeing a
dirty or entangled rail collapses the state. A rail that is not provably `|0⟩`
is **left allocated**, never freed dirty. A handle that escaped (`ret`,
`cq_invert_*`) or was measured is never freed by the pass either — the caller
or the measurement owns it.

`cqrt_measure_<W>` in the trace runtime does not reclaim the handle. The
**compiler** treats measurement as terminal for the uncompute spine: a measured
terminal gets no adjoint and no `cqrt_free` (`FreePoint` classifies it
`Measured`, §9.3), a gate applied to a handle after its measurement on a chain
the spine would reverse is a loud decline
(`cq uncompute: gate applied to handle after measurement`), and a dead chain
that would free a register read by a measurement declines loudly
(`cq uncompute: dead chain would free a measured register`) — freeing a
measured register is a hidden projective collapse. The only path to a
measurement is an explicit `cq_measure(...)`; casts are representation
changes, never measurements.

### 11.3 Rotation primitives

```c
void cqrt_ry_<W>(int32_t handle, double angle);   // Ry on each qubit of the register
void cqrt_rz_<W>(int32_t handle, double angle);   // Rz on each qubit of the register
void cqrt_ry_<W>_controlled(int32_t ctrl, int32_t handle, double angle);
```

`W` ranges over the nine widths above. Multi-bit registers are **tensored**:
`cqrt_ry_i32(h, θ)` applies `Ry(θ)` to each of the 32 qubits, matching the
frontend's per-bit rotation semantics
([`frontend.md`](./frontend.md) §3.2). The angle is always classical.
`cqrt_ry_<W>_controlled` is the controlled twin with the control flag
**prepended** as argument 0; the pass mints it only for the in-place rotation
arm, controlled state prep and the Ry-stem angle select (§8.3).

> **Rz is emitted at `i1` only.** The tensored reading is the whole
> `cqrt_rz_<W>` semantics, and it is exactly what makes a routed or controlled
> Rz useless as an oracle: the marked phase is `(−1)^popcount(target)`, and a
> per-qubit diagonal gate fixes `|0…0⟩`, so it can never mark it. `cq_phi` is
> therefore register-free, and the **only** Rz the pass emits is the kickback
> gate `cqrt_rz_i1(flag, θ)` on a flag ancilla (§6.1a): every `rzRtFn` call
> site in `ir-pass/src` requests `"i1"`. The `W > 1` widths and the whole
> `cqrt_rz_<W>_controlled[_inv]` family, and `cqrt_ry_<W>_controlled_inv`, stay
> **declared but unemitted**; re-enabling a controlled Rz for a phase arm would
> restore the tensored gate. "Unemitted" here means no emitter mints the symbol
> today; a backend must still define it, because only `cqrt_h` and
> `cqrt_h_controlled` are exempted from the required surface
> ([`backend-provider.md`](./backend-provider.md)). Verify rather than assume
> when you quote this: grep the pass output and the committed goldens for a
> `cqrt_rz` that is not `cqrt_rz_i1`, because a new emitter is all it takes to
> change it.

### 11.4 Gate primitives and copies

```c
void cqrt_x       (int32_t q);
void cqrt_h       (int32_t q);
void cqrt_cnot    (int32_t ctrl, int32_t tgt);
void cqrt_toffoli (int32_t c1, int32_t c2, int32_t tgt);
void cqrt_cswap   (int32_t ctrl, int32_t a, int32_t b);
```

The pass emits a stock opcode as a `cq_template_<op>_<W>` call, not as a
sequence of these primitives; the template bodies (or a backend) decompose into
them. The pass does emit these directly:

- `cqrt_x` — the `¬flag` bracket of a kickback or copy merge, on an ancilla flag.
- `cqrt_cnot` / `cqrt_toffoli` — the condition-tree flag network
  (`CondTreeEmit.cpp`, `SelectMergeEmit.cpp`), `Specialization.cpp`'s
  controlled-return mux, and the break reverse-play (`BreakReversePlay.cpp`).
- `cqrt_cswap` — **one** minter, the abort park (`AbortParkEmit.cpp`, via
  `emitRoute`'s single call site).
- `cqrt_h` and `cqrt_h_controlled` are declared and defined but **never
  emitted** (`tools/backend_contract.py`, `UNEMITTED_CORE`), and a backend need
  not define them. `cqrt_x_controlled` and `cqrt_cnot_controlled` are declared
  as well and no emitter mints them either, but they are not exempted, so a
  backend must still define them.

**Reversible basis copy.** `cqrt_copy_<W>(src, dst)` is the keep-sources-live
transversal-CNOT copy `|x⟩_src |0⟩_dst → |x⟩_src |x⟩_dst` (`dst` must be a
fresh `|0⟩` register, allocated immediately before the copy). It copies a
computational-basis *label*, not a state, so it is wrong for any
phase/superposition carrier (a CNOT copy of an Rz/Ry answer dephases it); it
never frees or consumes its source; and it is an involution, so there is no
`cqrt_copy_<W>_inv` twin.
`cqrt_copy_<W>_controlled(ctrl, src, dst)` performs the copy iff the control
flag is set, with the flag **prepended** as argument 0 — this is the value
merge's primitive (§8.3), where the controlled twins do the work; the
uncontrolled copy appears in the value-`switch` preload, the break
reverse-play's copy-out, the QRAM cell copy-out and the Bennett wrap's
copy-out. Both are declared at the five integer widths plus
`f16`/`f32`/`f64`/`f80`.

**In-place classical-immediate arithmetic.** `cqrt_addc_<W>(h, imm)` and
`cqrt_xorc_<W>(h, imm)` (integer widths only) mutate the register `h` in place
by a classical immediate: `h := (h + imm) mod 2^W` and `h := h ^ imm`. They
are void, take no `out`, and have no `_inv` / `_unc` twin — the adjoint
re-emits `xorc` as-is and `addc` with the negated immediate. They exist
because the out-of-place `cq_template_<op>_<W>_hl` mints a fresh rail per call
and leaves the parent standing as a live basis record of the wire, which
dephases a later non-diagonal gate.

**Output tape.** `cqrt_tape_alloc() → tape` registers a tape (a classical
resource token) and `cqrt_tape_write_<W>(tape, src) → out` appends `src` to it
as a fresh, **kept** `|0⟩` output rail (a basis copy that preserves `src`).
`cqrt_tape_write_<W>_controlled(ctrl, tape, src) → out` commits the content
under a control flag while always appending, so the tape length stays
deterministic. `W` is one of the five integer widths. The kept rail is never
freed or uncomputed. See `IOSinkLowering.h`.

**QRAM.** `cqrt_qram_alloc_<W>(count) → arr` registers a known-shape array;
`cqrt_qram_load_<W>(arr, idx) → out` reads the cell at a quantum index into a
fresh handle (the cell is preserved), with `cqrt_qram_load_<W>_unc(out, arr,
idx)`; `cqrt_qram_store_<W>(arr, idx, val)` is a void in-place mutation on the
array handle with `_unc`, `_controlled` and `_controlled_unc` variants. The
array's contents are classical metadata replayed at inspection; the strategy
(shadow, mux, QROM) is a backend detail that never appears in a signature.
`<W>` names the cell width only; the index `idx` is always a rail of logical
width 32. For any other index width the pass wraps each QRAM call, forward and
`_unc`, in its own `cq_template_<trunc|sext|zext>_<W>_to_i32` cast, the cast's
`_unc` and a `cqrt_free` (`bracketQramIndexCasts`, after `uncompute`), so the
cast rail never outlives its call. The trunc is exact because `count` is an
`int32_t`.

### 11.5 One IR, any backend

The handle ABI is the abstraction boundary; whatever a backend does behind it
is its concern. The same lowered IR links against any static backend that
defines the declared symbols, so the choice is made at link time. **One
implementation ships in this repository: the trace runtime.** There is no
counting variant, no statevector simulator and no classical-shadow
short-circuit here; those would be backend features. The trace format is the
golden contract:

```
<symbol>(<arg>[, <arg>…]) -> <return>     ; value-returning ops
<symbol>(<arg>[, <arg>…])                 ; void ops (no arrow)
```

Handles print as `h<N>` from 0, angles as `%a` hex floats (round-trip exact),
`cqrt_measure_<W>` prints `-> 0`. Exactly one implementation may be on an
application link line: linking a production backend together with
`libcq_templates.a` or `libcq_runtime.a` lets archive order silently pick the
trace body ([`backend-provider.md`](./backend-provider.md)).

### 11.6 ABI identity and versioning

The ABI is the four headers `cq_runtime.h`, `cq_templates.h`,
`cq_intrinsic_templates.h` and `cq_libm_templates.h`, the last three
generated from `tools/opcode_table.yaml`, `tools/intrinsic_table.yaml` and
`tools/libm_table.yaml`. `tools/backend_contract.py provider-manifest` records
that ABI identity from a CQ revision, and `backend_contract.py check` validates
a backend archive against the manifest with `nm`. There is no `cqrt_init` /
`cqrt_finalize` lifecycle hook, no `cqrt_abi_version()` query and no
symbol-versioning script in the tree; the pass emits none of them.

---

## 12. Template library

The reversible-circuit primitives the IR pass substitutes for tainted stock
LLVM opcodes.

### 12.1 The generated declaration set

The template surface is parametric in (opcode × width × operand shape ×
forward / inverse / uncompute / controlled). The project's generator
`tools/gen_templates.py`, reading `tools/opcode_table.yaml` (plus
`intrinsic_table.yaml` and `libm_table.yaml`), emits `runtime/cq_templates.h`
and `runtime/cq_templates.c` mechanically, together with the intrinsic and libm
siblings and the link-smoke table `runtime/cq_link_smoke.c`. **Edit the YAML
and regenerate; never edit the generated files.** Each generated file embeds
the YAML's SHA-256 in its banner, and `gen_templates.py --check` regenerates
into a temporary directory and diffs byte-for-byte; it runs as a ctest entry
(`runtime/CMakeLists.txt`). There is no CI service — all quality gates run
locally through `ctest`.

`runtime/cq_templates.h` carries 2,479 declarations at this revision; with the
intrinsic and libm surfaces the link-smoke gate (`runtime_link_smoke`) checks
2,880 generated `cq_template_*` symbols against `libcq_templates.a` (a link
regression gate, not a coverage number). Re-count rather than quote these:
they move with the YAML.

### 12.2 Operand-shape dispatch (`_hl`, `_lh`) and axes

Each template family carries a base symbol for the all-handle case plus
suffixed variants for mixed handle / classical-literal cases, and a
modifier-then-direction suffix order:

```
cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>][_hl|_lh][_controlled][_inv|_unc]
```

```c
int32_t cq_template_add_i32          (int32_t a_handle, int32_t b_handle);
int32_t cq_template_add_i32_hl       (int32_t a_handle, int32_t b_classical);
int32_t cq_template_add_i32_inv      (int32_t a_handle, int32_t b_handle);
void    cq_template_add_i32_unc      (int32_t out_handle, int32_t a_handle, int32_t b_handle);
void    cq_template_add_i32_hl_unc   (int32_t out_handle, int32_t a_handle, int32_t b_classical);
int32_t cq_template_add_i32_controlled(int32_t ctrl_flag, int32_t a_handle, int32_t b_handle);
```

The IR pass picks the symbol from the operand's **taint membership**, not from
its LLVM kind (§6.2): QQ takes the bare base symbol, `_hl` a classical right
operand, `_lh` a classical left operand of a non-commutative opcode; compares
and the commutative ops have no `_lh`. The direction axes are: forward
(returns a fresh handle), `_inv` (fresh-minting adjoint), `_unc` (**void**,
in-place, `out` is argument 0 — the uncompute spine's only data adjoint) and
`_controlled` (binary axis only; compares have no controlled grid, nesting
combines flags through `cqrt_toffoli`).

### 12.3 Template bodies today

Every body in `runtime/cq_templates.c`, `cq_intrinsic_templates.c` and
`cq_libm_templates.c` is a **trace stub**: it allocates the result handle where
the symbol returns one, prints `cq_template_…(args) -> h<N>` and returns. No
template body contains a gate sequence. `tools/opcode_table.yaml` states the
policy in its header — declare symbols and dispatch metadata, never circuit
bodies — and the choice of circuit family for each opcode (ripple-carry,
Cuccaro or Draper adders; schoolbook or Karatsuba multipliers; and so on) is
left to a backend, since the ABI fixes only the symbol and its argument shape.
Any statement about circuit depth or ancilla count therefore belongs to a
backend, not to this repository's runtime. NORTHSTAR is silent on whether a
reference gate-level implementation should ship here.

### 12.4 Distribution

The build produces two static archives, `libcq_runtime.a` and
`libcq_templates.a` (`runtime/CMakeLists.txt`); `cq_templates` links
`cq_runtime`. Link order is load-bearing: `libcq_templates.a` **before**
`libcq_runtime.a`, because the templates call `cqrt_*` and single-pass `ld`
needs the caller first. `tools/install_cq.py` builds and installs CQ with
exactly one explicitly selected static backend, and `tools/cqc` reads that
selection (falling back to the two trace archives in a source tree). A
production backend replaces the pair wholesale rather than being linked
beside it ([`backend-provider.md`](./backend-provider.md)). No `.bc` / LTO
distribution shape and no pass-internal IRBuilder template path exist.

---

## 13. Compilation flow

The backend's responsibility spans stages 2 and 3 of the flow the frontend
documents ([`frontend.md`](./frontend.md) §8).

### 13.1 Single-file program

```bash
clang -O1 -emit-llvm -c -I<prefix>/include -include CQ.h example.c -o example.bc   # 1: frontend
opt -load-pass-plugin libCQPass.so -passes=cq-lowering \
    example.bc -o example.lowered.bc                                                # 2: cq-lowering
clang example.lowered.bc libcq_templates.a libcq_runtime.a -o example               # 3: link
./example                                                                            # emits the trace
```

Stage 2's input is per §3; its output contains no `@cq_*` intrinsic call and no
tainted stock opcode — only `cqrt_*` runtime calls, `cq_template_*` template
calls, and stock LLVM classical IR threading them. Stage 3 is plain Clang
codegen and link against the templates archive then the runtime archive. Every
end-to-end test runs this pipeline (`tests/e2e/run_slice.sh`) and additionally
runs a free-pairing check on the lowered IR (`tools/free_pairing_check.py`),
because the golden trace cannot say whether a rail was `|0⟩` when it was freed.

### 13.2 Multi-file program (function lifting across translation units)

The clone-on-taint path (§7.2) needs callee bodies in the same bitcode module
the pass sees, so the per-TU IR is `llvm-link`ed **before** `opt`, with no
inliner in between:

```bash
clang -O1 -emit-llvm -c -I<prefix>/include -include CQ.h main.c -o main.bc
clang -O1 -emit-llvm -c util.c -o util.bc                         # no CQ.h needed
llvm-link main.bc util.bc -o combined.bc
opt -load-pass-plugin libCQPass.so -passes=cq-lowering \
    combined.bc -o combined.lowered.bc
clang combined.lowered.bc libcq_templates.a libcq_runtime.a -o program
```

`tools/cqc <cq_input.c> [lib.c …] -o <output>` runs exactly these four stages
(per-TU `clang -O1`, with `CQ.h` included only for the first source;
`llvm-link`; `opt -passes=cq-lowering`; link the selected backend). A callee
with no visible body cannot be lifted: a tainted call to it declines as
`tainted value consumed by an unknown callee` unless it is a curated intrinsic
(§7.1) or its source was injected.

### 13.3 Other source languages

The pass consumes LLVM IR, not C. A module that reaches it carrying the `cq_*`
external declarations and visible callee bodies is treated the same way
regardless of the source language. The test suite exercises C only; other
front ends are unexercised.

---

## 14. Cross-references

| Concern | Where it is documented |
|---|---|
| The plan of record: goals, what may decline, design principles | [`../NORTHSTAR.md`](../NORTHSTAR.md) |
| User-facing intrinsic surface (`cq_theta` / `cq_phi` / `cq_measure` / `cq_invert_*`) | [`frontend.md`](./frontend.md) §3 |
| Taint as Q/C boundary; mixed-operand semantics; conversion semantics | [`quantum-classical-handling.md`](./quantum-classical-handling.md) |
| Stock LLVM C++ APIs each mechanism uses | [`llvm-implementation.md`](./llvm-implementation.md) |
| Production pass-plugin sources | [`../ir-pass/`](../ir-pass/) |
| Runtime ABI header (hand-maintained `cqrt_*` core) | [`../runtime/cq_runtime.h`](../runtime/cq_runtime.h) |
| Template declarations (autogenerated) | [`../runtime/cq_templates.h`](../runtime/cq_templates.h), [`../runtime/cq_intrinsic_templates.h`](../runtime/cq_intrinsic_templates.h), [`../runtime/cq_libm_templates.h`](../runtime/cq_libm_templates.h) |
| Template generator source of truth | [`../tools/opcode_table.yaml`](../tools/opcode_table.yaml), [`../tools/intrinsic_table.yaml`](../tools/intrinsic_table.yaml), [`../tools/libm_table.yaml`](../tools/libm_table.yaml), [`../tools/gen_templates.py`](../tools/gen_templates.py) |
| What a production backend must implement | [`backend-provider.md`](./backend-provider.md) |
| QRAM local-array escape and uncompute (design note) | [`design/qram-local-array-uncompute.md`](./design/qram-local-array-uncompute.md) |
| End-to-end worked example, source → lowered IR | [`example.md`](./example.md) |
