#include "CQ.h"
// cq-m3mu (CR rule 10): a state prep stored into a slot cell under its quantum predicate. In C the cell is
// the prepared register; a select merge would copy the rotated rail (forbidden by rule 10). Not built.
int prep_store_predicated_error(int c, double a){ int q=0; cq_theta(&q,1.0); int t[2]; t[0]=0; t[1]=0;
  if (q > 3) { t[c&1] = 7; cq_theta(&t[c&1], a); }
  cq_theta(&t[c&1], -a);
  return t[0] + 2*t[1]; }
