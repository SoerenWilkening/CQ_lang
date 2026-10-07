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

The three historical fixtures whose sole restriction was `E6-classicalbr` now
pin positive edge transfers, including one-input and equal-input classical PHIs.
Their filenames remain for existing historical references. The effectful-call
fixture still fails loudly. Review reports and measured validation are retained
in this directory; the broader `dm7f.16` and `p3kd.7.7` scopes remain open.
