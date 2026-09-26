#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]);
  _Bool a = m > 5, b = m < 2;
  int q = cq_theta(m & 7, .5);
  int r;
  if (q > 3) { r = 5; } else { r = 9; }
  return cq_measure(q) + cq_measure(r) + a + b;
}
