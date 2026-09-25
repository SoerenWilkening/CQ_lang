__attribute__((noinline)) static int f1(int n) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    for (int i = 0; i < n; ++i) { int t = ((q > 1) & (r < 5)) ? i : 55; s += cq_measure(t); }
    return cq_measure(q) + cq_measure(r) + s;
}
__attribute__((noinline)) static int f2(int n) {
    int q = cq_theta(2, 0.3); int r = cq_theta(3, 0.6); int a = 0;
    for (int i = 0; i < n; ++i) { if ((q < 3) | (r > 1)) a += 7; }
    return cq_measure(q) + cq_measure(r) + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return f1(argc + 2) + f2(argc + 1); }
