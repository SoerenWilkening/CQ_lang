__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    int a = 0, z = 0;
    for (int i = 0; i < n; ++i) if ((q > 1) & (r < 5)) { a += i; z ^= 5; }
    return cq_measure(q) + cq_measure(r) + cq_measure(a) + cq_measure(z);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
