# Track R probes — F2's collider set: the peel CLONE (bd `rb9x`) and `vd`'s collider

**Every row below was measured on the session ORACLE on 2026-09-13**, read-only: nothing was
built, no suite was run (PROTOCOL.md row "scoping").

```
shasum -a 256 build/ir-pass/cq-opt      -> fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661
shasum -a 256 build/ir-pass/libCQPass.so-> 40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93
git log -1 --format=%h                  -> 01c89b5   (docs-only over the pass at e96f89c)
```

Run everything, from the REPO ROOT (the script re-checks the ORACLE hash and STOPS if it moved):

```
docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/trackR/probes/run.sh
CQDBG=1 …/trackR/probes/run.sh r_R1_clone_unpinned_operand.ll      # one probe, with its anchor
…/trackR/probes/surgery_vd.sh                                      # the three vd.c IR surgeries
```

Per probe the script runs exactly the PROTOCOL.md pipeline: `clang -O1 -g` → `cq-opt
-passes=cq-lowering` → (accepts only) `tools/free_pairing_check.py` → link `libcq_templates.a`
before `libcq_runtime.a` → run. `CQDBG=1` adds the `CQ_CTRL_DBG=1` anchor line for each decline.

Prefixes: `b_` = the 2026-09-11 integration-review baseline re-run here (copied verbatim from
`../../session-2026-09-11-orchestrator/review_integration_probes/`), `v_` = the `vd` family,
`r_` = route isolation, `w_` = the rivals F2 exists to refuse.

## Verdict table (36 probes = 14 `b_` + 11 `r_` + 6 `v_` + 5 `w_`, plus 3 surgeries)

`ls b_* v_* r_* w_* | grep -E '\.(c|ll)$' | wc -l` -> 36; of those **9 ACCEPT** (all STRICT stage 2b
`0 violation(s), 0 unproven`, all linked and ran) and **27 DECLINE**.

Diagnostics are quoted to the `cq …` prefix; every one is `DS_Error`, `opt` exit 1.
`F2` = `cq controlled lowering: state prep seed is proven equal to the condition register under
quantum control`.

