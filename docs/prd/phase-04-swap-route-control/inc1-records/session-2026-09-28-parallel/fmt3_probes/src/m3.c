#include <stdlib.h>
/* cq_measure with BOTH arms quantum: if (c) m = cq_measure(a); else m = cq_measure(b); */
int main(int c, char **v) { int m0 = atoi(v[1]); int q = cq_theta(m0, .5); int a = cq_theta(3, .2); int b = cq_theta(4, .3); int m;
  if (q > 5) m = cq_measure(a); else m = cq_measure(b);
  return m + cq_measure(q); }
