// The FOLDED if/else ANGLE SELECT with a CSE'd cross-block condition (S6 filed,
// not built -- confirm the unconditional decline survives, i.e. the SAFE direction).
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  if (q == 5) cq_phi(0.3); else cq_phi(0.7);
  if (q == 5) cq_phi(0.4); else cq_phi(0.8);
  return cq_measure(q);
}
