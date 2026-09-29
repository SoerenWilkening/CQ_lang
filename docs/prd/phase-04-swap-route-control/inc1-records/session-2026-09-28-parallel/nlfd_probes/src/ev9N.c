#include <stdlib.h>
int g(int a, int k); int h2(int a, int k);
__attribute__((noinline)) int f(int m, int k) {
  int q = cq_theta(m & 7, .5); int p = q * 3; int t = g(q, k); int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7); int z = cq_measure(q) + cq_measure(t);
  return h2(p, z);
}
int main(int c, char **v) { int m = atoi(v[1]); return f(m, m); }
