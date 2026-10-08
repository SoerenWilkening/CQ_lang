# Shared nested classical value arms

The focused change is `dm7f.16.1`, with speculative-literal obligations from
`p3kd.7.7`. Clang 19 at `-O1` produces the nested diamond pinned by
`control_predmux_nested_classical_call.ll`: a quantum comparison chooses whether
an ordinary classical classifier chooses subtraction or addition. The previous
compiler failed loudly on this valid program in main and in a lifted body.

For `g = x > y` and `c = y > 3`, the incoming values are `x-y` on `g && c`,
`x+y` on `g && !c`, and `y` on `!g`. PredMux computes each predecessor's edge
predicate, retains all incoming values, and uses the existing controlled-copy
merge into fresh rails. The borrowed quantum input survives. Main and clones
use the same condition grammar and merge owners. `ClaimAll` still adds classical
region roots only for clones; this change admits supported classical conditions
inside quantum-rooted main regions.

`SpeculationSafety.cpp` adds a total-call proof to the existing strict callee
walk. It checks exact scalar definitions, acyclic straight-line bodies and call
graphs, effects, dangerous division, poison-generating instructions, and the
contracts at both call-site and definition, matching calling conventions, and
poison-generating flags or metadata on ordinary nested calls. It proves integer return ranges
from actual dataflow without using the range annotation as its own evidence.
Ordinary classical calls remain calls; quantum calls still lift injected source.
Unproved totality remains a compiler gap requiring a lowering, not a physics
prohibition. Aggregate, memory and conditional callee bodies are outside this
focused proof.

A speculative operation records its scalar producer dependencies, including
values already in the entry block. Every admitted classical call argument must
be defined without a use/path assumption, or receive a stable freeze. This also
covers a bare outer parameter passed to an inner `noundef` call. A classical
value reaching a gate uses the same proof or a freeze at its definition. Local
replacement rewrites forward and inverse operands together; constants never
acquire uses of another function's SSA values. Clone stabilization precedes
forward capture, and main stabilization follows adjoint emission in both pass
entries. The proof walks use visited worklists.

R3's follow-up found that an erased quantum operation could lose its marker
while a raw poison constant survived as a gate literal. The existing pairing
guard deliberately accepts one unpaired literal slot; it cannot discharge this
speculative-definedness obligation. `p3kd.7.7.1` freezes raw scalar constants
while marking their source operands, before handle lowering. Each function
caches one freeze per typed constant and replaces only the selected source
operand uses. This avoids cross-function SSA references and runtime ABI guesses.
The new `spec_predmux_stable_raw_constant.ll` pins the single-slot case in two
functions. The established straight-line single-slot allowance is unchanged.

Bennett.jl at `824458d10e879c3fef673c231a02e5461dac667f` supplies the edge
predicate and incoming-value circuit construction in `src/lowering/phi.jl`.
BennettVM.jl at `23d28e6471f9cf5d8a22177d08260ca86adfe841` supplies the SSA
transfer semantics in `src/ir/ingest_phi.jl`, ADR 0022 and
`src/interpreter/Interpreter.jl::_bind_args_to_params!`: capture every incoming
before assigning outputs and preserve multi-use sources. Its duplicate-call-arg
and multi-use-PHI adversarial fixtures were inspected. CQ translates these
semantics into a fixed lowered gate script with mechanically derived adjoints
at compile time. The VM's runtime interpreter, history and replay are not used.
The reference scope and evidence limits remain in
[reversible-lowering-ground-truth.md](../reversible-lowering-ground-truth.md).

The linked slice `slice_nested_classical_call.c` exercises main plus lifted
calls with both runtime classifier outcomes. Its golden records 108 trace lines;
the preparation free check verified all 12 free sites, with zero violations and
zero unproven frees. The clone mirrors the captured phase-free gates before
freeing scratch, while its result and borrowed input remain available. Trace
and free checks complement the edge-transfer argument; they do not establish
numerical primitive implementations or simulate the unitary.

The four historical fixtures whose sole restriction was `E6-classicalbr` now
pin positive edge transfers, including one-input and equal-input classical PHIs.
Their filenames remain for existing historical references. The effectful-call
fixture still fails loudly. Review reports and measured validation are retained
in this directory; the broader `dm7f.16` and `p3kd.7.7` scopes remain open.

The full census at `9944c329` measures **100/180 scalar cells**, with source
coverage 42/120, intrinsic coverage 48/48 and macro coverage 10/12, plus the
classical-only 3/3 outside that total. All 378 accepted probes pass the structural
free check; 105 of 483 probes still decline. Compared with the committed census,
16 mixtures newly accept and 14 cells become complete, with no acceptance
regressions. The completed cells are `tanhl`, `expm1l`, all widths of `ldexp`
and `scalbn`, and f32/f64 `pow`, `hypot` and `fdim`. `fdiml` remains blocked.

Remaining first blockers are 43 body/memory, 17 shared control (eight nested),
18 undefined returns, 14 argument/return ABI, nine `frem`, two loop control and
two unknown macro callees. Their exact diagnostics and mixtures are in
[validation/census-audit.json](validation/census-audit.json); the full data is
[runtime_census.json](../../../tools/library_coverage/runtime_census.json).
Acceptance and structural checks do not establish numerical or unitary behavior.

The census command used `--jobs 1` at nice level 19. The batch uses `ctest -j1`,
lit `-j1`, and one worker in every inner harness. Its equivalence entry runs
`--stride 1 --jobs 1` once, replacing the usual sampled comparison and supplying
the full required comparison. Temporary scheduling overrides preserve all
assertions and are restored byte-for-byte after the gate; their exact settings
are recorded in [validation/serial-scheduling.json](validation/serial-scheduling.json).

The single serial batch at `9944c329` passed 539 of 549 entries, including
all 2709 driver equivalence comparisons with zero mismatches. Eight real-libm
slices exposed stale taint after boolean PHI replacement: a fresh quantum
predicate could be frozen as classical, then reach a binary-only negation
assumption. `dm7f.16.2` refreshes the existing taint owner after replacement
and erasure, before another edge literal is classified. Genuine frozen bits
are negated opaquely with xor against true. No bounded ancestry rejection or
runtime state is introduced. Three independent analytic follow-ups cleared
the correction; the outer specialization fixpoint and final literal checks
remain in force.

Only the failed batch subjects were rerun: scoped green passed 56 of 58 IR
fixtures and all nine failed slices; final passed the two remaining typed
seed assertions. Bare scalar inputs and unproved loads now have positively
checked freezes feeding the same literal slots. Two exact gate-stream twins
use matching noundef seeds for their defined-input comparison. Six historical
negatives now assert valid shared classical-control/call lowerings. The
nexttoward golden changes only an unused undef allocation seed to +0.0, with
the selected-edge argument recorded in the R3 follow-up. The passing batch
entries and full driver comparison were not rerun after this correction.
See [validation/batch.json](validation/batch.json) for commit-qualified counts.
