__attribute__((noinline)) int h2(int x, int k) { return k + x; }
__attribute__((noinline)) int h(int a, int k) { return h2(a, k) + 1; }
void __cq_q_h2_11_unc(int out, int x, int k) { (void)out; (void)x; (void)k; }
