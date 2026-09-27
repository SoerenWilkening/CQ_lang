#include <stdlib.h>
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int r = 0;
  if (q > 3) r = 7;
  return cq_measure(r) + cq_measure(q);
}
