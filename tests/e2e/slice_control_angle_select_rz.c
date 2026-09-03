/* slice_control_angle_select_rz.c — ANGLE-SELECT BY DIFFERENCE, `cq_phi` (Rz)
   stem, at the LINK layer (bd test_C_libtooling-drbq Increment 2b).

       if (q == 5) r = cq_phi(r, 0.9); else r = cq_phi(r, 0.3);

   The by-difference identity holds for Rz too, and EXACTLY rather than up to a
   phase: under this project's `Rz = diag(1, e^{i.theta})` convention the two
   diagonals multiply entrywise, so `Rz(0.3)·Rz(0.6) = Rz(0.9)` with no
   global-phase residue. The emitted gate is the drbq Increment-2a in-place
   `cqrt_rz_i32_controlled`, so this stem adds no frozen symbol and reuses the
   2a peephole's machinery unchanged.

   Its twin `slice_control_angle_select_rz_twin.c` is an in-place Rz DIAMOND,
   which the PRE-2b binary lowered via the 2a peephole;
   `e2e-angle-select-rz-twin-identical` compares the goldens. STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    if (q == 5) r = cq_phi(r, 0.9);
    else        r = cq_phi(r, 0.3);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
