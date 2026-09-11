/* beta: straight-through incoming folds to the seed; then MUTATE r in place and read q */
#include "CQ.h"
int slice(int u){ int q = cq_theta(u,0.5); int r = q;
  if (q != 5) r = cq_theta(5, 0.9);
  r = r + 3;
  return cq_measure(q) + cq_measure(r); }
