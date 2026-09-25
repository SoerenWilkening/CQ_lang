__attribute__((noinline)) static int slice(int n, int m) {
    long long q = cq_theta(0LL, 0.25);
    long long r = cq_theta(1LL, 0.5);
    int s = 0;
    { int t = ((q > 1) & (r < 5)) ? (q + 0) : 55; s += cq_measure(t); }
    { int t = ((q > 1) & (r < 5)) ? (q + 1) : 55; s += cq_measure(t); }
    { int t = ((q > 1) & (r < 5)) ? (q + 2) : 55; s += cq_measure(t); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
