__attribute__((noinline)) static int slice(int n, int m, int stop) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    for (int j = 0; j < m; ++j) {
      if (j == stop) break;
      for (int i = 0; i < n; ++i) { int t = ((q > 1) & (r < 5)) ? i + 10 * j : 55; s += cq_measure(t); }
    }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(void) { volatile int k = 2; volatile int st = 7; return slice(k, k, st); }
