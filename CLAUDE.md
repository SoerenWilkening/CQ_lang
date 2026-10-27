# CQ_lang2: operating manual

Read [`NORTHSTAR.md`](NORTHSTAR.md) first. It holds the goals and principles and wins over this file.
This file is how to work.

## Pins

- **Spec.** CQ_spec at `../CQ_spec`, read-only. `spec.lock` pins its commit and a sha256 of every
  file under `examples/` plus `CONSTRUCTION_RULES.md`, `CQ.h`, `BACKEND_ABI.md` and
  `_tools/drivers.txt`. Run `python3 tools/spec_lock.py` before any test run; drift exits 1. Re-pin
  with `--write` only on a deliberate spec bump, in a commit of its own. `BACKEND_ABI.md` is
  non-normative (CR wins over it) and `drivers.txt` is input data: a drift in either is a re-pin,
  not a spec issue.
- **Toolchain.** LLVM 19.1.7 from brew `llvm@19`: `/usr/local/opt/llvm@19/bin` (`clang`, `opt`,
  `llvm-link`, `llvm-as`, `llvm-config`). Never Apple clang. Triple `x86_64-apple-macosx`, `-O1`.
  C++17 for the pass.
- **Ground truth beyond the spec.** Bennett.jl `824458d10e879c3fef673c231a02e5461dac667f` and
  BennettVM.jl `23d28e6471f9cf5d8a22177d08260ca86adfe841`, the revisions CQ_spec names. Consult
  them at those revisions only, cite `path:function`, never vendor or link them.

## Reading the spec

- `CONSTRUCTION_RULES.md` (CR) is normative. `examples/NN_name/{name.c, name.O1.ll,
  name.lowered.ll}` are its witnesses. CR wins over an example; a contradiction goes to
  `SPEC_ISSUES.md` and a bead.
- `BACKEND_ABI.md` is the contract our evaluator runtime implements. `CQ.h` is the user surface.
- Comments and headers in lowered files explain; they add no requirements.
- `_tools/` is spec-authoring tooling. `_tools/drivers.txt` is input data (signatures, calls, the
  setup snippets) and is read. CQ_spec's checkers are never run as evidence. Nothing is ever written
  into CQ_spec.

## Pipeline

`clang -O1` per translation unit with `CQ.h` → `llvm-link` with the injection bundle → the pass
(`opt -load-pass-plugin=… -passes=cq-lower`: taint, then `fix-irreducible` on the tainted functions
only, then taint afresh if any function changed, then the constructions; taint is computed once over
the final CFG and nothing mutates the CFG after it) → the structural verifier (inside the pass) → the
lowered module. A function with no taint is never rewritten; a module with no taint is the pass's
identity (principle 1, kernel tier 1). The pass is the identity when `opt -passes=cq-lower` and `opt`
with no passes produce byte-identical output on the same input. The `cqcc` driver runs this chain. The corpus feeds each
`name.O1.ll` straight in; `clang-19 -O1` reproduces those files apart from comments and
`source_filename`.

K per loop, first match wins: the per-function flag (`fmod=2046,sin=53`), a `CQ_K(f, k)` line
(the `used` constant `__cq_k_<f>`), the global flag, the built-in default 4. Per-loop annotation is
deferred until CQ_spec defines its syntax.

The version 1 injection bundle is what the corpus lifts: compiler-rt's
`__{mul,div}{s,d,x}c3` (69, 169–174, 181, 182) and musl `memcmp` and friends (190). Everything else
with no body goes through rule 27 declared clones. Build the bundle with the corpus triple.

## Internal errors, never declines

- An unhandled shape is `report_fatal_error("cq: unimplemented: …")` with the offending
  instruction printed, a bead, and a fix. Nothing is emitted.
- Never write an "unsupported" diagnostic, an `isSupported()` predicate, a skip list, or a fallback
  that emits something the constructions did not produce.
- Never make a test pass by narrowing it: no skipped example, input class or check.

## The §6 checker

Built first (step 0 below). Requirements:

- **Evaluator.** A classical runtime implementing every `cqrt_*` and `cq_template_*` on basis
  values per BACKEND_ABI.md and the CR §2 table. Any width N. f80 through host `long double` (x87),
  fenv through the host FPU (`fesetround`, `fetestexcept`). Ry and phases are logged, not applied.
  Every `_unc` must leave 0, and every `cqrt_free` must see a rail in a known classical basis state
  (CR §0): the evaluator tracks known-basis-ness per rail (a seed, a seed after `xorc`, a `copy` of a
  known value, a rail its `_unc` returned to 0), never "unwritten". Every violation fails. Templates are generated per symbol the module declares, forwarding to one generic
  evaluator.
