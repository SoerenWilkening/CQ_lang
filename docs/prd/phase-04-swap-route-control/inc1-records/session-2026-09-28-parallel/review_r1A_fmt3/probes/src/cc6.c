#include <stdlib.h>
/* r1A: identical in-place Ry in both arms of a quantum branch (nothing else) */
int main(int c, char **v) { int q = cq_theta(atoi(v[1]), .5); int a = cq_theta(atoi(v[2]), .2);
  if (q > 3) a = cq_theta(a, .9); else a = cq_theta(a, .9);
  return cq_measure(a) + cq_measure(q); }
