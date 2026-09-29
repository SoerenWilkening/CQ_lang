#include <stdlib.h>
int h2(int a, int k);
__attribute__((noinline)) int w(int m, int k) {
  int q = cq_theta(m & 7, .5); int s = 0;
  for (int i = 0; i < k; ++i) { int p = q * 3; if (p == 6) cq_phi(3.14159); s += i; }
  int p2 = q * 5; if (p2 == 10) cq_phi(1.0);
  __attribute__((musttail)) return h2(s, k);
}
int main(int c, char **v) { int m = atoi(v[1]); return w(m, m); }
