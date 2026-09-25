__attribute__((noinline)) static int slice(int n, int m) {
    long long q = cq_theta(0LL, 0.25);
    long long r = cq_theta(1LL, 0.5);
    int s = 0;
    int i = 0;
    do { int t = ((q > 1) & (r < 5)) ? i : 55; int v = (t > 1) ? 3 : 4; s += cq_measure(v); } while (++i < n);
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
