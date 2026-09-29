#include <stdlib.h>
int h2(int a, int k);
__attribute__((noinline)) int f(int m, int k) {
  _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4;
  b = cq_theta(b, .7); int t = cq_measure(b);
  return h2(p, t + k);
}
int main(int c, char **v) { int m = atoi(v[1]); return f(m, m); }
