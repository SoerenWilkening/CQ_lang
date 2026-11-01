#include "CQ.h"
// USERCHECK f
__attribute__((noinline)) int g(int d) { return d > 3; }
__attribute__((noinline)) void h(int d) { __asm__ volatile("" ::: "memory"); }
void f(int c, int d) {
  bool q1 = 0, q2 = 0;
  cq_theta(&q1, 1.0);
  if (c) {
    if (g(d)) {
      h(d);
      if (q1) { cq_phi(0.3); return; }
    }
  }
  cq_theta(&q2, 1.0);
  if (q2) cq_phi(0.7);
}
