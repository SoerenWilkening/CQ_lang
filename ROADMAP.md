# CQ Roadmap

Phase-by-phase trajectory from v1 to a feature-complete quantum-C transpiler. Companion to the per-phase PRDs (v1: [PRD.md](phases/v1/PRD.md)).

---

## Design principles (cross-cutting, apply to all phases)

1. **Frontend first.** Backend functions remain stubs throughout Phases 2–11. Stubs `printf` their name and return default-constructed values. A real backend implementation follows the frontend work as a separate effort.
2. **Compile-time uncomputation.** Adjoints are emitted by the transpiler at compile time, op-by-op, using per-variable provenance (use-def chains). No runtime tracking, no Bennett-style wrap-the-whole-call. Every primitive ships with its adjoint defined.
3. **Type-dispatched semantics.** Classical-typed expressions stay classical; quantum-typed expressions trigger quantum codegen. The condition of an `if`, the operand of an op, etc. determine which path is taken.
4. **Four forms per primitive op.** Each primitive operation ships: forward, adjoint, controlled, controlled-adjoint. This is a hard structural requirement because `if` (Phase 4) needs controlled forms and uncomputation (Phase 5) needs adjoints.
5. **C philosophy: no foot-gun protection.** The language does not prevent the user from writing nonsense. The only enforced errors are physics-imposed (no-cloning) or unavoidable (non-adjointable use-site when uncomputation is required).
6. **No-cloning is physics, not policy.** `quantum int a = b;` cannot actually clone; it emits CNOT-based XOR-copy (which entangles). User is expected to understand this; document it, do not guard-rail it.
7. **Measurement happens at cast.** `(int) q` is the only way to extract a classical value from a quantum variable.
8. **Frontend/backend header separation.** `CQ.h` is the single user-facing entry point — intentionally lightweight, parse-only. It does *not* include backend headers (`qint.h` and successors); those are emitted into the *transpiled output* by the transpiler. The user never includes a backend header; the backend never sees CQ source. As features land, `CQ.h` gains markers but never backend types.

---

## Phase 1 — v1 (DONE)

Basic qint, single addition operation.

- `quantum int x;` declarations
- Initialization from literal, classical variable, or quantum + quantum
- `quantum int x = a + b;` and `quantum int x = a + E;` (mixed quantum/classical)
- Multi-variable declarations
- Auto `#include "qint.h"` insertion
- End-to-end fixtures 04–08

Backend: stubs for `init_qint` and `add`.

See [PRD.md](phases/v1/PRD.md) for full v1 spec.

---

## Phase 2 — Complete type system and `CQ.h` entry-point header

Extend qint to all integer widths; introduce qfloat/qdouble as stub structs; introduce `CQ.h` as the single user-facing entry point.

**Scope (type system):**
- Integer widths: `quantum char`, `quantum short`, `quantum int`, `quantum long`, `quantum long long`, both signed and unsigned
- `quantum float`, `quantum double`: stub structs only; internal representation deferred (decision between fixed-point / QFT-based / IEEE-mimic happens when backend lands)
- Assignment semantics: `quantum T a = b;` emits XOR-copy (CNOT-based)
- Measurement at cast: `(int) q`, `(float) q`, etc. lowered to a `measure` call

