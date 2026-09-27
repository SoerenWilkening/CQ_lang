#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int x = q > 3 ? 9 : 4;
  int t = h(__builtin_bswap32(x), m);
  q = cq_theta(q, .7);
  return t + cq_measure(q);
}
