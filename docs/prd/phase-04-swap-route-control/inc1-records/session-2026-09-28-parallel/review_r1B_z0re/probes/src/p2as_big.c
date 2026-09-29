#include <stdlib.h>
int main(int c, char **v) {
  int t = atoi(v[1]);
  int q = cq_theta(atoi(v[2]), 0.3);
  int r;
  if (q > 3) r = cq_theta(t, 3.141592653589793); else r = cq_theta(t, 1e16);
  return cq_measure(r) + cq_measure(q);
}
