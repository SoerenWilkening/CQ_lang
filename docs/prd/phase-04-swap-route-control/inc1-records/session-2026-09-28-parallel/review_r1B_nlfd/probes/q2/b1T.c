#include <stdlib.h>
__attribute__((noinline)) int f(int m, int k) {
  int q = cq_theta(m & 7, .5); int t = q + k;
  if (t == 9) cq_phi(3.14159);
  q = cq_theta(q, .7); int z = cq_measure(q);
  return z + 1;
}
int main(int c, char **v) { int m = atoi(v[1]); return f(m, m); }
