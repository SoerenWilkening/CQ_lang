#include <stdlib.h>
int main(int c, char **v) {
  const int s = 6;
  int q = cq_theta(atoi(v[2]), 0.3);
  int r = s;
  cq_invert_begin();
  if (q > 3) r = cq_theta(s, 0.2);
  cq_invert_end();
  return cq_measure(r) + cq_measure(q);
}