| probe | shape | verdict | anchor (`CQ_CTRL_DBG=1`) / reading |
|---|---|---|---|
| `b_HP_f_nopeel.ll` | `int` compare cond, `i1` prep φ, **no clone** | **ACCEPT** 9 lines, 2b `1 verified, 0 violation(s), 0 unproven` | the control: the region's own compare IS in `CondWire` |
| `b_HP_g_sel_only.ll` | + ONE `%clone = icmp eq i32 %1, 1` in the merge, no select | DECLINE **F2** | `%2 = icmp eq i32 %1, 1` |
| `b_HP_a_clone.ll` | clone variant | DECLINE F2 | `%2 = icmp eq i32 %1, 1` |
| `b_HP_b_orig.ll` | the region's own compare given a data use | DECLINE `condition data use neither escaped nor measured` | fires BEFORE F2 |
| `b_HP_c_merge.ll` | clone + select (the peel's exact output) | DECLINE F2 | `%2 = icmp eq i32 %1, 1` |
| `b_HP_d_unpinned_clone.ll` | clone `icmp sgt %1, 1` | DECLINE F2 | predicate-independent |
| `b_HP_e_other_const.ll` | clone `icmp eq %1, 77` | DECLINE F2 | constant-independent |
| `b_P1_intcmp_i1seed_singlephi.c` | plain C, `int b0` / `bool b1`, ONE merge φ | **ACCEPT** 9 | no peel ⇒ no clone |
| `b_P1t_seed_true.c` | the same, seed `true` | **ACCEPT** 9 | |
| `b_P2_intcmp_i1seed_peeled.c` | + one peelable `int a` φ | DECLINE F2 | `%2 = icmp eq i32 %1, 1` |
| `b_P2t_seed_true_peeled.c` | the same, seed `true` | DECLINE F2 | BOTH seeds collide — one per edge |
| `b_A_intb0_boolb1.c` | the owner's file, `int b0` / `bool b1` | DECLINE F2 | `%2 = icmp eq i32 %1, 1` — bd `rb9x` |
| `b_B_boolb0_intb1.c` | `bool b0` / `int b1` | **ACCEPT** 19 | |
| `b_C_intb0_intb1.c` | `int b0` / `int b1` | **ACCEPT** 22 | |
| `v_vd.c` | 3 bools, 3 regions (`slice_control_cascade_three_bools` candidate) | DECLINE **F2** | `%1 = … @cq_theta_i1(false, 5.0e-01)` = the b0 RAIL condition, `vd.c:10:14` |
| `v_vd_two_regions.c` | `vd` minus the b2 region (= the owner's file 2026-09-13) | DECLINE `control flow` | `%7 = select i1 %5, i32 %6, i32 %cq.peel.mux` — **Track M's wall**, confirmed |
| `v_vd_guard_neg.c` | `vd` with the third guard `a >= -5` | DECLINE `control flow` | the F2 collider neutralised IN C ⇒ only M's wall is left |
| `v_vd_no_b1_arm.c` | `vd` minus `if (b1) a -= 3` | DECLINE `control flow` | NOT a clean separation: `-O1` then FUSES the b1 and b2 preps into one arm (2 non-peelable φ). Use `r_R6a` for the separation |
| `v_vd_intb0.c` | `vd` with `int b0` | DECLINE `condition data use neither escaped nor measured` | an earlier fence, not F2 |
| `v_vd_allint.c` | `vd` all-`int` | DECLINE `condition data use neither escaped nor measured` | idem |
| `r_R1_clone_unpinned_operand.ll` | clone's operand is a SECOND rail, unpinned on both edges | **ACCEPT** 16 | ⇒ the clone is reached as a USER of a PINNED value |
| `r_R1b_clone_pinned_operand.ll` | same module, clone's operand = the condition's rail | DECLINE F2 | the control for R1 |
| `r_R3_asym_seed_false.ll` | cond `sgt %1,0`, clone `eq %1,5`, seed `false` | DECLINE F2 | only the FALSE edge can fold the clone, and only to `false` |
| `r_R3t_asym_seed_true.ll` | the same, seed `true` | **ACCEPT** 12 | ⇒ the pin is `ConstantRange` forward reasoning on the OPERAND's edge range |
| `r_R4_i32seed_i1clone.ll` | `i32` seed 0 + the i1 clone + `zext i1 %clone to i32` | DECLINE F2 | **CONFOUND, and a finding**: the collider is the `zext`, itself pinned to `i32 0` |
| `r_R4b_i32seed_i32collider.ll` | `i32` seed 0, post-branch `add %1,-1` pinned to 0 | DECLINE F2 | F2 bites at i32 too (the control for R4c) |
| `r_R4c_i32seed_i1clone_nozext.ll` | R4 with the `zext` removed (i1 measure instead) | **ACCEPT** 11 | ⇒ `:1616`'s `getType() == Seed->getType()` is why rb9x is a `_Bool`-only defect |
| `r_R5_clone_before_branch.ll` | the second compare placed in ENTRY, before the `br` | DECLINE F2 | an exclusion must cover both positions |
| `r_R6a_downstream_cmp_data.ll` | `vd`'s collider class, minimal, NO peel, flag used as DATA | DECLINE F2 | anchor = the `cq_theta_i1` rail condition. **The clean separation from M's wall** |
| `r_R6b_downstream_cmp_branch.ll` | the same, flag used as a second region's BRANCH condition (= `vd`) | DECLINE F2 | anchor = the rail condition |
| `r_R6c_edge_isolation.ll` | R6a with the mux `2`→`9` | **ACCEPT** 20 | ⇒ the pin is on the **TRUE** edge of `br i1 %1` |
| `w_W1_rival_flag_rotated.c` | `bool c=(b0==1); if (c) b1=cq_theta(c,.5)` | DECLINE `state prep seed does not match the merge incoming` | **F1**, not `condition data use` as bd `rb9x` predicted: `-O1` folds the arm's `c` to `true` against a `false` pred incoming |
| `w_W2_rival_downstream_guard_rotated.c` | the arm rotates the downstream guard, guard still branched on | DECLINE `control flow` | no lowering to be robbed of |
| `w_W3_rival_data_flag_rotated.c` | the same, guard consumed as DATA only | DECLINE `control flow` | idem |
| `w_W4_sink_probe.c` | the rival, asked for its `-O1` image | DECLINE `control flow` | IR: the compare is GONE (`%3 = xor i1 %1, true`), the arm KEEPS the register, the downstream branch reads `%1` |
| `w_W5_secondflag_rival_fold.c` | the program `…_second_flag_i1.ll` says it is `-O1`'s image of | DECLINE `control flow` | IR: `-O1` neither folds the arm's `%2` to a constant NOR sinks the compare — **one spelling, not a proof** |
| surgery `S1_cmp_true` | `vd` IR, guard `sgt %8,2`→`sgt %8,-5` | F2 GONE → `control flow` | identification |
| surgery `S2_cmp_mixed` | `vd` IR, guard → `sgt %8,0` | F2 GONE → `control flow` | identification |
| surgery `S3_seed_true` | `vd` IR, the b1 prep's seed → `true` | F2 GONE → `control flow` | the pinned constant is `false` |

`# work dir` on the last line of each run names the scratch dir holding every `*.s1.ll` /
`*.s2.ll` if you want to read the lowered IR.
