#include <stdlib.h>
static volatile int KI = 1;
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int p = 0;
  if (q > 3) p = KI;
  return cq_measure(p) + cq_measure(q);
}
