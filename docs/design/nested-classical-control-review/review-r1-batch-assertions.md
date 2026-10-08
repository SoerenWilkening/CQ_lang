# R1 saved-output assertion audit

Analytic review only: 0 tests, 0 builds, 0 probes, 0 cq-opt executions, 0 mutants. Repository files were not edited. All output cited is from the saved serial batch, not a rerun of the current taint correction or edited assertions.

## Findings

`lowering_invert_add_i32.ll` is an expected XFAIL, not an unexpected batch failure. The batch log records `XFAIL` at line 3613; the `failed-ir.txt` extraction included it by matching the substring FAIL. Its saved output still contains both inversion markers and a forward `cqrt_addc_i32`. Keep its XFAIL and inversion assertions unchanged. Do not migrate this compiler gap to acceptance or weaken the required inverse spelling.

The other three specifically requested fixtures have literal SSA/adjacency drift. Their saved output retains the quantum operations, source widths, control polarity and copy/strip order. Assertion edits should bind required freezes and their exact consumers, retaining original input signatures. Do not replace CHECK-NEXT with an unbounded CHECK to skip a freeze, accept raw-or-frozen alternatives, or add noundef to eliminate the case being checked.

## lowering_volatile_scalar_promote_runtime.ll

The runtime promoted value is still classical and remains the fmul literal, now `%rt.stable = freeze double %rt`. The original `%rt` has no noundef contract. The saved output also has the entry `%u0.stable` feeding the seed allocation. The minimally required correction is:

```diff
-; CHECK:     call i32 @cq_template_fmul_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double %rt)
+; CHECK:     %[[RTF:[a-zA-Z0-9_.]+]] = freeze double %rt
+; CHECK:     call i32 @cq_template_fmul_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double %[[RTF]])
```

Preserve the source `define double @probe(double %u0, double %rt)` and the source store's `%rt`. An in-flight parent edit accidentally changed the signature alone to `%rt.stable`, leaving `%rt` undefined in the source; that was reported immediately and must be restored. `.stable` is an output assertion, not a source parameter rename.

For an explicit seed proof, these checks can precede the fmul check after the RTF freeze check; the artifact places RTF before the seed freeze:

```llvm
; CHECK: %[[UF:[a-zA-Z0-9_.]+]] = freeze double %u0
; CHECK: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %[[UF]])
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: call i32 @cq_template_fmul_f64_hl(i32 %[[Q]], double %[[RTF]])
```

The existing controlled-copy, measure and volatile-elimination assertions remain. No allocation of the classical runtime value is introduced.

## condtree_classical_leaf_accept_predmux_ruleb.ll

The saved stream has entry freezes for x/y, one freeze of `%g = icmp eq %m,%n`, and one freeze of the later classical De Morgan compare `%V20 = icmp ne %m,%n`. Both classical boolean literals are shared between their corresponding forward and inverse gates. The correct minimal adaptations, with all surrounding CHECK-NEXT gates retained, are:

```diff
 ; CHECK: entry:
+; CHECK-DAG: %[[XF:[a-z0-9_.]+]] = freeze i32 %x
+; CHECK-DAG: %[[YF:[a-z0-9_.]+]] = freeze i32 %y
 ; CHECK: %[[V0:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
 ...
 ; CHECK-NEXT: %g = icmp eq i32 %m, %n
+; CHECK-NEXT: %[[GF:[a-z0-9_.]+]] = freeze i1 %g
 ; CHECK-NEXT: %[[V1:[a-z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[V0]], i32 0)
-; CHECK-NEXT: %[[V2:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V1]], i1 zeroext %g)
+; CHECK-NEXT: %[[V2:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V1]], i1 zeroext %[[GF]])
 ...
-; CHECK-NEXT: %[[V6:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
+; CHECK-NEXT: %[[V6:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[XF]])
 ...
-; CHECK-NEXT: %[[V7:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y)
+; CHECK-NEXT: %[[V7:[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[YF]])
 ...
-; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V2]], i32 %[[V1]], i1 zeroext %g)
+; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V2]], i32 %[[V1]], i1 zeroext %[[GF]])
 ...
-; CHECK-NEXT: %[[V9:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V8]], i1 zeroext %g)
+; CHECK-NEXT: %[[V9:[a-z0-9_.]+]] = call i32 @cq_template_and_i1_hl(i32 %[[V8]], i1 zeroext %[[GF]])
 ...
-; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V9]], i32 %[[V8]], i1 zeroext %g)
+; CHECK-NEXT: call void @cq_template_and_i1_hl_unc(i32 %[[V9]], i32 %[[V8]], i1 zeroext %[[GF]])
 ...
 ; CHECK-NEXT: %[[V20:[a-z0-9_.]+]] = icmp ne i32 %m, %n
+; CHECK-NEXT: %[[NF:[a-z0-9_.]+]] = freeze i1 %[[V20]]
 ...
-; CHECK-NEXT: %[[V22:[a-z0-9_.]+]] = call i32 @cq_template_or_i1_hl(i32 %[[V21]], i1 zeroext %[[V20]])
+; CHECK-NEXT: %[[V22:[a-z0-9_.]+]] = call i32 @cq_template_or_i1_hl(i32 %[[V21]], i1 zeroext %[[NF]])
 ...
-; CHECK-NEXT: call void @cq_template_or_i1_hl_unc(i32 %[[V22]], i32 %[[V21]], i1 zeroext %[[V20]])
+; CHECK-NEXT: call void @cq_template_or_i1_hl_unc(i32 %[[V22]], i32 %[[V21]], i1 zeroext %[[NF]])
```

