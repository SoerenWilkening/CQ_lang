/* f12 — the array-free twin of f11: three siblings on one rail, all measured. */
#include "CQ.h"
int slice(void) {
  int q = cq_theta(0, 0.3);
  int c0 = cq_theta(q, 0.5);
  int c1 = cq_theta(q, 0.5);
  int c2 = cq_theta(q, 0.5);
  return cq_measure(c0) + cq_measure(c1) + cq_measure(c2) + cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
