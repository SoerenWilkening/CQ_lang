__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    { int t = ((q > 1) & (r < 0)) ? 0 : 55; int u = ((q > 1) & (r < 0)) ? 7 : 0; s += cq_measure(t) + cq_measure(u); }
    { int t = ((q > 1) & (r < 1)) ? 1 : 55; int u = ((q > 1) & (r < 1)) ? 7 : 1; s += cq_measure(t) + cq_measure(u); }
    { int t = ((q > 1) & (r < 2)) ? 2 : 55; int u = ((q > 1) & (r < 2)) ? 7 : 2; s += cq_measure(t) + cq_measure(u); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
