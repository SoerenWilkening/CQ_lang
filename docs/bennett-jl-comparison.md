# CQ_lang vs Sturm.jl / Bennett.jl / Orkan — Rigorous Comparison

Comparison of CQ_lang's architecture with the three-layer Julia stack
maintained by Tobias Osborne (CQ_lang's advisor):

- **Sturm.jl** (https://github.com/tobiasosborne/Sturm.jl) — the quantum DSL
- **Bennett.jl** (https://github.com/tobiasosborne/Bennett.jl) — classical-to-reversible compiler
- **Orkan** (C17) — statevector / density-matrix simulator backend

Sources consulted: Sturm.jl README; Bennett.jl README, `docs/src/index.md`,
`docs/src/architecture.md` (fetched 2026-05-21).

> **Revision note.** An earlier draft of this document compared CQ_lang to
> Bennett.jl alone and concluded Bennett had "no rotations, no measurement,
> no quantum control." That framing was wrong — the **quantum-language layer
> is Sturm.jl**, which sits on top of Bennett and provides exactly those
> primitives. This document supersedes that comparison. Bennett's
> `when(qubit) do f(x) end` is the integration hook that Sturm composes
> against (documented as the integration motivation; current implementation
> status in Bennett v1.0 vision).

---

## TL;DR

**The right comparison is CQ_lang vs Sturm+Bennett+Orkan**, not CQ_lang vs
Bennett alone. Both projects are quantum-programming languages with
explicit quantum types, rotations, measurement-at-cast, and a bridge for
lifting classical functions into reversible circuits.

CQ_lang and Sturm independently landed on most of the same surface design.
The two real differences are:

1. **Quantum control**: Sturm makes `when(q)` a distinct construct from
   `if`; CQ_lang's ROADMAP currently dispatches `if` on the condition's
   type. Sturm has principled arguments against the type-dispatch route
   (compositional semantics under function lifting). Worth re-examining.
2. **Uncomputation**: Sturm/Bennett wraps any lifted call with Bennett's
   1973 construction (forward + CNOT-copy + reverse). CQ_lang's ROADMAP
   uses per-op compile-time adjoints. These cover different cases — they
   are complementary, not competing.

The earlier "reversible_oracle" sidecar recommendation stands, and now has
a direct counterpart in the reference stack: it's exactly what Sturm's
`oracle(f, q)` does. The hybrid (AST front-end + LLVM-IR-style lowering for
opaque classical calls) is not optional flavor — it's how the reference
design ships.

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

| Axis | **CQ_lang** | **Sturm.jl** |
|---|---|---|
| Surface language | C with `__attribute__((annotate("quantum")))` | Plain Julia |
| Front-end | Clang libtooling, AST matchers + Rewriter | Julia compiler + macros + dispatch |
| Quantum type | `quantum int`, `qint_t` (post-transpile struct) | `QInt{W}`, `QBool` |
| Amplitude rotation | `theta(angle)` → R_y (Phase 2) | `q.θ += δ` → Ry |
| Phase rotation | `phi(angle)` → R_z (Phase 2) | `q.φ += δ` → Rz |
| Measurement | `(int) q` — cast (Phase 2) | `Bool(q)`, `Int(q)` — cast |
| Adjoint marker | `invert(...)` (Phase 2/7) | implicit (Bennett wraps) |
| Quantum control | `if (q_cond) { ... }` — type-dispatched (Phase 4) | `when(q) do ... end` — distinct construct |
| Classical control | same `if`, classical condition path | `if Bool(q) ... end` (post-measurement) |
| Classical → quantum function bridge | proposed: `__attribute__((reversible_oracle))` (Phase 7.x) | `oracle(f, q)` |
| Uncomputation | Per-op compile-time adjoints, use-def chains (ROADMAP §2, Phase 5) | Whole-call Bennett 1973 (forward + CNOT-copy + reverse) |
| Per-op contract | forward / adjoint / controlled / controlled-adjoint (Phase 3) | No equivalent — Bennett derives everything |
| Per-bit attribution | `qint_t.mask` distinguishes qubit vs classical bits (Roadmap principle 9) | None — `QInt{W}` is uniformly quantum |
| Target gate set | Universal Q gates (aspirational; stubbed in v1) | {NOT, CNOT, Toffoli} from Bennett; rotations from Sturm primitives |
| Simulator backend | TBD (stubs print only) | Orkan (statevector / density-matrix) |
| Circuit export | TBD | OpenQASM via TracingContext |
| Multi-language input | C only | Anything → LLVM IR → Bennett |

---

## Design convergences (independent validation)

Sturm and CQ_lang were designed independently and converge on a striking
number of choices:

| Concept | Both projects |
|---|---|
| Explicit quantum type | yes (`QInt{W}` ↔ `quantum int`) |
| Measurement is a type cast (not a function) | yes |
| Two rotation primitives (R_y, R_z) | yes |
| Distinct quantum and classical control constructs | yes (different syntax choices, same idea) |
| Classical functions lifted via dedicated bridge | yes (`oracle(f, q)` ↔ proposed `reversible_oracle`) |
| No named gates in user code | yes (planned for CQ_lang) |
| Symmetric primitive contract (`when(a) do not!(b) end` = CNOT) | yes (Sturm shipping; CQ_lang Phase 3 controlled forms) |
| Functions as channels / first-class composition | yes (Sturm P1; CQ_lang Phase 7) |
| User writes domain logic, system handles QM | yes |

This is not coincidence — it's two competent teams hitting the same fixed
point in the design space. The convergence is a signal that CQ_lang's
ROADMAP is in good territory.

---

## Design divergences (where you should think twice)

### 1. `when` vs `if` — distinct construct vs type-dispatched

Sturm makes a deliberate, principled choice for a **separate keyword**:

```julia
when(q) do; target.θ += π; end    # coherent: q and target stay entangled
if Bool(q); target.θ += π; end    # collapse: q measured first
```

Their P4 rationale (paraphrasing the Sturm README):

> Two distinct channels — one syntax would lie about the type contract.
> Breaks composition with `oracle(f, q)` — the same `if` inside `f` means
> three different things depending on call context.

CQ_lang's ROADMAP Phase 4 currently goes the type-dispatch route: same
`if` keyword, dispatch on whether the condition expression is quantum or
classical. **Sturm's second argument is non-trivial for our Phase 7.**
When a function `foo` contains `if x { ... }`, and the function is later
called either classically, with a quantum argument, or inside a controlled
body — the semantics of that `if` shift. With one keyword, the same source
line means three different things depending on call site. With `when`/`if`
distinguished, each call site is unambiguous.

This deserves an explicit yes/no in the ROADMAP, not implicit dismissal.
It is reasonable to keep type-dispatched `if` (C-as-host pushes hard
against introducing `when` as a new keyword) — but the trade-off should
be acknowledged.

### 2. Whole-call Bennett vs per-op compile-time adjoint

ROADMAP principle 2 explicitly rejects whole-call Bennett:

> Compile-time uncomputation. Adjoints are emitted by the transpiler at
> compile time, op-by-op, using per-variable provenance. No runtime
> tracking, no Bennett-style wrap-the-whole-call.

Sturm/Bennett does exactly what we reject — every `oracle(f, q)` call is
forward + copy + reverse. The trade-off:

| Aspect | Per-op adjoint (CQ_lang) | Whole-call Bennett (Sturm) |
|---|---|---|
| Depth for inlined primitive sequence | minimal | 3× (always) |
| Ancilla reuse across primitives | possible (compiler can analyze) | not directly (each call is sealed) |
| Adjacent-inverse cancellation | natural | invisible (across a call boundary) |
| Adjointability contract | every primitive ships adjoint | no per-primitive contract needed |
| Works on opaque foreign code | no (need adjoint) | yes (Bennett derives reversibility) |
| Compiler complexity | higher | lower |

**These aren't competing — they cover different cases.** For primitive
ops and user-defined functions composed of primitives, per-op is more
efficient. For opaque classical functions (oracles, third-party libraries,
non-Julia / non-C code via `.ll`), per-op is impossible and Bennett is the
only path.

CQ_lang should ship both: per-op for the quantum-aware primitive path,
Bennett-style lifting for opaque classical functions (the
`reversible_oracle` slot — exactly Sturm's `oracle(f, q)`).

---

## The `qint_t`-as-struct observation

A nuance from the live discussion that the original draft glossed:

The "LLVM IR loses your types" concern is **overstated for post-transpile
code**. Once the AST rewriter has emitted:

```c
qint_t c = add(a, b);
```

Clang lowers that to LLVM IR with a typed call:

```llvm
%struct.qint_t = type { i32*, i32, i64, i64, i8 }
%c = call %struct.qint_t @add(%struct.qint_t %a, %struct.qint_t %b)
```

`%struct.qint_t` is a distinct nominal type at IR level. An LLVM pass can
pattern-match on it cleanly. The type distinction survives.

This matters because:

- The AST → C rewrite step is not load-bearing for *type preservation* —
  the struct itself does the preservation.
- An LLVM IR pass that recognizes `@add(qint_t, qint_t)` and emits gates
  is feasible without modifying the front-end.
- Phase 11 (optimization) naturally lives at this layer.

What still degrades through LLVM IR is **block structure** (Phase 4 `if`),
**per-bit mask attribution** (Roadmap principle 9), and **source-fidelity
diagnostics** (Phase 5). Those concerns drive the recommendation to keep
quantum-aware passes at the AST layer.

---

## Recommended adoption pattern

Restated (and now seen as paralleling Sturm's `oracle(f, q)`):

1. **AST front-end stays as primary.** Clang libtooling recognizes
   quantum types, controlled blocks, rotations, measurement. All
   quantum-aware passes operate on AST.
2. **`reversible_oracle` attribute** (or similar — name TBD) marks pure
   classical-deterministic C functions. The transpiler does NOT rewrite
   their bodies. Their bodies are compiled to LLVM IR and lowered to
   reversible gates via a Bennett-style 38-opcode mapper. This is the
   counterpart of Sturm's `oracle(f, q)`.
3. **Per-op compile-time adjoint** stays the primary uncomputation strategy
   for the quantum-aware path. Whole-call Bennett wraps the oracle calls
   only.
4. **The middle-IR slot on the board sketch** can be filled with a
   `qint_t`-typed LLVM IR pass for back-end optimization (Phase 11) and
   gate emission. The `qint_t` struct preserves enough type info that
   this works without quantum-aware metadata.

### Why this matches the board sketch

The whiteboard pipeline (`AST → middle IR → AST → emitter → gate set →
more transpile → hardware gate library`) maps directly:

- **AST** (entry): Clang libtooling front-end, quantum-aware passes.
- **Middle IR**: LLVM IR with `qint_t` struct types, classical-style
  optimization passes (mem2reg, sroa, instcombine) on the classical
  portions; oracle bodies lowered here via Bennett-style mapper.
- **AST** (exit): re-projection for quantum-aware emitter passes.
- **Emitter**: produces s-expression-style gate IR.
- **Gate set**: universal Q gates (rotations + Toffoli + CNOT + NOT).
- **More transpile**: targets concrete hardware gate library (Orkan-like
  layer for us, or a real hardware library).

---

## Alternatives considered

| Alternative | Why not (for now) |
|---|---|
| **LLVM IR as the *primary* IR.** | Loses block structure (Phase 4), per-bit `mask` attribution (principle 9), source-fidelity diagnostics. Quantum-aware passes are strictly easier at AST. The middle-IR LLVM slot is fine; replacing the AST entry is not. |
| **MLIR with a custom quantum dialect.** | Long-term plausible. Today: nothing in CQ_lang depends on it; cost of adoption is non-trivial. Revisit when Phase 11 optimization work matures. |
| **Adopt Sturm wholesale (Julia front-end).** | Gives up C as the source language. Non-starter for "Quantum C". |
| **Subprocess Bennett.jl from CQ_lang.** | Operationally awkward (Julia runtime in a C/C++ toolchain). The 38-opcode mapper is small enough to reimplement in C++ alongside libtooling — and that decouples our release cadence from Bennett.jl's. |
| **Drop CQ_lang in favor of Sturm.** | Misses the audience CQ_lang is for: C-ecosystem users, embedded / systems folks, anyone whose existing code is C. Sturm targets the Julia community. |

---

## Open questions

1. **Type-dispatched `if` vs distinct `when` keyword.** Document the decision
   in ROADMAP Phase 4 with an explicit nod to Sturm's argument.
2. **Spelling of the oracle attribute.** `reversible_oracle`,
   `pure_classical`, or repurpose `invert` when applied to a classical
   function?
3. **Bennett-mapper implementation**: subprocess Bennett.jl, reimplement in
   C++, or write our own from scratch? Reimplementation gets us release
   independence; reuse gets us Bennett's evolving QCLA / Karatsuba work.
4. **ROADMAP placement.** Natural fit: a Phase 7.x sub-item under
   user-defined functions. Phase 8 (memory) then has access to Bennett's
   QROM / Shadow strategies for classical-memory portions of oracles.
5. **First demonstrable oracle.** SHA-256 round? Modular exponentiation?
   Feistel block? These are the natural test cases — and per the Sturm
   README, Bennett reportedly compiles all three.

---

## References

- Sturm.jl — https://github.com/tobiasosborne/Sturm.jl (README, README §P1–P9)
- Bennett.jl — https://github.com/tobiasosborne/Bennett.jl (README, docs/src/index.md, docs/src/architecture.md)
- C. H. Bennett, "Logical reversibility of computation" (1973)
- Enzyme — LLVM-level AD; the architectural prior Bennett cites
- CQ_lang [ROADMAP.md](../ROADMAP.md) — phases 1–11, design principles
- CQ_lang [pipeline-sketch.md](./pipeline-sketch.md) — whiteboard transcription
