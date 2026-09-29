/* the runtime-base Ry-stem angle select spelled as a TERNARY on the angle -- no if/else,
   no SimplifyCFG merge of two thetas, so bd fmt3's `nomerge` has nothing to block.
   Same program as tests/e2e/slice_z0re_angle_select_runtime_base_exact.c (argc = 1 => m = 5, t = 6). */
__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int t = m + 1;
    int r = cq_theta(t, (q > 3) ? 0.75 : 0.25);
    return cq_measure(r) + cq_measure(q);
}
int main(int argc, char **argv) { (void) argv; (void) slice(argc + 4); return 0; }
