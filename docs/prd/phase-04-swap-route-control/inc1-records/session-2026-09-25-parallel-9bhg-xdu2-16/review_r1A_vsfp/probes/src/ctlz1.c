#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]);
  unsigned q = cq_theta((unsigned)(m & 255), .5);
  unsigned x = q; int n = 0;
  while (x) { x >>= 1; n++; }
  int t = h(n, m);
  return t + cq_measure(q);
}