- **Oracles.** (a) the reference `lowered.ll` in the same evaluator; it defines clean (freed at 0),
  kept (live at exit, measured and tape rails included) and the fired rotation list per input.
  (b) the C program: `name.O1.ll` with `cq_theta`/`cq_measure` as the identity, logging each
  `cq_theta`/`cq_phi` call site reached and its angle. A reference whose permutation part disagrees
  with its own C program goes to `SPEC_ISSUES.md`; it is not copied.
- **Comparison.** Named outputs; kept rails as a multiset; clean rails at 0; the rotation list
  (gate, target, angle or angle rail, predicate per input), up to reordering of gates with disjoint
  support and renaming of rails. Rails are matched by (kind, width, value function over all
  samples). Global phases are excluded from every comparison, against both oracles (CR §6): a
  phase whose control predicate is constant over the quantum inputs once the classical arguments
  are fixed, and whose angle is classical. Whether either side emits it is not compared. This never
  applies to an Ry, nor to a phase with an angle rail (`rz_qangle` is always compared). Rule 12's
  structural deletion is one case of it. Both sides run at K = 4.
- **Inputs.** Drivers are generated from `drivers.txt`. For every quantum input: edge values
  (0, ±1, MIN, MAX), fp specials (±0, ±Inf, NaN, a subnormal), a seeded random set, and every input
  when the quantum inputs total at most 16 bits. Also: values that hit every §2 totalization row
  (divisor 0, INT_MIN / −1, shift amount at and above W, index at and above n, NaN and out-of-range
  into `fptosi`); for every loop, inputs giving trip counts 0, K−1, K and K+1 (found by running
  the C oracle with trip counters); a seeded set over the classical arguments as well.
- **Self-test.** A mutated reference and an empty output must both be rejected before any green
  counts. Keep the mutants as permanent tests.
- **Reports.** Per example: §6 verdict, structural-verifier verdict, C-oracle verdict, and the
  normalized textual diff against the reference (comments stripped, locals renumbered) as a quality
  signal that never fails. A textual match may short-circuit the §6 run for that example.
- **Progress table.** rule → witness examples (from CR) → passing. Example counts come from the
  directory, never quoted.

## Build order

0. The §6 checker, evaluator runtime and drivers, with the self-test.
1. Straight-line code: taint, templates, the uncompute spine, the structural verifier.
2. Acyclic control flow: path predicates, flags, phases, value arms, `switch`, measurement.
3. Calls: clones, twins, `_ctl`, declared clones. Inline `asm` with a quantum operand (rule 27)
   joins this step once CQ_spec has its example (CR §8 lists it to write). Until then it is an
   internal compiler error like any unbuilt construction.
4. Memory: slots, QROM, QRAM, fat pointers, memory intrinsics, aggregates.
5. Loops: the three rule-14 cases, recursion depth, K resolution. (After memory: the
   classical-bound case writes slot arrays and QRAM, 187 and 188.)
6. The rest: tape, abort, `cq_invert`, fenv, `setjmp`/`longjmp`, varargs, atomics.
7. The version 1 injection bundle.

After version 1: the full musl bundle (musl b1efda5 with `_tools/musl_arch_cq/`, recipe in
CQ_spec `LIBC_COVERAGE.md`), the rule-27 library-build mode, then kernel tiers 2 and 3. Kernel tier
1 (passthrough) runs as soon as the driver exists.

## Review

Every milestone gets two rounds of independent adversarial review.

- **Wide.** Two or three reviewers, each with a disjoint hypothesis (for example: wrong predicate
  on some branch; a rail freed dirty or kept wrongly; a taint path missed through memory or calls),
  over the whole change.
- **Narrow.** One reviewer over the fix delta only, repeated until a round finds nothing.

Reviewers get the code and the spec, not the implementer's conclusions. They reason analytically and
run their own probes, never the implementer's tests. A finding becomes a bead.

## Issues and knowledge

- Beads (`bd`, prefix `cq`). Every internal error hit, every gap, every review finding and every
  spec contradiction is a bead. `bd ready` for the next work; `bd remember` for durable knowledge
  that is not derivable from code or spec.
- Nothing from CQ_lang's beads is imported.

## Documents

`NORTHSTAR.md` (goals and principles, nothing dated), this file, `SPEC_ISSUES.md`. No other
documents until something needs one.
