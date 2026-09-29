#include <stdlib.h>
int main(int c, char **v) {
  int s = atoi(v[1]); int s2 = atoi(v[3]);
  int q = cq_theta(atoi(v[2]), 0.3);
  int r = s;
  if (q > 3) r = cq_theta(s, 0.2);
  int r2 = s2;
  if (r > 5) r2 = cq_theta(s2, 0.4);
  return cq_measure(r2) + cq_measure(r) + cq_measure(q);
}
