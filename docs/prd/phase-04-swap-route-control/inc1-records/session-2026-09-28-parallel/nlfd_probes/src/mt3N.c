#include <stdlib.h>
static volatile int K = 7;
int out;
__attribute__((noinline)) void h2(int a, int k) { if (a > 3) (void)K; }
__attribute__((noinline)) void w(int m, int k) {
  int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7); out = cq_measure(q);
  return h2(p, k);
}
int main(int c, char **v) { int m = atoi(v[1]); w(m, c); return out; }
