#include "CQ.h"
struct rec { int a; short b; };
static int tab[4] = {3, 5, 9, 7};
static struct rec recs[3] = {{1, 2}, {3, 4}, {5, 6}};
int gq(unsigned x0, double t, int v) {
  unsigned x = x0;
  cq_theta(&x, t);
  unsigned i = x & 3, j = x % 3;
  tab[i] = v;
  recs[j].a = v;
  int r = tab[(i + 1) & 3] + recs[j].b + recs[(j + 1) % 3].a;
  return cq_measure(r);
}
