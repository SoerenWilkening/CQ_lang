#include <stdlib.h>
static volatile int K = 7;
int main(int c, char **v) {
  int m = atoi(v[1]);
  _Bool a = m > 5, b = m < 2, d = m == 4;
  int q = cq_theta(m & 7, .5);
  _Bool p1, p2, p3;
  if (q > 3) { (void)K; p1 = a; } else { p1 = b; }
  if (p1) { (void)K; p2 = b; } else { p2 = d; }
  if (p2) { (void)K; p3 = d; } else { p3 = a; }
  if (p3) { (void)K; }
  return cq_measure(q) + a + b + d;
}
