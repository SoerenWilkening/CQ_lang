# Track R — gate ledger (PROTOCOL.md: a gate result is a fact about a BINARY, not a moment)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`

per-probe pipeline (36 probes, ORACLE) | fbbe0820ef4b176a | 9 ACCEPT (all STRICT stage 2b `0 violation(s), 0 unproven`, all linked and ran), 27 DECLINE; full table in probes/README.md | scoping-R | 2026-09-13 12:06
per-probe pipeline (3 vd IR surgeries, ORACLE) | fbbe0820ef4b176a | S1/S2/S3: F2 gone, all three -> `control flow` | scoping-R | 2026-09-13 12:08
per-probe pipeline (24 R-2 rival-audit probes, ORACLE) | fbbe0820ef4b176a | 5 ACCEPT (all STRICT stage 2b `0 violation(s), 0 unproven`; LINKFAIL expected — the probes define @example, not @main), 19 DECLINE; full table in probes/r2/README.md | scoping-R2 | 2026-09-13 13:05

Not run by this agent (scoping row): any build, `lit`, any `ctest`, the corpus sweep, the
injection matrix, the twin matrices.
build worktree (cmake --build build -j8, BOTH targets), UNMODIFIED | fbbe0820ef4b176a | BYTE-IDENTICAL to the session ORACLE on cq-opt AND libCQPass.so (40e9c7a5...) -> the 36-probe scoping row above is a fact about this binary and was CITED, not re-run | impl-R1 | 2026-09-13 12:10
build worktree (cmake --build build -j8, BOTH targets), R-1 APPLIED | 221c1caa465db61e | libCQPass.so 818becd47c9a0650; comment-only re-edit + rebuild reproduced BOTH hashes exactly (objects did recompile: header 12:37:24, ArmClassify.cpp.o 12:38:04) | impl-R1 | 2026-09-13 12:39
per-probe pipeline (36 probes, SUBJECT) | 221c1caa465db61e | 12 ACCEPT / 24 DECLINE: 3 MOVED vs ORACLE (b_A 22 lines, b_P2 20, b_P2t 20 — all F2 -> ACCEPT, all STRICT 2b `0 violation(s), 0 unproven`); 33 unchanged line-count for line-count; table in probes/impl/subject_probes.txt | impl-R1 | 2026-09-13 12:24
lit --filter, the 7 new + 2 touched fixtures | 221c1caa465db61e | 9/9 PASS (2 accepts, 5 declines, 2 header-only) | impl-R1 | 2026-09-13 12:36
ctest -R ir-pass-lit | 221c1caa465db61e | Passed 41.34s; `lit ir-pass/test` = 1900 discovered, 1899 Passed, 1 Expectedly Failed (the standing XFAIL), 0 Failed | impl-R1 | 2026-09-13 13:06
ctest -R '^e2e-slice-control-stateprep-bool-under-int-compare-fused$' | 221c1caa465db61e | 1/1 Passed 1.79s (22 trace lines, STRICT stage 2b `4 verified, 0 violation(s), 0 unproven`) | impl-R1 | 2026-09-13 12:44
injection (mutation) matrix over the 2 new accepts | 221c1caa465db61e | fixtures=2 mutations=10 MISSED=0 DIRTY=0 n/a=0; probes/impl/injection_matrix.txt | impl-R1 | 2026-09-13 12:50
corpus sweep ORACLE-vs-SUBJECT | 221c1caa465db61e | rows=2949, movers=12 (10 F2->ACCEPT, 2 F2->a later DECLINE), accept-on-ORACLE-with-a-different-lowered-IR = 0; probes/impl/corpus_221c1caa.txt | impl-R1 | 2026-09-13 13:02
IR surgery: the 3 two-diamond bisect modules | 221c1caa465db61e + fbbe0820ef4b176a | td1 declines `control flow` on BOTH; td_aonly and td_bonly each ACCEPT on BOTH (SCOPE 3b unreachable at HEAD) | impl-R1 | 2026-09-13 12:31
IR surgery: O3 with the bool prep removed (o3_noprep.c) | 221c1caa465db61e + fbbe0820ef4b176a | lowered IR md5 9ce7d45e75e212a8721ac831d32bdca3 on BOTH binaries — the quantum-incoming mux is pre-existing 4.4 behaviour, untouched | impl-R1 | 2026-09-13 13:04

