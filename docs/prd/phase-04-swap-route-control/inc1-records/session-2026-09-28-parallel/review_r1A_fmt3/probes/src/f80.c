#include <stdlib.h>
/* r1A: n5-like pin on the f80 row: long double, literal 5.0L */
int main(int c, char **v) { long double m = atoi(v[1]); long double q = cq_theta(m, .5); long double t = q * 0.25L; long double r;
  if (t == 5.0L) r = cq_theta(t, .9); else r = cq_theta(5.0L, .9);
  return (int)cq_measure(r) + (int)cq_measure(t); }
