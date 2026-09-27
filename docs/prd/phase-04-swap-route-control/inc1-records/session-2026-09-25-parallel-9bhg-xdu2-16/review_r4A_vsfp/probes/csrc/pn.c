#include <stdlib.h>
int h(int a, int p[static 4]);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int b[4] = {m, 1, 2, 3};
  int q = cq_theta(m & 7, .5);
  int r = h(q, b);
  return cq_measure(r) + b[0];
}
