# cascade_reproducers — the four shapes `example/grover/grover_oracle_uncompute.c` went through on 2026-09-06/07, measured on `main` b731015

Basis for `docs/prd/phase-04-swap-route-control/HANDOFF_controlled_cascade_2026-09-10.md`. Single-TU programs; run with
`tools/show_pipeline.sh <file>` or the session harness. `lines` = trace lines. `user_file_as_of_2026-09-10.c` is the
example as it stood when this record was written (`example/` is git-excluded locally, so this copy is the only committed one).

| file | what | verdict on `main` b731015 |
|---|---|---|
| `c1_dead_prep_arm.c` | state-prep arm whose result `b` is never read (the arm call survives `-O1`, no merge phi) | DECLINE `cq controlled lowering: control flow under quantum control` |
| `c2_prep_seed_equals_compare.c` | genuine prep of `b`, seed 0, under `a == 0` | DECLINE `cq controlled lowering: state prep seed is proven equal to the condition register under quantum control` (drbq Inc-4 fence F2, PRD §14.11 Q1) |
| `c2a_prep_seed1_ACCEPTS.c` | same, seed 1 | ACCEPT, 9 lines (`cqrt_alloc_i32(1)` hoisted + `cqrt_ry_i32_controlled`) |
| `c2b_prep_b_quantum_ACCEPTS.c` | same, `b` quantum before the region | ACCEPT, 10 lines (controlled Ry on a disjoint register) |
| `c3_bool_bare_i1_condition.c` | `bool b0`: the select's condition is the bare tainted `i1` register, no compare | DECLINE `control flow under quantum control` (bd 3qlq.4) |
| `c3a_int_ACCEPTS.c` | same with `int b0` | ACCEPT, 14 lines (4.4 select merge over the constants 5 / 2) |
| `c4_cascade.c` | the two-step cascade with `a` the classical constant 5 | DECLINE `control flow under quantum control` — `-O1` folds `a >= 3` into `b0 != 0` and fuses both steps into ONE region (a two-instruction arm, two merge phis, a select on a merged `i1`) |
| `c4a_cascade_measure_b1_too.c` | same, `b1` also measured | DECLINE, same string (the fold does not depend on `b1`'s liveness) |
| `c4b_cascade_a_quantum.c` | the same cascade with `a` a quantum register (`cq_theta(a0, 0.2)`) | **ACCEPT, 33 lines — two onward regions, the cascade as intended** |
| `c4c_cascade_a_rail_zero_angle.c` | `int a = cq_theta(5, 0.0)` — a rail carrying 5 under an identity rotation, cascade otherwise as written | **ACCEPT, 33 lines, trace identical to `c4b` modulo the first Ry angle** |
| `user_file_as_of_2026-09-10.c` | the example as it stood on 2026-09-10 (`if (a >= 3) cq_phi(0.5)` under a quantum `a`) | ACCEPT, 7 lines (kickback) |
