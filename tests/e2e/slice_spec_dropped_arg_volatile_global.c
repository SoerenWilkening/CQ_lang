/* slice_spec_dropped_arg_volatile_global.c — bd test_C_libtooling-vsfp ROUND 3 / bd
   test_C_libtooling-tzfa + bd test_C_libtooling-stl3 (2-TU, run_slice_multi.sh; library TU
   spec_dropped_arg_volatile_global_lib.c: `h(a, k) { if (a > 3) (void)K; return k + 1; }`
   with `K` a never-stored internal volatile global).

   Rule-13 r2B's headline `k19`. `p = q * 3` is a template rail that is a complete
   which-path record of `q`; it feeds `h`'s dead slot AND the phase oracle's condition
   `(p ^ q) == 10`. On bd vsfp round 2 the phantom read survived to `specialize()` (the
   emptied diamond kept `a` live in the original `h`), the backstop let it through because
   `p` had another reader, and the phantom clone call left the uncompute spine one
   consumer too many: `p`'s rail was never uncomputed, so `q` was fully dephased before
   `Ry(0.7)` and the oracle's phase was erased (exit 0, one generic warning, 2b STRICT
   clean). The ORACLE emits the same wrong stream; round 1 declined.

   Under the fenv ruling this program MEANS slice_spec_dropped_arg_volatile_global_twin.c
   (`h` inlined, the volatile read gone), and
   `e2e-spec-dropped-arg-volatile-global-twin-identical` pins this golden byte-identical
   to the twin's: the `mul_i32_hl_unc` and `cqrt_free` of `p` precede the second Ry.
   What is RED on round 2 and on the oracle is this slice's own entry (measured).

   `m` is `slice`'s parameter, passed `argc + 4` (argc = 1 under the harness, m = 5);
   `noinline` keeps `clang -O1` from folding it (bd 46oo). `main` discards the result. */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m & 7, 0.5);
    int p = q * 3;
    int r = h(p, m);
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    q = cq_theta(q, 0.7);
    return r + cq_measure(q);
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
