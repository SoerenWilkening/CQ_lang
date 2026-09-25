__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    _Bool c = (q > 1) & (r < 5);
    for (int i = 0; i < n; ++i) { int t = c ? i : 55; s += cq_measure(t); }
    return cq_measure(c) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc + 2); }
