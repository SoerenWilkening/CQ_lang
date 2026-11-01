#include "CQ.h"
// USERCHECK f
// cq-1b92: the atom g(d) is minted in a classical arm and carried to the later gate's join. It is fixed
// true on one incoming edge (the g(d) && !q1 fallthrough), fixed false on another (g(d) false) and
// unfixed on a third (c false: g never ran).
__attribute__((noinline)) int g(int d) { return d > 3; }
__attribute__((noinline)) void h(int d) { __asm__ volatile("" ::: "memory"); }
void f(int c, int d, int e) {
  bool q1 = 0, q2 = 0;
  cq_theta(&q1, 1.0);
  if (c) {
    int t = g(d);
    h(d);
    if (t) {
      h(e);
      if (q1) { cq_phi(0.3); return; }
    } else {
      h(c);
      if (e & 1) { cq_phi(0.2); return; }
    }
  }
  cq_theta(&q2, 1.0);
  if (q2) cq_phi(0.7);
}
