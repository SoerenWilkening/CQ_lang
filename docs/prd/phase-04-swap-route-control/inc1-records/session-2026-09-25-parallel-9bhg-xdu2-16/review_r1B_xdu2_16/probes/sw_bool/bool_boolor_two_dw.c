__attribute__((noinline)) static int slice(int n, int m) {
    _Bool q = cq_theta((_Bool)0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    int i = 0;
    do { int t = (q | (r < 5)) ? i : 55; int u = (q | (r < 5)) ? 7 : i; s += cq_measure(t) + cq_measure(u); } while (++i < n);
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
