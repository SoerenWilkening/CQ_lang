__attribute__((noinline)) static int rot(int x) { return cq_theta(x, 0.3); }
__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int a = 0;
    for (int i = 0; i < n; ++i) { if ((q > 1) & (r < 5)) a ^= 1; }
    return cq_measure(rot(q)) + cq_measure(r) + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
