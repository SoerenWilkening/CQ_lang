#include <stdlib.h>
/* runtime seed that is ALSO the condition's classical operand, then a trailing Ry on the condition register */
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int r = s;
  if (q > s) r = cq_theta(s, .2); q = cq_theta(q, .7);
  return cq_measure(r) + cq_measure(q); }
