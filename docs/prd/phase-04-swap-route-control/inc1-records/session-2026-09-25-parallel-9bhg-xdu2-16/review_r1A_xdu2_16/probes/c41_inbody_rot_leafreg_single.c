__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int s = 0;
    for (int i = 0; i < n; ++i) { int t = (q > 1) ? i : 55; s += cq_measure(t); s += cq_measure(cq_theta(q, 0.1)); }
    return s;
}
int main(void) { volatile int k = 3; return slice(k); }
