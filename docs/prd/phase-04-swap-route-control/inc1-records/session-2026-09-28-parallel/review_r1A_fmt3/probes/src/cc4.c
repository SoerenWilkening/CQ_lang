#include <stdlib.h>
/* r1A: IDENTICAL rotation hoistable from both arms of a QUANTUM branch, plus a controlled Ry on a second register */
int main(int c, char **v) { int q = cq_theta(atoi(v[1]), .5); int a = cq_theta(atoi(v[2]), .2); int b = cq_theta(3, .1);
  if (q > 3) { a = cq_theta(a, .9); b = cq_theta(b, .4); } else { a = cq_theta(a, .9); }
  return cq_measure(a) + cq_measure(b) + cq_measure(q); }
