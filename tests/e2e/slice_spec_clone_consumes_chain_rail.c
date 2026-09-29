/* slice_spec_clone_consumes_chain_rail.c — bd test_C_libtooling-rhk5, the OWNED-rail
   half (2-TU, run_slice_multi.sh; library TU spec_dropped_arg_lib.c: `h(a, k) = k + 1`).

   Family member `f02`. The clone call reads the chain rail `p = 3q` ITSELF, so it is
   a CONSUMER of a rail the M-B interior partition owns. `isInteriorConsumer` listed a
   clone call among the consumers that DISQUALIFY a rail, so `3q` could not be
   discharged, and the component owning `3q ^ q` then refused the same call as a
   mutation of its borrowed parent `3q`: both rails stood entangled with `q` across
   `Ry(0.7)` on the ORACLE (warned). Both predicates now ask `cloneCallPreservesArg`.

   THE CORRECT CIRCUIT is slice_spec_clone_consumes_chain_rail_twin.c (`s = p + 1`);
   `e2e-spec-clone-consumes-chain-rail-twin-equivalent` compares the goldens.
   `m = argc + 4 = 5` under the harness (bd 46oo). */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int u = p ^ q;
    int s = h(m, p);
    if (u == 10)
        cq_phi(3.14159);
    int ms = cq_measure(s);
    q = cq_theta(q, 0.7);
    return ms + cq_measure(q);
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
