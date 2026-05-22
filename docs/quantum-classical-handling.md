# Quantum-Classical Handling: Sturm/Bennett vs CQ_lang

How each compiler delineates quantum and classical code, and at what
granularity reversibilization happens. Captured 2026-05-21 as a companion
to [`bennett-jl-comparison.md`](./bennett-jl-comparison.md) (broader design
comparison) and [`architecture.md`](./architecture.md) (the canonical
CQ_lang design).

---

## The distinction in one sentence

**Sturm/Bennett separates quantum and classical at the *source level* via
different primitives. CQ_lang separates them at the *LLVM IR instruction
level* via taint propagation on stock opcodes.**

---

## Sturm/Bennett: layered separation

Sturm.jl exposes two kinds of primitives to the user:

1. **Native quantum primitives** — `q.θ += δ`, `q.φ += δ`,
   `Bool(q) / Int(q)`, `when(q) do … end`. These are handled by Sturm
   directly: at execution time, they record gates into a
   `TracingContext`. Bennett is not involved.

2. **Classical functions lifted via `oracle(f, q)`** — when the user
   wants to call a classical `f` with a quantum argument, they wrap the
   call in `oracle`. Sturm's macro layer compiles `f` to LLVM IR, hands
   that IR to Bennett, and Bennett produces a reversible circuit using
   its 38-opcode mapping plus the forward + copy + reverse construction.
   The result is plugged into the surrounding Sturm program.

**Key property: Bennett's input is purely classical LLVM IR.** It never
sees `q.θ += δ` or `when(q)` constructs — by contract, anything Bennett
receives is a closed classical function meant to be reversibilized
*entirely*.

Bennett therefore does not need to disambiguate "is this op quantum or
classical?" within the function — *everything* is reversibilized. The
quantum/classical distinction is made BEFORE Bennett is invoked, by
Sturm's source-level separation of primitives.

```
[User Julia source]
   │
   ├── Sturm primitive (q.θ += δ, when, ...)
   │     │
   │     ▼
   │   [Sturm's TracingContext]
   │     │
   │     ▼
   │   [Gate recorded at execution time]
   │
   └── oracle(f, q) call
         │
         ▼
       [Sturm compiles f to LLVM IR; hands to Bennett]
         │
         ▼
       [Bennett applies whole-call construction]
         • forward: every op in f reversibilized
         • copy result to caller-provided output
         • reverse: undo forward, restore ancillas
         │
         ▼
       [Reversible circuit (NOT, CNOT, Toffoli, rotations)]
```

---

## CQ_lang: unified pipeline with taint propagation

CQ_lang exposes the user a single uniform language (C with the
`quantum` keyword). There are no separate "quantum" and "classical"
surface forms — the same C operators (`+`, `*`, `if`, function calls)
apply to both quantum and classical types.

The disambiguation happens **at the LLVM IR layer**, by the IR pass
(`architecture.md` §7.1):

1. **Taint sources** — `@cq_init` calls and `qint_mid_t`-typed function
   parameters are the seeds.
2. **Taint propagation** — any LLVM instruction whose operand is tainted
   produces a tainted result.
3. **Per-op classification** — every instruction in the IR is then
   either quantum (tainted) or classical (untainted).

The IR pass handles quantum ops via per-op compile-time adjoints
(`architecture.md` §7.4 + §7.6); classical ops are untouched.

```
[User C source with quantum keyword]
   │
   ▼
[Rewriter: emits qint_mid_t struct + cq_init calls]
   │
   ▼
[Clang: lowers to LLVM IR with stock opcodes + cq_* intrinsic calls]
   │
   ▼
[CQ IR pass — the BACK-END per architecture.md §7]
   • Forward taint propagation from @cq_init / fn params
   • Per-op classification on every LLVM instruction
   • Quantum ops → reversibilized via per-op templates
   • Adjoints emitted at SSA last-use sites
   • Classical ops → left alone
   │
   ▼
[LLVM IR with cqrt_* runtime gate calls]
```

**Key property: the IR pass sees mixed quantum-classical IR and
disambiguates per instruction.** Where Sturm/Bennett pre-separates
contracts at the source level, CQ_lang reasons at finer granularity at
the IR level.

---

## CQ_lang's hybrid: per-op inside, Bennett-wrap at function boundary

CQ_lang does NOT use per-op as a *universal* strategy. For
auto-specialization synthesis of external classical functions
(`architecture.md` §7.7), the IR pass:

1. Fetches `f`'s LLVM IR
2. Marks parameters corresponding to the q-arg-mask as tainted
3. Runs taint propagation on `f`'s body
4. Applies per-op lowering to tainted instructions
5. **Wraps the whole result in Bennett's construction** at the function
   boundary: forward + CNOT-copy of return + reverse

So for specialization synthesis we use:
- **Per-op adjoints inside the body** — CQ-style efficiency
- **Bennett's whole-call wrap at the boundary** — Sturm-style closure on
  opaque external code

