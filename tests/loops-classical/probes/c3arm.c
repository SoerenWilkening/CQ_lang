#include "CQ.h"
/* a case-3 multi-exit loop whose exit arm branches and stores */
int arm_branch(const int *s, int n, double t) {
  int x = 0; cq_theta(&x, t);
  int r = -1;
  for (int i = 0; i < n; i++) {
    if (s[i] == x) { r = (x > 2) ? i * 2 : i + 7; break; }
  }
  return cq_measure(r);
}
