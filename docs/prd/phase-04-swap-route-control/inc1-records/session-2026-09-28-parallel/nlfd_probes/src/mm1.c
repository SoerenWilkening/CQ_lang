#include <stdlib.h>
int h2(int a, int k);
__attribute__((noinline)) int w(int m, int k) {
  int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi(3.14159);
  __attribute__((musttail)) return h2(p, k);
}
int main(int c, char **v) { int m = atoi(v[1]); return w(m, m); }
