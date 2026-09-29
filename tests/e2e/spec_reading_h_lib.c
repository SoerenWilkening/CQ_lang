/* spec_reading_h_lib.c — bd test_C_libtooling-cepm: the READING callee, library TU 1 of 4.
   `h` READS its argument `a` (a call to `g`, an external in this TU, so `clang -O1`
   keeps the call) and returns the CLASSICAL `k + 1`. bd vsfp's dead-argument drop
   does NOT apply: the call to `g` is a liveness root (see spec_reading_g_lib.c). */
void g(int a);
int h(int a, int k) { g(a); return k + 1; }
