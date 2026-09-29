#include <stdlib.h>
/* r2A l2a — layer-(2) distinguishing input attempt. p = 3q is (b')-interior on
   ON (consumers: the in-loop per-bit templates + the clone call h(m,p)); u = p+q
   is DEAD after the kickback. ON: component {p,u} planned whole (no Ry between),
   then the body plan (per-trip rails, BORROWS p) sits in a RUNTIME-trip loop whose
   body does not dominate the post-loop anchor -> ordering check drops the OUTER
   {p,u} plan -> u lost. OFF: {u} alone, discharged at the strip. */
int h(int a, int k);
__attribute__((noinline)) int slice(int m, int n) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  for (int i = 0; i < 3; i++) { if ((p >> i) & 1) cq_phi(0.2); }
  int s = h(m, p);
  int q2 = cq_theta(q, 0.7);
  return cq_measure(s) + cq_measure(q2);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])) & 1; }
