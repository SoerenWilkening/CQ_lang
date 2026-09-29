/* slice_control_inplace_ry_loop_ifelse_unrolled.c — the HAND-UNROLLED twin of
   `slice_control_inplace_ry_loop_ifelse.c` (bd test_C_libtooling-fmt3,
   2026-09-28): the same three trips written out as three flat if/else regions,
   each lowered by the flat in-place Ry arm's if/else form (the `nomerge` header
   keeps each if/else an if/else). `e2e-inplace-ry-loop-ifelse-twin-identical`
   requires the two goldens to be byte-identical. STRICT stage 2b. */
int slice(void) {
    int q = 0;
    int r = 7;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);

    if ((q & 6) == 4) r = cq_theta(r, 0.9);
    else              r = cq_theta(r, 0.3);
    q = cq_theta(q, 0.1);

    if ((q & 6) == 4) r = cq_theta(r, 0.9);
    else              r = cq_theta(r, 0.3);
    q = cq_theta(q, 0.1);

    if ((q & 6) == 4) r = cq_theta(r, 0.9);
    else              r = cq_theta(r, 0.3);
    q = cq_theta(q, 0.1);

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
