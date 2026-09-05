/* onward_perbit_mixed_lib.c — the classical second TU for
   `slice_control_phase_onward_perbit_loop_mixed{,_unrolled}.c` (bd
   test_C_libtooling-3qlq Inc 1, the SECOND C-1 review round, finding F-C1-2).

   A pure, visible, un-inlined classical callee is what makes the caller's
   `if (q > 5) y = ext_f(7);` a Phase-6.5 CLASSICAL-CALL ARM: the call is hoisted
   into the pred and its i32 result route-merged into a fresh `%out` rail. `%out`
   is quantum-by-control, and its ONWARD consumers are classical at round 1 —
   which is what makes the loop below a ROUND-2 region. Compiled WITHOUT
   `-include CQ.h` by `run_slice_multi.sh` (C18 trap 1). */
int ext_f(int a) { return a + 100; }
