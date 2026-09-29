#include <stdlib.h>
int main(int c, char **v) {
  int t = atoi(v[1]);
  int q = cq_theta(atoi(v[2]), 0.3);
  int r;
  if (q > 3) r = cq_theta(t, __builtin_inf()); else r = cq_theta(t, 0.2);
  return cq_measure(r) + cq_measure(q);
}
