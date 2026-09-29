#include <stdlib.h>
/* r1A: CLASSICAL (runtime) condition choosing the Ry angle on ONE quantum register (if/else spelling) */
int main(int c, char **v) { int k = atoi(v[2]); int p = cq_theta(atoi(v[1]), .2);
  if (k > 3) p = cq_theta(p, .9); else p = cq_theta(p, .3);
  return cq_measure(p); }
