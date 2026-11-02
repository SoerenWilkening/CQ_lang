#include "CQ.h"
// USERCHECK f
// USERCHECK g
// cq-pfpy (rules 8, 9): a block reached from a quantum test and from a classical test inside the other
// arm (musl's `isnan(x) || isnan(y)`). It runs under q || c on every path: its phase, and its value arm
// read by the merge, also when the classical test is false.
__attribute__((noinline)) int h(int d) { __asm__ volatile("" ::: "memory"); return d; }
int f(int a, int b) {
  int x = a;
  cq_theta(&x, 0.3);
  int r;
  if (x > 100 || h(b) > 100) {
    cq_phi(0.5);
    r = x + b;
  } else {
    r = x * 3;
  }
  return cq_measure(r) + cq_measure(x);
}
int g(int a, int b, int c) {
  int x = a;
  cq_theta(&x, 0.3);
  int r;
  if (x > 100 || h(b) > 100)
    r = x + b;
  else if (h(c) > 5)
    r = x - c;
  else
    r = x * 3;
  return cq_measure(r) + cq_measure(x);
}
