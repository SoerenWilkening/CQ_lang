__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5);
    for (int i = 0; i < n; ++i) cq_phi(((q > 1) & (r < 5)) ? 0.3 : 0.7);
    return cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc + 2); }
