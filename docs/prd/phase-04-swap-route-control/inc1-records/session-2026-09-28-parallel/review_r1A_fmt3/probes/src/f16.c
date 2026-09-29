#include <stdlib.h>
/* r1A: pin on the _Float16 row */
int main(int c, char **v) { _Float16 m = atoi(v[1]); _Float16 q = cq_theta(m, .5); _Float16 t = q * (_Float16)0.25; _Float16 r;
  if (t == (_Float16)5.0) r = cq_theta(t, .9); else r = cq_theta((_Float16)5.0, .9);
  return (int)cq_measure(r) + (int)cq_measure(t); }
