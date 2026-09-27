#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]);
  _Bool a = m > 5, b = m < 2;
  int q = cq_theta(m & 7, .5);
  _Bool p;
  int r;
  if (q > 3) { volatile int z = 1; p = a; r = 5; } else { p = b; r = 9; }
  if (p) { volatile int w = 2; }
  return cq_measure(q) + cq_measure(r) + a + b;
}
