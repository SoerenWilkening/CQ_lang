__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    _Bool c1 = (q > 1);
    s += cq_measure(r ^ c1);
    for (int i = 0; i < n; ++i) { int t = (c1 & (r < 5)) ? i : 55; s += cq_measure(t); }
    return cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
