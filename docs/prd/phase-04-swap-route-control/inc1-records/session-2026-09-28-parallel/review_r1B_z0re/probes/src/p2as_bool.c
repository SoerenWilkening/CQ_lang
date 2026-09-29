#include <stdlib.h>
int main(int c, char **v) {
  int t = atoi(v[1]);
  _Bool b = cq_theta((_Bool)(atoi(v[2]) & 1), 0.3);
  int r;
  if (b) r = cq_theta(t, 0.7); else r = cq_theta(t, 0.2);
  return cq_measure(r) + cq_measure(b);
}
