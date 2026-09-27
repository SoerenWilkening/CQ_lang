static volatile int K = 7; int h(int a, int k) { if (__builtin_expect(a > 3, 1)) (void)K; return k + 1; }
