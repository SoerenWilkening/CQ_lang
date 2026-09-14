/* slice_control_phase_mergephi_ifelse.c — bd `3qps` (Track P). The IF/ELSE form
   over a prep merge phi, and it exists to put the NON-NEGOTIABLE through the
   LINK layer: the else arm fires on `b1 == 0` and is emitted as the DIAGONAL
   `cqrt_rz_i1(h1, -0.11)`, NEVER as a `cqrt_x` bracket on the user's register.

   The identity is `X.P(t).X = diag(e^it, 1) = e^it . P(-t)` — the same unitary up
   to a GLOBAL phase, which owner decision D2 already declares unobservable (an
   uncontrolled `cq_phi` is DELETED on exactly that ground). `fneg` is exact in
   IEEE for every double, so no rounding class is introduced.

   The golden therefore contains ZERO `cqrt_x`, ZERO `cqrt_free` and ZERO
   `cq_template_` lines: nothing is minted for either arm. */
int slice(void) {
    _Bool b0 = cq_theta((_Bool)0, 0.5);
    _Bool b1 = 0;
    if (b0) { b1 = cq_theta(b1, 0.5); }
    if (b1) { cq_phi(0.3); cq_phi(0.7); } else { cq_phi(0.11); }
    return (int) cq_measure(b0) + (int) cq_measure(b1);
}
int main(void) { (void) slice(); return 0; }
