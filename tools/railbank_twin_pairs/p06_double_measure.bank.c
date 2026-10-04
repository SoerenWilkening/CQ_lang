/* the bd `yiid` row, kept deliberately: measuring one rail N times is NOT this
   fence's question, and both halves ACCEPT on the ORACLE.  It is here so that a
   future change that makes the BANK decline while the register spelling still
   accepts shows up as an OVER-DECLINE row rather than as silence. */
#include "CQ.h"
int slice(int seed) {
  int q = seed; cq_theta(&q, 0.5);
  int b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  cq_theta(&q, 0.9);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
