#include <stdlib.h>
/* the Ry-stem angle select's C spelling INSIDE a classically-bounded loop (control_inplace_ry_inloop_ifelse.ll's C form) */
int main(int c, char **v) { int k = atoi(v[2]); int r = cq_theta(3, .2); int acc = 0;
  for (int i = 0; i < k; i++) { int q = cq_theta(i, .5);
    if (q > 3) r = cq_theta(r, .9); else r = cq_theta(r, .3);
    acc += cq_measure(q); }
  return acc + cq_measure(r); }
