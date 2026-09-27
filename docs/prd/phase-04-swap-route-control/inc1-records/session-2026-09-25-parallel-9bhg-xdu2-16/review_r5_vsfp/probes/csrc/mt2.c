#include <stdlib.h>
static volatile int K = 7;
__attribute__((noinline)) int h2(int a, int k) { if (a > 3) (void)K; return k + 1; }
__attribute__((noinline)) int w(int m, int k) {
  int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7); int z = cq_measure(q);
  __attribute__((musttail)) return h2(p, k + z);
}
int main(int c, char **v) { int m = atoi(v[1]); return w(m, c); }
