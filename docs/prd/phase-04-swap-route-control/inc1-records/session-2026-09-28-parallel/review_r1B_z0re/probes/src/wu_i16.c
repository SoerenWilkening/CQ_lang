#include <stdlib.h>
int main(int c, char **v) {
  short s = (short)atoi(v[1]);
  int q = cq_theta(atoi(v[2]), 0.3);
  short r = cq_theta(s, 0.2);
  return (int)cq_measure(r) + cq_measure(q);
}
