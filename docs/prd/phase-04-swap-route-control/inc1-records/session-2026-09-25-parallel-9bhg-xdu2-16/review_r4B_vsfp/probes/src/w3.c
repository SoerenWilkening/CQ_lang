#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  _Bool p = 0;
  if (q > 3) { volatile int z = 1; p = 1; }
  return cq_measure(q) + cq_measure(p);
}
