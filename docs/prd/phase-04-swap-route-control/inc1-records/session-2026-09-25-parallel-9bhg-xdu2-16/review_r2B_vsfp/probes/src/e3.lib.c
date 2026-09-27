static volatile int K = 7;
int h(int a, int k) { a += k; if (a > 30) (void)K; return k + 1; }
