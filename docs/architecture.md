# CQ_lang Architecture

The compilation architecture that fell out of the design discussions on
2026-05-21. Intended to be folded into [`ROADMAP.md`](../ROADMAP.md) in a
subsequent session; for now it is the reference for what each component
does and where each concern lives.

Companion documents:
- [`pipeline-sketch.md`](./pipeline-sketch.md) — whiteboard transcription
  that motivated the layered design
- [`bennett-jl-comparison.md`](./bennett-jl-comparison.md) — comparison
  with Sturm.jl / Bennett.jl / Orkan and the design convergences
- [`example.md`](./example.md) — worked end-to-end example from CQ
  source through LLVM IR

---

## 1. Scope

This document defines:

- The end-to-end CQ compilation pipeline (source → executable that emits
  a circuit)
- The split of responsibilities between AST front-end and LLVM IR back-end
- The mid-level type model (frontend / backend `qint_t`)
- The minimal intrinsic surface bridging the two layers
- The forward taint-propagation mechanism that identifies quantum
  operations in the IR
- The mechanisms for specialization, lowering, uncomputation, and manual
  inversion
- How each ROADMAP phase maps onto this architecture
- A note on MLIR as a longer-term consideration

It does **not** define:

- The opcode-template library (which reversible-circuit family implements
  each LLVM opcode) — deferred to backend-design time
- Specific simulator / hardware integration details
- Concrete syntax for any feature whose surface is still TBD in the
  ROADMAP

---

## 2. Architectural principles

The following principles supersede the v1-era assumption that CQ_lang is
a source-to-source rewriter. They were settled by the 2026-05-21
discussion.

### P1. AST front-end + LLVM IR back-end

CQ is a **two-stage compiler**: a Clang/libtooling front-end that
recognizes quantum-touching constructs in the AST, and an LLVM IR
back-end pass that does the bulk of the lowering work.

The front-end's output is not the final artifact. Its job is to inject
typed markers (a thin mid-level type and a tiny set of intrinsic function
calls) into otherwise stock C, so that after Clang's normal codegen the
resulting LLVM IR carries the signal the back-end needs.

The v1-era "rewritten C source" output remains a useful by-product —
demoable, gdb-friendly, drop-in compilable — but is no longer the
load-bearing artifact.

### P2. No `reversible` attribute on functions

Reversibilizability is not a user-declared property. The IR pass
discovers it by:

1. Identifying quantum SSA values (those produced, directly or
   transitively, by `@cq_init` / `@cq_alloc` calls or coming in as
   `qint_mid_t`-typed function parameters)
2. Forward call-graph closure: any function called with a `qint_mid_t`
   argument is a quantum-specialization candidate
3. Per-function classification (reversibilizable / not) by inspecting
   each candidate's IR against a known exclusion list

The user writes plain C. The compiler discovers which functions need
quantum specializations and which IR instructions are quantum operations.
(Trade: requires LLVM IR availability for all reachable callables — see §10.)

### P3. No custom IR opcodes; no LLVM fork

CQ extends the IR surface via **a tiny set of intrinsic function
declarations** only. We declare ~7 `@cq_*` functions with specific type
signatures; the IR pass treats calls to them specially. We do **not**
patch LLVM, define new IR instruction kinds, or build an MLIR dialect.

The same mechanism is used by Enzyme (autodiff at LLVM level),
AddressSanitizer, OpenMP runtime lowering, and Polly. It is the
lightest-weight LLVM extension that admits useful semantics.

MLIR with a custom quantum dialect is a longer-term possibility — see
§11. For the foreseeable phases (1–9) it is overkill; this lightweight
intrinsic surface is sufficient.

### P4. Arithmetic is stock LLVM, identified by taint propagation

