__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    signed char r = cq_theta((signed char)1, 0.5);
    int w = cq_theta(2, 0.4);
    int s = 0;
    { int t = ((q > 1) & (w < 5)) ? 0 : 55; int d = (r + 0) > 3; s += cq_measure(t) + cq_measure(d); }
    { int t = ((q > 1) & (w < 5)) ? 1 : 55; int d = (r + 1) > 3; s += cq_measure(t) + cq_measure(d); }
    { int t = ((q > 1) & (w < 5)) ? 2 : 55; int d = (r + 2) > 3; s += cq_measure(t) + cq_measure(d); }
    r = cq_theta(r, 0.7);
    return cq_measure(q) + (int)cq_measure(r) + cq_measure(w) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
