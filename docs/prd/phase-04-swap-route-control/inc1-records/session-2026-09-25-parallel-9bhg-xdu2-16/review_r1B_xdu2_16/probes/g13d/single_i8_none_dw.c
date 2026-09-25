__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    signed char r = cq_theta((signed char)1, 0.5);
    int w = cq_theta(2, 0.4);
    int s = 0;
    int i = 0; do { int t = (q > 1) ? i : 55; int d = (r + i) > 3; s += cq_measure(t) + cq_measure(d); } while (++i < n);
    return cq_measure(q) + (int)cq_measure(r) + cq_measure(w) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
