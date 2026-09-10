#include "CQ.h"
int slice(int u){
  int q = cq_theta(u,0.5);
  int y = (q>5) ? 3 : 7;          /* 4.4 select merge -> %out, tainted only at emission */
  int b = cq_theta(y,0.5);        /* theta on %out */
  int c = cq_theta(y,0.9);        /* SIBLING theta on the SAME %out rail */
  if (b == 1) cq_phi(0.7);        /* the branch reads the STALE name b */
  return cq_measure(c)+cq_measure(q);
}
int main(void){ return slice(3); }
