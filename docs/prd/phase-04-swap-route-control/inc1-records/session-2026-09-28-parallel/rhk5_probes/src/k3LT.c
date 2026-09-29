/* k3LT — hand-inlined twin of k3L (the z0re Rule-13 reviewer's literal-seed member of
   rhk5's class: a controlled state prep behind a clone call between a derived chain
   and its condition). `h(m, q)` written as `q + 1`; everything else verbatim, the
   seed literal 6 as in k3L. Its runtime-seed sibling k3T (z0re branch) is kept beside
   it as k3T_z0re_runtime_seed.c for the merge-gate check. */
#include <stdlib.h>
int main(int c, char **v) {
  int m = atoi(v[1]); int t = atoi(v[2]);
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3; int u = p ^ q;
  int s = q + 1;
  int r = 6; if (u == 10) r = cq_theta(6, 0.2);
  int ms = cq_measure(s);
  q = cq_theta(q, 0.7);
  return ms + cq_measure(q) + cq_measure(r);
}
