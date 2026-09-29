#include <stdlib.h>
int main(int c, char **v) {
  const int s = 6;
  int q = cq_theta(atoi(v[2]), 0.3);
  int r1 = s, r2 = s;
  if (q > 3) { r1 = cq_theta(s, 0.2); r2 = cq_theta(s, 0.4); }
  return cq_measure(r1) + cq_measure(r2) + cq_measure(q);
}
