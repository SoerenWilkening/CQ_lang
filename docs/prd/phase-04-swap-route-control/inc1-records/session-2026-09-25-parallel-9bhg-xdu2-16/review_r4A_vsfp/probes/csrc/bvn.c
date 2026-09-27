#include <stdlib.h>
struct Big { int x[8]; };
int h(int a, struct Big *sp);
int main(int c, char **v) {
  int m = atoi(v[1]);
  struct Big b = {{m, 1, 2, 3, 4, 5, 6, 7}};
  int q = cq_theta(m & 7, .5);
  int r = h(q, &b);
  return cq_measure(r) + b.x[0];
}
