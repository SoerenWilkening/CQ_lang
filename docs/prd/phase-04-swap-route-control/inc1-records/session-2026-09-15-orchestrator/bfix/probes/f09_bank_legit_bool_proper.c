/* f09 — f08's LEGITIMATE sibling (measure loop above the rotation).  MUST
   ACCEPT: it is the `_Bool` twin of `f06` and proves the storage-cast strip did
   not turn into a blanket refusal of `_Bool` banks. */
#include "CQ.h"
int slice(void) {
  bool q = 0;
  q = cq_theta(q, 0.5);
  bool b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  q = cq_theta(q, 0.7);
  return s + (int) cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
