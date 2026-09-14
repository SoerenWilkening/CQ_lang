/* ⚠ UNREGISTERED SINCE 2026-09-14 together with its caller (bd
   test_C_libtooling-3d8q, owner ruling 2026-09-14). Nothing in
   `tests/e2e/CMakeLists.txt` references this file any more; it is kept only so
   that `slice_control_select_bool_round2_window.c` remains a compilable
   two-TU record. See that file's header for the full disposition and for the
   lit fixture that now pins the decline. */
/* slice_control_select_bool_round2_window_lib.c — the classical TU of the
   bd test_C_libtooling-r9e5 round-2-window slice. Compiled WITHOUT -include
   CQ.h (run_slice_multi.sh stage 1b), so its arithmetic is plain classical C;
   its only job is to be a callee `clang -O1` cannot inline across TUs, which is
   what makes the caller's `if (q > 5) y = ext_f(7)` a 6.5 CLASSICAL-CALL ARM and
   its merge an `%out` rail that only ROUND 2 taints. */
int ext_f(int a) { return a + 100; }
