#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int n = atoi(v[1]), m = atoi(v[2]); int q = cq_theta(n, .5); int q2 = cq_theta(7, .4);
  g(q); int t = m + 1; int r = t; if (q2 > 3) r = cq_theta(t, .2);
  return cq_measure(r) + cq_measure(q) + cq_measure(q2); }
