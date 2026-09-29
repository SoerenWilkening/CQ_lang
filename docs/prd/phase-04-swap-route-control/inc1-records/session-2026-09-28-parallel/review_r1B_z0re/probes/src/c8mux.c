#include <stdlib.h>
int main(int c, char **v) {
  int q = cq_theta(atoi(v[2]), 0.3);
  int s = 5; if (q > 3) s = 7;
  int q2 = cq_theta(atoi(v[1]), 0.4);
  int r = s; if (q2 > 3) r = cq_theta(s, 0.2);
  return cq_measure(r) + cq_measure(q) + cq_measure(q2);
}
