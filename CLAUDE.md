# CQ_lang: operating manual

This compiler was built under the name CQ_lang2. That name in `DECISIONS.md`, bead text and reports means this
repository. The compiler it replaced is on branch `archive/v1` (tag `cq-lang-v1-final`).

Read [`NORTHSTAR.md`](NORTHSTAR.md) first. It holds the goals and principles and wins over this file.
This file is how to work.

## Pins

- **Spec.** CQ_spec is `spec/` in this repository (a subtree; it was a sibling checkout until 2026-11-17, and
  "CQ_spec" in older text means it). `spec.lock` pins a digest and a sha256 of every
  file under `examples/` plus `CONSTRUCTION_RULES.md`, `CQ.h`, `BACKEND_ABI.md` and
  `_tools/drivers.txt`. Run `python3 tools/spec_lock.py` before any test run; drift exits 1. Re-pin
  with `--write` only on a deliberate spec bump, in a commit of its own. `BACKEND_ABI.md` is
  non-normative (CR wins over it) and `drivers.txt` is input data: a drift in either is a re-pin,
  not a spec issue.
- **Toolchain.** LLVM 19.1.7 from brew `llvm@19`: `/usr/local/opt/llvm@19/bin` (`clang`, `opt`,
  `llvm-link`, `llvm-as`, `llvm-config`). Never Apple clang. Triple `x86_64-apple-macosx`, `-O1`.
  C++17 for the pass.
- **Ground truth beyond the spec, for templates and totalization only** (not for memory or
  pointers, owner 2026-11-05: Bennett.jl's static pointer provenance is retired). Bennett.jl `824458d10e879c3fef673c231a02e5461dac667f` and
  BennettVM.jl `23d28e6471f9cf5d8a22177d08260ca86adfe841`, the revisions CQ_spec names, checked out
  read-only at `../refs/Bennett.jl` and `../refs/BennettVM.jl`. Consult them at those revisions only,
  cite `path:function`, never vendor or link them. A mechanism cited without reading it is an
  unverified claim.

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
lowered module. A module with no `cq_*` call, no root list and no reference to a declared clone is
the pass's identity, and a call into it is a host call (rule 16). Inside a lowered module a function is
left as it is only if it has no memory access, no `cq_*` call and no call (principle 1, kernel tier 1). The pass is the identity when `opt -passes=cq-lower` and `opt`
with no passes produce byte-identical output on the same input. The `cqcc` driver runs this chain. The corpus feeds each
`name.O1.ll` straight in; `clang-19 -O1` reproduces those files apart from comments and
`source_filename`.

K per loop, first match wins: the per-function flag (`fmod=2046,sin=53`), a `CQ_K(f, k)` line
(the `used` constant `__cq_k_<f>`), the global flag, the built-in default 4. Per-loop annotation is
deferred until CQ_spec defines its syntax.

The injection bundle (`bundle/manifest.json`) holds the bodies the corpus lifts: compiler-rt's
`__{mul,div}{s,d,x}c3` (69, 169–174, 181, 182), musl `memcmp` and friends (190), the libm functions the
corpus calls (175) and the `sprintf` and `sscanf` families. A callee with no body and on no root list
is a host call (rule 16); on a root list it is a rule 27 declared clone. Build the bundle with the
corpus triple.

## Internal errors, never declines

- An unhandled shape does not stop the pass (owner 2026-11-03, 2026-11-05): no fatal error, guard or
  decline for a shape that is not built yet. The code behind the site runs on, at most with a
  non-fatal one-line note naming the site. The structural verifier, a crash or the §6 checker judges
  the result, never the pass refusing. A bead and a fix follow.
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
  when the quantum inputs total at most 8 bits (16 bits only in the on-demand full sampling mode,
  which the owner turns on explicitly; no test or default path runs it). Also: for every loop,
  inputs giving trip counts 0, K−1, K and K+1 (found by running the C oracle with trip counters);
  a seeded set over the classical arguments as well.
- **Domain.** Whatever LLVM does, we do. An input on which the C program has undefined behaviour
  as LLVM defines it (division by 0, INT_MIN / −1, shift amount at or above W, out-of-range
  `fptosi`, an access past an object) is outside the domain: the sampler never keeps it, the
  checker never compares it, and the pass does not protect against it.
- **Self-test.** A mutated reference and an empty output must both be rejected before any green
  counts. Keep the mutants as permanent tests.
- **Reports.** Per example: §6 verdict, structural-verifier verdict, C-oracle verdict, and the
  normalized textual diff against the reference (comments stripped, locals renumbered) as a quality
  signal that never fails. A textual match may short-circuit the §6 run for that example.
- **Progress table.** rule → witness examples (from CR) → passing. Example counts come from the
  directory, never quoted.

## Build order

Steps 0 to 7, the full musl bundle and the library mode are built. The list stays as the order the
constructions depend on.

0. The §6 checker, evaluator runtime and drivers, with the self-test.
1. Straight-line code: taint, templates, the uncompute spine, the structural verifier.
2. Acyclic control flow: path predicates, flags, phases, value arms, `switch`, measurement.
3. Calls: clones, twins, `_ctl`, declared clones. Inline `asm` with a quantum operand (rule 27)
   joins this step once CQ_spec has its example (CR §8 lists it to write). Until then it runs on
   like any unbuilt construction.
4. Memory: the one bus (rules 5, 20 to 22): bus accesses at integer addresses, the in-place form,
   load un-copy, `__cq_alloc` and K2, memory intrinsics, aggregates. No slots, per-object buses,
   QROM, fat pointers or pointer provenance: that code is removed, not adapted.
5. Loops: the three rule-14 cases, recursion as one clone with an activation counter, K
   resolution. (After memory: the classical-bound case accesses the bus, 187 and 188.)
6. The rest: tape, abort, `cq_invert`, fenv, `setjmp`/`longjmp`, varargs, atomics.
7. The version 1 injection bundle.

After version 1: the full musl bundle (musl b1efda5 with `_tools/musl_arch_cq/`, recipe in
CQ_spec `LIBC_COVERAGE.md`), the rule-27 library-build mode, then kernel tiers 2 and 3. Kernel tier
1 (passthrough) runs as soon as the driver exists.

## Review

Every milestone gets ONE round of independent review (owner, 2026-11-05).

- Two or three reviewers, each with a disjoint hypothesis (for example: wrong predicate on some
  branch; a rail freed dirty or kept wrongly; a taint path missed through memory or calls), over
  the whole change, asking only whether the lowered program computes what the C program computes.
- A fix is verified by the §6 checker and targeted tests. There is no review of a fix and no
  wording or style finding.

Reviewers get the code and the spec, not the implementer's conclusions. They reason analytically and
run their own probes, never the implementer's tests. A finding becomes a bead.

## Issues and knowledge

- Beads (`bd`, prefix `cq`). Every internal error hit, every gap, every review finding and every
  spec contradiction is a bead. `bd ready` for the next work; `bd remember` for durable knowledge
  that is not derivable from code or spec.
- Nothing from CQ_lang's beads is imported.

## Documents

`NORTHSTAR.md` (goals and principles, nothing dated), this file, `SPEC_ISSUES.md`. For users:
`README.md`, `docs/MANUAL.md`, `llms.txt` (the manual on one page for AI assistants; change it with
the manual) and `docs/EXPERIMENTS.md` (dated measurements). `DECISIONS.md` is history and is not
extended. No other documents until something needs one.
