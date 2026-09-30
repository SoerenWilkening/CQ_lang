# CQ Northstar

CQ is a small extension of C for writing quantum programs. There is no `quantum`
keyword and no special type: a value becomes quantum by passing through a `cq_*`
primitive, and an out-of-tree LLVM 19 pass propagates that **taint** through stock C
arithmetic, control flow and calls, lowering tainted opcodes to reversible runtime
templates. Stock `clang -O1` + one `opt` pass (`cq-lowering`) + the runtime. That is
the whole compiler.

This file is the plan of record. It replaces the phase roadmap. It carries three
goals and ten design principles, and nothing dated. When any other document,
comment, bd memory or old ruling disagrees with it, this file wins. If the
disagreement is not obvious, ask the owner.

## The three goals

**1. A decline is valid only if physics forbids the program. Everything else must compile.**

Physics forbids a program when no unitary circuit (plus explicit measurement) realizes it:

- it requires **cloning** an unknown quantum state (a CNOT fan-out is an entangling
  copy, not cloning, and is not a reason to decline);
- it lets quantum data reach classical code (control, memory, I/O) **without an explicit
  `cq_measure`**. Measurement is the sole sink;
- it needs a quantum-dependent loop or recursion with **no finite bound**. A bound
  the programmer supplies is valid (surface: a `cq_bound(N)` marker in the loop body,
  bd `wrwo`, not built yet); a bound the compiler derives is preferred where it exists;
- it calls code with **no implementation to lift** (an opaque external with no
  visible or injected body).

That list is closed. Extending it is an owner ruling. In particular a **rotation angle
derived from quantum data** (`cq_theta` and `cq_phi`) is valid and must compile. It is
realizable as an angle register driving a bit-controlled rotation ladder, and QPE and
HHL need it. Today it fails loudly, which makes it a gap (bd `94ad`).

A construct the compiler does not lower yet is **not** a valid decline. It is a compiler
bug: it fails loudly, it is filed in bd, and it never counts as a pass. Two things
never bend for this goal:

- The compiler never silently miscompiles. `opt -verify` clean proves the IR is well
  typed, not that the unitary is right. Loud failure beats a wrong circuit.
- The compiler never inserts a measurement the user did not write.

**2. `math.h` coverage.**

A function counts as compiled only when it compiles for **non-trivial input**:

- every combination of classical and quantum arguments: `{cc, cq, qc, qq}` for two
  inputs, all `2^n` for `n` inputs;
- classical operands are **runtime values** (function parameters), not literals. A
  runtime operand covers every literal, while a literal can fold into a different
  construct: `powf` that compiles only at exponents `0.5` and `2.0` lowers to `sqrtf`
  and a multiply, and is **not** covered.

The number is computed by the census tooling, never hand-copied, and is published with
its composition (source-injected, CQ-provided, intrinsic-lowered). A library function
means its real source injected before `cq-lowering`, never recognition by name. The
figures published before 2026-09-30 were scored without the non-trivial-input rule and
are a baseline to re-score, not the current number.

CQ-provided implementations count in their own component, with their numerical
accuracy and range limits published. Retaining an approximation is an owner decision.
Publish both scalar-input C/Q coverage and broader API coverage including classical-only
`nan`/`nanf`/`nanl`; report those three constructors separately as well.

**3. Every known quantum routine can be implemented in CQ.**

The acceptance corpus is the set of textbook and research routines, each written as
plain CQ C, compiled without a decline and pinned by a golden trace and independent
review. Examples, not a cap:

- transforms and phase estimation: QFT, QPE;
- search and amplification: Grover, amplitude amplification, amplitude estimation, quantum counting;
- number-theoretic: Shor (modular exponentiation, order finding);
- oracle algorithms: Deutsch–Jozsa, Bernstein–Vazirani, Simon;
- walks and linear algebra: quantum walks, HHL, block-encoding, LCU, qubitization, QSVT;
- simulation and variational: Hamiltonian simulation (Trotter, qDRIFT), VQE, QAOA;
- protocols and error correction: teleportation, swap test, syndrome extraction with
  measurement feedforward;
- primitives: reversible arithmetic, QRAM, state preparation, oracle construction with uncompute.

A routine the language cannot express is a language gap and gets filed as one.
Correctness is established by golden trace diff plus adversarial review. There is
no simulator (owner decision 2026-06-10).

## Design principles

1. **Taint is the only Q/C boundary.** An SSA value is quantum iff it is derived, by
   stock LLVM data flow, from a `@cq_theta_*` result. Allocation, opcode lowering,
   control, specialization and uncomputation are all driven by that one forward propagation.
2. **The frontend is a header.** `CQ.h` declares `cq_theta` (the sole taint source),
   `cq_measure` (the sole sink), the register-free branch phase `cq_phi(θ)`, and the
   inversion bracket `cq_invert_*`. No rewriter, no AST pass, no custom parser.
3. **Allocation is gate-triggered.** A qubit is allocated at the first `cq_theta` on a
   still-classical value. A variable never rotated produces no qubits.
4. **Uncomputation is compile-time.** Adjoints are emitted at compile time over the
   whole dependence DAG in reverse program order, and a rail is freed at its
   post-dominator only when it is provably `|0⟩`. No runtime tracking.
5. **Function lifting without source modification.** A plain function called with
   tainted arguments gets a specialization synthesized per call site: clone-on-taint
   for visible bodies, injected source for library functions. The library author writes
   one body and quantum and classical callers share it.
6. **No source-level controlled-region brackets.** A tainted `br`/`select`/`switch`
   identifies its quantum-control region structurally. The user writes a plain C `if`.
7. **Adjoints are derived, never authored.** The runtime ships forward templates;
   inverses come mechanically from `EmitInverse`.
8. **Width-only runtime ABI.** Signedness lives in the LLVM opcode and the pass strips
   it. A runtime handle is always `i32`. The template surface is generated from
   `tools/opcode_table.yaml`.
9. **No LLVM fork, no MLIR dialect.** Stock LLVM 19, out-of-tree module plugin.
   Re-evaluating MLIR is an owner decision.
10. **No foot-gun protection.** The language does not stop the user from writing
    nonsense. The only enforced errors are the physics-imposed ones in goal 1.
