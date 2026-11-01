#include "CQ.h"
// USERCHECK pq
// USERCHECK ps
// USERCHECK pv
// cq-0hhk: a switch case atom is the scrutinee's value at the switch, even after a case arm rotated the
// scrutinee's rail in place (gate 2a review pred-h1 #1).
int pq(int x0) {   // default falls through into case 2
  int x = x0;
  cq_theta(&x, 0.5);
  switch (x) {
  default: cq_theta(&x, 0.7);
  /* fallthrough */
  case 2: cq_phi(0.3); cq_phi(0.1); break;
  case 5: break;
  }
  return x;
}
int ps(int x0) {   // the rotation in one arm, the phase in a sibling arm
  int x = x0;
  cq_theta(&x, 0.5);
  switch (x) {
  case 2: cq_phi(0.3); break;
  default: cq_theta(&x, 0.7); break;
  case 3: cq_phi(-0.2); break;
  case 7: break;
  }
  return 0;   /* x is not merged: -O1 would merge the case constants into a rule 10 state */
}
int pv(int x0, int y) {   // value arms merged after the rotation
  int x = x0;
  cq_theta(&x, 0.5);
  switch (x) {
  default: cq_theta(&x, 0.7); y += 3;
  /* fallthrough */
  case 2: y *= 5; cq_phi(0.3); break;
  case 4: y -= 1; break;
  case 6: break;
  }
  return y;   /* x is not merged (see ps) */
}
