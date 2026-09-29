static volatile int K = 7;
__attribute__((noinline)) int h2(int a, int k) { if (a > 3) (void)K; return k + 1; }
