/* slice_control_inplace_ry_loop_derived_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_inplace_ry_loop_derived.c (ctest
   `e2e-inplace-ry-loop-derived-twin-identical`). */
int slice(void) {
    int q = 0;
    int r = 7;

    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);

    if ((q & 6) == 4) { cq_theta(&r, 0.9); }
    cq_theta(&q, 0.1);

    if ((q & 6) == 4) { cq_theta(&r, 0.9); }
    cq_theta(&q, 0.1);

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