The current parent diff already applies the equivalent exact x.stable/y.stable checks and GF/NF captures. These agree with the saved IR. Keep the long copy/Toffoli/strip/free chain intact.

## predmux_guarded_vla_reject_row13_hybrid_select.ll

One per-iteration freeze follows the guarded load and supplies both operations. This must stay downstream of the pointer guard: freezing a load result does not make an invalid memory access safe. Keep the existing address select and immediately following load checks and insert the exact dependency:

```diff
 ; CHECK:      %cq.gr.addr = select i1 %cq.gr.inb, ptr %cq.gr.cell, ptr @cq.guarded.read.zero
 ; CHECK-NEXT: %[[LD:[0-9]+]] = load i32, ptr %cq.gr.addr
-; CHECK-NEXT: %[[OPA:h_op[0-9]*]] = call i32 @cq_template_add_i32_hl(i32 %[[A:[0-9]+]], i32 %[[LD]])
-; CHECK-NEXT: %[[OPZ:h_op[0-9]*]] = call i32 @cq_template_sub_i32_hl(i32 %[[Z:[0-9]+]], i32 %[[LD]])
+; CHECK-NEXT: %[[LDF:[a-z0-9_.]+]] = freeze i32 %[[LD]]
+; CHECK-NEXT: %[[OPA:h_op[0-9]*]] = call i32 @cq_template_add_i32_hl(i32 %[[A:[0-9]+]], i32 %[[LDF]])
+; CHECK-NEXT: %[[OPZ:h_op[0-9]*]] = call i32 @cq_template_sub_i32_hl(i32 %[[Z:[0-9]+]], i32 %[[LDF]])
```

The saved name is `%.stable`, so the capture must permit a leading dot. Preserve noundef on the existing extent parameters; `%LIT = icmp eq %1,%0` remains defined and does not need a freeze. Preserve both control networks, both uses of LIT in each network's strip, guards, absence of Toffoli, count-two assertions and absence of freeing the borrowed H.

## Other saved seed/adjacency failures outside R2's focused list

For a bare seed argument, insert `CHECK: %[[SEEDF:[a-zA-Z0-9_.]+]] = freeze TYPE %ARG` before its allocation check and replace only the allocation operand with `%[[SEEDF]]`. Preserve the existing handle capture (Q, H or the literal `%h`) and all its consumers. These saved artifacts each contain precisely that freeze-to-allocation dependency at the first failing allocation assertion:

