/* r1A composition probe (nlfd/ev3m x cepm x rhk5): q passed in a DEAD slot and p = 3q in a LIVE one;
   the call result depends only on p. Main-today neutralises the dead q slot (vsfp);
   rhk5 then asks cloneCallPreservesArg only for the live p slot. */
#include <stdlib.h>

int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int p = q * 3;
  int u = p ^ q;
  int s = p + 1;
  if (u == 10) cq_phi(3.14159);
  int ms = cq_measure(s);
  q = cq_theta(q, .7);
  return ms + cq_measure(q);
}
