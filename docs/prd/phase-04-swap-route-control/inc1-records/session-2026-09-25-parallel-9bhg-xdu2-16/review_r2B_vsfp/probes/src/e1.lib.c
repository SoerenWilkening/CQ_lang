static volatile int K = 7;
int h(int a, int k) { int t = a ^ k; if (t > 30) (void)K; return k + 1; }
