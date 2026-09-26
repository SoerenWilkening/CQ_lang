__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int w = cq_theta(2, 0.4);
    int s = 0;
    int i = 0; do { int t = ((q > 1) & (w < 5)) ? (i + 1) : 55; int d = (r ^ (i + 1)) > 3; s += cq_measure(t) + cq_measure(d); } while (++i < 3);
    r = cq_theta(r, 0.7);
    return cq_measure(q) + cq_measure(r) + cq_measure(w) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
