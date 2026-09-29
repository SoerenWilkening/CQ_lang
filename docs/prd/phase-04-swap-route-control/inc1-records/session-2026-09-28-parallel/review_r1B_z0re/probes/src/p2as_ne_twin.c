#include <stdlib.h>
int main(int c, char **v) {
  int t = atoi(v[1]);
  int q = cq_theta(atoi(v[2]), 0.3);
  int r = cq_theta(t, 0.2);
  if (q != 3) r = cq_theta(r, 0.7 - 0.2);
  return cq_measure(r) + cq_measure(q);
}
