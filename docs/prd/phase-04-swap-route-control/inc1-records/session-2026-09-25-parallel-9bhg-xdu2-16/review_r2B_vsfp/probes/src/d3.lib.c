static volatile int K = 7;
int h(int a, int k) { int t = a > 2 ? 9 : 4; if (t > k) (void)K; return k + 1; }
