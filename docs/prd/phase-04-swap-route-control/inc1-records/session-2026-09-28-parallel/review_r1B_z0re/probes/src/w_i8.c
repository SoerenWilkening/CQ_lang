#include <stdlib.h>
int main(int c, char **v) {
  signed char s = (signed char)atoi(v[1]);
  int q = cq_theta(atoi(v[2]), 0.3);
  signed char r = s;
  if (q > 3) r = cq_theta(s, 0.2);
  return (int)cq_measure(r) + cq_measure(q);
}
