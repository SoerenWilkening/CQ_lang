int h(int a, int k) { if (k <= 0) return a; __attribute__((musttail)) return h(a + 1, k - 1); }
