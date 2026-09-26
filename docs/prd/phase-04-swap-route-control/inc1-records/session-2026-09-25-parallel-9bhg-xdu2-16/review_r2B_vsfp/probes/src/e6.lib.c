static volatile int K = 7;
int h(int a, int k) { unsigned u = (unsigned)a >> 2; if (u > 3u) (void)K; return k + 1; }
