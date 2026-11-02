#include <stdbool.h>
#include "CQ.h"
/* tests/uncompute probe (cq-4lqy; CR §0, rule 5, §1.1 handles may be compared): a non-diagonal gate on a handle loaded
 * from a slot cell that may hold an operand rail of pending garbage. Whether it hits that rail is decided at run time
 * by comparing the handles: hit, the garbage stays allocated (entangled); not hit, it is cleaned (was: awaiting owner
 * ruling: a gate through a slot cell). From the cq-zh7z repros (wt/rev/jan0-n2/p/a1.c, b1.c).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec alias_hit.c -o alias_hit.O1.ll */
int ah_loop(int n, int m, double t, double u) {
  n = (n & 3) + 1; m = (m & 7) % n;
  bool q[n], r[n];
  for (int k = 0; k < n; k++) { q[k] = 0; r[k] = 0; }
  for (int k = 0; k < n; k++) { cq_theta(&q[k], t); cq_theta(&r[k], t); }
  for (int i = 0; i < n; i++) {
    bool g = q[i] & r[i];
    q[m] = 0;
    cq_theta(&q[i], t);
    if (g) cq_phi(u);
  }
  int e = 0;
  for (int i = 0; i < n; i++) e += cq_measure(q[i]) + cq_measure(r[i]);
  return e;
}
int ah_line(int n, int i, int m, double t, double u) {
  n = (n & 3) + 1; m = (m & 7) % n; i = (i & 7) % n;
  bool q[n], r[n];
  q[i] = 0; r[i] = 0;
  cq_theta(&q[i], t); cq_theta(&r[i], t);
  bool g = q[i] & r[i];
  q[m] = 0;
  cq_theta(&q[i], t);
  if (g) cq_phi(u);
  return cq_measure(q[i]) + cq_measure(r[i]);
}
