static volatile int K = 0; int h(int a, int k) { return k + 1 + ((a > 3) ? K : 0); }
