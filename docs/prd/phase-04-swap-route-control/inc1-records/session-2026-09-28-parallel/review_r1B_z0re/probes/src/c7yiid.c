#include <stdlib.h>
int main(int c, char **v) {
  int q = cq_theta(atoi(v[2]), 0.3);
  int m = cq_measure(q);
  int r = m;
  if (q > 3) r = cq_theta(m, 0.2);
  return cq_measure(r) + m;
}
