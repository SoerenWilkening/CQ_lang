/* slice_spec_dropped_arg_boolsel.c — bd test_C_libtooling-vsfp (P1, SILENT
   DEPHASING), the SPEC-CLASSICAL ACCEPT that used to dephase, end to end (2-TU,
   run_slice_multi.sh; library TU spec_dropped_arg_lib.c: `h(a, k) = k + 1`, `a`
   unread). The bead's repro `b10f` with the 4.4 select spelling of `p`.

   On `main` aee8f4f8 the call `h(p, m)` was a Phase-6 site whose clone never read
   `p`, while the call still did: `p = b ? 9 : 4` is a 4.4 data select on a bare
   `_Bool`, so its `%out` rail — a which-path copy of `b` minted by two
   `cqrt_copy_i32_controlled` — was kept alive by that phantom read across
   `b = cq_theta(b, 0.7)`, dephasing it (P(b=1) 0.8356 instead of cos^2(.6) =
   0.6812 for odd m; exit 0, no warning, stage 2b STRICT clean). The CORRECT
   circuit is the hand-inlined twin's (slice_spec_dropped_arg_boolsel_twin.c,
   `int t = m + 1;`), and `e2e-spec-dropped-arg-boolsel-twin-identical` pins the two
   goldens BYTE-IDENTICAL: Ry(0.5) then Ry(0.7) on ONE handle and its measurement —
   no `%out`, no copies, no clone. (What is red on the oracle is THIS slice's own
   entry, `e2e-slice-spec-dropped-arg-boolsel` — its 2-TU trace carries the copies; the
   twin-identical gate compares two committed goldens and cannot be red on any binary,
   bd vsfp r1B F-VB-6.)

   `m` is `slice`'s parameter, passed `argc + 4` (argc = 1 under the harness, so m
   = 5 and `b` starts |1>); `noinline` keeps `clang -O1` from folding it (bd 46oo).
   `main` discards the result so the slice exits 0 under the harness's `pipefail`. */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    _Bool b = cq_theta((_Bool)(m & 1), 0.5);
    int p = b ? 9 : 4;
    int t = h(p, m);
    b = cq_theta(b, 0.7);
    return t + cq_measure(b);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
