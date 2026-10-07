# p3kd.7.8 adversarial review, round 1

Verdict: **ACCEPT** for this round's audited scope. No proven introduced silent miscompile. One source-comment correction is required; existing root/ABI/rolled-loop gaps remain compiler gaps and earn no coverage credit.

Reviewed implementation: p3kd78-one-pipeline / bae428e8. Read NORTHSTAR.md, CLAUDE.md, docs/design/clone-one-pipeline.md, CODE_MAP.md, latest bd p3kd.7.8 notes and both 2026-10-07 owner rulings. The mechanical-reversal ruling supersedes the earlier uncompute() recommendation.

## Finding R1-1: StageList.h overstates taint scoping (documentation, introduced)

`ir-pass/include/StageList.h:11` says every stage acts only on values in its TaintSet, therefore scopes the entire sequence to the clone. That is not literally true. `collectTaintedCalleeCone` (`LoopUnrollPrepass.cpp:78`) walks calls in the module and adds visible callees of tainted sites, then their transitive callees. `unrollConstTripLoops` (`:228`, `:243`, `:247`) admits a loop by that relevance cone as well as by local taint. Thus a clone's prepass can also rewrite a nested original callee. `stripPredMuxPredictedMarks` (`CondLiteral.cpp:158`) also clears metadata module-wide.

No semantic failure follows: relevance only chooses candidates; every loop must still satisfy the existing U1-U8 per-loop safety fences. The metadata cleanup removes compiler prediction records after their final consumers. Parent independently confirmed this scope distinction and plans a comment correction. State the two scopes explicitly instead of relying on the incorrect universal claim.

## Six new targeted probes (no implementer tests rerun)

Command shape, once per probe: `build/ir-pass/cq-opt -passes=cq-lowering -S /tmp/p3kd78-review-r1/<name>.ll -o /tmp/p3kd78-review-r1/<name>.lowered.ll`. Each stdout/stderr is preserved beside its source. No lit, ctest, corpus lowering, rebuild, or repository-source mutation was performed. Probe count: **6/6**.

| Probe | Result | Hypothesis and evidence |
|---|---|---|
| p1_alias_repeat | accept, exit 0 | Two quantum parameters alias the same caller handle; compound condition merge feeds a second merge, then an add. Caller line 22 passes `%h` twice. Clone lines 32-47 compute the requested piecewise value; lines 50-62 reverse the complete stream with the same operands, lines 63-71 free only its scratch. `%a` and `%b` appear only as read inputs, never as write targets or frees. This remains correct when their physical handles alias. |
| p2_fp_condtree | accept, exit 0 | Two fp64 quantum params, two fcmp leaves, AND and fp64 arithmetic arms. Clone lines 29-38 use f64 templates and `cqrt_copy_f64_controlled`, lines 39-40 copy out f64, lines 41-48 undo those exact gates. No i32-width data copy occurs; every free in lines 49-54 names scratch, never a param. |
| p3_ctlz_root | accept, exit 0 | Param-rooted shift/count loop with count seed 57. Clone lines 34-37 emit shift, ctlz, mask 31, then `56-mask`; lines 40-43 undo all four. On a basis input y=x<<1, the loop runs `1+(ctlz(y)&31)` iterations (zero y exits after one), so this result matches the source count. Demonstrates new prepass reachability does not need a theta root in the clone. |
| p4_i1_root | loud decline, exit 1 | Bare tainted i1 param condition. It stops at the pre-existing specialization ABI gate (`floating-point quantum argument or return has no reversible copy`), before H4 can be exercised. The misleading diagnostic is an existing ABI gap, not physics. No output circuit is accepted. |
| p5_untainted_constloop | accept, exit 0 | Four classical multiplies in a constant-trip loop with unroll-disable metadata, followed by add of quantum param. Original lines 10-13 and clone lines 31-34 contain exactly four multiplies; only the final mixed add is quantum. All loops are gone before wrapping. Confirms H6 does not block this reachable end-to-end shape because the original callee was already relevant to main's prepass. |
| p6_param_rolled | loud decline, exit 1 | Runtime finite classical bound, tainted additive accumulator fed from borrowed param. Main's loop stage diagnoses `loop-carried tainted value crosses iterations` inside the clone. This is an existing rolled accumulation gap, now attributed to its main-stage owner. |

