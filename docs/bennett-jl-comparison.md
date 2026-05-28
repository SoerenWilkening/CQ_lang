# CQ_lang vs Sturm.jl / Bennett.jl / Orkan — Rigorous Comparison

Comparison of CQ_lang's architecture with the three-layer Julia stack
maintained by Tobias Osborne (CQ_lang's advisor):

- **Sturm.jl** (https://github.com/tobiasosborne/Sturm.jl) — the quantum DSL
- **Bennett.jl** (https://github.com/tobiasosborne/Bennett.jl) — classical-to-reversible compiler
- **Orkan** (C17) — statevector / density-matrix simulator backend

Sources consulted: Sturm.jl README; Bennett.jl README, `docs/src/index.md`,
`docs/src/architecture.md` (fetched 2026-05-21).

> **Revision notes.**
> * An earlier draft compared CQ_lang to Bennett.jl alone and concluded
>   Bennett had "no rotations, no measurement, no quantum control." That
>   framing was wrong — the **quantum-language layer is Sturm.jl**, which
>   sits on top of Bennett and provides exactly those primitives.
> * A subsequent draft compared CQ_lang against Sturm under the
>   `quantum`-keyword / cast-as-measurement design. That CQ design has
>   since been retired in favor of the taint-driven pipeline
>   ([`frontend.md`](./frontend.md), [`backend.md`](./backend.md),
>   [`quantum-classical-handling.md`](./quantum-classical-handling.md)).
>   This document supersedes both earlier drafts.
> * Bennett's `when(qubit) do f(x) end` is the integration hook that
>   Sturm composes against (documented as the integration motivation;
>   current implementation status in Bennett v1.0 vision).

---

## TL;DR

**The right comparison is CQ_lang vs Sturm+Bennett+Orkan**, not CQ_lang vs
Bennett alone. Both projects are quantum-programming languages with
explicit rotations, explicit measurement-as-a-cast, and a bridge for
lifting classical functions into reversible circuits.

Under the taint-driven redesign, the *surface-level* convergence between
CQ_lang and Sturm has tightened considerably:

- **Explicit `cq_measure(x)` ↔ Sturm's `Bool(q)` / `Int(q)`.** Both
  designs make measurement syntactically distinct and the *only* path
  to state collapse. CQ_lang no longer has cast-as-measurement; an
  `(int) q` on a tainted `q` is a representation change, never a
  measurement.
- **Two rotation primitives.** `cq_theta(x, θ)` ↔ `q.θ += δ` (Ry) and
  `cq_phi(x, φ)` ↔ `q.φ += δ` (Rz).
- **Classical-function lifting.** Sturm's `oracle(f, q)` ↔ CQ_lang's
  clone-on-taint specialization (visible bodies) + curated symbol
  substitution (libm, intrinsics).
- **Plain control flow stays plain.** Sturm distinguishes `when(q)`
  (quantum) from `if Bool(q)` (post-measurement classical); CQ_lang
  dispatches the *same* `if` keyword on the condition's taint state,
  because measurement has its own syntax (`cq_measure`) and cannot be
  conflated with `if`.

The two structural differences that remain:

1. **The boundary mechanism.** Sturm uses a static type distinction
   (`QInt{W}` vs `Int`); CQ_lang uses a data-flow property (taint) on
   plain stock LLVM SSA values. Same goal — "the type system knows what
   is quantum" — different substrate.
2. **Uncomputation.** Sturm/Bennett wraps any lifted call with
   Bennett's 1973 construction (forward + CNOT-copy + reverse). CQ_lang
   uses per-op compile-time adjoints driven by SSA last-use analysis.
   These cover different cases — they are complementary, not competing
   — and CQ_lang uses Bennett-style wrap-around at one load-bearing
   point (clone synthesis at the CQ ↔ external-callee boundary).

The hybrid recommendation from the earlier draft (AST front-end + LLVM-IR
oracle path) is gone, replaced by something simpler: a small header
(`CQ.h`), stock Clang `-O1`, and a single LLVM IR pass. The taint-driven
design subsumed both halves of the hybrid.

---

## The full Osborne stack

```
┌─────────────────────────────────────────────────────────────────────┐
│ Sturm.jl (Julia)  — quantum DSL                                     │
│   • Types: QBool, QInt{W}                                           │
│   • Primitives: q.θ += δ (Ry), q.φ += δ (Rz)                        │
│   • Casts: Bool(q), Int(q) = measurement; QBool(p) = preparation    │
│   • Control: when(q) do ... end (coherent) vs if Bool(q) ...        │
│   • Bridge: oracle(f, q) lifts typed classical Julia via Bennett    │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Bennett.jl (Julia) — classical-to-reversible compiler               │
│   • code_llvm → LLVM IR → ParsedIR (SSA name table)                 │
│   • lower: 38 LLVM opcodes → {NOT, CNOT, Toffoli}                   │
│   • Memory strategies: Shadow, MUX-EXCH, QROM, Feistel, persistent  │
│   • Adder/multiplier strategies: ripple, Cuccaro, QCLA / Karatsuba  │
│   • Multi-language ingest: .ll/.bc from clang/rustc/etc.            │
│   • Quantum-control hook: when(qubit) do f(x) end                   │
│     (documented integration point; v1.0 vision)                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Orkan (C17) — simulator backend                                     │
│   • EagerContext (statevector), DensityMatrix, Tracing, Hardware    │
│   • OpenMP, statevector and density-matrix evolution                │
└─────────────────────────────────────────────────────────────────────┘
```

---

## CQ_lang vs Sturm — side by side

| Axis | **CQ_lang (taint-driven)** | **Sturm.jl** |
|---|---|---|
| Surface language | Plain C + `#include <CQ.h>` | Plain Julia |
| Front-end | `CQ.h` (`_Generic` dispatch) + stock Clang `-O1 -emit-llvm` | Julia compiler + macros + dispatch |
| Quantum data | No special type — taint is a property of SSA values, not declarations | `QInt{W}`, `QBool` — static type distinction |
| Amplitude rotation | `cq_theta(x, θ)` → Ry; sole taint **source** | `q.θ += δ` → Ry |
| Phase rotation | `cq_phi(x, φ)` → Rz; propagates taint only (no allocation) | `q.φ += δ` → Rz |
| Measurement | `cq_measure(x)` — explicit call; sole taint **sink** | `Bool(q)`, `Int(q)` — explicit cast; sole sink |
| Casts under quantum data | Representation change → quantum cast templates (`cq_template_sitofp_…`); **never** a measurement | `Bool(q)`/`Int(q)` *is* the measurement; other casts do not exist on `QInt{W}` |
| Manual inversion | `cq_invert_begin();` / `cq_invert_end();` — pass derives adjoint per-op | implicit (Bennett wraps whole calls) |
| Quantum control | Plain `if (tainted_cond) { ... }` — pass detects tainted branch condition, recovers shadow via `PostDominatorTree` | `when(q) do ... end` — distinct keyword |
| Classical control | Plain `if (classical_cond) { ... }` — same `if` keyword, untainted condition | `if Bool(q) ... end` (post-measurement) |
| Classical → quantum function bridge | Clone-on-taint specialization (visible bodies) + curated symbol substitution (libm, intrinsics) | `oracle(f, q)` |
| Uncomputation | Per-op compile-time adjoints, SSA last-use via `PostDominatorTree` | Whole-call Bennett 1973 (forward + CNOT-copy + reverse) |
| Per-op contract | forward + controlled-forward only; adjoint mechanically derived (`emit_inverse`) | No equivalent — Bennett derives everything from LLVM-IR opcodes |
| Allocation trigger | Gate-triggered: first `cq_theta` on a classical operand inserts `cqrt_alloc_<W>` | Declaration-triggered: `QInt{W}(p)` preparation |
| Mixed-operand opcodes | Handle + literal stays as literal — `_hl` template variant; classical operand never promoted to a handle | `QInt{W}` is uniformly quantum; mixed cases handled via Sturm/Bennett's preparation surface |
| Target gate set | Universal Q gates (forward + controlled-forward) declared; bodies deferred to post-frontend-freeze | {NOT, CNOT, Toffoli} from Bennett; rotations from Sturm primitives |
| Simulator backend | Two declared variants (`libcq_runtime_count`, `libcq_runtime_sim`) sharing one handle ABI; bodies deferred | Orkan (statevector / density-matrix) |
| Circuit export | TBD | OpenQASM via TracingContext |
| Multi-language input | Anything → LLVM bitcode → `llvm-link` → `opt` pass (same path as C) | Anything → LLVM IR → Bennett |

---

## Design convergences (independent validation)

Sturm and CQ_lang were designed independently and converge on a striking
number of choices. Several convergences strengthened under the
taint-driven redesign:

| Concept | Both projects |
|---|---|
| Measurement is syntactically explicit and the **only** state-collapse path | **Strengthened**: `cq_measure(x)` ↔ `Bool(q)`/`Int(q)`. CQ_lang no longer has cast-as-measurement, eliminating the implicit-collapse failure mode |
| Two rotation primitives (Ry, Rz) | yes |
| Rz on classical state is a no-op | **New convergence**: CQ_lang's IR pass deletes `cq_phi` on classical operands; Sturm's `q.φ += δ` on a basis state is observationally a no-op |
| Classical functions lifted via dedicated bridge | yes (`oracle(f, q)` ↔ clone-on-taint + curated symbols) |
| No named gates in user code | yes (CQ_lang exposes only `cq_theta` / `cq_phi` / `cq_measure` / `cq_invert_*` — no `H`, no `CNOT`, no `X` at the user surface) |
| Symmetric primitive contract (`when(a) do not!(b) end` = CNOT) | yes — CQ_lang derives controlled forms structurally from tainted-branch shadows; same mechanism, no separate keyword |
| Functions as channels / first-class composition | yes (Sturm P1 ↔ CQ_lang's function lifting) |
| User writes domain logic, system handles QM | yes |
| Reject side-effecting calls under lifting | **Strengthened**: both projects diagnose `printf`/syscalls/external globals at the lifting boundary |

The convergence at the *user-visible surface* is now near-total. The
remaining divergences are about **how the type system or analysis
determines what is quantum**, not about what the user writes.

---

## Design divergences (where you should think twice)

### 1. The boundary mechanism: static type vs data-flow taint

Sturm draws the Q/C boundary at the **type system**:

```julia
q::QInt{8}        # quantum (8 qubits)
x::Int            # classical
```

CQ_lang draws it at the **data flow**:

```c
int q = cq_theta(x, 0.3);  /* %q is tainted in IR — same C type as x */
int y = q + 5;             /* %y is tainted (operand-rule propagation) */
int m = cq_measure(y);     /* %m is classical — taint sink */
```

The two approaches reach the same destination (the system knows which
values are quantum at every point) by different routes:

| Aspect | Static type (Sturm) | Data-flow taint (CQ_lang) |
|---|---|---|
| Surface signal | Type annotation on declaration | None — taint inferred from SSA flow |
| Function lifting | Method dispatch on `QInt{W}` vs `Int` | Clone-on-taint keyed by per-arg signature |
| Bodies authored once | Yes (Julia multimethods) | Yes (the same C function is cloned per signature) |
| Boundary visibility | Read off the type signature | Read off the IR after taint analysis |
| User-facing language burden | New quantum types | No new types — plain C scalars throughout |
| Composability with non-CQ-aware code | Requires `oracle(f, q)` for non-quantum-aware fns | Same — clone-on-taint + curated symbol table |

Neither approach is strictly better; they are appropriate to different
host languages. Julia has rich type-system machinery (parametric types,
multimethods) that makes the static-type route ergonomic. C does not —
adding a `quantum int` keyword required a Clang rewriter and a struct
wrapper that broke when classical functions had hidden casts, which is
what motivated CQ_lang's redesign. Plain C scalars + IR-level taint
analysis is the C-shaped solution to the same problem Sturm solves
with `QInt{W}` + multimethods.

### 2. Quantum control: `when` vs taint-dispatched `if`

The earlier draft framed this as the central divergence. Under the
taint-driven design the divergence is narrower than it looked.

Sturm's argument for a distinct `when` keyword centered on compositional
semantics under function lifting: if `if` had two meanings depending on
whether `Bool(q)` was applied to the condition, the same `if` line
inside a lifted function would mean different things in different call
contexts. The fix in Sturm is to give the two cases different keywords.

CQ_lang's taint-driven design addresses the same concern by a different
route:

- **`if` is always `if`.** The C source is unchanged. The IR pass
  inspects the branch condition's taint state at lowering time and
  picks the controlled-form lowering iff the condition is tainted.
- **Measurement is a separate primitive** (`cq_measure`), not a cast.
  The Sturm-style "if `if` is fed a measurement cast, it means classical
  control" failure mode does not exist: in CQ_lang you write
  `if (cq_measure(q)) { ... }` to get classical control after
  measurement, and `if (q > 0) { ... }` with tainted `q` to get
  quantum control. The two cases differ at the level of the **condition
  expression**, not at the level of the **`if` keyword**.

Sturm's compositional concern still applies in one specific form: a
function lifted with a `(tainted, tainted)` signature vs the same
function called classically may lower the same `if` inside its body to
controlled-form gates in one specialization and stock branches in the
other. This is by design and is the whole point of cloning per
taint-signature — it is not a semantic ambiguity, it is a specialization
boundary. The cloned body is a distinct LLVM function (`__cq_q_<f>_<sig>`)
whose IR is unambiguous; the source-level `if` is shorthand that
specialization disambiguates.

In short: Sturm avoids the ambiguity at the source level; CQ_lang
disambiguates at the specialization layer. C's host-language constraints
push hard toward the latter (introducing a `when` keyword would require
either Clang patches or `_Generic` magic that adds no semantic
content over the taint check), and the taint-driven design's
explicit-`cq_measure` rule removes the second of Sturm's two motivating
ambiguities entirely.

### 3. Whole-call Bennett vs per-op compile-time adjoint

The remaining structural difference, mostly unchanged from the earlier
draft:

| Aspect | Per-op adjoint (CQ_lang) | Whole-call Bennett (Sturm) |
|---|---|---|
| Depth for inlined primitive sequence | minimal | 3× (always) |
| Ancilla reuse across primitives | possible (compiler can analyze SSA last-use) | not directly (each call is sealed) |
| Adjacent-inverse cancellation | natural | invisible (across a call boundary) |
| Adjointability contract | every primitive ships forward + controlled; adjoint derived | no per-primitive contract needed |
| Works on opaque foreign code | no (need IR body or curated symbol) | yes (Bennett derives reversibility from any LLVM IR) |
| Compiler complexity | higher | lower |

**These aren't competing — they cover different cases.** For primitive
ops and user-defined functions composed of primitives, per-op is more
efficient. For opaque classical functions (oracles, third-party
libraries, non-C code via `.ll`), per-op is impossible and a Bennett-style
construction is the only path.

CQ_lang's pipeline embodies both:

- **Per-op** is the default for everything the pass can see: stock LLVM
  opcodes lowered via `cq_template_<op>` calls, each with a derived
  `_inv` counterpart; uncomputation emitted at SSA last-use points via
  `PostDominatorTree::findNearestCommonDominator` (see
  [`backend.md`](./backend.md) §9–§10).
- **Bennett-style wrap-around** is used at one load-bearing point:
  clone synthesis when the pass needs the boundary-preserving forward +
  CNOT-copy + reverse construction so a specialized clone fits the
  handle ABI signature without leaking ancillas to the caller (see
  [`backend.md`](./backend.md) §7.2, §9.4).

So the divergence from the earlier draft survives, with one clarification
visible in the current design: CQ_lang does not reject Bennett-style
uncomputation wholesale; it reserves it for exactly the case it is
indispensable for (cross-function boundaries) and uses per-op everywhere
else.

---

## What changed from the earlier draft

For readers who saw the prior version of this document, the substantive
changes are:

| Topic | Earlier draft | Current draft |
|---|---|---|
| The "qint_t as struct" observation | Discussed LLVM IR's preservation of the `qint_mid_t` struct as a nominal type; framed an LLVM IR pass as feasible because of it | **Obsolete** — there is no `qint_t` / `qint_mid_t` struct in the taint-driven design; the SSA is plain `i32`/`i64`/`f64`. The IR pass still works, for a different reason: taint is a data-flow property on stock SSA, recovered by forward propagation from `@cq_theta` returns |
| Recommended adoption pattern (AST front-end + `reversible_oracle` attribute) | Hybrid: AST rewriter as primary, attribute-marked LLVM IR path for classical oracles | **Subsumed** — both halves of the hybrid converged. The actual design has no AST rewriter (the frontend is `_Generic` macros in `CQ.h` + stock Clang `-O1`); both classical oracles and user code go through the same clone-on-taint path in the single IR pass. No attribute is needed; taint signature alone drives specialization |
| Cast-as-measurement | Treated as a defensible source-level convention | **Retired** — diagnosed as the cause of the function-lifting failure mode (hidden casts inside library bodies collapsing the state). The taint-driven design separates representation change (cast) from substrate change (measurement) syntactically and semantically (see [`quantum-classical-handling.md`](./quantum-classical-handling.md) §3) |
| `cq_init_*` family | Implicit in the "quantum int" surface; allocation at declaration time | **Retired** — allocation is gate-triggered, on the first `cq_theta` against a classical operand. A declared `int a` that is never rotated touches no qubits (see [`backend.md`](./backend.md) §5) |
| `cq_when_*` source surface | Proposed for explicit quantum-control bracketing | **Retired** — quantum control is recovered structurally from tainted `br i1` conditions via `PostDominatorTree`. No source-level marker is needed because tainted-condition is necessary and sufficient (see [`backend.md`](./backend.md) §8.4) |
| Per-bit `qint_t.mask` attribution | Listed as a CQ_lang feature distinguishing qubit vs classical bits in a register | **Retired at the front end** — the user surface no longer carries a per-bit mask. Mixed Q+C is now per-instruction (`_hl` template variant) rather than per-bit-of-register |

The earlier draft's verdict — *CQ_lang's design is in good territory,
the convergence with Sturm validates the direction* — survives intact.
The specific surface details have moved.

---

## Recommended adoption pattern (current design)

What the project actually does now, restated for completeness:

1. **`CQ.h` is the entire user surface.** Four families (`cq_theta`,
   `cq_phi`, `cq_measure`, `cq_invert_*`) declared per-type via
   `_Generic`. No keyword, no struct wrapper, no preprocessor pass
   beyond standard C macros.
2. **Stock Clang `-O1 -emit-llvm`** produces the bitcode the pass
   consumes. No fork, no plugin to the front end. `mem2reg` / `SROA`
   run inside `-O1` and put the IR in the plain-SSA form the pass
   expects.
3. **One LLVM pass module** (`libCQPass.so`) runs as `opt
   -load-pass-plugin libCQPass.so -passes=cq-lowering`. It performs
   forward taint propagation, gate-triggered allocation insertion,
   opcode lowering (the 38-opcode surface), call-graph specialization
   (curated + clone-on-taint), controlled-form lowering, and per-op
   uncomputation.
4. **One runtime ABI** (`libcq_runtime`) with the handle abstraction
   carries the substrate-side concerns. Two declared variants share the
   ABI: a gate-counter and a statevector simulator.

What CQ_lang adopts from the Sturm/Bennett stack:

- **Bennett-style wrap-around** at clone synthesis. The forward +
  CNOT-copy + reverse construction is the right shape for keeping a
  specialized clone's signature pure (no ancilla leakage to the
  caller). CQ_lang uses it only there; everywhere else it uses per-op
  adjoints.
- **The 38-opcode surface** as the natural shape of "what reversibility
  needs to cover at the LLVM IR layer." See
  [`backend.md`](./backend.md) §6.3.
- **The curated-symbol-substitution path** for libm and intrinsics —
  conceptually identical to Sturm's specialization of math symbols
  against `QInt{W}` arguments.
- **The lifting-rejection set** (`printf`, syscalls, external globals,
  vector intrinsics without soft impls, …). Same rejection list,
  same reason: not reversibilizable.

What CQ_lang explicitly does *not* adopt:

- **The static type distinction for Q vs C.** C's type-system
  machinery cannot support it without breaking lifting; taint on SSA
  is the C-shaped equivalent.
- **Whole-call Bennett wrap-around as the default uncomputation
  strategy.** Per-op is more efficient for the common case (composing
  primitives + cloned user code) and lets the pass exploit
  adjacent-inverse cancellation that whole-call wrap hides.

---

## Alternatives considered (current design)

| Alternative | Why not |
|---|---|
| **Keep the `quantum` keyword + AST rewriter** | Broke function lifting on classical bodies with hidden casts (see [`quantum-classical-handling.md`](./quantum-classical-handling.md) §3). Not patchable in place; the conflation of representation change and substrate change at the cast site was structural |
| **Static `qint_t` type at the LLVM IR layer (without source keyword)** | Requires Clang to emit the struct type, which requires either a rewriter or a header-only trick that breaks under `_Generic`. The taint relation on plain SSA gives the same information without the type surface |
| **MLIR with a custom quantum dialect** | Long-term plausible. Today: stock LLVM IR + a single out-of-tree pass plugin is enough; the cost of MLIR adoption is non-trivial and would be motivated only by optimization-phase needs that have not yet appeared |
| **Adopt Sturm wholesale (Julia front-end)** | Gives up C as the source language. Non-starter for "Quantum C" |
| **Subprocess Bennett.jl from the CQ pipeline** | Operationally awkward (Julia runtime in a C/C++ toolchain). The mechanisms CQ_lang needs from Bennett (the 38-opcode mapper, the wrap-around construction at clone synthesis) are small enough to implement in C++ alongside the IR pass — and that decouples our release cadence from Bennett.jl's |
| **Drop CQ_lang in favor of Sturm** | Misses the audience CQ_lang is for: C-ecosystem users, embedded / systems folks, anyone whose existing code is C. Sturm targets the Julia community |

---

## Open questions

1. **Curated-symbol coverage.** Sturm has a working list of math-symbol
   quantum templates (sin/cos/sqrt/fabs/…). CQ_lang's curated table is
   declared but the template bodies are deferred to post-frontend-freeze
   work. Which symbols are first priorities, and which of Sturm's
   gate-sequence choices does CQ_lang adopt vs derive independently?
2. **Bennett-mapper implementation.** Subprocess Bennett.jl,
   reimplement in C++, or write our own from scratch? Reimplementation
   gets us release independence; reuse gets us Bennett's evolving
   QCLA / Karatsuba work.
3. **Mixed-operand `_lh` deferral.** Non-commutative opcodes with the
   handle on the RHS (`a - %h_b`, etc.) currently force a swap via
   ancilla expansion. When does a real call site demand the explicit
   `_lh` template, and what is the gate cost trade-off?
4. **First demonstrable lifted oracle.** SHA-256 round? Modular
   exponentiation? Feistel block? Same natural test cases Sturm uses —
   per the Sturm README, Bennett reportedly compiles all three.
5. **OpenQASM export.** Sturm's `TracingContext` exports OpenQASM
   directly from execution. CQ_lang's gate-counter runtime variant
   could trace the same way; the symmetry is worth designing for.

---

## References

- Sturm.jl — https://github.com/tobiasosborne/Sturm.jl (README, README §P1–P9)
- Bennett.jl — https://github.com/tobiasosborne/Bennett.jl (README, docs/src/index.md, docs/src/architecture.md)
- C. H. Bennett, "Logical reversibility of computation" (1973)
- Enzyme — LLVM-level AD; the architectural prior Bennett cites
- CQ_lang [frontend.md](./frontend.md) — user surface, allocation, lifting
- CQ_lang [backend.md](./backend.md) — IR pass, runtime ABI, templates
- CQ_lang [quantum-classical-handling.md](./quantum-classical-handling.md) — taint as the Q/C boundary
- CQ_lang [rationale/proposal-taint-driven-pipeline.md](./rationale/proposal-taint-driven-pipeline.md) — why the prior design was retired
