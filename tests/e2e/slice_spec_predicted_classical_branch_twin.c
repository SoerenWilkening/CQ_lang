/* slice_spec_predicted_classical_branch_twin.c — the HAND-INLINED twin of
   slice_spec_predicted_classical_branch.c (bd test_C_libtooling-cepm): `h(q, m)`
   inlined to `g(q); int t = m + 1;` (4-TU, run_slice_multi.sh; library TUs
   spec_reading_{g,f2,f3}_lib.c). It defines the correct circuit;
   `e2e-spec-predicted-classical-branch-twin-identical` pins the two goldens equal. */
void g(int a);

__attribute__((noinline)) int slice(int m) {
    int q = m; cq_theta(&q, 0.5);
    g(q);
    int t = m + 1;
    if (t > 3) cq_theta(&q, 0.2);
    return cq_measure(q);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
