/* 3qlq Inc 1: migrated to register-free cq_phi -- the if/else arms lose their register (P2 angle select).
   NOTE: PRD S3 retires the 2b BY-DIFFERENCE lowering for the Rz stem -- the new form
   is `x(f); rz_i1(f,B); x(f); rz_i1(f,A)`, exact, no subtraction and no 2^-40 fence.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_angle_select_rz.c — ANGLE-SELECT BY DIFFERENCE, `cq_phi` (Rz)
   stem, at the LINK layer (bd test_C_libtooling-drbq Increment 2b).

       if (q == 5) cq_phi(0.9); else cq_phi(0.3);

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
    if (q == 5) cq_phi(0.9);
    else        cq_phi(0.3);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
