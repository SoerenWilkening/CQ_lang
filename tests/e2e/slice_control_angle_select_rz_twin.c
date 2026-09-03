/* slice_control_angle_select_rz_twin.c — the MANUAL by-difference twin of
   `slice_control_angle_select_rz.c` (bd test_C_libtooling-drbq Increment 2b).

       r = cq_phi(r, 0.3);
       if (q == 5) r = cq_phi(r, 0.9 - 0.3);

   An ordinary in-place Rz diamond — the drbq Increment-2a peephole's own shape,
   which lowered on the pre-2b binary. */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    r = cq_phi(r, 0.3);
    if (q == 5) r = cq_phi(r, 0.9 - 0.3);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
