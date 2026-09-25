__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    for (int i = 0; i < 1000; ++i) { int t = ((q > 1) & (r < 5) & (i < m)) ? i : 55; s += cq_measure(t); }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc + 1); }
