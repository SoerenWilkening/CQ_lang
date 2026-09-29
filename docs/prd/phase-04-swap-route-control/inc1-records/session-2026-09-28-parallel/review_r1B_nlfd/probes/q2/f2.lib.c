static volatile int K = 7;
__attribute__((noinline)) double h2(double a, double k) { if (a > 3.0) (void)K; return k + 1.0; }
