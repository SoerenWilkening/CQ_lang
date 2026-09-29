#include <stdlib.h>
/* r1A inlining probe (STATIC helper) K=5 */
static int rotk(int r, int c) {
  if (c > 1) r = cq_theta(r, .2); else r = cq_theta(r, .6);
  if (c > 2) r = cq_theta(r, .3); else r = cq_theta(r, .7);
  if (c > 3) r = cq_theta(r, .4); else r = cq_theta(r, .8);
  if (c > 4) r = cq_theta(r, .5); else r = cq_theta(r, .9);
  if (c > 5) r = cq_theta(r, .6); else r = cq_theta(r, .10);
  return r; }
int main(int argc, char **v) { int m = atoi(v[1]); int n = atoi(v[2]);
  int c = cq_theta(m, .5); int a = cq_theta(n, .7); int b = cq_theta(n + 1, .4);
  a = rotk(a, c); b = rotk(b, c);
  return cq_measure(a) + cq_measure(b) + cq_measure(c); }
