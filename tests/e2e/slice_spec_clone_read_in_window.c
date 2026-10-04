/* slice_spec_clone_read_in_window.c — bd test_C_libtooling-rhk5 (2-TU,
   run_slice_multi.sh; library TU spec_dropped_arg_lib.c: `h(a, k) = k + 1`).

   Rule-13 r3A F-XA-4's probe `d4.c`. `p = q * 3` and `u = p ^ q` are a derived chain
   whose one consumer is the phase oracle's condition `u == 10`; the M-B interior
   partition discharges both after the flag strip, reading `q` as their BORROWED
   parent. The call `h(m, q)` — lifted to the Phase-6 clone `__cq_q_h_10` — sits
   between the chain and the oracle, i.e. INSIDE that discharge window. Until bd
   rhk5 the spine counted the call as a MUTATION of `q`, so the chain was never
   uncomputed: `3q` and `3q ^ q` stood allocated and ENTANGLED with `q` across
   `Ry(0.7)` (a Rule-8 wrong unitary; `opt` exit 0 with the lyyf-(B) warning; the
   ORACLE's trace has 16 lines and no `xor_i32_unc` / `mul_i32_hl_unc`).
   `cloneCallPreservesArg` now PROVES from the clone body that the call only reads
   `q`, and the chain is discharged before the Ry.

   THE CORRECT CIRCUIT is slice_spec_clone_read_in_window_twin.c (`h` inlined). The
   two goldens are NOT byte-identical and cannot be: the clone's Bennett copy-out
   is four extra lines, and `-O1` sinks the twin's inlined add past the oracle while
   the call stays where it is written. `e2e-spec-clone-read-in-window-twin-equivalent`
   runs tools/trace_twin_equiv.py over the two goldens: SAME CIRCUIT up to the
   Bennett contraction and commuting independent gates.

   `m` is `slice`'s parameter, passed `argc + 4` (argc = 1 under the harness, m = 5);
   `noinline` keeps `clang -O1` from folding it (bd 46oo). */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = m & 7; cq_theta(&q, 0.5);
    int p = q * 3;
    int u = p ^ q;
    int s = h(m, q);
    if (u == 10)
        cq_phi(3.14159);
    int ms = cq_measure(s);
    cq_theta(&q, 0.7);
    return ms + cq_measure(q);
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
