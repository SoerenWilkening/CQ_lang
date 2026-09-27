static volatile int KK = 7;
int h(int a, int k) { if (a > 3) (void)KK; return k + 1; }
