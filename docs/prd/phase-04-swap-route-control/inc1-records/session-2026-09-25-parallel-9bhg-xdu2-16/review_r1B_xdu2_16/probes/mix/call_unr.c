__attribute__((noinline)) static int g(int k) { return k * k + 1; }
__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int w = cq_theta(2, 0.4);
    int s = 0;
    { int t = ((q > 1) & (r < 5)) ? 0 : 55; if ((0 & 1) == 1) s += g(0); s += cq_measure(t); }
    { int t = ((q > 1) & (r < 5)) ? 1 : 55; if ((1 & 1) == 1) s += g(1); s += cq_measure(t); }
    { int t = ((q > 1) & (r < 5)) ? 2 : 55; if ((2 & 1) == 1) s += g(2); s += cq_measure(t); }
    return cq_measure(q) + cq_measure(r) + cq_measure(w) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
