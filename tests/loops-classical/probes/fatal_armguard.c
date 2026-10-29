/* tests/loops-classical fatal probe (cq-pkjc, the slots-h1 p21 repro): the arm `i > 0 && q[i]` is
 * one mixed i1, select(i != 0, q[i], false). Its classical conjunct i != 0 is the classical factor of
 * the arm's predicate (rule 8), which the trip does not establish: linearized, the arm would load
 * q[i - 1] at i == 0 and drop i != 0 from the phase control. cq::unimplemented until a classical
 * guard inside a trip is built. */
#include <stdbool.h>
int f_armguard(int n, double t) {
  bool q[8]; n = (n & 3) + 2;
  for (int k = 0; k < n; k++) q[k] = 0;
  for (int i = 0; i < n; i++) {
    cq_theta(&q[i], t);
    if (i > 0 && q[i] && q[i - 1]) cq_phi(t / (i + 1));
  }
  int e = 0;
  for (int i = 0; i < n; i++) e += cq_measure(q[i]) << i;
  return e;
}
