#include <stdlib.h>
/* r1A: pin by __builtin_assume on a quantum compare */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4;
  __builtin_assume(t == 5);
  int r = cq_theta(t, .9);
  return cq_measure(r) + cq_measure(q); }
