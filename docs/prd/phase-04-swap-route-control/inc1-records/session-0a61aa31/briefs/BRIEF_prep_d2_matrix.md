# BRIEF_prep_d2_matrix — Inc 1 prep (d2): the loop twin matrix under the new surface — ctest entry, POST tables, the 14 new divergences, the guard
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_prep_d_matrix.md`, `$SP/progress/prep_d.md`,
`$SP/progress/review_r1_L5.md` §F-L5-2 and §F-L5-7, and the headers of the three instruments.
Agent name: `prep_d2`. Model: opus.

## Where you work
Worktree `$SP/wt/prep-d`, branch `3qlq-inc1-matrix`, REBASED by the orchestrator onto c4bd888
(Inc 1a + round-1 fixes + Inc 1b). Build it in the background first. SUBJECT = your build; ORACLE =
`$SP/wt/pre-3qlq`. Touch only `tools/{loop,inplace,angle_select}_twin_matrix.py`,
`tools/loop_twin_matrix.expected.txt`, `tools/loop_twin_matrix.quarantine.txt`, the
`e2e-loop-twin-matrix` entry in `tests/e2e/CMakeLists.txt`, and `inc1-records/*_post1.txt`.

## Job
1. **F-L5-7(b):** the void-mode header guard in `loop_twin_matrix.py` (~:1313) is a whitespace-
   sensitive literal that REFUSES the shipped `include/CQ.h` (column-aligned declaration). Make it
   whitespace-insensitive (regex `void\s+cq_phi\s*\(\s*double`) or compile a one-line probe TU;
   exercise the guard against the SHIPPED header and against a register-surface header (must refuse).
2. **F-L5-7(a):** the committed `e2e-loop-twin-matrix` ctest invocation (CMakeLists.txt ~:4263)
   passes no `--phi-surface` and HARNESS-ERRORs 175 cells under the new header. Switch it to
   `--phi-surface void`; the VOID mode becomes the shipped gate. That means: a committed void EXPECTED
   table and a void QUARANTINE. Decide (and write in the header) whether the void mode reads the
   SAME `expected.txt`/`quarantine.txt` files (regenerated) or new `*_void.txt` files; the register
   tables are then HISTORY (keep them for the record under `inc1-records/`, delete from `tools/` if
   the register mode is unreachable against the shipped header — say so).
3. Run the void matrix on the SUBJECT (background, ~4 min). **F-L5-2:** the 14 non-quarantined
   TRACE-DIVERGENCE cells (`m_add_der_add … m_xor_range_rz` — L5 lists them) are the filed
   a3z7/1m5p M-C class as a NEW POPULATION (the oracle DECLINED all 14). They may NOT be recorded as
   expected verdicts. Re-measure on the fixed binary (the round-1 fixes may have moved some — say
   which), then quarantine each surviving one with its class, owning subsystem AND DIRECTION, and the
   SHA-256 of its unified diff, exactly as the existing 15 entries are; the owning bd issue is
   `test_C_libtooling-a3z7` (class B) or `-1m5p` (class A) — determine per cell; if a cell fits
   neither, STOP and report it as a FINDING. Run the quarantine self-test
   (`e2e-loop-twin-quarantine-selftest`) after editing.
4. **POST tables:** commit `inc1-records/{loop,inplace,angle_select}_post1.txt` from the SUBJECT
   (angle_select with `--oracle $SP/wt/pre-3qlq/build/ir-pass/cq-opt`); diff each against its
   `_pre1.txt` and summarize per-verdict deltas in your hand-back. Also take the inplace
   `--stateprep` pool under void (pre AND post are both taken now on the oracle and the subject;
   the pair is committed).
5. `ctest --test-dir build -R 'loop-twin'` must be GREEN (matrix + quarantine self-test). Commit;
   hand back per BRIEF_common with all counts measured.
