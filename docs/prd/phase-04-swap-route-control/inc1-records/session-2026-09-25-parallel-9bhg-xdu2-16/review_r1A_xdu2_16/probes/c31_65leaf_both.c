__attribute__((noinline)) int ext_f(int a) { return a * 3 + 1; }
__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    int y = 5; if (q > 5) y = ext_f(n);
    for (int i = 0; i < n; ++i) { int t = ((y > 6) & (m == 3)) ? i : 55; s += cq_measure(t) + cq_measure(r < i); }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k, k); }
