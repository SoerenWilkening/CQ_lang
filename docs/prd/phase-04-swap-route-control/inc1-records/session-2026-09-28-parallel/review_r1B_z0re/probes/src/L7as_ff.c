#include <stdlib.h>
int main(int c, char **v) {
  int t = atoi(v[1]); int n = atoi(v[3]);
  for (int i = 0; i < n; i++) { int w = cq_theta(t, 0.1); t = cq_measure(w) + 2; }
  int q = cq_theta(atoi(v[2]), 0.3);
  int r;
  if (q > 3) r = cq_theta(t, 0.7); else r = cq_theta(t, 0.2);
  return cq_measure(r) + cq_measure(q);
}
