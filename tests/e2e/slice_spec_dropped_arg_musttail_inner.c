/* slice_spec_dropped_arg_musttail_inner.c — bd test_C_libtooling-vsfp ROUND 6 / bd
   test_C_libtooling-w7nm (2-TU, run_slice_multi.sh; library TU spec_dropped_arg_musttail_lib.c).
   Rule-13 r5 F-Z-1, probe `mt1`: r2B's `k19` main with `h` forwarding through `musttail`.

   `p = q * 3` is a template rail — a complete which-path record of `q` — that feeds `h`'s dead
   slot and the phase oracle `(p ^ q) == 10`. `h2`'s clone records its slot 0 dead; inside `h`'s
   clone that slot sits on a `musttail` call. Round 5 asked the drop's whole eligibility (which
   refuses `musttail` as a POLICY) in the liveness call-slot rule, so the inner slot counted as a
   read, `h`'s parameter became live, the outer phantom slot was never neutralised, and the spine
   left `p`'s rail DIRTY across `Ry(0.7)` on `q` — bd tzfa's wrong unitary, exit 0, the ORACLE's
   stream byte-for-byte. Round 6 asks only null-soundness there (a constant in a `musttail` slot
   changes no signature), and `e2e-spec-dropped-arg-musttail-inner-twin-identical` pins this
   golden to the hand-inlined twin's: the `mul_i32_hl_unc` and `cqrt_free` of `p` precede the Ry.
   RED on round 5 and on the ORACLE (measured). `m` comes from argv (argc + 4, bd 46oo).
   ⚠ Since bd ev3m (2026-09-28) no clone is built for this program: a `musttail` site is
   drop-eligible, so the pre-specialize drop takes the chain (`h2`'s slot, `h`'s parameter, this
   caller's slot) before `specialize()` runs. The golden is unchanged (the twin's, measured).
   ⚠ Round 1 said the in-clone `musttail` slot is "pinned at IR level only" — FALSE (Rule-13 r1B
   F-r1B-3): since commit C (bd m5pn) a clone's `musttail` is demoted before any slot question, so
   nothing can pin that slot any more; spec_accept_phantom_arg_read_musttail_inner_slot.ll pins the
   generic inner-slot neutralisation on the demoted plain call. */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = m & 7; cq_theta(&q, 0.5);
    int p = q * 3;
    int r = h(p, m);
    int u = p ^ q;
    if (u == 10)
        cq_phi(3.14159);
    cq_theta(&q, 0.7);
    return r + cq_measure(q);
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
