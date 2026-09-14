#include "CQ.h"
/* WELL-FORMED: the invariant seed is READ in the loop but no gate ever moves the
   wire, so nothing is stale. Must ACCEPT (a measure reader has no self-gate). */
int main(void){ int q=cq_theta(0,0.3); int s=0; for(int i=0;i<3;i++){ s+=cq_measure(q); } return s; }
