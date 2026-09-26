static volatile int K = 7;
int h(int a, int k) { short s = (short)a; if (s > 30) (void)K; return k + 1; }
