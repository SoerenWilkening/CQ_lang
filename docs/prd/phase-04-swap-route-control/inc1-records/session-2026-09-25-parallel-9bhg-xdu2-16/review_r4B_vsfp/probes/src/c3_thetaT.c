#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int r = 2;
  if (q > 3) { r = 5; }
  r = cq_theta(r, .3);
  return cq_measure(r) + cq_measure(q);
}
