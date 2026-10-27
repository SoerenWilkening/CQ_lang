# CQ Northstar

CQ is C plus one header, `CQ.h`: `cq_theta` makes a value quantum by rotating it, `cq_measure`
reads it back, `cq_phi` puts a phase on the current branch, and `cq_invert_begin/end` emits a region
as its adjoint. Nothing else marks a value quantum. This repository is the frontend lowering: one
LLVM module pass that takes a whole program's `clang -O1` IR and rewrites everything that depends on
quantum data into calls of the CQ backend ABI. It builds no circuits. A backend links against the
lowered program and builds the circuit while the program runs.

This file holds the goals and the principles, and nothing dated. It wins over every other document
in this repository, every comment and every issue. When something disagrees with it and the
resolution is not obvious, ask the owner.

## The specification

CQ_spec (`CONSTRUCTION_RULES.md`, `CQ.h`, `examples/`, with `BACKEND_ABI.md` as the runtime
contract) is the specification. It is read-only from here and pinned by `spec.lock`; drift fails
loudly. Where CQ_spec leaves a question open, Bennett.jl and BennettVM.jl at the revisions CQ_spec
names are the ground truth. Where an example contradicts the rules, the rules win: the contradiction
goes into `SPEC_ISSUES.md` and the fix lands in CQ_spec, never as a workaround here.

## Goals

**1. No declines. Every C program lowers.**

There is no "unsupported program": no diagnostic path, no decline, no partial output. Where a
program asks for something a circuit can only approximate, the spec already says what happens: a
loop or recursion with a quantum exit runs for its cutoff K, a measurement inside a quantum arm runs
unconditionally, a rail that cannot be cleaned stays allocated, and a function with no body becomes a
declared clone that the link resolves. If the program then computes something its author did not
intend, that is the author's responsibility, never a reason to refuse it.

An IR shape the pass cannot lower yet is an internal compiler error: an assertion or
`report_fatal_error`, a non-zero exit, nothing emitted, a failing test, a bug to fix. That is a state
of the compiler, never a verdict on the program. "Every program lowers" is reached by construction
(principle 2), not by a fallback.

**2. Never emit a circuit that is not the spec's.**

A crash is always better than a plausible wrong circuit. Verify-clean IR and a green suite are not
evidence that the unitary is right. The pass emits only through the general constructions, checks
its own output on every run (principle 4), and correctness is decided by the §6 checker and by
independent review (principles 5 and 6).

**3. 100 % of C.**

First every example of the pinned CQ_spec, then the C standard library as injected source, then any
C program. Version 1 is done when, for the pinned CQ_spec commit:

- every example is §6-equal to its reference (the examples are counted from the directory, never
  quoted as a number);
- the structural verifier is green on every example;
- the C-oracle check is green on every example;
- `SPEC_ISSUES.md` is empty.

**4. The Linux kernel.**

The kernel is the archetype of "every C program"; compiling it shows the method scales to real code.
It is a demonstration, not the correctness test, in three tiers, each a real artefact:

- *Passthrough.* Kernel translation units rebuilt as `-O1` bitcode go through the pass and come
  out byte-identical to what went in, since nothing in them is quantum (the identity is the pass's:
  `llvm-link` and the driver are not measured). This shows the pass never touches classical code.
- *Quantum stress.* Every argument of every function marked quantum (the library-build mode with
  every function a root at the all-ones mask). Every function lowers with no internal error and
  verify-clean IR. Reported as robustness only, never as correctness.
- *Spot-checked correctness.* Sampled kernel functions run through the §6 checker against the
  classical function on basis inputs. Only this tier proves anything about unitaries.

Inline asm with a quantum operand is a declared clone (rule 27). The kernel's arch primitives get C
or circuit replacements in a bundle, the way musl's asm was replaced.

## Principles

