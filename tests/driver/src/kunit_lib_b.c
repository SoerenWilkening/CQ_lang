/* a static libf with its own lines (K 7, K2 50); libf2 is defined nowhere */
CQ_K(libf, 7)
CQ_K2(libf, 50)
CQ_K(libf2, 2)
__attribute__((noinline)) static int libf(int x) { int n = 0; while (x > 1) { x = (x & 1) ? 3 * x + 1 : x >> 1; n++; } return n; }
int ub(int x0, double th) { int x = x0; cq_theta(&x, th); return cq_measure(libf(x)); }
