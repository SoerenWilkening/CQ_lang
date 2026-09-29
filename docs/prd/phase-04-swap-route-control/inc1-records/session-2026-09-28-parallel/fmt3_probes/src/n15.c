#include <stdlib.h>
/* fmt3: pin on a WIDER register, arm reads a narrowing cast */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); long long t = (long long)q * 3; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (t == 5) r = cq_theta((int)t, .9); else r = cq_theta(5, .9); }
  return cq_measure(r) + (int)cq_measure(t) + cq_measure(q2); }
