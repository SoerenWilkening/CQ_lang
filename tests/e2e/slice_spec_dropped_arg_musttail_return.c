/* slice_spec_dropped_arg_musttail_return.c — bd test_C_libtooling-ev3m (2-TU, run_slice_multi.sh;
   library TU spec_dropped_arg_musttail_return_lib.c). r5 `mt2` / r6 `mm1`, the residual of bd 9bhg.

   `w` is a quantum function that ENDS in a `musttail` call forwarding `p = q * 3` — a complete
   which-path record of `q` — to `h2`, which ignores it (its only read is the condition of an arm
   that reads a never-stored internal volatile global: dead once the fenv stages ran). Before bd
   ev3m the dead-argument drop refused a `musttail` SITE as a POLICY conservatism, so the call kept
   reading `p`, its result stayed conservatively tainted, and the module DECLINED
   `cq taint escape: quantum value returned across a function boundary` — while the plain-`tail`
   spelling and the hand-inlined twin compile. Now the drop writes `0` into the `musttail` slot (an
   operand change: no signature, calling convention or ABI attribute moves), `w` returns a
   classical value, and `p` is discharged before the `Ry(0.7)` on `q` exactly as in the twin
   (`e2e-spec-dropped-arg-musttail-return-twin-identical`). RED on the ORACLE (main 9a230646:
   the 3jru decline, measured). `m` comes from argv (argc + 4, bd 46oo). */
int h2(int a, int k);

__attribute__((noinline)) int w(int m, int k) {
    int q = m & 7; cq_theta(&q, 0.5);
    int p = q * 3;
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    cq_theta(&q, 0.7);
    int z = cq_measure(q);
    __attribute__((musttail)) return h2(p, k + z);
}

/* The result is USED, exactly as r6 `mm1`'s `return w(m, m);`: the 3jru refusal speaks only for a
   call whose result has a use (`declineQuantumReturnCalls`). `w` returns `k + z + 1` and the trace
   runtime's `cqrt_measure` returns 0, so `main` exits 0 (run_slice*.sh runs under `pipefail`); a
   store to a sink instead would decline on the ORACLE at the store refusal, not at 3jru. */
int main(int argc, char **argv) {
    (void)argv;
    return w(argc + 4, argc) - argc - 1;
}
