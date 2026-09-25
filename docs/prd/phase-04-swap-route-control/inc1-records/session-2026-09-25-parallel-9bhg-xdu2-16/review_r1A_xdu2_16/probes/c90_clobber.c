__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int a = cq_theta(2, 0.5);
    for (int i = 0; i < n; ++i) { a = ((q > 1) & (a < 5)) ? a + 3 : a; }
    return cq_measure(q) + cq_measure(a);
}
int main(void) { volatile int k = 3; return slice(k); }
