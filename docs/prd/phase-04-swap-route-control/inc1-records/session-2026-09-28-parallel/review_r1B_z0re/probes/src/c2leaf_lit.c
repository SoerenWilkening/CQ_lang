#include <stdlib.h>
int main(int c, char **v) {
  const int s = 6;
  int q = cq_theta(atoi(v[2]), 0.3);
  int r = s;
  if (q > 3) r = cq_theta(s, 0.2);
  if (r > 5) cq_phi(3.141592653589793);
  return cq_measure(r) + cq_measure(q);
}