Not run by this agent (implementation row): `ctest -j6 -R '^e2e-'`, the full `ctest -j6`,
`cq-opt-equivalence-full`, the twin matrices, the duplicate-body fixture scan.
⚠ A decline STRING and an analysis site DID change behaviour (F2's accept predicate), so the
merge-and-gate agent owes `cq-opt-equivalence-full` per PROTOCOL.md's "iff a decline string /
analysis site changed" row, plus the one full `ctest -j6`.

build worktree after `git merge main` (9361826) + the 2 comment-only review items, BOTH targets | 2563baa4125bfd5f | libCQPass.so 885b8e119207b3c2; 53.838 s; 0 conflicts to resolve (the predicted CMakeLists add/add did not fire — disjoint anchors, union verified 393+1+7=401 add_test) | merge-R1 | 2026-09-13 13:22
FULL ctest --test-dir build -j6 --output-on-failure (ONCE) | 2563baa4125bfd5f | `100% tests passed, 0 tests failed out of 411`; `Total Test time (real) = 417.79 sec`; ir-pass-lit 68.49s, frontend-lit 5.07s, e2e-loop-twin-matrix 231.52s; no failure, nothing re-run serially | merge-R1 | 2026-09-13 13:30
cq-opt-equivalence-full (OWED — an analysis site changed) | 2563baa4125bfd5f | `cq_opt_equivalence: compared 1908 fixtures, 0 mismatch(es)` (93.82 s) | merge-R1 | 2026-09-13 13:32
corpus sweep ORACLE-vs-MERGED | 2563baa4125bfd5f | rows=3051 over 3062 files; oracle_accepts=1513 merged_accepts=1546; movers=35 visible (10 F2->ACCEPT, 2 F2->a later DECLINE, 23 21mg->ACCEPT) + 3 invisible to the string recipe = 38; ACCEPT->DECLINE = 0; both-accept-with-a-different-lowered-IR = 0; probes/merge/corpus_2563baa4.txt | merge-R1 | 2026-09-13 13:36
decline-side FULL-STDERR delta (F-R1: the recipe's `cq [a-z0-9 ]+:` tag renders the whole cq_measure_<sfx> family as an empty `D:`, so a D->D string change is INVISIBLE — 84 rows read D:/D:) | 2563baa4125bfd5f | 1537 decline rows re-run on both binaries, full stderr + exit byte-compared: 38 differ = the 35 visible movers + 3 invisible, all 3 landing 1's declared `operand is an undef/poison literal` string (c6_undef_bool.c, i0_poison_operand.ll, lowering_reject_measure_undef_operand.ll), each re-run SERIALLY to confirm; 0 R-1-string rows hidden; probes/merge/decline_delta_2563baa4.txt | merge-R1 | 2026-09-13 13:38
STRICT stage 2b over all 33 accepting movers | 2563baa4125bfd5f | 33/33 `0 violation(s), 0 unproven`; probes/merge/stage2b_movers_2563baa4.txt | merge-R1 | 2026-09-13 13:39
duplicate-body fixture scan (sha-256 over non-comment lines) | 2563baa4125bfd5f | files=1908, same-body groups=9 — all 9 the ones MERGE_C_1 §2 enumerated; R-1's 7 new fixtures add none; 0 renames on either side, 0 merge artefacts | merge-R1 | 2026-09-13 13:39
customers | 2563baa4125bfd5f | b_A_intb0_boolb1.c ACCEPT 22 lines BYTE-IDENTICAL to slice_control_stateprep_bool_under_int_compare_fused.expected.log (2b 2 verified 0/0); va.c 19 lines = va.trace; owner_2026-09-11_2218.c 15 lines = slice_measure_classical_bool.expected.log; owner_file_2026-09-13.c DECLINE `control flow` (Track M); vd.c + v_vd.c DECLINE F2 (R-2 not folded in) | merge-R1 | 2026-09-13 13:40
counts | 2563baa4125bfd5f | ir-pass/test/*.ll 1908; tests/e2e/*.expected.log 361; ctest -N 411; ^e2e- 401; ^e2e-slice- 359; twin-identical 32; add_test 401; twin matrix 259+29=288 | merge-R1 | 2026-09-13 13:40

Not run by this agent (merge-and-gate row): the injection matrix (an implementation-row gate, and
`MISSED=0 @ 221c1caa` is a fact about the PRE-merge binary — neither re-run nor cited for 2563baa4),
any second full suite, any bd write, the squash, the push.
