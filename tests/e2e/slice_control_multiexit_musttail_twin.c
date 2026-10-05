/* slice_control_multiexit_musttail_twin.c — bd test_C_libtooling-dm7f.5. The plain-
   return TWIN of slice_control_multiexit_musttail.c: the same source without
   `__attribute__((musttail))`, which `clang -O1` reconverges into one `ret` fed by a
   merge phi and which main 7b4e6359 already lowered (the 6.5 classical-call arm). Its
   golden must stay byte-identical to the musttail spelling's
   (`e2e-control-multiexit-musttail-twin-identical`). */
__attribute__((noinline)) int k(int u, int a) { return a + 100; }

__attribute__((noinline)) int f(int u, int a) {
    int q = u; cq_theta(&q, 0.5);
    if (q > 3) return k(u, a);
    return 5;
}

int main(int argc, char **argv) {
    (void)argv;
    int m = argc + 4;
    f(m, m);
    return 0;
}
