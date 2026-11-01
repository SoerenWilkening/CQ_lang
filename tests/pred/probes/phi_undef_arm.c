#include "CQ.h"
// USERCHECK pf
// cq-ylrk: -O1 merges the result with an undef incoming (an edge never taken); the select template on
// that arm and its _unc must read one value (gate 2a review pred-h1 #2).
int pf(int n) {
  int x = 0;
  cq_theta(&x, 0.5);
  n &= 7;
  for (int i = 0; i < n; i++) {
    if ((x >> i) & 1) goto BRK;
  }
  cq_phi(0.5);
  cq_phi(0.25);
  return x;
BRK:
  cq_phi(0.7);
  return x + 1;
}
