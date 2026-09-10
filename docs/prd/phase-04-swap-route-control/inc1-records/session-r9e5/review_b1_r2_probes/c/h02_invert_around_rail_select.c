/* h02 — a cq_invert bracket around a rail-conditioned select. */
#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5);
  int a = 0;
  cq_invert_begin();
  a = b ? 2 : 5;
  cq_invert_end();
  return cq_measure(a); }
