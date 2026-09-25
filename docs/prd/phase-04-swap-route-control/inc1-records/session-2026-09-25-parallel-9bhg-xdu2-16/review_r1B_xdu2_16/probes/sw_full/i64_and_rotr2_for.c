__attribute__((noinline)) static int slice(int n, int m) {
    long long q = cq_theta(0LL, 0.25);
    long long r = cq_theta(1LL, 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) { int t = ((q > 1) & (r < 5)) ? r : i; t = cq_theta(t, 0.7); s += cq_measure(t); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
