#include <stdlib.h>
/* r1A: sel1 spelled as an if/else VALUE assignment feeding ONE call (no second cq_theta to merge) */
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]);
  int t = cq_theta(m, .5); int s = cq_theta(n, .7); int a;
  if (t == s) a = t; else a = s;
  int r = cq_theta(a, .9);
  return cq_measure(r); }
