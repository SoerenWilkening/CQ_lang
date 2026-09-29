#include <stdlib.h>
int main(int c, char **v) {
  int s = atoi(v[1]); int u = atoi(v[3]);
  int q = cq_theta(atoi(v[2]), 0.3);
  int r;
  if (q > 3) r = cq_theta(s, 0.2); else r = cq_theta(u, 0.5);
  return cq_measure(r) + cq_measure(q);
}
