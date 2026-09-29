#include <stdlib.h>
/* r1A: cc4's hand-hoisted twin (what old -O1 produced) */
int main(int c, char **v) { int q = cq_theta(atoi(v[1]), .5); int a = cq_theta(atoi(v[2]), .2); int b = cq_theta(3, .1);
  a = cq_theta(a, .9);
  if (q > 3) { b = cq_theta(b, .4); }
  return cq_measure(a) + cq_measure(b) + cq_measure(q); }
