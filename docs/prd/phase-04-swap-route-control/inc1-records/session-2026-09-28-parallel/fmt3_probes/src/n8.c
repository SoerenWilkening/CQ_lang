#include <stdlib.h>
/* fmt3: a6 inside a classically-bounded loop */
int main(int c, char **v) { int m = atoi(v[1]); int k = atoi(v[2]); int q = cq_theta(m, .5); int t = q / 4; int acc = 0;
  for (int i = 0; i < k; i++) { int q2 = cq_theta(i, .4); int r = 5;
    if (q2 > 3) { if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9); }
    acc += cq_measure(r) + cq_measure(q2); }
  return acc + cq_measure(t); }
