# Northstar audit recheck — 2026-09-30

This recheck disputes iwz1's closure, three retitle rationales, and several fixture classifications. The owner has since resolved native-fmod eligibility: a placeholder trace primitive does not qualify; missing enforcement and exact source lowering are tracked in 3c6m.68. The other proposed tracker changes below have **not** been applied. The original verdict TSVs are preserved unchanged. The 15 separately authorized fixture edits change explanatory headers only.

## Evidence and limits

Reviewed the 27 CLOSE and 38 REFRAME rows against their original issue descriptions, notes and current implementation, then the 141 P3 deferrals against live issue histories. The P3 list overlaps the triage rows; these counts are not additive. Deferring a real compiler gap can be a scheduling decision under NORTHSTAR; it cannot turn the gap into a valid decline.

All **1,201** mapped fixtures passed their existing lit commands (41.04 seconds): `cd build && lit ir-pass/test -j6 --filter '<alternation of mapped filenames>$'`. These commands exercise transformed and generated inputs as well as plain `%s` inputs. Also ran 488 loop/PredMux/region/nested primary modules directly with `CQ_PREDMUX_DBG=1`: 487 declined and one accepted. The accepting file, `lowering_predmux_purecallee_deep_chain.ll`, is a generated-input fixture whose plain module contains no tested function; its actual lit command passed. A passing negative test establishes the current diagnostic, not its physics classification.

Compiler SHA-256: `e42a3dd742d7b69d53e7f80afc4c5c64037d6ce5f7aa48739b6cc677a1673ae6` (`build/ir-pass/cq-opt`). No lowering implementation was changed and no quantum simulator was used. Evidence is source reasoning, LLVM diagnostics and the trace runtime; lit success alone does not establish correct quantum semantics.

The detail TSV's exclusive classes are 587 SAFETY-NET, 473 GAP, 49 INPUT-ERROR, 46 PHYSICS-b, 35 PHYSICS-d, 10 PHYSICS-c and one MIXED. The four duplicate recommendations overlap those classes. All four were confirmed by stripping local names with LLVM and comparing normalized IR (`duplicate_checks.tsv`); no fixture was deleted. Thus the stated totals 587+473+49+91+4 double-count duplicates and omit the mixed row; they are not an exclusive partition.

## Closures to reconsider

| Issue | Proposed disposition | Evidence |
| --- | --- | --- |
| iwz1 | Reopen/reframe as the missing mechanical freeze/hoist invariant | `ClassicalCallArmEmit.cpp` queries `freezeDischargesHoistedArg` before moving the call, and comments document this order. Its issue notes explicitly say the remaining obligation is a mechanical pin. A comment and the current order do not provide that pin. |
| 3c6m.57 | Its original triage closure does not settle the subsequent owner ruling; follow up in 3c6m.68 | The compiler's native `frem` route passes through trace templates but has no implementation supplied by Bennett.jl. The owner now limits direct lowering to approved hardware primitives without source to inject or implementations provided by Bennett.jl. Exact fmod source must be lifted when that route is absent. Missing lowering is a compiler gap, not a physics prohibition or a valid completed capability. The old issue status is unchanged. |
| 0njv, 67s8, 67n5 | Original silent-defect closures can stand only with live successor gap tracking | The new stale-alias fences prevent the old silent error. They do not implement coherent basis fanout. CNOT fanout is valid, so the declined source still needs a lowering ticket. Confirm an active successor rather than treating the fence as completion of goal 1. |
| zujr | Keep closure scoped to its delivered headline | Original notes reject dependency subsumption as a closure argument. The new rationale can close the delivered parent, while each undelivered blocker remains independently tracked; it should not claim those blockers were delivered. |

The other close decisions have a delivered, superseded, retired-surface or explicit owner-scope basis. In particular zt0b's old alpha ruling was withdrawn after the `nomerge` stage-1 work; a removed register-form `cq_phi_*` route is not a current lowering capability gap. The machine-readable review lists every requested CLOSE/REFRAME/P3 row.

## Retitles to reconsider

| Issue | Problem | Proposed wording constraint |
| --- | --- | --- |
| lo7u | A post-measure switch title drops the separate unmeasured round-2 stale-scrutinee hazard recorded in the original description. | Preserve both correctness hazards, or split the unmeasured hazard into a linked issue. |
| k02s | “Guard-independent” requires more than a finite bound for every reachable loop-entry state. | A proved dominating guard may legitimately restrict the state set. Require a proved finite bound on reachable executions; do not assume an unchecked guard proves it. |
| ogwt | Principle 10 was presented as resolving an owner semantic question about abort-arm arguments. | Label that argument-erasure interpretation as proposed unless an explicit existing owner ruling is cited. Keep the currently sound park behavior while resolving its contract. |

