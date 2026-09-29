#include <stdlib.h>
int main(int c, char **v) {
  int q2 = cq_theta(atoi(v[1]), 0.4);
  int s = (q2 > 3) ? atoi(v[3]) : 7;
  int q = cq_theta(atoi(v[2]), 0.3);
  int r;
  if (q > 3) r = cq_theta(s, 0.7); else r = cq_theta(s, 0.2);
  return cq_measure(r) + cq_measure(q) + cq_measure(q2);
}
