__attribute__((noinline)) double h2(double a, double k) { return a + k; }
double h(double a, double k) { return h2(a, k); }
