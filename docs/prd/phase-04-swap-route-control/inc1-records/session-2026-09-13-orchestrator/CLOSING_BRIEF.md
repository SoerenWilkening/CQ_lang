# Closing brief — step 5 after the LAST landing: rebuild the primary, gate once, re-measure every count, run the owner's file

Model: opus. Checkout `/Users/sorenwilkening/Desktop/CQ_lang` (`main` at the hash the orchestrator gives you =
the last squash). Until now its `build/` was the frozen ORACLE (`fbbe0820…`); **you are the one agent
allowed to rebuild it**, exactly once, and nothing else may be measuring against it (the orchestrator
guarantees no other agent is running). Never `pkill` by pattern. Report only what you ran.

1. `shasum -a 256 build/ir-pass/cq-opt` BEFORE (must be `fbbe0820ef4b176a…` — record) and AFTER.
2. `cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release &&
   cmake --build build -j8` (BOTH targets).
3. **Full `ctest --test-dir build -j6 --output-on-failure`** ONCE — pass line + wall time; re-run any
   failure serially before calling it a regression.
4. `cmake --build build --target cq-opt-equivalence-full` ONCE (owed: three landings changed decline
   strings / analysis sites).
5. Counts BY COMMAND: `ls ir-pass/test/*.ll | wc -l`; `ls tests/e2e/*.expected.log | wc -l`;
   `ctest --test-dir build -N | tail -1`; `ctest --test-dir build -N -R '^e2e-' | tail -1`;
   `… -R '^e2e-slice-'`; `… -R twin-identical`; `grep -c '^add_test' tests/e2e/CMakeLists.txt`;
   `grep -c '^m_' tools/loop_twin_matrix.expected.txt`; `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt`.
6. The owner's REAL file: `./tools/show_pipeline.sh example/grover/grover_oracle_uncompute.c` (git-excluded;
   if it differs from `$SES/probes/owner_file_2026-09-13.c`, `diff` them and report the difference FIRST —
   the owner may have edited it again). Record exit code, stderr byte count, the STRICT 2b line, the full
   trace into `$SES/owner_file_final.trace`, and `diff` against `tests/e2e/slice_control_cascade_two_bools.expected.log`.
7. Also on the rebuilt primary: `$SES/probes/{va,vb,vc,vd}.c`, `$SES/trackC/probes/owner_2026-09-11_2218.c`,
   `$SES/trackR/probes/b_A_intb0_boolb1.c`, `$SES/trackL/probes/a_loop_n3.c` (the loop form — still the
   taint-escape string; record) — one line each: verdict, line count, 2b.
8. Write `$SES/CLOSING_MEASUREMENTS.md` with every command and its output verbatim (this is the source the
   docs pass quotes), and append to a new `$SES/GATES.md` (session-level) the full-suite and equivalence
   lines keyed to the NEW primary hash.

Final message ≤25 lines: the two hashes, the full-ctest line + time, equivalence, the nine counts, the
owner's-file line (exit/stderr/2b/lines/diff), the seven probe lines.
