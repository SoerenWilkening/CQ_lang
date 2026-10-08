# R2 analytic follow-up — PHI taint refresh and opaque freeze negation

Disposition: no correctness blocker found for the reported fresh-PHI predicate failure. The current source repairs its missing taint membership through the owning forward propagation mechanism and handles compiler-created FreezeInst leaves without an unchecked BinaryOperator cast. Clearance is limited to this correction and retains the outer pipeline's taint, specialization and literal backstops.

Counts: 0 tests, 0 builds, 0 probes, 0 cq-opt executions and 0 mutations. Repository files unchanged.

## Findings first

No new concrete regression or miscompile found. Scope qualification: propagateFromSeeds opens a new SpecPredictGeneration, and older predicted-classical call results intentionally remain sticky. refreshSpeculationTaint is therefore the normal owning growth drain over live roots, not a replacement for final specialization replanning/reseed or a proof of every future call-return taint decision. Keep those existing outer-driver owners and their loud backstops intact.

## Ordering and ownership

convertPhis builds Acc from edge predicates and incoming values, RAUWs the original PHI, normalizes marked scalar source operands, erases the PHI, and only then refreshes. This is the correct ordering: all consumers now read Acc before forward propagation follows them. TaintSet's pointer-keyed tables scrub deleted Values through LLVM deletion callbacks, so the erased PHI is absent from the subsequent root enumeration; the helper does not inspect dangling keys.

refreshSpeculationTaint snapshots existing live tainted Instructions and Arguments belonging to the function and invokes propagateFromSeeds. All such values are already members, matching the owner's API precondition. Starting from every current tainted definition ensures fresh users are reached even when an older intermediate user was already visited: that intermediate is itself another root. Newly inserted ordinary users are drained iteratively through the owning insertion/worklist discipline, without a new bounded backward-ancestry proof. Constants are not incorrectly promoted to quantum roots.

This preserves source/clone distinctions. Main has its existing theta-derived roots; a lifted clone retains its masked parameter roots before signature retyping. The owning growth drain preserves measurement sinks, angle-only edges, source call-result prediction and skipRuntimeCalls behavior. No new spelling of those decisions is introduced.

The region's topological order converts predecessor PHIs before later blocks' outgoing edge predicates are demanded. A downstream condition derived from the just-converted Acc therefore receives ordinary quantum dataflow membership before literal() asks whether that original terminator condition is classical. The source widths remain available at this point. The helper does not mutate CFG edges or erase further instructions while a raw local seed snapshot is live.

## Stable-bit negation

buildNegation now treats FreezeInst as an opaque i1 value and emits xor(F,true). This negates the exact already-chosen stable bit. Descending below the freeze or freezing the negated producer separately would select an independent arbitrary value on poison/undef and could fail to complement the true-edge literal. The new arm also prevents the old unchecked cast<BinaryOperator> from receiving a unary FreezeInst.

The reported quantum-derived Acc must not be frozen as a classical bit; the fresh owning taint membership pays that obligation. Genuine classical freezes remain scalar choices. Where such a classical negation occurs as a literal child of a mixed and/or predicate, the existing literal owner can consume the opaque classical subtree. The downstream grammar's existing restrictions on quantum freezes, root NOT forms and mixed xor remain; this correction does not author a new flag emitter or claim those separate gaps are solved.

## Pipeline boundary

The owning call predictor already uses LaterTaintOracle to anticipate PHIs selected by quantum control. A call that remains sticky across a growth generation still relies on the existing replanning and loud specialization/literal fences. The final pipeline must continue to re-seed taint after the complete flatten and apply its normal consumer checks. This report found no concrete case bypassing those fences and does not replace them with the narrower ordinary-dataflow argument used for the reported boolean PHI failure.

The correction changes compile-time analysis and emitted SSA predicates only. It adds no runtime interpreter, history, checkpoint or reversal state. The existing captured gate stream and mechanically emitted adjoints retain their ownership and zero-before-free rules.

## Reviewed material

Read the current SpeculationSafety helper and header diff, RegionFlattener run/convertPhis/literal/buildNegation ordering, TaintSet deletion discipline, propagateFromSeeds/propagateWorklist/drainWorklist/settleSpecPredictions, and the downstream collectCondTree/classical-literal owners. CODE_MAP was consulted before locating owners. No saved output was regenerated or passing test repeated.