The other retitles generally restore the right obligation: bounded quantum control, source injection, coherent memory and angle registers are gaps rather than permanent restrictions. Reframing a design ticket does not independently authorize a new library leaf or settle its range contract.

## P3 deferrals to reconsider

| Issue | Recommendation | Limit |
| --- | --- | --- |
| u9pl | Reproduce the recorded wrong-unitary QRAM/entangled-Shadow-main case on the current surface; promote if it survives. | Its old repro uses retired register-form `cq_phi`. A diagonal phase alone is insufficient to prove lost interference. No new current miscompile is claimed here. |
| jj3o | Recheck the supplied `_unc` twin trust defect alongside active P1 9oob; prioritize the distinct dirty-free route. | The original evidence was IR-only. That is a reachability limitation, not proof that wrong uncomputation is harmless. |
| 3c6m.62 | Include in the runtime census's scope and output-observation checks. | Reading byref outputs and preserving `signgam` distinguish a whole-function probe from the old return-only probe. |
| za4z | Candidate closure as superseded, after owner review. | Current `TaintPropagation.h` uses self-cleaning `TaintedValueSet` and `ScrubMap` for the reported `Tainted` and `BirthOrder` keys. The original raw-key claim is stale. |
| 8h7d.10 | Candidate closure as delivered, after owner review. | Current `multiplicityAgrees` compares `markedHeaderOf`; its use sites already enforce the multiplicity boundary the issue requests. |

Other deferred checker holes and unreachable hazards retain their recorded trigger conditions. This recheck does not promote hypothetical repros to demonstrated silent miscompiles or equate “not presently scheduled” with “physically impossible.”

## Fixture verdicts to change

Each named negative test actually ran and still declined. These proposed classifications concern the program's semantics, not permission to remove the current safety fence.

| Fixture | Audit class | Proposed class and reason |
| --- | --- | --- |
| lowering_predmux_leave_speccall_loop.ll | PHYSICS-c | GAP. Starts at zero and increments by one until the signed counter reaches the signed i32 argument. At most `INT_MAX` trips (or one for nonpositive input). Quantum-dependent count has a finite bound. |
| spec_reject_clone_loop.ll | PHYSICS-c | GAP. Same finite signed-i32 increment-to-bound loop. |
| lowering_predmux_leave_speccall_recursive.ll | PHYSICS-c | GAP. Recurses only for positive signed i32 `a`, with `a-1`; at most `INT_MAX` recursive steps. Huge finite depth is not unbounded depth. |
| control_classical_call_arm_reject_impure.ll | PHYSICS-b | GAP. The visible callee only adds 100 and returns. Missing purity attributes do not make its known body an irreversible side effect. |
| control_predmux_leave_unreachable_store_arm.ll | PHYSICS-b | GAP. The store targets an internal global with no reader or escaped address. It is dead classical state, not an observation of the quantum branch. |
| taint_reject_quantum_return_outparam.ll | PHYSICS-b | SAFETY-NET/GAP. The caller passes private stack storage, then uses its result coherently before an explicit final measure. An out-parameter is not intrinsically a classical escape; interprocedural quantum-memory propagation is missing. |
| lowering_unroll_leave_alloca_tainted_size.ll | PHYSICS-b | GAP/SAFETY-NET. Both the tainted-size alloca and its ptrtoint user are dead. The fixture header itself records that deleting them is unitary-equivalent; no allocation result reaches classical observation. |
| lowering_reject_qram_inttoptr.ll | PHYSICS-d | Incorrect category. There is no opaque callee; a forged quantum-derived address feeds an unused load. Resolve defined-address/UB and dead-load semantics before choosing input error, memory gap or a real classical-observation boundary. |

The PHYSICS-c rows with actual infinite backedges or nonterminating recursion remain distinct: for example an invariant quantum choice of a step of two can prevent an i32 counter from ever reaching an odd stop value. The in-loop tainted-exit header's assertion that its condition never changes is unsound when theta changes the state; absent a proved bound it still cannot be assigned a finite circuit by this audit.

## Classification questions needing an owner boundary

