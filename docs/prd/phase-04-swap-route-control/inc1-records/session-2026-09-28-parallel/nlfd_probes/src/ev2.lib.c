static volatile int K = 7;
__attribute__((noinline)) int h3(int a, int k) { if (a > 3) (void)K; return k + 1; }
__attribute__((noinline)) int h2(int a, int k) { __attribute__((musttail)) return h3(a, k); }
int h(int a, int k) { __attribute__((musttail)) return h2(a, k); }
