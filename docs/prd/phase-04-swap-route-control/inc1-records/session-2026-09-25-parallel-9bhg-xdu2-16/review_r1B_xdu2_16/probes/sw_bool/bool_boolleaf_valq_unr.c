__attribute__((noinline)) static int slice(int n, int m) {
    _Bool q = cq_theta((_Bool)0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    { int t = (q & (r < 5)) ? (q + 0) : 55; s += cq_measure(t); }
    { int t = (q & (r < 5)) ? (q + 1) : 55; s += cq_measure(t); }
    { int t = (q & (r < 5)) ? (q + 2) : 55; s += cq_measure(t); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
