#include <stdlib.h>
int h(int a, int m);
/* COMPOSITION (z0re x cepm+3zr4): the seed is a spec-call result whose value DOES depend on the quantum arg */
int main(int c, char **v) { int n = atoi(v[1]), m = atoi(v[2]); int q = cq_theta(n, .5); int q2 = cq_theta(7, .4);
  int t = h(q, m); int r = t; if (q2 > 3) r = cq_theta(t, .2);
  return cq_measure(r) + cq_measure(q) + cq_measure(q2); }
