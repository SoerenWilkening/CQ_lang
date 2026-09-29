#include <stdlib.h>
int main(int c, char **v) {
  float s = (float)atof(v[1]);
  int q = cq_theta(atoi(v[2]), 0.3);
  float r = s;
  if (q > 3) r = cq_theta(s, 0.2);
  return (int)cq_measure(r) + cq_measure(q);
}
