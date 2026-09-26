/* slice_spec_lift_quantum_base.c — bd test_C_libtooling-d88e, the SPEC-QUANTUM
   positive control, end to end (2-TU, run_slice_multi.sh; library TU
   spec_lift_quantum_lib.c: `h(a, k) = a + k`).

   The exact caller of the d88e decline family
   (ir-pass/test/lowering_reject_classical_mux_phi_spec_scrubbed_base.ll) with a
   library whose clone returns a QUANTUM handle. `t = h(q, m)` really is a register,
   so `declineClassicalMuxes`' one-register lift of `r = phi(t, cq_theta(t, .2))`
   is a true renaming, its re-ask after `specialize()` finds the premise intact,
   and the arm's Ry fires IN PLACE on the clone's returned handle, which the user
   measures. The golden pins that stream: no fresh rail in the arm, ONE
   `cqrt_measure` of the handle the clone returned.

   `m` is `slice`'s parameter, passed `argc + 4` (argc = 1 under the harness, so
   m = 5 and the arm runs); `noinline` keeps `clang -O1` from folding the
   classical condition away (bd 46oo). `main` discards the result so the slice
   exits 0 under the harness's `pipefail`. */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int t = h(q, m);
    int r = t;
    if (m > 3) r = cq_theta(t, 0.2);
    return cq_measure(r);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
