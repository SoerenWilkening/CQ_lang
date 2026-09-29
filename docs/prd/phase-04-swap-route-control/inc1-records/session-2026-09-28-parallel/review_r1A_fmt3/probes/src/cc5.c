#include <stdlib.h>
/* r1A: identical fresh prep in both arms of a quantum branch, one arm also rotates b */
int main(int c, char **v) { int q = cq_theta(atoi(v[1]), .5); int b = cq_theta(3, .1); int r;
  if (q > 3) { r = cq_theta(5, .9); b = cq_theta(b, .4); } else { r = cq_theta(5, .9); }
  return cq_measure(r) + cq_measure(b) + cq_measure(q); }
