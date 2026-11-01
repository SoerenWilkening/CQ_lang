#include "CQ.h"
// USERCHECK f
// cq-1b92: a switch atom fixed by the edge (case 0 of g(d)), carried by its scrutinee.
__attribute__((noinline)) int g(int d) { return d & 3; }
__attribute__((noinline)) void h(int d) { __asm__ volatile("" ::: "memory"); }
void f(int c, int d) {
  bool q1 = 0, q2 = 0;
  cq_theta(&q1, 1.0);
  if (c) {
    switch (g(d)) {
    case 0: h(d); if (q1) { cq_phi(0.3); return; } break;
    case 2: h(c); if (q1) { cq_phi(0.4); return; } break;
    default: break;
    }
  }
  cq_theta(&q2, 1.0);
  if (q2) cq_phi(0.7);
}
