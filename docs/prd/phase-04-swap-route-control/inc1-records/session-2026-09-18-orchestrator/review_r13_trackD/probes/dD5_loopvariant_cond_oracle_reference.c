// THE PRE-EXISTING REFERENCE: same leak shape, but the compare is loop-VARIANT so it
// stays in Pred and P4 never fired. If this ACCEPTS on the ORACLE with a dirty
// template rail, the DEFECT ships already and dD1 is a new POPULATION member.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == i) r = cq_theta(r, 0.9);
  }
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
}
