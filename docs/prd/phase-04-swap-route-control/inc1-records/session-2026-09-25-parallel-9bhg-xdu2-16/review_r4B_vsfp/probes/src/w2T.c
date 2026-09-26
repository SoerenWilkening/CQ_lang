#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  _Bool p = q > 3;
  p = cq_theta(p, 0.7);
  return cq_measure(q) + cq_measure(p);
}
