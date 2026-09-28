static volatile int K = 7;
__attribute__((noinline)) int h2(int a, int b, int k) { if (a > 3) (void)K; return k + b; }
int h(int a, int b, int k) { return h2(a, b, k); }
