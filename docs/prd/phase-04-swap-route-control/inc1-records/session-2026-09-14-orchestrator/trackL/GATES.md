# Track L (scoping, 2026-09-14) — GATES.md

Per `$SES/PROTOCOL.md`: a gate result is a fact about a BINARY. Format
`<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>`.

The scoping row of the gate-ownership matrix runs **NO build, NO `lit`, NO `ctest`, NO corpus sweep,
NO injection matrix**. Its one instrument is the per-probe pipeline. Every line below is `ran:`.

oracle-hash-check | f7b65d8ccd7bc472 | cq-opt f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc, libCQPass.so f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d — MATCH the brief | trackL-scope | 2026-09-14 10:12
per-probe a_loop_n2/n3/n8/n3_noarm/n3_uncond | f7b65d8ccd7bc472 | exit 1, `cq taint escape: tainted value stored to memory` at each (N-independent; a_loop_n3_uncond at col 14, the rest col 26) | trackL-scope | 2026-09-14 10:20
per-probe a_flat_n2 | f7b65d8ccd7bc472 | exit 0; 115 lowered lines; free_pairing_check STRICT `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`; 29 trace lines; gate stream == tests/e2e/slice_control_cascade_two_bools.expected.log (only the cqrt_measure_i32 line's position differs) | trackL-scope | 2026-09-14 10:22
per-probe a_flat_n3 | f7b65d8ccd7bc472 | exit 1, `cq controlled lowering: state prep seed is proven equal to the condition register under quantum control` (bd om35) | trackL-scope | 2026-09-14 10:22
per-probe L1_promoted_nostore | f7b65d8ccd7bc472 | exit 1, `cq controlled lowering: control flow inside a loop body under quantum control`; CQ_CTRL_DBG anchor `%6 = icmp sgt i32 %5, 2` (= ArmClassify.cpp:4396-4397, R7's loop half) | trackL-scope | 2026-09-14 10:31
per-probe L1_promoted_store | f7b65d8ccd7bc472 | exit 1, `cq taint escape: tainted value stored to memory` (col 14); its clang -O1 IR carries the merge phi + ONE trailing store = the carve's target shape | trackL-scope | 2026-09-14 10:31
per-probe L2_prep_only / L5_prep_only_phase | f7b65d8ccd7bc472 | exit 0, 9 trace lines each — DEGENERATE: clang -O1 folds `a>=3` (a never modified), no region in the IR. Not citable as an in-loop prep accept | trackL-scope | 2026-09-14 10:35
per-probe L3_uncond_prep_value / L6_good_prep_value_arm | f7b65d8ccd7bc472 | exit 1, `cq loop lowering: loop-carried tainted value crosses iterations` (LoopLowering.cpp:2106-2110, X1) — two independent spellings | trackL-scope | 2026-09-14 10:35
per-probe L4_uncond_prep_phase / L11_promoted_phase_classcond | f7b65d8ccd7bc472 | exit 0, 9 / 12 trace lines, 2b `1 (resp. 2) rail mint(s) … 0 violation(s), 0 unproven` — the in-loop controls | trackL-scope | 2026-09-14 10:35
per-probe L9_array_phase_arm / L10_promoted_phase_nostore | f7b65d8ccd7bc472 | exit 1, `tainted value stored to memory` / `cq controlled lowering: nested control flow under quantum control` — a phase arm adds a third wall | trackL-scope | 2026-09-14 10:40
per-probe L12/L13_flat_n2_opaque* , L14, L15 | f7b65d8ccd7bc472 | exit 1, `cq controlled lowering: control flow under quantum control`; CQ_CTRL_DBG anchor the data select. Discriminated: the OPAQUE SEED, not the select's arms (L14 const-arms declines identically) | trackL-scope | 2026-09-14 10:45
per-probe L7_array_uninit / L8_array_int_cells | f7b65d8ccd7bc472 | exit 1, `tainted value stored to memory` — the Track U composition and the ABI-width axis are both unreachable at the wall today | trackL-scope | 2026-09-14 10:40
per-probe N1_vla_bound / N2_escaping_array / N3_global_array | f7b65d8ccd7bc472 | exit 1, `tainted value stored to memory` (all three) — the clause-1 negatives | trackL-scope | 2026-09-14 10:52
per-probe N4_tainted_index | f7b65d8ccd7bc472 | exit 1, `cq QRAM access: array address has aliasing fan-out` — 7.5's own string on 7.5's own path; the axes are already separated | trackL-scope | 2026-09-14 10:52
per-probe N5_double_write | f7b65d8ccd7bc472 | exit 1, `cq controlled lowering: arm rewrites a condition operand under quantum control` — DEGENERATE (constant index ⇒ SROA ⇒ scalar spelling (ii) ⇒ bd x5fp). Not the clause-2' negative | trackL-scope | 2026-09-14 10:52
per-probe N5b_noninjective_var_index | f7b65d8ccd7bc472 | exit 1, `tainted value stored to memory`; 4 alloca/gep lines survive -O1 — the REAL clause-2' (injectivity) negative | trackL-scope | 2026-09-14 10:55
tree counts (file/grep, no ctest) | n/a — source tree at 607b6fe4 | `ls ir-pass/test/*.ll` 1928; `ls tests/e2e/*.expected.log` 367; twin cells 259+29=288; `grep -c bool tools/loop_twin_matrix.py` 2; fixtures pinning kMsgStore 31, `control flow inside a loop body` 28, kMsgCrossIter 9 | trackL-scope | 2026-09-14 11:05
cost calibration (git --numstat, no build) | n/a — source tree at 607b6fe4 | pass source (ir-pass/src+include, runtime, tools) — 94c085e +231/-107; 59ac5b7 +463/-74; e96f89c +764/-38; 3a3a2b9 +1212/-17 | trackL-scope | 2026-09-14 11:08
