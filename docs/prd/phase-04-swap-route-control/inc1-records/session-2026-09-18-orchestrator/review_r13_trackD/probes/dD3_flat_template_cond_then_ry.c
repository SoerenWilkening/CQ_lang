// CONTROL for dD1: the FLAT spelling (no loop, compare in Pred). If this ACCEPTS on
// the ORACLE with the same dirty template rail, the DEFECT is pre-existing and this
// landing widens its POPULATION; if it declines, the landing creates the class.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  if (t == 1) r = cq_theta(r, 0.9);
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
}
