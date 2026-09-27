static volatile int K = 7; int h(int a, int k) { switch (a) { case 1: (void)K; break; case 5: (void)K; (void)K; break; } return k + 1; }
