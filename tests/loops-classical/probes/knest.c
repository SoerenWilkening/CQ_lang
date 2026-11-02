#include "CQ.h"
/* rule 14: a quantum-exit loop nested in a classically bounded loop (musl __rem_pio2_large's shape) */
int k_in_c(int n, int m) {
  int x = 0; cq_theta(&x, 0.7);
  int s = 0;
  for (int i = 0; i < n; i++) {
    int j = 0;
    while (j < x) { s += i; j++; }
  }
  return cq_measure(s);
}
/* the K-loop in a quantum arm of the trip, its exit value joined with the skip edge */
int k_in_arm(int n, double t) {
  int x = 0; cq_theta(&x, t);
  int out = 0;
  for (int i = 0; i < n; i++) {
    int f = 0;
    if (x > 0) { int j = 0; do { f += j; j++; } while (j < x); }
    out ^= f;
  }
  return cq_measure(out);
}
/* a K-loop inside a case-3 trip */
int k_in_c3(int n, double t) {
  int x = 0; cq_theta(&x, t);
  int s = 0;
  for (int i = 0; i < n; i++) {
    int j = 0;
    while (j < x) { s++; j++; }
    if (s > x) break;
  }
  return cq_measure(s);
}
