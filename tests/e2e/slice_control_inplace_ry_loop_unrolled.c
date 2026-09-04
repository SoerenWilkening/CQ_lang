/* slice_control_inplace_ry_loop_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_inplace_ry_loop.c (two trips written out, no loop).

   This is the ORACLE, not a second test: it is the FLAT Increment-1 lowering,
   which shipped and was adversarially cleared. Its golden must equal the rolled
   slice's byte for byte (ctest `e2e-inplace-ry-loop-twin-identical`). Read the
   rolled slice's header for the blind spot this gate does NOT cover. */
int slice(void) {
    int q = 0;
    int r = 7;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);

    if (q == 5) { r = cq_theta(r, 0.9); }
    q = cq_phi(q, 0.1);

    if (q == 5) { r = cq_theta(r, 0.9); }
    q = cq_phi(q, 0.1);

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
