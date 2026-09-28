#include <stdlib.h>
int out;
__attribute__((noinline)) void w(int m, int k) {
  int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7); out = cq_measure(q);
}
int main(int c, char **v) { int m = atoi(v[1]); w(m, c); return out; }