* `control_swap_reject_value_stray.ll`, `lowering_reject_break_measure_in_body.ll` and the measured arm of `control_predmux_leave_multiexit.ll` contain explicit user measurements. Their existing fences protect erasure/reverse-play from dropping or duplicating those measurements. Calling the whole program PHYSICS-b solely because the measurement reveals a controlled path overlooks the explicit sink. The conditional-measure instrument and post-measure name contract need resolution (yiid); retain the fences meanwhile.
* `lowering_reject_railbank_global.ll` has a bounded three-cell global bank, all of whose accesses are visible in main, followed by an explicit measure. Global storage alone does not demonstrate an actual classical read of its quantum cells. Clarify the global-memory ABI/whole-program boundary before retaining PHYSICS-b; a coherent global bank is a compiler capability gap in a closed program. Other externally visible global escape fixtures should keep their fences while that boundary is established.
* `spec_reject_indirect.ll` does not call a literal null pointer: `getCalledFunction()` is null because its target is a runtime parameter. Its unknown-body verdict can stand, but the audit reason misdescribes the input.
* `lowering_reject_byref_inline_side_effect.ll` and `spec_reject_syscall.ll` call an opaque function with only classical arguments, once, in unconditional flow. The call receives no quantum data. Their PHYSICS-d verdict assumes that ordinary classical effects must themselves be replayed as a quantum lift; separating the classical call from the coherent calculation would avoid that obligation. Resolve this boundary before treating the program as physically forbidden; preserve the current fence against dropping or replaying the effect.
* Weak/interposable visible definitions need an exact-body/linkage proof. That is a fidelity obligation distinct from a declaration-only opaque callee. Do not erase interposition based only on an available body.
* Known LLVM math intrinsics without a current reversible lowering and declaration-only user externs should not be conflated. The latter fit PHYSICS-d; the former need their available semantics and lowering route examined. No libm-name recognizer is authorized by this distinction.

## Authorized followups and execution record

Rewrote the 15 angle/fanout/clobber headers listed in `header_rewrites.txt`. Compared the complete remaining IR and all test directives byte-for-byte before and after: unchanged. All 15 selected lit tests passed (1.24 seconds). Filed recheck issue **zxor** after this run. The runtime census is being measured separately from the historical constant-operand artifacts. Disputed tracker statuses and fixture class TSVs await owner review.

The five owner questions raised here concern native-frem accounting, the CQ sin approximation, nan's denominator, authored substitute slices and decline-to-accept twin transitions. The subsequent owner decisions and both census figures are in [OWNER_RULINGS.md](OWNER_RULINGS.md). Native frem is excluded from credit and its enforcement/source-lowering gap is tracked in 3c6m.68. The exact test-retirement scope remains unresolved; the approximation is retained, both census figures are published, and twin transitions require semantic review before their expectations change.

## Classical sin range check

Compiled the unchanged CQ sin leaf under a temporary renamed symbol and compared it with host libm (LLVM 19, `-O1 -fno-builtin`; separate translation units). `sin_classical_domain.tsv` records all six inputs. At 0.5 and 1e6 the values matched; at 1e20 the CQ leaf returned about +0.707 while host sin was negative. The leaf returned a finite value for infinity and NaN, and changed -0 to +0. This is a classical numerical check, not a quantum simulation or a unitary proof. Its own source documents the Cody–Waite range near 1.65e6; six compiled CQ-provided leaves therefore must not be advertised as full-domain math.h equivalence without a range contract or a replacement reduction.

## Runtime census result

The generated [runtime census](runtime_census.md) measures **131/180 scalar-input cells with pipeline acceptance for every C/Q mixture**: 76/120 real-source injection, 39/42 intrinsic-lowered, 6/6 CQ-provided, and 10/12 macro cells. The six CQ leaves remain range-qualified; this is not a full-domain equivalence claim. Three nan variants have classical-only acceptance and are reported separately. Including those would give 134/183 pipeline-accepted cells, pending the owner denominator ruling. This is within the recalled forecast, but the number comes from the run, not that forecast.

Ran all 483 probes: 391 accepted, 92 declined, zero build/link/runtime failures or compiler crashes. All 183 all-classical probes passed. Every accepted probe linked, trace-ran, and passed the structural free checker. Pointer outputs were consumed and explicitly measured, and signgam was preserved. The modeled macros retain the old f64 scope. No new goldens or independent unitary reviews were performed, so these are acceptance measurements rather than new semantic verification credit.

The original 159/183 constant-input baseline comprised 101 injection, 42 intrinsic, six CQ leaves, ten macros and zero nan cells. The new all-mixture injection row is 76 rather than 101, and the intrinsic row loses all three fma widths because CCQ fails. Several newly uncovered source cells pass QQ but fail CQ/QC: atan2, exponent-scaling functions, pow, nextafter/nexttoward and fdim. Keeping only the both-quantum column would overstate them again.

The separate [native fmod measurement](native_fmod.md) passed all 12 probes (four mixtures per width) via builtin fmod/frem, without source injection. Moving those three cells to the intrinsic row would add three to the scalar acceptance numerator; it does not make the real-source fmod bodies compile. No provider move was made while the owner accounting question is pending.

Completed batch validation: **ctest 585/585** (1235.91 s), **full cq-opt/stock-opt equivalence 2501 comparisons, zero mismatches**, and the code-map check. Fixture body/directive comparison passed for all 15 rewrites. The compiler binary remained byte-identical to the initial audit binary. Counts and per-fixture outcomes are in `validation.json` and `lit_results.tsv`.
