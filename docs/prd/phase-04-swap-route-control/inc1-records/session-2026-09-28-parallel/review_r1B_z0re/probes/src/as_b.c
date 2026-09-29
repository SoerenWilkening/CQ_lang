#include <stdlib.h>
int main(int c, char **v) {
  _Bool t = (_Bool)(atoi(v[1])!=0);
  int q = cq_theta(atoi(v[2]), 0.3);
  _Bool r;
  if (q != 3) r = cq_theta(t, 0.7); else r = cq_theta(t, 0.2);
  return (int)cq_measure(r) + cq_measure(q);
}
