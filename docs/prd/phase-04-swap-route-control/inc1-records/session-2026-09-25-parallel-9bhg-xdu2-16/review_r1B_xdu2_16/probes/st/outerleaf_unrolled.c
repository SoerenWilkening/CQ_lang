__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    int u = (q > 1) ? 7 : 2;
    { int t = ((u > 3) & (r < 5)) ? 0 : 55; s += cq_measure(t); }
    { int t = ((u > 3) & (r < 5)) ? 1 : 55; s += cq_measure(t); }
    { int t = ((u > 3) & (r < 5)) ? 2 : 55; s += cq_measure(t); }
    return cq_measure(q) + cq_measure(r) + cq_measure(u) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
