#include <stdlib.h>
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int p = 0;
  if (q > 3) p = 1;
  return cq_measure(p) + cq_measure(q);
}
