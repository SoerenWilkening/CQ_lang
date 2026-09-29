int cq_measure_si32(int);
__attribute__((noinline)) int h2(int t, int k) { return t * k + 1; }
int h(int a, int k) { int t = cq_measure_si32(a); return h2(t, k); }
