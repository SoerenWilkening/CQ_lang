__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int w = cq_theta(2, 0.4);
    int s = 0;
    { int t = ((q > 1) & (w < 5)) ? 1 : 55; int u = ((r ^ 1) > 3) ? 7 : 9; s += cq_measure(t) + cq_measure(u); }
    { int t = ((q > 1) & (w < 5)) ? 2 : 55; int u = ((r ^ 2) > 3) ? 7 : 9; s += cq_measure(t) + cq_measure(u); }
    { int t = ((q > 1) & (w < 5)) ? 3 : 55; int u = ((r ^ 3) > 3) ? 7 : 9; s += cq_measure(t) + cq_measure(u); }
    return cq_measure(q) + cq_measure(r) + cq_measure(w) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
