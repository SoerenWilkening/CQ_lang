/* spec_reading_f2_lib.c — bd test_C_libtooling-cepm, library TU 3 of 4. `f3` is an
   external here, so a call to `f2` (inside `g`) is a liveness root as well. */
int f3(int a);
int f2(int a) { return f3(a) + 1; }
