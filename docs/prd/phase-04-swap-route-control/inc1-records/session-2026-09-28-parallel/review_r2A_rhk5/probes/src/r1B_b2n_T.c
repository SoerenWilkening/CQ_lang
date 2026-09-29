#include <stdlib.h>
/* r1B b2n — b2 with a NON-INJECTIVE p: p = q & 3 keeps 2 bits of q, u = p + q keeps
   all of them. The clone reads p AFTER the second Ry on q (p must stay live: the
   program's own entanglement, 2 bits). u is DEAD after the kickback. ORACLE: u is
   discharged before the Ry; only p (2 bits) stays entangled. */

__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q & 3;
  int u = p + q;
  if (u == 10) cq_phi(3.14159);
  int q2 = cq_theta(q, 0.7);
  int s = p + 1;
  return cq_measure(s) + cq_measure(q2);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
