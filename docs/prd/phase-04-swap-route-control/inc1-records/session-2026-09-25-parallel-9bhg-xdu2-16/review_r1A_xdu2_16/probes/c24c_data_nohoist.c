__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    int p = q * 3;
    for (int i = 0; i < n; ++i) { int t = ((q > i) & (r < i)) ? i : 55; s += cq_measure(t) + cq_measure(p + i); }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc + 2); }
