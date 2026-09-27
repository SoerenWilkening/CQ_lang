#include <stdlib.h>
int main(int c, char **v) {
  volatile _Bool kb = 1;
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int q1 = q + 1;
  _Bool p = 1;
  if (q > 3) p = kb;
  int r = q;
  if (p) { volatile int w = 2; r = q1; }
  return cq_measure(r) + cq_measure(q1);
}
