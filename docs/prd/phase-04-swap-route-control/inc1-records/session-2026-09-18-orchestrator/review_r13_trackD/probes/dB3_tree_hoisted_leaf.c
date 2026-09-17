// The TREE spelling (step 5a): one HOISTED invariant leaf + one loop-VARIANT leaf.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int p = cq_theta(0, 0.7);
  for (int i = 0; i < 3; i++) {
    if (q == 5 && p == i) cq_phi(3.14159265358979);
  }
  return cq_measure(q) + cq_measure(p);
}
