__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;
    for (int j = 0; j < m; ++j)
      for (int i = 0; i < n; ++i) { if ((q > j) & (r < 5)) a += 3; }
    return cq_measure(q) + cq_measure(r) + cq_measure(a);
}
int main(void) { volatile int k = 2; return slice(k, k); }
