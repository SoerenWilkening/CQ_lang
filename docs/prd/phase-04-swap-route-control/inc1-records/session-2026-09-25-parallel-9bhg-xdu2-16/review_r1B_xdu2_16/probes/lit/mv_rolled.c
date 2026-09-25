__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int s = 0;
    for (int i = 0; i < n; ++i) { int t = (q && i < m) ? i : 55; s += cq_measure(t); }
    return cq_measure(q) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc + 1); }
