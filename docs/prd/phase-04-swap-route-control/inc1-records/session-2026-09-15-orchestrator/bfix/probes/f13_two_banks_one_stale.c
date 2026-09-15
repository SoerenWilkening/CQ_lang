/* f13 — RE-ATTACK: TWO banks in one function, one parking a rail that is later
   relabelled and one parking a per-trip rail that is not.  The hop is per-bank
   (`railBankOfPointer` of the LOAD's pointer), so the clean bank must not be
   dragged down by the stale one and the stale one must not be rescued by the
   clean one.  Expected: DECLINE, anchored on the STALE bank's measure. */
#include "CQ.h"
int slice(int seed) {
  int q = cq_theta(seed, 0.5);
  int b0[3]; int b1[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  for (int i = 0; i < 3; ++i) b1[i] = cq_theta(b1[i], 0.2);
  q = cq_theta(q, 0.7);
  for (int i = 0; i < 3; ++i) s += cq_measure(b1[i]);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + cq_measure(q);
}
int main(void) { return slice(1); }
