#include "CQ.h"
/* a case-3 loop with several exits (121's shape) nested in a classically bounded loop */
int mx_nest(const int *s, int n, int m, double t) {
  int x = 0; cq_theta(&x, t);
  int acc = 0;
  for (int k = 0; k < m; k++) {
    int r = -1;
    for (int i = 0; i < n; i++)
      if (s[i] + k == x) { r = i; break; }
    acc += r;
  }
  return cq_measure(acc);
}
