#include <stdlib.h>
__attribute__((noinline)) int h2(int x, int k) { if (x == 6) cq_phi(3.14159); return k + 1; }
__attribute__((noinline)) int w(int m, int k) {
  int q = cq_theta(m & 7, .5); int p = q * 3;
  __attribute__((musttail)) return h2(p, k);
}
int main(int c, char **v) { int m = atoi(v[1]); return w(m, m) - m; }
