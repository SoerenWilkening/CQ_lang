#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]);
  int z = cq_theta(m & 7, .3);
  int q = cq_theta(2, .5);
  int r = (z + 1) * 3;
  if ((q ^ 5) == 3) cq_phi(0.7);
  q = cq_theta(q, .7);
  return cq_measure(q) + cq_measure(r) + cq_measure(z);
}
