#include <stdlib.h>
int main(int c, char **v) {
  long double s = (long double)strtold(v[1],0);
  int q = cq_theta(atoi(v[2]), 0.3);
  long double r = s;
  if (q > 3) r = cq_theta(s, 0.2);
  return (int)cq_measure(r) + cq_measure(q);
}
