/* w3: alpha-reading of eqfold_derived_cond -- rotate the AND rail a under cond on a. */
#include "CQ.h"
int main(void){ int q = cq_theta(0,0.25); int a = q & 6; int r = a;
  if (a > 1) r = cq_theta(a, 0.9);
  return cq_measure(r)+cq_measure(q); }
