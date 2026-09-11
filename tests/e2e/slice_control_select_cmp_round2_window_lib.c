/* slice_control_select_cmp_round2_window_lib.c — the classical TU of the Track
   A.1 round-2-window slice (bd test_C_libtooling-9pum). Compiled WITHOUT
   -include CQ.h (run_slice_multi.sh stage 1b), so its arithmetic is plain
   classical C; its only job is to be a callee `clang -O1` cannot inline across
   TUs, which is what makes the caller's `if (q > 5) y = ext_f(7)` a 6.5
   CLASSICAL-CALL ARM and its merge an `%out` rail that only ROUND 2 taints. */
int ext_f(int a) { return a + 100; }
