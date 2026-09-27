#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]);
  _Bool a = m > 5, b = m < 2;
  int q = cq_theta(m & 7, .5);
  _Bool p;
  if (q > 3) { p = a; } else { p = b; }
  return cq_measure(q) + a + b;
}
