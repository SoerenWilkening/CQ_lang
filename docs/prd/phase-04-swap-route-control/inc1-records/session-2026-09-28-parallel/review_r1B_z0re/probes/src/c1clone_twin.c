#include <stdlib.h>
int main(int c, char **v) {
  int a, b;
  { int s = atoi(v[1]); int q = cq_theta(atoi(v[2]), 0.3); int r = s; if (q > 3) r = cq_theta(s, 0.2); a = cq_measure(r) + cq_measure(q); }
  int qs = cq_theta(atoi(v[1]), 0.5);
  { int s = qs; int q = cq_theta(atoi(v[2]), 0.3); int r = s; if (q > 3) r = cq_theta(s, 0.2); b = cq_measure(r) + cq_measure(q); }
  return a + b;
}
