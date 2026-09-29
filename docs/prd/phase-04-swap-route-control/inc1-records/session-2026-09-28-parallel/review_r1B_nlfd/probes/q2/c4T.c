#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int r = q + m;
  if (r == 9) cq_phi(3.14159);
  q = cq_theta(q, .7);
  return cq_measure(q);
}
