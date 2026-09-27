#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  _Bool c2 = q < 6;
  return cq_measure(q) + cq_measure(c2);
}
