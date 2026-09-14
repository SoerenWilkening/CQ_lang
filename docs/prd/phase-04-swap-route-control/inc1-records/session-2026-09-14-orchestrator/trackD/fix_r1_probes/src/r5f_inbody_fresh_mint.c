#include "CQ.h"
/* WELL-FORMED, and the EXACT boundary of the F-D1-1 fix: the seed is minted
   INSIDE the loop body, so it is re-established every trip and the reader's own
   previous instance cannot stale it. The barrier is a NON-phi instruction, which
   is the leg a blanket "loop-invariant seed => decline" would have broken. */
int main(void){ int s=0; for(int i=0;i<3;i++){ int q=cq_theta(0,0.3); int b=cq_theta(q,0.1); s+=cq_measure(b); } return s; }
