#include <stdlib.h>
/* r1A inlining probe (STATIC helper) K=1: an EXTERNAL-linkage helper with K if/else Ry pairs on ONE register, called twice.
   Old header: each pair folds to one call + angle select. New header: two calls + a branch -> bigger body. */
static int rotk(int r, int c) {
  if (c > 1) r = cq_theta(r, .2); else r = cq_theta(r, .6);
  return r; }
int main(int argc, char **v) { int m = atoi(v[1]); int n = atoi(v[2]);
  int c = cq_theta(m, .5); int a = cq_theta(n, .7); int b = cq_theta(n + 1, .4);
  a = rotk(a, c); b = rotk(b, c);
  return cq_measure(a) + cq_measure(b) + cq_measure(c); }
