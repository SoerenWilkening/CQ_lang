__attribute__((noinline)) static int slice(int n, int m) {
    _Bool q = cq_theta((_Bool)0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) { int t = (q & (m > 0)) ? i : 55; int v = (t > 1) ? 3 : 4; s += cq_measure(v); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
