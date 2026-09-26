/* slice_spec_dropped_arg_dead_smax.c — bd test_C_libtooling-vsfp ROUND 2 / bd
   test_C_libtooling-m1gi (2-TU, run_slice_multi.sh; library TU spec_dropped_arg_lib.c:
   `h(a, k) = k + 1`, `a` unused). Rule-13 r1A F-VA-2, probe `prov1`.

   The operand handed to `h`'s dead first parameter is `p > n ? p : n` — `clang -O1`
   turns it into `llvm.smax(p, n)`, an LLVM INTRINSIC call. Round 1's drop replaced the
   operand by `0` but its cone walk deleted only non-call instructions, so the dead
   `smax` survived and kept `p` — a 4.4 bool-select `%out` rail copying `b` — alive and
   entangled across `b = cq_theta(b, 0.7)`: exit 0, no warning, stage 2b STRICT clean,
   P(b=1) 0.8356 instead of 0.6812 for odd m. (The oracle declined this spelling at the
   3jru fence inside a helper; with `slice` exporting its result it accepted on both.)
   Round 2 asks LIVENESS: the dead intrinsic, the dead select and its `%out` never exist.
   `e2e-spec-dropped-arg-dead-smax-twin-identical` pins this golden BYTE-IDENTICAL to
   slice_spec_dropped_arg_boolsel_twin.c's (`int t = m + 1;`, the dead `p` folded away
   by `-O1`). What is RED on the round-1 binary is this slice's own entry (measured).

   `m = argc + 4` = 5 and `n = argc + 6` = 7 under the harness (bd 46oo); `noinline`
   keeps `clang -O1` from folding them. */
int h(int a, int k);

__attribute__((noinline)) int slice(int m, int n) {
    _Bool b = cq_theta((_Bool)(m & 1), 0.5);
    int p = b ? 9 : 4;
    int t = h(p > n ? p : n, m);
    b = cq_theta(b, 0.7);
    return t + cq_measure(b);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4, argc + 6);
    return 0;
}
