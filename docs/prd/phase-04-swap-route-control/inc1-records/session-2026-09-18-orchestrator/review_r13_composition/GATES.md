# GATES — Rule-13 COMPOSITION review, session 2026-09-18

Protocol format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <date time>`

## §6.1 redundancy check, reported as the protocol requires

* **Gates CITED (not re-run):** none. Every line below is `ran:`.
* **Gates RUN:** only the per-probe pipeline (the reviewer's one licensed gate per `PROTOCOL.md`'s
  matrix) plus one read-only fixture sweep (`cq-opt` on each `ir-pass/test/*.ll`, output grepped —
  **not** `ir-pass-lit`, no `lit`, no `ctest`, no build). Before starting, `$SES/GATES_INFLIGHT.md`
  held **no** IN-FLIGHT line for any of these at any of the four hashes.
* **Suites I did not run:** full `ctest`, `ir-pass-lit`, `^e2e-`, `cq-opt-equivalence-full`, the twin
  matrices, the injection matrix, `negative_vacuity_check.py`, the corpus sweep. Reviewer role.

## Binary hashes verified on disk at review open (2026-09-17)

```
9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3  build/ir-pass/cq-opt                                        (ORACLE)
07d937842bfb5135fe068d1b9bfb1b2cd501e67c152bf4932d9408d5c9fed6b4  .claude/worktrees/agent-ac2acfdde3461becc/build/ir-pass/cq-opt (COMBINED)
df2445fcaf82cf00d39eb11165a3c9e9307327c76d459647365b83114cd20898  .claude/worktrees/agent-ad443b9a480ffb751/build/ir-pass/cq-opt (Group 1 alone)
5ee9d14420c3533a3c8958370a3bf3c05375ff34bfa1b0f2db07a93c0989892c  .claude/worktrees/agent-ad7349188dd3b67bd/build/ir-pass/cq-opt (Track D alone)
e951d5d1bc072902e28bc0fd8a5d2adf1468bab100c4f1164c4e8f5f5ed21a7e  .claude/worktrees/p0p3/build/ir-pass/cq-opt                   (P0+P3, NOT USED)
```
All five match the brief character-for-character. Nobody rebuilt the oracle.

## Harness self-attack (run before any probe; `CLAUDE.md` L10)

```
harness-selfattack-empty      | 9bd01598d574b344 | VACUOUS-EMPTY, rc=2      | composition-reviewer | 2026-09-17
harness-selfattack-noquantum  | 9bd01598d574b344 | VACUOUS-NOQUANTUM, rc=2  | composition-reviewer | 2026-09-17
harness-selfattack-empty (re-run after the link-step fix) | 9bd01598d574b344 | VACUOUS-EMPTY, rc=2 | composition-reviewer | 2026-09-17
```
⚠ Two harness defects of my own, both found by reading raw output and both fixed before any recorded
number: (a) `clang … && ./a && echo` scored a probe whose PROGRAM exited non-zero as `LINK/RUN
FAILED`; (b) `echo "exit=$?"` placed after a `$(basename …)` substitution reported basename's status —
ten mover rows re-run in full. Recorded per L10, not as a footnote.

## Per-probe pipeline (`clang -O1 -g` → `cq-opt` → STRICT `free_pairing_check.py` **from the GATE worktree** → link+run)

```
probe dD1                    | 9bd01598d574b344 | opt exit=1, cq controlled lowering: condition predates a non-diagonal gate under quantum control | composition-reviewer | 2026-09-17
probe dD1                    | df2445fcaf82cf00 | opt exit=1, same string                                                                          | composition-reviewer | 2026-09-17
probe dD1                    | 5ee9d14420c3533a | opt exit=0, warning live derived record, 2b: 2 template rail mint(s) of which 1 left dirty, 1 free: 1 verified 0 violation 0 unproven, 20 trace lines | composition-reviewer | 2026-09-17
probe dD1                    | 07d937842bfb5135 | opt exit=0, stderr 0 bytes, 2b: 2 template rail mint(s) of which 0 left dirty, 2 free: 2 verified 0 violation 0 unproven, 22 trace lines | composition-reviewer | 2026-09-17
probe dD4 (unrolled twin)    | 07d937842bfb5135 | opt exit=0, 2b: 3 template rail mint(s) of which 0 left dirty, 3 free: 3 verified 0 unproven, 22 trace lines; MULTISET IDENTICAL to dD1, sole divergence one cqrt_free(h4) position | composition-reviewer | 2026-09-17
probe x1_multiexit           | 9bd01598d574b344 | opt exit=1, condition predates a non-diagonal gate | composition-reviewer | 2026-09-17
probe x1_multiexit           | 07d937842bfb5135 | opt exit=0, stderr 0 bytes, 2b: 0 left dirty, 1 verified 0 violation 1 UNPROVEN, rc=1; -O1 MERGED the two exits into one block | composition-reviewer | 2026-09-17
probe x2_twoexit_goto        | 9bd01598d574b344 | opt exit=1, condition predates a non-diagonal gate | composition-reviewer | 2026-09-17
probe x2_twoexit_goto        | 07d937842bfb5135 | opt exit=0, 0 left dirty, 1 verified 1 UNPROVEN rc=1, 26 trace lines; exits merged again | composition-reviewer | 2026-09-17
probe x3_parent_rotated_inbody | 9bd01598d574b344 / df2445fcaf82cf00 / 5ee9d14420c3533a / 07d937842bfb5135 | opt exit=1 on ALL FOUR, condition predates a non-diagonal gate under quantum control | composition-reviewer | 2026-09-17
probe x3c_parent_rotated_after_loop | 9bd01598d574b344 | opt exit=1 | composition-reviewer | 2026-09-17
probe x3c_parent_rotated_after_loop | df2445fcaf82cf00 | opt exit=1 | composition-reviewer | 2026-09-17
probe x3c_parent_rotated_after_loop | 5ee9d14420c3533a | opt exit=0, 1 left dirty, warning | composition-reviewer | 2026-09-17
probe x3c_parent_rotated_after_loop | 07d937842bfb5135 | opt exit=0, stderr 0 bytes, 0 left dirty, 2 free: 2 verified 0 unproven, 22 trace lines | composition-reviewer | 2026-09-17
probe x4 / x5 (unrolled by -O1) | 5ee9d14420c3533a and 07d937842bfb5135 | opt exit=0, md5 IDENTICAL across the two binaries; recorded as degenerate (no rolled loop survives) | composition-reviewer | 2026-09-17
probe x6_postloop_reader_after_rotation | 9bd01598d574b344 | opt exit=1, condition predates a non-diagonal gate | composition-reviewer | 2026-09-17
probe x6_postloop_reader_after_rotation | df2445fcaf82cf00 | opt exit=1, same | composition-reviewer | 2026-09-17
probe x6_postloop_reader_after_rotation | 5ee9d14420c3533a | opt exit=0, stderr 0 bytes, 3 template rail mint(s) of which 1 LEFT DIRTY, 1 free: 1 verified, md5 8393c3cdcc9aec3e66ab53ff2dc382f4 | composition-reviewer | 2026-09-17
probe x6_postloop_reader_after_rotation | 07d937842bfb5135 | opt exit=0, stderr 0 bytes, 1 LEFT DIRTY, md5 8393c3cdcc9aec3e66ab53ff2dc382f4 (IDENTICAL to D-alone), loop ROLLED confirmed in IR | composition-reviewer | 2026-09-17
probe x7_postloop_reader_before_rotation | 5ee9d14420c3533a and 07d937842bfb5135 | opt exit=0, 0 left dirty, 2 free: 2 verified, md5 e4c9e9f5393e5a1fac0e448931ddea93 on both | composition-reviewer | 2026-09-17
probe x8_g8door_inside_d_region | 9bd01598d574b344 | opt exit=1, condition predates a non-diagonal gate | composition-reviewer | 2026-09-17
probe x8_g8door_inside_d_region | 07d937842bfb5135 | opt exit=1, cq controlled lowering: control flow inside a loop body under quantum control | composition-reviewer | 2026-09-17
probe x9_break_p2_discharged  | 9bd01598d574b344 | opt exit=1, condition predates a non-diagonal gate | composition-reviewer | 2026-09-17
probe x9_break_p2_discharged  | 07d937842bfb5135 | opt exit=0, stderr 0 bytes, 0 left dirty, 2 free: 2 verified 0 unproven, 28 trace lines, 3 trips, single exit block %7 | composition-reviewer | 2026-09-17
probe x10_trailing_controlled_ry | 9bd01598d574b344 and 07d937842bfb5135 | opt exit=1 BOTH, cq controlled lowering: rotation arm shares the condition flag under quantum control | composition-reviewer | 2026-09-17
probe x10b_trailing_controlled_ry_unmeasured | 9bd01598d574b344 | opt exit=1, condition predates a non-diagonal gate | composition-reviewer | 2026-09-17
probe x10b_trailing_controlled_ry_unmeasured | 5ee9d14420c3533a | opt exit=0, 1 left dirty, warning | composition-reviewer | 2026-09-17
probe x10b_trailing_controlled_ry_unmeasured | 07d937842bfb5135 | opt exit=0, stderr 0 bytes, 0 left dirty, 3 free: 3 verified 0 unproven, 29 trace lines | composition-reviewer | 2026-09-17
probe x11_trailing_angle_select | 9bd01598d574b344 and 07d937842bfb5135 | opt exit=1 BOTH, cq controlled lowering: rotation angle under quantum control | composition-reviewer | 2026-09-17
probe x11b_angle_select_ifelse | 9bd01598d574b344 | opt exit=1, condition predates a non-diagonal gate | composition-reviewer | 2026-09-17
probe x11b_angle_select_ifelse | 5ee9d14420c3533a | opt exit=0, 1 left dirty, TWO warnings | composition-reviewer | 2026-09-17
probe x11b_angle_select_ifelse | 07d937842bfb5135 | opt exit=0, stderr 0 bytes, 0 left dirty, 3 free: 3 verified 0 unproven, 28 trace lines | composition-reviewer | 2026-09-17
probe x12_measure_of_derived  | 9bd01598d574b344 | opt exit=1, condition predates a non-diagonal gate | composition-reviewer | 2026-09-17
probe x12_measure_of_derived  | 07d937842bfb5135 | opt exit=0, stderr 0 bytes, 0 left dirty, 2 free: 2 verified 0 unproven, 23 trace lines | composition-reviewer | 2026-09-17
probe x13_two_hoisted_compares | 9bd01598d574b344 | opt exit=1, condition predates a non-diagonal gate | composition-reviewer | 2026-09-17
probe x13_two_hoisted_compares | 07d937842bfb5135 | opt exit=0, stderr 0 bytes, 0 left dirty, 3 free: 3 verified 0 unproven, 29 trace lines, ONE and_unc after both regions of both trips | composition-reviewer | 2026-09-17
probe x14_nested_loop         | 9bd01598d574b344 and 07d937842bfb5135 | opt exit=1 BOTH, condition predates a non-diagonal gate under quantum control | composition-reviewer | 2026-09-17
probe x15_round2_out_feeds_rail | 9bd01598d574b344 | opt exit=1, condition predates a non-diagonal gate | composition-reviewer | 2026-09-17
probe x15_round2_out_feeds_rail | 5ee9d14420c3533a | opt exit=0, 3 template rail mint(s) of which 1 left dirty, 2 free: 2 verified, 33 trace lines | composition-reviewer | 2026-09-17
probe x15_round2_out_feeds_rail | 07d937842bfb5135 | opt exit=0, stderr 0 bytes, 0 left dirty, 3 free: 3 verified 0 unproven, 35 trace lines | composition-reviewer | 2026-09-17
probe g8_arm_use_derived_owned_rot | 9bd01598d574b344 | opt exit=0, TWO warnings, 4 template rail mint(s) of which 2 LEFT DIRTY, 0 cqrt_free sites, 2b rc=0 | composition-reviewer | 2026-09-17
probe g8_arm_use_derived_owned_rot | df2445fcaf82cf00 | opt exit=1, cq loop lowering: rolled body leaks a rail entangled with a rotated register | composition-reviewer | 2026-09-17
probe g8_arm_use_derived_owned_rot | 07d937842bfb5135 | opt exit=1, same string | composition-reviewer | 2026-09-17
probe x16_g8_in_a_second_function | 9bd01598d574b344 | opt exit=0, 1 warning in @leaky, 4 template rails of which 2 left dirty | composition-reviewer | 2026-09-17
probe x16_g8_in_a_second_function | df2445fcaf82cf00 and 07d937842bfb5135 | opt exit=1 BOTH, rolled body leaks a rail entangled with a rotated register, diagnostic names `leaky` | composition-reviewer | 2026-09-17
```

## Track D's 14 movers, COMBINED binary, STRICT stage 2b with (T4)

```
trackD-movers-shipped-9  | 07d937842bfb5135 | 9/9 opt exit=0, 0 warning lines, 2b rc=0, 0 template rails left dirty, 0 unproven, 0 violations | composition-reviewer | 2026-09-17
trackD-movers-probes-5   | 07d937842bfb5135 | 5/5 opt exit=0, 0 warning lines, 2b rc=0, 0 left dirty, 0 unproven, 0 violations (all five exit 1 on the ORACLE with `condition predates a non-diagonal gate under quantum control`) | composition-reviewer | 2026-09-17
```

## (T4) instrument attacks — `tools/free_pairing_check.py` from the GATE worktree

```
t4-switch-backedge-k1     | (checker, not a binary) | 2 verified, 0 violation(s), 0 unproven, rc=0 -- PASSES a K:1 loop-exit discharge. FINDING F-1 | composition-reviewer | 2026-09-17
t4-br-backedge-k1-control | (checker)               | 1 verified, 0 violation(s), 1 unproven, rc=1 -- correctly refused by (T4f)'s own message      | composition-reviewer | 2026-09-17
t4-parse-gap-on-shipped   | 07d937842bfb5135 + checker | lowering_classical_mux_phi_onereg_switch_nway.ll lowered, then parsed with the checker's own parse_module: succ['%entry']=['%merge'], preds['%arm1']=[], preds['%arm2']=[] | composition-reviewer | 2026-09-17
switch-in-lowered-IR sweep | 07d937842bfb5135 | 1045 accepting ir-pass/test fixtures; 1 has a `switch` in the LOWERED IR (lowering_classical_mux_phi_onereg_switch_nway.ll). Read-only grep over cq-opt output; NOT ir-pass-lit | composition-reviewer | 2026-09-17
```

## Item 7 — the owner's loop program (read-only; not modified)

```
owner-grover-loop WALL 1 | 9bd01598d574b344 | opt exit=1, example/grover/grover_oracle_uncompute.c:91:15 in function main i32 (): cq controlled lowering: control flow inside a loop body under quantum control | composition-reviewer | 2026-09-17
owner-grover-loop WALL 1 | 07d937842bfb5135 | opt exit=1, IDENTICAL string and site -- unmoved by this session | composition-reviewer | 2026-09-17
owner-peel1b (guard removed) WALL 2 | 9bd01598d574b344 | opt exit=1, <unknown>:0:0 in function main i32 (): cq loop lowering: loop-carried tainted value crosses iterations (NO !dbg) | composition-reviewer | 2026-09-17
owner-peel1b (guard removed) WALL 2 | 07d937842bfb5135 | opt exit=1, IDENTICAL string, no !dbg -- unmoved | composition-reviewer | 2026-09-17
owner-peel1 (value arm removed) | 9bd01598d574b344 and 07d937842bfb5135 | opt exit=0 BOTH; lowered IR has a ROLLED !llvm.loop body with cqrt_alloc_i1 + cqrt_ry_i1 and a 12-byte handle alloca -- the rail bank; the taint-escape wall SCOPE_loop recorded is GONE | composition-reviewer | 2026-09-17
```