**Scope (entry-point header `CQ.h`):**
- User writes `#include <CQ.h>` (or `"CQ.h"`) at the top of their CQ source. The manual `#define quantum ...` of v1 goes away.
- `CQ.h` is intentionally lightweight: it provides only what's needed for the user's input to parse. It does NOT include `qint.h` or any other backend header — backend headers are wired into the *transpiled output* by the transpiler (same mechanism v1 already uses to insert `#include "qint.h"`).
- `CQ.h` exposes:
  - `quantum` attribute (was: user-written `#define`)
  - `theta(angle)` — R_y rotation marker (renamed from v1's `amplitude`)
  - `phi(angle)` — R_z rotation marker (renamed from v1's `phase`)
  - `invert(...)` — adjoint invocation marker. Full rewrite semantics land in Phase 7. Surface form is TBD — leaning keyword, possibly function-call shape; decision deferred.
- `amplitude` and `phase` are removed; no compatibility shim (no external users yet — clean break).
- v1 fixtures under `phases/v1/` remain frozen with their original `#define quantum ...` style. New Phase 2 fixtures use `#include <CQ.h>`.

**Out of scope:**
- Any arithmetic on qfloat/qdouble beyond what's already in v1 for qint
- Float representation decision
- Full `invert(...)` rewrite semantics (Phase 7)

**Stub backend additions** (emitted into transpiled output, NOT in `CQ.h`):
- `qfloat_t`, `qdouble_t` structs
- `init_qfloat`, `init_qdouble` (stubs)
- `measure_*` (stub family)

---

## Phase 3 — Full operation set

Every primitive operation, in both qq and qc forms, with all four shapes (forward / adjoint / controlled / controlled-adjoint).

**Operations:**
- Arithmetic: `+`, `-`, `*`, `/`, `%`, plus compound `+=`, `-=`, `*=`, `/=`, `%=`
- Bitwise: `<<`, `>>`, `|`, `&`, `^`, plus compound `<<=`, `>>=`, `|=`, `&=`, `^=`
- Structural: copy (XOR-copy via CNOT), swap

**Operand variants per op:**
- `op_qq` — both operands quantum
- `op_qc` — one quantum, one classical constant (different efficient circuit)

**Per-op deliverables (stubs):**
- Forward, adjoint, controlled, controlled-adjoint declared in `qint.h` family
- Stubs `printf` their name

**Sub-items:**
- **3.1 In-place semantics.** Out-of-place primitives that the language exposes as in-place are reconciled either by appended swap-back or by Fredkin substitution. Transpiler picks one strategy per op; later optimization may swap.
- **3.2 Modular-arithmetic peephole.** Compiler flag enabling pattern `(a + b) % N → add_mod(a, b, N)` and the analogous mul/exp forms. Flag default: off.

---

## Phase 4 — Quantum control flow: `if`

Type-dispatched on the condition expression.

**Classical condition.** Emit normal C `if`. No quantum machinery.

**Quantum condition (or mixed: any quantum subexpression → whole condition is quantum):**
1. Compute condition into a fresh flag ancilla via the appropriate comparator circuit (stub)
2. Body ops are emitted in their *controlled* form, controlled on the flag
3. At block exit, uncompute the flag (its provenance is known; same model as Phase 5)

**Nested ifs.** At each new nesting level, AND the new flag with the current effective control into a fresh ancilla; body ops control on that single AND-ancilla. On block exit: uncompute the AND-ancilla, then uncompute the local flag. Rationale: body ops are always singly-controlled at runtime; no multi-control decomposition needed at backend.

**Constraint:** every operation reachable inside an `if` body must have a controlled form (Phase 3 requirement).

---

## Phase 5 — Auto uncomputation

Compile-time, per-op adjoint emission for temps going out of scope.

**Mechanism:**
- Transpiler tracks per-qint provenance (use-def chains)
- At scope exit for any temp that is no longer used, emit the recorded forward op-sequence in reverse, each op replaced by its adjoint
- Operands match the original forward call exactly

**Function attributes (derived, not declared):**
- `is_adjointable` — every op in the function body has a defined adjoint
- `is_controllable` — every op in the function body has a defined controlled form
- External functions default to `false` for both; user may supply manual adjoint

**Errors:** any use-site that requires uncomputation of a non-adjointable result → compile error. The transpiler does not enumerate "what it can't invert" — it fires the error at the use-site, O(1) per call-site check.

---

## Phase 6 — For-loops (classical bounds)

Quantum data may appear in the loop body; loop variable and bounds are classical.

- **Compile-time constant bound:** unroll in the emitted source
- **Non-const classical bound:** emit a host-side loop in the generated code that constructs the circuit at startup time. The runtime circuit is still flat
- **Runtime-dynamic bound (measurement-derived):** deferred to dynamic-circuits work, out of scope for this phase

---

## Phase 7 — Function inversion

Structural adjoint derivation for user-defined functions (Q#-style).

- For a function composed of adjointable primitive ops, derive its adjoint by reversing the op-sequence and adjointing each op
- Relies on Phase 5 `is_adjointable` propagation through the call graph
- External / foreign calls require user-supplied adjoint to participate
- Surface syntax for invoking adjoint of a function: TBD (likely `adjoint foo(...)` or `foo.adj(...)`)

---

## Phase 8 — Memory: arrays and pointers

- **Classical-indexed quantum arrays:** straightforward register addressing
- **Quantum-indexed access** (`arr[q]` where `q` is quantum): triggers QRAM call. QRAM functionality itself is a backend stub in this phase
- **Pointer semantics for quantum data:** TBD — aliasing rules, lifetime, address-of behavior
- **Array-of-quantum vs quantum-of-array:** clarify which constructions are supported

---

## Phase 9 — Remaining C language surface

- `struct` (including with quantum fields)
- `union`, `typedef`, `enum`
- Storage classes, qualifiers
- Other C99/C11 features as they become relevant

Most of these need only mechanical AST handling; no new quantum semantics introduced.

---

## Phase 10 — Quantum-conditioned while loops (deferred design)

Likely transform-to-for or amplitude-amplification semantics. Design pinned down when we get here. Out of scope until prior phases are complete.

---

## Phase 11 — Compiler optimization passes

Optimizations on the emitted circuit / IR. Frontend-only; presumes the prior phases produce a faithful but unoptimized output.

- Gate cancellation (X·X = I, CNOT·CNOT = I, adjacent inverse pairs)
- Adjacent-gate fusion
- Peephole patterns (generalization of Phase 3.2)
- Constant folding for classical-known values feeding quantum ops
- Ancilla reuse across non-overlapping lifetimes (qubit-count reduction)
- Dead code elimination
- T-count / depth-targeted passes (research-y, later)

---

## Sequencing notes

- Phases 2 → 5 are tightly coupled and form the "make CQ look like real C with quantum types" core. They should land in order; each builds on the previous.
- Phase 4 (`if`) depends on Phase 3 controlled forms; Phase 5 (uncomputation) depends on Phase 3 adjoints. Both can be developed in parallel once Phase 3 lands.
- Phase 7 (function inversion) depends on Phase 5 attribute machinery.
- Phase 8 (memory) is largely independent of Phases 4–7 and could be parallelized, but it introduces QRAM which is a fresh stub area.
- Phase 11 (optimization) only makes sense once enough primitives exist to optimize over.
