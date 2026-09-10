#include "CQ.h"
int ext_f(int a);
int slice(int u){
  int q = cq_theta(u,0.5);
  int y = 5;
  if (q > 5) y = ext_f(7);        /* 6.5 classical-call arm -> %out (tainted only at emission) */
  int b = cq_theta(y,0.5);        /* theta on %out */
  int c = cq_theta(y,0.9);        /* SIBLING theta on the SAME rail */
  if (b == 1) cq_phi(0.7);        /* branch reads the STALE name b */
  return cq_measure(c)+cq_measure(q);
}
