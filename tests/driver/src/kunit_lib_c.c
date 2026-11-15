/* a static libf with no line: marked "cq-k"="0", so libf's constant does not reach it */
__attribute__((noinline)) static int libf(int x) { int n = 0; while (x > 1) { x = (x & 1) ? 3 * x + 1 : x >> 1; n++; } return n; }
int uc(int x0, double th) { int x = x0; cq_theta(&x, th); return cq_measure(libf(x)); }
