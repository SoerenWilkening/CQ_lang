__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;
    for (int i = 0; i < n; ++i) { if ((q > 1) & (r < 5)) a += 3; }
    int s = cq_measure(a); q = cq_theta(q, 0.9); return s + cq_measure(q) + cq_measure(r);
}
int main(void) { volatile int k = 2; return slice(k); }
