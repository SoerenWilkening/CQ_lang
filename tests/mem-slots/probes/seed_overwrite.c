#include "CQ.h"
/* cq-2t04 (CR rules 7, 20; 121): the zero initializer's seed of each cell is released when the fill loop
   overwrites the cell with the classical 'a' (a known basis state nothing read): load the handle, free it. */
int seed_overwrite(const double *th, int cap, int k) {
  char s[4] = {0, 0, 0, 0};
  for (int i = 0; i < cap; i++) { s[i] = 'a'; cq_theta(&s[i], th[i]); }
  return cq_measure(s[k & 3]);
}
