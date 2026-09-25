__attribute__((noinline)) static int g(int k) { return k * k + 3; }
__attribute__((noinline)) static int slice(int n, int k, int m) {
    int q = cq_theta(0, 0.25);
    int u = 5;
    if (q > 1) u = g(k);
    int s = 0;
    { int t = (u > 3) ? 1 : 55; s += cq_measure(t); }
    return cq_measure(q) + cq_measure(u) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc, argc); }
