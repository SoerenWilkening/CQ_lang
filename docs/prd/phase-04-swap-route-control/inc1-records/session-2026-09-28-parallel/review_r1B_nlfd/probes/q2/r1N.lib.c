static volatile int K = 7;
int h(int a, int k) { if (a > 3) (void)K; if (k <= 0) return 1; return h(a, k - 1); }
