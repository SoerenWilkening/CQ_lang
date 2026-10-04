/* slice_spec_predicted_classical_branch.c — bd test_C_libtooling-cepm, end to end
   (5-TU, run_slice_multi.sh; library TUs spec_reading_{h,g,f2,f3}_lib.c).

   `t = h(q, m)` where `h` READS `q` (through `g`, a liveness root — bd vsfp's
   dead-argument drop does not apply) and returns the CLASSICAL `m + 1`. Since bd cepm
   propagation asks `predictReturnTainted(h, 01)` — false — and leaves `t` CLASSICAL,
   so `if (t > 3)` is an ordinary classical branch around the in-place Ry of `q`, and
   the clone `__cq_q_h_01` runs `g`'s Bennett forward + reverse on `q` (identity) and
   returns the classical value. On the oracle (main 9a230646) `t` was tainted
   CONSERVATIVELY and the module declined (`condition predates a non-diagonal gate
   under quantum control`).

   The CORRECT circuit is the hand-inlined twin's (slice_spec_predicted_classical_
   branch_twin.c: `g(q); int t = m + 1;`); `e2e-spec-predicted-classical-branch-twin-
   identical` pins the two goldens BYTE-IDENTICAL.

   `m` is `slice`'s parameter, passed `argc + 4` (argc = 1 under the harness, so m = 5
   and t = 6: the branch is taken); `noinline` keeps `clang -O1` from folding it (bd
   46oo). `main` discards the result so the slice exits 0 under `pipefail`. */
int h(int a, int k);

__attribute__((noinline)) int slice(int m) {
    int q = m; cq_theta(&q, 0.5);
    int t = h(q, m);
    if (t > 3) cq_theta(&q, 0.2);
    return cq_measure(q);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
