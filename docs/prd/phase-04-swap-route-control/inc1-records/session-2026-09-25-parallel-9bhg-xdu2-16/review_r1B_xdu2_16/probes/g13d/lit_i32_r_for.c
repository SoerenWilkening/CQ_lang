__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int w = cq_theta(2, 0.4);
    int s = 0;
    for (int i = 0; i < n; ++i) { int t = ((q > 1) & (m > 0)) ? i : 55; int d = (r + i) > 3; s += cq_measure(t) + cq_measure(d); }
    r = cq_theta(r, 0.7);
    return cq_measure(q) + (int)cq_measure(r) + cq_measure(w) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
