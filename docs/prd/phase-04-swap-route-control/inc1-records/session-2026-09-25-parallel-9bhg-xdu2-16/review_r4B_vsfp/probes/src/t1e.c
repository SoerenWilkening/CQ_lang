#include <stdlib.h>
static volatile int KI = 1;
static volatile int K2 = 5;
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int q1 = q + 1;
  int p = 1;
  if (q > 3) p = KI;
  int t = atoi(v[2]);
  int r = q;
  if (p) { (void)K2; r = q1; }
  return cq_measure(r) + cq_measure(q1) + t;
}
