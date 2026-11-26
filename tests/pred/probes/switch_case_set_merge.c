#include "CQ.h"
// USERCHECK f
// cq-1cljt (CR rules 8, 9): a quantum test's one arm holds a classical switch; its cases 1-3 go straight to the return
// join, cases 0/3074 run a quantum switch and 3200/3202 a plain arm, both into a join before the return. TinyEMU
// csr_read's shape. The classical facts of the case 1-3 edge were empty (the classical factor of a case set is no
// conjunction of literals), so the return's merge read the inner join's value where that edge leaves, above its join
// (an internal error at pred's joinAbove).
int f(int a, int q) {
  cq_theta(&q, 1.0);
  int r;
  if (q & 1)
    return 5;
  switch (a) {
  case 1: case 2: case 3: return 7;
  case 0: case 3074:
    switch ((q >> 1) & 3) { case 0: r = q * 3; break; case 1: r = q ^ 0x55; break; default: return 8; }
    break;
  case 3200: case 3202: r = q + 9; break;
  default: r = 0;
  }
  return r * 3 + a;
}
