# dm7f.16.1 / dependent p3kd.7.7 — independent R11 round 2

Disposition: no new correctness blocker found in the current narrow capability change. Analytic clearance for the shared acyclic nested classical value-arm mechanism and total scalar call proof, subject to the remaining independent round and required validation. This does not close the full p3kd.7.7 scope or certify all compiler lowering.

## Findings first

No additional correctness finding. The three historical E6-classicalbr-only negative fixtures must become reviewed positive expectations in this capability change. Their claims that acceptance necessarily constitutes a silent miscompile are obsolete:

- `control_predmux_reject_classical_br_in_region.ll`: write `g = q > 5`, `c = n > 3`. The incoming quantum values are `q XOR 3` on `g AND c`, `q + 1` on `g AND NOT c`, and the original borrowed `q` on `NOT g`. These predicates are mutually exclusive and cover every defined input. Existing edge construction and controlled-copy merge implement exactly those transfers.
- `control_predmux_reject_degenerate_phi_classical.ll`: the one-incoming PHI is exactly `%arg`; its comparison stays classical. The three output edges are `q` on `g AND (arg == 0)`, `q * 7` on `g AND (arg != 0)`, and `q + 3` on `NOT g`. No claim that the degenerate PHI becomes quantum is needed.
- `control_predmux_reject_equal_incomings_phi.ll`: both PHI incomings are the same `%arg`. The inner quantum diamond reconverges without changing that argument; the downstream result has the same three edge equations as the degenerate case. Eliminating the redundant mux is an identity and preserves the borrowed source.

These are acceptance-direction migrations. Pin the emitted operation, condition literals and merge behavior rather than merely checking exit zero.

## Poison and immediate-UB argument

The strict owning callee walk rejects CFG and call-graph cycles, conditional branches, memory operations and dangerous integer division before the new helper reasons about defined results. Consequently `canCreateUndefOrPoison` is not being misused as a substitute for immediate-UB analysis. Acyclic exact bodies with scalar dataflow and unconditional br/ret have no hidden memory or branch-condition obligations.

The new call contract rejects effective `noreturn`, `returns_twice`, `convergent`, `noduplicate`, musttail and operand bundles. LLVM 19 CallBase accessors consult the callee when the call-site attribute is absent; this is not a call-site-only fence. Parameters are scalar and both call-site and definition attributes use the same inert whitelist. The return proof checks both homes, permits noundef only alongside the defined-input body proof, and proves range contracts from the actual return dataflow. Unmodeled value constraints such as nofpclass are not admitted. Pure-body reasoning, rather than a readnone annotation alone, establishes the absence of observable effects and immediate UB.

Every argument of an admitted speculative total call is now stabilized if it lacks a context-free definedness proof. This covers the R1 case where an unconstrained outer parameter feeds an inner noundef parameter or a noundef return. The proof does not infer that an argument is defined from the constrained call which is being moved.

The source marker now reaches scalar producer dependencies outside the moved block. A preexisting entry fptosi or shift that becomes a gate literal remains recorded after its quantum consumer is replaced. Argument literals are handled by the function mark. The runtime-call owner handles aliases using the called GlobalValue name. Constant replacement is scoped to instruction users within the owning function, so a freeze cannot introduce cross-function SSA uses.

A freeze is inserted immediately after a surviving source instruction, after PHIs when appropriate, or at entry for an argument/constant. The original definition dominated its legal local uses; these placements preserve that dominance. One freeze replaces those uses, including paired forward and inverse calls. In a lifted clone this happens before forward capture; in main it happens after adjoints are emitted, allowing the same local replacement to rewrite both directions. The source is unchanged for defined selected-arm values. On an untaken arm an arbitrary fixed literal controls scratch computation which the captured mechanical inverse removes.

The visited worklists eliminate the new recursive/exponential traversals reported in R1. No across-mutation cache is introduced. Moving the existing freezeDischargesHoistedArg owner into SpeculationSafety preserves its effective noundef and attribute-union behavior and gives both consumers one whitelist.

## Gate and ownership reasoning

Read the saved optimized `/tmp/dm7f16/shape.ll` and lowered `/tmp/dm7f16/shape.ready.ll`, without rerunning them. For `g = x > y`, `c = y > 3`, the direct and lifted forms choose `x - y` on `g AND c`, `x + y` on `g AND NOT c`, and `y` on `NOT g`. The classical classifier remains an ordinary noinline call; the quantum helper remains a lifted clone. Their f64 operations and copies preserve source widths.

The lifted forward captures the fsub/fadd, predicate flags and controlled copies, then copies the result into a distinct escaping f64 output. The reverse mirrors the captured forward in reverse order using the same classical SSA operands. This restores each fresh zero scratch rail before its free and leaves borrowed inputs available. A runtime-valued product rail allocated from a classical value is not treated as zero scratch and is not freed by the zero-only allocation rule. The change introduces no runtime tracking or interpreter.

Pinned implementation ground truth: Bennett.jl `824458d10e879c3fef673c231a02e5461dac667f`, `src/lowering/phi.jl` computes block/edge predicates and transfers the selected incoming value. BennettVM.jl `23d28e6471f9cf5d8a22177d08260ca86adfe841`, `src/ir/ingest_phi.jl` and ADR 0022 establish edge-specific PHI binding, capture-before-assign and preservation of multi-use sources. Those are source semantics for CQ controlled copies and borrowed ownership. The runtime VM execution model, history and replay are not an implementation route for CQ.

## Validation scope

Read AGENTS.md, NORTHSTAR.md, current CLAUDE.md rules, CODE_MAP.md, both design records, current diff and helper, R1 report, the saved optimized/lowered shape, the new poison fixture, the three historical classical-branch fixtures, relevant owning strict purity/cone/poison/literal/rail-select/reversal code and LLVM 19 API declarations. The current proof is analytic and uses existing saved evidence; it does not claim new measured acceptance or census gains.

Reviewer counts: 0 tests, 0 builds, 0 cq-opt executions, 0 targeted probes (0/6 ceiling). No implementer test or completed p3kd.7.8 validation was repeated. All review operations were read-only except this report in /tmp.
