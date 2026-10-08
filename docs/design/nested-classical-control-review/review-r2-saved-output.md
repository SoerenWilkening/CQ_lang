# R2 saved-output audit of the serial batch failures

Disposition for the 13 focused IR fixtures: no lowering regression identified. Twelve failures are stale literal SSA assertions or the exact gate-string twin comparison; one is a sound acceptance-direction migration requiring positive semantic checks. This is an analytic classification of saved output, not a rerun or a claim that edited assertions pass.

Counts: 0 tests, 0 builds, 0 probes, 0 mutants, 0 cq-opt executions. Repository files unchanged.

## 1. Seed literal freezes: exact assertion adaptation

The bare fixture parameters have no noundef contract. A marked function now stabilizes such scalar runtime literals at entry. The saved IR keeps the same allocations, rotations, operations, predicate polarity, source widths and copies; allocation consumes the frozen seed.

For each seed check, bind the freeze and then use its SSA value:

```llvm
; CHECK: %[[SEED:[a-zA-Z0-9_.]+]] = freeze i32 %u
; CHECK: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[SEED]])
```

Use the actual seed name and type, preserving existing bound quantum handle Q everywhere else. Keep a CHECK-LABEL for each function where the fixture has several subjects. In QROM fixtures the freeze precedes the table allocation, so its check must precede the table-handle check.

Exact affected assertion positions:

| Fixture | Original failing line | Adaptation |
|---|---:|---|
| control_predmux_accept_selectform_curated_total.ll | 59 | freeze i32 %u, then alloc_i32 with SEED; keep intrinsic result R in the shielded compare |
| control_predmux_accept_i80_cmp_arm.ll | 64 | freeze x86_fp80 %u0, then alloc_f80 with SEED |
| control_predmux_accept_i80_cmp_purecallee.ll | 92 | same f80 seed binding; retain f80 copies and i80 clone compare/mask bindings |
| control_predmux_accept_i80_cmp_purecallee_transitive.ll | 77 | same f80 seed binding; retain both clones and the inner uncompute twin |
| control_predmux_accept_qrom_read_masked.ll | 45 | freeze i32 %u0 before table CHECK, alloc_i32 consumes SEED |
| control_predmux_accept_qrom_jumptable.ll | 43 | same i32 seed binding |
| control_predmux_accept_qrom_mask_narrow_source.ll | 73,104,137,329,384 | seed type respectively i8,i16,i8,i32,i32; bind SEED in each corresponding function |
| control_predmux_accept_qrom_mask_width_bounds.ll | 46,76,101 | seed type respectively i8,i32,i32; bind SEED before each table allocation |

The remaining QROM narrow/wide mask sequences in the saved IR still match the intended widths: i8/i16 masks followed by only the required zext-to-i32 brackets; i32 direct masked loads; wide masks only when a narrow mask cannot represent N-1. Both forward and inverse mask operands remain the same quantum handles. Do not wildcard or remove those checks.

## 2. Load literal freezes

`control_predmux_accept_flat_classical_table_masked.ll:58-59` and `control_predmux_accept_inloop_classical_table.ll:64-65` now use `%z.stable` and `%p.stable`. The actual load instructions and their pointer/index expressions remain, and the freeze stays immediately after each load (per iteration for the loop case). Bind each load's freeze and check the gate consumes that exact value:

```llvm
; CHECK-DAG: %[[ZF:[a-zA-Z0-9_.]+]] = freeze i32 %z
; CHECK-DAG: call i32 @cq_template_sub_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[ZF]])
; CHECK-DAG: %[[PF:[a-zA-Z0-9_.]+]] = freeze i32 %p
; CHECK-DAG: call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[PF]])
```

Keep the existing load/branch/absence-of-QRAM expectations. A load is conservatively unproven by the context-free definedness walk; freezing its scalar result does not change the result of any defined load or repair an invalid memory access. This is literal stabilization, not a new memory-lowering route.

`control_predmux_accept_qrom_mask_narrow_source.ll:201`, subject zext_i1_n1, similarly needs the existing loaded V to feed its freeze:

```llvm
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = load i32, ptr %[[G]], align 4
; CHECK-NEXT: %[[VF:[a-zA-Z0-9_.]+]] = freeze i32 %[[V]]
; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32_hl(
; CHECK: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[VF]])
```

Its table-of-one classical load and subsequent controlled copy remain the existing mechanism.

## 3. Exact gate-string twins

Saved `.a.gates` and `.b.gates` for these fixtures differ only at the first allocation operand:

- `control_predmux_accept_inloop_value_diamond.ll`: `%u0.stable` versus `%u0`.
- `control_predmux_accept_rail_leaf_boolalg.ll`: `%u.stable` versus `%u`.

No operation, order, copy source, flag, width or free differs. The manually flattened twin does not have the speculative function mark, so no entry seed freeze is requested there.

The smallest subject-preserving fixture correction is to declare the seed parameter noundef in BOTH original and twin fixtures. These tests concern the conditional diamond/boolean-algebra lowering and are meant to compare defined input seeds; normal Clang C scalar parameters already have that contract. This preserves exact gate comparisons. Alternatively, explicitly verify the introduced freeze and canonicalize only its checked SSA alias in the gate extraction. Do not discard gate operands or broadly normalize all SSA names: they pin merge-source correctness.

## 4. Genuine acceptance migration: i80 pure-callee defined cone

`control_predmux_reject_i80_cmp_purecallee_conedef.ll` is no longer a negative. Its exact branchless leaf is:

`leaf(a) = zext_i32((zext_i80(a) AND 0xffffffff) == 555)`.

Every operation is defined for every defined i32 input; there is no memory, partial shift/cast/division, branch, cycle, constant poison or constrained argument. The new total-call proof therefore provides precisely the defined-result property whose absence caused removal of the old lax pure-body S4 disjunct. The body can be lifted for quantum q without inlining and uses the existing zext/and/i80 constant-compare/cast route.

Let `c = (q > 3) AND (leaf(q) > 0)`. The first result is q+7 on c and q otherwise; the second is 3q on c and q otherwise; the final result adds those two merges. Since leaf(q) is the indicator of q==555, this is a valid coherent basis function. The source guard's shielded operand is defined on every newly observed input, so select(a,b,false) -> and(a,b) is valid.

Migrate the fixture to positive RUN and binding checks, mirroring the strength of curated_total: bind Q allocation, R = call @__cq_q_leaf_1(Q), arm ADD(Q,7), arm MUL(Q,3), compare A(Q,3), compare B(R,0), zero G and Toffoli(A,B,G). First merge must copy ADD on G and Q on its negation; second merge must copy MUL on its own conjunction flag and Q on negation. Strip compare B using R, never Q. Pin the clone's actual i32->i80 zext, mask, compare to555, zext back to i32 and mechanical reversal/zero-before-free. The old DBG assertion requiring E6-condtree must be removed or changed to absence of leave for this positive subject. Preserve the neighboring retpoison/inherentpoison/poison-immarg negative fixtures.

## Scope

Inspected current CODE_MAP owners, the focused fixture source, saved serial batch diagnostics and saved `.cqd0.ll`, `.twin.ll`, `.a.gates` and `.b.gates` artifacts. All proposed assertion changes are derived from those artifacts and analytic source reasoning. No batch rerun is authorized or implied by this report; follow the issue-specific checkpoint budget for any newly tracked regression corrections.