**1. Taint is the only quantum/classical boundary.** A value is quantum iff it derives from a
`cq_theta` result by LLVM data flow, through memory, calls and pointers as the rules say. A module
with nothing quantum in it comes out of the pass byte-identical, and a function with nothing quantum
in it is never rewritten, not even to make its loops reducible.

**2. General construction first.** One construction per IR concept, total over its inputs: a path
predicate per block, a `select` chain per merge, a K-trip predicate chain per loop with a quantum
exit, the rule-20 table per memory object, the rule-16/18/19/27 classification per call. The
examples are what these constructions produce. There is no path gated by a pattern matcher and no
ad-hoc lowering. Each construction is argued once against Bennett.jl/BennettVM.jl and witnessed by
the examples its rule names. Where the spec fixes an outcome §6 can see, the construction reproduces
it:

- A purely classical condition stays a real classical branch, also inside a clone. A classical `i1`
  becomes a seed rail only as a term of one mixed `i1`. A branch not taken emits no gates; a flag
  that reads 0 still emits them, so the two are not interchangeable.
- Rule 14's three loop cases keep their own Kept sets. Classical bound: a classical loop, nothing
  kept. Quantum exit: the K-chain, cutoff min(K, B), `a_K` kept iff B > K or no bound is known.
  Classical bound with a quantum break: a classical loop, the chain fully uncomputed, nothing kept.
- Pure nested selects nest. A conjunction flag exists only for a phase or an in-place gate in an
  inner arm.

Irreducible control flow is made reducible (`fix-irreducible`) inside the pass, only in functions
that carry taint, after taint is known.

**3. One module.** `clang -O1` per translation unit, `llvm-link` of the user units with the
injection bundle, then the pass once over the result. x86-64 and `-O1` only.

**4. The pass checks itself on every run.** A structural verifier over the pass's output runs in
every build and fails with `report_fatal_error`. It rejects:

- a `cqrt_free` that does not follow the rail's matching `_unc` and is not of a seed rail;
- a use of a rail after its free;
- an in-place gate on a frozen (rotated) rail;
- an `_unc` whose operands differ from its forward call;
- a quantum value reaching a classical instruction;
- a classical `br`, `select` or `switch` on a tainted value left in the output;
- a measurement the user did not write.

**5. Acceptance is §6, decided by our own checker.** The checker is a classical basis-state
evaluator over the §2 totalization table. It is not a simulator and not a backend; a state-vector
simulation is never correctness evidence. It compares the lowered program against two oracles:

- the reference `lowered.ll`, run in the same evaluator;
- the C program itself: the `.O1.ll` with `cq_theta`/`cq_measure` as the identity, logging which
  `cq_theta`/`cq_phi` call sites each input reaches, which is the §6.2 control predicate point by
  point.

It checks the permutation part (named outputs, kept rails as a multiset, clean rails at 0) and the
rotation list (gate, target, angle or angle rail, predicate per input), up to reordering of gates
with disjoint support and renaming of rails. Rails are matched by kind, width and value over all
samples. Both sides run at K = 4. It covers f80 and fenv. Skipping an example, an input class or a
check is a decline of the test. The checker exists before any lowering, and it has rejected a
mutated reference and an empty output before its first green counts. The same checker is available
to users as `--cq-check`, with their own C program as the oracle.

A textual diff against the reference is reported per example as a quality signal. It never fails a
test, and byte identity is never a gate.

**6. Evidence is review, not green.** Every milestone gets independent adversarial review in two
rounds: wide (two or three reviewers with disjoint hypotheses over the whole change), then narrow
(one reviewer over the fix delta only, repeated until clean). Reviewers reason analytically and run
their own probes, never the implementer's tests.

**7. Progress is measured per rule.** Each construction rule names its witnesses, so progress is the
table rule → witnesses → passing. A rule unimplemented across many examples shows there; the bare
count hides it.

**8. Nothing is inherited from CQ_lang.** No code, runtime, issues or rulings are imported. The
runtime is written against `BACKEND_ABI.md`.