| Fixture | Original line | Type / argument |
|---|---:|---|
| control_predmux_accept_w6_direct_condphi.ll | 64 | i32 / u0 |
| control_predmux_accept_i1phi_final_merge.ll | 38 | i32 / u0 |
| control_predmux_accept_xor_negation.ll | 64 | i32 / u0 |
| control_predmux_accept_xor_kept_cone_no_orphan.ll | 75 | i32 / u0 |
| control_predmux_accept_i1phi_branch_cond.ll | 67 | i32 / u0 |
| control_predmux_accept_dag_join.ll | 48 | i32 / u0 |
| control_predmux_accept_w6_stranded_merge_condphi.ll | 89 | i32 / u0 |
| control_predmux_accept_willtaint_cmp_over_phi.ll | 71 | i32 / u0 |
| control_predmux_accept_aliased_leaf.ll | 41 | i32 / u0 |
| control_predmux_accept_nested_value_chain.ll | 49 | i32 / u0 |
| control_predmux_accept_twophi_merge.ll | 37 | i32 / u0 |
| control_predmux_accept_nested_shortcircuit_claim_order.ll | 71 | i32 / u0 |
| control_predmux_accept_armbody_flags_stripped.ll | 83 | i32 / u |
| control_predmux_accept_i1phi_branch_chained.ll | 71 | i32 / u0 |
| control_predmux_accept_i1phi_const_folds.ll | 48 | i32 / u0 |
| control_predmux_accept_i1phi_cond.ll | 47 | i32 / u0 |
| control_predmux_accept_nested_value.ll | 43 | i32 / u0 |
| control_predmux_accept_switch_nested_arm.ll | 44 | i32 / u0 |
| control_predmux_accept_compound_negation.ll | 35 | i32 / u0 |
| control_predmux_accept_i1phi_branch_in_andtree.ll | 79 | i32 / u0 |
| control_predmux_accept_unreachable_dead_body.ll | 56 | i32 / u0 |
| control_predmux_accept_unreachable_default_switch.ll | 62 | i32 / u0 |
| control_predmux_accept_i1phi_branch_allconst.ll | 74 | i32 / u0 |
| control_predmux_accept_i1phi_cond_fp.ll | 41 | double / u0 |
| control_predmux_accept_selectchain_foldresidue.ll | 55 | i32 / u0 |
| control_predmux_accept_i1phi_data.ll | 43 | i32 / u0 |
| control_predmux_accept_staircase.ll | 45 | i64 / u0 |
| control_predmux_accept_seq_siblings.ll | 45 | i32 / u0 |
| control_predmux_accept_fp_mini_lround.ll | 35 | double / u0 |
| control_predmux_accept_selectchain_loopphi_residue.ll | 58 | i32 / u0 |
| control_predmux_accept_straightthrough_value_arm.ll | 89 | i32 / u0 |

This table identifies the stale assertion only; it does not claim subsequent current checks pass or silently classify all negative acceptance migrations. Those negative fixtures need separate semantic derivations.

The flag-preservation fixture's saved seed is still `add nuw nsw i32 %u,1`, immediately followed by `freeze i32 %seed` then allocation. Insert the freeze CHECK-NEXT and allocate its capture; do not strip the seed flags. The in-cone flags-stripped and retattr-dropped fixtures respectively have `%cc.stable` and `%pc.stable`; bind each freeze immediately after the already-checked classical result and require its exact gate literal. Keep existing global flag/range negatives, original noundef signatures and exact classical operations. Parent has applied these equivalent changes in the current diff.

In `spec_accept_clone_classical_leaf.ll`, bind `freeze i1 C2` after its compare and use that capture in both and_i1 forward and mirrored `_unc` calls. In `spec_accept_clone_classical_scope.ll`, bind entry `CS = freeze i32 %c` and use CS in CC and both arithmetic gates and their inverse calls; retain the later existing selector freeze. In `spec_accept_clone_quantum_in_classical_region.ll`, CS supplies **all** classical uses, including `NC = sub i32 0,CS`, the GE compare, both handle-literal gates and inverses. The saved GE result stays unfrozen because it is defined from CS; preserve the existing later CC selector freeze. Parent's current diff had left NC referencing raw c; this exact missing replacement was reported.

Two exact gate-string twin fixtures should retain their original seed parameter contracts if the requirement is to preserve poison coverage. Add positive checks for the speculative subject's frozen seed, then canonicalize only that checked allocation operand alias in its extracted gate stream for the source/twin comparison. Do not normalize other gate operands, mask flags, handles or order. Adding noundef to both fixtures is a narrowing of their inputs, even though it leaves their original defined-input purpose intact; this tradeoff was reported to parent.

## Scope and limits

Read current CODE_MAP owners, focused source fixtures, saved batch diagnostics and saved IR artifacts, plus the current in-flight parent fixture diff. No lowering or checking commands were executed. The current taint/Freeze negation correction was separately reviewed analytically; this report makes no post-correction execution claim.