```
__cq_q_<f>_<mask>:
  ┌── Bennett wrap (forward + copy + reverse) at fn boundary ──┐
  │                                                             │
  │  inside: taint propagation + per-op compile-time adjoints   │
  │          on tainted instructions; classical instructions    │
  │          untouched                                          │
  │                                                             │
  └─────────────────────────────────────────────────────────────┘
```

This hybrid is deliberate: per-op buys efficiency for the inside of the
function (only tainted ops are reversibilized; adjacent-inverse
cancellation visible); Bennett's wrap buys correctness at the function
boundary where the caller is opaque to us.

---

## Summary table

| Aspect | Sturm/Bennett | CQ_lang |
|---|---|---|
| Quantum-classical disambiguation happens at | Source level (different primitives) | LLVM IR level (taint propagation) |
| Granularity of reversibilization | Whole function | Per instruction |
| Does Bennett ever see mixed quantum-classical IR? | No — only purely classical | N/A (CQ_lang has its own IR pass; Bennett-style wrap used only at fn boundary in §7.7) |
| Adjacent-inverse cancellation | Blocked at function boundaries | Possible across instructions |
| Ancilla reuse | Per-function | Per-instruction (where SSA def-use permits) |
| Over-reversibilization | Yes (all ops in oracle'd fn get the treatment, even if their results never enter quantum land) | No (only tainted instructions are reversibilized) |
| Depth penalty for whole-function call | 3× (forward + copy + reverse) | Per-op: minimal; per-call (§7.7): 3× at boundary, optimal inside |
| Used for opaque external classical functions | Yes (default mechanism) | Yes (via §7.7 specialization synthesis — Bennett-wrap at boundary, per-op inside) |
| Compile-time analysis cost | Lower (whole-function transform) | Higher (taint propagation + SSA def-use + per-op template lookup) |

---

## The cascade-from-one-keyword property: syntax vs semantics

CQ_lang has an elegant property where a single `quantum` keyword
propagates through call sites and triggers cascading auto-specialization:

```c
quantum int q = 5;                       /* single quantum keyword */
int answer = pow(q, 2);                  /* pow auto-specialized */
int x = some_helper(answer);             /* also auto-specialized */
quantum int final = combine(answer, q);  /* and this too */
```

Taint propagates instruction-by-instruction through the SSA graph; every
called function reachable in the call graph gets auto-specialized by the
IR pass.

**Important nuance**: this *syntactic* elegance could in principle be
matched under a Bennett-style design via compiler auto-insertion. A
Bennett-style compiler could detect "function called with quantum arg
→ wrap in Bennett construction automatically," removing the need for
explicit `oracle()` calls. So the syntactic experience (single keyword,
implicit cascade through call sites) is matchable.

**What is NOT matchable** is the *semantic* quality. Under Bennett-style,
even with `oracle()` auto-insertion:

- Every reversibilized function pays 3× depth (forward + copy + reverse
  wrap)
- Internal classical subroutines all get reversibilized regardless of
  whether their results carry quantum-ness
- Cross-function optimization is blocked at every boundary
- Ancilla reuse stops at each function

Under CQ_lang's per-op approach:

- Only tainted instructions get reversibilized — classical subroutines
  stay classical
- Depth is minimal (no forward + reverse wrap)
- Optimization sees through the whole call (specializations are
  inlinable)
- Ancilla reuse is possible across instruction boundaries

**The cascade-from-one-keyword property is downstream of the granularity
choice, not a separate advantage.** Both flow from the same underlying
mechanism (taint propagation on SSA). If forced to identify which is the
more important architectural win, it is the granularity, not the syntax.
A Bennett-style design that auto-inserts `oracle()` could match CQ_lang's
syntactic experience but not its circuit quality.

---

## Why this matters for architectural decisions

The two approaches make different cost/quality trade-offs:

- **Sturm/Bennett favors simplicity of the compiler** at the cost of
  circuit quality (3× depth on every Bennett-wrapped function;
  blocked optimization across function boundaries).
- **CQ_lang favors circuit quality** at the cost of compiler complexity
  (taint propagation, per-op template library, SSA last-use analysis).

CQ_lang's hybrid in §7.7 captures the best of both: use per-op where
the IR is ours to reason about; fall back to Bennett-wrap where the
function is opaque (and per-op isn't possible anyway).

The trade-off is genuine and not all on one side. Sturm/Bennett's
approach is well-trodden, less error-prone, and works on any
LLVM-emittable language. CQ_lang's approach is more ambitious and
yields better circuits where it applies.

---

## References

- [`architecture.md`](./architecture.md) §7.1 (taint propagation), §7.4
  (per-op uncomputation), §7.6 (inverse generation), §7.7 (specialization
  synthesis with Bennett wrap)
- [`bennett-jl-comparison.md`](./bennett-jl-comparison.md) — broader
  design comparison including ROADMAP principle 2's explicit rejection of
  whole-call Bennett as the primary mechanism
- [`example.md`](./example.md) — worked example illustrating CQ_lang's
  Stage-1-through-Stage-4 pipeline (the frontend's deliverable; backend
  reversibilization is below scope of that doc)
