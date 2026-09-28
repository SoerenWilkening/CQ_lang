#include <stdlib.h>
int main(int c, char **v) {
  _Bool s = (_Bool)(atoi(v[1]) != 0);
  int q = cq_theta(atoi(v[2]), 0.3);
  _Bool r = cq_theta(s, 0.2);
  return (int)cq_measure(r) + cq_measure(q);
}
