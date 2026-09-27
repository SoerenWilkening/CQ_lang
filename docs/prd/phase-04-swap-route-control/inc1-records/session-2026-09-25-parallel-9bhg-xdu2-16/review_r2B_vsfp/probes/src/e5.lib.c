static volatile int K = 7;
int h(int a, int k) { int t = (a > 2) ? a + 1 : a - 1; if (t != k) (void)K; return k + 1; }
