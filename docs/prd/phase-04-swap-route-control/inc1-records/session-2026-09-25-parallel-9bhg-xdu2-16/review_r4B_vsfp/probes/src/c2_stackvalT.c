#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int r = 1, s = 2, t = 3;
  if (q > 3) { r = 5; }
  if (q > 1) { s = 6; }
  if (q < 6) { t = 0; }
  return cq_measure(q) + cq_measure(r) + cq_measure(s) + cq_measure(t);
}
