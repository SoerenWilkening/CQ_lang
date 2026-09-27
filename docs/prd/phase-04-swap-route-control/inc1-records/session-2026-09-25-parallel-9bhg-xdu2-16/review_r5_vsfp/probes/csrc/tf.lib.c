static volatile int K = 7;
int h(float a, int k) { if (a > 3) (void)K; return k + 1; }
