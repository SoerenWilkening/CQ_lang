#include <stdlib.h>
int main(int c, char **v) {
  _Float16 s = (_Float16)atof(v[1]);
  int q = cq_theta(atoi(v[2]), 0.3);
  _Float16 r = s;
  if (q > 3) r = cq_theta(s, 0.2);
  return (int)cq_measure(r) + cq_measure(q);
}