Crucially, quantum arithmetic does **not** go through dedicated
intrinsics. The rewriter emits ordinary C arithmetic on the `.val` field
of `qint_mid_t`; Clang lowers it to stock LLVM opcodes (`add`, `sub`,
`mul`, `icmp`, …, the 38 primitives Bennett's mapper handles). The IR
pass identifies which instructions are quantum by **forward taint
propagation** from `@cq_init` / `@cq_alloc` results (see §7.1).

This is the major correction over an earlier draft of this document
that enumerated `cq_add_qq`, `cq_mul_qq`, etc., as separate intrinsics.
There are none. Arithmetic intrinsics would have:

- Hidden the 38 LLVM primitives from the IR
- Multiplied the intrinsic surface (50+ entries for all C operators × QQ/QC variants)
- Failed to unify with auto-specialization of classical functions (which uses stock LLVM opcodes natively)

Under taint propagation, the IR pass sees the same `%c = add i32 %a, %b`
regardless of whether `%a` and `%b` came from explicit `quantum int`
declarations or from a classical function being auto-specialized for
quantum arguments. One mapper, one path.

### P5. Per-op compile-time adjoints (ROADMAP §2 preserved)

Uncomputation is per-op, emitted at compile time, derived from per-value
provenance — *not* whole-call Bennett wrapping. The original ROADMAP §2
principle is preserved; only its implementation moves from AST-level
use-def tracking to IR-level SSA-based live-range analysis.

Whole-call Bennett construction is used **only** internally when
synthesizing the body of a quantum specialization of an external
function (§7.2).

### P6. Inverses derived mechanically from forwards

For every primitive opcode template, the inverse is generated by walking
the forward gate sequence in reverse and adjointing each gate. NOT, CNOT,
Toffoli are self-adjoint; rotations negate their angle.

Consequence: the back-end ships **forward + controlled** templates per
primitive. **Adjoint + controlled-adjoint** are derived. This halves
ROADMAP Phase 3's per-op deliverable surface from four to two.

### P7. Three-level `qint_t`

See §3.

### P8. Runtime emission via gate-API calls

The compiled binary, when executed, constructs the circuit by making
calls into a small runtime library (`libcq_runtime`). The runtime can
emit OpenQASM, build an in-memory circuit object, stream gates to a
simulator, or transport to hardware — the choice is made by which
runtime the binary links against, not by the compiler.

### P9. Cross-language input is structurally feasible

Any function whose LLVM IR is reachable can participate in
quantum-specialization. This includes `clang -emit-llvm`'d C,
`rustc --emit=llvm-ir`'d Rust, Fortran, etc. The IR pass operates on
stock LLVM IR + our intrinsics + taint propagation; the language of
origin is invisible at that layer.

---

## 3. The three-level `qint_t` model

| Layer | Representation | Where it lives | Created by | Purpose |
|---|---|---|---|---|
| **Source `qint_t`** | `quantum int` keyword (and `quantum char`, `quantum long`, etc.) | User's CQ source | User | Surface syntax — declares intent to use quantum data |
| **Mid `qint_mid_t`** | `struct { int val; }` (or analogous for other widths) | Rewritten C / LLVM IR | Rewriter | Type signal that survives at function-signature boundaries; flattened by mem2reg/sroa inside bodies; taint propagation tracks quantum-ness post-flattening |
| **Backend `qint_t`** | Actual qubit register (allocation in the gate-emission runtime / simulator) | Runtime | Runtime, when an IR-pass-emitted allocation call fires | The "real" qint — qubits, gates, simulator state |

Distinctions worth being explicit about:

- **Source vs Mid.** The rewriter is the bridge. It recognizes
  `quantum int x` and emits `qint_mid_t x` plus an `@cq_init` call.
  Operations on `x` are emitted as plain C arithmetic on `x.val`.

- **Mid vs Backend.** The IR pass is the bridge. It walks intrinsic
  calls and the tainted SSA closure of arithmetic ops, and emits calls
  to runtime allocation / gate-emission functions. From the compiler's
  perspective, the backend qint_t is opaque — handles, not semantics.

- **At function boundaries**, `qint_mid_t` is the canonical type.
  Function signatures `qint_mid_t my_func(qint_mid_t, qint_mid_t)`
  carry quantum-ness through linkage and through opt passes — `mem2reg`
  cannot flatten across a call boundary. Inside bodies the struct can
  flatten freely; taint propagation re-establishes the signal.

---

## 4. Pipeline

```
.c source
   │
   ▼
Clang frontend (parsing, sema, macros, _Generic, type promotion, …)
   │
   ▼
Clang AST
   │
   ▼
┌────────────────────────────────────────────────────────────────┐
│ libtooling rewriter                                            │
│   • quantum-typed decl   → qint_mid_t + @cq_init call          │
│   • quantum arithmetic   → .val-field arithmetic               │
│                            (stock C, no intrinsic)             │
│   • measurement-as-cast  → @cq_measure                          │
│   • rotation surface     → @cq_theta / @cq_phi                  │
│   • if (q_cond)          → @cq_when_begin / @cq_when_end        │
│   • invert(...)          → @cq_invert_begin / @cq_invert_end    │
│                            OR call to mangled __cq_invert_<f>   │
│   • quantum call site    → call to mangled specialization       │
└────────────────────────────────────────────────────────────────┘
   │
   ▼
Rewritten .c  (still valid C; links against CQ.h declarations of
                the mid-level qint_mid_t struct and ~7 intrinsics)
   │
   ▼
clang -emit-llvm  (with normal mem2reg/sroa cleanup)
   │
   ▼
LLVM IR
   • stock opcodes for both classical and quantum arithmetic
   • @cq_init / @cq_alloc as taint sources
   • @cq_measure as taint sink
   • @cq_theta / @cq_phi for rotations
   • @cq_when_* / @cq_invert_* region brackets
   • mangled specialization call sites for quantum cross-fn calls
   • qint_mid_t struct type at function signatures
   │
   ▼
┌────────────────────────────────────────────────────────────────┐
│ CQ IR pass                                                     │
│   1. Forward taint propagation from @cq_init / @cq_alloc       │
│      results and qint_mid_t-typed parameters                   │
│   2. Call-graph forward closure: any function called with      │
│      qint_mid_t arg → quantum-specialization candidate         │
│   3. Per-candidate classify reversibilizable / not             │
│   4. Synthesize quantum specialization for each reversibili-   │
│      zable candidate (opcode-template substitution on tainted  │
│      instructions; intrinsic-specific templates for @cq_*)     │
│   5. Lower tainted stock opcodes + @cq_* intrinsics to gate-   │
│      runtime calls                                             │
│   6. Emit per-op uncomputation at last-use / lifetime-end of   │
│      tainted SSA values (excluding main; excluding returned-   │
│      by-value qints)                                           │
│   7. Generate inverse of any forward template via reverse +    │
│      per-gate adjoint                                          │
│   8. Resolve @cq_invert_* markers via the same mechanism       │
└────────────────────────────────────────────────────────────────┘
   │
   ▼
LLVM IR with calls into libcq_runtime
   │
   ▼
clang compile + link with libcq_runtime
   │
   ▼
Compiled binary
   │
   ▼ (executes)
Runtime calls into libcq_runtime, building the circuit
   │
   ▼
Circuit  (OpenQASM file / in-memory object / streamed to simulator /
           transport to hardware — runtime-determined)
```

---

## 5. AST rewriter (front-end) responsibilities

The rewriter is the libtooling-based component already prototyped in v1.
Its responsibility set in the new architecture is **smaller** than the
v1-era plan, because most of the work moves down to the IR pass.

### 5.1 Recognize and translate quantum-touching AST patterns

Only a small set of patterns get rewritten. Everything else passes through
unchanged.

| AST pattern | Emit |
|---|---|
| `VarDecl` carrying `AnnotateAttr("quantum")`, uninitialized | `qint_mid_t x = cq_init(0, W);` |
| `VarDecl` `quantum int x = E;` where E is classical | `qint_mid_t x = cq_init(E, W);` |
| `BinaryOperator` / `UnaryOperator` / `CompoundAssignOperator` whose result type is quantum | **Stock C arithmetic on the `.val` field of operands.** Example: `c.val = a.val + b.val;` |
| `CStyleCastExpr` from quantum to classical | `cq_measure(q)` |
| `IfStmt` with a quantum-typed condition | `cq_when_begin(_cond); …body…; cq_when_end();` (`_cond` is a fresh `qint_mid_t` holding the condition's `.val`) |
| `CallExpr` with at least one `qint_mid_t` argument to a non-CQ function | Replace with call to the mangled quantum-specialization name `__cq_q_<funcname>_<argmask>(...)` (decl-only; IR pass binds the body) |
| `theta(q, angle)` / `phi(q, angle)` markers (Phase 2) | `cq_theta(&q, angle); / cq_phi(&q, angle);` |
| `invert(F)(args)` surface (Phase 2/7) | Either `__cq_invert_<F>(args)` mangled call, or bracketed `cq_invert_begin(); F(args); cq_invert_end();` |

### 5.2 No operator-form dispatch (QQ vs QC)

Under taint propagation, the rewriter does **not** need separate code
paths for "both operands quantum" vs "one quantum, one classical." A
mixed expression like `quantum int c = a + 5;` becomes `c.val = a.val + 5;`
— the IR has `%c = add i32 %a, 5`, where `%a` is tainted and `5` is a
constant. Taint propagates to `%c`; the reversibilization template
handles the classical constant as an initial-state preparation register.

This is a significant simplification of v1's per-pattern rewriter logic
(formerly: pattern 3 = QQ, pattern 4 = QC, etc.).

### 5.3 No inverse emission

The rewriter does **not** emit inverse calls anywhere. All inverse
emission is the IR pass's responsibility (§7.5, §7.6, §7.8).

### 5.4 No specialization synthesis

The rewriter never inlines or expands the body of a quantum specialization.
It emits a call to a mangled name; the IR pass binds the body.

### 5.5 Multi-decl, mixed-operand, source-text handling

As in v1: a `quantum int a = 3, b = 2;` decomposes to two `qint_mid_t`
initializations sharing a `DeclStmt` region. Mixed-operand classical values
are spliced into stock `.val` arithmetic directly — no wrapping intrinsic
needed.

### 5.6 Diagnostic preservation

The rewriter preserves source locations on every emitted node so the
back-end's diagnostics can be reported in user-source terms via `!dbg`
metadata after Clang lowering.

---

## 6. Intrinsic surface

This is the complete LLVM-level extension surface. All ~7 functions are
declared (not defined) in `CQ.h` so user source parses and so the IR
pass can pattern-match on the calls.

### 6.1 Construction (taint sources)

```c
qint_mid_t cq_init(int64_t value, unsigned num_bits);    /* classical-seed quantum */
qint_mid_t cq_alloc(unsigned num_bits);                  /* fresh |0…0> ancilla */
```

Both return a `qint_mid_t`; both are taint sources in the §7.1 analysis.

### 6.2 Measurement (taint sink)

```c
int64_t cq_measure(qint_mid_t);                          /* cast → classical, lossy */
```

The `i64` result is classical; taint stops here. Type-narrower casts
(e.g., `(int) q` when `q` is a `quantum short`) compose `cq_measure` with
a stock `trunc`.

### 6.3 Quantum-specific primitives (no classical opcode equivalent)

```c
void cq_theta(qint_mid_t* q, double angle);              /* R_y rotation in place */
void cq_phi  (qint_mid_t* q, double angle);              /* R_z rotation in place */
```

These have no stock-LLVM analog. The pointer-passing convention is
deliberate: the IR pass treats the `qint_mid_t*` argument as a quantum
register handle whose state mutates in place.

### 6.4 Region brackets (lexical-scope markers)

```c
void cq_when_begin(qint_mid_t cond);                     /* controlled-on cond */
void cq_when_end  (void);

void cq_invert_begin(void);                              /* invert the bracketed region */
void cq_invert_end  (void);
```

The IR pass treats instructions between matching `begin`/`end` pairs as
a region needing the specified transformation. Same shape OpenMP uses for
parallel regions, AddressSanitizer for instrumented regions.

### 6.5 Specialization mangling (declaration-only, no body)

For a classical function `T f(A, B, ...)`, the quantum specialization
when called with at least one `qint_mid_t` argument is named
`__cq_q_<demangled>_<arg-mode-mask>`. Inverse: `__cq_invert_<demangled>`.

The IR pass synthesizes the body of each on demand from `f`'s LLVM IR.
User source never writes these mangled names; the rewriter emits them.

### 6.6 What is *deliberately* not in the intrinsic surface

- **Arithmetic operators** (`add`, `sub`, `mul`, `div`, `mod`, shifts,
  bitwise, comparisons, unary): stock LLVM opcodes. Taint propagation
  identifies the quantum ones.
- **Type-width casts**: stock `sext` / `zext` / `trunc`. Taint
  propagates through them.
- **Per-op inverses** (`cq_add_inv`, `cq_mul_inv`, …): generated
  mechanically by `emit_inverse` (§7.6); not declared as intrinsics.
- **Per-op controlled variants**: similarly, generated by the IR pass
  from the forward template when inside a `cq_when_*` region.

This keeps the LLVM-visible surface trivially small and forces all
arithmetic to live in stock IR where standard LLVM optimization
(constant folding, peephole, DCE) applies before our pass even runs.

---

## 7. IR pass (back-end) responsibilities

This is where most of CQ_lang's compiler work lives. The pass runs after
Clang's standard optimization (`-O1`-level mem2reg + sroa minimum); its
input is clean SSA with `qint_mid_t` struct types preserved at function
boundaries and `@cq_*` intrinsic calls preserved as opaque external
calls.

### 7.1 Forward taint propagation

The first analysis the pass runs. Standard data-flow over SSA values.

```
taint_sources = {
    return value of @cq_init / @cq_alloc call sites,
    qint_mid_t-typed function parameters,
    extractvalue results of any of the above,
}

taint(v) = true  iff  v is in taint_sources, OR
                       any operand of the producing instruction is tainted

taint_sinks = {
    @cq_measure call sites,   // result (i64) is classical
}
```

Propagation is monotone and terminates on the SSA DAG. After the pass:

- Every stock LLVM instruction (`add`, `mul`, `icmp`, etc.) whose result
  is tainted is a **quantum operation**. The reversibilization pipeline
  applies.
- Every untainted instruction is **classical**. Left alone.
- Branch conditions (`br i1`) that are tainted indicate quantum control
  flow that should be inside a `cq_when_*` region. (The rewriter is
  responsible for ensuring this; the IR pass can sanity-check.)

This is the mechanism that lets the same `add i32` be quantum in one
function instance and classical in another, without any function-level
annotation.

### 7.2 Call-graph specialization

Driver loop:

```
worklist = { call sites where any arg is qint_mid_t-typed }
visited  = ∅

while worklist not empty:
    call = worklist.pop()
    spec_key = (target_function, q-arg-mask)

    if spec_key in visited: continue
    visited.add(spec_key)

    target_ir = resolve_ir(target_function)
    if target_ir is None:
        emit error: "no IR available for {target}, cannot specialize"
        continue

    if not classify_reversibilizable(target_ir):
        emit error or insert measurement bridge (per design decision §12)
        continue

    spec_body = synthesize_quantum_specialization(target_ir, q-arg-mask)
    cache[spec_key] = spec_body

    // any calls within spec_body that take qint_mid_t become new entries
    for each call within spec_body whose operands include qint_mid_t:
        worklist.push(call)
```

Crucially, `synthesize_quantum_specialization` uses **the same per-opcode
template substitution** as the per-op lowering in §7.5 — taint
propagation on the target's IR (with parameters marked tainted from the
start), then template substitution on tainted instructions.

### 7.3 Reversibilizability classifier

Walk the candidate function's IR. Reject if any of the following are
present:

| Reject | Reason |
|---|---|
| inline asm | opaque |
| syscall instructions | non-pure |
| `volatile` loads/stores | shared state |
| atomic instructions | shared state / non-determinism |
| exception-handling (`invoke`, `landingpad`, `catchpad`) | non-reversible |
| `setjmp` / `longjmp` (via libc decl) | non-reversible non-local control |
| indirect calls to unresolved targets | unknown reversibilizability |
| recursion without static depth bound | possibly non-terminating |
| vector / SIMD intrinsics | not yet implemented; future |
| transcendental intrinsics without soft impl | future |

Accept on a clean pass. Diagnostics report the offending instruction with
source-location precision via `!dbg`.

### 7.4 Per-op uncomputation (auto)

For each quantum-mode function being lowered:

1. Build an ordered sequence of tainted instructions in program order.
2. For each tainted SSA value `%v`, determine its last use (live-range
   end) via the SSA def-use graph.
3. At each last-use point (or at `@llvm.lifetime.end` for stack
   `qint_mid_t` slots), emit the **adjoint** of the tainted instructions
   that produced `%v`. The adjoint is generated by `emit_inverse` (§7.6)
   from the gate sequence the forward instructions lowered to.
4. Exceptions:
   - the enclosing function is `main` (ROADMAP §Phase 5)
   - `%v` escapes via return-by-value (callee preserves it)
   - `%v` is explicitly handed off via a `cq_invert_*` region inversion

### 7.5 Lowering to runtime gate calls

After taint analysis, specialization, and uncomputation emission, each
tainted instruction and each `@cq_*` intrinsic is replaced with calls
into `libcq_runtime`. Sketched mapping:

| Tainted or intrinsic | Lowered |
|---|---|
| `call @cq_init(v, w)` | `cqrt_alloc_classical(int qubit_handle, i64 v, u32 w)` |
| tainted `add i32 %a, %b` | sequence of `cqrt_cnot` / `cqrt_toffoli` realizing the chosen adder template, on qubit handles of `%a`, `%b` |
| tainted `mul i32 %a, %b` | shift-and-add or Karatsuba template, similarly |
| tainted `icmp slt i32 %a, %b` | comparator circuit producing a flag qubit |
| `call @cq_theta(q, θ)` | `cqrt_ry(handle(q), θ)` |
| `call @cq_phi(q, θ)` | `cqrt_rz(handle(q), θ)` |
| `call @cq_measure(q) → v` | `cqrt_measure(handle(q))` returning `i64` |
| `cq_when_begin(q) … cq_when_end()` | each inner gate replaced by its controlled version, controlled on `handle(q)` |
| `cq_invert_begin() … cq_invert_end()` | inner gate sequence reversed + adjointed per §7.6 |

After lowering, the IR contains no `@cq_*` calls and no tainted stock
opcodes — only `cqrt_*` runtime calls and the surrounding control flow
that threads them.

### 7.6 Inverse generation (mechanical)

For any forward gate sequence `S` produced by §7.5:

```
emit_inverse(S):
    for each gate g in reverse(S):
        if g has parameterized angle:  emit g with angle negated
        else:                          emit g as-is  (self-adjoint)
```

NOT, CNOT, Toffoli are self-adjoint → no transformation.
`cqrt_ry(handle, θ)` inverse → `cqrt_ry(handle, -θ)`. Same for `cqrt_rz`.

The IR pass thus needs only **forward + controlled-forward** templates
per primitive. Adjoint and controlled-adjoint are produced by
`emit_inverse` post-hoc. (Cuts ROADMAP Phase 3's per-op surface in half.)

### 7.7 Specialization synthesis

For each `__cq_q_<f>_<mask>` mangled call discovered in §7.2:

1. Fetch `f`'s LLVM IR.
2. Mark parameters corresponding to `mask` as tainted.
3. Run taint propagation on `f`'s body.
4. Apply §7.5 lowering to tainted instructions.
5. Wrap with Bennett's construction at function boundaries:
   forward + CNOT-copy of return value to caller-provided output regs +
   reverse the forward pass to clear ancillas.
6. Cache the result; replace the mangled call with a direct call to it.

Bennett's wrap-the-whole-function is used **only here** — at the
boundary between CQ source and externally-defined (or recursively-
specialized) functions. Within CQ source, ROADMAP §2's per-op
uncomputation applies via §7.4.

### 7.8 Manual inversion via `invert(...)`

User surface form: `invert(foo)(args);` (exact spelling per ROADMAP
Phase 2; mechanism is independent).

The rewriter lowers this to a call to `__cq_invert_<foo>(args)` (the
mangled inverse-specialization name). The IR pass synthesizes its body
by:

1. Running the forward `__cq_q_foo_<mask>(args)` synthesis (§7.7) if not
   already in cache.
2. Applying `emit_inverse` (§7.6) to the forward's gate sequence.
3. Caching.

This is **distinct** from auto-uncomputation at scope exit (§7.4):
auto-uncomputation runs without user intervention; manual inversion
applies the inverse of an explicit operation the user wants to undo (e.g.
de-preparing a state after a measurement, undoing oracle preparation in
phase estimation).

---

## 8. Runtime emission model

The compiled binary makes calls into `libcq_runtime`. The runtime's API
is the gate set:

```c
// libcq_runtime API (sketch)
int      cqrt_alloc(unsigned num_bits);             // → qubit handle
int      cqrt_alloc_classical(i64 val, u32 width);
void     cqrt_free(int handle);

void     cqrt_x  (int q);
void     cqrt_cnot(int ctrl, int target);
void     cqrt_toffoli(int c1, int c2, int target);
void     cqrt_ry(int q, double angle);
void     cqrt_rz(int q, double angle);

int64_t  cqrt_measure(int q);

void     cqrt_begin_circuit(...);    // optional batching
void     cqrt_end_circuit(...);
```

The runtime is **interchangeable**. Different implementations of
`libcq_runtime` give different output modes:

| Runtime | What happens at each gate call |
|---|---|
| `libcq_runtime_qasm.so` | Append a line to an OpenQASM output stream |
| `libcq_runtime_circuit.so` | Append to an in-memory `Circuit` struct |
| `libcq_runtime_eager.so` | Apply the gate immediately to a statevector (a la Orkan's EagerContext) |
| `libcq_runtime_density.so` | Apply to a density matrix; supports noise |
| `libcq_runtime_hw.so` | Serialize and dispatch to a hardware backend |

The same compiled CQ program produces different artifacts depending on
the runtime it links. Same separation Qiskit has between `QuantumCircuit`
and `Aer`/`Backend`.

### Phase 6 implications

ROADMAP §Phase 6 wants runtime-bound loops to "construct the circuit at
startup time. The runtime circuit is still flat." This drops out
naturally: the IR pass leaves the `for` loop alone; each iteration emits
its body's gate-runtime calls; the runtime accumulates them. Final
circuit shape depends on the loop bound at program startup.

---

## 9. ROADMAP phase mapping

How each ROADMAP phase lands under this architecture. Items marked
**[changed]** differ materially from the v1-era plan; items marked
**[same]** are unaffected by the architecture shift.

| Phase | Description | Architecture impact |
|---|---|---|
| **1 — v1** | Basic qint, `+` only | **[done as-is]** — proof-of-pipeline at the AST/rewriter layer |
| **2 — type system + `CQ.h`** | All widths + qfloat/qdouble stubs + `theta`/`phi`/`invert` markers | **[changed]** `CQ.h` becomes the declaration site for the tiny §6 intrinsic surface (~7 functions, no arithmetic intrinsics). Backend headers no longer ship with rewritten output; the binary links against `libcq_runtime` instead |
| **3 — full op set** | Every primitive in QQ / QC forms, 4 shapes per op | **[changed substantially]** No QQ/QC variants — taint propagation handles both. 4 → 2 shapes per primitive (forward + controlled-forward); adjoints derived per §7.6. The "primitive op" surface is now the 38 LLVM opcodes (template per opcode in the opcode-template library), not language-level operators |
| **3.3 — classical-mask views** | `q & C` as zero-cost bit view | **[same in principle]** view materialization is an IR-pass operation triggered at binding sites |
| **3.4 — mixed-width type promotion** | C-standard widening rules | **[easier]** Clang lowers to explicit `sext` / `zext` / `trunc`; taint propagates through them; the reversibilization templates for those opcodes handle the rest |
| **4 — `if` (q-condition)** | Type-dispatched on condition | **[partially changed]** rewriter emits `cq_when_*` bracket pairs; IR pass owns controlled-form substitution. Sturm's `when`/`if` distinct-construct argument deserves explicit consideration (see §12) |
| **5 — auto uncomputation** | Per-op compile-time adjoints | **[changed]** moves from AST-level use-def to IR-level SSA live-range analysis over tainted values. ROADMAP §2 principle preserved; implementation is strictly easier |
| **6 — for-loops** | Classical bounds | **[same]** Clang handles loop lowering; IR pass leaves loop intact, emits body's gate calls per iteration |
| **7 — user-defined fns + inversion** | Function adjoint derivation; explicit `invert(...)` | **[changed]** function specialization and inversion are the call-graph mechanism (§7.2, §7.8). No `is_adjointable` propagation; classify each function once and synthesize on demand |
| **8 — memory: arrays/pointers** | Array indexing, pointer aliasing | **[easier]** LLVM alias analysis available; Bennett-style memory strategies (Shadow/MUX/QROM) selectable per allocation site at the IR pass |
| **9 — full C surface** | structs/unions/typedefs/storage classes | **[easier]** Clang frontend lowers all of these correctly; rewriter only handles AST shapes that contain quantum-typed members |
| **10 — q-conditioned while loops** | Likely amplitude amplification | **[same]** still deferred |
| **11 — optimization passes** | Gate cancellation, ancilla reuse, fusion | **[easier]** standard LLVM-pass shapes operating on lowered IR (post §7.5); constant folding, DCE, peephole free from LLVM |

---

## 10. Toolchain assumptions and obligations

Under this architecture, the user (or the project's build system) must:

- **Provide IR for any external function called with quantum arguments.**
  Compile libm and other standard libraries with `-emit-llvm` and ship
  the `.bc` archives alongside the runtime. Pre-build a canonical
  `libm.bc` for distribution. Closed-source binary libraries without
  IR cannot be specialized.

- **Use LTO-aware linkage** at the point where the CQ IR pass runs.
  Either run the pass under `-flto` or perform the specialization step
  as a discrete tool that ingests all relevant `.bc` files.

- **Link against `libcq_runtime`.** The binary is incomplete without one
  of the runtime variants.

Failure modes that need to be designed (see §12):

- A reachable external function has no IR available
- A reachable function fails the reversibilizability classifier
- An indirect call cannot be devirtualized

---

## 11. Future direction: MLIR

MLIR (LLVM's Multi-Level Intermediate Representation) is a natural
long-term consideration. It allows defining custom dialects with new IR
types, operations, and region semantics — strictly richer than the
intrinsic-call mechanism described in §6.

**Why it would be attractive:**

- **First-class quantum types** (`!quantum.qubit_register<8>`,
  `!quantum.amplitude`) survive optimization passes by construction —
  no taint propagation needed
- **Custom region semantics**: a `quantum.when` op with a region operand
  carries controlled-execution semantics natively; same for
  `quantum.invert`
- **Multi-level lowering**: preserve high-level structure (e.g.,
  "this is a quantum adder") through optimization, then progressively
  lower to gate-level — preserves optimization opportunities the
  intrinsic approach has to recover via pattern-matching
- **Standard interchange**: emerging quantum-MLIR efforts
  (PennyLane Catalyst, CIRCT-Q, Quantum-MLIR, QSSA) define dialects
  that CQ could either adopt or interoperate with
- **Multi-language input** at the dialect level becomes natural: Polygeist
  for C, mlir-rust for Rust, etc. — all converge on the same dialect
  before gate-level lowering

**Why not now:**

- Significant infrastructure investment; MLIR has a learning curve
- The intrinsic + taint-propagation approach is sufficient through
  Phase 9 of the ROADMAP; we have no concrete problem MLIR uniquely
  solves
- MLIR is still evolving and quantum dialects are still consolidating;
  early adoption risks lock-in to a transient interface
- A single front-end (C) doesn't yet justify the cross-language
  multi-frontend story MLIR shines at

**Plausible trigger conditions for revisiting:**

1. **Phase 11 (optimization)** demands cross-region quantum/classical
   optimization that intrinsics cannot cleanly express (e.g.,
   commuting gates across non-trivial classical control flow)
2. **A second frontend** (Rust-with-quantum, Python-with-quantum, etc.)
   becomes a real product requirement
3. **A quantum dialect standardizes** in the broader compiler community
   to a degree that CQ's interop value would substantially increase
4. **A specific intrinsic-approach limitation** turns up that's
   awkward to engineer around — e.g., a Phase 11 optimization that
   requires reasoning about quantum-typed instructions across
   intermediate classical computations

Until at least one of these triggers fires, the intrinsic-based design
described in §3–§7 is the right point on the cost/value curve.

---

## 12. Open design questions

These are the explicit decisions still owed:

1. **`when` vs type-dispatched `if`.** Sturm's argument (composition
   under function lifting) bites for our Phase 7. Keep type-dispatched
   `if` (lighter user-facing change), introduce a `when` keyword
   (stronger compositional guarantees, larger surface change), or
   ship both?

2. **`invert` surface spelling.** ROADMAP Phase 2 leaves this TBD.
   Options: keyword `invert foo(...)`, function-call `invert(foo)(...)`,
   attribute `__attribute__((adjoint))`. Mechanism is independent;
   pick what reads best in C.

3. **Failure on non-reversibilizable callee.** When a quantum argument
   flows into a function that fails the classifier (or has no IR),
   three options:
   - **Compile error.** Strict; forces the user to provide a replacement
     or measure explicitly.
   - **Implicit measurement.** Insert `@cq_measure` at the boundary and
     proceed classically. Convenient; loses quantum info.
   - **Warning + implicit measurement.** Sturm's choice.

4. **Auto-specialization scope.** Every reachable function, or only
   functions the user has opted into (e.g. via a marker that's not a
   "reversible attribute" but a "specialize-on-demand" hint)? Bennett.jl
   in practice asks for `oracle(f, q)` because compile-time cost
   balloons otherwise. We can start strict and relax later.

5. **`qint_mid_t` ABI stability.** Single-field struct
   (`struct { int val; }`) is mem2reg-friendly. Should it carry a `mask`
   field (per-bit attribution, ROADMAP principle 9) at the mid level, or
   is that purely a backend concern?

6. **Specialization mangling scheme.** Concrete name format, handling of
   overloads, ABI stability across compiler invocations for caching.

7. **Runtime API stability.** `libcq_runtime` is the interchange point
   with simulators / hardware. Its API needs a versioning discipline.

8. **Diagnostics location preservation.** `!dbg` survives most opt
   passes but not all. What's the minimum-acceptable diagnostic fidelity
   at use-site error reporting (Phase 5 promise)?

9. **MLIR trigger threshold.** Concretely document the trigger
   conditions in §11 against ROADMAP phases — when does the cost of
   intrinsic-pattern-matching become higher than the cost of MLIR
   adoption?

---

## 13. Glossary

| Term | Meaning |
|---|---|
| `qint_mid_t` | Mid-level frontend struct type. Single integer field. Survives at function-signature boundaries; flattened within bodies by mem2reg. |
| Frontend qint_t | Synonym for source-level / `quantum int` usage and `qint_mid_t` at IR boundaries. The user-visible quantum type. |
| Backend qint_t | The runtime's actual qubit register / handle. Lives in `libcq_runtime`. Not our compilation concern. |
| Taint propagation | Forward data-flow analysis that marks SSA values as quantum if they are produced (directly or transitively) by `@cq_init` / `@cq_alloc` / a `qint_mid_t`-typed parameter. The mechanism that lets stock LLVM opcodes carry quantum-ness without dedicated arithmetic intrinsics. (§7.1) |
| Taint source | `@cq_init`, `@cq_alloc`, `qint_mid_t`-typed function parameters. |
| Taint sink | `@cq_measure` (result is classical i64). |
| Quantum operation | A stock LLVM instruction whose result is tainted, OR a `@cq_*` intrinsic call. Eligible for lowering to gates by the IR pass. |
| Quantum specialization | An IR-pass-synthesized function body where every tainted instruction is replaced by its reversible-gate template. Generated on demand from a classical function's IR via §7.7. |
| Reversibilizable function | A function whose IR passes the classifier (§7.3). Eligible for quantum specialization. |
| Reversibilization | Per-opcode template substitution + Bennett's construction at the function boundary (forward + CNOT-copy of return + reverse). The compile-time analog of "make this function reversible". |
| Uncomputation | Compile-time emission of adjoint operation sequences at scope exits / last uses of tainted values. Per-op, not whole-call. ROADMAP §2. |
| Inverse | The adjoint of a gate sequence; mechanically generated by `emit_inverse` (§7.6) from the forward template. |
| Manual inversion | User-explicit `invert(foo)(args)` surface form; lowered to a call to `__cq_invert_<foo>`. Distinct from auto-uncomputation. |
| Auto-uncomputation | Last-use-driven emission of adjoint sequences for tainted values going out of scope. |
| Quantum entry point | A call site or expression in the original CQ source whose evaluation introduces taint into the IR (e.g., a `quantum int` decl that calls `@cq_init`). |
| Specialization cache | Per-(function, q-arg-mask) memoization of synthesized quantum specializations. |
| `libcq_runtime` | The gate-emission runtime library the compiled binary links against. Interchangeable per output target (OpenQASM / in-memory / simulator / hardware). |
| MLIR | LLVM's multi-level IR framework. Future-direction option for CQ; see §11. |

---

## 14. References

- [`ROADMAP.md`](../ROADMAP.md) — phase trajectory; this document refines,
  does not replace, the phase definitions
- [`pipeline-sketch.md`](./pipeline-sketch.md) — whiteboard transcription
  that motivated the layered design
- [`bennett-jl-comparison.md`](./bennett-jl-comparison.md) — design
  convergences/divergences with Sturm.jl / Bennett.jl / Orkan
- [`example.md`](./example.md) — worked end-to-end example from CQ
  source through LLVM IR
- C. H. Bennett, "Logical reversibility of computation" (1973) — forward
  + copy + reverse construction
- LLVM intrinsic-call pattern: Enzyme (autodiff), AddressSanitizer,
  OpenMP runtime, Polly — same architectural shape
- MLIR Quantum dialect efforts: PennyLane Catalyst, CIRCT-Q,
  Quantum-MLIR, QSSA — referenced in §11
