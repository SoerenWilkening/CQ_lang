#include "CQ.h"
/* WELL-FORMED: the loop BREAKS immediately after the read, so the reader executes at
   most once on every trace. leg 1 still sees a CFG cycle. Candidate OVER-DECLINE. */
int main(void){ int q=cq_theta(0,0.3); int s=0;
  for(int i=0;i<3;i++){ int b=cq_theta(q,0.1); s+=cq_measure(b); break; } return s; }
