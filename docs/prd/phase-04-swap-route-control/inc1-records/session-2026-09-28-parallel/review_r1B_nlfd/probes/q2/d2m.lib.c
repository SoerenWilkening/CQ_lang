__attribute__((noinline)) int h2(int a, int k) { return a + k; }
int h(int a, int k) { __attribute__((musttail)) return h2(a, k); }
