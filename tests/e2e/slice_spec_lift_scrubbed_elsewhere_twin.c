/* slice_spec_lift_scrubbed_elsewhere_twin.c — the HAND-INLINED TWIN of
   slice_spec_lift_scrubbed_elsewhere.c (bd test_C_libtooling-d88e): the same
   caller with `h`'s classical return written directly (`int t = m + 1;`), single
   TU, no specializer. Its golden must stay byte-identical to the 2-TU slice's
   (`e2e-spec-lift-scrubbed-elsewhere-twin-identical`) — the definition of the
   correct circuit for a module whose Phase-6 call result the specializer proves
   classical. */
__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int t = m + 1;
    int r = q;
    if (m > 3) r = cq_theta(q, 0.2);
    return cq_measure(r) + t;
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
