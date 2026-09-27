#include <stdlib.h>
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int q1 = q + 1;
  _Bool p = 1;
  int r = q;
  if (p) { r = q1; }
  return cq_measure(r) + cq_measure(q1);
}
