#include <stdlib.h>
int main(int c, char **v) {
  int s = atoi(v[1]);
  int q = cq_theta(atoi(v[2]), 0.3);
  int r = s;
  if (q != 3) { } else { r = cq_theta(s, 0.2); }
  return cq_measure(r) + cq_measure(q);
}
