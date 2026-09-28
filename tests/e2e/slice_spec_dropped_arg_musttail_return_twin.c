/* slice_spec_dropped_arg_musttail_return_twin.c — the HAND-INLINED, fenv-intended TWIN of
   slice_spec_dropped_arg_musttail_return.c (bd test_C_libtooling-ev3m; r5 `mt2T`): `h2`'s classical
   return written directly (`k + z + 1`), single TU, no specializer. Its golden must stay
   byte-identical to the 2-TU slice's (`e2e-spec-dropped-arg-musttail-return-twin-identical`). */
__attribute__((noinline)) int w(int m, int k) {
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    q = cq_theta(q, 0.7);
    int z = cq_measure(q);
    return k + z + 1;
}

/* The result is USED, exactly as r6 `mm1`'s `return w(m, m);`: the 3jru refusal speaks only for a
   call whose result has a use (`declineQuantumReturnCalls`). `w` returns `k + z + 1` and the trace
   runtime's `cqrt_measure` returns 0, so `main` exits 0 (run_slice*.sh runs under `pipefail`); a
   store to a sink instead would decline on the ORACLE at the store refusal, not at 3jru. */
int main(int argc, char **argv) {
    (void)argv;
    return w(argc + 4, argc) - argc - 1;
}
