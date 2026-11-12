__attribute__((noinline)) int inner(int x, int c) { return x * x + c; }
int e(int x0, double t, int c) { int x = x0; cq_theta(&x, t); return cq_measure(inner(x, c)); }
