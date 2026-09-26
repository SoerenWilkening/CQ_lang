__attribute__((noinline)) static int slice(int n, int m) {
    long long q = cq_theta(0LL, 0.25);
    long long r = cq_theta(1LL, 0.5);
    int s = 0;
    for (int i = 0; i < 3; ++i) { int t = ((q > 1) & (m > 0)) ? i : 55; int u = ((q > 1) & (m > 0)) ? 7 : i; s += cq_measure(t) + cq_measure(u); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
