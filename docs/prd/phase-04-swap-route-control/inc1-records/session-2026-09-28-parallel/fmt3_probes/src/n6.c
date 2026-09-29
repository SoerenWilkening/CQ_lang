#include <stdlib.h>
#include <stdbool.h>
/* fmt3: i1 member — b = q & 1 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); bool b = q & 1; int q2 = cq_theta(7, .4); bool r = true;
  if (q2 > 3) { if (b) r = cq_theta(b, .9); else r = cq_theta(true, .9); }
  return cq_measure(r) + cq_measure(b) + cq_measure(q2); }
