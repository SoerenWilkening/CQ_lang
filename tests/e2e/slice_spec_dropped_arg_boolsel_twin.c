/* slice_spec_dropped_arg_boolsel_twin.c — the HAND-INLINED TWIN of
   slice_spec_dropped_arg_boolsel.c (bd test_C_libtooling-vsfp): the same caller
   with `h`'s classical return written directly (`int t = m + 1;`), single TU, no
   specializer. `clang -O1` deletes the now-dead `p`. Its golden must stay
   byte-identical to the 2-TU slice's (`e2e-spec-dropped-arg-boolsel-twin-identical`)
   — the definition of the correct circuit for a call whose callee never reads the
   quantum argument it is handed. */
__attribute__((noinline)) int slice(int m) {
    _Bool b = cq_theta((_Bool)(m & 1), 0.5);
    int p = b ? 9 : 4;
    int t = m + 1;
    (void) p;
    b = cq_theta(b, 0.7);
    return t + cq_measure(b);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
