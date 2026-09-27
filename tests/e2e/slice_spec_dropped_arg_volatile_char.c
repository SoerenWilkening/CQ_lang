/* slice_spec_dropped_arg_volatile_char.c — bd test_C_libtooling-vsfp ROUND 2 / bd
   test_C_libtooling-a8q5 (2-TU, run_slice_multi.sh; library TU
   spec_dropped_arg_volatile_lib.c: `h(a, k) { volatile char z = a; return k + 1; }`).

   The caller is slice_spec_dropped_arg_boolsel.c verbatim; only the library differs.
   `p = b ? 9 : 4` feeds only `h`'s first parameter, which the library stores to a
   `volatile char` and never reads. On the oracle AND on bd vsfp round 1 the fenv
   pre-pass erased the store but kept its `trunc`, so the parameter still had a use,
   the drop and the backstop both stayed silent, and the 4.4 `%out` rail copying `b`
   stayed allocated and entangled across `b = cq_theta(b, 0.7)` — exit 0, no warning,
   stage 2b STRICT clean, P(b=1) 0.8356 instead of cos^2(.6) = 0.6812 for odd m.

   Under the fenv ruling this program MEANS the one without the volatile line, i.e.
   slice_spec_dropped_arg_boolsel_twin.c, and
   `e2e-spec-dropped-arg-volatile-char-twin-identical` pins this golden BYTE-IDENTICAL
   to that twin's: Ry(0.5) then Ry(0.7) on ONE handle and its measurement. (That gate
   compares two committed goldens; what is RED on the oracle is this slice's own entry,
   whose 2-TU trace carries the copy block — measured.)

   `m` is `slice`'s parameter, passed `argc + 4` (argc = 1 under the harness, so m
   = 5 and `b` starts |1>); `noinline` keeps `clang -O1` from folding it (bd 46oo).
   `main` discards the result so the slice exits 0 under the harness's `pipefail`. */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    _Bool b = cq_theta((_Bool)(m & 1), 0.5);
    int p = b ? 9 : 4;
    int t = h(p, m);
    b = cq_theta(b, 0.7);
    return t + cq_measure(b);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
