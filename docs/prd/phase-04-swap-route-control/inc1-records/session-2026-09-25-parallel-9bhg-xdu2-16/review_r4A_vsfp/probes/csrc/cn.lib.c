static volatile int KK = 7;
__attribute__((noinline)) int g(int x, int y) { if (x > 3) (void)KK; return y * 3; }
int h(int a, int b) { int t = a * 5 + 1; return g(t, b + 1); }
