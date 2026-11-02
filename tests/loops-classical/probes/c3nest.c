/* Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec c3nest.c -o c3nest.O1.ll.
 * tests/loops-classical probes (cq-w3cd): loops nested in a case-3 trip (CR rule 14: the inner chain seeded by
 * the outer trip predicate; a case-1 inner loop runs under the outer trip rail). */
#include "CQ.h"
int n_inner1(int n, double t) {          /* a case-1 loop in a case-3 trip */
  int x = 0; cq_theta(&x, t); int s = 0;
  for (int i = 0; i < n; i++) { for (int j = 0; j < 3; j++) s += x ^ j; if (s == 5) break; }
  return cq_measure(s);
}
int n_inner3(int n, int m, double t) {   /* a case-3 loop in a case-3 trip */
  int x = 0; cq_theta(&x, t); int s = 0;
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) { s += 1; if (x == j) break; }
    if (s == x + 4) break;
  }
  return cq_measure(s);
}
int n_phase(int n, double t) {           /* a phase in the inner trip: under the outer trip rail */
  int x = 0; cq_theta(&x, t);
  for (int i = 0; i < n; i++) { for (int j = 0; j < 2; j++) cq_phi(t * (j + 1)); if (x == i) break; }
  return cq_measure(x);
}