## H1-H7 audit

- H1: `tryCaseA` (`LoopLowering.cpp:3209`) requires a collected clean theta mint. A param fails that conjunct; no collapse to an unrelated rail occurs. Fresh additive latch data takes the loud cross-iteration path first (p6).
- H2: `railPhiRootMint` (`:403`) delegates to `railChainRootMint`; `:425-428` require a call in GateCalls. Params yield null, so the header phi is left for its loud owner.
- H3: `invariantRegisterRootsImpl` (`:4744-4746`) returns false for a tainted Argument. It cannot grant iteration-local discharge permission on an unclassified borrowed root.
- H4: `isCondRailLeaf` (`SelectClassify.cpp:635`) accepts only `cq_theta_i1`. A tainted i1 Argument is rejected rather than treated as a clean flag. Current ABI rejection precedes this in p4.
- H5: `classifyConeNode` (`PredMuxFlatten.cpp:639-641`) requires noundef on an Argument. Deferring retype preserves source attributes during these stages; rewritten attributes are removed afterwards. p2 demonstrates a typed fp condition tree survives and becomes a width-correct circuit.
- H6: current clone is not the tainted-callee cone member merely because it has tainted params. However original/nested callees may enter the cone via tainted call sites. Relevance is module-wide, with per-loop safety fencing; p5 demonstrates main's earlier original-body unroll covers an otherwise untainted clone loop.
- H7: `reseedCloneTaintFromParams` (`Specialization.cpp:108-126`) seeds the captured params and closes only inside Clone. It runs after prepass/PredMux mutations. The control stages do not perform that destructive rebuild after emitter rails exist (`:280-284`, `:303-310`); round 2 incrementally seeds UntaintedMergeRails through the shared worklist (`TaintPropagation.cpp:2741-2744`). Thus a fresh `%out` not reachable by def-use from a param remains tainted.

## Strip-elision and borrowed-input soundness

The pre-lift body scan rejects rotations/phase and measurement by intrinsic membership (`SpecializeReject.cpp:542-551`), rejects opaque/indirect nested calls (`:658-663`), and restricts memory to admitted const-table QROM reads (`:679-694`). The accepted data producers are reversible basis-function embeddings; AND networks, X and XOR copies are basis permutations. Nested lifted calls preserve their inputs by induction on the acyclic lift order. Classical computations run once and supply the same immutable SSA literals in the forward and its mirror.

For scratch R with only call users, `elideForwardStrips` (`BennettWrap.cpp:148-190`) records writes after its last observed read up to its free. Known write targets are target-only x, cnot, toffoli, controlled copy and the output of an uncontrolled template `_unc` (`:101-118`). Multi-target or unknown effects refuse elision; non-call users refuse it. Mint calls read their operands and write fresh outputs. Removing an R-only basis permutation after the emitter's last use cannot change a later output label; the mirror restores all kept scratch. Program-order frees allow removal of a node strip to expose its earlier leaf flags' final read, without deleting any forward control needed by a retained copy. p1/p2 show complete mirror streams over dependent merges and a condition tree.

The helper's last-read scan is bounded by the free. It relies on the control emitter invariant that its freed scratch is not read afterwards, rather than independently establishing it over the suffix after the free. No such suffix read was found in the reachable gate emission under review. A future emitter that violates this invariant needs a suffix-use check; the current source should not be described as a general dead-register optimizer.

Borrowed args are never candidates for final freeing: `emitBennettWrap` (`:259-262`) frees only captured Mint call results and zero-initialized Alloc call results. It never inserts a parameter into that set. Return copy-out is fresh and excluded from Fwd capture (`:215-227`, `:239-241`), so it escapes. The basis copy changes only that fresh out rail. Reverse calls reuse original operands (`:246-252`) and clean the entire retained gate stream; accepted clone streams contain no forward free or `_unc` after the pre-scan (`:221-223`). Nonzero/runtime classical initializations are restored to their original product basis value and remain allocated, per R5.

These arguments and the inspected streams support ACCEPT for round 1, while the three-round review requirement remains pending with the coordinator.
