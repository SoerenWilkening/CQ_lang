/* slice_spec_dropped_arg_inplace.c — bd test_C_libtooling-hgwx (the WARNED sibling
   of bd vsfp; d88e probe `j02C`), end to end (2-TU, run_slice_multi.sh; library TU
   spec_dropped_arg_lib.c: `h(a, k) = k + 1`, `a` unread).

   On `main` aee8f4f8 the clone call `h(q, m)` never read `q` but still counted as a
   PRIOR USE of it, so M-C's G7 refused `u = t + q` in place: a fresh
   `cq_template_add_i32_hl` rail took the Ry(0.2) while `q` kept the which-value
   record — a DEPHASED circuit reported only by the lyyf-(B) warning. With bd vsfp's
   dead-argument drop the call is `h(0, m)`, `q` has no prior user, and the add lowers
   IN PLACE (`cqrt_addc_i32`), exactly as in the hand-inlined twin
   (slice_spec_dropped_arg_inplace_twin.c). `e2e-spec-dropped-arg-inplace-twin-identical`
   pins the two goldens BYTE-IDENTICAL. On the oracle that gate is RED.

   `m = argc + 4` = 5 under the harness (bd 46oo), so the arm runs. */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int t = h(q, m);
    int u = t + q;
    int r = u;
    if (m > 3) r = cq_theta(u, 0.2);
    return cq_measure(r);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
